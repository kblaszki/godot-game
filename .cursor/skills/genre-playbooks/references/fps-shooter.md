# FPS shooter (lab)

## Sim

- Hitscan/projectile rays in sim space; damage, weapons, ammo (`sim-physics`).
- Enemy decisions (`sim-bot-ai`); no Camera3D ownership of aiming truth —
  aim angles are sim inputs.

## App

- `godot-3d-presentation` + first-person/`camera-systems`.
- Muzzle flash/shake (`game-feel`); HUD crosshair (`game-ui-ux`).

## Compose

`sim-physics` · `input-systems` · `sim-bot-ai` · `camera-systems` · `godot-3d-presentation` · `game-feel`
