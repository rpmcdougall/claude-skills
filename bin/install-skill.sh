#!/usr/bin/env bash
# install-skill.sh — install skill(s) from this repo into a Claude Code skills dir.
#
# Usage:
#   bin/install-skill.sh <name>...   [--project PATH] [--copy] [--dry-run] [--force]
#   bin/install-skill.sh --group <g> [--project PATH] [--copy] [--dry-run] [--force]
#   bin/install-skill.sh --tag <t>   [--project PATH] [--copy] [--dry-run] [--force]
#   bin/install-skill.sh --uninstall <name>... [--project PATH] [--dry-run]
#   bin/install-skill.sh --list      [--project PATH]
#   bin/install-skill.sh --available [--group <g>] [--tag <t>]
#
# <name> is the skill package name (directory name under skills/).
#
# Default target is ~/.claude/skills/ (global).
# With --project PATH, installs to PATH/.claude/skills/ instead.
#
# Default install mode is symlink. On platforms where symlink fails (e.g. Windows
# without developer mode), rerun with --copy. --force replaces existing entries.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

target_dir="$HOME/.claude/skills"
mode="symlink"
dry_run=0
force=0
action="install"
filter_group=""
filter_tag=""
targets=()

die() { echo "error: $*" >&2; exit 1; }
log() { echo "$*"; }
run() { if [[ $dry_run -eq 1 ]]; then echo "+ $*"; else eval "$@"; fi; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      [[ $# -ge 2 ]] || die "--project requires a path"
      target_dir="$(cd "$2" && pwd)/.claude/skills"
      shift 2
      ;;
    --group)
      [[ $# -ge 2 ]] || die "--group requires a name"
      filter_group="$2"
      shift 2
      ;;
    --tag)
      [[ $# -ge 2 ]] || die "--tag requires a value"
      filter_tag="$2"
      shift 2
      ;;
    --copy)      mode="copy"; shift ;;
    --dry-run)   dry_run=1; shift ;;
    --force)     force=1; shift ;;
    --uninstall) action="uninstall"; shift ;;
    --list)      action="list"; shift ;;
    --available) action="available"; shift ;;
    -h|--help)
      sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    --*) die "unknown flag: $1" ;;
    *)   targets+=("$1"); shift ;;
  esac
done

# --- Available: list skills from manifests ---
if [[ $action == "available" ]]; then
  log "Available skills in $SKILLS_DIR:"
  for manifest in "$SKILLS_DIR"/*/manifest.json; do
    [[ -f "$manifest" ]] || continue
    name=$(jq -r '.name' "$manifest")
    desc=$(jq -r '.description' "$manifest")
    group=$(jq -r '.group' "$manifest")
    tags=$(jq -r '.tags // [] | join(", ")' "$manifest")

    if [[ -n "$filter_group" && "$group" != "$filter_group" ]]; then continue; fi
    if [[ -n "$filter_tag" ]] && ! jq -e --arg t "$filter_tag" '.tags // [] | index($t)' "$manifest" &>/dev/null; then continue; fi

    printf "  %-28s %s\n" "$name [$group]" "$desc"
  done
  exit 0
fi

# --- List installed ---
mkdir -p "$target_dir"

if [[ $action == "list" ]]; then
  log "Installed skills in $target_dir:"
  shopt -s nullglob
  found=0
  for f in "$target_dir"/*.md; do
    found=1
    base="$(basename "$f")"
    if [[ -L "$f" ]]; then
      echo "  $base -> $(readlink "$f")"
    else
      echo "  $base (copy)"
    fi
  done
  [[ $found -eq 0 ]] && echo "  (none)"
  exit 0
fi

# --- Resolve targets from --group / --tag if no explicit names ---
if [[ ${#targets[@]} -eq 0 ]]; then
  if [[ -n "$filter_group" || -n "$filter_tag" ]]; then
    for manifest in "$SKILLS_DIR"/*/manifest.json; do
      [[ -f "$manifest" ]] || continue
      name=$(jq -r '.name' "$manifest")
      group=$(jq -r '.group' "$manifest")
      if [[ -n "$filter_group" && "$group" != "$filter_group" ]]; then continue; fi
      if [[ -n "$filter_tag" ]] && ! jq -e --arg t "$filter_tag" '.tags // [] | index($t)' "$manifest" &>/dev/null; then continue; fi
      targets+=("$name")
    done
  fi
fi

[[ ${#targets[@]} -gt 0 ]] || die "no skills specified. See --help."

# --- Resolve a skill name to its source file ---
resolve_source() {
  local name="$1"
  # Strip .md suffix if provided
  name="${name%.md}"
  local skill_dir="$SKILLS_DIR/$name"
  if [[ -f "$skill_dir/skill.md" ]]; then
    echo "$skill_dir/skill.md"
    return
  fi
  die "could not resolve skill: $name (expected $skill_dir/skill.md)"
}

install_one() {
  local name="$1"
  name="${name%.md}"
  local src dest
  src=$(resolve_source "$name")
  dest="$target_dir/${name}.md"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ $force -eq 1 ]]; then
      run rm -f "\"$dest\""
    else
      log "skip (exists): $dest  — use --force to replace"
      return
    fi
  fi

  if [[ $mode == "symlink" ]]; then
    if ! run ln -s "\"$src\"" "\"$dest\""; then
      die "symlink failed for $src → $dest (try --copy)"
    fi
    log "linked: ${name}.md"
  else
    run cp "\"$src\"" "\"$dest\""
    log "copied: ${name}.md"
  fi
}

uninstall_one() {
  local name="$1"
  name="${name%.md}"
  local dest="$target_dir/${name}.md"
  if [[ -e "$dest" || -L "$dest" ]]; then
    run rm -f "\"$dest\""
    log "removed: ${name}.md"
  else
    log "not installed: ${name}.md"
  fi
}

for t in "${targets[@]}"; do
  if [[ $action == "uninstall" ]]; then
    uninstall_one "$t"
  else
    install_one "$t"
  fi
done

log "target: $target_dir"
