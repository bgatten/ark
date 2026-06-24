#!/usr/bin/env bash
set -euo pipefail
#
# install-everything.sh — the setup orchestrator.
#
# One interface: bring up this box. Behind it lives the ordering, the
# dependency edges, the NVIDIA-GPU gate, and the failure policy. Each installer
# stays runnable on its own and carries its own "already done?" probe; this
# script only decides *which* installers run, *in what order*, and *what to do
# when one fails*.
#
#   ./install-everything.sh                 # auto: every applicable target
#   ./install-everything.sh docker cuda     # just these (deps pulled in)
#   ./install-everything.sh --dry-run        # print the plan, run nothing
#
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
. "$here/lib.sh"

# ── target registry ─────────────────────────────────────────────────────────
# Canonical order already respects the dependency edges below, so no topo sort.
ALL_TARGETS=(base docker nvidia cuda aws)

installer_for() {
  case "$1" in
    base)   echo "install_base.sh" ;;
    docker) echo "setup_docker.sh" ;;
    nvidia) echo "nvidia-container-toolkit.sh" ;;
    cuda)   echo "cuda-install.sh" ;;
    aws)    echo "aws-install.sh install" ;;   # install seam only; never configure
  esac
}
needs_of()   { case "$1" in nvidia) echo "docker" ;; *) echo "" ;; esac; }
gpu_gated()  { case "$1" in nvidia|cuda) return 0 ;; *) return 1 ;; esac; }

# ── arg parsing ─────────────────────────────────────────────────────────────
DRY_RUN=0
requested=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    base|docker|nvidia|cuda|aws) requested+=("$arg") ;;
    *) ark_err "unknown target: $arg (known: ${ALL_TARGETS[*]})"; exit 2 ;;
  esac
done
[ ${#requested[@]} -eq 0 ] && requested=("${ALL_TARGETS[@]}")

# ── resolve: pull in dependencies of explicitly requested targets ───────────
declare -A want=()
for t in "${requested[@]}"; do
  want[$t]=1
  for d in $(needs_of "$t"); do want[$d]=1; done
done
plan=()
for t in "${ALL_TARGETS[@]}"; do [ -n "${want[$t]:-}" ] && plan+=("$t"); done

ark_platform
gpu=no; ark_has_nvidia_gpu && gpu=yes
ark_log "platform: ${ARK_DISTRO} ${ARK_VERSION_ID} (${ARK_ARCH}) · NVIDIA GPU: ${gpu}"
ark_log "plan: ${plan[*]}"

# ── run ─────────────────────────────────────────────────────────────────────
declare -A status=()   # ok | failed | skipped:<reason>

run_target() {
  local t="$1" cmd; cmd="$(installer_for "$t")"

  if gpu_gated "$t" && [ "$gpu" != yes ]; then
    status[$t]="skipped:no-gpu"; ark_warn "skip ${t}: no NVIDIA GPU"; return
  fi
  for d in $(needs_of "$t"); do
    case "${status[$d]:-}" in
      ok|"") : ;;   # ok, or not in this run (already on the box / ran standalone)
      *) status[$t]="skipped:dep-${d}"; ark_warn "skip ${t}: dependency ${d} did not succeed"; return ;;
    esac
  done

  if [ "$DRY_RUN" -eq 1 ]; then
    ark_log "[dry-run] would run: ${cmd}"; status[$t]="ok"; return
  fi
  ark_log "── ${t} ─────────────────────────────"
  # shellcheck disable=SC2086
  if bash "$here/"${cmd}; then status[$t]="ok"; else status[$t]="failed"; ark_err "${t} failed"; fi
}

if [ "$DRY_RUN" -eq 0 ]; then
  : >"$ARK_REBOOT_FILE"
  ark_log "caching sudo credentials…"; sudo -v
fi

for t in "${plan[@]}"; do run_target "$t"; done

# ── summary ─────────────────────────────────────────────────────────────────
echo
ark_log "summary"
for t in "${plan[@]}"; do printf '  %-8s %s\n' "$t" "${status[$t]:-?}"; done
if [ "$DRY_RUN" -eq 0 ] && [ -s "$ARK_REBOOT_FILE" ]; then
  echo
  ark_warn "REBOOT REQUIRED before the box is fully converged:"
  sed 's/^/    · /' "$ARK_REBOOT_FILE" >&2
  ark_warn "after rebooting, re-run ./install-everything.sh to finish (each step self-skips)."
fi
for t in "${plan[@]}"; do [ "${status[$t]}" = failed ] && exit 1; done
exit 0
