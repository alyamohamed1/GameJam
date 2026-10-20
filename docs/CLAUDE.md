# CLAUDE.md — Heist jam game

Read this first, every session. Full design: `docs/game-context.md`. Full build plan: `docs/build-plan.md`.

## Project facts
- Godot 4 (exact version: FILL IN from Help → About), **typed GDScript only**. Never write Godot 3 syntax
  (`KinematicBody2D`, `export var`, `onready var`, `yield`, `remote func`, `TileMap`, `move_and_slide(velocity)`).
- 2D, base resolution 480×270, 16×16 tiles, Compatibility renderer.
- The builder is a beginner using Godot for the first time: when you add or change a scene, tell the user exactly
  which nodes exist and where each script is attached. Keep code simple and commented. Do one small task at a time.
- Godot binary on macOS: `/Applications/Godot.app/Contents/MacOS/Godot`

## Current stage
We build in stages and finish each one before starting the next (see "Build in stages" in the plan).
- Stage 0: connected skeleton — host/join, burglar square moves and syncs, Player 2 sees one monitor.
- Stage 1: basic version — full loop with placeholders, NO vacuum, NO shaders, NO checkpoints, NO art/sound.
- Stage 2: full version.
**Current stage: 0** (update this line as you go). Do not build features from a later stage.

## Architecture rules (do not break)
- Both machines load the same `level/house.tscn`. No MultiplayerSpawner; every moving thing is placed in the scene.
- **Host = Player 1 = authority for everything** (dog AI, puzzles, phase, fail/victory). Default authority (peer 1)
  is correct; never call `set_multiplayer_authority()`.
- Gameplay code on host only: start `_physics_process` with `if not multiplayer.is_server(): return`.
- Client (Player 2) never moves anything. It only sends RPCs to the host: `request_feeder()`, `set_vacuum_input(dir)`.
  Client→host RPCs use `@rpc("any_peer", ...)` and the host checks `multiplayer.is_server()`.
  Host→both RPCs use `@rpc("authority", "call_local", "reliable")`.
- Positions sync with `MultiplayerSynchronizer` (position, facing/rotation, state int).
- Autoloads: `Net` (`net/net.gd`) and `Game` (`game/game.gd`, holds `Phase` enum, `phase_changed` signal, `set_phase()`).
  Every script reacts to `Game.phase_changed` rather than polling.
- Client deletes the `Darkness` CanvasModulate and disables the burglar's light; Player 2 monitors are
  SubViewports sharing `get_tree().root.world_2d`.

## Folders and workflow
`net/ game/ level/ player1/ dog/ player2/ devices/ ui/ art/ audio/ shaders/ docs/`
- All code and scenes are built on this one Mac, by one person working with you. Nobody else edits the project.
- Teammates deliver art (PNG) and sound (WAV) by AirDrop; the builder drops them into `art/` and `audio/`.
  Placeholders and final art share the same file names and sizes, so swapping art needs no code changes.
  When you create a placeholder, tell the user its file name and pixel size so the artist can match it.
- A second Mac is used only for playtests (the project is copied over as a zip, or later as an exported app).
- Changing `project.godot` (settings, input map, autoloads) is fine, but tell the user what you changed.

## Editing scenes (.tscn)
- Prefer creating scripts and telling the user which nodes to add in the editor.
- If you must write or edit a `.tscn`, keep it minimal, keep existing node names and `ext_resource` ids,
  and remind the user to close that scene tab in Godot first (Godot overwrites files open in the editor).
- Never edit anything inside `.godot/`.

## Checking your work
After changing scripts, run from the project root:
- `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import` (re-imports, prints script errors)
- For one script: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --check-only --script res://path/to/file.gd`
Fix every error before saying you're done. You cannot see the game window: ask the user to press F5
(with Debug → Customize Run Instances: 2 instances, feature tags `host` and `client`) and report what happens.

## Input actions (defined in project.godot)
`move_up` `move_down` `move_left` `move_right` `run` `interact`

## Puzzle data
Laptop password `Biscuit2019` (case-insensitive). Ciphertext `VHYHQ WZR QLQH IRXU`, Caesar shift 3 → 7294 = safe code.
Phases: LOBBY → PRE_USB → POST_USB → BLACKOUT → VICTORY, FAIL from any active phase.

## Git
Commit after each working step, with a clear message ("dog patrol works"), so a bad change can be undone.
Push to the private GitHub repo as a backup when the user asks. Never force-push. Don't commit `.godot/`.
