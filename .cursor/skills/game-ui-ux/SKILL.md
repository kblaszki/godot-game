---
name: game-ui-ux
description: >-
  Build lab game HUDs and menus — anchors, containers, corner docks, focus
  navigation, event-driven updates on LayeredHost stacks. Use when adding HUD,
  pause/settings, phase docks, scaling, safe areas, or gamepad menu focus.
---

# Game UI/UX

Owner: `games/<game>/app/` Control scenes. Model: Districts corner HUD + phase docks.

Adapted from awesome-gamedev-agent-skills (`game-ui-ux`, `godot-ui-control`),
Apache-2.0; rewritten for godot-game Headless First.

## When to use / not

- Use for HUD, menus, overlays, focus, stretch/scale.
- Not for dialogue graph logic → `dialogue-systems`. Juice pops → `game-feel`.
- Screen stack → `LayeredHost` / `SceneRequest` (`godot-app-scripting`).

## Workflow

1. Anchors + containers; never absolute 1080p pixel positions.
2. Drive HUD from sim events / phase changes — avoid polling every frame when
   a signal/drain exists.
3. Grab focus on screen show; set neighbors where auto-guess fails.
4. Stretch: project canvas_items + expand (see project settings); corner-anchor HUD.
5. Host_flow GUT for push/pop; visual check at multiple window sizes.

## Patterns

### Corner HUD

Anchor score/phase labels to corners; phase actions in a bottom dock
(`games/districts/app/play.tscn` pattern).

### Event update

```gdscript
func _on_phase_changed(phase: StringName) -> void:
	_refresh_dock(phase)
```

### Focus

```gdscript
func _on_shown() -> void:
	$PlayButton.grab_focus()
```

## Pitfalls

- Boolean menu flag soup → use scene stack.
- Polling `player.hp` in `_process` → couple to events.
- No initial focus → gamepad dead on menus.

## Verify

`host_flow` GUT; docs `games/<game>/docs/reference/app.md`.
