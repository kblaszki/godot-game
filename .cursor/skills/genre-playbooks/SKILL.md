---
name: genre-playbooks
description: >-
  Compose a lab game genre from Headless First skills — platformer, roguelike,
  RPG, FPS, tower defense, card game, visual novel, survival-crafting, puzzle.
  Use when starting a genre title, scoping sim vs app systems, or asking which
  skills to load for a game type.
---

# Genre playbooks

Dispatcher for genre templates. Each genre splits into **sim systems** (rules,
SeededRng, FixedTick, GUT) and **app systems** (scenes, juice, UI). Read only the
matching `references/<genre>.md`.

Adapted from awesome-gamedev-agent-skills genre skills (platformer, roguelike,
rpg, fps-shooter, tower-defense, card-game, visual-novel, survival-crafting,
puzzle), Apache-2.0; rewritten for godot-game Headless First.

## When to use / not

- Use when the user names a genre or "make a deckbuilder/roguelike/…".
- Not for a single mechanic spike → `prototype-mechanic`. Scaffolding folders →
  `add-game`.

## Workflow

1. Identify the dominant genre; open its reference below.
2. Implement sim systems first with GUT; then app presentation.
3. Compose listed local skills; do not re-teach their primitives here.
4. Register the game via `add-game` / lab launcher when ready.

## Genre index

| Genre | Reference | Core sim idea |
|-------|-----------|---------------|
| platformer | [references/platformer.md](references/platformer.md) | run/jump ticks, coyote/buffer |
| roguelike | [references/roguelike.md](references/roguelike.md) | grid turns, FOV, proc dungeon |
| rpg | [references/rpg.md](references/rpg.md) | stats, inventory, quests |
| fps-shooter | [references/fps-shooter.md](references/fps-shooter.md) | hitscan/projectiles in sim |
| tower-defense | [references/tower-defense.md](references/tower-defense.md) | waves, towers, economy |
| card-game | [references/card-game.md](references/card-game.md) | zones, effects, phases |
| visual-novel | [references/visual-novel.md](references/visual-novel.md) | dialogue graph + flags |
| survival-crafting | [references/survival-crafting.md](references/survival-crafting.md) | gather, craft, needs |
| puzzle | [references/puzzle.md](references/puzzle.md) | board resolve, undo |

## Pitfalls

- Building the genre in scene scripts first → violates Headless First.
- Loading all nine references → pick one dominant genre.
- Shipping without GUT for the resolution loop → unfair / undebugable.

## Verify

Per-game GUT under `tests/games/<name>/`; docs under `games/<name>/docs/`.
