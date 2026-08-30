#!/usr/bin/env bash
# Is the campus wired port behind a captive portal, and where is it?
#   ~/homelab/scripts/magi/diag-portal.sh
#
# Writes everything to /tmp/portal-diag.txt as well as stdout, because plugging
# the wired adapter in steals the default route (metric 100) from wifi and drops
# MAGI off the tailnet — so the SSH session running this will die. Run it, unplug
# the cable, then read the file once the tailnet is back.
#
# A walled-garden portal looks exactly like what we see: HTTP/80 permitted so the
# login page is reachable, TCP/443 refused outright until you authenticate.
set -uo pipefail
OUT=/tmp/portal-diag.txt
exec > >(tee "$OUT") 2>&1

IFACE=$(ip -br link | awk '/^en/{print $1}' | head -1)
echo "=== interface: ${IFACE:-NONE} ==="
ip -br addr show "$IFACE" 2>/dev/null
ip route | grep "$IFACE" || true

echo
echo "=== DHCP-supplied resolver and gateway ==="
resolvectl status "$IFACE" 2>/dev/null | grep -iE "dns servers|current dns|dhcp" || true
GW=$(ip route | awk "/^default.*$IFACE/{print \$3}" | head -1)
echo "gateway: ${GW:-none}"

echo
echo "=== what the standard connectivity checks actually return ==="
for u in http://connectivity-check.ubuntu.com/ \
         http://detectportal.firefox.com/success.txt \
         http://www.gstatic.com/generate_204 \
         http://neverssl.com/ ; do
  echo "--- $u"
  curl --interface "$IFACE" -4 -sS -m 10 -i -o - "$u" 2>&1 | head -25
  echo
done

echo "=== does the gateway itself serve a page? ==="
[[ -n "${GW:-}" ]] && curl --interface "$IFACE" -4 -sS -m 8 -i "http://$GW/" 2>&1 | head -20

echo
echo "=== port reachability, same destination ==="
for p in 80 443 8080 8090; do
  timeout 5 bash -c "cat < /dev/null > /dev/tcp/142.250.192.100/$p" 2>/dev/null \
    && echo "  tcp/$p  open" || echo "  tcp/$p  BLOCKED"
done

echo
echo "written to $OUT"
