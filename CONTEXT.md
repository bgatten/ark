# ark

Provisioning scripts for bringing up a fresh Linux box (a robotics/GPU dev
machine). This file fixes the vocabulary so future architecture reviews and
contributors use the same words.

## Language

**Orchestrator**:
The single entry point (`install-everything.sh`) that decides which installers
run, in what order, and what happens when one fails. Holds the dependency edges
and the GPU gate; runs no installs itself.
_Avoid_: master script, runner, main.

**Installer**:
A standalone, re-runnable script that sets up one piece of the box
(`setup_docker.sh`, `cuda-install.sh`, …). Carries its own "already done?"
probe so it is safe to run alone or via the orchestrator.
_Avoid_: module (too generic here), step, task.

**Target**:
The name a caller uses to ask for an installer — `base`, `devtools`, `node`,
`claude`, `claude-config`, `gh`, `tailscale`, `vscode`, `chrome`, `docker`,
`driver`, `nvidia`, `cuda`, `aws`. The orchestrator maps a target to its
installer, dependencies, and gate.
_Avoid_: package, job.

**Claude target**:
The `claude` target installs Claude Code from Anthropic's signed apt repo (same
`add_apt_repo` dance as `gh`/`docker`), on the `stable` channel. It is a native
binary and does **not** need Node — so `claude` carries no dependency edge.
_Avoid_: claude-code step.

**Node target**:
The `node` target installs Node.js LTS from NodeSource. It exists only to carry
`npx`, which the `claude-config` target's skills step needs. It is independent
of the `claude` target.
_Avoid_: nodejs step, npm install.

**Claude-config target**:
The `claude-config` target makes a box's Claude Code match every other box. It
symlinks `~/.claude/CLAUDE.md` and `~/.claude/settings.json` to the canonical
copies in `claude/` — single source of truth, edit once and pull anywhere — and
installs the personal agent skills listed in `claude/skill-lock.json`
non-interactively (`npx skills@latest add <source> -y -a claude-code -s …`,
grouped by source). `settings.json` carries the plugin + marketplace list, so
Claude Code reinstalls the plugin skills itself. Depends on `claude` (the app it
configures) and `node` (the `npx` runtime).
_Avoid_: dotfiles step, config installer.

**Skills step**:
Now part of the `claude-config` target and automated — *not* the manual,
interactive step it once was. A skill list read from the lockfile plus `-y`
makes `npx skills@latest add` run unattended, so it belongs in the orchestrator.
Needs the `node` target for `npx`.
_Avoid_: skills installer (as a separate target), manual skills step.

**Driver target**:
The `driver` target picks the NVIDIA driver from the GPU's PCI device id
(10de:XXXX), not its lspci name — the id range is always present even when the
pci.ids name DB is stale. Ada → `nvidia-driver-550`, Blackwell →
`nvidia-driver-575-open` (open modules mandatory), everything else →
`ubuntu-drivers autoinstall`. GPU-gated; `nvidia` depends on it.
_Avoid_: gpu driver step, video driver.

**Platform module**:
`ark_platform` in `lib.sh` — the one place that answers "what box is this?"
(`ARK_DISTRO`, `ARK_VERSION_ID`, `ARK_CODENAME`, `ARK_REPO_ID`, `ARK_ARCH`).
Replaces the three ad-hoc distro/arch detections the installers used to carry.
_Avoid_: env detection, os helper.

**Probe**:
A read-only check of the live system that decides whether an installer's work
is already done (`have docker`, `dpkg -s …`, `nvcc --version`). The machine is
the source of truth — not marker files.
_Avoid_: state check, flag.

**GPU gate**:
`ark_has_nvidia_gpu` — probes the *hardware* (via `lspci`), so GPU targets are
gated correctly on a fresh box before any driver exists.
_Avoid_: gpu check, driver check (it deliberately is not a driver check).

**Dependency edge**:
A "needs" relation between targets the orchestrator enforces (e.g. `nvidia`
needs `docker`). A failed or absent dependency skips its dependents; independent
targets still run.
_Avoid_: requirement, prerequisite.

**Operational tool**:
A script that operates an already-provisioned box rather than setting one up —
`source_cuda.sh` (switch active CUDA version per shell), `enable_x11_for_orin_container.sh`
(configure X11 on a remote Orin). Out of the orchestrator's scope.
_Avoid_: installer, setup script.

## Example dialogue

> **Dev:** Adding `cuda` to a box with no card — does it just fail?
> **Ben:** No. `cuda` is GPU-gated, so the **GPU gate** probes the hardware with
> `lspci`; no card means the **orchestrator** skips that **target** and reports
> it. Nothing errors.
> **Dev:** And if I run `nvidia` but docker isn't there?
> **Ben:** The orchestrator pulls docker in — there's a **dependency edge**
> `nvidia → docker`. If docker's **installer** then fails, nvidia is skipped, but
> `aws` still runs. Re-run later and every installer's **probe** self-skips what's
> already done.
