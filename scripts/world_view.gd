class_name WorldView
extends Node2D
## Рисует комнату и всё, что в ней: стиль Нэкоацумэ, жирный контур у героя, тоньше у врагов,
## тонкие пастельные линии у мебели. Плюс «мысли» героя: линия намерения, рамки внимания, режим.

const INK := Art.INK
const C_FLOOR := Color("f1e6d2")
const C_PLANK := Color("e3d3b8")
const C_WALL := Color("dccab2")
const C_FURN_LINE := Color("8f7d6d")
const C_GREEN := Color("7cc46a")
const C_WING := Color("58a04c")
const C_YELLOW := Color("f6d84c")
const C_FOCUS := Color("4f79a8")
const C_GOLD := Color("e0a92e")
const HERO_SCALE := 1.35

var game
var font: Font


func _ready() -> void:
	font = ThemeDB.fallback_font


func _draw() -> void:
	if game == null or game.hero == null:
		return
	var fr := Art.frame()
	_draw_room(fr)
	for m in game.meteors:
		_draw_shadow(m)
	for g in game.gems:
		_draw_gem(g, fr)
	for a in game.apples:
		_draw_apple(a, fr)
	for c in game.chests:
		_draw_chest(c, fr)
	_draw_aura()
	for e in game.enemies:
		if not e.dead:
			_draw_enemy(e, fr)
	_draw_intent()
	_draw_hero(fr)
	for s in game.shots:
		var p: Vector2 = s["pos"]
		var d: Vector2 = Vector2(s["vel"]).normalized()
		draw_line(p - d * 9.0, p + d * 5.0, Color("f7f3e8"), 5.0, true)
		draw_line(p - d * 9.0, p + d * 5.0, C_WING, 2.0, true)
	for s in game.enemy_shots:
		var p: Vector2 = s["pos"]
		var sd: int = int(s["id"]) + fr
		Art.blob(self, p, 13.0, 10.0, Color(0.72, 0.86, 0.95, 0.75), 2.0, sd, 0.0, Color("6f9bb8"))
		draw_circle(p + Vector2(-4, -3), 3.0, Color(1, 1, 1, 0.8))
	for f in game.fx:
		_draw_fx(f, fr)
	for m in game.meteors:
		_draw_book(m, fr)
	_draw_focus()
	_draw_overhead()
	for t in game.texts:
		var a := 1.0 - clampf((float(t["t"]) - 0.7) / 0.5, 0.0, 1.0)
		var col: Color = t["color"]
		col.a = a
		Art.text_c(self, font, t["pos"], t["text"], int(t["size"]), col, Color(1, 0.98, 0.94, a * 0.9), 5)
	if game.debug:
		_draw_debug()


# ---------- комната ----------

func _draw_room(fr: int) -> void:
	var f: Rect2 = game.floor_rect
	draw_rect(Rect2(0, 0, 1600, 900), C_WALL)
	# плинтус и обои: редкий узор
	for i in 20:
		var x := 60.0 + i * 80.0
		draw_circle(Vector2(x, 20), 3.0, Color("cbb79d"))
		draw_circle(Vector2(x, 880), 3.0, Color("cbb79d"))
	draw_rect(f, C_FLOOR)
	var y := f.position.y + 48.0
	var row := 0
	while y < f.end.y:
		draw_line(Vector2(f.position.x, y), Vector2(f.end.x, y), C_PLANK, 2.0)
		var off := 0.0 if row % 2 == 0 else 110.0
		var x := f.position.x + 60.0 + off
		while x < f.end.x:
			draw_line(Vector2(x, y - 48.0), Vector2(x, y), C_PLANK, 1.5)
			x += 220.0
		y += 48.0
		row += 1
	# ковёр
	Art.blob(self, Vector2(640, 500), 290, 165, Color("eddcea"), 2.0, 7 + fr % 2, 0.0, Color("c4adc3"), 0.025)
	Art.blob(self, Vector2(640, 500), 230, 120, Color("f3e6f0"), 1.5, 9 + fr % 2, 0.0, Color("d4bfd2"), 0.03)
	var pts := Art.wobbly_rect(f, fr, 1.0)
	Art.outline(self, pts, INK, 3.0)
	var cols := [Color("cfdcc6"), Color("dcc3a2"), Color("e8d6b6"), Color("d7cde3"), Color("c9dcbe"), Color("f0d4cc")]
	for i in game.obstacles.size():
		var r: Rect2 = game.obstacles[i]
		var p := Art.wobbly_rect(r, i * 13 + fr, 1.3)
		draw_colored_polygon(p, cols[i])
		Art.outline(self, p, C_FURN_LINE, 2.0)
		match i:
			0: # диван: подушки
				for k in 3:
					var cr := Rect2(r.position.x + 14 + k * 92, r.position.y + 34, 84, 70)
					Art.outline(self, Art.wobbly_rect(cr, k + fr, 1.2), C_FURN_LINE, 1.5)
			1: # полка: корешки книг (отсюда и падают)
				var bc := [Color("e0a49a"), Color("a9c3dd"), Color("e7cf8f"), Color("b9d4ad"), Color("cdb3dc")]
				for k in 12:
					var by := r.position.y + 10 + k * 24
					draw_rect(Rect2(r.position.x + 10, by, 70 - (k % 3) * 8, 18), bc[k % 5])
					draw_rect(Rect2(r.position.x + 10, by, 70 - (k % 3) * 8, 18), C_FURN_LINE, false, 1.0)
			2: # столик: чашка
				Art.blob(self, r.get_center() + Vector2(30, -10), 14, 12, Color("fffaf0"), 1.5, fr, 0.0, C_FURN_LINE)
				Art.outline(self, Art.wobbly_rect(r.grow(-12), fr + 3, 1.0), C_FURN_LINE, 1.2)
			3: # кресло
				Art.blob(self, r.get_center() + Vector2(0, 10), 44, 40, Color("e3dbec"), 1.5, fr + 5, 0.0, C_FURN_LINE)
			4: # цветок
				for k in 5:
					var a := TAU * k / 5.0 + 0.4
					Art.blob(self, r.get_center() + Vector2(cos(a), sin(a)) * 20, 14, 8, Color("a6cf98"), 1.5, fr + k, a, C_FURN_LINE)
			5: # лежанка кота
				Art.blob(self, r.get_center(), 66, 46, Color("f7e2dc"), 1.5, fr + 2, 0.0, C_FURN_LINE)


# ---------- награды ----------

func _draw_gem(g: Dictionary, fr: int) -> void:
	var p: Vector2 = g["pos"]
	if g["big"]:
		var sd: int = int(g["id"]) + fr
		draw_line(p + Vector2(-2, 12), p + Vector2(3, -12), Color("b98c34"), 2.0, true)
		Art.blob(self, p, 6.0, 12.0, Color("f5c84c"), 2.0, sd, 0.25, Color("a0742a"))
		for k in 4:
			draw_circle(p + Vector2(-1.5 + (k % 2) * 3.0, -7.0 + k * 4.5).rotated(0.25), 1.6, Color("d9a43a"))
	else:
		draw_circle(p, 3.6, Color("a0742a"))
		draw_circle(p, 2.6, Color("f6cd56"))


func _draw_apple(a: Dictionary, fr: int) -> void:
	var p: Vector2 = a["pos"]
	var sd: int = int(a["id"]) + fr
	Art.blob(self, p, 12.0, 8.0, Color("e0614a"), 2.5, sd)
	Art.blob(self, p + Vector2(0, -1), 9.0, 5.5, Color("fff3d6"), 0.0, sd + 1)
	draw_circle(p + Vector2(-3, -1), 1.3, INK)
	draw_circle(p + Vector2(3, -1), 1.3, INK)


func _draw_chest(c: Dictionary, fr: int) -> void:
	var p: Vector2 = c["pos"]
	var sd: int = int(c["id"]) + fr
	var life := clampf(float(c["life"]) / 40.0, 0.0, 1.0)
	draw_arc(p, 30.0, -PI * 0.5, -PI * 0.5 + TAU * life, 32, Color(0.85, 0.55, 0.15, 0.8), 3.0, true)
	var pts := Art.wobbly_rect(Rect2(p - Vector2(18, 12), Vector2(36, 24)), sd, 1.2)
	draw_colored_polygon(pts, Color("f6c94a"))
	Art.outline(self, pts, INK, 3.0)
	draw_line(p + Vector2(-14, -2), p + Vector2(14, -2), Color("b98c34"), 2.0)
	for k in 5:
		draw_circle(p + Vector2(-10 + k * 5, -6), 1.8, Color("fff2b0"))
	Art.blob(self, p + Vector2(8, 5), 5.0, 5.0, Color("e98a7a"), 2.0, sd + 1)


# ---------- орда ----------

func _tint(base: Color, e: Enemy) -> Color:
	var c := base
	if e.blue > 0.0:
		c = c.lerp(Color("8fb6ff"), clampf(e.blue / 0.8, 0.0, 1.0) * 0.8)
	if e.flash > 0.0:
		c = c.lerp(Color.WHITE, 0.7)
	return c


func _draw_enemy(e: Enemy, fr: int) -> void:
	var sd := e.id * 7 + fr
	var p := e.pos
	var w := 3.0
	var rot := e.tumble * 14.0
	Art.fill_blob(self, p + Vector2(0, e.radius * 0.75), e.radius * 0.95, e.radius * 0.35, Color(0, 0, 0, 0.08))
	if e.from_player:
		draw_arc(p + Vector2(0, e.radius * 0.75), e.radius * 0.9, 0, TAU, 16, Color(0.42, 0.31, 0.7, 0.5), 2.0)
	match e.type:
		Enemy.T.SOCK:
			var ph := e.phase
			var sx := 1.0
			var sy := 1.0
			var lift := 0.0
			if ph < 0.35:
				var k := ph / 0.35
				sx = 1.0 + 0.2 * k
				sy = 1.0 - 0.25 * k
			elif ph < 0.7:
				var k := (ph - 0.35) / 0.35
				lift = sin(k * PI) * 16.0
				sx = 0.88
				sy = 1.15
			else:
				var k := (ph - 0.7) / 0.3
				sx = 1.0 + 0.15 * (1.0 - k)
				sy = 1.0 - 0.12 * (1.0 - k)
			var c := p - Vector2(0, lift)
			var face := 1.0 if e.move_dir.x >= 0.0 else -1.0
			var body := _tint(Color("f1eee8"), e)
			# носок буквой «L»: голенище и стопа носком вперёд
			Art.blob(self, c + Vector2(-1.0 * face * sx, -3.0 * sy).rotated(rot), 6.5 * sx, 11.0 * sy, body, w, sd, rot)
			Art.blob(self, c + Vector2(5.0 * face * sx, 8.0 * sy).rotated(rot), 10.0 * sx, 5.5 * sy, body, w, sd + 1, rot)
			Art.fill_blob(self, c + Vector2(0.0, 4.0 * sy).rotated(rot), 4.5 * sx, 5.0 * sy, body)
			Art.fill_blob(self, c + Vector2(12.0 * face * sx, 8.0 * sy).rotated(rot), 3.5 * sx, 3.5 * sy, _tint(Color("d6d0c6"), e))
			Art.fill_blob(self, c + Vector2(-3.0 * face * sx, 8.5 * sy).rotated(rot), 3.5 * sx, 3.0 * sy, _tint(Color("d6d0c6"), e))
			draw_line(c + Vector2(-6 * sx - face, -11 * sy).rotated(rot), c + Vector2(5 * sx - face, -11 * sy).rotated(rot), Color("b8b0a5"), 2.5)
			draw_line(c + Vector2(-6 * sx - face, -7 * sy).rotated(rot), c + Vector2(5 * sx - face, -7 * sy).rotated(rot), Color("b8b0a5"), 2.0)
		Enemy.T.BALL:
			var c := p
			Art.blob(self, c, 9.5, 9.5, _tint(Color("dfe3e8"), e), w, sd, 0.0)
			var a := time_roll(e)
			draw_line(c + Vector2(-8, 0).rotated(a), c + Vector2(8, 0).rotated(a), Color("9aa6b6"), 2.5)
			draw_circle(c + Vector2(0, -3).rotated(a * 0.5), 2.6, Color("b8a777"))
		Enemy.T.SLIPPER:
			var a := e.move_dir.angle()
			var flap := sin(e.phase * TAU) * 0.08
			var c := p
			Art.blob(self, c, 19.0, 12.0 * (1.0 + flap), _tint(Color("ecdbd5"), e), w, sd, a + rot)
			Art.blob(self, c + Vector2(5, 0).rotated(a), 8.0, 13.0, _tint(Color("d7b9b0"), e), 2.5, sd + 3, a + rot)
			Art.fill_blob(self, c + Vector2(-10, 0).rotated(a), 5.0, 6.0, _tint(Color("e2cbc4"), e))
		Enemy.T.SPRAYER:
			var squat := 0.82 if e.shoot_cd > 2.9 else 1.0
			var c := p + Vector2(0, 12.0 * (1.0 - squat))
			Art.blob(self, c, 9.0, 12.0 * squat, _tint(Color("d4e6ef"), e), w, sd, 0.0)
			var head := c + Vector2(0, -14 * squat)
			draw_rect(Rect2(head - Vector2(5, 4), Vector2(10, 7)), _tint(Color("9cc0d4"), e))
			draw_rect(Rect2(head - Vector2(5, 4), Vector2(10, 7)), INK, false, 2.0)
			draw_line(head + Vector2(5, -1), head + Vector2(10, -1), INK, 2.0)
			draw_circle(c + Vector2(-3, -2), 1.6, INK)
			draw_circle(c + Vector2(3, -2), 1.6, INK)
		Enemy.T.HAND:
			_draw_hand(e, sd)


func time_roll(e: Enemy) -> float:
	return (e.pos.x + e.pos.y) * 0.08


func _draw_hand(e: Enemy, sd: int) -> void:
	var p := e.pos
	var wind := e.grab_state == 1
	var spread := 1.0
	var crouch := 0.0
	if wind:
		var k := 1.0 - clampf(e.grab_t / 0.5, 0.0, 1.0)
		spread = 1.0 + 0.5 * k
		crouch = 4.0 * k
		draw_arc(p, 1.9 * 40.0, 0, TAU * k, 40, Color(0.75, 0.25, 0.2, 0.75), 3.0, true)
		draw_arc(p, 1.9 * 40.0, 0, TAU, 40, Color(0.75, 0.25, 0.2, 0.25), 1.5, true)
	var col := _tint(Color("efe2d0"), e)
	for k in 5:
		var a := -PI * 0.5 + (float(k) - 2.0) * 0.42 * spread
		var walk := sin(e.phase * TAU + k * 1.7) * 3.0 if not wind else 0.0
		var fp := p + Vector2(0, crouch) + Vector2(cos(a), sin(a)) * (17.0 + walk)
		Art.blob(self, fp, 4.5, 8.0, col, 2.5, sd + k, a + PI * 0.5)
	Art.blob(self, p + Vector2(0, crouch), 15.0, 13.0, col, 3.0, sd)
	if e.carries_chest:
		var cp := p + Vector2(0, crouch - 4)
		var pts := Art.wobbly_rect(Rect2(cp - Vector2(11, 8), Vector2(22, 15)), sd, 1.0)
		draw_colored_polygon(pts, Color("f6c94a"))
		Art.outline(self, pts, INK, 2.5)
	var hpw := 34.0
	draw_rect(Rect2(p + Vector2(-hpw * 0.5, 24), Vector2(hpw, 4)), Color(0, 0, 0, 0.15))
	draw_rect(Rect2(p + Vector2(-hpw * 0.5, 24), Vector2(hpw * clampf(e.hp / e.max_hp, 0, 1), 4)), Color("c9a27a"))


# ---------- герой ----------

func _draw_aura() -> void:
	var h: Hero = game.hero
	var lvl := h.lvl_of("bell")
	if lvl <= 0:
		return
	var r := (1.6 + 0.25 * lvl) * 40.0
	Art.fill_blob(self, h.pos, r, r, Color(0.98, 0.85, 0.35, 0.07))
	draw_arc(h.pos, r, 0, TAU, 48, Color(0.9, 0.7, 0.25, 0.35), 2.0, true)


func _draw_hero(fr: int) -> void:
	var h: Hero = game.hero
	var p := h.pos
	var face := 1.0 if h.heading.x >= 0.0 else -1.0
	var moving := h.vel.length() > 10.0
	var hop := absf(sin(h.bob)) * 5.0 if moving else 0.0
	var puff := 1.0 + 0.12 * clampf((h.greed - 0.6) / 0.4, 0.0, 1.0)
	var sd := 991 + fr
	var c := p - Vector2(0, hop)
	# герой крупнее орды: масштаб вокруг его точки
	draw_set_transform(p * (1.0 - HERO_SCALE), 0.0, Vector2(HERO_SCALE, HERO_SCALE))
	Art.fill_blob(self, p + Vector2(0, 14), 17, 6, Color(0, 0, 0, 0.12))
	# светлая подложка: героя видно в самой густой орде
	Art.fill_blob(self, c + Vector2(0, -2), 25.0 * puff, 23.0 * puff, Color(1, 0.99, 0.94, 0.9), sd)
	var green := C_GREEN.lerp(Color.WHITE, 0.5) if h.hurt > 0.0 else C_GREEN
	var tail := PackedVector2Array([c + Vector2(-face * 12, 4), c + Vector2(-face * 30, 14), c + Vector2(-face * 27, 3)])
	draw_colored_polygon(tail, Color("3f7d5a"))
	Art.outline(self, tail, INK, 3.0)
	Art.blob(self, c + Vector2(-2 * face, 3), 16.0 * puff, 13.0 * puff, green, 4.0, sd)
	Art.blob(self, c + Vector2(-5 * face, 3), 10.0, 7.0, C_WING, 3.0, sd + 2, -0.3 * face)
	for k in 2:
		draw_arc(c + Vector2(-5 * face - 2 + k * 4, 2 + k * 3), 4.0, 0.2, PI - 0.2, 6, Color("2f5e33"), 1.5)
	var head := c + Vector2(8 * face, -10)
	Art.blob(self, head, 10.5, 10.0, C_YELLOW, 4.0, sd + 4)
	for k in 3:
		var hx := head + Vector2(-face * (3 + k * 2.5), -4 + k * 2)
		draw_arc(hx, 3.0, PI * 1.1, PI * 1.9, 5, Color("6b5a2a"), 1.3)
	# хохолок: прижат — спокоен, дыбом — стресс, распушён — жадность
	var crest_a := -2.4 if face > 0 else -0.74
	var lift := 0.0
	if h.stress > 0.6:
		lift = 1.0
	var greedy := h.greed > 0.65
	for k in 3:
		var base := head + Vector2(-face * 2 + k * face * 3, -9)
		var a := lerpf(crest_a, -PI * 0.5, lift) + (k - 1) * (0.35 if greedy else 0.15)
		var tip := base + Vector2(cos(a), sin(a)) * (9.0 if greedy else 7.0)
		draw_line(base, tip, INK, 2.5, true)
	var eye := head + Vector2(3 * face, -2)
	draw_circle(eye, 2.6, INK)
	draw_circle(eye + Vector2(-0.8, -0.9), 0.8, Color.WHITE)
	draw_circle(head + Vector2(7 * face, 1), 2.2, Color("6d8fd6"))
	var beak := PackedVector2Array([head + Vector2(8 * face, 2), head + Vector2(13 * face, 5), head + Vector2(8 * face, 8)])
	draw_colored_polygon(beak, Color("f0a64a"))
	Art.outline(self, beak, INK, 2.0)
	draw_circle(head + Vector2(2 * face, 6), 2.2, Color("5f6fcf"))
	if h.stun > 0.0 or h.held > 0.0:
		for k in 3:
			var a := float(Time.get_ticks_msec()) * 0.008 + k * TAU / 3.0
			var sp := head + Vector2(0, -18) + Vector2(cos(a) * 14.0, sin(a) * 5.0)
			Art.blob(self, sp, 3.5, 2.5, Color("f6cd56"), 1.5, k, a)
	if h.mode == Hero.Mode.PANIC:
		for k in 2:
			var a := float(Time.get_ticks_msec()) * 0.004 + k * 2.5
			var fp := c + Vector2(cos(a) * 26.0, -8 + sin(a * 1.3) * 10.0)
			Art.blob(self, fp, 5.0, 2.0, C_GREEN, 1.5, k + fr, a)
	draw_set_transform(Vector2.ZERO)
	var hw := 44.0
	var hb := Rect2(p + Vector2(-hw * 0.5, -56), Vector2(hw, 5))
	draw_rect(hb, Color(0, 0, 0, 0.18))
	draw_rect(Rect2(hb.position, Vector2(hw * h.hp_frac(), 5)), Color("d95c4a") if h.hp_frac() < 0.2 else Color("6fae5c"))
	draw_rect(hb, INK, false, 1.5)


func _draw_intent() -> void:
	var h: Hero = game.hero
	if not h.valid(h.target) or (h.mode != Hero.Mode.GOAL and h.mode != Hero.Mode.HUNT):
		return
	var tp := Hero.opos(h.target)
	var col := Color(0.82, 0.58, 0.12, 0.85)
	# пунктир — идёт к цели, сплошная — «вцепился»
	if h.greed > 0.6:
		draw_line(h.pos, tp, col, 3.0, true)
	else:
		draw_dashed_line(h.pos, tp, col, 2.0, 10.0)


func _draw_focus() -> void:
	var h: Hero = game.hero
	for o in h.focus:
		var p := Hero.opos(o)
		var s := 18.0
		if o is Enemy:
			s = 30.0
		elif o.has("r"):
			s = float(o["r"]) * 0.75 if o.has("delay") else 18.0
		elif int(o["id"]) == int(h.horde_obj["id"]):
			s = 48.0
		elif o.has("life") and o.has("taken") and not o.has("big"):
			s = 26.0
		_brackets(p, s, C_FOCUS)


func _brackets(p: Vector2, s: float, col: Color) -> void:
	var l := maxf(6.0, s * 0.35)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var c := p + Vector2(sx * s, sy * s)
			draw_line(c, c - Vector2(sx * l, 0), col, 2.0, true)
			draw_line(c, c - Vector2(0, sy * l), col, 2.0, true)


func _draw_overhead() -> void:
	var h: Hero = game.hero
	var label: String = Hero.MODE_NAMES[h.mode]
	if h.dodging:
		label = "уворот!"
	elif h.opening > 0.0:
		label = "открываю"
	elif h.held > 0.0:
		label = "схвачен"
	elif h.stun > 0.0:
		label = "оглушён"
	var size := 15
	var w := Art.text_w(font, label, size) + 16.0
	var c := h.pos + Vector2(0, -76)
	var r := Rect2(c - Vector2(w * 0.5, 13), Vector2(w, 22))
	var fill := Color("fff8ea")
	if h.mode == Hero.Mode.PANIC or h.dodging:
		fill = Color("ffd9cf")
	elif h.mode == Hero.Mode.GOAL or h.mode == Hero.Mode.HUNT:
		fill = Color("ffefc2")
	Art.card(self, r, fill, Art.frame() + 3, INK, 2.0)
	draw_line(c + Vector2(-4, 9), c + Vector2(0, 16), INK, 2.0)
	draw_line(c + Vector2(4, 9), c + Vector2(0, 16), INK, 2.0)
	draw_string(font, Vector2(r.position.x + 8, c.y + 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, INK)


# ---------- книги и эффекты ----------

func _draw_shadow(m: Dictionary) -> void:
	var p: Vector2 = m["pos"]
	var r: float = m["r"]
	if not m["landed"]:
		var k := clampf(float(m["t"]) / float(m["delay"]), 0.0, 1.0)
		Art.fill_blob(self, p, r * (0.35 + 0.65 * k), r * (0.35 + 0.65 * k) * 0.92, Color(0.18, 0.12, 0.09, 0.10 + 0.25 * k))
		draw_arc(p, r, 0, TAU, 48, Color(0.3, 0.2, 0.15, 0.45), 1.5, true)
	else:
		var a := 1.0 - clampf(float(m["land_t"]) / 0.9, 0.0, 1.0)
		var pts := Art.rot_rect(p, 74, 52, 0.3)
		draw_colored_polygon(pts, Color(0.76, 0.36, 0.29, a))
		Art.outline(self, pts, Color(INK, a), 3.0)
		var pg := Art.rot_rect(p + Vector2(4, 3), 64, 40, 0.3)
		Art.outline(self, pg, Color(1, 0.96, 0.88, a), 2.0)


func _draw_book(m: Dictionary, fr: int) -> void:
	if m["landed"]:
		return
	var k := clampf(float(m["t"]) / float(m["delay"]), 0.0, 1.0)
	if k < 0.55:
		return
	var kk := (k - 0.55) / 0.45
	var p: Vector2 = m["pos"] - Vector2(0, pow(1.0 - kk, 2.0) * 420.0)
	var sc := 1.35 - 0.35 * kk
	var rot := 0.3 + (1.0 - kk) * 1.2
	var pts := Art.rot_rect(p, 74 * sc, 52 * sc, rot)
	draw_colored_polygon(pts, Color("c25b4a"))
	Art.outline(self, pts, INK, 3.0)
	draw_line(p + Vector2(-30 * sc, 0).rotated(rot), p + Vector2(30 * sc, 0).rotated(rot), Color("f0d27a"), 3.0)


func _draw_fx(f: Dictionary, fr: int) -> void:
	var t: float = f["t"]
	var k: float = t / float(f["dur"])
	var p: Vector2 = f["pos"]
	match f["kind"]:
		"ring":
			var col: Color = f["color"]
			col.a *= 1.0 - k
			draw_arc(p, float(f["r"]) * (0.4 + 0.6 * k), 0, TAU, 48, col, 3.0, true)
		"dust":
			var r: float = f["r"]
			for i in 8:
				var a := TAU * i / 8.0
				Art.blob(self, p + Vector2(cos(a), sin(a)) * r * (0.6 + 0.5 * k), 12 * (1.0 - k) + 4, 9 * (1.0 - k) + 3, Color(0.9, 0.85, 0.78, 1.0 - k), 1.5, i + fr, 0.0, Color(0.55, 0.47, 0.4, 1.0 - k))
		"beam":
			var to: Vector2 = f["to"]
			draw_line(p, to, Color(1.0, 0.95, 0.55, 0.65 * (1.0 - k)), 10.0, true)
			draw_line(p, to, Color(1.0, 1.0, 0.9, 0.9 * (1.0 - k)), 3.0, true)
		"peck":
			var to: Vector2 = f["to"]
			var d := (to - p).normalized()
			draw_arc(p + d * 18.0, 12.0, d.angle() - 0.9, d.angle() + 0.9, 8, Color(INK, 1.0 - k), 2.5, true)
		"jingle":
			for i in 3:
				draw_arc(p, 14.0 + i * 12.0 + k * 20.0, 0, TAU, 24, Color(0.45, 0.5, 0.6, 0.8 * (1.0 - k)), 2.0, true)
			Art.text_c(self, font, p + Vector2(0, -40), "дзынь!", 18, Color(0.35, 0.4, 0.5, 1.0 - k), Color(1, 1, 1, 0.8 * (1.0 - k)), 4)
		"basket":
			Art.blob(self, p, 50, 30, Color(0.86, 0.74, 0.55, 1.0 - k), 3.0, fr, 0.0, Color(INK, 1.0 - k))
			for i in 4:
				draw_line(p + Vector2(-40 + i * 26, -22), p + Vector2(-44 + i * 26, 22), Color(0.6, 0.48, 0.32, 1.0 - k), 2.0)
		"stamp":
			var a := 1.0 - clampf((k - 0.6) / 0.4, 0.0, 1.0)
			Art.text_c(self, font, p + Vector2(0, 8), "СОРВАНО", 26, Color(0.75, 0.2, 0.15, a), Color(1, 0.97, 0.9, a), 5)


func _draw_debug() -> void:
	var h: Hero = game.hero
	for i in Hero.NDIR:
		var d := h.dirs[i]
		var closed := h.dbg_D[i] > h.dbg_thr
		var col := Color(0.85, 0.2, 0.2, 0.8) if closed else Color(0.25, 0.65, 0.3, 0.8)
		draw_line(h.pos, h.pos + d * (30.0 + h.dbg_D[i] * 40.0), col, 2.0)
		draw_line(h.pos + d * 20.0, h.pos + d * (20.0 + h.dbg_I[i] * 40.0), Color(0.85, 0.65, 0.1, 0.9), 4.0)
	draw_line(h.pos, h.pos + h.desired * 70.0, Color(0.1, 0.1, 0.8), 3.0)
	if h.horde_count > 0:
		draw_circle(h.horde_center, 6.0, Color(0.6, 0.1, 0.6, 0.7))
	draw_arc(h.pos, h.view_radius(), 0, TAU, 64, Color(0.3, 0.3, 0.8, 0.25), 1.0)
