class_name Art
extends RefCounted
## Процедурная «карандашная» графика: дрожащие контуры, перерисовка 3 раза в секунду.

const INK := Color("3a2f2a")
const PAPER := Color("fffaf0")


## Номер «кадра» дрожания линии: меняется 3 раза в секунду.
static func frame() -> int:
	return int(Time.get_ticks_msec() / 333)


static func _h(n: float) -> float:
	var x := sin(n * 12.9898 + 4.1414) * 43758.5453
	return x - floor(x)


static func ellipse_pts(c: Vector2, rx: float, ry: float, sd: int, amp: float = 0.07, n: int = 14, rot: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(n)
	for i in n:
		var a := TAU * float(i) / float(n)
		var j := 1.0 + (_h(float(sd * 17 + i)) - 0.5) * 2.0 * amp
		pts[i] = c + Vector2(cos(a) * rx * j, sin(a) * ry * j).rotated(rot)
	return pts


static func outline(ci: CanvasItem, p: PackedVector2Array, ink: Color, width: float) -> void:
	var q := p.duplicate()
	q.append(p[0])
	ci.draw_polyline(q, ink, width, true)


static func blob(ci: CanvasItem, c: Vector2, rx: float, ry: float, fill: Color, width: float, sd: int, rot: float = 0.0, ink: Color = INK, amp: float = 0.07) -> void:
	var n := clampi(int(maxf(rx, ry) / 3.0), 14, 64)
	var p := ellipse_pts(c, rx, ry, sd, amp * 14.0 / float(n), n, rot)
	ci.draw_colored_polygon(p, fill)
	if width > 0.0:
		outline(ci, p, ink, width)


static func fill_blob(ci: CanvasItem, c: Vector2, rx: float, ry: float, fill: Color, sd: int = 0) -> void:
	ci.draw_colored_polygon(ellipse_pts(c, rx, ry, sd, 0.03, clampi(int(maxf(rx, ry) / 3.0), 16, 64)), fill)


static func wobbly_rect(r: Rect2, sd: int, amp: float = 1.5) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	var k := 0
	for ci in 4:
		var a: Vector2 = corners[ci]
		var b: Vector2 = corners[(ci + 1) % 4]
		var n := maxi(1, int(a.distance_to(b) / 40.0))
		for j in n:
			var p := a.lerp(b, float(j) / float(n))
			p += Vector2(_h(float(sd * 7 + k)) - 0.5, _h(float(sd * 11 + k + 3)) - 0.5) * 2.0 * amp
			pts.append(p)
			k += 1
	return pts


static func rot_rect(c: Vector2, w: float, h: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for v in [Vector2(-w, -h), Vector2(w, -h), Vector2(w, h), Vector2(-w, h)]:
		pts.append(c + (v * 0.5).rotated(rot))
	return pts


static func card(ci: CanvasItem, r: Rect2, fill: Color, sd: int, ink: Color = INK, width: float = 2.5) -> void:
	var p := wobbly_rect(r, sd, 1.2)
	ci.draw_colored_polygon(p, fill)
	outline(ci, p, ink, width)


static func text_w(font: Font, s: String, size: int) -> float:
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func text_c(ci: CanvasItem, font: Font, c: Vector2, s: String, size: int, col: Color, outline_col: Color = Color(0, 0, 0, 0), outline_w: int = 0) -> void:
	var p := Vector2(c.x - text_w(font, s, size) * 0.5, c.y)
	if outline_w > 0:
		ci.draw_string_outline(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline_w, outline_col)
	ci.draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
