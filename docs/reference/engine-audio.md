---
title: Engine audio
diataxis: reference
audience: [ai, human]
related_code:
  - engine/null_audio.gd
  - lab/godot_audio.gd
  - tests/mocks/audio_spy.gd
  - tests/engine/null_audio_test.gd
related_docs:
  - ../index.md
  - ../explanation/architecture.md
  - lab-shell.md
  - source-layout.md
keywords: [audio, NullAudio, GodotAudio, AudioSpy, duck-typing]
last_reviewed: 2026-11-02
---

# Engine audio

Duck-typed playback port: any audio object exposes `play(sound_id: StringName, volume: float = 1.0)`. Sims never call audio; apps react to sim events.

```mermaid
classDiagram
  class NullAudio {
    +play(sound_id, volume)
  }
  class AudioSpy {
    +calls
    +play(sound_id, volume)
  }
  class GodotAudio {
    +register_blip(id, hz, seconds)
    +play(sound_id, volume)
  }
  NullAudio --|> RefCounted
  AudioSpy --|> RefCounted
  GodotAudio --|> Node
```

## NullAudio

`engine/null_audio.gd` — headless no-op. Default when no host audio is found.

## AudioSpy

`tests/mocks/audio_spy.gd` — records `{id, volume}` for GUT assertions.

## GodotAudio

`lab/godot_audio.gd` — Node adapter (outside `engine/` because it uses the scene tree). Builds short square mono `AudioStreamWAV` blips via `register_blip`, plays through a pool of `AudioStreamPlayer` voices.

Snake host constructs `GodotAudio`, registers `eat` / `die`, and exposes `get_audio()`. Play walks parents for `get_audio` and plays on `ate` / `game_over` events.
