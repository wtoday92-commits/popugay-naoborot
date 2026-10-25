class_name WorldView
extends Node2D
## Рисует поле: комнату с объёмной мебелью (сортировка по глубине), орду, героя, ивенты,
## «мысли» героя (линия намерения, рамки внимания, режим), меню над просом и выбор перка кругом.

const INK := Art.INK
const M := 40.0
const C_FLOOR := Color("e6d3b2")
const C_PLANK := Color("d3bc96")
const C_WALL := Color("b49d7c")
const C_GREEN := Color("7cc46a")
const C_WING := Color("58a04c")
const C_YELLOW := Color("f6d84c")
const C_FOCUS := Color("4f79a8")
const HERO_SCALE := 1.6
const FURN := {
	"sofa": Color("bfd6b8"), "shelf": Color("d9bf9a"), "table": Color("e6cfa8"), "armchair": Color("d2c4e3"),
	"plant": Color("e3b89c"), "stool": Color("e8c98f"), "boxes": Color("dcc29b"), "lamp": Color("f3e3b0"),
	"books": Color("c9d8e8"), "toys": Color("d9b98a"), "nightstand": Color("cfb08c"), "catbed": Color("f2cfc6"),
	"chair": Color("c7d9c0"),
}

var game
var font: Font
var _time := 0.0


func _ready() -> void:
	font = ThemeDB.fallback_font


func _process(delta: float) -> void:
	_time += delta


func _draw() -> void:
	if game == null or game.hero == null:
		return
	var fr := Art.frame()
	_draw_room(fr)
	_draw_event_floor(fr)
	for m in game.meteors:
		_draw_shadow(m)
	for g in game.gems:
		_draw_gem(g, fr)
	for c in game.chests:
		_draw_chest(c, fr)
	for f in game.fruit_drops:
		var fp: Vector2 = f["pos"]
		var hop := absf(sin(float(f["t"]) * 6.0)) * 10.0 * maxf(0.0, 1.0 - float(f["t"]) / 0.8)
		Art.fill_blob(self, fp + Vector2(0, 14), 14, 5, Color(0, 0, 0, 0.12))
		Art.fill_blob(self, fp - Vector2(0, hop), 22, 22, Color(1, 0.9, 0.5, 0.35))
		Icons.draw(self, f["fruit"], fp - Vector2(0, hop), 34.0, clampf(float(f["life"]) / 2.0, 0.3, 1.0), false)
	for z in game.zones:
		_draw_zone(z, fr)
	for m in game.mines:
		_draw_mine(m)
	for t in game.tornados:
		_draw_tornado(t)
	_draw_aura()
	for f in game.fx:
		if f["kind"] == "burnline":
			_draw_fx(f, fr)
	# всё, что стоит на полу, рисуем по глубине: дальше — раньше
	var items: Array = []
	for i in game.furniture.size():
		var r: Rect2 = game.furniture[i][0]
		items.append([r.end.y, 0, i])
	for e in game.enemies:
		if not e.dead:
			items.append([e.pos.y + e.radius, 1, e])
	if game.over == "" or game.hero.pos.y > -100.0:
		items.append([game.hero.pos.y + game.hero.radius + (2000.0 if game.phase != "play" or game.over != "" else 0.0), 2, null])
	items.sort_custom(func(a, b): return a[0] < b[0])
	_draw_intent()
	for it in items:
		match it[1]:
			0:
				_draw_furniture(it[2], fr)
			1:
				_draw_enemy(it[2], fr)
			2:
				_draw_hero(fr)
	_draw_orbit(fr)
	# что схватит лапка: подсветка, только когда рогатка готова
	if game.phase == "play" and game.over == "" and game.held_e == null and game.throw_cd <= 0.0 and game.levelup.is_empty():
		var gt = game.grab_target(game.paw["pos"])
		if gt != null:
			draw_arc(gt.pos, gt.radius + 9.0, 0, TAU, 24, Color(0.42, 0.31, 0.7, 0.9), 3.0, true)
	for s in game.shots:
		_draw_shot(s)
	_draw_laser()
	for s in game.enemy_shots:
		var p: Vector2 = s["pos"]
		Art.blob(self, p, 13.0, 10.0, Color(0.72, 0.86, 0.95, 0.75), 2.0, int(s["id"]) + fr, 0.0, Color("6f9bb8"))
		draw_circle(p + Vector2(-4, -3), 3.0, Color(1, 1, 1, 0.8))
	for s in game.thrown:
		var e: Enemy = s["e"]
		var v: Vector2 = s["vel"]
		var fire: float = s["fire"]
		e.pos = s["pos"]
		var dn := v.normalized()
		# след: серый у холодного броска, языки пламени у разгоревшегося носка
		for k in 6:
			var q := e.pos - dn * (14.0 + k * 9.0) + Vector2(-dn.y, dn.x) * sin(_time * 30.0 + k) * 4.0 * fire
			var col := Color(INK, 0.3 * (1.0 - k / 6.0)).lerp(Color(1.0, 0.45 + 0.08 * k, 0.1, 0.9 * (1.0 - k / 6.0)), fire)
			draw_circle(q, (8.0 - k) * (0.5 + fire), col)
		if fire > 0.3:
			Art.fill_blob(self, e.pos, 20.0 * fire + 6.0, 20.0 * fire + 6.0, Color(1.0, 0.55, 0.15, 0.35 * fire))
		e.tumble = float(s["spin"])
		_draw_enemy(e, fr)
	for s in game.missiles:
		_draw_missile(s, fr)
	if game.held_e != null:
		game.held_e.tumble = 0.0
		_draw_enemy(game.held_e, fr)
	for f in game.fx:
		if f["kind"] != "burnline" and f["kind"] != "event_card" and f["kind"] != "reward_fly":
			_draw_fx(f, fr)
	for m in game.meteors:
		if m.has("basket"):
			_draw_basket_front(m)
		else:
			_draw_book(m, fr)
	_draw_focus()
	_draw_overhead()
	_draw_boss_bar()
	for t in game.texts:
		var a := 1.0 - clampf((float(t["t"]) - 0.7) / 0.5, 0.0, 1.0)
		var col: Color = t["color"]
		col.a = a
		Art.text_c(self, font, t["pos"], t["text"], int(t["size"]), col, Color(1, 0.98, 0.94, a * 0.9), 5)
	_draw_event_marks(fr)
	_draw_outro_items(fr)
	_draw_menu(fr)
	_draw_tut(fr)
	_draw_levelup(fr)
	if game.debug:
		_draw_debug()


# ---------- комната ----------

func _draw_room(fr: int) -> void:
	var f: Rect2 = game.floor_rect
	var field: Rect2 = game.FIELD
	draw_rect(field, C_WALL)
	for i in 30:
		var x := field.position.x + 20.0 + i * 42.0
		draw_circle(Vector2(x, 16), 3.0, Color("bba487"))
		draw_circle(Vector2(x, 1064), 3.0, Color("bba487"))
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
	# ковёр плоский: тонкая линия, без объёма
	Art.blob(self, game.rug_pos, 250, 150, Color("dccadb"), 1.5, 7, 0.0, Color("bea6bb"), 0.02)
	Art.blob(self, game.rug_pos, 195, 108, Color("e5d6e3"), 1.0, 9, 0.0, Color("ccb6c9"), 0.02)
	Art.outline(self, Art.wobbly_rect(f, fr, 1.0), INK, 3.5)
	# плинтус
	draw_rect(Rect2(f.position.x, f.position.y, f.size.x, 6), Color("b7a283"))


func _shade(c: Color, k: float) -> Color:
	return Color(c.r * k, c.g * k, c.b * k, c.a)


## Мебель — объём: основание на полу, верх поднят на высоту, передняя грань темнее, тень.
func _draw_furniture(i: int, fr: int) -> void:
	var r: Rect2 = game.furniture[i][0]
	var kind: String = game.furniture[i][1]
	var h: float = game.furniture[i][2]
	var fb: float = game.furniture_bounce
	if fb > 0.0:
		r.position.y -= absf(sin(fb * 18.0 + i)) * 14.0 * fb
	var col: Color = FURN.get(kind, Color("e0d0b8"))
	var line := Color("5e4e42")
	var sd := i * 13 + fr
	# тень вправо-вниз
	var sh := Art.wobbly_rect(Rect2(r.position + Vector2(10, 8), r.size), sd, 2.0)
	draw_colored_polygon(sh, Color(0.25, 0.18, 0.1, 0.16))
	match kind:
		"lamp":
			Art.fill_blob(self, r.get_center() + Vector2(6, 6), 30, 16, Color(0.25, 0.18, 0.1, 0.12))
			Art.blob(self, r.get_center() + Vector2(0, 10), 22, 12, _shade(col, 0.8), 2.5, sd, 0.0, line)
			draw_line(r.get_center() + Vector2(0, 8), r.get_center() + Vector2(0, -h + 10), line, 4.0)
			Art.blob(self, r.get_center() + Vector2(0, -h + 6), 30, 20, col, 3.0, sd + 1, 0.0, line)
			Art.blob(self, r.get_center() + Vector2(0, -h + 2), 18, 10, Color("fff6d8"), 2.0, sd + 2, 0.0, line)
			return
		"plant":
			var pot := PackedVector2Array([r.position + Vector2(8, 10), Vector2(r.end.x - 8, r.position.y + 10), Vector2(r.end.x - 16, r.end.y), Vector2(r.position.x + 16, r.end.y)])
			draw_colored_polygon(pot, col)
			Art.outline(self, pot, line, 2.5)
			for k in 6:
				var a := TAU * k / 6.0 + 0.3
				Art.blob(self, r.get_center() + Vector2(0, -h * 0.6) + Vector2(cos(a), sin(a) * 0.6) * 24, 18, 9, Color("9fcf8c"), 2.5, sd + k, a, line)
			return
	var top := Rect2(r.position - Vector2(0, h), r.size)
	var front := Rect2(Vector2(r.position.x, r.end.y - h), Vector2(r.size.x, h))
	var fp := Art.wobbly_rect(front, sd + 3, 1.0)
	draw_colored_polygon(fp, _shade(col, 0.78))
	Art.outline(self, fp, line, 2.5)
	var tp := Art.wobbly_rect(top, sd, 1.2)
	draw_colored_polygon(tp, col)
	Art.outline(self, tp, line, 3.0)
	match kind:
		"sofa":
			for k in 3:
				var cr := Rect2(top.position.x + 14 + k * 92, top.position.y + 34, 84, 66)
				Art.outline(self, Art.wobbly_rect(cr, k + fr, 1.2), line, 2.0)
			Art.outline(self, Art.wobbly_rect(Rect2(top.position + Vector2(6, 6), Vector2(top.size.x - 12, 22)), fr + 7, 1.0), line, 2.0)
		"shelf":
			var bc := [Color("e0a49a"), Color("a9c3dd"), Color("e7cf8f"), Color("b9d4ad"), Color("cdb3dc")]
			for k in 11:
				var by := top.position.y + 10 + k * 25
				var br := Rect2(top.position.x + 10, by, 70 - (k % 3) * 8, 19)
				draw_rect(br, bc[k % 5])
				draw_rect(br, line, false, 1.5)
		"table", "nightstand", "stool", "chair":
			Art.outline(self, Art.wobbly_rect(top.grow(-10), fr + 3, 1.0), _shade(line, 1.3), 1.5)
			if kind == "table":
				Art.blob(self, top.get_center() + Vector2(34, -8), 14, 12, Color("fffaf0"), 2.0, fr, 0.0, line)
				Art.blob(self, top.get_center() + Vector2(-30, 6), 22, 14, Color("f4e3c8"), 2.0, fr + 1, 0.2, line)
			if kind == "chair":
				Art.outline(self, Art.wobbly_rect(Rect2(top.position, Vector2(top.size.x, 18)), fr + 4, 1.0), line, 2.5)
		"armchair":
			Art.blob(self, top.get_center() + Vector2(0, 12), 48, 40, _shade(col, 1.08), 2.0, fr + 5, 0.0, line)
		"boxes":
			draw_line(top.position + Vector2(0, top.size.y * 0.5), Vector2(top.end.x, top.position.y + top.size.y * 0.5), line, 2.0)
			draw_line(Vector2(top.get_center().x, top.position.y), Vector2(top.get_center().x, top.end.y), _shade(line, 1.3), 1.5)
		"books":
			for k in 3:
				draw_line(Vector2(front.position.x + 4, front.position.y + 7 + k * 7), Vector2(front.end.x - 4, front.position.y + 7 + k * 7), Color("fffaf0"), 2.0)
		"toys":
			Art.blob(self, top.get_center() + Vector2(-18, -8), 12, 12, Color("e98a7a"), 2.0, fr, 0.0, line)
			Art.blob(self, top.get_center() + Vector2(16, -4), 10, 10, Color("8fb6e8"), 2.0, fr + 1, 0.0, line)
			Art.blob(self, top.get_center() + Vector2(0, 14), 14, 7, Color("f2c14e"), 2.0, fr + 2, 0.3, line)
		"catbed":
			Art.blob(self, top.get_center(), 62, 40, Color("fbe7e1"), 2.0, fr + 2, 0.0, line)


# ---------- ивенты на полу ----------

func _draw_event_floor(fr: int) -> void:
	var ev: Dictionary = game.event
	if ev.is_empty():
		return
	var left: float = ev["left"]
	match ev["type"]:
		"circle":
			var p: Vector2 = ev["pos"]
			var r: float = ev["r"]
			var pulse := 0.5 + 0.5 * sin(_time * 3.0)
			Art.fill_blob(self, p, r, r * 0.92, Color(1.0, 0.9, 0.4, 0.22 + 0.06 * pulse))
			for k in 12:
				var a := TAU * k / 12.0 + _time * 0.3
				draw_line(p + Vector2(cos(a), sin(a)) * (r + 6), p + Vector2(cos(a), sin(a)) * (r + 18), Color(0.9, 0.7, 0.2, 0.7), 2.5)
			draw_arc(p, r, 0, TAU, 48, Color(0.85, 0.6, 0.15, 0.9), 3.0, true)
			var prog: float = game.event_progress()
			draw_arc(p, r - 10, -PI * 0.5, -PI * 0.5 + TAU * prog, 48, Color(0.95, 0.55, 0.1, 0.95), 7.0, true)
			Art.text_c(self, font, p + Vector2(0, -r - 22), "%d/%d · %d с" % [int(ev["kills"]), int(ev["need"]), int(ceil(left))], 20, Color("8a5a1e"), Color(1, 0.98, 0.9, 0.9), 5)
		"altar":
			var p: Vector2 = ev["pos"]
			Art.fill_blob(self, p + Vector2(4, 6), 30, 12, Color(0, 0, 0, 0.12))
			Art.blob(self, p, 30, 14, Color("f7f3e8"), 3.0, fr, 0.0, INK)
			Art.blob(self, p + Vector2(0, -8), 15, 11, Color("b98a6a"), 3.0, fr + 1, 0.0, INK)
			draw_circle(p + Vector2(-5, -12), 3.0, Color("f3a7b5"))
			draw_arc(p, 40, -PI * 0.5, -PI * 0.5 + TAU * left / 20.0, 32, Color(0.7, 0.2, 0.2, 0.8), 3.0, true)
			Art.text_c(self, font, p + Vector2(0, -36), "?", 26, Color("b23a2e"), Color(1, 1, 1, 0.8), 4)


# ---------- награды ----------

func _draw_gem(g: Dictionary, fr: int) -> void:
	var p: Vector2 = g["pos"]
	var age: float = game.time - float(g["born"])
	var pop := 1.0 + 0.4 * maxf(0.0, 1.0 - age / 0.2)
	if g["glow"]:
		var pulse := 0.5 + 0.5 * sin(_time * 5.0 + float(g["id"]))
		Art.fill_blob(self, p, 26 + 6 * pulse, 26 + 6 * pulse, Color(0.4, 0.85, 0.95, 0.25))
		draw_line(p + Vector2(-2, 13), p + Vector2(3, -13), Color("b98c34"), 2.5, true)
		Art.blob(self, p, 8.0, 14.0, Color("fff3a0"), 2.5, int(g["id"]) + fr, 0.25, Color("2f8fa8"))
		return
	if g["big"] and g.has("mod"):
		_draw_swapped(g, p, fr)
		return
	if g["big"]:
		var sd: int = int(g["id"]) + fr
		draw_line(p + Vector2(-2, 13) * pop, p + Vector2(3, -13) * pop, Color("b98c34"), 2.0, true)
		Art.blob(self, p, 6.5 * pop, 12.5 * pop, Color("f5c84c"), 2.0, sd, 0.25, Color("a0742a"))
		for k in 4:
			draw_circle(p + Vector2(-1.5 + (k % 2) * 3.0, -7.0 + k * 4.5).rotated(0.25), 1.6, Color("d9a43a"))
	else:
		draw_circle(p, 3.8 * pop, Color("a0742a"))
		draw_circle(p, 2.7 * pop, Color("f6cd56"))


## Подменённое просо: игрок видит, во что оно превратилось, попугай — обычный колосок.
func _draw_swapped(g: Dictionary, p: Vector2, fr: int) -> void:
	var sd: int = int(g["id"]) + fr
	Art.fill_blob(self, p + Vector2(0, 10), 16, 5, Color(0, 0, 0, 0.12))
	match g["mod"]:
		"trap":
			# капкан: две полудуги с зубьями и пружина
			for sgn in [-1.0, 1.0]:
				draw_arc(p + Vector2(0, sgn * 4.0), 15.0, PI if sgn < 0 else 0.0, (PI if sgn < 0 else 0.0) + PI, 12, Color("7d838c"), 4.0, true)
				for t in 5:
					var x := -11.0 + t * 5.5
					draw_line(p + Vector2(x, sgn * 4.0), p + Vector2(x + 2.5, sgn * -1.0), Color("4a4f57"), 2.0)
			draw_circle(p, 4.0, Color("b7bcc4"))
			draw_arc(p, 4.0, 0, TAU, 8, INK, 1.5)
			Art.blob(self, p + Vector2(10, -10), 3.0, 6.0, Color("f5c84c"), 1.5, sd, 0.4, Color("a0742a"))
		"rotten":
			# тухлое: бурый колосок, мухи и вонь
			draw_line(p + Vector2(-2, 13), p + Vector2(3, -13), Color("6e5a2a"), 2.0, true)
			Art.blob(self, p, 6.5, 12.5, Color("9a9a4a"), 2.0, sd, 0.25, Color("4e5a22"))
			for k in 3:
				draw_circle(p + Vector2(-1.5 + (k % 2) * 3.0, -6.0 + k * 5.0).rotated(0.25), 1.8, Color("5a6a2a"))
			for k in 3:
				var a := _time * 4.0 + k * TAU / 3.0
				draw_circle(p + Vector2(cos(a) * 16.0, -12.0 + sin(a * 1.7) * 6.0), 2.0, INK)
			draw_arc(p + Vector2(-8, -22 - fmod(_time * 10.0, 8.0)), 4.0, 0, PI * 1.5, 6, Color(0.4, 0.55, 0.2, 0.8), 2.0)
		"egg":
			Art.blob(self, p, 10.0, 13.0, Color("fff7e6"), 2.5, sd)
			for k in 3:
				draw_circle(p + Vector2(-4 + (k % 2) * 7, -5 + k * 5), 1.8, Color("d98a7a"))
			if fmod(_time, 1.6) < 0.2:
				draw_polyline(PackedVector2Array([p + Vector2(-6, -2), p + Vector2(-2, -5), p + Vector2(2, -1)]), INK, 1.5)
		_:
			Art.blob(self, p, 6.5, 12.5, Color("f5c84c"), 2.0, sd, 0.25, Color("a0742a"))


func _draw_chest(c: Dictionary, fr: int) -> void:
	var p: Vector2 = c["pos"]
	var sd: int = int(c["id"]) + fr
	var life := clampf(float(c["life"]) / 30.0, 0.0, 1.0)
	draw_arc(p, 30.0, -PI * 0.5, -PI * 0.5 + TAU * life, 32, Color(0.85, 0.55, 0.15, 0.8), 3.0, true)
	var bob := sin(_time * 4.0) * 2.0
	var pts := Art.wobbly_rect(Rect2(p - Vector2(18, 12 + bob), Vector2(36, 24)), sd, 1.2)
	draw_colored_polygon(pts, Color("f6c94a"))
	Art.outline(self, pts, INK, 3.0)
	draw_line(p + Vector2(-14, -2 - bob), p + Vector2(14, -2 - bob), Color("b98c34"), 2.0)
	for k in 5:
		draw_circle(p + Vector2(-10 + k * 5, -6 - bob), 1.8, Color("fff2b0"))


# ---------- орда ----------

func _tint(base: Color, e: Enemy) -> Color:
	var c := base
	if e.blue > 0.0:
		c = c.lerp(Color("8fb6ff"), clampf(e.blue / 0.8, 0.0, 1.0) * 0.8)
	if e.burn > 0.0:
		c = c.lerp(Color("f08a3a"), 0.35)
	if e.slow > 0.0:
		c = c.lerp(Color("bfe3f5"), 0.5)
	if e.flash > 0.0:
		c = c.lerp(Color.WHITE, 0.75)
	return c


func _draw_enemy(e: Enemy, fr: int) -> void:
	var sd := e.id * 7 + fr
	var p := e.pos
	var w := 3.0
	var rot := e.tumble * 14.0 if e.tumble > 0.0 else 0.0
	if e.type != Enemy.T.BOSS:
		Art.fill_blob(self, p + Vector2(0, e.radius * 0.8), e.radius * 0.95, e.radius * 0.35, Color(0, 0, 0, 0.1))
	if e.from_player:
		draw_arc(p + Vector2(0, e.radius * 0.8), e.radius * 0.95, 0, TAU, 16, Color(0.42, 0.31, 0.7, 0.6), 2.0)
	if e.stun > 0.0 and e.type != Enemy.T.BOSS:
		for k in 2:
			var a := _time * 8.0 + k * PI
			draw_circle(p + Vector2(cos(a) * 9.0, -e.radius - 8 + sin(a) * 3.0), 2.0, Color("f6cd56"))
	match e.type:
		Enemy.T.SOCK, Enemy.T.SUPER:
			_draw_sock(e, sd, rot)
		Enemy.T.YARN:
			_draw_yarn(e, sd)
		Enemy.T.SLIPPER:
			var a := e.move_dir.angle()
			var flap := sin(e.phase * TAU) * 0.1
			Art.blob(self, p, 19.0, 12.0 * (1.0 + flap), _tint(Color("ecdbd5"), e), w, sd, a + rot)
			Art.blob(self, p + Vector2(5, 0).rotated(a), 8.0, 13.0, _tint(Color("d7b9b0"), e), 2.5, sd + 3, a + rot)
			Art.fill_blob(self, p + Vector2(-10, 0).rotated(a), 5.0, 6.0, _tint(Color("e2cbc4"), e))
			# глазки-дырочки делают тапок «живым»
			draw_circle(p + Vector2(10, -4).rotated(a), 1.8, INK)
			draw_circle(p + Vector2(10, 4).rotated(a), 1.8, INK)
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
		Enemy.T.DUST:
			var hop := absf(sin(e.phase)) * 5.0
			var c := p - Vector2(0, hop)
			Art.blob(self, c + Vector2(-4, -11), 3.0, 7.0, _tint(Color("c9c6c1"), e), 2.0, sd + 1, -0.3)
			Art.blob(self, c + Vector2(4, -11), 3.0, 7.0, _tint(Color("c9c6c1"), e), 2.0, sd + 2, 0.3)
			Art.blob(self, c, 10.0, 8.5, _tint(Color("d6d3ce"), e), 2.5, sd, 0.0, INK, 0.2)
			draw_circle(c + Vector2(-3, -1), 1.6, INK)
			draw_circle(c + Vector2(3, -1), 1.6, INK)
		Enemy.T.BOX:
			_draw_box(e, sd)
		Enemy.T.BOSS:
			_draw_boss(e, sd)
		Enemy.T.REMOTE, Enemy.T.PILLOW, Enemy.T.BALL, Enemy.T.CABLE, Enemy.T.ALARM, Enemy.T.SPONGE, Enemy.T.CAR:
			var key: String = game.ENAMES[e.type]
			if e.type == Enemy.T.CABLE and e.trail.size() > 1:
				# провод: хвост тянется за вилкой
				var pts := PackedVector2Array()
				for q in e.trail:
					pts.append(q)
				draw_polyline(pts, INK, 7.0, true)
				draw_polyline(pts, Color("3a3a44"), 4.0, true)
			var st := e.state
			if e.type == Enemy.T.ALARM:
				st = 1 if e.state_t > 0.0 else 0
			var tint := Color(1, 1, 1, 0.7) if e.flash > 0.0 else Color(1, 1, 1, 0)
			UnitArt.draw(self, key, p, 1.0, _time + float(e.id), st, e.move_dir if e.type != Enemy.T.CAR or e.state == 0 else e.dash_dir, tint)
	if e.shield > 0:
		# броня тапка: голубой полукруг-щиток
		draw_arc(p, e.radius + 6.0, PI * 1.05, PI * 1.95, 12, Color(0.35, 0.55, 0.85, 0.95), 4.0, true)
		draw_arc(p, e.radius + 6.0, PI * 1.05, PI * 1.95, 12, Color(0.85, 0.93, 1.0, 0.9), 1.5, true)


func _draw_sock(e: Enemy, sd: int, rot: float) -> void:
	var p := e.pos
	var w := 3.0
	var ph := e.phase
	var sx := 1.0
	var sy := 1.0
	var lift := 0.0
	var sup := e.type == Enemy.T.SUPER
	if sup and e.state == 1:
		sx = 1.3
		sy = 0.7
	elif sup and e.state == 2:
		sx = 0.8
		sy = 1.25
	elif ph < 0.35:
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
	var sc := 1.35 if sup else 1.0
	sx *= sc
	sy *= sc
	var c := p - Vector2(0, lift)
	var face := 1.0 if e.move_dir.x >= 0.0 else -1.0
	var body := _tint(Color("f1eee8"), e)
	var stripe := Color("b8b0a5")
	if sup:
		body = _tint(Color("fbe3dc"), e)
		stripe = Color("d9442e")
		if e.state == 1:
			draw_line(p, p + e.dash_dir * 90.0, Color(0.8, 0.2, 0.15, 0.5), 6.0)
	Art.blob(self, c + Vector2(-1.0 * face * sx, -3.0 * sy).rotated(rot), 6.5 * sx, 11.0 * sy, body, w, sd, rot)
	Art.blob(self, c + Vector2(5.0 * face * sx, 8.0 * sy).rotated(rot), 10.0 * sx, 5.5 * sy, body, w, sd + 1, rot)
	Art.fill_blob(self, c + Vector2(0.0, 4.0 * sy).rotated(rot), 4.5 * sx, 5.0 * sy, body)
	Art.fill_blob(self, c + Vector2(12.0 * face * sx, 8.0 * sy).rotated(rot), 3.5 * sx, 3.5 * sy, _tint(Color("d6d0c6"), e))
	draw_line(c + Vector2(-6 * sx - face, -11 * sy).rotated(rot), c + Vector2(5 * sx - face, -11 * sy).rotated(rot), stripe, 2.5)
	draw_line(c + Vector2(-6 * sx - face, -7 * sy).rotated(rot), c + Vector2(5 * sx - face, -7 * sy).rotated(rot), stripe, 2.0)
	if sup:
		draw_line(c + Vector2(-5 * sx, -1 * sy), c + Vector2(-1 * sx, 1 * sy), INK, 2.0)
		draw_line(c + Vector2(4 * sx, -1 * sy), c + Vector2(0 * sx, 1 * sy), INK, 2.0)
		draw_circle(c + Vector2(-3 * sx, 3 * sy), 1.8, INK)
		draw_circle(c + Vector2(2 * sx, 3 * sy), 1.8, INK)


## Клубок ниток: катится, за ним тянется нитка — читается сразу.
func _draw_yarn(e: Enemy, sd: int) -> void:
	var p := e.pos
	var base: Color = [Color("e98a9a"), Color("8fb6e8"), Color("b9d48f")][e.id % 3]
	var col := _tint(base, e)
	if e.trail.size() > 1:
		var pts := PackedVector2Array()
		for k in e.trail.size():
			pts.append(e.trail[k] + Vector2(sin(float(k) * 1.3 + e.phase * 0.2) * 3.0, 6.0))
		draw_polyline(pts, base.darkened(0.25), 2.0, true)
	Art.blob(self, p, 10.5, 10.0, col, 3.0, sd, 0.0)
	var a := e.phase * 0.3
	for k in 3:
		var off := Vector2(0, -6 + k * 6).rotated(a)
		draw_arc(p + off * 0.4, 9.0, a + 0.6 + k * 0.4, a + 2.6 + k * 0.4, 8, base.darkened(0.35), 1.6)


## Рука из «Семейки Аддамс», вид сбоку: бежит на пальцах, большой палец вперёд, манжета сзади.
func _draw_hand(e: Enemy, sd: int) -> void:
	var p := e.pos
	var face := 1.0 if e.move_dir.x >= 0.0 else -1.0
	var wind := e.grab_state == 1
	var col := _tint(Color("efe0cc"), e)
	var line := INK
	var crouch := 0.0
	var spread := 0.0
	if wind:
		var k := 1.0 - clampf(e.grab_t / 0.5, 0.0, 1.0)
		crouch = 6.0 * k
		spread = k
		draw_arc(p, 1.9 * M, 0, TAU * k, 40, Color(0.75, 0.25, 0.2, 0.75), 3.0, true)
		draw_arc(p, 1.9 * M, 0, TAU, 40, Color(0.75, 0.25, 0.2, 0.25), 1.5, true)
	var palm := p + Vector2(0, -10 + crouch)
	# четыре пальца-ноги: шагают по очереди
	for k in 4:
		var ph := e.phase * TAU + k * PI * 0.5
		var base: Vector2 = palm + Vector2((-9 + k * 6) * face, 6)
		var step := sin(ph) * (0.0 if wind else 6.0)
		var lift := maxf(0.0, cos(ph)) * (0.0 if wind else 5.0)
		var knee := base + Vector2((4 + step * 0.5) * face, 6 - lift - spread * 3.0)
		var tip := base + Vector2((2 + step + spread * (k - 1.5) * 4.0) * face, 15 - crouch * 0.5)
		draw_polyline(PackedVector2Array([base, knee, tip]), line, 7.0, true)
		draw_polyline(PackedVector2Array([base, knee, tip]), col, 4.0, true)
	# ладонь сбоку
	Art.blob(self, palm, 17.0, 9.0, col, 3.0, sd, 0.0)
	# большой палец вперёд
	var th := palm + Vector2(15 * face, 2)
	draw_line(palm + Vector2(10 * face, 3), th + Vector2(6 * face, 4), line, 7.0)
	draw_line(palm + Vector2(10 * face, 3), th + Vector2(6 * face, 4), col, 4.0)
	# запястье с манжетой
	var wr := palm + Vector2(-18 * face, -2)
	Art.blob(self, wr, 6.0, 7.5, Color("3a3a44"), 2.5, sd + 2, 0.0)
	draw_line(wr + Vector2(-2 * face, -6), wr + Vector2(-2 * face, 6), Color("e9e9ef"), 2.0)
	if e.carries_chest:
		var cp := palm + Vector2(0, -13)
		var pts := Art.wobbly_rect(Rect2(cp - Vector2(12, 8), Vector2(24, 15)), sd, 1.0)
		draw_colored_polygon(pts, Color("f6c94a"))
		Art.outline(self, pts, INK, 2.5)
		for k in 3:
			draw_circle(cp + Vector2(-6 + k * 6, -2), 1.6, Color("fff2b0"))
	var hpw := 36.0
	draw_rect(Rect2(p + Vector2(-hpw * 0.5, 16), Vector2(hpw, 4)), Color(0, 0, 0, 0.15))
	draw_rect(Rect2(p + Vector2(-hpw * 0.5, 16), Vector2(hpw * clampf(e.hp / e.max_hp, 0, 1), 4)), Color("c9a27a"))


func _draw_box(e: Enemy, sd: int) -> void:
	var p := e.pos
	var hop := absf(sin(e.phase)) * 6.0
	var c := p - Vector2(0, hop)
	for k in 2:
		var lp := c + Vector2(-7 + k * 14, 12 + hop * 0.5)
		draw_line(c + Vector2(-7 + k * 14, 8), lp + Vector2(sin(e.phase + k * PI) * 4.0, 4), INK, 2.5)
	var body := Art.wobbly_rect(Rect2(c - Vector2(16, 8), Vector2(32, 18)), sd, 1.0)
	draw_colored_polygon(body, _tint(Color("c98fb0"), e))
	Art.outline(self, body, INK, 3.0)
	var lid_a := -0.4 - absf(sin(e.phase * 0.5)) * 0.5
	var lid := Art.rot_rect(c + Vector2(-2, -12), 34, 8, lid_a)
	draw_colored_polygon(lid, _tint(Color("b07898"), e))
	Art.outline(self, lid, INK, 2.5)
	for k in 3:
		draw_circle(c + Vector2(-8 + k * 8, 1), 2.6, Color("fff2b0"))
	Art.blob(self, c + Vector2(0, -6), 4.0, 2.0, Color("f3a7b5"), 1.0, sd)
	var hpw := 36.0
	draw_rect(Rect2(p + Vector2(-hpw * 0.5, 20), Vector2(hpw * clampf(e.hp / e.max_hp, 0, 1), 4)), Color("b07898"))


## Робот-пылесос: круглый, жирный, с бампером, щётками и красным глазом.
func _draw_boss(e: Enemy, sd: int) -> void:
	var p := e.pos
	var r := e.radius
	var dir := e.move_dir
	if e.state == 2 or e.state == 3:
		dir = e.dash_dir
	if e.state == 2:
		var k := 1.0 - clampf(e.state_t / 0.9, 0.0, 1.0)
		var b := p + e.dash_dir * 13.0 * M
		var nrm := Vector2(-e.dash_dir.y, e.dash_dir.x) * 1.4 * M
		draw_colored_polygon(PackedVector2Array([p + nrm, b + nrm, b - nrm, p - nrm]), Color(0.85, 0.2, 0.15, 0.12 + 0.2 * k))
		draw_dashed_line(p + nrm, b + nrm, Color(0.8, 0.2, 0.15, 0.7), 2.0, 12.0)
		draw_dashed_line(p - nrm, b - nrm, Color(0.8, 0.2, 0.15, 0.7), 2.0, 12.0)
	if e.state == 1:
		for k in 6:
			var a := -_time * 4.0 + TAU * k / 6.0
			var rr := 7.0 * M * fmod(1.0 - _time * 0.8 + k * 0.17, 1.0)
			draw_arc(p, rr, a, a + 0.9, 10, Color(0.45, 0.5, 0.6, 0.45), 2.5, true)
	if e.state == 4:
		Art.fill_blob(self, p, r + 16, r + 12, Color(0.6, 0.58, 0.55, 0.3))
	Art.fill_blob(self, p + Vector2(8, 12), r + 4, r * 0.75, Color(0, 0, 0, 0.18))
	var wob := sin(e.phase * 30.0) * 1.5 if e.state == 3 else 0.0
	var c := p + Vector2(wob, 0)
	Art.blob(self, c, r, r * 0.92, _tint(Color("b9c0c9"), e), 4.0, sd, 0.0)
	Art.blob(self, c + Vector2(0, -4), r * 0.7, r * 0.6, _tint(Color("d6dbe1"), e), 3.0, sd + 1, 0.0)
	draw_arc(c, r - 4, dir.angle() - 1.1, dir.angle() + 1.1, 16, Color("5f6670"), 7.0, true)
	for k in 2:
		var bp := c + dir.rotated(0.9 * (1 if k == 0 else -1)) * (r - 2)
		var a := _time * 18.0 * (1 if k == 0 else -1)
		for j in 3:
			draw_line(bp, bp + Vector2(cos(a + j * TAU / 3.0), sin(a + j * TAU / 3.0)) * 12.0, INK, 2.0)
	var eye := c + dir * (r * 0.35) + Vector2(0, -6)
	var angry := e.state != 0
	draw_circle(eye, 7.0, Color("e0614a") if angry else Color("8fd06a"))
	draw_arc(eye, 7.0, 0, TAU, 12, INK, 2.0)
	if e.stun > 0.0:
		for k in 3:
			var a := _time * 6.0 + k * TAU / 3.0
			Art.blob(self, c + Vector2(cos(a) * 30.0, -r - 10 + sin(a) * 6.0), 4.0, 3.0, Color("f6cd56"), 1.5, k, a)


func _draw_boss_bar() -> void:
	var b: Enemy = game.boss
	if b == null or b.dead:
		return
	var r := Rect2(game.FIELD.position.x + 270, 52, 700, 20)
	draw_rect(r.grow(3), Color(1, 0.98, 0.93, 0.9))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(b.hp / b.max_hp, 0, 1), r.size.y)), Color("c25b4a"))
	draw_rect(r, INK, false, 2.5)
	Art.text_c(self, font, Vector2(r.get_center().x, r.position.y - 6), "Робот-пылесос", 18, INK, Color(1, 0.98, 0.93, 0.9), 5)


# ---------- герой ----------

func _draw_aura() -> void:
	var h: Hero = game.hero
	var lvl := h.lvl_of("bell")
	if lvl <= 0:
		return
	var r := (1.6 + 0.25 * lvl) * M * (1.4 if h.has_mod("bell_wide") else 1.0)
	var beat := fmod(_time * 2.0, 1.0)
	Art.fill_blob(self, h.pos, r, r, Color(0.98, 0.85, 0.35, 0.10))
	draw_arc(h.pos, r, 0, TAU, 56, Color(0.9, 0.65, 0.15, 0.75), 3.5, true)
	draw_arc(h.pos, r * (0.3 + 0.7 * beat), 0, TAU, 48, Color(0.95, 0.75, 0.2, 0.6 * (1.0 - beat)), 4.0, true)
	for k in 3:
		var a := _time * 1.5 + k * TAU / 3.0
		Icons._glyph(self, "bell", h.pos + Vector2(cos(a), sin(a)) * r, 0.45, 0.9)

func _draw_orbit(fr: int) -> void:
	var h: Hero = game.hero
	var cols := [Color("e98a7a"), Color("8fb6e8"), Color("f2c14e"), Color("b9d48f"), Color("cdb3dc")]
	var pts := h.orbit_points()
	if pts.size() > 0:
		draw_arc(h.pos, h.orbit_radius(), 0, TAU, 48, Color(0.5, 0.45, 0.6, 0.25), 2.0, true)
	for i in pts.size():
		var c: Color = cols[i % cols.size()]
		var tang := (pts[i] - h.pos).rotated(-PI * 0.5).normalized()
		for k in 3:
			draw_circle(pts[i] + tang * (8.0 + k * 7.0), 7.0 - k * 2.0, Color(c, 0.35 - k * 0.1))
		if h.has_mod("orbit_fire"):
			Art.fill_blob(self, pts[i], 18, 18, Color(1.0, 0.55, 0.2, 0.4))
		Art.blob(self, pts[i], 11.0, 11.0, c, 3.0, i + fr)
		draw_circle(pts[i] + Vector2(-3, -3), 3.0, Color(1, 1, 1, 0.7))

func _draw_hero(fr: int) -> void:
	var h: Hero = game.hero
	var p := h.pos
	var flying: bool = game.phase == "intro" or game.over != ""
	var face := 1.0 if h.heading.x >= 0.0 else -1.0
	if h.peck_t > 0.0:
		face = 1.0 if h.peck_dir.x >= 0.0 else -1.0
	var moving := h.vel.length() > 10.0 or flying
	var hop := absf(sin(h.bob)) * 6.0 if moving and not flying else 0.0
	var puff := 1.0 + 0.12 * clampf((h.greed - 0.6) / 0.4, 0.0, 1.0)
	var sd := 991 + fr
	var lunge := Vector2.ZERO
	if h.peck_t > 0.0:
		lunge = h.peck_dir * 10.0 * sin((1.0 - h.peck_t / 0.18) * PI)
	var c := p - Vector2(0, hop)
	var squash := 1.08 if hop < 1.0 and moving and not flying else 1.0
	if not flying:
		Art.fill_blob(self, p + Vector2(0, 18), 19, 6, Color(0, 0, 0, 0.14))
	if h.trapped > 0.0:
		_draw_trap(p + Vector2(0, 12), 1.0 - h.trapped)
	var bd: Dictionary = Parrots.bird(h.bird)
	var col: Dictionary = bd["col"]
	var hs: float = HERO_SCALE * float(bd["scale"])
	draw_set_transform(p * (1.0 - hs), 0.0, Vector2(hs, hs))
	Art.fill_blob(self, c + Vector2(2 * face, -6), 28.0 * puff, 27.0 * puff, Color(1, 0.99, 0.94, 0.9), sd)
	if h.shield_hits > 0:
		draw_arc(c + Vector2(0, -4), 29.0, 0, TAU, 24, Color(0.95, 0.85, 0.2, 0.8), 3.0, true)
	var hurt := h.hurt > 0.0
	var green: Color = Color(col["body"]).lerp(Color.WHITE, 0.5) if hurt else col["body"]
	# хвост: два длинных пера
	var sway := sin(_time * 5.0) * 0.12
	for k in 2:
		var root := c + Vector2(-face * 10, 8)
		var dir := Vector2(-face, 0.55 + k * 0.25).normalized().rotated(sway * face)
		var tip := root + dir * (26.0 - k * 4.0)
		var nrm := Vector2(-dir.y, dir.x) * 4.0
		var tail := PackedVector2Array([root + nrm, tip, root - nrm])
		draw_colored_polygon(tail, col["tail1"] if k == 0 else col["tail2"])
		Art.outline(self, tail, INK, 3.0)
	# лапки
	if not flying:
		for k in 2:
			var fp := c + Vector2(-3 + k * 8, 17)
			draw_line(fp, fp + Vector2(face * 4, 2), col["feet"], 3.0)
			draw_line(fp, fp + Vector2(-face * 2, 3), col["feet"], 3.0)
	# тельце-груша и светлое брюшко
	Art.blob(self, c + Vector2(-2 * face, 5), 16.0 * puff * squash, 14.0 * puff / squash, green, 4.0, sd)
	Art.fill_blob(self, c + Vector2(3 * face, 9), 8.0 * puff, 7.0 * puff, col["belly"], sd + 9)
	if col.has("spots"):
		# какапо: моховые пятнышки
		for k in 6:
			Art.fill_blob(self, c + Vector2(-10 + (k % 3) * 7, -2 + int(k / 3) * 8) * Vector2(face, 1), 2.2, 1.6, col["spots"], k)
	# крыло с волнистыми полосками; в полёте — машет
	var flap := sin(_time * 22.0) if flying else (sin(h.bob * 2.0) * 0.4 if h.speed_t > 0.0 else 0.0)
	var wing_c := c + Vector2(-6 * face, 3 - flap * 6.0)
	var wing_rot := (-0.35 - flap * 0.8) * face
	Art.blob(self, wing_c, 11.0, 7.5 + absf(flap) * 3.0, col["wing"], 3.0, sd + 2, wing_rot)
	for k in 3:
		draw_arc(wing_c + Vector2(-4 + k * 4, -1 + k * 1.5).rotated(wing_rot), 3.5, 0.3, PI - 0.3, 6, col["bars"], 1.6)
	# большая голова
	var head := c + Vector2(8 * face, -12) + lunge
	var tilt := sin(_time * 1.3) * 0.08
	Art.blob(self, head, 12.5, 12.0, col["head"], 4.0, sd + 4, tilt)
	if Color(col["stripes"]).a > 0.0 and not col.has("owl"):
		for k in 3:
			var hx := head + Vector2(-face * (5 + k * 2.8), -6 + k * 3)
			draw_arc(hx, 3.4, PI * 1.05, PI * 1.95, 6, col["stripes"], 1.5)
	if col.has("face"):
		# жако: светлая маска вокруг глаза
		Art.fill_blob(self, head + Vector2(5 * face, -1), 6.5, 5.5, col["face"], 3)
	if col.has("owl"):
		# какапо: совиный лицевой диск и усики у клюва
		Art.fill_blob(self, head + Vector2(5 * face, 1), 8.0, 7.5, Color(col["head"]).lightened(0.25), 4)
		for k in 3:
			draw_line(head + Vector2(9 * face, 3 + k * 2), head + Vector2(16 * face, 1 + k * 4), Color(col["stripes"], 0.8), 1.0)
	# хохолок: прижат — спокоен, дыбом — стресс, распушён — жадность
	var crest_a := -2.4 if face > 0 else -0.74
	var lift := 1.0 if h.stress > 0.6 or flying else 0.0
	var greedy := h.greed > 0.65
	if col["crest"] == "small":
		for k in 3:
			var base: Vector2 = head + Vector2(-face * 3 + k * face * 3, -11)
			var a := lerpf(crest_a, -PI * 0.5, lift) + (k - 1) * (0.35 if greedy else 0.18)
			var tip := base + Vector2(cos(a), sin(a)) * (10.0 if greedy else 8.0)
			draw_line(base, tip, INK, 3.0, true)
			draw_line(base, tip, col["head"], 1.2, true)
	elif col["crest"] == "tall":
		# какаду: высокий жёлтый хохол, дыбом при стрессе и на низком здоровье
		var up := 1.0 if h.stress > 0.5 or flying or h.hp_frac() < 0.4 else 0.25
		for k in 5:
			var base: Vector2 = head + Vector2(-face * (2 + k * 1.5), -10)
			var a := lerpf(crest_a - 0.2, -PI * 0.5 - face * 0.25, up) + (k - 2) * 0.13 * face
			var tip := base + Vector2(cos(a), sin(a)) * (14.0 + 6.0 * up - absf(k - 2) * 1.5)
			var nrm := (tip - base).normalized().orthogonal() * 2.2
			var fea := PackedVector2Array([base + nrm, tip, base - nrm])
			draw_colored_polygon(fea, Color("f2cf3a"))
			Art.outline(self, fea, INK, 1.6)
	# глаз: белок, зрачок, блик, моргание раз в несколько секунд
	var eye := head + Vector2(4 * face, -2)
	var blink := fmod(_time + float(h.level) * 0.37, 3.3) < 0.12
	if h.stun > 0.0 or h.trapped > 0.0 or h.held > 0.0:
		draw_line(eye + Vector2(-3, -3), eye + Vector2(3, 3), INK, 2.2)
		draw_line(eye + Vector2(-3, 3), eye + Vector2(3, -3), INK, 2.2)
	elif blink:
		draw_line(eye + Vector2(-3.5, 0), eye + Vector2(3.5, 0), INK, 2.2)
	else:
		var wide := 1.25 if game.over == "hero_dead" or h.mode == Hero.Mode.PANIC else 1.0
		draw_circle(eye, 4.4 * wide, Color.WHITE)
		draw_arc(eye, 4.4 * wide, 0, TAU, 12, INK, 1.5)
		draw_circle(eye + Vector2(face * 0.8, 0.3), 2.9, INK)
		draw_circle(eye + Vector2(face * 0.8 - 1.0, -1.0), 1.0, Color.WHITE)
	# восковица, клюв крючком, фиолетовая щёчка и пятнышки на горле
	var bk := head + Vector2(10 * face, 1)
	draw_circle(bk + Vector2(-1 * face, -3), 2.6, col["cere"])
	var open := 3.0 if h.peck_t > 0.0 or h.eat_t > 0.0 else 0.0
	var beak := PackedVector2Array([bk + Vector2(-1 * face, -1), bk + Vector2(5 * face, 1), bk + Vector2(4 * face, 6 + open), bk + Vector2(-1 * face, 5 + open)])
	draw_colored_polygon(beak, col["beak"])
	Art.outline(self, beak, INK, 2.0)
	if Color(col["cheek"]).a > 0.0:
		Art.fill_blob(self, head + Vector2(3 * face, 7), 3.2, 2.4, col["cheek"])
		for k in 3:
			draw_circle(head + Vector2((-1 + k * 3) * face, 12), 1.1, INK)
	if greedy:
		Art.fill_blob(self, head + Vector2(-2 * face, 5), 3.0, 2.0, Color(1.0, 0.55, 0.6, 0.6))
	if h.stun > 0.0 or h.held > 0.0 or h.trapped > 0.0:
		for k in 3:
			var a := _time * 8.0 + k * TAU / 3.0
			var sp := head + Vector2(0, -20) + Vector2(cos(a) * 14.0, sin(a) * 5.0)
			Art.blob(self, sp, 3.5, 2.5, Color("f6cd56"), 1.5, k, a)
	if h.mode == Hero.Mode.PANIC or game.over == "hero_dead":
		for k in 3:
			var a := _time * 4.0 + k * 2.1
			var fp := c + Vector2(cos(a) * 28.0, -6 + sin(a * 1.3) * 12.0)
			Art.blob(self, fp, 5.0, 2.0, col["body"], 1.5, k + fr, a)
	draw_set_transform(Vector2.ZERO)
	if h.speed_t > 0.0:
		for k in 3:
			draw_line(p + Vector2(-face * (26 + k * 6), -6 + k * 8), p + Vector2(-face * (40 + k * 6), -6 + k * 8), Color(INK, 0.4), 2.0)
	if game.over != "" or game.phase == "intro":
		return
	var hw := 46.0
	var hb := Rect2(p + Vector2(-hw * 0.5, -64), Vector2(hw, 6))
	draw_rect(hb, Color(0, 0, 0, 0.18))
	draw_rect(Rect2(hb.position, Vector2(hw * h.hp_frac(), 6)), Color("d95c4a") if h.hp_frac() < 0.2 else Color("6fae5c"))
	draw_rect(hb, INK, false, 1.5)


func _draw_trap(p: Vector2, k: float) -> void:
	var close := clampf(k * 5.0, 0.0, 1.0)
	for s in [-1.0, 1.0]:
		var a0 := PI if s < 0 else 0.0
		draw_arc(p + Vector2(0, s * (10.0 - 8.0 * close)), 20.0, a0, a0 + PI, 12, Color("8a8f96"), 4.0, true)
		for t in 5:
			var x := -16.0 + t * 8.0
			draw_line(p + Vector2(x, s * (10.0 - 8.0 * close)), p + Vector2(x + 4, s * (4.0 - 8.0 * close)), Color("5f6670"), 2.0)


func _draw_intent() -> void:
	var h: Hero = game.hero
	if not h.valid(h.target) or not [Hero.Mode.GOAL, Hero.Mode.HUNT, Hero.Mode.EVENT].has(h.mode):
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
			s = o.radius + 14.0
		elif o.has("delay"):
			s = float(o["r"]) * 0.75
		elif o.has("r"):
			s = float(o["r"]) * 0.6
		elif int(o["id"]) == int(h.horde_obj["id"]):
			s = 48.0
		elif o.has("life") and not o.has("big"):
			s = 26.0
		_brackets(p, s, Color(C_FOCUS, 0.55))


func _brackets(p: Vector2, s: float, col: Color) -> void:
	var l := maxf(6.0, s * 0.35)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var c := p + Vector2(sx * s, sy * s)
			draw_line(c, c - Vector2(sx * l, 0), col, 1.6, true)
			draw_line(c, c - Vector2(0, sy * l), col, 1.6, true)


func _draw_overhead() -> void:
	var h: Hero = game.hero
	if not game.levelup.is_empty() or game.over != "" or game.phase == "intro":
		return
	var label: String = Hero.MODE_NAMES[h.mode]
	# фарм — обычное состояние, его не подписываем, чтобы не шуметь
	if h.mode == Hero.Mode.FARM:
		label = ""
	if h.dodging:
		label = "уворот!"
	elif h.trapped > 0.0:
		label = "в капкане"
	elif h.opening > 0.0:
		label = "открываю"
	elif h.held > 0.0:
		label = "схвачен"
	elif h.stun > 0.0:
		label = "оглушён"
	elif h.eat_t > 0.0:
		label = "ням!"
	if label == "":
		return
	var size := 15
	var w := Art.text_w(font, label, size) + 16.0
	var c := h.pos + Vector2(0, -86)
	var r := Rect2(c - Vector2(w * 0.5, 13), Vector2(w, 22))
	var fill := Color("fff8ea")
	if h.mode == Hero.Mode.PANIC or h.dodging:
		fill = Color("ffd9cf")
	elif [Hero.Mode.GOAL, Hero.Mode.HUNT, Hero.Mode.EVENT].has(h.mode):
		fill = Color("ffefc2")
	Art.card(self, r, fill, Art.frame() + 3, INK, 2.0)
	draw_line(c + Vector2(-4, 9), c + Vector2(0, 16), INK, 2.0)
	draw_line(c + Vector2(4, 9), c + Vector2(0, 16), INK, 2.0)
	draw_string(font, Vector2(r.position.x + 8, c.y + 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, size, INK)


# ---------- меню над колоском ----------

func _draw_menu(fr: int) -> void:
	if not game.aim.is_empty():
		var g: Dictionary = game.aim["gem"]
		var a: Vector2 = g["pos"]
		var b: Vector2 = game.paw["pos"]
		var d := (b - a).normalized()
		draw_dashed_line(a, a + d * 220.0, Color(0.42, 0.31, 0.7, 0.9), 3.0, 10.0)
		draw_polyline(PackedVector2Array([a + d * 220.0 + d.rotated(2.5) * 16.0, a + d * 220.0, a + d * 220.0 + d.rotated(-2.5) * 16.0]), Color(0.42, 0.31, 0.7, 0.9), 3.0)
		return
	if game.menu.is_empty():
		return
	var g: Dictionary = game.menu["gem"]
	var c: Vector2 = g["pos"]
	var k := clampf(float(game.menu["t"]) / 0.12, 0.0, 1.0)
	draw_arc(c, game.MENU_R, 0, TAU, 32, Color(0.42, 0.31, 0.7, 0.4 * k), 2.0, true)
	var pp: Vector2 = game.paw["pos"]
	for i in game.MENU_OPTS.size():
		var key: String = game.MENU_OPTS[i]
		var bp: Vector2 = c.lerp(game.menu_button_pos(i), k)
		var hover := pp.distance_to(bp) < 26.0
		Icons.draw(self, key, bp, 46.0 if hover else 40.0, k)
		if hover:
			var nm: String = game.MENU_NAMES[key] + " — " + game.MENU_DESC[key]
			Art.text_c(self, font, c + Vector2(0, game.MENU_R + 46), nm, 17, INK, Color(1, 0.98, 0.93, 0.95), 6)


# ---------- выбор перка кругом вокруг попугая ----------

func _draw_levelup(fr: int) -> void:
	var lu: Dictionary = game.levelup
	if lu.is_empty():
		return
	var h: Hero = game.hero
	var t: float = lu["t"]
	var appear := clampf(float(lu.get("appear", 0.0)) / 0.3, 0.0, 1.0)
	var blocking: bool = game.levelup_block_open()
	var fade := 1.0 if blocking else 1.0 - clampf((t - (game.LU_END - 0.5)) / 0.5, 0.0, 1.0)
	var cards: Array = lu["cards"]
	var chosen: int = lu["chosen"]
	var blocked: int = lu["blocked"]
	var picked: bool = not blocking and t >= game.LU_PICK
	var n := cards.size()
	# затемнение: игра стоит
	draw_rect(game.FIELD, Color(0.15, 0.1, 0.05, 0.25 * fade * appear))
	_draw_hero(fr)
	var center: Vector2 = game.levelup_center()
	var ring := center.distance_to(game.levelup_card_pos(0))
	draw_arc(center, ring, 0, TAU, 64, Color(0.95, 0.75, 0.25, 0.6 * fade), 4.0, true)
	var hover := -1
	if not blocking and not picked:
		# попугай колеблется между оставшимися
		var rest: Array = []
		for i in n:
			if i != blocked:
				rest.append(i)
		hover = rest[int(t * 7.0) % rest.size()]
	elif picked:
		hover = chosen
	var pp: Vector2 = game.paw["pos"]
	var tip := -1
	for i in n:
		var cp: Vector2 = game.levelup_card_pos(i)
		var c: Dictionary = cards[i]
		var k: String = c["key"]
		var al := fade * appear
		if picked and i != chosen:
			al *= 0.3
		var size := 62.0
		var under := pp.distance_to(cp) < 34.0
		if under:
			tip = i
		if blocking:
			size = 66.0 + (8.0 if under else 3.0 * sin(_time * 6.0 + i))
			if under:
				Art.fill_blob(self, cp, size * 0.85, size * 0.85, Color(1.0, 0.35, 0.25, 0.35))
		elif i == hover and i != blocked:
			size = 74.0 + (5.0 * sin(t * 18.0) if not picked else 10.0)
			draw_line(center, cp, Color(0.95, 0.7, 0.2, 0.8 * al), 3.0, true)
			Art.fill_blob(self, cp, size * 0.8, size * 0.8, Color(1.0, 0.85, 0.3, 0.4 * al))
		Icons.draw(self, k, cp, size, al)
		if i == blocked:
			draw_line(cp + Vector2(-28, -28), cp + Vector2(28, 28), Color(0.8, 0.15, 0.1, al), 7.0, true)
			draw_line(cp + Vector2(-28, 28), cp + Vector2(28, -28), Color(0.8, 0.15, 0.1, al), 7.0, true)
		if picked and i == chosen:
			Art.text_c(self, font, cp + Vector2(0, -size * 0.5 - 10), "ВЫБРАЛ", 18, Color(0.75, 0.45, 0.05, al), Color(1, 0.98, 0.9, al), 6)
	if blocking:
		var pulse := 0.6 + 0.4 * sin(_time * 8.0)
		var big: bool = lu["tut"]
		Art.text_c(self, font, center + Vector2(0, -ring - 70), "Запретите одно умение", 28 if big else 22, Color(0.75, 0.15, 0.1), Color(1, 0.98, 0.9, pulse), 8)
		Art.text_c(self, font, center + Vector2(0, -ring - 44), "попугай выберет из двух оставшихся", 17, INK, Color(1, 0.98, 0.9, 0.95), 6)
	elif not picked:
		Art.text_c(self, font, center + Vector2(0, -ring - 50), "Кеша выбирает…", 20, INK, Color(1, 0.98, 0.93, 0.95), 6)
	if tip >= 0:
		_card_tip(cards[tip], lu["scores"][tip], game.levelup_card_pos(tip))

func _draw_shadow(m: Dictionary) -> void:
	var p: Vector2 = m["pos"]
	var r: float = m["r"]
	if m.has("basket"):
		_draw_basket(m)
		return
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
	if m["landed"] or m.has("basket") or m.has("fake"):
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


func _draw_missile(s: Dictionary, fr: int) -> void:
	var p: Vector2 = s["pos"]
	var v: Vector2 = s["vel"]
	for k in 4:
		draw_circle(p - v.normalized() * (10.0 + k * 9.0), 5.0 - k, Color(0.96, 0.78, 0.3, 0.5 - k * 0.1))
	var a := _time * 14.0
	Art.blob(self, p, 7.0, 13.0, Color("f5c84c"), 2.5, fr, a, Color("6a4fb3"))


## Снаряды попугая: у каждого умения свой силуэт, чтобы было видно, что чем стреляет.
func _draw_shot(s: Dictionary) -> void:
	var p: Vector2 = s["pos"]
	var d: Vector2 = Vector2(s["vel"]).normalized()
	match String(s.get("kind", "")):
		"seed":
			Art.blob(self, p, 3.5, 6.0, Color("3a2e28"), 1.2, 3, d.angle() + PI * 0.5)
			draw_line(p - d * 3.0, p + d * 3.0, Color("e8dcc0"), 1.2, true)
		"boomer":
			var a := _time * 18.0
			var r: float = s.get("r", 14.0)
			for k in 2:
				var dd := Vector2(cos(a + k * PI), sin(a + k * PI))
				Art.blob(self, p + dd * r * 0.45, r * 0.25, r * 0.6, Color("8fd46a"), 2.0, k, a + k * PI)
		"crest":
			Art.blob(self, p, 4.0, 11.0, Color("f7e27a"), 2.0, 5, d.angle() + PI * 0.5)
		"shard":
			draw_colored_polygon(PackedVector2Array([p + d * 6.0, p + d.orthogonal() * 3.0, p - d * 4.0, p - d.orthogonal() * 3.0]), Color("fff6e0"))
		"sock":
			Art.blob(self, p, 7.0, 10.0, Color("e9e4f0"), 2.0, 7, d.angle())
		_:
			draw_line(p - d * 26.0, p - d * 8.0, Color(1, 1, 1, 0.5), 5.0, true)
			Art.blob(self, p, 5.5, 13.0, Color("bfe3f5") if s["ice"] else Color("8fd46a"), 2.5, int(p.x) % 7, d.angle() + PI * 0.5)
			draw_line(p - d * 12.0, p + d * 12.0, Color("2f5e33"), 1.5, true)


## Лазерная указка: красный луч с точкой на цели.
func _draw_laser() -> void:
	var h: Hero = game.hero
	if h == null or h.laser_pts.is_empty() or not h.skills.has("laser"):
		return
	var from := h.pos + Vector2(0, -14)
	for q in h.laser_pts:
		var to: Vector2 = q
		draw_line(from, to, Color(1.0, 0.2, 0.2, 0.35), 6.0, true)
		draw_line(from, to, Color(1.0, 0.35, 0.3, 0.95), 2.0, true)
		draw_circle(to, 5.0 + sin(_time * 30.0) * 1.0, Color(1.0, 0.15, 0.1, 0.9))
		from = to


func _draw_mine(m: Dictionary) -> void:
	var p: Vector2 = m["pos"]
	var armed: bool = float(m["t"]) >= 0.5
	Art.blob(self, p, 9.0, 6.5, Color("fff6e0"), 2.0, int(m["id"]), 0.0)
	draw_polyline(PackedVector2Array([p + Vector2(-8, -1), p + Vector2(-4, -4), p + Vector2(0, 0), p + Vector2(4, -4), p + Vector2(8, -1)]), Art.INK, 1.5)
	if armed:
		draw_circle(p + Vector2(0, -8), 2.0, Color(1.0, 0.4, 0.2, 0.6 + 0.4 * sin(_time * 8.0)))


func _draw_tornado(t: Dictionary) -> void:
	var p: Vector2 = t["pos"]
	var k := clampf(float(t["t"]) / 0.3, 0.0, 1.0) * clampf(float(t["life"]) - float(t["t"]), 0.0, 1.0)
	Art.fill_blob(self, p + Vector2(0, 8), 26.0, 9.0, Color(0, 0, 0, 0.1 * k))
	for i in 5:
		var y := -i * 10.0
		var w := 10.0 + i * 6.0
		var a := _time * 14.0 + i
		draw_arc(p + Vector2(sin(a) * 4.0, y), w, a, a + PI * 1.4, 14, Color(0.6, 0.75, 0.85, 0.75 * k), 3.0, true)


## Пыль замедляет, искры жгут: обе зоны видны сразу, чтобы их было легко обойти.
func _draw_zone(z: Dictionary, fr: int) -> void:
	var p: Vector2 = z["pos"]
	var r: float = z["r"]
	var k := clampf(float(z["t"]) / 0.3, 0.0, 1.0) * (1.0 - clampf((float(z["t"]) - float(z["life"]) + 0.6) / 0.6, 0.0, 1.0))
	if z["kind"] == "fluff":
		Art.fill_blob(self, p, r, r * 0.8, Color(0.97, 0.94, 0.98, 0.55 * k), int(z["id"]))
		for i in 7:
			var a := float(z["id"]) + i * 0.9 + _time * 0.4
			var q := p + Vector2(cos(a), sin(a)) * r * 0.6
			Art.blob(self, q, 3.0, 7.0, Color(1, 1, 1, 0.9 * k), 1.0, i, a)
		return
	if z["kind"] == "dust":
		Art.fill_blob(self, p, r, r * 0.8, Color(0.62, 0.56, 0.5, 0.28 * k), int(z["id"]))
		for i in 4:
			var a := float(z["id"]) + i * 1.7 + _time * 0.6
			Art.fill_blob(self, p + Vector2(cos(a), sin(a)) * r * 0.45, r * 0.32, r * 0.26, Color(0.7, 0.65, 0.6, 0.3 * k), i)
	else:
		Art.fill_blob(self, p, r, r * 0.8, Color(1.0, 0.75, 0.2, 0.18 * k), int(z["id"]))
		for i in 5:
			var a := float(z["id"]) * 3.1 + i * 1.3
			var q := p + Vector2(cos(a), sin(a)) * r * 0.6 * absf(sin(_time * 7.0 + i))
			draw_line(q, q + Vector2(cos(a * 2.0), sin(a * 2.0)) * 8.0, Color(1.0, 0.9, 0.3, k), 2.5, true)


func _draw_fx(f: Dictionary, fr: int) -> void:
	var t: float = f["t"]
	var k: float = t / float(f["dur"])
	var p: Vector2 = f["pos"]
	match f["kind"]:
		"ring":
			var col: Color = f["color"]
			col.a *= 1.0 - k
			for j in 3:
				var kk := clampf(k - j * 0.12, 0.0, 1.0)
				draw_arc(p, float(f["r"]) * (0.3 + 0.7 * kk), 0, TAU, 56, Color(col, col.a * (1.0 - j * 0.3)), 5.0 - j, true)
		"fire":
			var r: float = f["r"]
			Art.fill_blob(self, p, r * (0.3 + 0.7 * k), r * (0.3 + 0.7 * k), Color(1.0, 0.5, 0.15, 0.4 * (1.0 - k)))
			for i in 10:
				var a := TAU * i / 10.0
				Art.blob(self, p + Vector2(cos(a), sin(a)) * r * (0.3 + 0.7 * k), 10, 14, Color(1.0, 0.55 + 0.2 * (i % 2), 0.2, 1.0 - k), 1.5, i + fr, a)
		"dust":
			var r: float = f["r"]
			for i in 8:
				var a := TAU * i / 8.0
				Art.blob(self, p + Vector2(cos(a), sin(a)) * r * (0.6 + 0.5 * k), 12 * (1.0 - k) + 4, 9 * (1.0 - k) + 3, Color(0.9, 0.85, 0.78, 1.0 - k), 1.5, i + fr, 0.0, Color(0.55, 0.47, 0.4, 1.0 - k))
		"poof":
			var col: Color = f.get("col", Color.WHITE)
			var rr: float = f.get("r", 12.0)
			for i in 6:
				var a := TAU * i / 6.0 + float(p.x)
				var q := p + Vector2(cos(a), sin(a)) * rr * (0.4 + 1.3 * k)
				draw_circle(q, (rr * 0.45) * (1.0 - k) + 1.0, Color(col, 1.0 - k))
				draw_arc(q, (rr * 0.45) * (1.0 - k) + 1.0, 0, TAU, 8, Color(INK, 0.5 * (1.0 - k)), 1.2)
		"beam":
			var to: Vector2 = f["to"]
			draw_line(p, to, Color(1.0, 0.85, 0.3, 0.45 * (1.0 - k)), 22.0, true)
			draw_line(p, to, Color(1.0, 0.95, 0.55, 0.8 * (1.0 - k)), 10.0, true)
			draw_line(p, to, Color(1.0, 1.0, 0.95, 1.0 - k), 4.0, true)
			Icons._star(self, to, 12.0 * (1.0 - k) + 4.0, Color("fff3a0"), 1.0 - k)
			Icons._star(self, p, 9.0 * (1.0 - k) + 3.0, Color("fff3a0"), 1.0 - k)
		"burnline":
			var to: Vector2 = f["to"]
			for i in 8:
				var q := p.lerp(to, (float(i) + 0.5) / 8.0)
				Art.blob(self, q + Vector2(0, -sin(_time * 10.0 + i) * 3.0), 7, 10, Color(1.0, 0.55, 0.2, 0.7 * (1.0 - k)), 0.0, i + fr)
		"peck":
			var to: Vector2 = f["to"]
			var d := (to - p).normalized()
			var hit := p.lerp(to, 0.7)
			draw_arc(hit, 14.0 * (0.6 + k), d.angle() - 1.0, d.angle() + 1.0, 8, Color(INK, 1.0 - k), 3.0, true)
			for i in 3:
				var a := d.angle() + (i - 1) * 0.7
				draw_line(to + Vector2(cos(a), sin(a)) * 8.0, to + Vector2(cos(a), sin(a)) * (14.0 + 8.0 * k), Color(0.95, 0.75, 0.3, 1.0 - k), 2.5)
		"zap":
			var pts: PackedVector2Array = f["pts"]
			var jag := PackedVector2Array()
			for i in pts.size() - 1:
				var a0: Vector2 = pts[i]
				var a1: Vector2 = pts[i + 1]
				var nrm := (a1 - a0).normalized().orthogonal()
				for j in 4:
					var q := a0.lerp(a1, float(j) / 4.0)
					jag.append(q + nrm * (0.0 if j == 0 else randf_range(-7.0, 7.0)))
			if pts.size() > 0:
				jag.append(pts[pts.size() - 1])
			if jag.size() > 1:
				draw_polyline(jag, Color(0.55, 0.75, 1.0, 0.5 * (1.0 - k)), 7.0, true)
				draw_polyline(jag, Color(1.0, 0.97, 0.6, 1.0 - k), 2.5, true)
			for q in pts:
				draw_circle(q, 5.0 * (1.0 - k) + 1.0, Color(1.0, 0.95, 0.5, 1.0 - k))
		"jingle":
			for i in 3:
				draw_arc(p, 14.0 + i * 12.0 + k * 20.0, 0, TAU, 24, Color(0.45, 0.5, 0.6, 0.8 * (1.0 - k)), 2.0, true)
			Art.text_c(self, font, p + Vector2(0, -40), "дзынь!", 18, Color(0.35, 0.4, 0.5, 1.0 - k), Color(1, 1, 1, 0.8 * (1.0 - k)), 4)
		"basket":
			Art.blob(self, p, 50, 30, Color(0.86, 0.74, 0.55, 1.0 - k), 3.0, fr, 0.0, Color(INK, 1.0 - k))
			for i in 4:
				draw_line(p + Vector2(-40 + i * 26, -22), p + Vector2(-44 + i * 26, 22), Color(0.6, 0.48, 0.32, 1.0 - k), 2.0)
		"gust":
			var dir: Vector2 = f["dir"]
			var half: float = f["half"]
			var r: float = f["r"]
			for j in 4:
				var a := dir.angle() - half + 2.0 * half * (float(j) + 0.5) / 4.0
				var q := p + Vector2(cos(a), sin(a)) * r * (0.3 + 0.7 * k)
				draw_arc(q, 10.0, a - 1.2, a + 1.2, 8, Color(0.55, 0.75, 0.85, 0.9 * (1.0 - k)), 2.5, true)
		"notes":
			var r: float = f["r"]
			draw_arc(p, r, 0, TAU, 40, Color(0.55, 0.45, 0.85, 0.25 * (1.0 - k)), 2.0, true)
			for j in 3:
				var a := float(j) * 2.1 + float(f["t"]) * 2.0
				var q := p + Vector2(cos(a), sin(a)) * r * 0.7 + Vector2(0, -20.0 * k)
				draw_circle(q, 3.5, Color(0.42, 0.31, 0.7, 1.0 - k))
				draw_line(q + Vector2(3, 0), q + Vector2(3, -10), Color(0.42, 0.31, 0.7, 1.0 - k), 1.5)
		"lob":
			var to: Vector2 = f["to"]
			var q := p.lerp(to, k) - Vector2(0, sin(k * PI) * 90.0)
			Art.fill_blob(self, to, 18.0 * k, 7.0 * k, Color(0, 0, 0, 0.15))
			if f["what"] == "book":
				var pts := Art.rot_rect(q, 30, 22, k * 8.0)
				draw_colored_polygon(pts, Color("c25b4a"))
				Art.outline(self, pts, Art.INK, 2.0)
			else:
				Art.blob(self, q, 8.0, 7.0, Color("b07a4a"), 2.0, 3, k * 10.0)
		"starfall":
			var q := p - Vector2(0, (1.0 - k) * 140.0)
			Icons._star(self, q, 9.0, Color("ffe36a"), 1.0)
			Art.fill_blob(self, p, 10.0 * k, 4.0 * k, Color(1.0, 0.9, 0.4, 0.4))
		"heal":
			for j in 3:
				var q := p + Vector2(-10 + j * 10, -14 - 20.0 * k)
				draw_line(q - Vector2(4, 0), q + Vector2(4, 0), Color(0.3, 0.75, 0.3, 1.0 - k), 2.5)
				draw_line(q - Vector2(0, 4), q + Vector2(0, 4), Color(0.3, 0.75, 0.3, 1.0 - k), 2.5)
		"miss":
			Art.text_c(self, font, p + Vector2(0, -18 - 14.0 * k), "мимо", 14, Color(0.4, 0.4, 0.45, 1.0 - k), Color(1, 1, 1, 0.7 * (1.0 - k)), 4)
		"stamp":
			var a := 1.0 - clampf((k - 0.6) / 0.4, 0.0, 1.0)
			Art.text_c(self, font, p + Vector2(0, 8), "СОРВАНО", 26, Color(0.75, 0.2, 0.15, a), Color(1, 0.97, 0.9, a), 5)
		"sparkle":
			for i in 6:
				var a := TAU * i / 6.0
				draw_line(p + Vector2(cos(a), sin(a)) * (10 + 20 * k), p + Vector2(cos(a), sin(a)) * (16 + 26 * k), Color(0.42, 0.31, 0.7, 1.0 - k), 2.0)
		"trap":
			pass
		"stink":
			for i in 4:
				var q := p + Vector2(-18 + i * 12, -20 - 40 * k + sin(_time * 6.0 + i) * 4.0)
				draw_arc(q, 6.0, 0, PI * 1.5, 8, Color(0.45, 0.6, 0.2, 1.0 - k), 2.5)
		"egg":
			Art.blob(self, p, 10, 13, Color(1, 0.97, 0.88, 1.0 - k), 2.5, fr, 0.0, Color(INK, 1.0 - k))
			draw_polyline(PackedVector2Array([p + Vector2(-9, 0), p + Vector2(-4, -4), p + Vector2(0, 1), p + Vector2(5, -4), p + Vector2(9, 0)]), Color(INK, 1.0 - k), 2.0)
		"eat":
			Icons.draw(self, f["fruit"], p + Vector2(0, -60 - 20 * k), 34.0, 1.0 - k, false)
		"confetti":
			var cols := [Color("f2c14e"), Color("e98a7a"), Color("8fb6e8"), Color("9fcf8c"), Color("cdb3dc")]
			for i in 24:
				var a := TAU * i / 24.0 + float(i) * 0.37
				var sp := 120.0 + float(i % 5) * 40.0
				var q := p + Vector2(cos(a), sin(a)) * sp * k + Vector2(0, 160.0 * k * k)
				draw_rect(Rect2(q - Vector2(4, 2), Vector2(8, 4)), Color(cols[i % 5], 1.0 - k))


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



# ---------- обучение игрока ----------

func _draw_tut(fr: int) -> void:
	var tu: Dictionary = game.tut
	if tu.is_empty() or tu["kind"] != "millet":
		return
	var g: Dictionary = tu["gem"]
	var p: Vector2 = g["pos"]
	var pulse := 0.5 + 0.5 * sin(_time * 8.0)
	draw_arc(p, 30.0 + 8.0 * pulse, 0, TAU, 32, Color(0.42, 0.31, 0.7, 0.9), 4.0, true)
	draw_arc(p, 48.0 + 8.0 * pulse, 0, TAU, 32, Color(0.42, 0.31, 0.7, 0.4), 3.0, true)
	var a := p + Vector2(0, -90 - 10 * pulse)
	draw_line(a, p + Vector2(0, -40), Color(0.42, 0.31, 0.7, 1.0), 5.0, true)
	draw_polyline(PackedVector2Array([p + Vector2(-12, -54), p + Vector2(0, -40), p + Vector2(12, -54)]), Color(0.42, 0.31, 0.7, 1.0), 5.0)
	var cap := "Выберите подмену: попугай её не увидит" if not game.menu.is_empty() else "Кликните по колоску проса!"
	Art.text_c(self, font, p + Vector2(0, -110), cap, 24, Color(0.42, 0.31, 0.7), Color(1, 0.98, 0.93, 0.95), 8)


# ---------- ивенты: маяк и награда видны издалека ----------

func _draw_event_marks(fr: int) -> void:
	var ev: Dictionary = game.event
	if ev.is_empty():
		return
	var p := Vector2.ZERO
	if ev.has("pos"):
		p = ev["pos"]
	else:
		for e in game.enemies:
			if e.type == Enemy.T.BOX and not e.dead:
				p = e.pos
	if p == Vector2.ZERO:
		return
	var bob := sin(_time * 3.0) * 6.0
	# столб света
	var top := p + Vector2(0, -150)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-26, 0), top + Vector2(-10, 0), top + Vector2(10, 0), p + Vector2(26, 0)]), Color(1.0, 0.88, 0.4, 0.18 + 0.06 * sin(_time * 4.0)))
	var ip := p + Vector2(0, -78 + bob)
	Art.fill_blob(self, ip, 30, 30, Color(1.0, 0.92, 0.55, 0.55))
	Icons.draw(self, ev["fruit"], ip, 42.0, 1.0)
	for k in 4:
		var a := _time * 2.0 + k * TAU / 4.0
		Icons._star(self, ip + Vector2(cos(a), sin(a)) * 30.0, 5.0, Color("f6d84c"), 0.9)
	Art.text_c(self, font, ip + Vector2(0, -32), "награда", 14, Color("8a5a1e"), Color(1, 0.98, 0.9, 0.9), 5)
	if ev["type"] == "glow":
		Art.text_c(self, font, game.hero.pos + Vector2(0, -110), "светящиеся зёрна: %d/%d · %d с" % [int(ev["got"]), game.GLOW_NEED, int(ceil(float(ev["left"])))], 18, Color("2f8fa8"), Color(1, 0.98, 0.93, 0.9), 5)
	elif ev["type"] == "box":
		Art.text_c(self, font, p + Vector2(0, 40), "%d с" % int(ceil(float(ev["left"]))), 18, Color("8a5a1e"), Color(1, 0.98, 0.93, 0.9), 5)


# ---------- финал: яйцо и перья ----------

func _draw_outro_items(fr: int) -> void:
	var o: Dictionary = game.outro
	if o.is_empty():
		return
	for it in o["items"]:
		if it["got"]:
			continue
		var p: Vector2 = it["pos"]
		var pulse := 0.5 + 0.5 * sin(_time * 6.0)
		if it["landed"]:
			Art.fill_blob(self, p, 40 + 8 * pulse, 40 + 8 * pulse, Color(1.0, 0.9, 0.45, 0.35))
			for k in 6:
				var a := _time * 1.5 + k * TAU / 6.0
				Icons._star(self, p + Vector2(cos(a), sin(a)) * (46.0 + 4.0 * pulse), 5.0, Color("f6d84c"), 0.9)
		if it["kind"] == "egg":
			Art.fill_blob(self, p + Vector2(4, 24), 20, 6, Color(0, 0, 0, 0.15))
			Art.blob(self, p, 18.0, 23.0, Color("fff7e6"), 3.5, fr)
			for k in 4:
				draw_circle(p + Vector2(-8 + (k % 2) * 12, -10 + k * 6), 2.5, Color("c9b38a"))
			if it["landed"]:
				Art.text_c(self, font, p + Vector2(0, -44), "Кликните по яйцу!", 22, Color("8a5a1e"), Color(1, 0.98, 0.9, 0.95), 7)
		else:
			var rot := sin(float(it["sway"])) * 0.6
			Art.blob(self, p, 6.0, 18.0, Color("79c85f"), 2.5, fr, rot)
			draw_line(p + Vector2(0, 18).rotated(rot), p + Vector2(0, -16).rotated(rot), Color("2f5e33"), 2.0)
			if it["landed"]:
				Art.text_c(self, font, p + Vector2(0, -34), "перо!", 18, Color("4f8f3a"), Color(1, 0.98, 0.9, 0.95), 6)



## Подсказка по наведению на карту умения.
func _card_tip(c: Dictionary, sc: Dictionary, cp: Vector2) -> void:
	var k: String = c["key"]
	var tag := ""
	match c["kind"]:
		"skill":
			tag = "новое умение" if c["new"] else "умение, ур. %d" % int(c["lvl"])
		"general":
			tag = "пассивка" if c["new"] else "пассивка, ур. %d" % int(c["lvl"])
		"mod":
			tag = "особая пассивка для «%s»" % String(Skills.NAMES[Skills.mod_parent(k)])
	var lines := [String(Skills.NAMES[k]), tag, String(Skills.DESC[k]), "попугаю нравится на %.1f" % float(sc["score"])]
	var w := 0.0
	for i in lines.size():
		w = maxf(w, Art.text_w(font, lines[i], 20 if i == 0 else 15))
	var r := Rect2(cp + Vector2(44, -50), Vector2(w + 28, 104))
	if r.end.x > game.FIELD.end.x - 10:
		r.position.x = cp.x - 44 - r.size.x
	Art.card(self, r, Color(1, 0.98, 0.92, 0.97), Art.frame(), INK, 2.5)
	draw_string(font, r.position + Vector2(14, 28), lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)
	draw_string(font, r.position + Vector2(14, 50), lines[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.3, 0.3, 0.45))
	draw_string(font, r.position + Vector2(14, 72), lines[2], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
	draw_string(font, r.position + Vector2(14, 94), lines[3], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.31, 0.47, 0.66))



## Клетка: пока падает, её тень ползёт за лапкой; приземлилась — стоит над попугаем.
## Рисуется в два прохода: задние прутья и поддон под всеми, передние прутья — поверх.
func _draw_basket(m: Dictionary) -> void:
	var p: Vector2 = m["pos"]
	var r: float = m["r"]
	if not m["landed"]:
		var k := clampf(float(m["t"]) / float(m["delay"]), 0.0, 1.0)
		var hidden := float(m["t"]) < float(m.get("hidden", 0.0))
		var sa := 0.35 if hidden else 1.0
		Art.fill_blob(self, p, r * (0.3 + 0.7 * k), r * (0.3 + 0.7 * k) * 0.42, Color(0.25, 0.18, 0.1, (0.12 + 0.28 * k) * sa))
		draw_arc(p, r, 0, TAU, 40, Color(0.42, 0.31, 0.7, 0.6 * sa), 2.0, true)
		# прицел-крестик: клетка тянется к лапке
		var to: Vector2 = game.paw["pos"]
		if to.distance_to(p) > 8.0:
			draw_line(p, p + (to - p).limit_length(r * 0.8), Color(0.42, 0.31, 0.7, 0.45 * sa), 2.0, true)
		return
	var lt: float = m["land_t"]
	var tt: float = m.get("trap", game.BASKET_TRAP)
	var a := 1.0 - clampf((lt - tt) / 0.3, 0.0, 1.0)
	var bounce := absf(sin(lt * 18.0)) * 6.0 * maxf(0.0, 1.0 - lt * 2.0)
	_cage(p - Vector2(0, bounce), r, a, 0)
	if m.has("caught") and lt < tt:
		var left: float = 1.0 - lt / tt
		draw_arc(p, r + 10, -PI * 0.5, -PI * 0.5 + TAU * left, 32, Color(0.42, 0.31, 0.7, 0.9), 4.0, true)


## Передний план клетки: падающая клетка целиком или передние прутья стоящей.
func _draw_basket_front(m: Dictionary) -> void:
	var p: Vector2 = m["pos"]
	var r: float = m["r"]
	if not m["landed"]:
		var k := clampf(float(m["t"]) / float(m["delay"]), 0.0, 1.0)
		if k > 0.6:
			var kk := (k - 0.6) / 0.4
			var c := p - Vector2(0, pow(1.0 - kk, 2.0) * 420.0)
			var sc := 1.25 - 0.25 * kk
			_cage(c, r * sc, 1.0, 0)
			_cage(c, r * sc, 1.0, 1)
		return
	var lt: float = m["land_t"]
	var tt: float = m.get("trap", game.BASKET_TRAP)
	var a := 1.0 - clampf((lt - tt) / 0.3, 0.0, 1.0)
	var bounce := absf(sin(lt * 18.0)) * 6.0 * maxf(0.0, 1.0 - lt * 2.0)
	_cage(p - Vector2(0, bounce), r, a, 1)


const CAGE_GOLD := Color("d9ae4f")
const CAGE_DARK := Color("8a6a2a")


## Птичья клетка-купол: поддон, 12 прутьев, два кольца, крючок сверху. part 0 — задняя половина, 1 — передняя.
func _cage(c: Vector2, r: float, a: float, part: int) -> void:
	var ry := r * 0.4
	var h := r * 1.75
	var bars := 12
	if part == 0:
		# поддон и тень
		Art.fill_blob(self, c + Vector2(0, 6), r * 1.08, ry * 1.1, Color(0, 0, 0, 0.18 * a))
		var tray := Art.ellipse_pts(c, r * 1.06, ry * 1.06, 3, 0.0, 28)
		draw_colored_polygon(tray, Color(0.55, 0.38, 0.22, 0.9 * a))
		Art.outline(self, tray, Color(INK, a), 2.5)
		draw_colored_polygon(Art.ellipse_pts(c + Vector2(0, -3), r * 0.92, ry * 0.88, 5, 0.0, 28), Color(0.85, 0.75, 0.55, 0.55 * a))
	# прутья: задние (верх эллипса) в первом проходе, передние — во втором
	for i in bars:
		var ang := TAU * (float(i) + 0.5) / float(bars)
		var front := sin(ang) >= 0.0
		if front != (part == 1):
			continue
		var pts := PackedVector2Array()
		for j in 9:
			var t := float(j) / 8.0
			var kk := sqrt(maxf(0.0, 1.0 - t * t * 0.96))
			pts.append(c + Vector2(r * cos(ang) * kk, ry * sin(ang) * kk - h * t))
		var shade := 1.0 if front else 0.55
		draw_polyline(pts, Color(INK, a * shade), 4.0, true)
		draw_polyline(pts, Color(CAGE_GOLD.lerp(CAGE_DARK, 1.0 - shade), a), 2.0, true)
	# кольца: середина и верх, половинки по проходам
	for t in [0.42, 0.85]:
		var kk := sqrt(maxf(0.0, 1.0 - t * t * 0.96))
		var cc := c - Vector2(0, h * t)
		var from := PI if part == 0 else 0.0
		var arc := PackedVector2Array()
		for j in 17:
			var ang2 := from + PI * float(j) / 16.0
			arc.append(cc + Vector2(r * kk * cos(ang2), ry * kk * sin(ang2)))
		draw_polyline(arc, Color(INK, a), 4.5, true)
		draw_polyline(arc, Color(CAGE_GOLD, a), 2.5, true)
	if part == 1:
		# передний край поддона и крючок
		var rim := PackedVector2Array()
		for j in 17:
			var ang3 := PI * float(j) / 16.0
			rim.append(c + Vector2(r * 1.06 * cos(ang3), ry * 1.06 * sin(ang3)))
		draw_polyline(rim, Color(INK, a), 3.0, true)
		var top := c - Vector2(0, h)
		draw_arc(top - Vector2(0, 9), 8.0, 0, TAU, 16, Color(INK, a), 4.0, true)
		draw_arc(top - Vector2(0, 9), 8.0, 0, TAU, 16, Color(CAGE_GOLD, a), 2.0, true)
		draw_circle(top, 4.0, Color(CAGE_GOLD, a))
