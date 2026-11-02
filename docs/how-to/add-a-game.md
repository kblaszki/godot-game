---
title: Add a game
diataxis: how-to
audience: [ai, human]
related_code: [games/, tests/games/, docs/, lab/launcher.gd]
related_docs:
  - ../index.md
  - ../tutorials/create_new_game.md
  - ../explanation/architecture.md
  - ../reference/source-layout.md
  - ../reference/lab-shell.md
keywords: [add-game, scaffold, sim, app, launcher]
last_reviewed: 2026-11-02
---

# Add a game

Checklist (also encoded in the `add-game` skill):

1. Create `games/<name>/sim/`, `games/<name>/app/`, `games/<name>/docs/`.
2. Put rules in `sim/` as `RefCounted` (Headless First).
3. Add GUT suites under `tests/games/<name>/` **before** polishing scenes.
4. Add presentation under `app/` with a **host** that extends `lab/layered_host.gd` (`games/<name>/app/host.tscn` is the game entry).
5. Override host `_on_quit_requested` to call lab `return_to_launcher` (deferred) when nested; fallback to `get_tree().quit()` standalone.
6. Register the game in [`lab/launcher.gd`](../../lab/launcher.gd) `GAMES` as `{title, host_path}`.
7. Write `games/<name>/docs/index.md`, `reference/sim.md`, `reference/app.md`, and an explanation with a Mermaid `stateDiagram-v2`.
8. Add a row to the Game documentation table in [docs/index.md](../index.md).
9. Update [source-layout.md](../reference/source-layout.md).
10. Smoke-load the project and run GUT for `res://tests/games/<name>`.
