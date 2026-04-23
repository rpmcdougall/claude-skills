#!/usr/bin/env bash
# install-skill.sh — install skill(s) from this repo into a Claude Code skills dir.
#
# Usage:
#   bin/install-skill.sh <skill-or-dir>... [--project PATH] [--copy] [--dry-run] [--force]
#   bin/install-skill.sh --uninstall <name>... [--project PATH] [--dry-run]
#   bin/install-skill.sh --list [--project PATH]
#
# <skill-or-dir> may be:
#   - a skill name           e.g.  checkpoint
#   - a path relative to repo e.g.  turnipsim/checkpoint.md
#   - a group directory      e.g.  turnipsim         (installs every *.md inside)
#
# Default target is ~/.claude/skills/ (global).
# With --project PATH, installs to PATH/.claude/skills/ instead.
#
# Default install mode is symlink. On platforms where symlink fails (e.g. Windows
# without developer mode), rerun with --copy. --force replaces existing entries.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

target_dir="$HOME/.claude/skills"
mode="symlink"
dry_run=0
force=0
action="install"
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
    --copy)    mode="copy"; shift ;;
    --dry-run) dry_run=1; shift ;;
    --force)   force=1; shift ;;
    --uninstall) action="uninstall"; shift ;;
    --list)    action="list"; shift ;;
    -h|--help)
      sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    --*) die "unknown flag: $1" ;;
    *)   targets+=("$1"); shift ;;
  esac
done

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

[[ ${#targets[@]} -gt 0 ]] || die "no skills specified. See --help."

# Expand each target into a list of source .md files.
resolve_sources() {
  local t="$1"
  # Absolute or repo-relative path to a .md file
  if [[ -f "$REPO_ROOT/$t" ]]; then
    echo "$REPO_ROOT/$t"; return
  fi
  if [[ -f "$t" ]]; then
    local d b
    d="$(cd "$(dirname "$t")" && pwd)"
    b="$(basename "$t")"
    echo "$d/$b"; return
  fi
  # Group directory (e.g. "turnipsim")
  if [[ -d "$REPO_ROOT/$t" ]]; then
    find "$REPO_ROOT/$t" -maxdepth 1 -name '*.md' -not -name 'README.md' | sort
    return
  fi
  # Bare skill name — search the repo for <name>.md
  local found
  found=$(find "$REPO_ROOT" -maxdepth 3 -name "${t}.md" -not -path '*/doc/*' -not -name 'README.md' | sort)
  if [[ -n "$found" ]]; then
    echo "$found"; return
  fi
  die "could not resolve skill: $t"
}

install_one() {
  local src="$1"
  local base dest
  base="$(basename "$src")"
  dest="$target_dir/$base"

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
    log "linked: $base"
  else
    run cp "\"$src\"" "\"$dest\""
    log "copied: $base"
  fi
}

uninstall_one() {
  local name="$1"
  [[ "$name" == *.md ]] || name="${name}.md"
  local dest="$target_dir/$name"
  if [[ -e "$dest" || -L "$dest" ]]; then
    run rm -f "\"$dest\""
    log "removed: $name"
  else
    log "not installed: $name"
  fi
}

for t in "${targets[@]}"; do
  if [[ $action == "uninstall" ]]; then
    uninstall_one "$t"
  else
    while IFS= read -r src; do
      [[ -n "$src" ]] && install_one "$src"
    done < <(resolve_sources "$t")
  fi
done

log "target: $target_dir"
