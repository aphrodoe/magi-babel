#!/usr/bin/env bash
# H-00 hardening for MAGI. Idempotent — safe to run more than once.
#   sudo ./h00-harden.sh
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "run this with sudo"; exit 1; }
USER_HOME=$(getent passwd "${SUDO_USER:?run via sudo, not as root directly}" | cut -d: -f6)

# --- 0. refuse to lock you out -------------------------------------------
KEYS="$USER_HOME/.ssh/authorized_keys"
if [[ ! -s "$KEYS" ]] || ! grep -q '^ssh-' "$KEYS"; then
  echo "ABORT: no usable key in $KEYS."
  echo "Turning off password auth now would leave no way in over SSH."
  exit 1
fi
echo "· $(grep -c '^ssh-' "$KEYS") authorized key(s) present — safe to disable passwords"

# --- 1. SSH: keys only ----------------------------------------------------
# sshd uses the FIRST value it finds, and 'Include sshd_config.d/*.conf' sits at
# the top of sshd_config — so this file beats anything below it. The 10- prefix
# keeps it ahead of 50-cloud-init.conf if cloud-init ever repopulates that.
cat > /etc/ssh/sshd_config.d/10-magi-hardening.conf <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
EOF
sshd -t
systemctl reload ssh
echo "· ssh: password auth off, root login off"

# --- 2. firewall ----------------------------------------------------------
# Order matters: allow SSH *before* enabling, or enabling ufw cuts this session.
ufw allow OpenSSH                     >/dev/null
ufw allow in on tailscale0            >/dev/null
ufw allow 41641/udp comment 'tailscale direct peers' >/dev/null
ufw --force enable                    >/dev/null
echo "· ufw: default-deny inbound; SSH, tailscale0 and 41641/udp allowed"

# --- 3. automatic security updates ---------------------------------------
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
systemctl enable --now unattended-upgrades >/dev/null 2>&1 || true
echo "· unattended-upgrades: on"

# --- 4. lid closed, machine awake ----------------------------------------
mkdir -p /etc/systemd/logind.conf.d
cat > /etc/systemd/logind.conf.d/10-magi-lid.conf <<'EOF'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOF
echo "· logind: lid switch ignored (takes effect after reboot)"

echo
echo "done. verify from cipher:  ssh magi 'sudo ufw status verbose'"
