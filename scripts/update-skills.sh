#!/usr/bin/env bash
# Fetches the latest SKILL.md and scripts/ for every sourced skill from
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

fetch_skill() {
  local skill="$1"
  local dest="$SKILLS_DIR/$skill"
  echo "  updating $skill..."
  mkdir -p "$dest"

  # Fetch SKILL.md
  gh api "repos/$REPO/contents/skills/$skill/SKILL.md" --jq '.content' \
    | base64 -d > "$dest/SKILL.md"

  # Fetch scripts/ if the directory exists
  local scripts
  scripts=$(gh api "repos/$REPO/contents/skills/$skill/scripts" \
    --jq '.[].name' 2>/dev/null || true)

  if [ -n "$scripts" ]; then
    mkdir -p "$dest/scripts"
    # Remove stale .gd files so renamed scripts don't linger
    rm -f "$dest/scripts/"*.gd
    while IFS= read -r script_file; do
      gh api "repos/$REPO/contents/skills/$skill/scripts/$script_file" \
        --jq '.content' | base64 -d > "$dest/scripts/$script_file"
    done <<< "$scripts"
  fi
}

echo "Fetching ${#SOURCED_SKILLS[@]} skills from $REPO..."
for skill in "${SOURCED_SKILLS[@]}"; do
  fetch_skill "$skill"
done

echo ""
echo "Done. Review with: git diff"
echo "Commit with: git add -p && git commit -m 'chore: update sourced skills from gd-agentic-skills'"
