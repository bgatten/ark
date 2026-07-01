#!/usr/bin/env bash
set -euo pipefail
# install_claude_config.sh — the `claude-config` target: make this box's Claude
# Code match every other box.
#
# Two jobs, both probe-driven and re-runnable like every ark installer:
#   1. Link this machine's global Claude config to the canonical copies in ark
#      (single source of truth): ~/.claude/CLAUDE.md and ~/.claude/settings.json
#      become symlinks into ark/claude/. Edit once, commit, pull anywhere.
#      settings.json carries enabledPlugins + extraKnownMarketplaces, so Claude
#      Code installs the plugin skills (superpowers, karpathy, …) on its own on
#      first launch.
#   2. Install the personal skills vendored in claude/skills/ (caveman, diagnose,
#      …) by copying them into ~/.claude/skills.
#
# The skills are vendored — committed as real files in the repo — rather than
# refetched by name from upstream. Upstream skill repos rename and remove skills;
# a name-based reinstall (npx skills add -s …) fails the whole batch on the first
# mismatch. Vendoring makes ark the source of truth: drift-proof and offline.
# To refresh the set: copy ~/.claude/skills into claude/skills/ and commit.
#
# Depends only on `claude` (the app it configures) — the orchestrator pulls it
# in first. No node/npx: copying files needs neither.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$here/lib.sh"

CLAUDE_DIR="$HOME/.claude"
PAYLOAD="$here/claude"
SKILLS_SRC="$PAYLOAD/skills"

# Probe: a path already points at the same file we'd link to.
link_into_claude() {            # $1 = filename under the payload
  local name="$1" src="$PAYLOAD/$1" dst="$CLAUDE_DIR/$1"
  if [ "$(readlink -f "$dst" 2>/dev/null)" = "$(readlink -f "$src")" ]; then
    ark_log "claude-config: ${name} already linked — skipping"; return 0
  fi
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    ark_warn "claude-config: existing ${name} found — backing up to ${name}.bak"
    mv "$dst" "$dst.bak"
  fi
  ln -sfn "$src" "$dst"
  ark_log "claude-config: linked ${name} -> ark"
}

# Copy each vendored skill into ~/.claude/skills. Probe per skill: present -> skip
# (to refresh one, delete its dir and re-run — the usual ark idiom).
install_skills() {
  [ -d "$SKILLS_SRC" ] || { ark_warn "claude-config: no vendored skills dir — skipping"; return 0; }
  mkdir -p "$CLAUDE_DIR/skills"
  local d n new=0
  for d in "$SKILLS_SRC"/*/; do
    n="$(basename "$d")"
    [ -e "$CLAUDE_DIR/skills/$n" ] && continue
    cp -r "$d" "$CLAUDE_DIR/skills/$n"
    new=$((new + 1))
  done
  ark_log "claude-config: vendored skills -> ~/.claude/skills (${new} new, $(ls -1 "$SKILLS_SRC" | wc -l) total)"
}

install_claude_config() {
  mkdir -p "$CLAUDE_DIR"
  link_into_claude CLAUDE.md
  link_into_claude settings.json
  install_skills
}

install_claude_config
