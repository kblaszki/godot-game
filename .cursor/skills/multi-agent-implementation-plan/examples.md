# Examples

## Code: grow a module in sequential waves

This tree is `engine/` (shared typed GDScript) + `games/<game>/` (`sim/` + `app/`). Contract: [`docs/explanation/architecture.md`](../../../docs/explanation/architecture.md). Prefer documented scene-flow requests over invented manager types.

| Wave | Package | Owned writes (typical) |
|------|---------|------------------------|
| 1 | Engine type | `engine/…`, `tests/engine/…`, matching `docs/reference/*` + `source-layout.md` |
| 2 | Game sim or app | `games/<game>/<sim\|app>/…`, `tests/games/<game>/…`, matching `games/<game>/docs/**/*.md` |
| 3 | Docs leftover sweep | leftover `docs/**` and `games/*/docs/**` only (`related_code`, index pages) |

Within a wave, split only if paths stay disjoint.

After each of waves 1–2:

1. Same-change Diátaxis docs for every touched file. New types update `source-layout.md` (and a new reference/how-to if behavior needs a home).
2. Hard gate: the wave diff must include a `docs/` or `games/*/docs/` path. If not, write the docs before commit.
3. `godot --path . --headless --quit-after 1` and GUT for the touched tests directory.
4. One orchestrator commit (owned paths + matching docs). Do not commit if the docs gate or verify failed.

Wave 3 is a leftover-docs audit, not the first time docs are written. Commit that sweep if it changes files.

## Docs-only fan-out

Use a docs-only fan-out only when the user asked for a written plan or documentation, not the implementation. Orchestrator commits after stitch if verify (links / contract lock) passes.
