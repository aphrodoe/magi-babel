#!/usr/bin/env bash
# Create or update the Mosquitto password file.
#
# Interactive, and idempotent: run it again to add a user or change a password.
# Users you don't name are left alone.
#
# Writes secrets/mosquitto/passwd — gitignored, and one of the files R2 cannot
# regenerate. Record it in the rebuild notes with the other three.
#
#   ./45-mqtt-passwd.sh admin magi
#
# Uses the mosquitto image's own mosquitto_passwd, so there is nothing to
# install on the host.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DIR="$REPO/secrets/mosquitto"
IMG="eclipse-mosquitto:2"

[ $# -ge 1 ] || { echo "usage: $0 <username> [<username>...]" >&2; exit 1; }

mkdir -p "$DIR"

for user in "$@"; do
  # -c creates the file, and overwrites it — only ever on the first user.
  flags=(); [ -f "$DIR/passwd" ] || flags=(-c)
  echo "· password for '$user'"
  # sudo: after the first run the file is owned by 1883, so the container
  # needs write access to it as well as the directory.
  sudo docker run --rm -it -v "$DIR:/out" "$IMG" \
    mosquitto_passwd "${flags[@]}" /out/passwd "$user"
done

# The broker runs as uid 1883 inside the container. Owning the file lets it
# stay 0600 — readable by mosquitto, by nobody else, and not flagged by
# mosquitto's own permission warning.
sudo chown 1883:1883 "$DIR/passwd"
sudo chmod 600 "$DIR/passwd"

echo "✓ $DIR/passwd — $(sudo grep -c . "$DIR/passwd") user(s)"
