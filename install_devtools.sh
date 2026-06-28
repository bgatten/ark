#!/usr/bin/env bash
set -euo pipefail
# install_devtools.sh — C++ build toolchain. Recent cmake comes from Kitware;
# the rest from the distro. (The heavier lib*-dev / robotics bundle is a
# separate cpp-libs target, intentionally not included here yet.)
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

PKGS=(build-essential ninja-build ccache cmake
      clang-format clang-tidy cppcheck doxygen graphviz gdb)

install_devtools() {
  if have cmake && have ninja && have ccache && have clang-format && have cppcheck && have doxygen; then
    ark_log "devtools: toolchain present — skipping"
    return 0
  fi
  ark_platform
  # recent cmake from Kitware rather than the distro's older one
  add_apt_repo kitware \
    https://apt.kitware.com/keys/kitware-archive-latest.asc \
    "https://apt.kitware.com/ubuntu/ ${ARK_CODENAME} main"
  sudo apt-get install -y "${PKGS[@]}"
}

install_devtools
