---
name: sim-bot-ai
description: >-
  Add headless bot/NPC decisions in games/<game>/sim/ — utility scoring, FSM,
  small behavior trees, AStarGrid2D pathing — acting only through the public
  sim API. Use when adding bots, enemy AI, pathfinding, utility AI, or when a
  bot should finish a match in GUT.
---

# Sim bot AI

Owner: `games/<game>/sim/` (`RefCounted`). Models: `district_bot.gd`,
`minigolf_bot.gd`. Bots never touch Nodes or Input.

Adapted from awesome-gamedev-agent-skills (`game-ai`,
`ai-behavior-trees-utility-ai`), Apache-2.0; rewritten for godot-game Headless First.

## When to use / not

- Use for hotseat bots, NPC decisions, grid pathing inside the sim.
- Not for Godot `NavigationAgent*` as rule authority → optional app visualization
  only. Juice for bot actions → `game-feel`.

## Workflow

1. Expose intents via the same public API humans use (`bot_act`, aim/power, buy).
2. Pick model: few states → FSM; continuous options → utility; reactive stacks → BT.
3. Path with `AStarGrid2D` (`RefCounted`) or a plain grid A*; recompute sparsely.
4. Inject `SeededRng` when choices are random.
5. GUT: bot reaches a terminal phase; same seed → same action sequence.

## Patterns

### Utility over public API

```gdscript
# Prefer scoring legal actions, then call sim methods — never mutate private state.
func choose_action(sim) -> void:
	var best_score := -INF
	var best: Callable
	for action in _legal_actions(sim):
		var s := _score(action, sim)
		if s > best_score:
			best_score = s
			best = action
	best.call()
```

### Tiny FSM

```gdscript
class_name BotState
extends RefCounted
func enter(_bot) -> void: pass
func update(_bot, _sim) -> BotState: return null  # null = stay
func exit(_bot) -> void: pass
```

### Grid path

Build `AStarGrid2D`, set solid cells from sim board data, `get_id_path`. Keep the
path cached; repath when the goal cell changes.

## Pitfalls

- Bot reaches into private sim fields → brittle; use public API only.
- Path every tick → slow; timer or cell-change repath.
- Decision logic in `app/` → untestable without a window.
- Unseeded random among ties → flaky GUT.

## Verify

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/games/<name>
```

Include a test where a bot finishes a short match / hole.

## Docs to update

`games/<game>/docs/reference/sim.md`, `explanation/flow.md` sequence if bots join.
