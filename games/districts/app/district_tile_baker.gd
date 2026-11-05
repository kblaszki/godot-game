class_name DistrictTileBaker
extends RefCounted

## Bakes rectangular Monopoly-style space faces (color band on the outer edge).

const WIDTH := 80
const HEIGHT := 112
const CORNER_SIZE := 112
const BAND_H := 26
## Kept for play layout spacing (edge tile half-extents).
const HALF_W := 40.0
const HALF_H := 56.0

const GROUP_COLORS: Array[Color] = [
	Color(0.55, 0.32, 0.18, 1),
	Color(0.45, 0.72, 0.92, 1),
	Color(0.88, 0.4, 0.72, 1),
	Color(0.95, 0.55, 0.18, 1),
	Color(0.86, 0.22, 0.22, 1),
	Color(0.94, 0.84, 0.28, 1),
	Color(0.28, 0.68, 0.38, 1),
]

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


static func is_corner_kind(kind: String) -> bool:
	return (
		kind == BoardSpace.KIND_GO
		or kind == BoardSpace.KIND_JAIL
		or kind == BoardSpace.KIND_FREE
		or kind == BoardSpace.KIND_TOUR
		or kind == BoardSpace.KIND_ARENA
	)


static func bake(space: BoardSpace) -> ImageTexture:
	return ImageTexture.create_from_image(bake_image(space))


static func bake_image(space: BoardSpace) -> Image:
	if is_corner_kind(space.kind):
		return _bake_corner(space)
	return _bake_edge(space)


static func group_color(group: int) -> Color:
	if group < 0 or group >= GROUP_COLORS.size():
		return Color(0.5, 0.5, 0.55, 1)
	return GROUP_COLORS[group]


static func _bake_edge(space: BoardSpace) -> Image:
	var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_fill_rect(image, Rect2i(1, 1, WIDTH - 2, HEIGHT - 2), _face_color(space))
	# Outer color band at top of texture (play rotates so top faces outward).
	var band := group_color(space.group) if space.kind == BoardSpace.KIND_PROPERTY else _special_band(space)
	_fill_rect(image, Rect2i(1, 1, WIDTH - 2, BAND_H), band)
	_stroke_rect(image, Rect2i(0, 0, WIDTH, HEIGHT), Color(0.08, 0.09, 0.11, 1), 2)
	var ink := Color(0.14, 0.15, 0.18, 1)
	match space.kind:
		BoardSpace.KIND_PROPERTY:
			_draw_wrapped(image, space.name, Vector2(WIDTH * 0.5, BAND_H + 28), float(WIDTH - 12), 2, ink)
			_draw_centered(image, "$%d" % space.price, Vector2(WIDTH * 0.5, HEIGHT - 28), 2, Color(0.12, 0.35, 0.28, 1))
		BoardSpace.KIND_TAX:
			_draw_coin(image, Vector2(WIDTH * 0.5, BAND_H + 22))
			_draw_wrapped(image, space.name, Vector2(WIDTH * 0.5, BAND_H + 48), float(WIDTH - 12), 1, ink)
			_draw_centered(image, "$%d" % space.tax, Vector2(WIDTH * 0.5, HEIGHT - 24), 2, Color(0.55, 0.28, 0.12, 1))
		_:
			_draw_wrapped(image, space.name, Vector2(WIDTH * 0.5, HEIGHT * 0.55), float(WIDTH - 12), 2, ink)
	return image


static func _bake_corner(space: BoardSpace) -> Image:
	var s := CORNER_SIZE
	var image := Image.create(s, s, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_fill_rect(image, Rect2i(1, 1, s - 2, s - 2), _face_color(space))
	_stroke_rect(image, Rect2i(0, 0, s, s), Color(0.08, 0.09, 0.11, 1), 2)
	var center := Vector2(s * 0.5, s * 0.5)
	match space.kind:
		BoardSpace.KIND_GO:
			_draw_arrow(image, center + Vector2(0, -18), Color(0.15, 0.45, 0.3, 1))
			_draw_wrapped(image, space.name, center + Vector2(0, 10), float(s - 16), 2, Color(0.1, 0.28, 0.18, 1))
			_draw_centered(image, "GO", center + Vector2(0, 36), 2, Color(0.12, 0.4, 0.25, 1))
		BoardSpace.KIND_JAIL:
			_draw_bars(image, center + Vector2(0, -16), Color(0.25, 0.28, 0.38, 1))
			_draw_wrapped(image, space.name, center + Vector2(0, 12), float(s - 16), 2, Color(0.18, 0.2, 0.28, 1))
			_draw_centered(image, "JAIL", center + Vector2(0, 36), 2, Color(0.3, 0.32, 0.4, 1))
		BoardSpace.KIND_GOTO_JAIL:
			_draw_point(image, center + Vector2(0, -16), Color(0.55, 0.18, 0.16, 1))
			_draw_wrapped(image, space.name, center + Vector2(0, 12), float(s - 16), 2, Color(0.4, 0.14, 0.12, 1))
			_draw_centered(image, "GO TO JAIL", center + Vector2(0, 36), 1, Color(0.5, 0.16, 0.14, 1))
		BoardSpace.KIND_FREE:
			_draw_tree(image, center + Vector2(0, -16), Color(0.18, 0.48, 0.4, 1))
			_draw_wrapped(image, space.name, center + Vector2(0, 12), float(s - 16), 2, Color(0.12, 0.32, 0.3, 1))
			_draw_centered(image, "FREE", center + Vector2(0, 36), 2, Color(0.16, 0.4, 0.36, 1))
		BoardSpace.KIND_TOUR:
			_draw_point(image, center + Vector2(0, -16), Color(0.25, 0.55, 0.85, 1))
			_draw_wrapped(image, space.name, center + Vector2(0, 12), float(s - 16), 2, Color(0.15, 0.35, 0.55, 1))
			_draw_centered(image, "TOUR", center + Vector2(0, 36), 2, Color(0.2, 0.45, 0.7, 1))
		BoardSpace.KIND_ARENA:
			_draw_coin(image, center + Vector2(0, -16))
			_draw_wrapped(image, space.name, center + Vector2(0, 12), float(s - 16), 2, Color(0.5, 0.35, 0.1, 1))
			_draw_centered(image, "ARENA", center + Vector2(0, 36), 2, Color(0.7, 0.5, 0.15, 1))
	return image


static func _special_band(space: BoardSpace) -> Color:
	match space.kind:
		BoardSpace.KIND_TAX:
			return Color(0.85, 0.7, 0.35, 1)
		BoardSpace.KIND_CHANCE:
			return Color(0.55, 0.35, 0.75, 1)
		BoardSpace.KIND_GOTO_JAIL:
			return Color(0.75, 0.3, 0.28, 1)
	return Color(0.55, 0.6, 0.65, 1)


static func _face_color(space: BoardSpace) -> Color:
	match space.kind:
		BoardSpace.KIND_PROPERTY:
			return Color(0.96, 0.95, 0.9, 1)
		BoardSpace.KIND_TAX:
			return Color(0.95, 0.9, 0.78, 1)
		BoardSpace.KIND_GO:
			return Color(0.72, 0.9, 0.78, 1)
		BoardSpace.KIND_JAIL:
			return Color(0.78, 0.8, 0.86, 1)
		BoardSpace.KIND_GOTO_JAIL:
			return Color(0.92, 0.72, 0.78, 1)
		BoardSpace.KIND_FREE:
			return Color(0.72, 0.88, 0.9, 1)
		BoardSpace.KIND_TOUR:
			return Color(0.7, 0.85, 0.95, 1)
		BoardSpace.KIND_ARENA:
			return Color(0.95, 0.88, 0.7, 1)
		BoardSpace.KIND_CHANCE:
			return Color(0.9, 0.85, 0.95, 1)
	return Color(0.92, 0.92, 0.94, 1)


static func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var x0 := maxi(rect.position.x, 0)
	var y0 := maxi(rect.position.y, 0)
	var x1 := mini(rect.position.x + rect.size.x, image.get_width())
	var y1 := mini(rect.position.y + rect.size.y, image.get_height())
	for y in range(y0, y1):
		for x in range(x0, x1):
			image.set_pixel(x, y, color)


static func _stroke_rect(image: Image, rect: Rect2i, color: Color, thickness: int) -> void:
	for t in thickness:
		var r := Rect2i(rect.position.x + t, rect.position.y + t, rect.size.x - 2 * t, rect.size.y - 2 * t)
		for x in range(r.position.x, r.position.x + r.size.x):
			_blend_pixel(image, x, r.position.y, color)
			_blend_pixel(image, x, r.position.y + r.size.y - 1, color)
		for y in range(r.position.y, r.position.y + r.size.y):
			_blend_pixel(image, r.position.x, y, color)
			_blend_pixel(image, r.position.x + r.size.x - 1, y, color)


static func _blend_pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
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
				if (mask >> (4 - col)) & 1:
					for sy in scale:
						for sx in scale:
							_blend_pixel(image, pen_x + col * scale + sx, pen_y + row * scale + sy, color)
		pen_x += (_GLYPH_W + 1) * scale


static func _draw_line(image: Image, a: Vector2, b: Vector2, color: Color, thickness: int) -> void:
	var steps := int(maxi(1, ceili(a.distance_to(b))))
	for i in steps + 1:
		var p := a.lerp(b, float(i) / float(steps))
		for oy in range(-thickness + 1, thickness):
			for ox in range(-thickness + 1, thickness):
				_blend_pixel(image, int(round(p.x)) + ox, int(round(p.y)) + oy, color)


static func _fill_circle(image: Image, center: Vector2, radius: float, color: Color) -> void:
	var r := int(ceil(radius))
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			if Vector2(x, y).length() <= radius:
				_blend_pixel(image, int(center.x) + x, int(center.y) + y, color)


static func _draw_coin(image: Image, center: Vector2) -> void:
	_fill_circle(image, center, 10, Color(0.85, 0.65, 0.2, 1))
	_fill_circle(image, center, 7, Color(0.98, 0.9, 0.45, 1))
	_draw_centered(image, "$", center, 2, Color(0.45, 0.3, 0.08, 1))


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
