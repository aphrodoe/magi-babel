#!/usr/bin/env bash
# Install the R3 backup job: restic nightly to the external HDD.
#
# Idempotent. Re-run to pick up a changed unit or script; --reset re-prompts
# for the repository password.
#
# Writes /etc/magi/backup.env — root-only, outside the repo, and the sixth file
# R2 cannot regenerate. LOSING THE REPOSITORY PASSWORD MEANS LOSING EVERY
# SNAPSHOT: restic has no recovery path, by design. Put it in Vaultwarden once
# Vaultwarden exists, and on paper until then.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENVF=/etc/magi/backup.env
MOUNT="${BACKUP_MOUNT:-/mnt/backup}"

for p in restic sqlite3; do
  command -v "$p" >/dev/null || sudo apt-get install -y "$p"
done

# `sudo test`, not `test`: /etc/magi is 0700 root, so an unprivileged check
# reports "missing" for a file that is right there (same trap as 55-*).
if ! sudo test -f "$ENVF" || [ "${1:-}" = --reset ]; then
  echo "This password encrypts the repository. There is no way to recover it."
  read -rsp "restic repository password: " PASS; echo
  read -rsp "again: " PASS2; echo
  [ "$PASS" = "$PASS2" ] || { echo "passwords differ" >&2; exit 1; }
  sudo install -d -m 700 /etc/magi
  sudo install -m 600 /dev/null "$ENVF"
  printf 'BACKUP_MOUNT=%s\nRESTIC_REPOSITORY=%s/restic\nRESTIC_PASSWORD=%s\n' \
    "$MOUNT" "$MOUNT" "$PASS" | sudo tee "$ENVF" >/dev/null
  unset PASS PASS2
fi

sudo tee /etc/systemd/system/magi-backup.service >/dev/null <<UNITEOF
[Unit]
Description=MAGI nightly restic backup (R3)
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$REPO/scripts/magi/magi-backup.sh
EnvironmentFile=$ENVF
EnvironmentFile=/etc/magi/mqtt.env
# Root, because it reads every Docker volume and /etc/magi. The job's own
# mountpoint guard is what stops it writing to the wrong disk.
User=root
UNITEOF

sudo tee /etc/systemd/system/magi-backup.timer >/dev/null <<'UNITEOF'
[Unit]
Description=Run the MAGI backup nightly

[Timer]
OnCalendar=*-*-* 02:00:00
# The laptop may be asleep or off at 02:00; run on the next boot instead of
# skipping the night entirely.
Persistent=true
RandomizedDelaySec=15m

[Install]
WantedBy=timers.target
UNITEOF

sudo systemctl daemon-reload

if mountpoint -q "$MOUNT"; then
  # Sourced inside the privileged shell, never passed as arguments: an `env
  # RESTIC_PASSWORD=...` would put the repository password in `ps` for anyone
  # on the box to read.
  sudo bash -c 'set -a; . '"$ENVF"'; set +a
                restic snapshots >/dev/null 2>&1 || {
                  echo "initialising repository at $RESTIC_REPOSITORY"
                  restic init
                }'
  sudo systemctl enable --now magi-backup.timer
  echo; systemctl list-timers --no-pager magi-backup.timer
else
  # Deliberately not enabled. An enabled timer with no drive would fail every
  # night for weeks and teach you to ignore a red unit — which is exactly the
  # habit that makes the real failure invisible.
  cat <<MSG

Units installed but the timer is NOT enabled: $MOUNT is not mounted.

When the 2 TB HDD arrives:
  lsblk -f                                    # find its UUID
  sudo mkdir -p $MOUNT
  echo "UUID=<uuid> $MOUNT ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
  sudo mount -a
  ./scripts/magi/70-backup.sh                 # re-run: inits the repo, enables the timer

nofail matters: without it a missing drive drops the box to an emergency
shell at boot, and MAGI is headless.
MSG
fi
