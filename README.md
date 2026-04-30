# snackpackgames-claude-plugins

Claude Code plugin containing Godot 4, Nakama, and Hiro skills for Snack Pack Games projects.

## Installation

### Step 1 — Register the marketplace (once per machine)

In Claude Code:

```
/plugin marketplace add snackpackgames/snackpackgames-claude-plugins
```

### Step 2 — Install the plugin (once per project)

```
/plugin install snackpackgames-claude-plugins@snackpackgames
```

After installation, all 43 skills appear in the session-start system-reminder automatically.

## Skills

### Sourced from [gd-agentic-skills](https://github.com/thedivergentai/gd-agentic-skills) (40 skills)

| Skill | Domain |
|---|---|
| `godot-2d-animation` | AnimatedSprite2D, sprite frames, cutout animation |
| `godot-2d-physics` | Collision layers, Area2D, raycasting |
| `godot-ability-system` | Cooldowns, combo systems, skill trees |
| `godot-adapt-single-to-multiplayer` | Multiplayer conversion patterns |
| `godot-animation-player` | AnimationPlayer tracks, RESET, root motion |
| `godot-animation-tree-mastery` | AnimationTree, BlendSpace2D, state machines |
| `godot-audio-systems` | AudioBus, positional audio, music crossfade |
| `godot-autoload-architecture` | Singleton pattern, signal buses |
| `godot-camera-systems` | Camera follow, shake, deadzone |
| `godot-characterbody-2d` | Player movement, coyote time, move_and_slide |
| `godot-combat-system` | Hitbox/hurtbox, DamageData, health components |
| `godot-composition` | Component-based entity design |
| `godot-export-builds` | Multi-platform exports, CI/CD |
| `godot-gdscript-mastery` | Static typing, style guide, performance patterns |
| `godot-genre-action-rpg` | Stats, combat, loot, itemization |
| `godot-genre-card-game` | Card data, deck management, hand layout |
| `godot-genre-metroidvania` | Map traversal, warp zones, unlock gates |
| `godot-genre-platformer` | Coyote time, jump buffering, game feel |
| `godot-input-handling` | InputMap, controller support, rebinding |
| `godot-inventory-system` | Slot-based inventory, equipment, drag-drop UI |
| `godot-mcp-scene-builder` | Programmatic scene creation via MCP tools |
| `godot-mcp-setup` | Godot MCP server installation and config |
| `godot-multiplayer-networking` | MultiplayerSynchronizer, RPC, peer connections |
| `godot-navigation-pathfinding` | NavigationAgent2D, avoidance, path updates |
| `godot-particles` | GPUParticles2D, VFX, sub-emitters |
| `godot-performance-optimization` | Profiling, object pooling, draw calls |
| `godot-platform-desktop` | Windows/Linux/macOS settings, Steam |
| `godot-procedural-generation` | Procedural level layout, dungeon generation |
| `godot-raycasting-queries` | Raycast, ShapeCast, DirectSpaceState queries |
| `godot-resource-data-patterns` | Resource/.tres data-first design |
| `godot-rpg-stats` | Stat systems, modifiers, derived stats |
| `godot-save-load-systems` | Save/load, versioned persistence |
| `godot-shaders-basics` | GLSL shaders, canvas_item, visual effects |
| `godot-signal-architecture` | Signal-up/call-down, event buses |
| `godot-state-machine-advanced` | Hierarchical FSM, pushdown automata |
| `godot-testing-patterns` | GUT tests, async testing, watch_signals |
| `godot-tilemap-mastery` | TileMap, room grids, level scenes |
| `godot-tweening` | Tween animations, UI transitions |
| `godot-ui-containers` | Container layouts, responsive UI |
| `godot-ui-theming` | Theme resources, StyleBox, fonts |

### Custom skills (3 skills)

| Skill | Domain |
|---|---|
| `hiro-framework` | Hiro economy, inventory, energy, Go hooks |
| `nakama-server-modules` | Nakama JS RPCs, auth hooks, storage, wallet |
| `nakama-multiplayer` | Authoritative matches, parties, matchmaker |

## Updating sourced skills

When `thedivergentai/gd-agentic-skills` publishes updates:

```bash
bash scripts/update-skills.sh
git diff                          # review changes
git add -p && git commit -m "chore: update sourced skills from gd-agentic-skills"
git push
```

To add a new skill from gd-agentic-skills:

```bash
bash scripts/add-skill.sh godot-some-new-skill
# then add the skill name to SOURCED_SKILLS in scripts/update-skills.sh
```
