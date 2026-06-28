#!/usr/bin/env bash
set -euo pipefail
# install_tailscale.sh — Tailscale VPN. Per-codename repo; key is pre-dearmored.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

install_tailscale() {
  if have tailscale; then ark_log "tailscale: present — skipping"; return 0; fi
  ark_platform
  add_apt_repo tailscale \
    "https://pkgs.tailscale.com/stable/ubuntu/${ARK_CODENAME}.noarmor.gpg" \
    "https://pkgs.tailscale.com/stable/ubuntu ${ARK_CODENAME} main"
  sudo apt-get install -y tailscale
  ark_log "tailscale installed — run 'sudo tailscale up' to authenticate."
}

install_tailscale
