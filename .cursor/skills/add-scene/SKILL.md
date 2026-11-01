---
name: add-scene
description: >-
  Adds a Godot scene (.tscn + script) under games/<name>/app and wires it into
  that game's scene flow. Use when introducing or extending game scenes (menu,
  gameplay, pause, overlays) for an existing or new game in the lab.
---

# Add a scene

Source of truth: [docs/explanation/architecture.md](../../../docs/explanation/architecture.md), [docs/how-to/add-a-game.md](../../../docs/how-to/add-a-game.md), and `games/<name>/docs/reference/app.md` when present.

Concrete game scenes live in `games/<name>/app/`, not in `engine/`. Shared helpers may live in `engine/` only if they stay headless or are documented presentation utilities.

## Checklist

```
- [ ] Create foo_scene.tscn + foo_scene.gd under games/<name>/app/
- [ ] Presentation reads sim state; does not embed new rules
- [ ] Wire into the game's scene flow per architecture contract (push/pop/replace/pause/quit style requests)
- [ ] Cover behavior with a headless test where practical (sim-facing logic under tests/games/<name>/)
- [ ] Update games/<name>/docs/reference/app.md (+ state diagram in explanation if flow changed)
- [ ] Update docs/reference/source-layout.md if a new file or suite was added
```

## Steps

1. **Role.** Menu, gameplay, pause, or overlay. Pause/result overlays should not redefine sim rules.

2. **Requests.** Change the active scene only through the lab's documented scene-flow API (see architecture). Do not invent `SceneManager` / `ScreenStack` names.

3. **Script.** Node script beside the `.tscn`. Keep `_process` / input thin; call into `sim/` for rules.

4. **Tests.** Prefer testing rule changes in sim suites. App flow tests stay headless when they exist.

5. **Docs.** Same-change Diátaxis update for the owning game.
