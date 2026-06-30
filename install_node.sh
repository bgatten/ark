#!/usr/bin/env bash
set -euo pipefail
# install_node.sh — Node.js LTS from NodeSource. Carries npm/npx, which is the
# only reason it's here: the Claude Code skills CLI (`npx skills@latest …`)
# needs a Node runtime. Claude Code itself does not — it ships a native binary
# via the apt repo (see install_claude.sh), so this is an independent target.
# NodeSource's key is armored; add_apt_repo dearmors it like the rest.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

NODE_MAJOR="${NODE_MAJOR:-22}"   # current LTS line; override to bump

install_node() {
  if have node && have npm; then
    ark_log "node: $(node --version) present — skipping"
    return 0
  fi
  add_apt_repo nodesource \
    https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    "https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main"
  sudo apt-get install -y nodejs
}

install_node
