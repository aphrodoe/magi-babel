#!/usr/bin/env bash
# Docker Engine + Compose v2 on MAGI. Idempotent — safe to run more than once.
#   sudo ~/homelab/scripts/magi/40-docker.sh
#
# From Docker's own apt repo, not Ubuntu's docker.io package: the distro build
# lags upstream badly and ships compose v1 (a dead Python script) instead of the
# v2 plugin every compose.yaml in this repo assumes.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "run this with sudo"; exit 1; }
: "${SUDO_USER:?run via sudo, not as root directly}"

. /etc/os-release

# --- 1. Docker's apt repo -------------------------------------------------
apt-get update -qq
apt-get install -y -qq ca-certificates curl >/dev/null

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

cat > /etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable
EOF
echo "· apt: docker repo pinned to '$VERSION_CODENAME'"

# --- 2. engine + plugins --------------------------------------------------
apt-get update -qq
apt-get install -y -qq \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin >/dev/null
echo "· installed: $(docker --version), compose $(docker compose version --short)"

# --- 3. cap the logs ------------------------------------------------------
# Docker's default json-file driver never rotates. A chatty container on a box
# that runs for months fills / and takes the whole stack down with it. 3x10M
# per container is plenty to debug yesterday and bounded forever.
cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
EOF
systemctl restart docker
echo "· daemon.json: logs capped at 3 x 10M per container"

# --- 4. let a port bind before its address exists -------------------------
# compose/caddy publishes on 100.94.219.53, MAGI's tailnet address, so the port
# never opens on the campus LAN (rule 7). But that address only appears once
# tailscaled has registered, and docker starts containers at boot without
# waiting for it — so Caddy died on 2026-08-30 with
#   failed to bind host port 100.94.219.53:80/tcp: cannot assign requested address
# and, being a *start* failure rather than a crash, the restart policy never
# retried it. ip_nonlocal_bind lets the socket bind ahead of the address; packets
# still only ever arrive over tailscale0, so nothing is loosened.
cat > /etc/sysctl.d/10-magi-nonlocal-bind.conf <<'EOF'
net.ipv4.ip_nonlocal_bind = 1
EOF
sysctl -q --system
echo "· sysctl: ip_nonlocal_bind=1 — published ports survive tailscale0 being late"

# --- 5. run docker without sudo ------------------------------------------
# The docker group is root-equivalent: a member can bind-mount / into a
# container and walk out as root. Acceptable here because $SUDO_USER already
# has full sudo — it grants no new authority, it just removes the typing.
if id -nG "$SUDO_USER" | grep -qw docker; then
  echo "· $SUDO_USER already in the docker group"
else
  usermod -aG docker "$SUDO_USER"
  echo "· $SUDO_USER added to the docker group — log out and back in to use it"
fi

systemctl enable --now docker containerd >/dev/null 2>&1
echo "· docker enabled at boot"

# --- 6. prove it works ----------------------------------------------------
if docker run --rm hello-world >/dev/null 2>&1; then
  echo "· hello-world ran clean"
else
  echo "! hello-world FAILED — check 'journalctl -u docker'"; exit 1
fi
