#!/usr/bin/env bash
# Fetches the latest SKILL.md, scripts/, and references/ for every sourced skill from
# thedivergentai/gd-agentic-skills. Requires `gh` CLI authenticated.
# Usage: bash scripts/update-skills.sh
# After running, review with: git diff

set -euo pipefail

REPO="thedivergentai/gd-agentic-skills"
SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/skills"

SOURCED_SKILLS=(
  godot-2d-animation
  godot-2d-physics
  godot-ability-system
  godot-adapt-single-to-multiplayer
  godot-animation-player
  godot-animation-tree-mastery
  godot-audio-systems
  godot-autoload-architecture
  godot-camera-systems
  godot-characterbody-2d
  godot-combat-system
  godot-composition
  godot-export-builds
  godot-gdscript-mastery
  godot-genre-action-rpg
  godot-genre-card-game
  godot-genre-metroidvania
  godot-genre-platformer
  godot-input-handling
  godot-inventory-system
  godot-mcp-scene-builder
  godot-mcp-setup
  godot-multiplayer-networking
  godot-navigation-pathfinding
  godot-particles
  godot-performance-optimization
  godot-platform-desktop
  godot-procedural-generation
  godot-raycasting-queries
  godot-resource-data-patterns
  godot-rpg-stats
  godot-save-load-systems
  godot-shaders-basics
  godot-signal-architecture
  godot-state-machine-advanced
  godot-testing-patterns
  godot-tilemap-mastery
  godot-tweening
  godot-ui-containers
  godot-ui-theming
)

# Fetches one flat subdirectory (scripts/, references/) if it exists upstream.
# Clears the local copy first so files renamed or dropped upstream don't linger.
fetch_subdir() {
  local skill="$1"
  local subdir="$2"
  local dest="$SKILLS_DIR/$skill/$subdir"

  local entries
  entries=$(gh api "repos/$REPO/contents/skills/$skill/$subdir" \
    --jq '.[] | select(.type == "file") | .name' 2>/dev/null || true)

  [ -z "$entries" ] && return 0

  mkdir -p "$dest"
  find "$dest" -maxdepth 1 -type f -delete

  while IFS= read -r entry; do
    gh api "repos/$REPO/contents/skills/$skill/$subdir/$entry" \
      --jq '.content' | base64 -d > "$dest/$entry"
  done <<< "$entries"
}

fetch_skill() {
  local skill="$1"
  local dest="$SKILLS_DIR/$skill"
  echo "  updating $skill..."
  mkdir -p "$dest"

  # Fetch SKILL.md through a temp file so a failed request can't truncate the
  # existing skill to zero bytes.
  local staged
  staged=$(mktemp)
  if ! gh api "repos/$REPO/contents/skills/$skill/SKILL.md" --jq '.content' \
    | base64 -d > "$staged" || [ ! -s "$staged" ]; then
    rm -f "$staged"
    echo "    WARNING: could not fetch SKILL.md, leaving $skill unchanged" >&2
    return 0
  fi
  mv "$staged" "$dest/SKILL.md"

  fetch_subdir "$skill" scripts
  fetch_subdir "$skill" references
}

echo "Fetching ${#SOURCED_SKILLS[@]} skills from $REPO..."
for skill in "${SOURCED_SKILLS[@]}"; do
  fetch_skill "$skill"
done

echo ""
echo "Done. Review with: git diff"
echo "Commit with: git add -p && git commit -m 'chore: update sourced skills from gd-agentic-skills'"
