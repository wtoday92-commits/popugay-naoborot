class_name Hud
extends Node2D
## Интерфейс поверх комнаты: карточка героя со шкалами, цели, таймер и орда, лента мыслей,
## кнопки игрока, выбор перка на виду, баннеры, итог забега и сама кошачья лапка.

const INK := Art.INK
const PANEL := Color(1.0, 0.98, 0.93, 0.9)
const C_HP := Color("74b562")
const C_STRESS := Color("e07a6a")
const C_GREED := Color("e8b84a")
const C_PLAYER := Color("6a4fb3")

var game
var font: Font
var _a := 1.0


func _ready() -> void:
	font = ThemeDB.fallback_font


func _t(p: Vector2, s: String, size: int, col: Color = INK) -> void:
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(col, col.a * _a))


func _bar(r: Rect2, frac: float, col: Color, label: String) -> void:
	draw_rect(r, Color(0, 0, 0, 0.08 * _a))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(frac, 0.0, 1.0), r.size.y)), Color(col, col.a * _a))
	draw_rect(r, Color(INK, _a), false, 1.5)
	if label != "":
		_t(r.position + Vector2(6, r.size.y - 3), label, 13)


static func mmss(t: float) -> String:
	var s := int(t)
	return "%02d:%02d" % [s / 60, s % 60]


func _draw() -> void:
	if game == null or game.hero == null:
		return
	var fr := Art.frame()
	var h: Hero = game.hero
	_a = _fade(Rect2(12, 12, 318, 320))
	_draw_hero_card(h, fr)
	_a = _fade(Rect2(600, 10, 400, 98))
	_draw_top(h, fr)
	_a = _fade(Rect2(1248, 12, 340, 262))
	_draw_thoughts(fr)
	_a = _fade(Rect2(500, 820, 600, 58))
	_draw_buttons(h, fr)
	_a = 1.0
	_draw_levelup(fr)
	_draw_banners()
	_draw_vignettes(h)
	if game.hint_t > 0.0 and game.over == "":
		var a := clampf(game.hint_t, 0.0, 1.0)
		var w := Art.text_w(font, game.hint, 18) + 30.0
		var r := Rect2(Vector2(800 - w * 0.5, 744), Vector2(w, 34))
		Art.card(self, r, Color(1, 0.97, 0.88, 0.92 * a), fr + 9, Color(INK, a), 2.0)
		_t(r.position + Vector2(15, 23), game.hint, 18, Color(INK, a))
	_t(Vector2(14, 892), "Мышь — лапка · ЛКМ/1 книга · ПКМ/2 корзина · Пробел пауза · F2 ×3 · F3 мысли ИИ · R заново", 13, Color(INK, 0.6))
	if game.paused:
		_overlay("Пауза", "Пробел — продолжить")
	if game.over != "":
		_draw_end()
	_draw_paw(fr)


func _draw_hero_card(h: Hero, fr: int) -> void:
	var r := Rect2(12, 12, 318, 214)
	Art.card(self, r, Color(PANEL, PANEL.a * _a), fr, Color(INK, _a))
	_t(Vector2(26, 38), "Кеша", 22)
	_t(Vector2(90, 37), "упрямый коллекционер", 14, Color(INK, 0.65))
	_t(Vector2(26, 62), "Уровень %d" % h.level, 15)
	_bar(Rect2(120, 50, 196, 12), float(h.xp) / float(h.xp_next), Color("f2cd5c"), "")
	_bar(Rect2(26, 72, 290, 18), h.hp_frac(), C_HP if h.hp_frac() >= 0.2 else Color("d95c4a"), "Здоровье %d/%d" % [int(ceil(h.hp)), int(h.max_hp())])
	_bar(Rect2(26, 96, 290, 14), h.stress, C_STRESS, "Стресс")
	_bar(Rect2(26, 114, 290, 14), h.greed, C_GREED, "Жадность")
	if h.greed > h.stress:
		_t(Vector2(232, 126), "рискует", 12, Color("9a6a10"))
	var mode: String = Hero.MODE_NAMES[h.mode]
	_t(Vector2(26, 150), "Режим: " + mode, 15)
	_t(Vector2(170, 150), "План: Колокольчик + Пух", 13, Color(INK, 0.7))
	var parts: Array[String] = []
	for k in h.weapons:
		parts.append("%s %d" % [Perks.NAMES[k], int(h.weapons[k])])
	_t(Vector2(26, 174), " · ".join(parts), 13)
	parts.clear()
	for k in h.passives:
		parts.append("%s %d" % [Perks.NAMES[k], int(h.passives[k])])
	_t(Vector2(26, 194), " · ".join(parts) if parts.size() > 0 else "пассивок нет", 13, Color(INK, 0.75))
	var focus_txt := "Смотрит на %d из 3" % h.focus.size()
	_t(Vector2(26, 216), focus_txt + (" · выбирает перк, слоты заморожены" if h.choosing else ""), 12, Color("4f79a8"))

	var g := Rect2(12, 234, 318, 98)
	Art.card(self, g, Color(PANEL, PANEL.a * _a), fr + 1, Color(INK, _a))
	_t(Vector2(26, 256), "Цели героя", 16)
	_goal(Vector2(26, 280), "Выжить 30:00", game.over == "survived", game.over == "hero_dead")
	var chest_fail: bool = game.over == "hero_dead" and h.chests_opened < 3
	_goal(Vector2(26, 302), "Открыть 3 кормушки: %d/3" % h.chests_opened, h.chests_opened >= 3, chest_fail, game.last_chance() > 0.0)
	var bell := h.lvl_of("bell")
	_goal(Vector2(26, 324), "Колокольчик до ур. 5: %d/5" % bell, bell >= 5, game.over == "hero_dead" and bell < 5)


func _goal(p: Vector2, s: String, done: bool, failed: bool, blink: bool = false) -> void:
	var col := INK
	if blink and int(Time.get_ticks_msec() / 300) % 2 == 0:
		col = Color("b23a2e")
	draw_rect(Rect2(p + Vector2(0, -12), Vector2(12, 12)), INK, false, 1.5)
	if done:
		draw_line(p + Vector2(2, -6), p + Vector2(5, -2), Color("4f8f3a"), 2.5)
		draw_line(p + Vector2(5, -2), p + Vector2(11, -12), Color("4f8f3a"), 2.5)
	_t(p + Vector2(20, 0), s, 15, col)
	if failed:
		_t(p + Vector2(200, 0), "СОРВАНО", 15, Color("b23a2e"))


func _draw_top(h: Hero, fr: int) -> void:
	var r := Rect2(600, 10, 400, 98)
	Art.card(self, r, Color(PANEL, PANEL.a * _a), fr + 2, Color(INK, _a))
	Art.text_c(self, font, Vector2(800, 48), mmss(game.time), 34, Color(INK, _a))
	_t(Vector2(872, 46), "/ 30:00", 15, Color(INK, 0.6))
	var nxt: float = game.next_horde - game.time
	Art.text_c(self, font, Vector2(800, 70), "Орда: уровень %d · гонг через %s" % [game.horde_level, mmss(maxf(nxt, 0.0))], 15, Color(0.25, 0.44, 0.71, _a))
	# перетягивание «мощь героя ↔ мощь орды»
	var hero_p := h.power() * 2.0 + float(h.level)
	var horde_p: float = float(game.horde_level) * 4.0 + game.player_damage / 25.0 + 2.0
	var k: float = hero_p / (hero_p + horde_p)
	var bar := Rect2(620, 82, 360, 14)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * k, bar.size.y)), Color("9fd28c"))
	draw_rect(Rect2(bar.position + Vector2(bar.size.x * k, 0), Vector2(bar.size.x * (1.0 - k), bar.size.y)), Color("a7bfe6"))
	draw_rect(bar, INK, false, 1.5)
	draw_line(Vector2(bar.position.x + bar.size.x * k, bar.position.y - 4), Vector2(bar.position.x + bar.size.x * k, bar.end.y + 4), INK, 3.0)
	_t(Vector2(624, 94), "мощь героя", 11)
	_t(Vector2(918, 94), "мощь орды", 11)


func _draw_thoughts(fr: int) -> void:
	var r := Rect2(1248, 12, 340, 262)
	Art.card(self, r, Color(PANEL, PANEL.a * _a), fr + 3, Color(INK, _a))
	_t(Vector2(1262, 36), "Мысли героя", 16)
	var y := 60.0
	var i := 0
	for th in game.thoughts:
		if y > 262.0:
			break
		var a := 1.0 - i * 0.09
		var s: String = th["text"]
		var lines := 1 if Art.text_w(font, s, 14) < 300.0 else 2
		draw_multiline_string(font, Vector2(1262, y), s, HORIZONTAL_ALIGNMENT_LEFT, 316, 14, 2, Color(INK, a * _a))
		y += 18.0 * lines + 6.0
		i += 1


func _draw_buttons(h: Hero, fr: int) -> void:
	var edge: bool = h.hp_frac() < 0.2 and game.over == ""
	var x0 := 800.0 - 300.0
	var y0 := 820.0
	_button(Rect2(x0, y0, 190, 58), fr, "Книга с полки", "ЛКМ / 1", game.meteor_cd, game.METEOR_CD, true, edge)
	var unlocked: bool = game.time >= game.WAVE_UNLOCK
	_button(Rect2(x0 + 205, y0, 190, 58), fr + 1, "Корзина белья", "ПКМ / 2" if unlocked else "откроется в 3:00", game.wave_cd, game.WAVE_CD, unlocked, edge)
	var pr := Rect2(x0 + 410, y0, 190, 58)
	var st := "толкает юнитов"
	var cd := 0.0
	if game.paw_bruise > 0.0:
		st = "ушиблена %.1f с" % game.paw_bruise
		cd = game.paw_bruise
	elif game.time < game.RAM_UNLOCK:
		st = "таран с 1:30"
	else:
		st = "таран готов"
	_button(pr, fr + 2, "Лапка", st, cd, game.PAW_BRUISE, true, edge and cd <= 0.0 and game.time >= game.RAM_UNLOCK)


func _button(r: Rect2, fr: int, title: String, sub: String, cd: float, cd_max: float, unlocked: bool, glow: bool) -> void:
	var ready := unlocked and cd <= 0.0
	var fill := Color(1, 0.97, 0.9, 0.95) if ready else Color(0.9, 0.88, 0.84, 0.92)
	Art.card(self, r, Color(fill, fill.a * _a), fr, Color(INK, _a), 2.5)
	if not ready and unlocked and cd_max > 0.0:
		draw_rect(Rect2(r.position + Vector2(3, 3), Vector2((r.size.x - 6) * (1.0 - cd / cd_max), r.size.y - 6)), Color(0.6, 0.5, 0.85, 0.18))
	if glow and ready:
		var a := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
		Art.outline(self, Art.wobbly_rect(r.grow(4), fr + 5, 1.0), Color(0.9, 0.3, 0.2, a), 3.0)
	_t(r.position + Vector2(12, 24), title, 17, INK if unlocked else Color(INK, 0.5))
	var sub_txt := sub
	if unlocked and cd > 0.0 and title != "Лапка":
		sub_txt = "%s · %.0f с" % [sub, ceil(cd)]
	_t(r.position + Vector2(12, 46), sub_txt, 13, Color(INK, 0.7))


func _draw_levelup(fr: int) -> void:
	var lu: Dictionary = game.levelup
	if lu.is_empty():
		return
	var t: float = lu["t"]
	var fade := 1.0 - clampf((t - 2.2) / 0.6, 0.0, 1.0)
	var cards: Array = lu["cards"]
	var scores: Array = lu["scores"]
	var chosen: int = lu["chosen"]
	var hover := chosen
	if t < 1.0:
		var seq := [0, 1, 2, 1, 0, 2, 1]
		hover = seq[int(t * 7.0) % seq.size()] % cards.size()
	var applied: bool = lu["applied"]
	Art.text_c(self, font, Vector2(800, 288), "Уровень %d · герой выбирает игрушку (время замедлено)" % int(lu["level"]), 18, Color(INK, fade), Color(1, 0.98, 0.94, 0.9 * fade), 5)
	var n := cards.size()
	var w := 214.0
	var gap := 18.0
	var x0 := 800.0 - (n * w + (n - 1) * gap) * 0.5
	for i in n:
		var c: Dictionary = cards[i]
		var r := Rect2(x0 + i * (w + gap), 300, w, 118)
		var a := fade
		if applied and i != chosen:
			a *= 0.35
		var fill := Color(1, 0.98, 0.93, 0.95 * a)
		if i == hover:
			fill = Color(1, 0.93, 0.7, 0.97 * a)
		Art.card(self, r, fill, fr + i, Color(INK, a), 3.0 if i == hover else 2.0)
		var k: String = c["key"]
		_t(r.position + Vector2(14, 30), Perks.NAMES[k], 19, Color(INK, a))
		var tag := "новое" if c["new"] else "ур. %d" % int(c["lvl"])
		_t(r.position + Vector2(14, 54), tag + (" · оружие" if Perks.is_weapon(k) else " · пассивка"), 13, Color(INK, 0.7 * a))
		_t(r.position + Vector2(14, 78), Perks.DESC[k], 14, Color(INK, a))
		_t(r.position + Vector2(14, 104), "оценка героя %.1f" % float(scores[i]["score"]), 13, Color(0.31, 0.47, 0.66, a))
		if i == hover:
			var pc := r.position + Vector2(w - 26, 18)
			draw_circle(pc, 7.0, Color(0.95, 0.75, 0.2, a))
			draw_arc(pc, 7.0, 0, TAU, 12, Color(INK, a), 2.0)


func _draw_banners() -> void:
	var y := 196.0
	for b in game.banners:
		var t: float = b["t"]
		var d: float = b["dur"]
		var a := clampf(t / 0.15, 0.0, 1.0) * (1.0 - clampf((t - (d - 0.4)) / 0.4, 0.0, 1.0))
		var sc := 1.0 + 0.25 * maxf(0.0, 1.0 - t / 0.2)
		var col: Color = b["color"]
		col.a = a
		Art.text_c(self, font, Vector2(800, y), b["text"], int(float(b["size"]) * sc), col, Color(1, 0.98, 0.93, a), 8)
		y += float(b["size"]) + 14.0


func _draw_vignettes(h: Hero) -> void:
	if game.over == "" and h.hp_frac() < 0.2:
		var a := 0.18 + 0.12 * sin(Time.get_ticks_msec() * 0.012)
		_frame(Color(0.85, 0.15, 0.1, a), 26.0)
		Art.text_c(self, font, Vector2(800, 140), "На волоске!", 26, Color(0.75, 0.15, 0.1, 0.9), Color(1, 0.97, 0.9, 0.9), 6)
	if game.power_flash > 0.0:
		_frame(Color(0.75, 0.1, 0.08, game.power_flash), 60.0)


func _frame(col: Color, w: float) -> void:
	draw_rect(Rect2(0, 0, 1600, w), col)
	draw_rect(Rect2(0, 900 - w, 1600, w), col)
	draw_rect(Rect2(0, w, w, 900 - 2 * w), col)
	draw_rect(Rect2(1600 - w, w, w, 900 - 2 * w), col)


func _overlay(title: String, sub: String) -> void:
	draw_rect(Rect2(0, 0, 1600, 900), Color(0.2, 0.15, 0.1, 0.35))
	var r := Rect2(560, 360, 480, 140)
	Art.card(self, r, PANEL, Art.frame())
	Art.text_c(self, font, Vector2(800, 418), title, 38, INK)
	Art.text_c(self, font, Vector2(800, 462), sub, 17, Color(INK, 0.7))


func _draw_end() -> void:
	draw_rect(Rect2(0, 0, 1600, 900), Color(0.2, 0.15, 0.1, 0.4))
	var r := Rect2(470, 300, 660, 300)
	Art.card(self, r, PANEL, Art.frame(), INK, 3.0)
	var h: Hero = game.hero
	if game.over == "hero_dead":
		Art.text_c(self, font, Vector2(800, 362), "Попался!", 46, Color("b23a2e"))
		Art.text_c(self, font, Vector2(800, 398), "Кеша повержен на %s" % mmss(game.time), 20, INK)
	else:
		Art.text_c(self, font, Vector2(800, 362), "Кеша выжил", 46, Color("4f8f3a"))
		Art.text_c(self, font, Vector2(800, 398), "Все 30 минут. В следующий раз ловите его на жадности.", 18, INK)
	var lines := [
		"Ваш урон по герою: %d" % int(game.player_damage),
		"Книги попали: %d из %d · тараны лапкой: %d · загоны: %d" % [game.meteor_hits, game.meteors_cast, game.rams, game.combos],
		"Кормушек открыл герой: %d · сорвано вами: %d" % [h.chests_opened, game.chests_denied],
		"Герой: уровень %d · орда: уровень %d · убито юнитов: %d" % [h.level, game.horde_level, game.kills],
	]
	var y := 446.0
	for s in lines:
		Art.text_c(self, font, Vector2(800, y), s, 17, INK)
		y += 28.0
	Art.text_c(self, font, Vector2(800, 580), "R — новый забег", 17, Color(INK, 0.7))


func _draw_paw(fr: int) -> void:
	var off: Vector2 = game.world.position
	for tr in game.paw_trail:
		var a := clampf(float(tr["t"]) / 0.3, 0.0, 1.0)
		draw_line(Vector2(tr["a"]) + off, Vector2(tr["b"]) + off, Color(INK, 0.35 * a), 2.0, true)
	var p: Vector2 = game.paw["pos"] + off
	var bruised: bool = game.paw_bruise > 0.0
	if bruised:
		var m := get_global_mouse_position()
		draw_dashed_line(p, m, Color(INK, 0.35), 1.5, 6.0)
		draw_circle(m, 3.0, Color(INK, 0.4))
	var fill := Color("d9dbe8") if bruised else Color("fffaf2")
	var sd := 77 + fr
	for k in 4:
		var tp: Vector2 = p + [Vector2(-13, -10), Vector2(-5, -17), Vector2(5, -17), Vector2(13, -10)][k]
		Art.blob(self, tp, 5.5, 6.0, fill, 3.0, sd + k)
		draw_circle(tp + Vector2(0, 1), 2.4, Color("f3a7b5"))
	Art.blob(self, p + Vector2(0, 4), 15.0, 12.5, fill, 3.0, sd)
	Art.fill_blob(self, p + Vector2(0, 6), 7.0, 5.5, Color("f3a7b5"))
	if bruised:
		for k in 3:
			var a := Time.get_ticks_msec() * 0.006 + k * TAU / 3.0
			var sp := p + Vector2(cos(a) * 20.0, -24 + sin(a) * 6.0)
			draw_circle(sp, 2.5, Color("f6cd56"))
			draw_arc(sp, 2.5, 0, TAU, 8, INK, 1.0)
	elif game.time >= game.RAM_UNLOCK and game.paw_vel.length() > game.RAM_SPEED:
		draw_arc(p + Vector2(0, -2), 26.0, 0, TAU, 24, Color(0.42, 0.31, 0.7, 0.6), 2.5, true)


## Панель бледнеет, когда под ней оказывается герой.
func _fade(r: Rect2) -> float:
	var hp: Vector2 = game.hero.pos + game.world.position
	return 0.3 if r.grow(40.0).has_point(hp) else 1.0
