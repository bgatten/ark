#!/usr/bin/env bash
set -euo pipefail
# install_vscode.sh — VS Code from the Microsoft apt repo (armored .asc key).
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

install_vscode() {
  if have code; then ark_log "vscode: present — skipping"; return 0; fi
  add_apt_repo vscode \
    https://packages.microsoft.com/keys/microsoft.asc \
    "https://packages.microsoft.com/repos/code stable main"
  sudo apt-get install -y code
}

install_vscode
