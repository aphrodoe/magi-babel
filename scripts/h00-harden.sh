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
echo "· logind: lid switch ignored"

# A server must never suspend. Masking makes it impossible rather than merely
# unconfigured — 'static' targets can still be pulled in by something else.
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target >/dev/null 2>&1 || true
echo "· sleep/suspend/hibernate: masked"

# logind only reads its config at start, so apply it now rather than waiting for
# a reboot to make the lid safe.
systemctl restart systemd-logind
echo "· logind restarted — lid setting is live"

# netplan's `optional: true` did not produce RequiredForOnline=no on this box
# (networkctl still reports "Required For Online: yes"), so boot blocks in
# systemd-networkd-wait-online for its full 120s default when the switch is down
# — which is exactly the state after a power cut, since the router takes ~5min to
# come back and MAGI boots faster than that. Anything ordered after
# network-online.target (Docker, from H-01 on) inherits that stall.
# --any: proceed as soon as one link is up, rather than all of them.
mkdir -p /etc/systemd/system/systemd-networkd-wait-online.service.d
cat > /etc/systemd/system/systemd-networkd-wait-online.service.d/10-magi-timeout.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/lib/systemd/systemd-networkd-wait-online --any --timeout=20
EOF
systemctl daemon-reload
echo "· wait-online: capped at 20s, --any (was an unbounded 120s wait)"

# The battery is MAGI's UPS, so the critical-battery action matters. Stock is
# HybridSleep — which we just masked, so upower would try it, fail, and let the
# box hard-die at 0%. Hibernate isn't an alternative either: swap (4G) is smaller
# than RAM (8G), and will stay smaller when the RAM is upgraded to 16G.
# PowerOff is "risky" in upower's terms (it drops unsaved state), which is why it
# needs the second key — but a clean shutdown beats an unclean one every time.
mkdir -p /etc/UPower/UPower.conf.d
cat > /etc/UPower/UPower.conf.d/10-magi-power.conf <<'EOF'
[UPower]
CriticalPowerAction=PowerOff
AllowRiskyCriticalPowerAction=true
EOF
systemctl restart upower
echo "· upower: clean PowerOff at critical battery (was HybridSleep, which is masked)"

echo
echo "done. verify from cipher:  ssh magi 'sudo ufw status verbose'"
