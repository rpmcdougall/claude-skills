# claude-skills

Personal library of [Claude Code](https://docs.claude.com/en/docs/claude-code) skills. Authored here, pulled into individual projects (or `~/.claude/skills/`) as needed.

## Intent

This repo is the **source of truth** for my skills. It is not wired directly into any Claude session — skills only activate once copied or symlinked into a location Claude Code scans:

- `~/.claude/skills/<name>.md` — available in every project.
- `<repo>/.claude/skills/<name>.md` — scoped to a single project, version-controlled with that repo.

Keeping the authoritative copy here means:

- Skills can be version-controlled and reviewed independently of any one project.
- The same skill can be installed into multiple projects without drifting.
- A skill can be iterated on in isolation, then re-pulled into its target(s).

## What a skill is

A Markdown file with YAML frontmatter:

```yaml
---
name: <skill-name>
description: <when to trigger — be specific about phrases Claude should match>
---
```

The body is free-form Markdown instructions addressed to Claude. Skills are invoked either explicitly (`/<name>`) or auto-matched from the description against user messages. See the [Claude Code skills docs](https://docs.claude.com/en/docs/claude-code/skills) for specifics.

## Layout

Skills are grouped by the project or domain they target. One file per skill.

```
claude-skills/
├── README.md              ← this file
├── sql/
│   └── sql_explainer.md   ← layered SQL explainer (Snowflake/Oracle/Databricks)
└── turnipsim/
    ├── doc/               ← briefing + opportunities notes used to author the set
    ├── checkpoint.md
    ├── v17-rule.md
    ├── engine-tests.md
    ├── pre-merge-housekeeping.md
    ├── file-issue.md
    ├── engine-feature-scope.md
    ├── post-merge.md
    ├── combat-dice-budget.md
    ├── ruleset-diff-audit.md
    └── godot-repl.md
```

### `sql/`
Generic skills for working with SQL. Not tied to one project.

- **sql_explainer** — four-layer teaching walk-through of a pasted query (TL;DR → logical execution order → line-by-line → patterns/techniques), with row trace and performance notes.

### `turnipsim/`
Skills for the Turnip28 multiplayer sim (Godot 4.6.2, GDScript, authoritative server). Briefing and opportunity analysis live in `turnipsim/doc/`.

- **checkpoint** — generate and commit `memory/checkpoint-YYYY-MM-DD-<topic>.md` on the current feature branch.
- **v17-rule** — quote a rule verbatim from `rules_export/` PDFs with page numbers; flags v17↔v18 divergence.
- **engine-tests** — headless runner for both `test_game_engine.gd` and `test_runner.gd` with platform-detected Godot path; compact pass/fail summary. Not to be confused with `scripts/test-stack.sh` (manual-play, not tests).
- **pre-merge-housekeeping** — bundle checkpoint + wiki scan + MEMORY.md/CLAUDE.md staleness check into one `docs:` commit, on the feature branch, before PR open.
- **file-issue** — standard-template `gh issue create` (motivation / Scope / Non-goals / Relates to / Phase).
- **engine-feature-scope** — scoping pass for a new engine mechanic: issue read, rules citation, current-state grep, proposed shape, open questions. Stops before coding.
- **post-merge** — sync main, delete merged branch (safe `-d` only), surface the checkpoint's "Next pickup".
- **combat-dice-budget** — worst-case dice pool math for melee bouts, shooting, and return fire.
- **ruleset-diff-audit** — walk engine code against a ruleset version; flag hardcoded constants that should be JSON-driven; feed findings into #38 / #72.
- **godot-repl** — throwaway scratch-script runner for one-off engine checks; auto-deletes.

## Installing skills

Use `bin/install-skill.sh` from the repo root. It symlinks by default (so edits here propagate instantly); pass `--copy` on platforms where symlinks aren't available.

```bash
# One skill, global (~/.claude/skills/):
bin/install-skill.sh checkpoint

# Whole group, into a specific project:
bin/install-skill.sh turnipsim --project /path/to/turnipsim

# By explicit path, with copy instead of symlink, replacing any existing entry:
bin/install-skill.sh turnipsim/checkpoint.md --copy --force

# See what would happen without doing it:
bin/install-skill.sh turnipsim --dry-run --project .

# List what's installed at a target:
bin/install-skill.sh --list --project /path/to/turnipsim

# Remove an installed skill:
bin/install-skill.sh --uninstall checkpoint --project /path/to/turnipsim
```

Flags: `--project PATH` (default `~/.claude/skills/`), `--copy`, `--force`, `--dry-run`, `--uninstall`, `--list`, `--help`.

Targets can be a bare skill name (`checkpoint`), a repo-relative path (`turnipsim/checkpoint.md`), or a group directory (`turnipsim` installs every `*.md` in that folder, skipping `README.md`).

After install, restart Claude Code (or start a new session) so the skill is picked up, then invoke with `/<name>` to confirm it loads.

## Maintaining skills

- **Descriptions are the matching surface.** When a skill misfires or fails to trigger, the fix is almost always in the `description` field — add or remove trigger phrases. The body can be thorough; the description must be precise.
- **One skill, one job.** If a skill's body is growing conditionals ("if X then ... else if Y then ..."), it probably wants to split into two skills with sharper descriptions.
- **Keep rules blocks.** The `## Rules` sections at the end of each skill capture hard-won constraints (e.g., `game/` is pure RefCounted; checkpoints live in-repo; never `--amend`). Don't strip them during cleanup passes — they exist to prevent specific past failure modes.
- **Version-control edits.** Every non-trivial change to a skill should land as its own commit with a conventional message (`feat(turnipsim): add combat-dice-budget skill`, `fix(sql): tighten sql_explainer trigger description`). Reviewable in isolation.
- **Re-verify after editing.** A skill change only takes effect in installed copies. If you edit `turnipsim/checkpoint.md` here but the installed copy was a file-copy (not a symlink), re-copy it. A quick `/<skill> --dry-run`-style invocation confirms the install is current.

## Authoring a new skill

1. Decide scope (project-specific → `<project>/`, cross-cutting → a new top-level dir or `sql/`-style grouping).
2. Write the file with frontmatter (`name`, `description`) + body. Keep the body prescriptive, not explanatory.
3. Make the `description` rich in trigger phrases. Think about the *exact* wording you're likely to use when you want the skill — that's what Claude will match against.
4. Include a `## Rules` block for constraints that aren't obvious from the instructions.
5. Commit.
6. Install it into its target location and invoke once to confirm it matches.
