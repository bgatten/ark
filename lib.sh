#!/usr/bin/env bash
# lib.sh — shared modules for ark installers.
#
# Source this; do not execute it. Provides one place for the things every
# installer needs: platform detection, the apt-repository registration dance,
# the NVIDIA-GPU gate, logging, and a re-runnable reboot signal.
#
#   . "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Idempotent source guard — sourcing twice is harmless.
[ -n "${_ARK_LIB:-}" ] && return 0
_ARK_LIB=1

# ── logging ───────────────────────────────────────────────────────────────
ark_log()  { printf '\033[1;34m>>>\033[0m %s\n' "$*"; }
ark_warn() { printf '\033[1;33m!!!\033[0m %s\n' "$*" >&2; }
ark_err()  { printf '\033[1;31mEEE\033[0m %s\n' "$*" >&2; }

# ── have: is a command on PATH? ─────────────────────────────────────────────
have() { command -v "$1" >/dev/null 2>&1; }

# ── platform module ─────────────────────────────────────────────────────────
# One place that answers "what box is this?". Sets, for the current machine:
#   ARK_DISTRO        e.g. ubuntu
#   ARK_VERSION_ID    e.g. 22.04
#   ARK_VERSION_NODOT e.g. 2204        (cuda repo id form)
#   ARK_CODENAME      e.g. jammy       (docker repo form)
#   ARK_REPO_ID       e.g. ubuntu22.04 (libnvidia-container repo form)
#   ARK_ARCH          e.g. amd64
# Replaces the three different ad-hoc detections the installers used to carry.
ark_platform() {
  [ -n "${ARK_DISTRO:-}" ] && return 0   # detect once per process
  # shellcheck disable=SC1091
  . /etc/os-release
  ARK_DISTRO="${ID:-unknown}"
  ARK_VERSION_ID="${VERSION_ID:-}"
  ARK_VERSION_NODOT="${ARK_VERSION_ID//./}"
  ARK_CODENAME="${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null || echo unknown)}"
  ARK_REPO_ID="${ARK_DISTRO}${ARK_VERSION_ID}"
  ARK_ARCH="$(dpkg --print-architecture 2>/dev/null || echo amd64)"
  export ARK_DISTRO ARK_VERSION_ID ARK_VERSION_NODOT ARK_CODENAME ARK_REPO_ID ARK_ARCH
}

# ── NVIDIA-GPU gate ─────────────────────────────────────────────────────────
# Probes the hardware, not the driver — true on a fresh box before any driver
# exists, so GPU targets aren't wrongly skipped on the first pass.
ark_has_nvidia_gpu() {
  if have lspci; then
    lspci 2>/dev/null | grep -iq 'nvidia'
  elif [ -d /proc/driver/nvidia ]; then
    return 0
  else
    ark_warn "lspci not found; cannot detect NVIDIA GPU — assuming none."
    return 1
  fi
}

# ── reboot signal ───────────────────────────────────────────────────────────
# Installers that leave the box needing a reboot (driver, group membership)
# record why here. The orchestrator clears it at start and reports it at end;
# the re-runnable design means the next pass converges after the reboot.
ARK_REBOOT_FILE="${ARK_REBOOT_FILE:-${TMPDIR:-/tmp}/ark-reboot-required}"
export ARK_REBOOT_FILE
ark_request_reboot() {
  ark_warn "reboot required: $*"
  printf '%s\n' "$*" >>"$ARK_REBOOT_FILE"
}

# ── add_apt_repo: keyring + signed-by source list + update ──────────────────
# The repeated apt-repo dance, in one place. Small interface, three args:
#   add_apt_repo NAME GPG_URL "REPO_LINE"
# where REPO_LINE is everything after the [signed-by=...] block, e.g.
#   "https://download.docker.com/linux/ubuntu jammy stable"
# Writes /etc/apt/keyrings/<name>-keyring.gpg and
# /etc/apt/sources.list.d/<name>.list, then refreshes apt. Re-running rewrites
# both (cheap) so it is safe under the re-runnable contract.
#
# Note: only vendors whose repo is a single deb line fit this interface (docker).
# nvidia-container-toolkit ships a remote .list and cuda ships a local .deb, so
# those installers keep their own registration but still read the platform
# module above — that is where candidate-3's win actually lands.
add_apt_repo() {
  local name="$1" gpg_url="$2" repo_line="$3"
  ark_platform
  local keyring="/etc/apt/keyrings/${name}-keyring.gpg"
  local listfile="/etc/apt/sources.list.d/${name}.list"
  ark_log "apt repo: ${name}"
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "$gpg_url" | sudo gpg --batch --yes --dearmor -o "$keyring"
  sudo chmod a+r "$keyring"
  echo "deb [arch=${ARK_ARCH} signed-by=${keyring}] ${repo_line}" \
    | sudo tee "$listfile" >/dev/null
  sudo apt-get update
}
