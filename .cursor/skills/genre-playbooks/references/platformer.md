# Platformer (lab)

## Sim

- Position/velocity, gravity, jump, coyote/buffer as **tick counters** (`input-systems`, `sim-physics`).
- Hazards/goals as data; death/respawn commands.
- Same-seed if any random hazards (`SeededRng`).

## App

- Mirror body with Sprite/Anim; camera follow (`camera-systems`, `godot-2d-presentation`).
- Juice on land/hit (`game-feel`); SFX (`game-audio`).

## Compose

`sim-physics` · `input-systems` · `level-design` · `camera-systems` · `game-feel` · `godot-2d-presentation`
