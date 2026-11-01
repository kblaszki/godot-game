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
- For unit tests: install **GUT** into `addons/gut/` (Asset Library or vendor the addon). It is not shipped with the empty lab stub.

## Smoke-load the project

```sh
godot --path . --headless --quit-after 1
```

## Run GUT (headless)

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

Narrow scope:

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/engine -gexit
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/games/<name> -gexit
```

Always use `--headless`. Suites must not require an open editor window.
