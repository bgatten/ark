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
#      Code reinstalls the plugin skills (superpowers, karpathy, …) on its own.
#   2. Install the personal skills recorded in claude/skill-lock.json
#      (caveman, diagnose, …) for Claude Code, non-interactively.
#
# Depends on the `claude` (the app it configures) and `node` (the `npx` runtime
# the skills CLI needs) targets — the orchestrator pulls those in first. The
# skills step also probes for npx/python3 and self-skips with a note if either
# is missing, so running this standalone on a bare box is safe.
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$here/lib.sh"

CLAUDE_DIR="$HOME/.claude"
PAYLOAD="$here/claude"
LOCK="$PAYLOAD/skill-lock.json"

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

install_skills() {
  if ! have npx;     then ark_warn "claude-config: npx not found (run the node target) — skipping personal skills"; return 0; fi
  if ! have python3; then ark_warn "claude-config: python3 not found — skipping personal skills; install python3, then re-run"; return 0; fi
  [ -f "$LOCK" ] || { ark_warn "claude-config: no skill-lock.json — skipping personal skills"; return 0; }

  # Probe: every locked skill already present for Claude Code?
  local names missing=0 n
  names="$(python3 -c 'import json,sys; print("\n".join(json.load(open(sys.argv[1]))["skills"]))' "$LOCK")"
  for n in $names; do [ -e "$CLAUDE_DIR/skills/$n" ] || missing=1; done
  if [ "$missing" -eq 0 ]; then ark_log "claude-config: personal skills present — skipping"; return 0; fi

  ark_log "claude-config: installing personal skills via the skills manager (target agent: claude-code)"
  # Skills span >1 source (mattpocock/skills, vercel-labs/skills); install each
  # source's locked set. Names are read live from the lockfile so this tracks it.
  while IFS=$'\t' read -r src csv; do
    [ -n "$src" ] || continue
    ark_log "claude-config:   ${src} -> ${csv}"
    npx --yes skills@latest add "$src" -g -y -a claude-code -s "$csv"
  done < <(python3 -c '
import json, sys, collections
skills = json.load(open(sys.argv[1]))["skills"]
by_source = collections.defaultdict(list)
for name, info in skills.items():
    by_source[info["source"]].append(name)
for src, names in by_source.items():
    print(src + "\t" + ",".join(names))
' "$LOCK")
}

install_claude_config() {
  mkdir -p "$CLAUDE_DIR"
  link_into_claude CLAUDE.md
  link_into_claude settings.json
  install_skills
}

install_claude_config
