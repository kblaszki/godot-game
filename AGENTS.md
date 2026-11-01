# Agent guide: godot-game

This is a Godot **4.x** game lab using typed **GDScript**. Shared code lives in `engine/`. Games live under `games/<name>/` with headless `sim/` and presentation `app/`. This file is a tool-neutral summary. The full rules live in [`.cursor/rules/`](.cursor/rules) and the task skills in [`.cursor/skills/`](.cursor/skills).

## Verify

```sh
godot --path . --headless --quit-after 1
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

GUT must be installed under `addons/gut/` before unit tests can run. Details: [`docs/how-to/build-and-test.md`](docs/how-to/build-and-test.md).

## Where to read first

| Task | Read |
|------|------|
| Engine work | [`docs/explanation/architecture.md`](docs/explanation/architecture.md), [`docs/reference/source-layout.md`](docs/reference/source-layout.md) |
| An existing game | `games/<game>/docs/index.md` |
| A new game | [`docs/tutorials/create_new_game.md`](docs/tutorials/create_new_game.md), [`docs/how-to/add-a-game.md`](docs/how-to/add-a-game.md) |
| Tests | [`docs/how-to/write-headless-tests.md`](docs/how-to/write-headless-tests.md) |

The map of engine docs is [`docs/index.md`](docs/index.md). Each game has its own Diátaxis tree under `games/<game>/docs/`. Prefer real type and path names from this repo. Do not invent generic managers (`SceneManager`, `InputManager`, …) unless they are documented here.

## Non-negotiables

1. **Headless First.** Mechanics live in `games/<game>/sim/` as `RefCounted` (no `Node`, no scene tree, seeded RNG, fixed tick) and are tested before presentation. See [headless-first.mdc](.cursor/rules/headless-first.mdc).
2. **Docs in the same change.** Every new engine feature or game mechanic gets a Diátaxis entry, in `docs/` for the engine or `games/<game>/docs/` for a game. Architecture and state-flow changes include a Mermaid diagram. Update docs whose `related_code` lists files you changed, and set `last_reviewed`. See [documentation.mdc](.cursor/rules/documentation.mdc).
3. **Test new behavior.** Add or extend GUT suites under `tests/engine/` or `tests/games/<name>/`. Suites run headless.
4. **Surgical, verified, committed.** Keep changes minimal (see [golden-rule.mdc](.cursor/rules/golden-rule.mdc)), and commit each verified unit with explicit paths. Never commit `.godot/` cache or secrets.

## Conventions

Typed GDScript; `class_name` PascalCase; methods/vars `snake_case`. Sim and shared engine libraries extend `RefCounted`, not `Node`. Details: [gdscript-conventions.mdc](.cursor/rules/gdscript-conventions.mdc) and [godot-and-tests.mdc](.cursor/rules/godot-and-tests.mdc).
