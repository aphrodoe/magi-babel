#!/usr/bin/env bash
# 24online captive-portal login for the campus WIRED port.
#   sudo ~/homelab/scripts/magi/35-netaccess.sh           set up: prompt, install timer
#   sudo ~/homelab/scripts/magi/35-netaccess.sh --login   log in now (what the timer runs)
#
# The wall port is a walled garden: HTTP/80 is intercepted and answered by a
# Webcat/Skein proxy, and TCP/443 is refused outright until you authenticate.
# Everything the lab does needs 443, so an unauthenticated wired link looks
# exactly like a dead network — DHCP fine, ping fine, DNS fine, nothing works.
# On Windows a browser pops the login page; headless, we POST the same form.
#
# CREDENTIALS live in root-only /etc/magi/netaccess.env, never in this repo.
# Third file R2 cannot regenerate, after the wifi password and the deSEC token.
set -euo pipefail
CREDS=/etc/magi/netaccess.env
# HTTPS, not HTTP. The servlet 302s every plain-HTTP POST to its own https:// URL
# and the redirect body is empty, so an http:// POST silently does nothing. The
# walled garden permits 443 to the portal host itself even while blocking it
# everywhere else, and the certificate validates, so this needs no -k.
PORTAL="https://netaccess.iitj.ac.in"
UNIT=/etc/systemd/system/magi-netaccess.service
TIMER=/etc/systemd/system/magi-netaccess.timer
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

[[ $EUID -eq 0 ]] || { echo "run this with sudo"; exit 1; }

wired_iface() { ip -br addr | awk '/^en.*UP/ && /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\//{print $1; exit}'; }

# Is 443 actually usable? That, not ping, is the test that matters here.
have_443() {
  local i="$1"
  timeout 6 curl --interface "$i" -4 -sS -m 5 -o /dev/null https://www.google.com 2>/dev/null
}

do_login() {
  local IF; IF=$(wired_iface)
  [[ -n "$IF" ]] || { echo "· no wired interface with an address — nothing to do"; exit 0; }
  if have_443 "$IF"; then echo "· $IF already has 443; no login needed"; exit 0; fi

  [[ -r "$CREDS" ]] || { echo "no $CREDS — run this script without --login first"; exit 1; }
  # shellcheck disable=SC1090
  . "$CREDS"
  : "${NETACCESS_USER:?}" "${NETACCESS_PASS:?}"

  # Ask the portal what it thinks our MAC and IP are, rather than guessing —
  # it reports the address it will bind the session to, which is not always the
  # interface's own MAC.
  # One cookie jar across both requests. The servlet issues a JSESSIONID with the
  # login page and expects it back on the POST; two separate curl calls looked
  # like two unrelated visitors and the POST was bounced with a 302.
  local JAR PAGE MAC IP
  JAR=$(mktemp); trap 'rm -f "$JAR"' RETURN
  PAGE=$(curl --interface "$IF" -4 -sS -m 12 -L -c "$JAR" -b "$JAR" \
           "$PORTAL/24online/webpages/client.jsp" 2>/dev/null || true)
  MAC=$(printf '%s' "$PAGE" | grep -oE "name=[\"']macaddress[\"'] value='[^']*'" | grep -oE "'[^']*'$" | tr -d "'")
  IP=$(printf  '%s' "$PAGE" | grep -oE "name=[\"']ipaddress[\"'] value='[^']*'"  | grep -oE "'[^']*'$" | tr -d "'")
  [[ -n "$IP" ]] || IP=$(ip -4 -br addr show "$IF" | grep -oE '[0-9.]+/[0-9]+' | cut -d/ -f1)
  echo "· portal sees ip=$IP mac=${MAC:-unknown}"

  # The portal's own JavaScript rewrites the username before submitting:
  #   normalizeIitUsername()  ->  strips any @iitj.ac.in, then appends it.
  # A browser therefore sends b24cs1005@iitj.ac.in, never the bare name, and the
  # bare name is rejected. Do the same normalisation, idempotently.
  local U="${NETACCESS_USER%@iitj.ac.in}@iitj.ac.in"

  curl --interface "$IF" -4 -sS -m 20 -L -c "$JAR" -b "$JAR" \
    -e "$PORTAL/24online/webpages/client.jsp" \
    -o /tmp/netaccess-last.html \
    -X POST "$PORTAL/24online/servlet/E24onlineHTTPClient" \
    --data-urlencode "mode=191" \
    --data-urlencode "username=$U" \
    --data-urlencode "login=Login" \
    --data-urlencode "password=$NETACCESS_PASS" \
    --data-urlencode "mac=$MAC" \
    --data-urlencode "macaddress=$MAC" \
    --data-urlencode "ipaddress=$IP" \
    --data-urlencode "servername=netaccess.iitj.ac.in" \
    --data-urlencode "logintype=2" \
    --data-urlencode "isAccessDenied=null" \
    --data-urlencode "url=null" \
    --data-urlencode "checkClose=0" \
    --data-urlencode "sessionTimeout=0" \
    --data-urlencode "orgSessionTimeout=0" \
    --data-urlencode "guestmsgreq=false" \
    --data-urlencode "loginotp=false" \
    --data-urlencode "logincaptcha=false" \
    --data-urlencode "chrome=-1" \
    --data-urlencode "timeout=0" \
    --data-urlencode "popupalert=0" \
    --data-urlencode "dtold=0" 2>/dev/null || true

  sleep 3
  if have_443 "$IF"; then
    echo "· logged in — 443 is open on $IF"
  else
    echo "! login did not open 443. The portal's reply is in /tmp/netaccess-last.html;"
    echo "  grep it for a message before assuming the credentials are wrong."
    grep -oE "alert\\('[^']*'\\)|<font color=[\"']?red[\"']?>[^<]*" /tmp/netaccess-last.html 2>/dev/null | head -3
    exit 1
  fi
}

[[ "${1:-}" == "--login" ]] && { do_login; exit $?; }

# --- setup ----------------------------------------------------------------
echo "Campus net-access credentials. Not echoed, not committed, not recoverable"
echo "from the repo — a rebuild asks again. Same trade as the wifi password."
read -rp  "username: " U
read -rsp "password (not shown): " P; echo
[[ -n "$U" && -n "$P" ]] || { echo "both are required"; exit 1; }

install -d -m 700 /etc/magi
umask 077
cat > "$CREDS" <<EOF
NETACCESS_USER=$U
NETACCESS_PASS=$P
EOF
chmod 600 "$CREDS"
echo "· credentials written to $CREDS (600, root only)"

cat > "$UNIT" <<EOF
[Unit]
Description=Log MAGI into the campus 24online portal
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$SELF --login
EOF

# Every two minutes rather than once at boot: the session is bound to the DHCP
# lease, so it dies whenever the lease moves or the cable is replugged, not only
# at boot. The check is cheap and a no-op whenever 443 already works.
cat > "$TIMER" <<'EOF'
[Unit]
Description=Keep MAGI logged into the campus portal

[Timer]
OnBootSec=30s
OnUnitActiveSec=2min
AccuracySec=10s

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now magi-netaccess.timer >/dev/null
echo "· magi-netaccess.timer enabled — checks every 2 min, logs in only when 443 is shut"

do_login
