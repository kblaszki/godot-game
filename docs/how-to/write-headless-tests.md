---
title: Write headless tests
diataxis: how-to
audience: [ai, human]
related_code: [tests/, engine/, games/, addons/gut/, .gutconfig.json]
related_docs:
  - ../index.md
  - build-and-test.md
  - ../explanation/architecture.md
  - ../reference/agent-skills.md
keywords: [gut, tests, headless, sim, exit-code, import]
last_reviewed: 2026-11-08
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

```sh
godot --path . --headless --import   # fresh checkout / new class_name
godot --path . --headless -s addons/gut/gut_cmdln.gd
```

## Headless runner pitfalls

Adapted from upstream `godot-gdscript-headless-testing` (Apache-2.0; see [NOTICE](../../NOTICE)).

- **Gate on the process exit code**, not stdout. GUT sets a non-zero exit when `should_exit` is on in [`.gutconfig.json`](../../.gutconfig.json).
- **Import before tests on a clean checkout.** Without `godot --path . --headless --import`, `class_name` types and imported assets fail to resolve.
- **Step timeout in CI.** An unresolved `await` hangs forever; put `timeout-minutes` (or equivalent) on the test step.
- **Capture stderr.** `push_error` and SCRIPT ERROR lines go to stderr; wrappers that only keep stdout can hide failures.
- **Bare `assert()` in a custom SceneTree runner** can abort before `quit(1)` and hang CI. Prefer GUT helpers (or an assert that records failure and continues).
- **Agent sandbox.** Invoking Godot from the agent Shell tool needs unrestricted permissions; the default sandbox can crash the binary.

## Related

- Skill: [run-build-and-tests](../../.cursor/skills/run-build-and-tests/SKILL.md)
- Skill map: [agent-skills.md](../reference/agent-skills.md)
