#!/usr/bin/env bash
# build-registry.sh — generate skills/registry.json from per-skill manifest.json files.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
REGISTRY="$SKILLS_DIR/registry.json"

if ! command -v jq &>/dev/null; then
  echo "error: jq is required. Install with: brew install jq" >&2
  exit 1
fi

entries=()
for manifest in "$SKILLS_DIR"/*/manifest.json; do
  [[ -f "$manifest" ]] || continue
  dir="$(basename "$(dirname "$manifest")")"
  entry=$(jq --arg path "skills/$dir/skill.md" '. + {path: $path}' "$manifest")
  entries+=("$entry")
done

if [[ ${#entries[@]} -eq 0 ]]; then
  echo "No skills found in $SKILLS_DIR" >&2
  exit 1
fi

printf '%s\n' "${entries[@]}" | jq -s '{skills: (. | sort_by(.name))}' > "$REGISTRY"
echo "wrote $REGISTRY ($(jq '.skills | length' "$REGISTRY") skills)"
