---
title: Build and test
diataxis: how-to
audience: [ai, human]
related_code: [project.godot, tests/, addons/gut/]
related_docs:
  - ../index.md
  - write-headless-tests.md
  - ../reference/source-layout.md
keywords: [godot, gut, headless, verify]
last_reviewed: 2026-11-01
---

# Build and test

## Prerequisites

- Godot **4.x** on `PATH` as `godot` (or use the full binary path)
- **GUT 9.3.1** is vendored at `addons/gut/` and enabled via `editor_plugins` in `project.godot`

## Smoke-load the project

```sh
godot --path . --headless --quit-after 1
```

## Run GUT (headless)

Test scripts are named `*_test.gd`. Pass an empty prefix and that suffix so GUT finds them (default prefix is `test_`).

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests -ginclude_subdirs \
  -gprefix="" -gsuffix="_test.gd" -gexit
```

Narrow scope:

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/engine -gprefix="" -gsuffix="_test.gd" -gexit
godot --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/games/<name> -gprefix="" -gsuffix="_test.gd" -gexit
```

Always use `--headless`. Suites must not require an open editor window.
