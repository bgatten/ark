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
`claude`, `gh`, `tailscale`, `vscode`, `chrome`, `docker`, `driver`, `nvidia`,
`cuda`, `aws`. The orchestrator maps a target to its installer, dependencies,
and gate.
_Avoid_: package, job.

**Claude target**:
The `claude` target installs Claude Code from Anthropic's signed apt repo (same
`add_apt_repo` dance as `gh`/`docker`), on the `stable` channel. It is a native
binary and does **not** need Node — so `claude` carries no dependency edge.
_Avoid_: claude-code step.

**Node target**:
The `node` target installs Node.js LTS from NodeSource. It exists only to carry
`npx`, which the Claude Code **skills step** needs. It is independent of the
`claude` target.
_Avoid_: nodejs step, npm install.

**Skills step**:
A *manual, per-user* step — not an installer — that adds Matt Pocock's agent
skills to `~/.claude` via `npx skills@latest add mattpocock/skills`. It is
interactive (you select skills, then run the bundled setup), so it stays out of
the orchestrator. Needs the `node` target first. See README.
_Avoid_: skills installer, skills target.

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
