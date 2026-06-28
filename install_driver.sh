#!/usr/bin/env bash
set -euo pipefail
# install_driver.sh — NVIDIA driver, picked from the detected GPU architecture.
#
# Grounded in field-proven branches rather than the latest production release:
#   Ada       (RTX 40xx) -> nvidia-driver-550        (proven on the Legion 4060)
#   Blackwell (RTX 50xx) -> nvidia-driver-575-open   (proven on the 5080; open
#                                                      modules are mandatory)
#   anything else        -> ubuntu-drivers autoinstall (safe fallback; Ampere
#                                                        and unknown land here)
# Probe: if nvidia-smi already works, leave the working driver alone.
#
# Architecture comes from the PCI device id (10de:XXXX), not the lspci name —
# a fresh box often has a stale pci.ids DB that shows "Device [10de:28e0]" with
# no model, but the id range is always present and network-free.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# 4-hex device id of the first NVIDIA display controller (e.g. 28e0), or empty.
nvidia_pci_id() {
  have lspci || return 0
  lspci -nn 2>/dev/null | grep -iE 'vga|3d controller|display' \
    | grep -ioE '10de:[0-9a-f]{4}' | head -1 | cut -d: -f2
}

# Map a device id to an architecture by its known consumer id ranges.
nvidia_arch() {
  local id="$1" n
  [ -n "$id" ] || { echo unknown; return; }
  n=$((16#$id))
  if   (( n >= 0x2600 && n <= 0x28ff )); then echo ada
  elif (( n >= 0x2b00 && n <= 0x2fff )); then echo blackwell
  elif (( n >= 0x2200 && n <= 0x25ff )); then echo ampere
  else echo unknown
  fi
}

install_driver() {
  if ! ark_has_nvidia_gpu; then
    ark_log "driver: no NVIDIA GPU — skipping"
    return 0
  fi
  if have nvidia-smi && nvidia-smi >/dev/null 2>&1; then
    ark_log "driver: working ($(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1)) — leaving it alone"
    return 0
  fi

  local id arch pkg
  id="$(nvidia_pci_id)"
  arch="$(nvidia_arch "$id")"
  case "$arch" in
    ada)       pkg="nvidia-driver-550" ;;
    blackwell) pkg="nvidia-driver-575-open" ;;   # open modules mandatory
    *)         pkg="" ;;                          # ampere/unknown → autoinstall
  esac
  ark_log "driver: NVIDIA [10de:${id:-????}] arch=${arch}"

  # graphics-drivers PPA as the source (LTS repos cover 550/575; the PPA is the
  # safe fallback so the pinned package always resolves).
  if ! grep -rqi 'graphics-drivers' /etc/apt/sources.list.d/ 2>/dev/null; then
    sudo add-apt-repository -y ppa:graphics-drivers/ppa
    sudo apt-get update
  fi

  if [ -n "$pkg" ]; then
    ark_log "driver: ${arch} → ${pkg}"
    sudo apt-get install -y "$pkg"
  else
    ark_warn "driver: arch '${arch}' has no pinned driver → ubuntu-drivers autoinstall"
    sudo apt-get install -y ubuntu-drivers-common
    sudo ubuntu-drivers autoinstall
  fi
  ark_request_reboot "NVIDIA driver installed — reboot to load it, then re-run to converge"
}

install_driver
