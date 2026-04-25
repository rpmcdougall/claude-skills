---
name: checkpoint
description: Use when the user asks to "checkpoint this session", "write a checkpoint", "bundle housekeeping", or references closing out a PR/feature. Generates memory/checkpoint-YYYY-MM-DD-<topic>.md in the turnipsim repo following the project's fixed template (What shipped / Design decisions / Deferred / Board state / Next pickup) and commits it on the current branch.
---

# Checkpoint skill

Write a session checkpoint file for turnipsim, following the project's established template.

## Inputs
- Topic slug (kebab-case, e.g. `shooting-engagements`). Ask the user if not obvious from conversation.
- Optional PR number. Infer from current branch name or recent conversation.

## Steps

1. Resolve today's date in `YYYY-MM-DD` via `date +%Y-%m-%d` (do not guess).
2. Determine the target path: `memory/checkpoint-<DATE>-<topic>.md` at repo root.
3. Before writing, read the most recent existing `memory/checkpoint-*.md` file as a style reference — match its tone, depth, and section headings exactly.
4. Gather material from conversation context. Do NOT invent content — if a section has nothing to say, write "(none)" rather than fabricate.
5. Run `gh issue list --state open --limit 20` to populate the "Board state after" section with currently-open issues.
6. Write the file with these sections (in order):
   - `# Checkpoint — <Topic>` (H1 with human-readable topic)
   - `**Date:** <DATE>` / `**PR:** #<N>` / `**Branch:** <branch>` (metadata block)
   - `## What shipped` — function signatures + key behavior. Reference file paths with line numbers.
   - `## Design decisions` — 1-2 lines each, explain the why.
   - `## Deferred` — what was punted, with linked issue numbers.
   - `## Board state after` — open issues list + any new issues filed this session.
   - `## Next pickup` — concrete suggestion for the next session.
7. Commit on the current branch with a heredoc message:

```bash
git add memory/checkpoint-<DATE>-<topic>.md
git commit -m "$(cat <<'EOF'
docs: <topic> checkpoint

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

## Rules
- Checkpoints live **inside the repo** under `memory/`, not in global `~/.claude/projects/...` memory. Do not confuse the two.
- Never `--amend`. Never `--no-verify`.
- If the current branch is `main`, stop and ask the user — checkpoints ride on the feature branch.
- If the user said "bundle housekeeping" or "ready to merge", defer to the `pre-merge-housekeeping` skill instead of running solo.
