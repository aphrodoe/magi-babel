#!/usr/bin/env bash
# Radicale — CalDAV and CardDAV. Calendar and contacts off Google.
#
# Idempotent. --reset re-prompts for the password. Re-run after editing
# config/radicale/config to apply it.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STACK="$REPO/compose/radicale/compose.yaml"
USERS="$REPO/secrets/radicale/users"

install -d -m 700 "$REPO/secrets" "$REPO/secrets/radicale"

if [ ! -f "$USERS" ] || [ "${1:-}" = --reset ]; then
  read -rp  "Radicale username: " RUSER
  read -rsp "Radicale password: " PASS; echo
  # -i takes the password on stdin, keeping it out of argv (same as 75-*).
  LINE="$(printf '%s\n' "$PASS" | docker run --rm -i httpd:2.4 \
            htpasswd -B -C 10 -n -i "$RUSER")"
  unset PASS
  [ -n "$LINE" ] || { echo "hashing failed" >&2; exit 1; }
  install -m 600 /dev/null "$USERS"
  printf '%s\n' "$LINE" > "$USERS"
  unset LINE
  echo "wrote $USERS (user: $RUSER)"
fi

# The image starts as root and drops to uid 2999 (verified against this tag's
# /etc/passwd), so hand the file to that uid and keep it 0600. World-readable
# would also work and is what most guides do — but this is a bcrypt hash, and
# 0600-to-the-right-uid costs one line.
sudo chown 2999:2999 "$USERS"
sudo chmod 600 "$USERS"

docker compose -f "$STACK" up -d
docker compose -f "$STACK" restart radicale
docker compose -f "$REPO/compose/caddy/compose.yaml" restart caddy
echo
docker compose -f "$STACK" ps
cat <<'MSG'

Add the account on your phone as a CalDAV/CardDAV server:

  URL       https://dav.lab.akhildhyani.me/
  Username  the one you just set

  iOS      Settings -> Calendar -> Accounts -> Add -> Other -> CalDAV
  Android  DAVx5 (F-Droid or Play), "Login with URL and username"

Only reachable on the tailnet, so the phone needs Tailscale up to sync.
MSG
