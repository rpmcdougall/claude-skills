# claude-skills

Personal library of [Claude Code](https://docs.claude.com/en/docs/claude-code) skills. Each skill is a self-contained package with metadata, installable into any project or globally.

## Layout

Each skill lives in its own directory under `skills/`, with a standardized structure:

```
skills/<name>/
├── manifest.json   ← metadata (description, group, tags, version)
└── SKILL.md        ← the skill itself (YAML frontmatter + Markdown body)
```

The full repo:

```
claude-skills/
├── README.md
├── bin/
│   ├── install-skill.sh      ← install/uninstall/list skills
│   └── build-registry.sh     ← regenerate skills/registry.json
├── docs/
│   └── turnipsim/            ← authoring notes (not skills)
└── skills/
    ├── registry.json          ← auto-generated index of all skills
    ├── checkpoint/
    ├── combat-dice-budget/
    ├── engine-feature-scope/
    ├── engine-tests/
    ├── file-issue/
    ├── godot-repl/
    ├── post-merge/
    ├── adversarial-code-reviewer/
    ├── agile-project-manager/
    ├── pre-merge-housekeeping/
    ├── ruleset-diff-audit/
    ├── senior-software-engineer/
    ├── sql-explainer/
    └── v17-rule/
```

## Skill groups

### `sql`
Generic skills for working with SQL. Not tied to one project.

- **sql-explainer** — four-layer teaching walk-through of a pasted query (TL;DR → logical execution order → line-by-line → patterns/techniques), with row trace and performance notes.

### `roles`
Technical role personas. Activate to shift Claude's perspective for a specific job function.

- **senior-software-engineer** — senior/staff SWE lens for architecture, code quality, trade-off analysis, and production readiness.
- **adversarial-code-reviewer** — hostile code review targeting bugs, security holes, race conditions, edge cases, and silent failures.
- **agile-project-manager** — pragmatic agile PM for sprint planning, story writing, backlog grooming, estimation, and retros.

### `turnipsim`
Skills for the Turnip28 multiplayer sim (Godot 4.6.2, GDScript, authoritative server).

- **checkpoint** — generate and commit `memory/checkpoint-YYYY-MM-DD-<topic>.md` on the current feature branch.
- **v17-rule** — quote a rule verbatim from `rules_export/` PDFs with page numbers; flags v17↔v18 divergence.
- **engine-tests** — headless runner for test suites with platform-detected Godot path; compact pass/fail summary.
- **pre-merge-housekeeping** — bundle checkpoint + wiki scan + MEMORY.md/CLAUDE.md staleness check into one `docs:` commit before PR open.
- **file-issue** — standard-template `gh issue create` (motivation / Scope / Non-goals / Relates to / Phase).
- **engine-feature-scope** — scoping pass for a new engine mechanic: issue read, rules citation, current-state grep, proposed shape, open questions.
- **post-merge** — sync main, delete merged branch (safe `-d` only), surface the checkpoint's "Next pickup".
- **combat-dice-budget** — worst-case dice pool math for melee bouts, shooting, and return fire.
- **ruleset-diff-audit** — walk engine code against a ruleset version; flag hardcoded constants that should be JSON-driven.
- **godot-repl** — throwaway scratch-script runner for one-off engine checks; auto-deletes.

## Browsing skills

```bash
# List all available skills:
bin/install-skill.sh --available

# Filter by group:
bin/install-skill.sh --available --group turnipsim

# Filter by tag:
bin/install-skill.sh --available --tag workflow
```

## Installing skills

Use `bin/install-skill.sh` from the repo root. It symlinks by default (so edits here propagate instantly); pass `--copy` on platforms where symlinks aren't available.

```bash
# One skill, global (~/.claude/skills/):
bin/install-skill.sh checkpoint

# All skills in a group:
bin/install-skill.sh --group turnipsim

# Into a specific project:
bin/install-skill.sh checkpoint --project /path/to/turnipsim

# Whole group into a project:
bin/install-skill.sh --group turnipsim --project /path/to/turnipsim

# By tag:
bin/install-skill.sh --tag workflow

# With copy instead of symlink, replacing any existing entry:
bin/install-skill.sh checkpoint --copy --force

# See what would happen without doing it:
bin/install-skill.sh checkpoint --dry-run

# List what's installed at a target:
bin/install-skill.sh --list --project /path/to/turnipsim

# Remove an installed skill:
bin/install-skill.sh --uninstall checkpoint --project /path/to/turnipsim
```

Flags: `--project PATH` (default `~/.claude/skills/`), `--group`, `--tag`, `--copy`, `--force`, `--dry-run`, `--uninstall`, `--list`, `--available`, `--help`.

After install, restart Claude Code (or start a new session) so the skill is picked up, then invoke with `/<name>` to confirm it loads.

## Authoring a new skill

1. Create `skills/<name>/` with the skill name in kebab-case.
2. Write `SKILL.md` with YAML frontmatter (`name`, `description`) + body. Keep the body prescriptive, not explanatory.
3. Write `manifest.json` with `name`, `description` (short browsable summary), `group`, `tags`, and `version`.
4. Make the frontmatter `description` rich in trigger phrases — that's what Claude matches against.
5. Include a `## Rules` block for constraints that aren't obvious from the instructions.
6. Run `bin/build-registry.sh` to update the registry.
7. Commit.
8. Install and invoke once to confirm it matches.

### manifest.json format

```json
{
  "name": "my-skill",
  "description": "Short browsable summary of what this does",
  "group": "my-project",
  "tags": ["relevant", "tags"],
  "version": "1.0.0"
}
```

## Maintaining skills

- **Descriptions are the matching surface.** When a skill misfires or fails to trigger, the fix is almost always in the frontmatter `description` field.
- **One skill, one job.** If a skill's body is growing conditionals, split it into two skills with sharper descriptions.
- **Keep rules blocks.** The `## Rules` sections capture hard-won constraints. Don't strip them during cleanup.
- **Run `bin/build-registry.sh`** after adding or modifying skills to keep the registry current.
- **Re-verify after editing.** If the installed copy was a file-copy (not a symlink), re-install it.
