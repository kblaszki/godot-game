---
name: game-assets
description: >-
  Produce cohesive lab art — palette lock, greybox primitives, procedural
  meshes, import settings under assets/ — and check them in-context. Use when
  creating sprites, tiles, textures, icons, UI art, or 3D prop style guides.
---

# Game assets

Owner: `assets/` (shared) and `games/<game>/assets/`. Prefer greybox / procedural
meshes until a mechanic is proven (`prototype-mechanic`).

Adapted from awesome-gamedev-agent-skills (`create-game-assets`), Apache-2.0;
rewritten for godot-game Headless First.

## When to use / not

- Use for visual targets, palettes, import presets, Kenney-style packs (respect
  their licenses under `assets/LICENSE*`).
- For **2D pixel sprites / tiles / icons as code**, use `pixel-art-pxl` (vendored
  `tools/pxl` DSL) instead of hand-painting PNGs.
- Not for implementing rules → sim. Shaders for effects → `godot-shaders`.

## Workflow

1. Lock a short style brief (palette, silhouette, pixel density / mesh scale).
2. Greybox with primitives (`BoxMesh`, CSG for throwaway only) matching sim metrics.
3. 2D pixel art: write `art/<name>/*.px.js`, build with `pixel-art-pxl`, import via
   `PxlSheet` + nearest filter (see `docs/how-to/make-pixel-art.md`).
4. Import: compress modes, filter, mipmaps consistent across a family.
5. Drop into the real scene (Course3D / Board3D / HUD / Pixel Gallery) for QA.
6. Document attribution; don't commit huge binaries without need.

## Patterns

### Procedural first (lab default)

Fairway Circuit and Districts already build boards from code meshes — extend that
before adding glTF packs unless art is the question.

### Palette lock

Keep 5–8 colors; reuse across UI and meshes so games feel related in the lab.

## Pitfalls

- Polishing art before the verb is fun → waste; spike greybox first.
- Mixing licenses without NOTICE/LICENSE → fix attribution.
- Editor-only assets with no import settings → noisy filtering between sprites.

## Verify

In-context screenshot/play; license files present. Docs: game app reference +
`docs/reference/source-layout.md` if new asset trees appear.
