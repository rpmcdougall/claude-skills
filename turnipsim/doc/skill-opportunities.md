# Skill Opportunities — Turnip28 Simulator

Patterns in this repo that recur often enough to warrant dedicated skills. Each entry is sized for a single-purpose `~/.claude/skills/<name>.md` skill definition.

---

## 1. `v17-rule` — Look up an exact rule from the v17/v18 PDFs

**Trigger:** user asks "what does v17 say about X", "look up the melee bout rule", or code review needs a verbatim rules citation.

**Why it matters:** we've repeatedly opened the `rules_export/` PDFs to confirm distances, thresholds, and edge cases (retreat distance D6+2×tokens, Fearless override, bout structure). Each lookup is slow and breaks flow.

**Behavior:**
- Search `rules_export/` for the requested rule (grep the change lists first for context, then page-range-read the relevant PDF).
- Return the quoted rules text plus page number.
- Flag if v17 and v18 playtest differ.

---

## 2. `checkpoint` — Write a session checkpoint file

**Trigger:** "checkpoint this session", "bundle housekeeping", or pre-merge flow.

**Why it matters:** every merged PR so far has a `memory/checkpoint-YYYY-MM-DD-<topic>.md` following a fixed template (What shipped / Design decisions / Deferred / Board state / Next pickup). Writing the frame by hand each time wastes tokens.

**Behavior:**
- Pull topic + PR number from arguments or context.
- Generate the checkpoint with today's date, populated headings, and the recurring "Board state after" section (open issues, new issues this session).
- Commit on the current branch with a consistent `docs: <topic> checkpoint + wiki update` message.

---

## 3. `pre-merge-housekeeping` — Bundle checkpoint + wiki + memory updates

**Trigger:** user says "ready to merge", "do housekeeping", or similar.

**Why it matters:** memorized feedback already captures the rule — housekeeping lives on the feature branch, not after. A skill automates: checkpoint file, wiki Manual-Testing-Guide row, CLAUDE.md phase-status check, MEMORY.md update if warranted, then a single docs commit.

**Behavior:**
- Prompt for or infer the PR topic.
- Run the checkpoint skill.
- Scan `docs/wiki/` for files that mention the affected mechanic and propose edits.
- Diff MEMORY.md and CLAUDE.md for stale claims.
- One clean `docs:` commit at the end.

---

## 4. `engine-feature-scope` — Kick off a new engine mechanic

**Trigger:** "let's start #N", "scope issue X", or branching from main for combat work.

**Why it matters:** every engine feature (panic, retreat, melee bouts, shooting engagements) followed the same opening flow: read the issue, grep current engine behavior, propose the shape, list open design questions, list dependencies, recommend a default. The checklist is identical; only the subject changes.

**Behavior:**
- Read the issue via `gh issue view N`.
- Grep relevant engine functions.
- Produce: current state summary / rules requirements / proposed shape / open questions / scope boundary / branch name suggestion.
- Do not start coding until the user confirms.

---

## 5. `file-issue` — File a consistently structured GitHub issue

**Trigger:** "file this", "track this", "new issue for X".

**Why it matters:** every issue we've filed this session (#64–#70, #72, #74) shares a structure: short motivation / Scope bullets / Non-goals / Relates to / Phase. Doing it by hand each time risks drift.

**Behavior:**
- Prompt for or infer the title + motivation.
- Produce a body with the standard sections.
- `gh issue create` with the filled template.
- Return the URL.

---

## 6. `engine-tests` — Run the headless engine + type test suites

**Trigger:** "run tests", "run the suite".

**Why it matters:** the actual commands are `$GODOT --headless --path godot -s tests/test_runner.gd` and `.../test_game_engine.gd`, with Godot path varying per platform. `scripts/test-stack.sh` is manual-play, not tests — easy to confuse. A skill codifies the platform detection and returns a pass/fail summary instead of full output.

**Behavior:**
- Detect platform (Windows `C:\tools\Godot\...` vs macOS `/Applications/Godot.app/...`).
- Run both suites.
- Report `<engine> engine + <types> type = <total> total, <failures> failing`.
- If failures: show only the FAIL lines.

---

## 7. `melee-dice-budget` (or `combat-dice-budget`) — Compute worst-case dice pool

**Trigger:** "how many dice for this melee", "what's the pool size".

**Why it matters:** we've computed `(A_atk × models + A_def × models) × 2 × MAX_BOUTS` by hand repeatedly when writing tests or sizing server pools. Easy to get wrong. A deterministic calculator would remove the guesswork.

**Behavior:**
- Accept two unit stat tuples (or unit ids + state context).
- Return: per-bout pool, worst-case pool, dice layout diagram.
- Covers melee bouts, shooting engagements, return-fire paths.

---

## 8. `ruleset-diff-audit` — Cross-check engine code against a ruleset version

**Trigger:** "audit v17 compliance", "is the code ruleset-accurate".

**Why it matters:** #38 and #72 are long-running audit issues. Doing the audit once produced gaps (retreat D6, melee bouts, shooting engagements). A skill-ified version makes re-auditing for v18/v19 cheap when those drop.

**Behavior:**
- Walk engine functions that implement a rule (match against `rules_export/` quotes).
- Flag hardcoded constants that aren't in `game/rulesets/*.json`.
- Produce a checklist of {rule, engine location, JSON-driven?, matches rules?}.
- Feed findings into #38-style audit issues.

---

## 9. `post-merge` — Close out a merged PR

**Trigger:** user says "PR is merged", "just merged".

**Why it matters:** every merge so far has been followed by: `git checkout main && git pull && git branch -d <branch>`, then a "next pickup" suggestion based on the checkpoint. Already half-automated manually; worth codifying.

**Behavior:**
- Sync main, delete the just-merged branch (only if already merged remotely).
- Read the latest checkpoint's "Next pickup" section.
- Suggest the next issue with reasoning.

---

## 10. `godot-repl` — Run a one-off snippet of GDScript against the engine

**Trigger:** "check what X returns", "quick sanity check of this function".

**Why it matters:** we've fabricated full tests just to verify small behaviors (e.g., does `_can_return_fire` behave correctly with wr=0). A scratch-runner would be faster.

**Behavior:**
- Write a temp `tests/scratch_*.gd` extending SceneTree.
- Execute it headless.
- Delete it after.
- Surface only printed output + exit code.

*This one is lower-priority — the test suite is already fast and leaving scratch files around is a lint hazard. File only if it comes up repeatedly.*

---

## Not worth a skill (considered, rejected)

- **Commit message formatter** — conventional commits are simple enough; shell heredocs work.
- **Issue priority sort** — the project board already does this.
- **PR description writer** — the PR template is short and varies by PR; too much bespoke.

---

## Suggested build order

1. `checkpoint` — highest-frequency use, simplest to build.
2. `v17-rule` — biggest single productivity win (PDF reads are slow).
3. `engine-tests` — trivial, used every session.
4. `pre-merge-housekeeping` — composes `checkpoint` + wiki scan; build after those two.
5. `file-issue` — useful once the structure is stable enough to template.
6. `engine-feature-scope` — meatier, more judgment required; build when the pattern feels fully stable.
7. `post-merge` — nice-to-have.
8. `combat-dice-budget` — narrow but helpful.
9. `ruleset-diff-audit` — most ambitious; wait until v18 or v19 decision is live.
10. `godot-repl` — only if scratch-runs become frequent.
