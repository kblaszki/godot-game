---
name: godot-app-scripting
description: >-
  Write Godot 4.3 app/presentation scripts — Node lifecycle, signals, scenes,
  LayeredHost/SceneRequest flow — without putting rules in Nodes. Use when
  editing games/<game>/app scripts, wiring menus, hosts, or signal glue.
---

# Godot app scripting

Owner: `games/<game>/app/`, `lab/`. Conventions: `.cursor/rules/gdscript-conventions.mdc`.
Sim rules stay in `sim/` — this skill is the Node shell only.

Adapted from awesome-gamedev-agent-skills (`godot-gdscript`, `godot-nodes-scenes`,
`godot-signals-groups`), Apache-2.0; rewritten for godot-game Headless First.

## When to use / not

- Use for hosts, menus, play scenes, signal wiring, PackedScene instancing.
- Not for movement/economy rules → sim skills. Not for GUT runners →
  `run-build-and-tests`.

## Workflow

1. Typed GDScript; `class_name` only when shared; scene scripts beside `.tscn`.
2. Read sim state/events; call public sim APIs; never reimplement rules.
3. Scene flow via `SceneRequest` / `SceneStack` / `LayeredHost` — not ad-hoc flags.
4. Prefer signals or explicit host callbacks over autoload god-objects.
5. After new `class_name`, `godot --path . --headless --import`.

## Patterns

### Host owns sim

```gdscript
# host.gd constructs sim, passes it into play; quit pops LayeredHost
func configure_match(...) -> void:
	_sim = DistrictSim.new(config, seed)
```

### SceneRequest

Push/pop/replace/quit through `engine/scene_request.gd` — see
`docs/reference/lab-shell.md` and `engine-scene-stack.md`.

### Signals as edges

App listens to sim-emitted events (or polls a drain queue) to update HUD/meshes.

## Pitfalls

- Rules in `_process` → move to sim tick.
- Autoload holding game state → prefer host-scoped sim.
- Untyped Variant inference treated as error in strict projects — annotate returns.

## Verify

`host_flow` GUT + smoke load. Docs: `games/<game>/docs/reference/app.md`.
