# revup — advanced

For the daily loop see [SKILL.md](SKILL.md). This covers the less-common needs.

## Target multiple / non-default base branches — `Branches:`
```
A fix for two branches

Topic: fix
Branches: main, rel1.1
```
Makes one PR per branch. A relative topic may only target a subset of its parent's branches.
CLI equivalent for a one-off: `revup upload --base-branch <name>`.

## Contribute via a fork — you lack push access to the target
Add both remotes (`origin` = upstream, `myfork` = your fork), then:
```
revup --remote-name origin --fork-name myfork upload
```
The PR is created in `origin`; branches are pushed to `myfork`. Note: GitHub can't base a PR
in a different fork, so `Relative:` chains across forks are deferred until the parent merges.

## Collaborate on one PR — `Uploader:`
```
Uploader: teamname
```
Fixes the generated branch name so any teammate can check out and upload to the same PR.
All relative topics in the chain must share the same uploader.

## Branch naming — `Branch-Format:` (tag) or `--branch-format`
`user+branch` (default, never conflicts) · `user` (lets you retarget a PR's base branch) ·
`branch` · `none`.

## PR body source — `--pr-body-source`
`first-commit` (default) · `squashed` (all commit messages in the topic, tags stripped) ·
`template` (repo `PULL_REQUEST_TEMPLATE.md`). For dedicated PR text, make an empty first
commit for the title/body and add `--skip-empty-first-commit` to keep it out of merged history.

## Navigation comments (on by default via flags)
- `--review-graph` — a comment linking every PR in the relative chain, auto-updated.
- `--patchsets` — a table of each upload with per-push diffs, including rebase-aware
  "virtual" diffs that hide upstream churn.

## Squash a topic — `revup restack --squash`
Squashes each topic's commits into one (messages merged, duplicate revup tags combined).
Useful right before a final upload.

## Other handy flags
- `--pre-upload "<cmd>"` — run lint/tests before uploading; abort if the command fails.
- `--create-local-branches` — also create a local branch per PR for testing/debugging.
- `--trim-tags` — strip revup tags from pushed commit messages and the default PR body.
- `--auto-topic` — derive a topic from the first words of untagged commits (fast, but editing
  the title changes the branch).
- `revup cherry-pick` — cherry-pick a topic's commits onto a branch (see `revup cherry-pick -h`).
