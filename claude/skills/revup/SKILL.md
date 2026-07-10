---
name: revup
description: Coach the user through revup, the stacked-diff / commit-based PR tool (revup upload / amend / restack). Explains the mental model and hands over the exact commands for creating, stacking, revising, and merging dependent GitHub PRs — the user runs them. Use when the user mentions revup, Topic:/Relative: commit tags, stacked or dependent PRs, "stack this on my PR", uploading or restacking a stack, or splitting work into independently-mergeable PRs.
---

# revup — coach the stacked-PR workflow

revup turns tagged commits into a stack of independently-mergeable GitHub PRs.
**Coach:** explain just enough, then hand the user the exact command — they run
it, not you. Ground every answer in the recipes below.

If `git --version` < 2.43 or revup isn't installed, start with [setup.md](setup.md).
For forks, multi-branch, collaboration, and config, see [advanced.md](advanced.md).

## Mental model (share this with a new user first)

- A **topic** is one PR. `Topic: name` in a commit message creates/updates that PR.
- Several commits with the same topic = one PR; they need **not** be adjacent in history.
- `Relative: other-topic` makes this PR **stack on** that one (targets its branch).
- revup PRs target the **real base branch** (`main`), so each merges on its own through
  normal GitHub/CI — no special merge order or tooling.
- revup never touches your working tree; it builds and pushes branches in the background.
- A PR's title/body come from the **first commit** of its topic.
- Pull with `git pull --rebase` only — never a merge commit.

## Recipes (map the user's goal to a command)

**Make N independent PRs** — one topic per change:
```
git commit -m "Add foo" -m "Topic: foo"
git commit -m "Add bar" -m "Topic: bar"
revup upload
```

**Stack a PR on another** — add `Relative:`:
```
git commit -m "More foo" -m "Topic: foo2" -m "Relative: foo"
revup upload
```
If the whole stack is dependent, skip the tags: `revup upload --relative-chain`.

**Revise a PR mid-stack** — stage the fix, amend by topic (or commit), re-upload:
```
git add -p
revup amend foo --no-edit        # or: revup amend HEAD~2
revup upload
```
`revup amend` reapplies later commits without touching the working tree (faster than
`git rebase -i`). Also valid: just add a new commit carrying the same `Topic:`.

**Add reviewers / labels / draft** — tags on any commit in the topic:
```
Reviewers: alice, myorg/backend-team
Labels: bug, draft               # "draft" toggles PR draft state
```

**Pull in main** — rebase, don't merge:
```
git pull --rebase
revup upload --rebase            # --rebase forces re-push even if only rebased
```

**Reorder / group the stack** — `revup restack` groups commits by topic in the history.

**Preview without pushing** — `revup upload --dry-run` (or `--status` to just show PR state).

## Conflicts

On a cherry-pick/amend conflict, revup prints the conflicting paths and **exits without
changing anything** — there is no interactive resolve. Fix by adjusting `Relative:` ordering
so each topic sits on the branch it actually depends on, then re-upload.

## Confirm step

`revup upload` prints the planned topics and asks to confirm; `-s`/`--skip-confirm` skips it.
The first-ever run needs a GitHub token — see [setup.md](setup.md).
