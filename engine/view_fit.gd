class_name ViewFit
extends RefCounted


## Uniform scale + centered offset so content fits inside viewport.
## Returns { "scale": float, "offset": Vector2 }.
static func compute(content: Vector2, viewport: Vector2) -> Dictionary:
	if content.x <= 0.0 or content.y <= 0.0 or viewport.x <= 0.0 or viewport.y <= 0.0:
		return {"scale": 1.0, "offset": Vector2.ZERO}
	var scale := minf(viewport.x / content.x, viewport.y / content.y)
	var offset := (viewport - content * scale) * 0.5
	return {"scale": scale, "offset": offset}
