---
name: prototype-mechanic
description: >-
  Spike one mechanic headless-first — written question, timebox, keep/kill
  criteria, sim+GUT before greybox app; jam scope when a deadline exists.
  Use when prototyping, vertical slice, greybox, game jam scoping, or deciding
  throwaway vs rewrite.
---

# Prototype mechanic

Validate one question fast without polluting production sims. A "keep" authorizes
a rewrite via `add-game` / `add-entity`, not a copy-paste of the spike.

Adapted from awesome-gamedev-agent-skills (`prototype-fast`, `game-jam`),
Apache-2.0; rewritten for godot-game Headless First.

## When to use / not

- Use for "is it fun?", vertical slice, jam planning.
- Not for shipping store pages → `ship-build`. Full genre build →
  `genre-playbooks`.

## Workflow

1. Write the one question + KEEP/KILL signals before coding.
2. Timebox (30–90 min mechanic; jam: budget table below).
3. Sim spike + GUT first (even ugly); greybox app second.
4. Contain under `prototypes/<idea>/` or a throwaway branch when possible.
5. KEEP → schedule real build with `add-game`/`add-entity`. KILL → log and delete.

## Patterns

### Brief

```text
QUESTION:   …
CORE VERB:  …
THROWAWAY?: yes/no
TIMEBOX:    …
KEEP IF:    …
KILL IF:    …
```

### Jam buffer

Reserve ~20% of the clock for export/page/submit. Submit early; core loop by
first third of the clock or cut. Prep empty Godot project + export once before
theme drop when rules allow.

### Headless slice

`RefCounted` sim → GUT green → minimal `app/` play scene → lab launcher only if KEEP.

## Pitfalls

- Polishing art before the verb works.
- Promoting spike code to `games/<name>/sim` unchanged.
- Missing ship buffer / jam attachment (itch jam submission ≠ page upload alone).

## Verify

GUT for the spike; playtest once with an uncoached player when possible.

## Docs

If KEEP becomes a real game, full Diátaxis under `games/<name>/docs/`.
