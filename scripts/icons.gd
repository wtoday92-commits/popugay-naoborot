class_name Icons
extends RefCounted
## Процедурные иконки той же карандашной линией: умения, пассивки, кнопки игрока, ивенты, фрукты.

const INK := Art.INK

## Значок-модификатор в углу для особых пассивок.
const BADGE := {
	"feather_bounce": "zigzag", "feather_fan": "fan", "feather_pierce": "arrow", "feather_homing": "curve", "feather_ice": "snow",
	"bell_wide": "out", "bell_stun": "star", "bell_pull": "in", "bell_push": "out", "bell_armor": "shield",
	"mirror_chain": "zigzag", "mirror_double": "double", "mirror_burn": "flame", "mirror_long": "arrow", "mirror_blind": "star",
	"scream_echo": "double", "scream_stun": "star", "scream_wide": "out", "scream_fast": "clock", "scream_fear": "bang",
	"orbit_more": "plus", "orbit_fast": "clock", "orbit_wide": "out", "orbit_knock": "out", "orbit_fire": "flame",
}

const BG := {
	"skill": Color("fff3d6"), "general": Color("e9f3e2"), "mod": Color("eee6f7"), "player": Color("ece6fb"),
	"event": Color("fff0c9"), "fruit": Color("ffe8e0"), "boss": Color("e3e6ea"),
}


static func kind_of(key: String) -> String:
	if Skills.SKILLS.has(key) or key == "peck":
		return "skill"
	if Skills.GENERAL.has(key):
		return "general"
	if BADGE.has(key):
		return "mod"
	if Skills.FRUITS.has(key):
		return "fruit"
	if Skills.EVENTS.has(key):
		return "event"
	if key == "boss":
		return "boss"
	return "player"


static func draw(ci: CanvasItem, key: String, c: Vector2, s: float, a: float = 1.0, bg: bool = true) -> void:
	if bg:
		var r := Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s))
		var col: Color = BG.get(kind_of(key), Color("fff8ea"))
		col.a *= a
		Art.card(ci, r, col, key.hash() % 97 + Art.frame(), Color(INK, a), 2.0)
	var u := s / 44.0
	if BADGE.has(key):
		_glyph(ci, Skills.mod_parent(key), c + Vector2(-4, -4) * u, u * 0.8, a)
		var bc := c + Vector2(11, 11) * u
		ci.draw_circle(bc, 9.0 * u, Color(1, 1, 1, a))
		ci.draw_arc(bc, 9.0 * u, 0, TAU, 16, Color(INK, a), 1.5 * maxf(u, 0.7), true)
		_badge(ci, BADGE[key], bc, u, a)
	else:
		_glyph(ci, key, c, u, a)


static func _poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color, a: float, w: float) -> void:
	var f := fill
	f.a *= a
	ci.draw_colored_polygon(pts, f)
	Art.outline(ci, pts, Color(INK, a), w)


static func _blob(ci: CanvasItem, c: Vector2, rx: float, ry: float, fill: Color, a: float, w: float, rot: float = 0.0) -> void:
	var f := fill
	f.a *= a
	Art.blob(ci, c, rx, ry, f, w, int(c.x * 3.0 + c.y), rot, Color(INK, a), 0.04)


static func _pts(c: Vector2, u: float, arr: Array) -> PackedVector2Array:
	var p := PackedVector2Array()
	for v in arr:
		p.append(c + Vector2(v) * u)
	return p


static func _glyph(ci: CanvasItem, key: String, c: Vector2, u: float, a: float) -> void:
	var w := maxf(1.5, 2.2 * u)
	var ink := Color(INK, a)
	match key:
		"peck":
			_poly(ci, _pts(c, u, [Vector2(-12, -8), Vector2(12, 0), Vector2(-12, 8)]), Color("f0a64a"), a, w)
			ci.draw_line(c + Vector2(-12, 0) * u, c + Vector2(4, 0) * u, ink, w * 0.7)
			for k in 3:
				ci.draw_line(c + Vector2(14, -8 + k * 8) * u, c + Vector2(19, -10 + k * 10) * u, ink, w * 0.7)
		"feather":
			_blob(ci, c, 7 * u, 16 * u, Color("7cc46a"), a, w, 0.7)
			ci.draw_line(c + Vector2(-10, 12) * u, c + Vector2(9, -11) * u, ink, w * 0.8)
		"bell":
			_poly(ci, _pts(c, u, [Vector2(-4, -14), Vector2(4, -14), Vector2(10, -2), Vector2(14, 9), Vector2(-14, 9), Vector2(-10, -2)]), Color("f2c14e"), a, w)
			ci.draw_circle(c + Vector2(0, 12) * u, 3.5 * u, ink)
		"mirror":
			ci.draw_line(c + Vector2(5, 6) * u, c + Vector2(13, 16) * u, ink, w * 2.0)
			_blob(ci, c + Vector2(-3, -4) * u, 12 * u, 12 * u, Color("bfe3f5"), a, w)
			ci.draw_line(c + Vector2(-9, -6) * u, c + Vector2(-3, -12) * u, Color(1, 1, 1, a), w)
		"scream":
			_poly(ci, _pts(c, u, [Vector2(-14, -9), Vector2(-2, -3), Vector2(-14, 1)]), Color("f0a64a"), a, w)
			_poly(ci, _pts(c, u, [Vector2(-14, 3), Vector2(-4, 4), Vector2(-14, 9)]), Color("f0a64a"), a, w)
			for k in 3:
				ci.draw_arc(c + Vector2(-6, 0) * u, (8.0 + k * 6.0) * u, -0.7, 0.7, 8, ink, w * 0.8)
		"orbit":
			ci.draw_arc(c, 13 * u, 0, TAU, 24, Color(INK, 0.5 * a), w * 0.6)
			ci.draw_circle(c, 4 * u, Color("7cc46a", a))
			var cols := [Color("e98a7a"), Color("8fb6e8"), Color("f2c14e")]
			for k in 3:
				var ang := TAU * k / 3.0 + 0.4
				_blob(ci, c + Vector2(cos(ang), sin(ang)) * 13 * u, 5 * u, 5 * u, cols[k], a, w * 0.7)
		"wings":
			for k in 3:
				_blob(ci, c + Vector2(-6 + k * 6, -2 + k * 4) * u, 10 * u, 5 * u, Color("58a04c").lightened(k * 0.15), a, w * 0.8, -0.5)
		"fluff":
			_blob(ci, c + Vector2(-7, 3) * u, 8 * u, 7 * u, Color("fffaf0"), a, w)
			_blob(ci, c + Vector2(7, 3) * u, 8 * u, 7 * u, Color("fffaf0"), a, w)
			_blob(ci, c + Vector2(0, -5) * u, 9 * u, 8 * u, Color("fffaf0"), a, w)
		"shell":
			_poly(ci, _pts(c, u, [Vector2(-13, -2), Vector2(-8, -8), Vector2(-3, -2), Vector2(2, -8), Vector2(7, -2), Vector2(13, -7), Vector2(13, 4), Vector2(8, 12), Vector2(-8, 12), Vector2(-13, 4)]), Color("f7f1e3"), a, w)
		"magnet":
			ci.draw_arc(c + Vector2(0, -2) * u, 10 * u, PI, TAU, 12, Color("d95c4a", a), 7 * u)
			ci.draw_line(c + Vector2(-10, -2) * u, c + Vector2(-10, 10) * u, Color("d95c4a", a), 7 * u)
			ci.draw_line(c + Vector2(10, -2) * u, c + Vector2(10, 10) * u, Color("d95c4a", a), 7 * u)
			ci.draw_line(c + Vector2(-10, 7) * u, c + Vector2(-10, 13) * u, Color("cfd3d8", a), 7 * u)
			ci.draw_line(c + Vector2(10, 7) * u, c + Vector2(10, 13) * u, Color("cfd3d8", a), 7 * u)
		"beak":
			_poly(ci, _pts(c, u, [Vector2(-12, -9), Vector2(10, 0), Vector2(-12, 9)]), Color("e8903a"), a, w)
			_star(ci, c + Vector2(10, -10) * u, 6 * u, Color("f6d84c"), a)
		"luck":
			_blob(ci, c + Vector2(-2, 2) * u, 6 * u, 14 * u, Color("f2c14e"), a, w, 0.6)
			_star(ci, c + Vector2(10, -10) * u, 6 * u, Color("f6d84c"), a)
		"book":
			_poly(ci, _pts(c, u, [Vector2(-14, -10), Vector2(12, -14), Vector2(15, 9), Vector2(-11, 13)]), Color("c25b4a"), a, w)
			ci.draw_line(c + Vector2(-10, 9) * u, c + Vector2(12, 5) * u, Color("f0d27a", a), w)
		"basket":
			_poly(ci, _pts(c, u, [Vector2(-15, -4), Vector2(15, -4), Vector2(11, 13), Vector2(-11, 13)]), Color("d9b98a"), a, w)
			for k in 4:
				ci.draw_line(c + Vector2(-9 + k * 6, -3) * u, c + Vector2(-7 + k * 5, 12) * u, Color("9a7a52", a), w * 0.6)
			_blob(ci, c + Vector2(-5, -8) * u, 6 * u, 4 * u, Color("f1eee8"), a, w * 0.7)
			_blob(ci, c + Vector2(6, -8) * u, 6 * u, 4 * u, Color("a9c3dd"), a, w * 0.7)
		"paw", "ram", "grab":
			var pf := Color("fffaf2")
			for k in 4:
				var tp: Vector2 = [Vector2(-9, -7), Vector2(-3, -12), Vector2(4, -12), Vector2(10, -7)][k]
				_blob(ci, c + tp * u, 3.8 * u, 4.2 * u, pf, a, w * 0.7)
			_blob(ci, c + Vector2(0, 4) * u, 10 * u, 8 * u, pf, a, w)
			ci.draw_circle(c + Vector2(0, 5) * u, 4 * u, Color("f3a7b5", a))
			if key == "ram":
				for k in 3:
					ci.draw_line(c + Vector2(-20, -6 + k * 6) * u, c + Vector2(-13, -6 + k * 6) * u, ink, w * 0.7)
			if key == "grab":
				_blob(ci, c + Vector2(10, 12) * u, 4 * u, 7 * u, Color("f1eee8"), a, w * 0.7)
		"millet", "glow":
			ci.draw_line(c + Vector2(-3, 15) * u, c + Vector2(3, -14) * u, Color("b98c34", a), w)
			_blob(ci, c, 6 * u, 13 * u, Color("f5c84c"), a, w, 0.2)
			if key == "glow":
				for k in 6:
					var ang := TAU * k / 6.0
					ci.draw_line(c + Vector2(cos(ang), sin(ang)) * 15 * u, c + Vector2(cos(ang), sin(ang)) * 19 * u, Color("6cc7d9", a), w)
			else:
				ci.draw_arc(c + Vector2(9, 9) * u, 6 * u, 0, TAU, 10, Color("6a4fb3", a), w)
		"circle":
			ci.draw_circle(c, 9 * u, Color("f6d84c", a))
			ci.draw_arc(c, 9 * u, 0, TAU, 16, ink, w)
			for k in 8:
				var ang := TAU * k / 8.0
				ci.draw_line(c + Vector2(cos(ang), sin(ang)) * 12 * u, c + Vector2(cos(ang), sin(ang)) * 17 * u, Color("e0a92e", a), w)
		"box":
			_poly(ci, _pts(c, u, [Vector2(-13, -6), Vector2(13, -6), Vector2(13, 11), Vector2(-13, 11)]), Color("c98fb0"), a, w)
			_poly(ci, _pts(c, u, [Vector2(-15, -12), Vector2(15, -12), Vector2(13, -6), Vector2(-13, -6)]), Color("b07898"), a, w)
			for k in 3:
				ci.draw_circle(c + Vector2(-6 + k * 6, 3) * u, 2.5 * u, Color("fff2b0", a))
			for k in 2:
				ci.draw_line(c + Vector2(-17 - k * 4, 0) * u, c + Vector2(-21 - k * 4, 0) * u, ink, w * 0.6)
		"altar":
			_blob(ci, c + Vector2(0, 8) * u, 16 * u, 5 * u, Color("f7f3e8"), a, w)
			_blob(ci, c + Vector2(0, 0) * u, 9 * u, 7 * u, Color("b98a6a"), a, w)
			ci.draw_circle(c + Vector2(-3, -2) * u, 2 * u, Color("f3a7b5", a))
			Art.text_c(ci, ThemeDB.fallback_font, c + Vector2(11, -6) * u, "?", int(16 * u), Color("b23a2e", a))
		"boss":
			_blob(ci, c, 15 * u, 13 * u, Color("b9c0c9"), a, w)
			_blob(ci, c + Vector2(0, -2) * u, 9 * u, 7 * u, Color("8a939e"), a, w * 0.7)
			ci.draw_circle(c + Vector2(0, -8) * u, 2.5 * u, Color("e0614a", a))
		"apple":
			_blob(ci, c + Vector2(0, 2) * u, 12 * u, 11 * u, Color("e0614a"), a, w)
			ci.draw_line(c + Vector2(0, -8) * u, c + Vector2(2, -14) * u, Color("7a5a3a", a), w)
			_blob(ci, c + Vector2(6, -12) * u, 5 * u, 2.5 * u, Color("8fcf7a"), a, w * 0.6, -0.4)
		"chili":
			_poly(ci, _pts(c, u, [Vector2(-12, -8), Vector2(-4, -9), Vector2(8, -2), Vector2(14, 10), Vector2(6, 4), Vector2(-6, -2)]), Color("d9442e"), a, w)
			_blob(ci, c + Vector2(-12, -9) * u, 4 * u, 4 * u, Color("6fae5c"), a, w * 0.6)
		"carrot":
			_poly(ci, _pts(c, u, [Vector2(-7, -8), Vector2(7, -8), Vector2(0, 15)]), Color("f08a3a"), a, w)
			for k in 3:
				ci.draw_line(c + Vector2(0, -8) * u, c + Vector2(-6 + k * 6, -16) * u, Color("6fae5c", a), w)
		"grape":
			for k in 6:
				var gp: Vector2 = [Vector2(-6, -6), Vector2(0, -6), Vector2(6, -6), Vector2(-3, 0), Vector2(3, 0), Vector2(0, 6)][k]
				_blob(ci, c + gp * u, 4.5 * u, 4.5 * u, Color("9a6fc4"), a, w * 0.6)
			ci.draw_line(c + Vector2(0, -10) * u, c + Vector2(3, -15) * u, Color("7a5a3a", a), w)
		"lemon":
			_blob(ci, c, 14 * u, 10 * u, Color("f6e04c"), a, w)
			ci.draw_circle(c + Vector2(15, 0) * u, 2.5 * u, Color("f6e04c", a))
		"trap":
			ci.draw_arc(c + Vector2(0, 2) * u, 13 * u, PI, TAU, 12, Color("8a8f96", a), 4 * u)
			ci.draw_arc(c + Vector2(0, -2) * u, 13 * u, 0, PI, 12, Color("8a8f96", a), 4 * u)
			for k in 5:
				var x := -10.0 + k * 5.0
				ci.draw_line(c + Vector2(x, -3) * u, c + Vector2(x + 2, 3) * u, ink, w * 0.7)
		"rotten":
			_blob(ci, c + Vector2(0, 4) * u, 7 * u, 12 * u, Color("a8b86a"), a, w, 0.2)
			for k in 3:
				ci.draw_arc(c + Vector2(-8 + k * 8, -12) * u, 4 * u, 0, PI * 1.5, 6, Color("6f8a2a", a), w * 0.7)
		"egg":
			_blob(ci, c + Vector2(0, 2) * u, 11 * u, 14 * u, Color("fff6e0"), a, w)
			ci.draw_polyline(_pts(c, u, [Vector2(-10, 0), Vector2(-5, -5), Vector2(0, 1), Vector2(5, -5), Vector2(10, 0)]), ink, w * 0.8)
		"missile":
			for k in 3:
				ci.draw_circle(c + Vector2(-14 + k * 5, 8 - k * 3) * u, (3.0 - k * 0.5) * u, Color("f5c84c", a * 0.6))
			_blob(ci, c + Vector2(4, -3) * u, 6 * u, 11 * u, Color("f5c84c"), a, w, 0.8)
			ci.draw_polyline(_pts(c, u, [Vector2(10, -14), Vector2(15, -9), Vector2(10, -4)]), ink, w)
		_:
			Art.text_c(ci, ThemeDB.fallback_font, c + Vector2(0, 6) * u, "?", int(18 * u), ink)


static func _star(ci: CanvasItem, c: Vector2, r: float, col: Color, a: float) -> void:
	var p := PackedVector2Array()
	for k in 10:
		var ang := -PI * 0.5 + TAU * k / 10.0
		var rr := r if k % 2 == 0 else r * 0.45
		p.append(c + Vector2(cos(ang), sin(ang)) * rr)
	_poly(ci, p, col, a, maxf(1.0, r * 0.18))


static func _badge(ci: CanvasItem, kind: String, c: Vector2, u: float, a: float) -> void:
	var ink := Color(INK, a)
	var w := maxf(1.2, 1.8 * u)
	match kind:
		"zigzag":
			ci.draw_polyline(_pts(c, u, [Vector2(-6, 4), Vector2(-2, -4), Vector2(2, 4), Vector2(6, -4)]), ink, w)
		"fan":
			for k in 3:
				ci.draw_line(c + Vector2(-5, 3) * u, c + Vector2(-5, 3) * u + Vector2(10, 0).rotated(-0.6 + k * 0.6) * u, ink, w)
		"arrow", "long":
			ci.draw_line(c + Vector2(-6, 0) * u, c + Vector2(6, 0) * u, ink, w)
			ci.draw_polyline(_pts(c, u, [Vector2(2, -4), Vector2(6, 0), Vector2(2, 4)]), ink, w)
		"curve":
			ci.draw_arc(c + Vector2(0, 3) * u, 5 * u, PI, TAU, 8, ink, w)
			ci.draw_polyline(_pts(c, u, [Vector2(2, 0), Vector2(5, 3), Vector2(8, 0)]), ink, w)
		"snow":
			for k in 3:
				ci.draw_line(c + Vector2(0, -6).rotated(k * PI / 3.0) * u, c + Vector2(0, 6).rotated(k * PI / 3.0) * u, Color("4f8fbf", a), w)
		"out":
			ci.draw_line(c + Vector2(-6, 0) * u, c + Vector2(6, 0) * u, ink, w)
			ci.draw_polyline(_pts(c, u, [Vector2(3, -3), Vector2(6, 0), Vector2(3, 3)]), ink, w)
			ci.draw_polyline(_pts(c, u, [Vector2(-3, -3), Vector2(-6, 0), Vector2(-3, 3)]), ink, w)
		"in":
			ci.draw_polyline(_pts(c, u, [Vector2(-6, -3), Vector2(-2, 0), Vector2(-6, 3)]), ink, w)
			ci.draw_polyline(_pts(c, u, [Vector2(6, -3), Vector2(2, 0), Vector2(6, 3)]), ink, w)
		"star":
			_star(ci, c, 6 * u, Color("f6d84c"), a)
		"shield":
			_poly(ci, _pts(c, u, [Vector2(-5, -5), Vector2(5, -5), Vector2(5, 1), Vector2(0, 6), Vector2(-5, 1)]), Color("a9c3dd"), a, w * 0.8)
		"double":
			ci.draw_arc(c, 3 * u, -0.9, 0.9, 6, ink, w)
			ci.draw_arc(c, 6 * u, -0.9, 0.9, 6, ink, w)
		"flame":
			_poly(ci, _pts(c, u, [Vector2(0, -7), Vector2(5, 1), Vector2(3, 6), Vector2(-3, 6), Vector2(-5, 1)]), Color("f08a3a"), a, w * 0.8)
		"clock":
			ci.draw_arc(c, 5 * u, 0, TAU, 12, ink, w)
			ci.draw_line(c, c + Vector2(0, -4) * u, ink, w)
			ci.draw_line(c, c + Vector2(3, 0) * u, ink, w)
		"bang":
			ci.draw_line(c + Vector2(0, -6) * u, c + Vector2(0, 2) * u, Color("b23a2e", a), w * 1.3)
			ci.draw_circle(c + Vector2(0, 5) * u, 1.3 * u, Color("b23a2e", a))
		"plus":
			ci.draw_line(c + Vector2(-5, 0) * u, c + Vector2(5, 0) * u, ink, w * 1.3)
			ci.draw_line(c + Vector2(0, -5) * u, c + Vector2(0, 5) * u, ink, w * 1.3)
