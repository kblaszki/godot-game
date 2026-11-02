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
- **GUT 9.3.1** vendored at `addons/gut/` (plugin enabled in `project.godot`)
- Test options in [`.gutconfig.json`](../../../.gutconfig.json)

## First clone / new `class_name`

On a clean checkout (or after adding a `class_name` script), import before smoke/tests:

```sh
godot --path . --headless --import
```

## Load / smoke the project

```sh
godot --path . --headless --quit-after 1
```

Fails if `project.godot` is broken or required resources fail to load.

## Unit tests (GUT, headless)

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd
```

- Suites under `tests/` named `*_test.gd` (see `.gutconfig.json`)
- Always `--headless` — tests open no window
- Exit non-zero on failure (`should_exit` in config)

Narrow a directory when useful:

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/engine
godot --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/games/<name>
```

## Typical verify loop after code changes

1. `--import` if new `class_name` types were added
2. Smoke-load the project (`--quit-after 1`)
3. Run GUT for the touched area (or all of `res://tests`)
4. Confirm Diátaxis docs updated in the same change when `engine/` or `games/` code changed
5. Commit the verified unit (golden rule §5)
