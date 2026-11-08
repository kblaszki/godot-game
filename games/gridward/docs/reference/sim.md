---
title: Gridward sim
diataxis: reference
audience: [ai, human]
related_code:
  - games/gridward/sim/
related_docs:
  - ../index.md
  - ../spec.md
  - ../explanation/flow.md
  - ../../../../docs/explanation/architecture.md
keywords: [gridward, sim, stub, headless]
last_reviewed: 2026-11-08
---

# Gridward sim

`games/gridward/sim/` is a placeholder. It holds no `RefCounted` types yet. Match rules (grid, waves, towers, gold, lives) stay out of `app/` and arrive in later plans. The directory must stay free of `Node`, the scene tree, wall-clock `Time`, unseeded RNG, and `FileAccess`.

Planned phase names (`build`, `wave`) are stubs in [flow.md](../explanation/flow.md). Product numbers live in [spec.md](../spec.md) and are not implemented here.
