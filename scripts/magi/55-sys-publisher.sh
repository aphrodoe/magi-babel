#!/usr/bin/env bash
# Install the system telemetry publisher: magi/status + magi/sys/*.
#
# Idempotent. Re-run to pick up a changed unit file or script. Pass --reset to
# be prompted for the MQTT password again.
#
# Writes /etc/magi/mqtt.env — root-only, gitignored by virtue of not being in
# the repo at all, and one of the files R2 cannot regenerate.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENVF=/etc/magi/mqtt.env
UNIT=/etc/systemd/system/magi-sys.service

# paho-mqtt, because the publisher holds one long-lived connection so its Last
# Will actually means something. mosquitto_pub cannot: it disconnects cleanly
# after every message, so the broker would never fire the will.
dpkg -s python3-paho-mqtt >/dev/null 2>&1 || sudo apt-get install -y python3-paho-mqtt

if [ ! -f "$ENVF" ] || [ "${1:-}" = --reset ]; then
  read -rsp "MQTT password for user 'magi': " PASS; echo
  sudo install -d -m 700 /etc/magi
  printf 'MQTT_USER=magi\nMQTT_PASS=%s\n' "$PASS" | sudo install -m 600 /dev/stdin "$ENVF"
  unset PASS
fi

sudo tee "$UNIT" >/dev/null <<UNITEOF
[Unit]
Description=MAGI system telemetry to MQTT
# The broker publishes on the tailnet address, so the tailnet has to be up.
After=network-online.target docker.service tailscaled.service
Wants=network-online.target

[Service]
ExecStart=$REPO/scripts/magi/magi-sys.py
EnvironmentFile=$ENVF
User=aphrodoe
Restart=always
RestartSec=10s
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=read-only
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
UNITEOF

sudo systemctl daemon-reload
sudo systemctl enable --now magi-sys.service
sudo systemctl restart magi-sys.service
sleep 3
systemctl --no-pager --lines=10 status magi-sys.service
