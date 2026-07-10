# revup setup

One-time, per machine. revup needs **git ≥ 2.43** and **python ≥ 3.8**.

## 1. Upgrade git (Ubuntu 22.04 ships 2.34 — too old)

```
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt-get update && sudo apt-get install -y git
git --version        # expect >= 2.43
```

## 2. Install revup

```
python3 -m pip install revup
revup -h             # verify
```

## 3. Authenticate to GitHub

Create a Personal Access Token with **repo** scope:
<https://github.com/settings/tokens/new?scopes=repo>

```
revup config forge_oauth
# paste the token at the prompt
```
GitHub Enterprise: add `--forge-url your.host` (or set `forge_url` in config).

## 4. Recommended git config (rebase-based pulls)

Add to `~/.gitconfig` so pulls rebase and auto-stash instead of making merge commits:
```
[pull]
    rebase = true
[rebase]
    autoStash = true
```

## 5. Per-repo config (only if `main` isn't the base, or there are release branches)

Commit a `.revupconfig` at the repo root:
```
[revup]
main_branch = master
base_branch_globs =
    rel[1-9].[0-9]
    rel[1-9].[0-9][0-9]
```

**Config precedence** (highest first): command-line flags → `.git/.revupconfig`
(per-checkout, untracked) → repo-root `.revupconfig` (shared) → `~/.revupconfig` (user).
Any flag is also a config key — e.g. to always skip the confirm prompt, put in `~/.revupconfig`:
```
[upload]
skip_confirm = True
```

## Practice safely

Don't learn on real PRs — creating test PRs is spammy. Fork revup (or any repo you own)
and walk revup's own tutorial: <https://github.com/Skydio/revup#tutorial>
