#!/usr/bin/env bash
# Hardware workarounds for this specific machine. Runs before anything touches
# the network, because one of them decides whether the wifi card works at all.
#   sudo ~/homelab/scripts/magi/05-hw-quirks.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run this with sudo"; exit 1; }

# --- RTL8822CE: disable PCIe ASPM -----------------------------------------
# The card fails to leave ASPM L1 reliably. Its IRQ is masked during NAPI poll,
# so the link stays parked, RX DMA crawls, and the controller misses its
# completion window — the console then floods with
#   rtw88_8822ce ... PCIe Bus Error: severity=Uncorrectable ... [14] CmpltTO
# fast enough that you cannot type. Observed 2026-08-30, the first time wifi had
# to carry MAGI on its own; under wired the card idles and never trips it.
# Same bug was fixed in-tree for the 8821CE (commit 24f5e38a13b5).
if [[ -e /sys/module/rtw88_pci ]] || modinfo rtw88_pci >/dev/null 2>&1; then
  cat > /etc/modprobe.d/rtw88-aspm.conf <<'EOF'
# See scripts/magi/05-hw-quirks.sh. Without this the card storms the PCIe bus
# with completion timeouts as soon as it carries real traffic.
options rtw88_pci disable_aspm=1
EOF
  echo "· modprobe.d: rtw88_pci disable_aspm=1"

  # Take effect now if the driver is loaded, rather than waiting for a reboot.
  if lsmod | grep -q '^rtw88_pci'; then
    DRV=$(lsmod | awk '/^rtw88_8822c/{print $1; exit}')
    modprobe -r "${DRV:-rtw88_8822ce}" 2>/dev/null || true
    modprobe -r rtw88_pci             2>/dev/null || true
    modprobe "${DRV:-rtw88_8822ce}"   2>/dev/null || true
    echo "· reloaded the wifi driver with ASPM off"
  else
    echo "· wifi driver not loaded; the option applies at next load"
  fi
else
  echo "· no rtw88_pci on this machine — nothing to do"
fi
