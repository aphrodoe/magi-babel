#!/usr/bin/env bash
# H-03 — Prometheus, node_exporter, cAdvisor, Grafana.
#
# Exists to answer "what do I run on a bare MAGI, in what order" for the one
# thing the compose file cannot carry: the Grafana admin password, which is
# gitignored. Everything else is just `up -d`.
#
# Idempotent. Re-run it to apply a config change; pass --reset to set a new
# Grafana password (note: Grafana only reads it when it creates the admin
# user, so on an existing install use `grafana-cli admin reset-admin-password`
# instead — this only fixes the file for the next rebuild).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STACK="$REPO/compose/observability/compose.yaml"
ENVF="$REPO/secrets/grafana.env"

if [ ! -f "$ENVF" ] || [ "${1:-}" = --reset ]; then
  read -rsp "Grafana admin password: " PASS; echo
  install -d -m 700 "$REPO/secrets"
  # Empty at 0600 first, then write into it — the password is never on disk at
  # looser permissions and never passes through a temp file.
  install -m 600 /dev/null "$ENVF"
  printf 'GF_SECURITY_ADMIN_USER=admin\nGF_SECURITY_ADMIN_PASSWORD=%s\n' "$PASS" > "$ENVF"
  unset PASS
fi

# node_exporter is in the host namespace, so Prometheus reaches it over the
# bridge rather than by container name — and ufw's default-deny drops that
# silently. The socket is bound and listening; the packets never arrive. Any
# future host-networked exporter needs the same one-line exception.
sudo ufw allow in on br-glass to 100.94.219.53 port 9100 proto tcp \
  comment 'prometheus -> node_exporter' >/dev/null

docker compose -f "$STACK" up -d
# Bind mounts don't trigger a recreate, so a changed prometheus.yml or
# provisioning file needs this to take effect (same reason as 50-mqtt.sh).
docker compose -f "$STACK" restart prometheus grafana

# Caddy learned two new hostnames; it reloads config on restart.
docker compose -f "$REPO/compose/caddy/compose.yaml" restart caddy

echo
docker compose -f "$STACK" ps
