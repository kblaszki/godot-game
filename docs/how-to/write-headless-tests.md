---
title: Write headless tests
diataxis: how-to
audience: [ai, human]
related_code: [tests/, engine/, games/]
related_docs:
  - ../index.md
  - build-and-test.md
  - ../explanation/architecture.md
keywords: [gut, tests, headless, sim]
last_reviewed: 2026-11-01
---

# Write headless tests

## Where suites live

| Code under | Tests under |
|------------|-------------|
| `engine/` | `tests/engine/` |
| `games/<name>/sim/` or `app/` | `tests/games/<name>/` |

Name scripts `*_test.gd`. Prefer behavioral names like `test_score_should_increase_on_clear`.

## Rules

- Extend GUT's test base and construct `RefCounted` sim/engine types directly.
- Do not open windows or depend on the editor viewport.
- When the mechanic uses RNG, assert **same-seed determinism** (two sims with the same seed produce the same outcomes).
- Do not put rules into the test that belong in `sim/` — tests exercise the real type.

## Run

See [build-and-test.md](build-and-test.md). GUT must be installed under `addons/gut/`.
