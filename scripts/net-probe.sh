#!/usr/bin/env bash
# Diagnose a campus wired port: open / captive portal / 802.1X.
# Run on MAGI as root with the ethernet adapter plugged into the wall port:
#   sudo ~/homelab/scripts/net-probe.sh [interface]
# Leaves a working DHCP config in place if the port turns out to be open.
set -uo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }

LOG=/root/net-probe.log
exec > >(tee "$LOG") 2>&1
PROBE=/etc/netplan/99-probe.yaml

IFACE="${1:-}"
if [[ -z "$IFACE" ]]; then
  # newest en* that isn't a tether already holding the default route
  for i in $(ls /sys/class/net | grep '^en'); do
    ip link set "$i" up 2>/dev/null
  done
  sleep 3
  for i in $(ls /sys/class/net | grep '^en'); do
    [[ $(cat "/sys/class/net/$i/carrier" 2>/dev/null) == 1 ]] && IFACE="$i" && break
  done
fi
[[ -n "$IFACE" ]] || { echo "no en* interface with carrier. Is the cable in both ends?"; exit 1; }

echo "=== interface: $IFACE ==="
ip link set "$IFACE" up
echo "carrier: $(cat /sys/class/net/$IFACE/carrier 2>/dev/null)  speed: $(cat /sys/class/net/$IFACE/speed 2>/dev/null)Mb  mac: $(cat /sys/class/net/$IFACE/address)"
echo
echo "=== existing netplan ==="
cat /etc/netplan/*.yaml
echo

echo "=== listening for 802.1X (EAPOL) for 40s ==="
EAP=/tmp/eapol.txt
timeout 40 tcpdump -i "$IFACE" -nn -c 5 'ether proto 0x888e' > "$EAP" 2>/dev/null &
TCPD=$!

cat > "$PROBE" <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $IFACE:
      dhcp4: true
      optional: true
EOF
chmod 600 "$PROBE"
netplan apply 2>&1 | head -5

echo "waiting up to 40s for a DHCP lease..."
IP=""
for _ in $(seq 40); do
  IP=$(ip -4 -br addr show "$IFACE" | awk '{print $3}')
  [[ -n "$IP" ]] && break
  sleep 1
done
wait $TCPD 2>/dev/null
EAPCOUNT=$(grep -c . "$EAP" 2>/dev/null); EAPCOUNT=${EAPCOUNT:-0}

echo
echo "=== results ==="
echo "EAPOL frames seen: $EAPCOUNT"
[[ $EAPCOUNT -gt 0 ]] && sed -n '1,3p' "$EAP"
echo "lease: ${IP:-NONE}"
echo "route: $(ip route | grep "^default.*$IFACE" || echo NONE)"

PORTAL=""
if [[ -n "$IP" ]]; then
  echo "dns: $(getent hosts github.com | head -1 || echo FAIL)"
  echo -n "http probe: "
  curl -sS -m 10 -o /dev/null -w '%{http_code} -> %{redirect_url}\n' \
    http://connectivity-check.ubuntu.com/ || echo "curl failed"
  PORTAL=$(curl -sS -m 10 -o /dev/null -w '%{redirect_url}' http://neverssl.com/ 2>/dev/null)
  echo "redirect: ${PORTAL:-none}"
  echo -n "direct https: "
  curl -sS -m 10 -o /dev/null -w '%{http_code}\n' https://1.1.1.1/ || echo "blocked"
fi

echo
echo "======================= VERDICT ======================="
if [[ $EAPCOUNT -gt 0 && -z "$IP" ]]; then
  echo "802.1X. The switch is asking for credentials and refusing DHCP."
  echo "Next: netplan auth block (EAP-PEAP/MSCHAPv2), no portal login needed."
elif [[ -n "$PORTAL" ]]; then
  echo "CAPTIVE PORTAL at: $PORTAL"
  echo "Next: script a curl login + keepalive."
elif [[ -n "$IP" ]]; then
  echo "OPEN PORT. DHCP + internet with no auth. Nothing else to do."
  echo "(99-probe.yaml left in place; will be replaced by the repo config.)"
else
  echo "NO LEASE and NO EAPOL. Either MAC registration is required, the port"
  echo "is dead/unpatched, or the adapter needs a driver. See details above."
  rm -f "$PROBE"; netplan apply
fi
echo "======================================================="
echo "full log: $LOG"
