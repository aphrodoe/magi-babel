#!/usr/bin/env bash
# Install MAGI's netplan config from the repo and apply it, reverting if the
# network doesn't come back. Run: sudo ~/homelab/scripts/magi/10-network.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }
SRC="$(cd "$(dirname "$0")/../.." && pwd)/config/netplan/10-magi-net.yaml"
BAK=$(mktemp -d)

cp -a /etc/netplan/. "$BAK"/ 2>/dev/null || true
echo "backup of /etc/netplan -> $BAK"

rm -f /etc/netplan/00-installer-config.yaml /etc/netplan/99-probe.yaml
install -m 600 -o root -g root "$SRC" /etc/netplan/10-magi-net.yaml
netplan apply

for _ in $(seq 20); do
  ip route | grep -q '^default' && break
  sleep 1
done

if ip route | grep -q '^default'; then
  echo "OK: $(ip route | grep '^default')"
else
  echo "NO DEFAULT ROUTE — reverting"
  rm -f /etc/netplan/*.yaml
  cp -a "$BAK"/. /etc/netplan/
  netplan apply
  exit 1
fi
