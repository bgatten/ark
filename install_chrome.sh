#!/usr/bin/env bash
set -euo pipefail
# install_chrome.sh — Google Chrome from the Google apt repo (armored key).
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

install_chrome() {
  if have google-chrome || have google-chrome-stable; then
    ark_log "chrome: present — skipping"; return 0
  fi
  add_apt_repo google-chrome \
    https://dl.google.com/linux/linux_signing_key.pub \
    "https://dl.google.com/linux/chrome/deb/ stable main"
  sudo apt-get install -y google-chrome-stable
}

install_chrome
