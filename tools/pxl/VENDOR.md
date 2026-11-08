# Vendored: crsolver/claude-pxl

| Field | Value |
|-------|-------|
| Upstream | https://github.com/crsolver/claude-pxl |
| Commit | `21fee41f7ecce00bc868d7567f24ffd0f3acc8fa` |
| License | MIT (see `LICENSE`) |
| Vendored on | 2026-11-08 |

## Included paths

`bin/`, `src/`, `types/`, `package.json`, `LICENSE`, `README.md`, `examples/basics.px.js`.

Skipped: `test/`, large `examples/`, `scripts/`, gallery docs, and upstream skill files
(adapted under `.cursor/skills/pixel-art-pxl/` instead).

## Do not edit

Treat this tree as read-only. Lab-specific workflow lives in the Cursor skill and
`docs/how-to/make-pixel-art.md`.

## Update procedure

```sh
TMP=$(mktemp -d)
git clone --depth 1 https://github.com/crsolver/claude-pxl.git "$TMP/claude-pxl"
cd "$TMP/claude-pxl"
git fetch --depth 1 origin <NEW_SHA>
git checkout <NEW_SHA>
DEST=/path/to/godot-game/tools/pxl
rm -rf "$DEST/bin" "$DEST/src" "$DEST/types" "$DEST/examples"
cp -a bin src types package.json LICENSE README.md "$DEST/"
mkdir -p "$DEST/examples"
cp examples/basics.px.js "$DEST/examples/"
# Update the SHA and date in this file, then:
node "$DEST/bin/pxl.js" build "$DEST/examples/basics.px.js" --out /tmp/pxl-smoke
```

## Smoke

```sh
node tools/pxl/bin/pxl.js build tools/pxl/examples/basics.px.js --out /tmp/pxl-smoke
```
