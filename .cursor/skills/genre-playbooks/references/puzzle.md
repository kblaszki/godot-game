# Puzzle (lab)

## Sim

- Board model single source of truth; legal moves; resolve until stable.
- Cascades/undo with full snapshot including `SeededRng` state for refills.
- Solvable generation or authored levels (`procedural-gen` / `level-design`).
- Lock input acceptance until stable (flag in sim).

## App

- Tile/mesh mirror; swap/fall tweens (`game-feel`); HUD score (`game-ui-ux`).

## Compose

`sim-data-resources` · `level-design` · `procedural-gen` · `game-feel` · `godot-2d-presentation` · `save-systems`
