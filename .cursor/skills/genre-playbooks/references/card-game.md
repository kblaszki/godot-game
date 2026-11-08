# Card game (lab)

## Sim

- Card defs as data; zones deck/hand/play/discard; exactly one zone each.
- Draw/shuffle via `SeededRng`; phase machine; effect interpreter (ops list).
- Atomic play: validate cost+targets then commit.
- Bots pick legal plays (`sim-bot-ai`). Model: Districts chance/gadgets spirit.

## App

- Hand layout, drag/tap (`game-ui-ux`); card motion juice (`game-feel`).

## Compose

`sim-data-resources` · `sim-bot-ai` · `save-systems` · `game-ui-ux` · `game-feel` · `game-audio`
