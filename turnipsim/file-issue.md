---
name: file-issue
description: Use when the user says "file this", "track this", "open an issue for X", "new issue for X", or flags a scope-creep observation that should not go into the current PR. Creates a GitHub issue via gh using the project's standard template (motivation / Scope / Non-goals / Relates to / Phase) and returns the URL.
---

# file-issue skill

File a GitHub issue on the turnipsim repo using the project's consistent body template.

## Inputs
- Title: short, imperative. Ask the user if unclear.
- Motivation: 1-3 sentences. Infer from conversation; ask if thin.
- Scope bullets: what the issue covers.
- Non-goals: what it explicitly doesn't cover (important — prevents scope creep later).
- Relates to: `#N` references for linked issues/PRs.
- Phase: `Phase 4`, `Phase 5`, `Refactor`, `Audit`, etc. Infer from existing issues if unsure.

## Body template

```markdown
## Motivation

<1-3 sentences>

## Scope

- <bullet>
- <bullet>

## Non-goals

- <bullet>

## Relates to

- #<N>

## Phase

<phase label>
```

## Command

```bash
gh issue create --title "<title>" --body "$(cat <<'EOF'
<body>
EOF
)"
```

Return the URL the command prints.

## Rules
- Every out-of-scope observation during a PR becomes an issue, not PR scope creep. Strict rule — if the user describes something that doesn't belong in the current work, offer to file it here.
- Keep Non-goals filled. An empty Non-goals section invites scope drift later.
- Check `gh issue list --state open` for duplicates before filing.
- Never close or comment on issues as a side effect — this skill only creates.
