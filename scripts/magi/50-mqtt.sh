#!/usr/bin/env bash
# Bring up the MQTT broker. Re-run after ANY change under config/mosquitto/.
#
# Two things this does that `docker compose up -d` alone will not:
#
#  1. Fixes the ACL file's ownership. Mosquitto 2.1 warns — and says future
#     versions will refuse — if acl_file is world-readable or not owned by the
#     broker user (uid 1883 inside the container). The file is tracked in git,
#     so `git pull` restores it to 0644 aphrodoe:aphrodoe every time it
#     changes upstream. Mode 0640 keeps the exec bit clear, which is the only
#     permission bit git records — so this never shows up as a dirty tree.
#
#  2. Restarts the container. `up -d` compares the service definition, not the
#     contents of bind-mounted files, so a changed .conf or acl sits on disk
#     unread and everything looks fine.

set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STACK="$REPO/compose/mosquitto/compose.yaml"

# mosquitto_pub / mosquitto_sub on the host — the telemetry publisher needs
# them, and so does every debugging session. Clients only; the broker itself
# runs in the container. (`snap install mosquitto` would install a second one.)
dpkg -s mosquitto-clients >/dev/null 2>&1 || sudo apt-get install -y mosquitto-clients

sudo chown 1883:1883 "$REPO/config/mosquitto/acl"
sudo chmod 0640      "$REPO/config/mosquitto/acl"

docker compose -f "$STACK" up -d
docker compose -f "$STACK" restart

sleep 2
docker logs --since 15s mosquitto 2>&1 | tail -15
