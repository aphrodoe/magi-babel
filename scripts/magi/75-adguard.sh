#!/usr/bin/env bash
# AdGuard Home — DNS filtering for the whole tailnet.
#
# Idempotent. Re-run to apply a change to config/adguard/AdGuardHome.yaml;
# --reset re-prompts for the admin password.
#
# NOTE: this OVERWRITES the live config with the repo's copy. Anything changed
# in AdGuard's web UI lives only on the host and is lost here. That is the R1
# trade, made on purpose — edit the repo file, re-run this.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STACK="$REPO/compose/adguard/compose.yaml"
SRC="$REPO/config/adguard/AdGuardHome.yaml"
DST=/etc/magi/adguard/AdGuardHome.yaml
HASHF=/etc/magi/adguard/.pwhash

sudo install -d -m 700 /etc/magi/adguard

if ! sudo test -f "$HASHF" || [ "${1:-}" = --reset ]; then
  read -rp  "AdGuard admin username: " AGUSER
  read -rsp "AdGuard admin password: " PASS; echo
  # htpasswd -i reads the password from STDIN, so unlike `-b` it never appears
  # in the container's argv and never shows up in `ps`.
  HASH="$(printf '%s\n' "$PASS" | docker run --rm -i httpd:2.4 \
            htpasswd -B -C 10 -n -i "$AGUSER" | cut -d: -f2-)"
  unset PASS
  [ -n "$HASH" ] || { echo "hashing failed" >&2; exit 1; }
  printf '%s\n%s\n' "$AGUSER" "$HASH" | sudo tee "$HASHF" >/dev/null
  sudo chmod 600 "$HASHF"
  unset HASH
fi

AGUSER="$(sudo sed -n 1p "$HASHF")"

# Rendered with awk rather than sed: a bcrypt hash contains '/' and '$', which
# sed would treat as a delimiter and as backreferences respectively.
#
# Whole lines are REPLACED, not substrings substituted. The first version
# matched "^    name: admin$" against a line that is actually "  - name: admin"
# — two spaces and a dash, because it is the first item of a YAML list. It
# silently did nothing, the username stayed `admin`, and the only symptom was a
# 403 at the login page that looked exactly like a mistyped password.
sudo awk -v u="$AGUSER" -v h="$(sudo sed -n 2p "$HASHF")" '
  /^  - name: /     { print "  - name: " u; next }
  /^    password: / { print "    password: " h; next }
                    { print }' "$SRC" | sudo tee "$DST" >/dev/null

# Fail loudly rather than serving a config with the placeholder still in it.
sudo grep -q '__ADGUARD_PASSWORD_HASH__' "$DST" \
  && { echo "render failed: placeholder still present in $DST" >&2; exit 1; }
sudo grep -q "^  - name: $AGUSER\$" "$DST" \
  || { echo "render failed: username not applied in $DST" >&2; exit 1; }
sudo chmod 600 "$DST"

docker compose -f "$STACK" up -d
# AdGuard reads its config once at start, and a bind-mounted file change does
# not recreate the container.
docker compose -f "$STACK" restart adguardhome
docker compose -f "$REPO/compose/caddy/compose.yaml" restart caddy
echo
docker compose -f "$STACK" ps
cat <<'MSG'

Not done yet — AdGuard filters nothing until something asks it:

  Point ONE device at 100.94.219.53 first and confirm it resolves, before
  touching the tailnet-wide setting. Then, if you want it everywhere:

    Tailscale admin -> DNS -> Global nameserver 100.94.219.53
    ...and on MAGI:  sudo tailscale up --accept-dns=false

  --accept-dns=false matters: without it MAGI resolves through itself and loops.
  And with "Override local DNS" on, MAGI going down takes DNS down for every
  device on the tailnet. Leave Override off until you have lived with it a while.
MSG
