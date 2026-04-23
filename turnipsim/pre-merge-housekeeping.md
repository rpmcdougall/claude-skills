---
name: pre-merge-housekeeping
description: Use when the user says "ready to merge", "do housekeeping", "bundle housekeeping", or is finishing a feature branch and about to open/merge a PR. Bundles checkpoint file + wiki updates + MEMORY.md/CLAUDE.md staleness check into a single docs commit on the CURRENT feature branch, BEFORE the PR is opened or merged. Never runs after merge.
---

# pre-merge-housekeeping skill

Bundle all pre-merge documentation updates into one clean `docs:` commit on the feature branch.

## Preconditions
- Current branch is a feature branch, NOT `main`. If on `main`, stop and tell the user.
- Conversation has enough context to name the topic and summarize what shipped. If not, ask.

## Steps

1. **Topic**: confirm or infer the PR topic slug.
2. **Checkpoint**: invoke the `checkpoint` skill logic to generate `memory/checkpoint-YYYY-MM-DD-<topic>.md`. Do not commit yet — batch with later changes.
3. **Wiki scan**: search `docs/wiki/` for any file mentioning the affected mechanic (e.g. if the PR touches melee, grep for "melee" across `docs/wiki/*.md`). For each hit:
   - Propose concrete edits (especially in `Manual-Testing-Guide.md` — usually gets a new row).
   - Apply edits after user confirmation, or apply directly if the change is a clear addition (new test-plan row).
4. **CLAUDE.md**: re-read it. If phase status, feature list, or current-work line is stale, update it.
5. **MEMORY.md**: diff against what the user actually worked on this session. Update if a claim is now wrong. Archive superseded lines to `memory/history.md` if MEMORY.md is over 200 lines.
6. **Single commit** at the end:

```bash
git add memory/checkpoint-*.md docs/wiki/ CLAUDE.md MEMORY.md memory/history.md 2>/dev/null
git commit -m "$(cat <<'EOF'
docs: <topic> checkpoint + wiki update

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

7. Surface a summary to the user: files touched, what was updated, anything that looked stale but was left alone.

## Rules
- Housekeeping lives on the **feature branch before PR open**, not after merge. This is a hard rule.
- One docs commit, not one per file. Previous behavior of splitting docs across commits was corrected.
- Don't invent content in the checkpoint — pull from conversation context only.
- If nothing in `docs/wiki/` is affected, say so and skip that section; don't force an edit.
