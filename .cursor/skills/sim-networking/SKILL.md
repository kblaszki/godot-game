---
name: sim-networking
description: >-
  Keep the sim authoritative for multiplayer — commands through NetworkPort /
  LocalHotseatPort, lockstep or command queues, MultiplayerAPI/RPC only in an
  app adapter. Use when adding online play, RPCs, host/client sync, or
  hotseat ports that must stay headless-testable.
---

# Sim networking

Owner: ports and command application in `games/<game>/sim/`. Godot
`MultiplayerAPI` / RPC / ENet live only in `games/<game>/app/` adapters.

Adapted from awesome-gamedev-agent-skills (`godot-multiplayer`), Apache-2.0;
rewritten for godot-game Headless First.

## When to use / not

- Use when moving beyond local hotseat toward online or split transports.
- Not for UI lobbies alone → `game-ui-ux`. Save download → `save-systems`.

## Workflow

1. Define a command Dictionary schema (action name + args + tick/player id).
2. Sim applies commands in deterministic order; never trusts remote state blobs.
3. Implement `NetworkPort` for the transport; keep `LocalHotseatPort` for tests.
4. App adapter maps RPC ↔ port `send_action` / `poll_actions`.
5. GUT: same command stream → identical sim snapshots (lockstep determinism).

## Patterns

### Port interface (existing)

```gdscript
# games/districts/sim/network_port.gd
class_name NetworkPort
extends RefCounted

func is_online() -> bool: return false
func send_action(_action: Dictionary) -> void: pass
func poll_actions() -> Array: return []
func disconnect_session() -> void: pass
```

`LocalHotseatPort` feeds local UI/bot actions into the same `MatchSession` path.

### Lockstep sketch

```gdscript
func on_tick() -> void:
	var cmds: Array = _port.poll_actions()
	cmds.sort_custom(func(a, b): return a["player"] < b["player"])
	for c in cmds:
		_sim.apply_command(c)
	_sim.step()  # FixedTick
```

### App adapter boundary

RPC handlers only translate to `send_action`; they do not mutate board rules.

## Pitfalls

- RPC that directly edits money/HP → cheat surface; apply via sim commands.
- Sim calling `MultiplayerAPI` → Node/engine dependency.
- Nondeterministic iteration order of Dictionaries → sort commands explicitly.
- Mixing prediction without reconcile → desync; start with lockstep/hotseat.

## Verify

Hotseat port drives a full match in GUT; duplicate command logs match state hashes.

## Docs to update

`games/<game>/docs/reference/sim.md`, explanation sequence for session/port.
