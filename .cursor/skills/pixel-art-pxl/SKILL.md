---
name: pixel-art-pxl
description: >-
  Create pixel art for lab games with the vendored pxl DSL — sprites, sheets,
  tiles, icons, animations — then import PNGs into Godot with nearest filtering
  and PxlSheet JSON. Use when drawing sprites, tilesets, icons, palette swaps,
  or iterating 2D game art as code.
---

# Pixel art with pxl (lab)

Owner: sources under `art/<game-or-demo>/*.px.js`; committed PNGs under
`games/<game>/assets/pxl/` or `assets/<demo>/`. App presentation only — sim never
loads PNGs (Headless First).

Adapted from [crsolver/claude-pxl](https://github.com/crsolver/claude-pxl) (MIT);
CLI vendored at `tools/pxl/` (see `tools/pxl/VENDOR.md`).

`PXL` below means `node tools/pxl/bin/pxl.js`. Needs Node ≥ 22.18 (repo CI/dev: 26.x).

## When to use / not

- Use for 2D sprites, tiles, icons, sheets, short animations, palette variants.
- Not for 3D meshes → `godot-3d-presentation` / `game-assets` greybox.
- Not for gameplay rules → sim skills. Cross-art direction → `game-assets`.

## Workflow

1. **Write** `art/<name>/<file>.px.js` with a locked palette (`pal` / `use` + `ramps`).
2. **Build scratch** (previews for QA):
   ```sh
   PXL=node\ tools/pxl/bin/pxl.js
   $PXL build art/<name>/<file>.px.js
   # reads art/<name>/out/_preview/*.png and `PXL ascii … <asset>`
   ```
3. **Iterate** with `$PXL build … --only slime,heart` until silhouettes read.
4. **Commit outputs** without previews into the game/demo assets tree:
   ```sh
   $PXL build art/<name>/<file>.px.js \
     --out assets/pixel_demo --no-preview
   # or: --out games/<game>/assets/pxl --no-preview
   ```
5. **Import** in Godot (`godot --path . --headless --import`). Display with
   `texture_filter = TEXTURE_FILTER_NEAREST`; parse sheets via `PxlSheet`.
6. Optional live watch: `$PXL serve art/<name>/<file>.px.js` (background).

Full API: [references/reference.md](references/reference.md). Lighting only when
needed: [references/lighting.md](references/lighting.md). How-to:
`docs/how-to/make-pixel-art.md`.

## Template

```js
pal({ k: "#1b1630", g: "#8ccf63", G: "#4c8a44", t: "#2a5560", w: "#fff6e0",
      r: "#e2585e", R: "#a63a4c", b: "#5b8def", B: "#3a5fad", o: "#e8b84a" })
ramps("ktGg", "kRr", "kbB")

sprite("slime", { mx: true, outline: "k" }, `
  ....ggg
  ..ggGGg
  .ggGwGg
  gggkwgg
  tgggggg
  .tttttt`)
sprite("slime_red", { base: "slime", swap: { g: "r", G: "R" } })

sheet("demo_sprites", ["slime*", "heart"], { pad: 1 })
```

## Habits

- Half of anything symmetric (`mx`) + `outline`; recolors via `base` + `swap`.
- Parts (`_name`) + `stamp`; families via loops / `group`.
- Large areas: primitives, `grad`, `pattern`, `tilemap` — not giant hand grids.
- Organic texture: tiny brush parts + `scatter` with `on`/`clip`.
- **No filler noise** on flat walls; every mark needs a cause.
- 2–4 shades per material; mnemonic keys (`g`/`G`).
- Align palette with `game-assets` lab lock when shipping into a title.

## Godot import

- Prefer `PxlSheet.parse(json_text)` for TexturePacker / anim JSON (no hand rects).
- Nearest filter on sprites; avoid mipmaps on pixel art.
- Keep `art/**/out/` gitignored; commit only `--no-preview` asset trees.

## Verify

```sh
node tools/pxl/bin/pxl.js build art/<name>/<file>.px.js --out /tmp/pxl-check
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/engine
```

## Docs to update

`docs/how-to/make-pixel-art.md`, game `app.md` if a title consumes new sheets,
`docs/reference/source-layout.md` for new art paths.
