#!/usr/bin/env bash
set -euo pipefail
# nvidia-container-toolkit.sh — wires the NVIDIA container runtime into docker.
# Depends on docker (the orchestrator enforces the edge). Its repo ships as a
# remote .list, so it keeps its own registration but reads the platform module.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

install_nvidia_toolkit() {
  if dpkg -s nvidia-docker2 >/dev/null 2>&1; then
    ark_log "nvidia-docker2: present — skipping"
    return 0
  fi
  if ! have docker; then
    ark_err "docker not installed — run setup_docker.sh first."
    return 1
  fi

  ark_platform
  local distribution="${ARK_REPO_ID}"   # e.g. ubuntu22.04
  ark_log "nvidia container toolkit for ${distribution}"

  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -s -L "https://nvidia.github.io/libnvidia-container/${distribution}/libnvidia-container.list" \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y nvidia-docker2
  sudo systemctl restart docker
}

install_nvidia_toolkit
