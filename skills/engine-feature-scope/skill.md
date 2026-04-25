---
name: engine-feature-scope
description: Use when the user says "let's start #N", "scope issue X", "begin work on issue N", or is branching from main to start a new engine mechanic (panic, retreat, melee, shooting, etc.). Reads the issue, greps current engine state, produces a scoping document (current state / rules requirements / proposed shape / open questions / scope boundary / branch name). Does NOT start coding — waits for user confirmation.
---

# engine-feature-scope skill

Open a new engine mechanic with a consistent scoping pass before any code is written.

## Steps

1. **Read the issue**: `gh issue view <N>` — capture title, body, linked issues.
2. **Pull rules**: if the issue references a v17 mechanic, invoke the `v17-rule` skill logic to quote the exact rules text with page numbers.
3. **Grep current engine**: search `godot/server/game_engine.gd` and `godot/game/` for functions related to the mechanic. Report what exists today and what is missing.
4. **Check ruleset data**: inspect `godot/game/rulesets/v17.json` for any fields that already encode this rule. Flag hardcoded constants that should move into JSON.
5. **Produce the scoping doc** (inline reply, not a file):
   - **Current state** — what the engine does today.
   - **Rules requirements** — quoted from PDFs, cite pages.
   - **Proposed shape** — function signatures + data flow. Respect the pure-RefCounted contract for `game/`.
   - **Open questions** — each one with a recommended default answer.
   - **Scope boundary** — explicit "in this PR" / "not in this PR" lists.
   - **Branch name** — `feature/<slug>` suggestion.
6. **Stop and wait for user confirmation.** Do not create the branch, edit code, or run tests until the user signs off on the shape.

## Rules
- `game/` is pure RefCounted — no Node, no signals, no scene tree access. Any proposed shape that violates this is wrong; reject it at scoping time.
- Dice injection stays: engine receives pre-rolled pools and returns dice-used counts. Do not propose `Callable` injection — that was considered and rejected.
- Prefer JSON ruleset extension over hardcoded constants.
- Out-of-scope observations become issues via `file-issue`, not PR scope creep.
- Euclidean distance on integer grid for all range/movement (1 cell = 1 inch).
