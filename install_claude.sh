#!/usr/bin/env bash
set -euo pipefail
# install_claude.sh — Claude Code, from Anthropic's signed apt repo.
# Same dance as gh/docker: armored .asc key, add_apt_repo dearmors it.
# Updates then ride the normal `apt upgrade` path (apt installs don't
# self-update). The `stable` channel trails latest by ~a week, skipping
# releases with major regressions — the right default for a provisioned box.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

install_claude() {
  if have claude; then ark_log "claude: present — skipping"; return 0; fi
  add_apt_repo claude-code \
    https://downloads.claude.ai/keys/claude-code.asc \
    "https://downloads.claude.ai/claude-code/apt/stable stable main"
  sudo apt-get install -y claude-code
}

install_claude
