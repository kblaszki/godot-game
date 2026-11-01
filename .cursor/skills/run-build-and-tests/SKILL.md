---
name: run-build-and-tests
description: >-
  Loads the Godot 4 project and runs GUT unit tests headless for godot-game.
  Use when verifying the project, running unit tests, or checking CI-like steps.
---

# Run build and tests

Source of truth: [docs/how-to/build-and-test.md](../../../docs/how-to/build-and-test.md). Keep this skill consistent with that doc.

## Prerequisites

- Godot **4.x** binary on `PATH` as `godot` (or substitute the full path)
- Typed GDScript project at the repo root (`project.godot`)
- **GUT** installed under `addons/gut/` for unit tests (not bundled in the empty lab; install before expecting green suites)

## Load / smoke the project

```sh
godot --path . --headless --quit-after 1
```

Fails if `project.godot` is broken or required resources fail to load.

## Unit tests (GUT, headless)

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

- Suites: `tests/engine/`, `tests/games/<name>/`
- Always `--headless` — tests open no window
- Exit non-zero on failure (`-gexit`)

Narrow a directory when useful:

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/engine -gexit
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/games/<name> -gexit
```

## Typical verify loop after code changes

1. Smoke-load the project (`--quit-after 1`)
2. Run GUT for the touched area (or all of `res://tests`)
3. Confirm Diátaxis docs updated in the same change when `engine/` or `games/` code changed
4. Commit the verified unit (golden rule §5)
