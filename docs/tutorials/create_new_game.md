---
title: Create a new game
diataxis: tutorial
audience: [ai, human]
related_code: [games/, tests/games/, engine/]
related_docs:
  - ../index.md
  - ../how-to/add-a-game.md
  - ../explanation/architecture.md
  - ../how-to/write-headless-tests.md
keywords: [tutorial, new-game, walkthrough]
last_reviewed: 2026-11-01
---

# Create a new game

End-to-end path for the first (or next) title in this lab.

1. Read [architecture.md](../explanation/architecture.md) and [add-a-game.md](../how-to/add-a-game.md).
2. Pick a short `<name>` (folder-safe, unique `class_name` prefixes if needed).
3. Scaffold folders: `games/<name>/{sim,app,docs}` and `tests/games/<name>/`.
4. Implement one tiny sim type (for example a score or board step) as `RefCounted`.
5. Write a GUT test that fails, then make it pass ([write-headless-tests.md](../how-to/write-headless-tests.md)).
6. Add a minimal `app/` scene that displays or drives that sim state — no new rules in the scene script.
7. Document the game under `games/<name>/docs/` and link it from [docs/index.md](../index.md).
8. Verify with the commands in [build-and-test.md](../how-to/build-and-test.md).

There is no sample game in the empty lab yet; the first title becomes the model for later ones.
