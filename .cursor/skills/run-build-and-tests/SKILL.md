---
name: run-build-and-tests
description: >-
  Loads the Godot 4 project and runs GUT unit tests headless for godot-game.
  Use when verifying the project, running unit tests, checking CI-like steps,
  debugging a godot --headless hang, a zero exit despite failures, missing
  --import on a fresh checkout, or sandbox crashes during Godot runs.
---

# Run build and tests

Source of truth: [docs/how-to/build-and-test.md](../../../docs/how-to/build-and-test.md).
Keep this skill consistent with that doc. Headless-runner pitfalls adapted from
upstream `godot-gdscript-headless-testing` (see [NOTICE](../../../NOTICE)).

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

Without `--import`, `class_name` types fail to resolve (`Identifier "X" not declared`)
and imported assets may fail to load.

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
- **Gate on the process exit code**, not stdout alone
- Agent shell: Godot needs unrestricted permissions (sandbox crashes the binary);
  use `required_permissions: ["all"]` when invoking via the Shell tool

Narrow a directory when useful:

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/engine
godot --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/games/<name>
```

## CI / wrapper tips

- Put a step timeout around GUT (hung `await` never exits).
- Redirect stdout and stderr to files when a wrapper shell reorders or drops live streams;
  `push_error` goes to stderr.
- Prefer GUT assertions that record failures and continue; bare `assert()` in a custom
  `SceneTree` runner can abort before `quit(1)` and hang CI.

## Typical verify loop after code changes

1. `--import` if new `class_name` types were added
2. Smoke-load the project (`--quit-after 1`)
3. Run GUT for the touched area (or all of `res://tests`)
4. Confirm Diátaxis docs updated in the same change when `engine/` or `games/` code changed
5. Commit the verified unit (golden rule §5)

## Pitfalls

- Opens a window → missing `--headless`.
- Fresh checkout fails on `class_name` → run `--import` first.
- Exit 0 despite failures → runner never called `quit(1)` / GUT `should_exit` off.
- Hang forever → unresolved `await`; set a step timeout and fix the suite.
- Sandbox crash → re-run Godot with unrestricted permissions.
