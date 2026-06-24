#!/usr/bin/env bash
set -euo pipefail
# cuda-install.sh — CUDA toolkit (12.4) + dkms for kernel-module builds.
# Reads the platform module instead of hardcoding the repo id, so a mismatch is
# reported rather than silently 404-ing. The local-installer .deb stays version-
# pinned (it names an exact toolkit/driver build) and is flagged as such.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

CUDA_REPO_ID="ubuntu2204"          # what the pinned local installer targets
CUDA_DEB="cuda-repo-ubuntu2204-12-4-local_12.4.1-550.54.15-1_amd64.deb"

install_cuda() {
  if have nvcc; then
    ark_log "cuda: nvcc present — skipping"
    return 0
  fi

  ark_platform
  local detected="${ARK_DISTRO}${ARK_VERSION_NODOT}"   # e.g. ubuntu2204
  if [ "$detected" != "$CUDA_REPO_ID" ]; then
    ark_warn "cuda-install is pinned to ${CUDA_REPO_ID}; detected ${detected} — repo URLs may 404."
  fi

  ark_log "dkms (kernel module build support)"
  sudo apt-get install -y dkms

  ark_log "cuda toolkit 12.4 for ${CUDA_REPO_ID}"
  wget "https://developer.download.nvidia.com/compute/cuda/repos/${CUDA_REPO_ID}/x86_64/cuda-${CUDA_REPO_ID}.pin"
  sudo mv "cuda-${CUDA_REPO_ID}.pin" /etc/apt/preferences.d/cuda-repository-pin-600
  wget "https://developer.download.nvidia.com/compute/cuda/12.4.1/local_installers/${CUDA_DEB}"
  sudo dpkg -i "${CUDA_DEB}"
  sudo cp /var/cuda-repo-${CUDA_REPO_ID}-12-4-local/cuda-*-keyring.gpg /usr/share/keyrings/
  sudo apt-get update
  sudo apt-get -y install cuda-toolkit-12-4
}

install_cuda
