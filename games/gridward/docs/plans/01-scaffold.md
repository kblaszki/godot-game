---
title: Gridward plan 01 — scaffold
diataxis: how-to
audience: [ai, human]
related_code:
  - games/gridward/
  - lab/launcher.gd
  - tests/games/gridward/
related_docs:
  - 00-roadmap.md
  - 02-data-model.md
  - ../../../../docs/how-to/add-a-game.md
keywords: [gridward, scaffold, add-game, launcher]
last_reviewed: 2026-11-08
---

# 01 — Scaffold

## Goal

Create the game shell so later plans have real paths. Success: launcher shows
**Gridward**, host loads headless, `host_flow` GUT passes.

## Prerequisites

- [00-roadmap.md](00-roadmap.md)

## Scope

**In:** `games/gridward/{sim,app,docs}/`, stub host/menu, launcher row, host_flow test, stub `reference/sim.md` + `app.md` + `explanation/flow.md`.  
**Out:** real rules, 3D board, campaign.

## Files

| Path | Action |
|------|--------|
| `games/gridward/sim/.gitkeep` or stub `gridward_config.gd` | add |
| `games/gridward/app/host.gd` / `.tscn` | add (extends LayeredHost) |
| `games/gridward/app/menu.gd` / `.tscn` | add (Play → play stub, Quit) |
| `games/gridward/app/play.gd` / `.tscn` | stub placeholder |
| `lab/launcher.gd` | add `{title: "Gridward", host_path: "res://games/gridward/app/host.tscn"}` |
| `tests/games/gridward/gridward_host_flow_test.gd` | add |
| `games/gridward/docs/reference/sim.md`, `app.md`, `explanation/flow.md` | stub pages |

## API sketch

```gdscript
# host.gd
extends LayeredHost
func _boot() -> void:
	submit(SceneRequest.replace("res://games/gridward/app/menu.tscn"))
func _on_quit_requested() -> void:
	# walk parents for return_to_launcher; else get_tree().quit()
	pass
```

## GUT

- `test_menu_should_replace_into_play_and_quit_returns_to_lab` (mirror other games)

## Docs

Update stubs; `source-layout.md` game row; engine docs index if needed.

## Skills

`add-game`, `add-scene`, `godot-app-scripting`, `run-build-and-tests`

## Verify

```sh
godot --path . --headless --import
godot --path . --headless --quit-after 1
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/games/gridward
```

## Todos / commits

1. Scaffold folders + host/menu → `Scaffold Gridward lab host and launcher entry.`
2. host_flow GUT + stub docs → `Cover Gridward host flow and stub Diataxis pages.`
