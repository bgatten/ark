# ark

Provisioning scripts for bringing up a fresh Linux box — a robotics / GPU dev
machine on Ubuntu. One orchestrator decides *what* runs and *in what order*;
each installer is standalone, re-runnable, and self-skips work that's already
done. See [CONTEXT.md](CONTEXT.md) for the precise vocabulary.

## Quick start

Git is the only prerequisite:

```bash
sudo apt-get install -y git
git clone <this-repo> ark && cd ark
./install-everything.sh            # auto: every applicable target
```

GPU targets self-gate: on a box with no NVIDIA card they're skipped, not
failed. Some targets (driver, group membership) leave the box needing a reboot
— the orchestrator says so at the end. Re-run `./install-everything.sh` after
rebooting; every step self-skips what's already in place.

## Usage

```bash
./install-everything.sh                 # every applicable target
./install-everything.sh docker cuda     # just these (dependencies pulled in)
./install-everything.sh --dry-run       # print the plan, run nothing
./install-everything.sh -h              # help
```

Each installer also runs on its own — `./install_claude.sh`,
`./setup_docker.sh`, etc. — and carries its own "already done?" probe, so
running it standalone is safe.

## Targets

| Target     | Installs                                                        | Notes |
|------------|----------------------------------------------------------------|-------|
| `base`     | htop, foxglove-studio                                          | every box |
| `devtools` | C++ toolchain (build-essential, ninja, ccache, gdb, …); recent cmake from Kitware | |
| `node`     | Node.js LTS (NodeSource)                                       | carries `npx` for the `claude-config` skills step |
| `claude`   | Claude Code (Anthropic apt repo, `stable` channel)            | native binary; no Node needed |
| `claude-config` | CLAUDE.md + settings.json symlinks into ark; personal agent skills | shared Claude config across machines; needs `claude` + `node` |
| `gh`       | GitHub CLI                                                     | |
| `tailscale`| Tailscale VPN                                                 | |
| `vscode`   | VS Code (Microsoft apt repo)                                  | |
| `chrome`   | Google Chrome (Google apt repo)                               | |
| `docker`   | Docker Engine                                                 | |
| `driver`   | NVIDIA driver, chosen from the GPU's PCI device id            | GPU-gated |
| `nvidia`   | NVIDIA Container Toolkit                                      | GPU-gated; needs `docker` + `driver` |
| `cuda`     | CUDA toolkit (12.4) + dkms                                    | GPU-gated |
| `aws`      | AWS CLI v2 (install only; `configure` is a separate opt-in step) | |

Updates ride the normal `apt upgrade` path — apt-installed targets, including
Claude Code on the `stable` channel, don't self-update.

## Claude Code config + skills (`claude-config`)

The `claude-config` target keeps every box's Claude Code identical. It symlinks
`~/.claude/CLAUDE.md` and `~/.claude/settings.json` to the canonical copies in
[`claude/`](claude/) — edit once, commit, pull anywhere — and installs the
personal agent skills pinned in `claude/skill-lock.json`
([Matt Pocock's](https://github.com/mattpocock/skills) plus
[Vercel's](https://github.com/vercel-labs/skills) `find-skills`) for Claude
Code, non-interactively. `settings.json` also carries the plugin + marketplace
list, so Claude Code reinstalls its plugin skills on its own.

```bash
./install-everything.sh claude-config   # pulls in `claude` + `node` first
```

It depends on `claude` (the app) and `node` (for the skills CLI's `npx`), so the
orchestrator runs those first. The skills step self-skips if `npx` or `python3`
is missing — install them and re-run. To change the skill set, edit it with
`npx skills@latest add|remove …`, refresh `claude/skill-lock.json`, and commit.

## Operational tools

Not part of the orchestrator — these operate an already-provisioned box:

- `source_cuda.sh <version>` — switch the active CUDA version for the current
  shell (`source source_cuda.sh 12.2`).
- `enable_x11_for_orin_container.sh` — configure X11 forwarding for a container
  on a remote Orin.

## Layout

- `install-everything.sh` — the orchestrator (target registry, ordering, GPU
  gate, dependency edges, failure policy).
- `lib.sh` — shared library: logging, platform detection (`ark_platform`), the
  `add_apt_repo` dance, the GPU gate, the reboot signal. Source it; don't run it.
- `install_*.sh` / `setup_*.sh` / `*-install.sh` — one installer per target.
- `CONTEXT.md` — the project vocabulary.
