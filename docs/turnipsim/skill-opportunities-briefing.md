# Briefing — Implementing the Turnip28 Sim Skills

Companion document to `skill-opportunities.md`. If you are an agent tasked with building the skills described there, read this first. None of this context is in `skill-opportunities.md` itself.

---

## 1. What a Claude Code skill actually is

A skill is a Markdown file that adds instructions to Claude's prompt when triggered. It is not executable code.

**Locations (Claude Code looks in both):**
- `~/.claude/skills/<name>.md` — global, available in every project.
- `<repo>/.claude/skills/<name>.md` — project-scoped, version-controlled with the repo.

**Frontmatter:**
```yaml
---
name: checkpoint
description: Use when the user asks to write a session checkpoint, bundle pre-merge housekeeping, or close out a PR. Generates memory/checkpoint-YYYY-MM-DD-<topic>.md following the project template.
---
```

- `description` is the matching surface. Claude uses it to decide whether to invoke the skill on a given user message. Be specific about trigger phrases (`"bundle housekeeping"`, `"ready to merge"`, etc.). Vague descriptions produce missed invocations or false positives.
- The skill body is free-form Markdown instructions addressed to Claude — tell it what to do, what files to touch, what patterns to follow.

**Invocation:**
- User types `/name` as a slash command (explicit), or
- User writes a message matching the skill's description and Claude auto-invokes it via the `Skill` tool.

**Only invoke a skill that appears in the available-skills list of the current session.** Don't invent skill names from training data.

---

## 2. Project shape (what you're building against)

Turnip28 Simulator — a Godot 4.6.2 multiplayer wargame sim in GDScript. Server-authoritative over ENet.

```
godot/
├── entry.tscn              # Main scene, branches on NetworkManager.is_server
├── autoloads/              # NetworkManager
├── game/                   # PURE LOGIC — no Node, no scene tree, no signals
│   ├── types.gd            # Stats, UnitDef, Roster, UnitState, GameState
│   ├── ruleset.gd          # Loads + validates ruleset JSON
│   └── rulesets/v17.json
├── server/                 # game_engine.gd (the big one), network_server.gd
├── client/                 # scenes/{menu,lobby,battle,roster_builder}
└── tests/                  # test_runner.gd (types), test_game_engine.gd (engine)
```

**Hard rules that affect skill design:**
- **`game/` is pure RefCounted.** Never reach into Node, scene tree, or signals from `game_engine.gd`, `types.gd`, or anything under `game/`. Any skill that edits engine code must preserve this contract.
- **Rulesets are data-driven.** `game/rulesets/v17.json` holds the rules data; engine logic stays singular. When a new rule comes in, prefer a JSON schema extension over hardcoding.
- **Runtime mode detection.** `--server` CLI arg or `dedicated_server` feature tag flips the mode. Server and client run from the same project.
- **`scripts/test-stack.sh` launches a manual play stack** (headless server + windowed clients). It is **not** a unit-test runner — confusing the two is a common mistake.

---

## 3. Workflow conventions the skills should respect

### Commits
- **Conventional commits:** `<type>(<scope>): <description>` — `feat`, `fix`, `test`, `docs`, `refactor`, `chore`.
- **Modular commits.** One logical unit per commit. A feature lands as several commits (engine → server → tests → docs), not one mega-commit. The user is strict about this.
- **`Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>` trailer** on every commit.
- Pass multi-line commit messages via heredoc, not string concatenation.
- Never `--amend` unless explicitly asked. New commit > amend.
- Never `--no-verify` unless explicitly asked.

### Branches + PRs
- Feature branches named `feature/<topic>` or `fix/<topic>`. Branch off `main`.
- Push and open PR via `gh pr create` with a body that includes Summary, Test plan, and Explicitly-not-in-this-PR sections.
- The user merges PRs themselves. After merge: sync main, delete local branch, suggest next pickup. Never force-push to `main`.

### Memory + checkpoints
- Global memory lives in `~/.claude/projects/<project-hash>/memory/MEMORY.md` and sibling files. Each line in `MEMORY.md` points to a memory file with frontmatter.
- Session checkpoints live **in the repo** at `memory/checkpoint-YYYY-MM-DD-<topic>.md`. These are committed.
- The checkpoint template recurs (see `memory/checkpoint-2026-04-22-shooting-engagements.md` for a good example):
  - What shipped (function signatures + key behavior)
  - Design decisions (why, in 1-2 lines each)
  - Deferred (what was punted and to which issue)
  - Board state after (new issues filed, sequencing of open work)
  - Next pickup
- Pre-merge housekeeping bundles checkpoint + wiki update + MEMORY.md fixes on the same branch, **before** PR open. Not after merge.

### Issues
- Every out-of-scope observation becomes a GitHub issue, not PR scope creep. Strict rule.
- Issue body template: motivation / Scope bullets / Non-goals / Relates to / Phase.
- File via `gh issue create --title ... --body "$(cat <<'EOF' ... EOF )"`.

---

## 4. Tooling the skills will shell out to

### Godot binaries
Detect platform:
- **Windows (Git Bash / MSYS):** `/c/tools/Godot/Godot_v4.6.2-stable_win64.exe`
- **macOS:** `/Applications/Godot.app/Contents/MacOS/Godot`
- **Linux:** not set up in this repo.

### Test commands
```bash
# Engine tests (~103 tests as of 2026-04-22)
$GODOT --headless --path godot -s tests/test_game_engine.gd

# Type tests (19 tests)
$GODOT --headless --path godot -s tests/test_runner.gd
```

Both runners print a summary ending with `Passed: N / Failed: M`. Parse those lines for the `engine-tests` skill's output.

### GitHub CLI
- `gh issue view <n>` — read issue.
- `gh issue list --state open` — scan open work.
- `gh issue create --title ... --body ...` — file.
- `gh pr create --title ... --body ...` — open PR.
- `gh api repos/<owner>/<repo>/pulls/<n>/comments` — read PR comments.
- Auth is already set up in the user's environment.

### PDF reading
`rules_export/` contains:
- `Turnip28 V17 Core Rules For Print-2.pdf` — v17 core (current authoritative ruleset).
- `Turnip28_V18_Core Rules_PLAYTEST.pdf` — v18 playtest (may skip to v19).
- `Change list v17.txt` and `TURNIP CORE RULES v18 CHANGELIST.txt` — plain-text change logs, fast to grep.

**The Read tool can read PDFs.** For large PDFs, you must pass a `pages` parameter (e.g. `pages: "20"`). Without it, reads fail on docs >10 pages. Prefer grepping the change-list text files first to locate the right page.

---

## 5. What's already known that a skill doesn't need to rediscover

### Live facts (as of 2026-04-22)
- Engine combat mechanics done: panic test (#52), retreat with `D6 + 2×tokens` (#53 + #73 fix), melee bouts (#55), shooting engagements with return fire (#40). See recent checkpoint files for details.
- Phase 4 is close to rules-complete. Open combat items: #54 stand-and-shoot, #56 LoS + closest-target, #58 terrain, #59 scenarios.
- Refactor tracked in #65 (large files: game_engine.gd ~1600 lines, test_game_engine.gd ~1500 lines, battle.gd ~1135 lines).
- Ruleset-version agility audit tracked in #72 (pre-v19 prep).

### Stable decisions
- **Euclidean distance on integer grid** for all range/movement checks (`sqrt(dx² + dy²)`, 1 cell = 1 inch). Range visualizations are circles, not diamonds.
- **Dependency injection for dice** in combat: pre-rolled dice pool passed into engine, sized by server. Engine functions return dice-used counts for audit. Do not switch to `Callable` injection — that pattern was considered and rejected.
- **MELEE_MAX_BOUTS = 3** hard cap with draw-on-cap (no retreat).
- **gl_compatibility renderer** (no Vulkan requirement).

### Existing skill templates in this session
- Several broad skills (`update-config`, `simplify`, `review`, `security-review`, `init`) are already shipped with Claude Code and visible in the available-skills list. Look at their descriptions as a style reference — short, trigger-oriented, explicit about what they do and don't do.

---

## 6. How to pick the first skill to build

`skill-opportunities.md` ends with a suggested build order. Honor it unless the user says otherwise:

1. `checkpoint` — highest frequency, simplest shape, lowest risk.
2. `v17-rule` — biggest single productivity win.
3. `engine-tests` — trivial to build, used every session.

Build one skill end-to-end (skill file + a dry-run to confirm invocation) before batching more. Do not author all 10 skills in one pass.

---

## 7. What will go wrong if you skip this briefing

- Skills invoking `scripts/test-stack.sh` thinking it's the test runner (it isn't).
- Checkpoints written in the wrong directory (MEMORY.md lives outside the repo; checkpoints live inside).
- Commit messages missing the `Co-Authored-By` trailer.
- PR bodies lacking "Explicitly not in this PR" — this is how the project tracks deferred work.
- Skills stomping on the `game/` no-node contract by proposing signal-based refactors.
- Rules lookups going to `rules_export/*.txt` when the answer is in the PDFs, or vice versa.

Read `memory/checkpoint-2026-04-22-shooting-engagements.md` for a worked example of the conventions end-to-end.
