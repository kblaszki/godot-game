---
name: game-audio
description: >-
  Wire game audio through buses and NullAudio — procedural SFX, ducking,
  settings sliders in dB — with tests using the null port. Use when adding
  sound, music buses, pitch variation, or fixing silent/clipping mixes.
---

# Game audio

Owner: `games/<game>/app/` audio helpers; tests use `engine/null_audio.gd`.
Sim emits events; audio reacts in app.

Adapted from awesome-gamedev-agent-skills (`audio-design`, `godot-audio`),
Apache-2.0; rewritten for godot-game Headless First.

## When to use / not

- Use for SFX/music routing, procedural beeps, bus volumes from LabSettings.
- Not for juice timing alone → `game-feel`. Persist volumes → `save-systems`.

## Workflow

1. Buses: Master ← {Music, SFX, UI, Voice}; route every player to a bus.
2. Map 0..1 sliders via squared linear → `AudioServer.set_bus_volume_linear`.
3. Inject `NullAudio` in GUT; real players only in app.
4. Vary repeated SFX (pitch/volume jitter or `AudioStreamRandomizer`).
5. Duck music under voice/important SFX (compressor sidechain or MusicDuck bus).

## Patterns

### Null port

```gdscript
# engine/null_audio.gd
func play(_sound_id: StringName, _volume: float = 1.0) -> void:
	pass
```

Reference implementations: `district_audio.gd`, `minigolf_audio.gd`.

### Slider → bus

```gdscript
func set_bus_volume(bus_name: StringName, slider01: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	var gain := clampf(slider01, 0.0, 1.0)
	AudioServer.set_bus_mute(idx, gain <= 0.0)
	AudioServer.set_bus_volume_linear(idx, gain * gain)
```

## Pitfalls

- Treating slider as dB directly → near-silent or no change.
- Spawning unbounded `AudioStreamPlayer`s → leak; polyphony / free on finished.
- Asserting audio in headless without NullAudio → brittle.

## Verify

`tests/engine/null_audio_test.gd`; docs `docs/reference/engine-audio.md`.
