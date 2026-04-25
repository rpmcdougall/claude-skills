---
name: combat-dice-budget
description: Use when the user asks "how many dice for this melee/shooting engagement", "what's the pool size for X", "size the dice pool", or is writing a test/server-side pool allocation. Computes worst-case dice pool for melee bouts, shooting engagements, or return-fire paths given unit stats and model counts, and returns a per-bout + worst-case breakdown.
---

# combat-dice-budget skill

Deterministic dice-pool calculator for combat math.

## Known constants
- `MELEE_MAX_BOUTS = 3` (hard cap, draw-on-cap, no retreat).
- Each model rolls `A` (attacks) dice per bout.
- Each die may be re-rolled once (defense save / to-hit modifier) — multiply by 2 for worst-case.

## Inputs
- Attacker: `(A_atk, models_atk)` — attacks stat + model count.
- Defender: `(A_def, models_def)` — same.
- Mode: `melee` | `shooting` | `return-fire`.

## Formulas

**Melee (bouts with return attacks):**
```
per_bout = (A_atk × models_atk + A_def × models_def) × 2
worst_case = per_bout × MELEE_MAX_BOUTS
```

**Shooting (single volley, no return):**
```
worst_case = A_atk × models_atk × 2
```

**Shooting with return fire:**
```
worst_case = (A_atk × models_atk + A_def × models_def) × 2
```
(Return fire resolves once; no bout loop.)

## Output shape

```
Mode: <mode>
Attacker: A=<A_atk>, models=<models_atk>
Defender: A=<A_def>, models=<models_def>

Per-bout pool: <N>
Worst-case pool: <M>
Dice layout:
  Atk attacks: <models_atk × A_atk> × 2 rerolls = <x>
  Def attacks: <models_def × A_def> × 2 rerolls = <y>
  × bouts: <MELEE_MAX_BOUTS>    (melee only)
  Total: <M>
```

## Rules
- Do NOT invent stats — if the user gives a unit id, read `godot/game/rulesets/v17.json` for the stat block. If not found, ask.
- Worst-case assumes every die consumes its reroll — real combat uses fewer. This number is for upper-bound server pool sizing, not expected consumption.
- Flag if the user's model count exceeds what's reasonable for the unit — suggest they double-check.
