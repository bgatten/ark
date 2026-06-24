#!/usr/bin/env bash
set -euo pipefail
# install_base.sh — base packages for every box (GPU or not).
# dkms moved out to the GPU/driver path (cuda-install.sh) since it exists to
# build the NVIDIA kernel module, not to serve a generic box.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

install_base() {
  ark_log "base: htop, foxglove-studio"
  sudo apt-get update
  sudo apt-get install -y htop

  if have snap && snap list foxglove-studio >/dev/null 2>&1; then
    ark_log "foxglove-studio present — skipping"
  else
    sudo snap install foxglove-studio
  fi
}

install_base
