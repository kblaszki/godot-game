---
name: godot-shaders
description: >-
  Author Godot 4.3 canvas_item and spatial shaders for presentation only —
  outlines, dissolve, fairway tint — never as sim rules. Use when writing
  .gdshader materials, UVs, fragment effects, or debugging shader compile errors.
---

# Godot shaders (presentation)

Owner: materials under `games/<game>/app/` or `assets/`. Shaders must not own
gameplay truth (hit detection, fog-of-war logic belongs in sim data).

Adapted from awesome-gamedev-agent-skills (`godot-shaders`, `shader-programming`),
Apache-2.0; rewritten for godot-game Headless First / Godot **4.3**.

## When to use / not

- Use for visual polish: outline, flash, water, card sheen.
- Not for replacing collision or FOV rules → sim. Cross-engine theory only —
  bind to Godot shading language here.

## Workflow

1. Choose `shader_type canvas_item;` (2D) or `spatial;` (3D).
2. Prefer `StandardMaterial3D` until a custom effect is required.
3. Keep uniforms documented; expose via `ShaderMaterial` on MeshInstance/Sprite.
4. Test in editor; headless GUT cannot assert pixels — guard optional.
5. Document the effect in the game app reference.

## Patterns

### Canvas flash

```glsl
shader_type canvas_item;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = mix(c, flash_color, flash_amount);
}
```

### Spatial note (4.3)

Use documented render modes for Forward Plus; avoid 4.7-only light APIs.

## Pitfalls

- Gameplay branching on shader output → unreproducible in GUT.
- Huge fill-rate full-screen effects → see `performance-optimization`.

## Verify

Visual check; keep material paths in `games/<game>/docs/reference/app.md`.
