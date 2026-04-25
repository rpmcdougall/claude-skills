---
name: ruleset-diff-audit
description: Use when the user asks to "audit v17 compliance", "check if the code is ruleset-accurate", "ruleset audit for vN", or is preparing for a new ruleset version (v18/v19). Walks engine functions, cross-checks them against rules_export/ PDFs, flags hardcoded constants that should live in game/rulesets/*.json, and produces a checklist feeding into #38 / #72-style audit issues.
---

# ruleset-diff-audit skill

Cross-check `godot/server/game_engine.gd` and `godot/game/` against a specified ruleset version.

## Inputs
- Version: `v17` | `v18` | `v19`.
- Optional scope filter: `melee`, `shooting`, `movement`, `morale`, `all`. Default `all`.

## Steps

1. **List rules**: grep the rules PDF table of contents and the changelist `.txt` files to produce a flat list of rules in scope.
2. **Map to engine**: for each rule, grep `godot/server/game_engine.gd` and `godot/game/` for the implementing function(s).
3. **Map to JSON**: grep `godot/game/rulesets/<version>.json` for the data that parameterizes the rule.
4. **Build the checklist row** for each rule:
   ```
   | Rule | Engine location | JSON-driven? | Matches rules? | Notes |
   |------|------------------|--------------|-----------------|-------|
   | Retreat distance | game_engine.gd:<line> _resolve_retreat() | yes (retreat_base, retreat_token_mult) | yes | — |
   | Panic threshold  | game_engine.gd:<line> _panic_test()     | NO (hardcoded 7) | yes | Move to JSON (#72) |
   ```
5. **Output**:
   - The full table.
   - A "Findings" section grouping: (a) hardcoded constants to extract, (b) rules-code mismatches, (c) rules with no engine coverage.
6. **Offer to file issues** via `file-issue` for each finding, linking to #38 / #72 as the parent audit issue.

## Rules
- Quote the rules text verbatim when flagging mismatches — use the `v17-rule` skill to pull citations with page numbers.
- "JSON-driven? NO" is only a finding if the constant represents a rule parameter. Pure implementation details (MELEE_MAX_BOUTS is a rule cap; array indices are not) need judgment.
- Do not edit engine code as part of this audit — findings feed issues, not PRs.
- If the version has no ruleset JSON yet (e.g. v18 is still playtest), say so and audit what the v18 changelist says should change vs what's currently coded under v17.
