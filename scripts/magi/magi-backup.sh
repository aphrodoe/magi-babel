#!/usr/bin/env bash
# The R3 job. Runs nightly from magi-backup.timer, as root.
#
# Reads /etc/magi/backup.env (RESTIC_REPOSITORY, RESTIC_PASSWORD, BACKUP_MOUNT)
# and /etc/magi/mqtt.env (MQTT_USER, MQTT_PASS) — both supplied by the unit.
#
# Publishes magi/backup/state per config/mosquitto/TOPICS.md, which H-05's
# BACKUP LED subscribes to.
set -euo pipefail

STAGE=/var/lib/magi-backup
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

pub() {
  # Retained: `state` is a current value, so a subscriber connecting at 03:00
  # learns the world as it is. TOPICS.md, "state is current value, retained".
  mosquitto_pub -h 100.94.219.53 -u "$MQTT_USER" -P "$MQTT_PASS" \
    -t "magi/backup/$1" -m "$2" -r -q 1 2>/dev/null || true
}

fail() { echo "backup failed: $*" >&2; pub state failed; exit 1; }
trap 'pub state failed' ERR

# The guard that matters. If the HDD is unplugged or failed to mount, this path
# is an ordinary empty directory on the NVMe — restic would happily write a
# "backup" onto the same disk it is meant to protect, fill the root filesystem,
# and report success every night. Refuse instead.
mountpoint -q "$BACKUP_MOUNT" || fail "$BACKUP_MOUNT is not a mountpoint"

pub state running
pub pct 0

# --- 1. Databases, dumped rather than copied ---------------------------------
# A live SQLite file copied byte-for-byte can land mid-write and restore
# corrupt. `.backup` uses SQLite's own backup API, which is safe against a
# running writer, WAL included.
#
# Globbed rather than listed, so a service added later is picked up without
# editing this script. Immich and Paperless bring Postgres when they land —
# that needs a `docker exec ... pg_dump` here, and it must run BEFORE the
# restic call below, not alongside it.
rm -rf "$STAGE"; install -d -m 700 "$STAGE"
while IFS= read -r db; do
  out="$STAGE/$(echo "${db#/var/lib/docker/volumes/}" | tr / _)"
  sqlite3 "$db" ".backup '$out'" || fail "sqlite dump of $db"
done < <(find /var/lib/docker/volumes \
           -path '*observability_loki_data*' -prune -o \
           -path '*observability_prometheus_data*' -prune -o \
           \( -name '*.db' -o -name '*.sqlite3' \) -print)

pub pct 50

# --- 2. The snapshot ----------------------------------------------------------
# Prometheus, Loki and Alloy are deliberately excluded. They are regenerable
# telemetry: losing them costs history, not function, and Loki is the one thing
# here that grows without bound. Everything else is either irreplaceable or
# small.
restic backup \
  --tag magi \
  --exclude-caches \
  --exclude '/var/lib/docker/volumes/observability_prometheus_data' \
  --exclude '/var/lib/docker/volumes/observability_loki_data' \
  --exclude '/var/lib/docker/volumes/observability_alloy_data' \
  "$STAGE" \
  /etc/magi \
  /etc/netplan \
  "$REPO/secrets" \
  /var/lib/docker/volumes \
  || fail "restic backup"

rm -rf "$STAGE"
pub pct 100

# --- 3. Retention -------------------------------------------------------------
# `forget` is metadata-only and cheap, so it runs nightly. `--prune` rewrites
# pack files, which is a lot of small random I/O — the one thing a 2.5" SMR
# portable drive is genuinely bad at. Weekly on Sunday is the compromise.
PRUNE=""
[ "$(date +%u)" = 7 ] && PRUNE="--prune"
restic forget --tag magi \
  --keep-daily 7 --keep-weekly 4 --keep-monthly 6 $PRUNE \
  || fail "restic forget"

pub state ok
echo "backup ok: $(restic snapshots --tag magi --latest 1 --compact 2>/dev/null | tail -2 | head -1)"
