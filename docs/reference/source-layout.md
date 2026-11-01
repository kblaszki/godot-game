---
title: Source layout
diataxis: reference
audience: [ai, human]
related_code: [project.godot, engine/, games/, tests/, docs/, AGENTS.md]
related_docs:
  - ../index.md
  - ../explanation/architecture.md
keywords: [layout, inventory, paths, tests]
last_reviewed: 2026-11-01
---

# Source layout

Inventory of the lab tree. Update this page when paths are added, removed, or renamed.

## Root

| Path | Role |
|------|------|
| `project.godot` | Godot 4.x project (single lab) |
| `AGENTS.md` | Tool-neutral agent summary |
| `engine/` | Shared headless GDScript libraries |
| `games/` | Per-game `sim/`, `app/`, `docs/` (none yet) |
| `tests/engine/` | GUT suites for `engine/` |
| `tests/games/` | Per-game GUT suites |
| `docs/` | Cross-game Diátaxis docs |
| `addons/gut/` | GUT addon when installed |
| `.cursor/rules/` | Cursor rules |
| `.cursor/skills/` | Cursor skills |

## Games

| Game | sim | app | docs | tests |
|------|-----|-----|------|-------|
| _(none yet)_ | — | — | — | — |

## Engine modules

| Path | Notes |
|------|-------|
| `engine/` | Placeholder directory; add `class_name` libraries as needed |
