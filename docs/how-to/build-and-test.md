---
title: Build and test
diataxis: how-to
audience: [ai, human]
related_code: [project.godot, tests/, addons/gut/, .gutconfig.json, .github/workflows/ci.yml]
related_docs:
  - ../index.md
  - write-headless-tests.md
  - ../reference/source-layout.md
keywords: [godot, gut, headless, verify, CI, github-actions, gutconfig]
last_reviewed: 2026-11-02
---

# Build and test

## Prerequisites

- Godot **4.x** on `PATH` as `godot` (or use the full binary path)
- **GUT 9.3.1** is vendored at `addons/gut/` and enabled via `editor_plugins` in `project.godot`

## First clone

On a fresh checkout (no `.godot/` cache yet):

```sh
godot --path . --headless --import
godot --path . --headless --quit-after 1
godot --path . --headless -s addons/gut/gut_cmdln.gd
```

`--import` builds the global `class_name` cache. Without it, new engine types may fail to resolve until the editor has imported once.

## Smoke-load the project

```sh
godot --path . --headless --quit-after 1
```

After adding a new `class_name` script, run `--import` again (or open the editor) so the cache updates.

## Run GUT (headless)

Test discovery comes from [`.gutconfig.json`](../../.gutconfig.json): `dirs` = `res://tests`, empty `prefix`, `suffix` = `_test.gd`, `include_subdirs`, `should_exit`.

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd
```

Narrow scope (CLI overrides config dirs; keep the same naming convention):

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/engine
godot --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/games/<name>
```

Always use `--headless`. Suites must not require an open editor window.

## CI

GitHub Actions workflow [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) runs on push and pull request to `main` (Ubuntu):

1. Download Godot **4.3-stable** Linux x86_64
2. `godot --path . --headless --import`
3. Smoke-load (`--quit-after 1`)
4. Full GUT via `addons/gut/gut_cmdln.gd` (options from `.gutconfig.json`)
