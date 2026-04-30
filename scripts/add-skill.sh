#!/usr/bin/env bash
# Pulls a single named skill from thedivergentai/gd-agentic-skills.
# Usage: bash scripts/add-skill.sh <skill-name>
# After running, add the skill name to SOURCED_SKILLS in scripts/update-skills.sh.

set -euo pipefail

REPO="thedivergentai/gd-agentic-skills"
SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/skills"

skill="${1:-}"
if [ -z "$skill" ]; then
  echo "Usage: $0 <skill-name>"
  echo "Example: $0 godot-shaders-advanced"
  exit 1
fi

# Verify the skill exists before writing anything
gh api "repos/$REPO/contents/skills/$skill" --silent 2>/dev/null || {
  echo "Error: skill '$skill' not found in $REPO"
  exit 1
}

echo "Fetching $skill from $REPO..."
dest="$SKILLS_DIR/$skill"
mkdir -p "$dest"

gh api "repos/$REPO/contents/skills/$skill/SKILL.md" --jq '.content' \
  | base64 -d > "$dest/SKILL.md"

scripts=$(gh api "repos/$REPO/contents/skills/$skill/scripts" \
  --jq '.[].name' 2>/dev/null || true)

if [ -n "$scripts" ]; then
  mkdir -p "$dest/scripts"
  while IFS= read -r script_file; do
    gh api "repos/$REPO/contents/skills/$skill/scripts/$script_file" \
      --jq '.content' | base64 -d > "$dest/scripts/$script_file"
  done <<< "$scripts"
  echo "Fetched SKILL.md + $(echo "$scripts" | wc -l | tr -d ' ') scripts"
else
  echo "Fetched SKILL.md (no scripts directory)"
fi

echo ""
echo "Next: add '$skill' to SOURCED_SKILLS in scripts/update-skills.sh"
