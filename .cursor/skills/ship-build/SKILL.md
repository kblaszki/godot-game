---
name: ship-build
description: >-
  Export Godot 4.3 builds and publish — export_presets, headless CLI export,
  itch butler channels, Steam checklist. Use when exporting, COOP/COEP web
  builds, butler push, or Steamworks onboarding. Does not sudo-install templates.
---

# Ship build

Owner: export presets / CI scripts at repo root; storefront steps are operator-run.
Export templates are a **user-owned** Godot download — if missing, stop and give
install steps; do not sudo-workaround (user rule).

Adapted from awesome-gamedev-agent-skills (`godot-export`, `itch-publish`,
`steam-publish`), Apache-2.0; rewritten for godot-game / Godot **4.3**.

## When to use / not

- Use for desktop/web export, itch upload, Steam release checklist.
- Not for jam scoping → `prototype-mechanic`. Not for multiplayer code →
  `sim-networking`.

## Workflow

1. Confirm Godot 4.3 export templates match the editor (Manage Export Templates).
2. Add presets in Project → Export → `export_presets.cfg`.
3. Headless export; smoke-test the artifact (not only the editor).
4. itch: create page, `butler login`, `butler push ./build user/game:channel`.
5. Steam: app/depots/store page/build upload checklist (operator with Steamworks).
6. Writes go to `user://` only in shipped builds.

## Patterns

### Headless export

```sh
godot --path . --headless --export-release "Linux" build/linux/game.x86_64
godot --path . --headless --export-release "Web" build/web/index.html
```

Preset names must match exactly (quote spaces).

### butler

```sh
butler push ./build/linux you/game:linux --userversion 0.1.0
butler status you/game
```

HTML5: page Kind = HTML + channel tagged playable in browser. Thread Support needs
COOP/COEP (itch toggle) or leave threads off (4.3 default).

### Runtime feature checks

```gdscript
if DisplayServer.get_name() == "headless":
	pass  # skip UI
if OS.has_feature("web"):
	pass
```

## Pitfalls

- Templates version mismatch → "No export template found".
- Writing to `res://` in export → fail; use `user://`.
- Pushing installers to itch → breaks patching; push portable folders.
- Agent installing system Godot/templates with sudo → forbidden; ask the user.

## Verify

Run exported binary; GUT still green on source. Docs: note export in how-to if added.
