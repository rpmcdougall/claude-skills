---
name: post-merge
description: Use when the user says "PR is merged", "just merged", "PR #N merged", or similar after a feature branch lands. Syncs main, deletes the merged local branch (only if remote confirms merge), then reads the latest checkpoint's "Next pickup" section and suggests the next issue to tackle.
---

# post-merge skill

Close out a merged PR cleanly and propose the next pickup.

## Steps

1. **Verify remote merge** before deleting anything:
   ```bash
   gh pr view <N> --json state,mergedAt
   ```
   If `state` is not `MERGED`, stop and tell the user. Never force-delete an unmerged branch.
2. **Capture current branch name** before switching: `git branch --show-current`.
3. **Sync main**:
   ```bash
   git checkout main
   git pull --ff-only
   ```
4. **Delete the local feature branch**:
   ```bash
   git branch -d <branch>
   ```
   Use `-d` (safe), not `-D`. If git refuses, surface the reason and stop — do not force.
5. **Read latest checkpoint**: `ls -t memory/checkpoint-*.md | head -1`, then read the file. Extract the "Next pickup" section.
6. **Suggest next work**: combine the checkpoint's Next pickup with `gh issue list --state open --limit 10`. Recommend one issue with one sentence of reasoning.

## Rules
- Never `git branch -D` or force-delete — if `-d` fails, something is unmerged and needs investigation.
- Never `git push --force` to main.
- Never `git reset --hard` as part of this flow.
- If the user is on a detached HEAD or in the middle of a rebase, stop and surface that — do not "fix" it silently.
- This skill does NOT run housekeeping — that was supposed to happen before merge via `pre-merge-housekeeping`. If the merged PR has no checkpoint file, flag it.
