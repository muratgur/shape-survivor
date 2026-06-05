---
title: Shape Survivor Godot Prototype Run Note
summary: How to open and run the primitive-drawn Godot arena-survivor prototype.
created_by: Godot Game Developer
created_at: 2026-06-04
project: godot-brotato-like-shape-survivor
upstream: docs/game_design_shape_survivor.md
tags:
  - godot
  - prototype
  - run-note
---

# Shape Survivor Godot Prototype Run Note

## Godot Version

- Target: Godot 4.x 2D.
- Verified parser/runtime startup with Godot `4.6.2.stable`.
- No external art or audio assets are required.

## Main Scene

- Project file: `project.godot`
- Main scene: `res://scenes/main.tscn`
- Main controller script: `res://scripts/main.gd`

## Run

1. Open the workspace folder in Godot 4.x.
2. Open `project.godot` if Godot asks for a project file.
3. Press Play. The configured startup scene is `res://scenes/main.tscn`.
4. Choose a character, then confirm to start combat.

Command line:

```sh
godot --path .
```

## Controls

- Character select: A/D, arrow keys, gamepad stick/D-pad, or mouse hover; Enter, Space, A/Cross, or left click confirms.
- Move: WASD, arrow keys, gamepad stick, or D-pad.
- Confirm upgrade/return to select: Enter, Space, A/Cross, or left click.
- Pause/resume: Esc.
- Return to character select from result or pause: R.
- Gamepad: left stick or D-pad movement, A/Cross confirm, Start/Menu pause.

## Prototype Coverage

- Primitive-drawn sketchbook arena, selectable shape player, shape enemies, projectiles, pickups, fragments, and UI.
- Character select supports Balanced Blob, Quick Dot, Sturdy Square, and Fancy Hex, with distinct HP, speed, collision radius, Side Count, and primitive-drawn silhouettes.
- Six-segment run: four upgrade-bearing waves, the no-draft Polygon Tremor prelude, followed by a Chunk Polygon boss wave.
- Enemies: Wobble Circle, Smug Square, Pointy Triangle, Needle Line, Dizzy Spiral, and Chunk Polygon boss.
- Weapons: Volunteer Dot starter plus Corner Cannon, Dot Swarm, Rude Triangle, Orbit Ruler, and Apology Orb unlocks/upgrades.
- Pickups: Ink Drops and Heart-ish Blobs.
- Four between-wave upgrade drafts with 15 prototype upgrades, Side Count support, restart, pause, win, and loss flows.

## Latest Validation

- Added Fancy Hex as a fourth selectable character: 5 HP, 250 speed, 18 radius, and starting Side Count 6.
- Updated the character select layout to size cards from the roster count so four choices fit without adding pagination.
- Validation run: Godot headless check/startup smoke tests passed after the character addition.
- Tuned Volunteer Dot starter cooldown from 0.95s to 0.80s; damage, projectile behavior, targeting, upgrades, enemies, waves, character selection, pause, restart, and win/loss flow were left unchanged.
- Validation run: Godot parser and runtime smoke tests passed after the cooldown tuning.

## References

- [[creative_direction_shape_survivor]]
- [[game_design_shape_survivor]]
