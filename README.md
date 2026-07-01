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
| `node`     | Node.js LTS (NodeSource)                                       | standalone `npx`/`npm` runtime |
| `claude`   | Claude Code (Anthropic apt repo, `stable` channel)            | native binary; no Node needed |
| `claude-config` | CLAUDE.md + settings.json symlinks into ark; vendored agent skills | shared Claude config across machines; needs `claude` |
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
[`claude/`](claude/) — edit once, commit, pull anywhere — and copies the personal
agent skills **vendored** in [`claude/skills/`](claude/skills/) into
`~/.claude/skills` ([Matt Pocock's](https://github.com/mattpocock/skills) plus
[Vercel's](https://github.com/vercel-labs/skills) `find-skills`). `settings.json`
also carries the plugin + marketplace list (superpowers, karpathy, skill-creator),
so Claude Code installs its plugin skills on first launch.

```bash
./install-everything.sh claude-config   # pulls in `claude` first
```

The skills are vendored — real files committed to the repo — not refetched by
name from upstream. Upstream skill repos rename and remove skills; a name-based
reinstall fails the whole batch on the first mismatch. Vendoring makes ark the
source of truth: drift-proof and offline, and it drops the `node`/`npx`
dependency. To change the skill set, edit your skills the usual way, then copy
`~/.claude/skills` into `claude/skills/` and commit.

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
