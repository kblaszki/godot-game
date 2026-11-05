class_name DistrictTileBaker
extends RefCounted

## Bakes Monopoly-style iso diamond faces as ImageTextures (no scene tree / GPU).

const WIDTH := 192
const HEIGHT := 112
const HALF_W := 88.0
const HALF_H := 48.0

const GROUP_COLORS: Array[Color] = [
	Color(0.55, 0.32, 0.18, 1),
	Color(0.45, 0.72, 0.92, 1),
	Color(0.88, 0.4, 0.72, 1),
	Color(0.95, 0.55, 0.18, 1),
	Color(0.86, 0.22, 0.22, 1),
	Color(0.94, 0.84, 0.28, 1),
	Color(0.28, 0.68, 0.38, 1),
]

# Classic 5x7 bitmap font: each glyph is 7 row masks (bit4 = left pixel).
const _GLYPH_W := 5
const _GLYPH_H := 7
const _GLYPHS := {
	" ": [0, 0, 0, 0, 0, 0, 0],
	"A": [0x0E, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11],
	"B": [0x1E, 0x11, 0x11, 0x1E, 0x11, 0x11, 0x1E],
	"C": [0x0E, 0x11, 0x10, 0x10, 0x10, 0x11, 0x0E],
	"D": [0x1E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x1E],
	"E": [0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x1F],
	"F": [0x1F, 0x10, 0x10, 0x1E, 0x10, 0x10, 0x10],
	"G": [0x0E, 0x11, 0x10, 0x17, 0x11, 0x11, 0x0F],
	"H": [0x11, 0x11, 0x11, 0x1F, 0x11, 0x11, 0x11],
	"I": [0x0E, 0x04, 0x04, 0x04, 0x04, 0x04, 0x0E],
	"J": [0x01, 0x01, 0x01, 0x01, 0x11, 0x11, 0x0E],
	"K": [0x11, 0x12, 0x14, 0x18, 0x14, 0x12, 0x11],
	"L": [0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x1F],
	"M": [0x11, 0x1B, 0x15, 0x15, 0x11, 0x11, 0x11],
	"N": [0x11, 0x19, 0x15, 0x13, 0x11, 0x11, 0x11],
	"O": [0x0E, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E],
	"P": [0x1E, 0x11, 0x11, 0x1E, 0x10, 0x10, 0x10],
	"Q": [0x0E, 0x11, 0x11, 0x11, 0x15, 0x12, 0x0D],
	"R": [0x1E, 0x11, 0x11, 0x1E, 0x14, 0x12, 0x11],
	"S": [0x0F, 0x10, 0x10, 0x0E, 0x01, 0x01, 0x1E],
	"T": [0x1F, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04],
	"U": [0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x0E],
	"V": [0x11, 0x11, 0x11, 0x11, 0x11, 0x0A, 0x04],
	"W": [0x11, 0x11, 0x11, 0x15, 0x15, 0x1B, 0x11],
	"X": [0x11, 0x11, 0x0A, 0x04, 0x0A, 0x11, 0x11],
	"Y": [0x11, 0x11, 0x0A, 0x04, 0x04, 0x04, 0x04],
	"Z": [0x1F, 0x01, 0x02, 0x04, 0x08, 0x10, 0x1F],
	"0": [0x0E, 0x11, 0x13, 0x15, 0x19, 0x11, 0x0E],
	"1": [0x04, 0x0C, 0x04, 0x04, 0x04, 0x04, 0x0E],
	"2": [0x0E, 0x11, 0x01, 0x06, 0x08, 0x10, 0x1F],
	"3": [0x1F, 0x01, 0x02, 0x06, 0x01, 0x11, 0x0E],
	"4": [0x02, 0x06, 0x0A, 0x12, 0x1F, 0x02, 0x02],
	"5": [0x1F, 0x10, 0x1E, 0x01, 0x01, 0x11, 0x0E],
	"6": [0x06, 0x08, 0x10, 0x1E, 0x11, 0x11, 0x0E],
	"7": [0x1F, 0x01, 0x02, 0x04, 0x08, 0x08, 0x08],
	"8": [0x0E, 0x11, 0x11, 0x0E, 0x11, 0x11, 0x0E],
	"9": [0x0E, 0x11, 0x11, 0x0F, 0x01, 0x02, 0x0C],
	"$": [0x04, 0x0F, 0x14, 0x0E, 0x05, 0x1E, 0x04],
	"-": [0x00, 0x00, 0x00, 0x1F, 0x00, 0x00, 0x00],
	".": [0x00, 0x00, 0x00, 0x00, 0x00, 0x0C, 0x0C],
	"'": [0x0C, 0x08, 0x08, 0x00, 0x00, 0x00, 0x00],
	"/": [0x01, 0x02, 0x04, 0x04, 0x08, 0x10, 0x10],
	":": [0x00, 0x0C, 0x0C, 0x00, 0x0C, 0x0C, 0x00],
}


static func bake(space: BoardSpace) -> ImageTexture:
	return ImageTexture.create_from_image(bake_image(space))


static func bake_image(space: BoardSpace) -> Image:
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2(WIDTH * 0.5, HEIGHT * 0.5)
	_fill_diamond(image, center + Vector2(3, 5), HALF_W, HALF_H, Color(0, 0, 0, 0.35))
	_fill_diamond(image, center, HALF_W, HALF_H, _face_color(space))
	match space.kind:
		BoardSpace.KIND_PROPERTY:
			_fill_diamond_band(image, center, HALF_W, HALF_H, 0.0, 0.34, group_color(space.group))
			_stroke_diamond(image, center, HALF_W, HALF_H, Color(0.08, 0.09, 0.11, 1), 2)
			_bevel_diamond(image, center, HALF_W, HALF_H)
			_draw_wrapped(image, space.name, center + Vector2(0, 2), 110.0, 2, Color(0.14, 0.15, 0.18, 1))
			_draw_centered(image, "$%d" % space.price, center + Vector2(0, 22), 2, Color(0.12, 0.35, 0.28, 1))
			_draw_centered(image, "rent $%d" % space.rent, center + Vector2(0, 36), 1, Color(0.35, 0.38, 0.42, 1))
		BoardSpace.KIND_TAX:
			_stroke_diamond(image, center, HALF_W, HALF_H, Color(0.08, 0.09, 0.11, 1), 2)
			_bevel_diamond(image, center, HALF_W, HALF_H)
			_draw_coin(image, center + Vector2(0, -18))
			_draw_wrapped(image, space.name, center + Vector2(0, 4), 108.0, 2, Color(0.28, 0.2, 0.1, 1))
			_draw_centered(image, "tax $%d" % space.tax, center + Vector2(0, 28), 2, Color(0.55, 0.28, 0.12, 1))
		BoardSpace.KIND_GO:
			_stroke_diamond(image, center, HALF_W, HALF_H, Color(0.08, 0.09, 0.11, 1), 2)
			_bevel_diamond(image, center, HALF_W, HALF_H)
			_draw_arrow(image, center + Vector2(0, -16), Color(0.15, 0.45, 0.3, 1))
			_draw_wrapped(image, space.name, center + Vector2(0, 8), 110.0, 2, Color(0.1, 0.28, 0.18, 1))
			_draw_centered(image, "GO", center + Vector2(0, 28), 2, Color(0.12, 0.4, 0.25, 1))
		BoardSpace.KIND_JAIL:
			_stroke_diamond(image, center, HALF_W, HALF_H, Color(0.08, 0.09, 0.11, 1), 2)
			_bevel_diamond(image, center, HALF_W, HALF_H)
			_draw_bars(image, center + Vector2(0, -16), Color(0.25, 0.28, 0.38, 1))
			_draw_wrapped(image, space.name, center + Vector2(0, 8), 108.0, 2, Color(0.18, 0.2, 0.28, 1))
			_draw_centered(image, "JAIL", center + Vector2(0, 28), 2, Color(0.3, 0.32, 0.4, 1))
		BoardSpace.KIND_GOTO_JAIL:
			_stroke_diamond(image, center, HALF_W, HALF_H, Color(0.08, 0.09, 0.11, 1), 2)
			_bevel_diamond(image, center, HALF_W, HALF_H)
			_draw_point(image, center + Vector2(0, -16), Color(0.55, 0.18, 0.16, 1))
			_draw_wrapped(image, space.name, center + Vector2(0, 8), 108.0, 2, Color(0.4, 0.14, 0.12, 1))
			_draw_centered(image, "GO TO JAIL", center + Vector2(0, 28), 1, Color(0.5, 0.16, 0.14, 1))
		BoardSpace.KIND_FREE:
			_stroke_diamond(image, center, HALF_W, HALF_H, Color(0.08, 0.09, 0.11, 1), 2)
			_bevel_diamond(image, center, HALF_W, HALF_H)
			_draw_tree(image, center + Vector2(0, -16), Color(0.18, 0.48, 0.4, 1))
			_draw_wrapped(image, space.name, center + Vector2(0, 8), 108.0, 2, Color(0.12, 0.32, 0.3, 1))
			_draw_centered(image, "FREE", center + Vector2(0, 28), 2, Color(0.16, 0.4, 0.36, 1))
		_:
			_stroke_diamond(image, center, HALF_W, HALF_H, Color(0.08, 0.09, 0.11, 1), 2)
			_draw_centered(image, space.name, center, 2, Color(0.15, 0.16, 0.18, 1))
	return image


static func group_color(group: int) -> Color:
	if group < 0 or group >= GROUP_COLORS.size():
		return Color(0.5, 0.5, 0.55, 1)
	return GROUP_COLORS[group]


static func _face_color(space: BoardSpace) -> Color:
	match space.kind:
		BoardSpace.KIND_PROPERTY:
			return Color(0.93, 0.91, 0.84, 1)
		BoardSpace.KIND_TAX:
			return Color(0.94, 0.88, 0.72, 1)
		BoardSpace.KIND_GO:
			return Color(0.72, 0.9, 0.78, 1)
		BoardSpace.KIND_JAIL:
			return Color(0.78, 0.8, 0.86, 1)
		BoardSpace.KIND_GOTO_JAIL:
			return Color(0.9, 0.72, 0.7, 1)
		BoardSpace.KIND_FREE:
			return Color(0.72, 0.88, 0.86, 1)
	return Color(0.88, 0.88, 0.9, 1)


static func _point_in_diamond(p: Vector2, center: Vector2, half_w: float, half_h: float) -> bool:
	var local := p - center
	return (absf(local.x) / half_w) + (absf(local.y) / half_h) <= 1.0


static func _fill_diamond(image: Image, center: Vector2, half_w: float, half_h: float, color: Color) -> void:
	var min_x := int(floor(center.x - half_w))
	var max_x := int(ceil(center.x + half_w))
	var min_y := int(floor(center.y - half_h))
	var max_y := int(ceil(center.y + half_h))
	for y in range(maxi(0, min_y), mini(HEIGHT, max_y + 1)):
		for x in range(maxi(0, min_x), mini(WIDTH, max_x + 1)):
			if _point_in_diamond(Vector2(x + 0.5, y + 0.5), center, half_w, half_h):
				_blend_pixel(image, x, y, color)


static func _fill_diamond_band(
	image: Image,
	center: Vector2,
	half_w: float,
	half_h: float,
	t0: float,
	t1: float,
	color: Color
) -> void:
	var min_x := int(floor(center.x - half_w))
	var max_x := int(ceil(center.x + half_w))
	var min_y := int(floor(center.y - half_h))
	var max_y := int(ceil(center.y + half_h))
	for y in range(maxi(0, min_y), mini(HEIGHT, max_y + 1)):
		for x in range(maxi(0, min_x), mini(WIDTH, max_x + 1)):
			var p := Vector2(x + 0.5, y + 0.5)
			if not _point_in_diamond(p, center, half_w, half_h):
				continue
			var t := ((p.y - (center.y - half_h)) / (half_h * 2.0))
			if t >= t0 and t <= t1:
				_blend_pixel(image, x, y, color)


static func _stroke_diamond(image: Image, center: Vector2, half_w: float, half_h: float, color: Color, thickness: int) -> void:
	var pts := PackedVector2Array([
		center + Vector2(0, -half_h),
		center + Vector2(half_w, 0),
		center + Vector2(0, half_h),
		center + Vector2(-half_w, 0),
	])
	for i in pts.size():
		_draw_line(image, pts[i], pts[(i + 1) % pts.size()], color, thickness)


static func _bevel_diamond(image: Image, center: Vector2, half_w: float, half_h: float) -> void:
	var pts := PackedVector2Array([
		center + Vector2(0, -(half_h - 2.0)),
		center + Vector2(half_w - 3.0, 0),
		center + Vector2(0, half_h - 2.0),
		center + Vector2(-(half_w - 3.0), 0),
	])
	_draw_line(image, pts[0], pts[1], Color(1, 1, 1, 0.28), 1)
	_draw_line(image, pts[3], pts[0], Color(1, 1, 1, 0.18), 1)
	_draw_line(image, pts[1], pts[2], Color(0, 0, 0, 0.18), 1)
	_draw_line(image, pts[2], pts[3], Color(0, 0, 0, 0.22), 1)


static func _draw_line(image: Image, a: Vector2, b: Vector2, color: Color, thickness: int) -> void:
	var steps := int(maxi(1, ceili(a.distance_to(b))))
	for i in steps + 1:
		var p := a.lerp(b, float(i) / float(steps))
		for oy in range(-thickness + 1, thickness):
			for ox in range(-thickness + 1, thickness):
				_blend_pixel(image, int(round(p.x)) + ox, int(round(p.y)) + oy, color)


static func _blend_pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= WIDTH or y >= HEIGHT:
		return
	var dst := image.get_pixel(x, y)
	var a := color.a
	image.set_pixel(
		x,
		y,
		Color(
			dst.r * (1.0 - a) + color.r * a,
			dst.g * (1.0 - a) + color.g * a,
			dst.b * (1.0 - a) + color.b * a,
			clampf(dst.a + a * (1.0 - dst.a), 0.0, 1.0)
		)
	)


static func _draw_centered(image: Image, text: String, center: Vector2, scale: int, color: Color) -> void:
	var w := _measure(text, scale)
	_draw_text(image, text, Vector2(center.x - float(w) * 0.5, center.y - float(_GLYPH_H * scale) * 0.5), scale, color)


static func _draw_wrapped(
	image: Image,
	text: String,
	center: Vector2,
	max_width: float,
	scale: int,
	color: Color
) -> void:
	var words := text.split(" ")
	var lines: PackedStringArray = PackedStringArray()
	var current := ""
	for word in words:
		var trial := word if current.is_empty() else "%s %s" % [current, word]
		if float(_measure(trial, scale)) <= max_width or current.is_empty():
			current = trial
		else:
			lines.append(current)
			current = word
	if not current.is_empty():
		lines.append(current)
	var line_h := float((_GLYPH_H + 2) * scale)
	var start_y := center.y - (float(lines.size() - 1) * line_h * 0.5)
	for i in lines.size():
		_draw_centered(image, lines[i], Vector2(center.x, start_y + float(i) * line_h), scale, color)


static func _measure(text: String, scale: int) -> int:
	if text.is_empty():
		return 0
	return text.length() * (_GLYPH_W + 1) * scale - scale


static func _glyph_rows(ch: String) -> Array:
	if _GLYPHS.has(ch):
		return _GLYPHS[ch]
	var upper := ch.to_upper()
	if _GLYPHS.has(upper):
		return _GLYPHS[upper]
	return _GLYPHS[" "]


static func _draw_text(image: Image, text: String, origin: Vector2, scale: int, color: Color) -> void:
	var pen_x := int(round(origin.x))
	var pen_y := int(round(origin.y))
	for i in text.length():
		var rows: Array = _glyph_rows(text.substr(i, 1))
		for row in _GLYPH_H:
			var mask: int = int(rows[row])
			for col in _GLYPH_W:
				# bit4 is the leftmost pixel of the 5-wide glyph
				if (mask >> (4 - col)) & 1:
					for sy in scale:
						for sx in scale:
							_blend_pixel(image, pen_x + col * scale + sx, pen_y + row * scale + sy, color)
		pen_x += (_GLYPH_W + 1) * scale


static func _draw_coin(image: Image, center: Vector2) -> void:
	_fill_circle(image, center, 10, Color(0.85, 0.65, 0.2, 1))
	_fill_circle(image, center, 7, Color(0.98, 0.9, 0.45, 1))
	_draw_centered(image, "$", center + Vector2(0, 0), 2, Color(0.45, 0.3, 0.08, 1))


static func _draw_arrow(image: Image, center: Vector2, color: Color) -> void:
	_draw_line(image, center + Vector2(-14, 4), center + Vector2(10, 4), color, 2)
	_draw_line(image, center + Vector2(2, -6), center + Vector2(14, 4), color, 2)
	_draw_line(image, center + Vector2(2, 14), center + Vector2(14, 4), color, 2)


static func _draw_bars(image: Image, center: Vector2, color: Color) -> void:
	for i in 4:
		var x := center.x - 12.0 + float(i) * 8.0
		_draw_line(image, Vector2(x, center.y - 10), Vector2(x, center.y + 10), color, 2)
	_draw_line(image, center + Vector2(-14, -10), center + Vector2(14, -10), color, 2)
	_draw_line(image, center + Vector2(-14, 10), center + Vector2(14, 10), color, 2)


static func _draw_point(image: Image, center: Vector2, color: Color) -> void:
	_draw_line(image, center + Vector2(-4, -12), center + Vector2(-4, 8), color, 2)
	_draw_line(image, center + Vector2(-4, 8), center + Vector2(10, 2), color, 2)
	_fill_circle(image, center + Vector2(-4, -14), 3, color)


static func _draw_tree(image: Image, center: Vector2, color: Color) -> void:
	_fill_circle(image, center + Vector2(0, -4), 9, color)
	_fill_circle(image, center + Vector2(-6, 0), 6, color.lightened(0.1))
	_fill_circle(image, center + Vector2(6, 0), 6, color.lightened(0.1))
	_draw_line(image, center + Vector2(0, 2), center + Vector2(0, 14), Color(0.35, 0.22, 0.12, 1), 2)


static func _fill_circle(image: Image, center: Vector2, radius: float, color: Color) -> void:
	var r := int(ceil(radius))
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			if Vector2(x, y).length() <= radius:
				_blend_pixel(image, int(center.x) + x, int(center.y) + y, color)
