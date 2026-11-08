---
name: dialogue-systems
description: >-
  Build branching dialogue as sim data — node graph, conditions, variables,
  line IDs — with app UI rendering text and choices. Use when adding NPC
  conversations, branching narrative, Ink/Yarn-like flow, or dialogue flags
  that affect later sim state.
---

# Dialogue systems

Owner: graph + runner under `games/<game>/sim/` (`RefCounted`). Presentation
(textbox, portraits, choice buttons) under `games/<game>/app/`.

Adapted from awesome-gamedev-agent-skills (`dialogue-systems`), Apache-2.0;
rewritten for godot-game Headless First.

## When to use / not

- Use for branching conversations, narrative flags, choice gates.
- Not for HUD layout → `game-ui-ux`. Persist flags → `save-systems`.

## Workflow

1. Prefer a small JSON/Dictionary graph + runner over inventing a language.
2. Nodes yield: line, choices, command/set, end/jump.
3. Variables live in a store the runner reads/writes; gate choices with `if`.
4. Author **line IDs**, not raw display strings (localization table in app).
5. GUT walks every branch; unreachable / dead-end nodes fail the suite.

## Patterns

### Graph data

```gdscript
const GUARD := {
	"start": "intro",
	"nodes": {
		"intro": {
			"speaker": "Guard", "line": "DLG_GUARD_001",
			"choices": [
				{"text": "DLG_OPT_BRIBE", "to": "bribe", "if": "gold>=50"},
				{"text": "DLG_OPT_LEAVE", "to": "end"},
			],
		},
		"bribe": {"speaker": "Guard", "line": "DLG_GUARD_BRIBED",
			"set": {"gate_open": true}, "next": "end"},
		"end": {"end": true},
	},
}
```

### Runner advances; UI displays

Sim emits `{speaker, line_id, choices}`; app localizes and shows Controls.
`choose(index)` applies choice `set` then `goto(to)`.

## Pitfalls

- Mutating gold on a revisit-able line node → double charge; set on transition.
- Hardcoded UI strings → localization rewrite.
- Runner in a scene script → untestable; keep graph in sim.
- Dead-end node with no next/choices/end → stall; validate in GUT.

## Verify

Every node terminates; conditions hide choices; `set` flags readable by sim.

## Docs to update

`games/<game>/docs/reference/sim.md` + app reference for the dialogue UI.
