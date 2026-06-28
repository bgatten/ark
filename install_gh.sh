#!/usr/bin/env bash
set -euo pipefail
# install_gh.sh — GitHub CLI. Key ships pre-dearmored; add_apt_repo handles it.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

install_gh() {
  if have gh; then ark_log "gh: present — skipping"; return 0; fi
  add_apt_repo github-cli \
    https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    "https://cli.github.com/packages stable main"
  sudo apt-get install -y gh
}

install_gh
