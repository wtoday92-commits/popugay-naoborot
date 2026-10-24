class_name Hud
extends Node2D
## Боковые полосы с информацией (поле посередине не перекрывается). На старте они пустые:
## блоки выезжают с анимацией, когда появляется то, что в них показывать.
## Слева — герой, умения, фрукты, цели, очередь ивентов (перетаскивается); справа — время, мысли, кнопки игрока.

const INK := Art.INK
const PANEL := Color(1.0, 0.98, 0.93, 1.0)
const STRIP := Color("efe4d2")
const C_HP := Color("74b562")
const C_STRESS := Color("e07a6a")
const C_GREED := Color("e8b84a")
const LEFT := Rect2(0, 0, 340, 1080)
const RIGHT := Rect2(1580, 0, 340, 1080)
const QUEUE_Y := 676.0
const QUEUE_ROW := 74.0
const APPEAR := 0.45

var game
var font: Font
var _shown := {}


func _ready() -> void:
	font = ThemeDB.fallback_font


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## Блок появляется один раз и выезжает с «пружинкой»; возвращает сдвиг по x (0 — на месте) или NAN, если блока нет.
func _slide(name: String, visible: bool, from_left: bool) -> float:
	if not visible and not _shown.has(name):
		return NAN
	if not _shown.has(name):
		_shown[name] = _now()
		if game.time > 0.5:
			game.sfx("tick", -10.0, 0.9)
	var k := clampf((_now() - float(_shown[name])) / APPEAR, 0.0, 1.0)
	var c1 := 1.70158
	var e := 1.0 + (c1 + 1.0) * pow(k - 1.0, 3.0) + c1 * pow(k - 1.0, 2.0)
	return (1.0 - e) * (-360.0 if from_left else 360.0)


func reset() -> void:
	_shown.clear()


func _t(p: Vector2, s: String, size: int, col: Color = INK) -> void:
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _bar(r: Rect2, frac: float, col: Color, label: String) -> void:
	draw_rect(r, Color(0, 0, 0, 0.08))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(frac, 0.0, 1.0), r.size.y)), col)
	draw_rect(r, INK, false, 1.5)
	if label != "":
		_t(r.position + Vector2(6, r.size.y - 3), label, 13)


static func mmss(t: float) -> String:
	var s := int(maxf(t, 0.0))
	return "%d:%02d" % [s / 60, s % 60]


func _draw() -> void:
	if game == null or game.hero == null:
		return
	var fr := Art.frame()
	var h: Hero = game.hero
	draw_rect(LEFT, STRIP)
	draw_rect(RIGHT, STRIP)
	draw_line(Vector2(LEFT.end.x, 0), Vector2(LEFT.end.x, 1080), INK, 3.0)
	draw_line(Vector2(RIGHT.position.x, 0), Vector2(RIGHT.position.x, 1080), INK, 3.0)
	var playing: bool = game.phase == "play"
	_panel("hero", playing, true, func(): _draw_hero_card(h, fr))
	_panel("skills", h.skills.size() + h.general.size() > 0, true, func(): _draw_skills(h, fr))
	_panel("fruits", h.fruits.size() > 0 or h.shield_hits > 0, true, func(): _draw_fruits(h, fr))
	_panel("goals", playing and game.time > 3.0, true, func(): _draw_goals(h, fr))
	var q_vis: bool = playing and (not game.first_run or game.time >= game.EVENT_SLOTS[0] - 25.0)
	_panel("queue", q_vis, true, func(): _draw_queue(fr))
	_panel("timer", playing, false, func(): _draw_top(h, fr))
	_panel("thoughts", game.thoughts.size() > 1 and game.time > 1.0, false, func(): _draw_thoughts(fr))
	_panel("hands", playing, false, func(): _draw_buttons(h, fr))
	_draw_banners()
	_draw_vignettes(h)
	for f in game.fx:
		if f["kind"] == "event_card":
			_draw_event_card(f)
		elif f["kind"] == "reward_fly":
			_draw_reward_fly(f)
	if game.hint_t > 0.0 and game.over == "":
		var a := clampf(game.hint_t, 0.0, 1.0)
		var w := minf(Art.text_w(font, game.hint, 18) + 30.0, 1200.0)
		var r := Rect2(Vector2(960 - w * 0.5, 1012), Vector2(w, 34))
		Art.card(self, r, Color(1, 0.97, 0.88, 0.95 * a), fr + 9, Color(INK, a), 2.0)
		_t(r.position + Vector2(15, 23), game.hint, 18, Color(INK, a))
	if game.paused:
		_overlay("Пауза", "Пробел — продолжить · M — звук")
	if game.over != "":
		_draw_end()
	_draw_paw(fr)


func _panel(name: String, visible: bool, from_left: bool, fn: Callable) -> void:
	var dx := _slide(name, visible, from_left)
	if is_nan(dx):
		return
	draw_set_transform(Vector2(dx, 0))
	fn.call()
	draw_set_transform(Vector2.ZERO)


# ---------- левая полоса ----------

func _draw_hero_card(h: Hero, fr: int) -> void:
	Art.card(self, Rect2(10, 10, 320, 218), PANEL, fr)
	_t(Vector2(24, 40), "Кеша", 24)
	_t(Vector2(94, 39), "упрямый коллекционер", 14, Color(INK, 0.65))
	_t(Vector2(24, 64), "Уровень %d" % h.level, 16)
	_bar(Rect2(120, 52, 196, 12), float(h.xp) / float(h.xp_next), Color("f2cd5c"), "")
	_bar(Rect2(24, 74, 292, 20), h.hp_frac(), C_HP if h.hp_frac() >= 0.2 else Color("d95c4a"), "Здоровье %d/%d" % [int(ceil(h.hp)), int(h.max_hp())])
	_bar(Rect2(24, 100, 292, 15), h.stress, C_STRESS, "Стресс")
	_bar(Rect2(24, 120, 292, 15), h.greed, C_GREED, "Жадность")
	if h.greed > h.stress:
		_t(Vector2(244, 132), "рискует", 12, Color("9a6a10"))
	_t(Vector2(24, 160), "Режим: " + String(Hero.MODE_NAMES[h.mode]), 16)
	_t(Vector2(24, 184), "Смотрит на %d из 3" % h.focus.size() + (" · слоты заморожены" if h.choosing else ""), 13, Color("4f79a8"))
	var mem := "Забегов в памяти: %d" % h.learned_runs if h.learned_runs > 0 else "Первый забег: память пуста"
	_t(Vector2(24, 208), mem, 13, Color(INK, 0.6))


func _draw_skills(h: Hero, fr: int) -> void:
	Art.card(self, Rect2(10, 236, 320, 206), PANEL, fr + 1)
	_t(Vector2(24, 260), "Умения", 16)
	_t(Vector2(174, 260), "Пассивки", 16)
	var keys: Array = h.skills.keys()
	for i in 3:
		var y := 300.0 + i * 50.0
		if i < keys.size():
			var k: String = keys[i]
			Icons.draw(self, k, Vector2(42, y), 42.0)
			_pips(Vector2(68, y - 4), int(h.skills[k]), Skills.MAX_SKILL_LVL)
			if h.mods.has(k):
				Icons.draw(self, h.mods[k], Vector2(128, y), 34.0)
			else:
				_slot(Vector2(128, y), 30.0)
		else:
			_slot(Vector2(42, y), 38.0)
	var gk: Array = h.general.keys()
	for i in 3:
		var y := 300.0 + i * 50.0
		if i < gk.size():
			Icons.draw(self, gk[i], Vector2(194, y), 42.0)
			_pips(Vector2(220, y - 4), int(h.general[gk[i]]), Skills.MAX_GEN_LVL)
		else:
			_slot(Vector2(194, y), 38.0)
	var hover := _hover_skill(keys, gk, h)
	if hover != "":
		_t(Vector2(24, 434), "%s: %s" % [Skills.NAMES[hover], Skills.DESC[hover]], 13, Color(INK, 0.8))


func _draw_fruits(h: Hero, fr: int) -> void:
	Art.card(self, Rect2(10, 450, 320, 84), PANEL, fr + 2)
	_t(Vector2(24, 474), "Фрукты (ест сам)", 16)
	for i in 3:
		var c := Vector2(48 + i * 56, 506)
		if i < h.fruits.size():
			Icons.draw(self, h.fruits[i], c, 44.0)
		else:
			_slot(c, 40.0)
	if h.fruits.size() > 0:
		_t(Vector2(206, 500), Skills.FRUIT_DESC[h.fruits[0]], 12, Color(INK, 0.7))
	if h.shield_hits > 0:
		_t(Vector2(206, 516), "щит: %d" % h.shield_hits, 12, Color("9a8a10"))


func _draw_goals(h: Hero, fr: int) -> void:
	Art.card(self, Rect2(10, 542, 320, 114), PANEL, fr + 3)
	_t(Vector2(24, 566), "Цели героя", 16)
	var dead: bool = game.over == "hero_dead"
	_goal(Vector2(24, 590), "Выжить 5:00", game.over == "survived", dead)
	_goal(Vector2(24, 614), "Открыть 2 кормушки: %d/2" % mini(h.chests_opened, 2), h.chests_opened >= 2, dead and h.chests_opened < 2, game.last_chance() > 0.0)
	_goal(Vector2(24, 638), "Пройти 3 ивента: %d/3" % mini(h.events_done, 3), h.events_done >= 3, (dead and h.events_done < 3) or game.events_denied >= 2, game.last_chance() > 0.0)


func _hover_skill(keys: Array, gk: Array, h: Hero) -> String:
	var p: Vector2 = game.paw["pos"]
	for i in keys.size():
		if p.distance_to(Vector2(42, 300 + i * 50)) < 21.0:
			return keys[i]
		if h.mods.has(keys[i]) and p.distance_to(Vector2(128, 300 + i * 50)) < 18.0:
			return h.mods[keys[i]]
	for i in gk.size():
		if p.distance_to(Vector2(194, 300 + i * 50)) < 21.0:
			return gk[i]
	return ""


func _pips(p: Vector2, n: int, mx: int) -> void:
	for k in mx:
		var c := p + Vector2(k * 10, 0)
		draw_circle(c, 3.5, Color("e0a92e") if k < n else Color(0, 0, 0, 0.12))
		draw_arc(c, 3.5, 0, TAU, 8, INK, 1.0)


func _slot(c: Vector2, s: float) -> void:
	var r := Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s))
	draw_rect(r, Color(0, 0, 0, 0.05))
	draw_dashed_line(r.position, Vector2(r.end.x, r.position.y), Color(INK, 0.35), 1.5, 4.0)
	draw_dashed_line(Vector2(r.end.x, r.position.y), r.end, Color(INK, 0.35), 1.5, 4.0)
	draw_dashed_line(r.end, Vector2(r.position.x, r.end.y), Color(INK, 0.35), 1.5, 4.0)
	draw_dashed_line(Vector2(r.position.x, r.end.y), r.position, Color(INK, 0.35), 1.5, 4.0)


func _goal(p: Vector2, s: String, done: bool, failed: bool, blink: bool = false) -> void:
	var col := INK
	if blink and not done and int(Time.get_ticks_msec() / 300) % 2 == 0:
		col = Color("b23a2e")
	draw_rect(Rect2(p + Vector2(0, -12), Vector2(12, 12)), INK, false, 1.5)
	if done:
		draw_line(p + Vector2(2, -6), p + Vector2(5, -2), Color("4f8f3a"), 2.5)
		draw_line(p + Vector2(5, -2), p + Vector2(11, -12), Color("4f8f3a"), 2.5)
	_t(p + Vector2(20, 0), s, 15, col)
	if failed and not done:
		_t(p + Vector2(222, 0), "СОРВАНО", 14, Color("b23a2e"))


# ---------- очередь ивентов ----------

func queue_row_rect(i: int) -> Rect2:
	return Rect2(18, QUEUE_Y + 34 + i * QUEUE_ROW, 304, QUEUE_ROW - 8)


func queue_press(p: Vector2) -> Dictionary:
	if not _shown.has("queue"):
		return {}
	for i in game.queue.size():
		if queue_row_rect(i).has_point(p):
			if game.queue_locked(i):
				game.sfx("fail", -12.0, 1.5)
				return {}
			game.sfx("tick")
			return {"from": i, "grab": p - queue_row_rect(i).position}
	return {}


func queue_release(d: Dictionary, p: Vector2) -> void:
	for i in game.queue.size():
		var r := queue_row_rect(i)
		if p.y >= r.position.y - 4 and p.y <= r.end.y + 4:
			game.move_queue(int(d["from"]), i)
			return


func _draw_queue(fr: int) -> void:
	var box := Rect2(10, QUEUE_Y, 320, 394)
	Art.card(self, box, PANEL, fr + 4)
	_t(Vector2(24, QUEUE_Y + 24), "Ивенты (перетащите)", 16)
	var dragging: Dictionary = game.drag
	var cur := _active_row()
	for i in game.queue.size():
		if not dragging.is_empty() and int(dragging["from"]) == i:
			continue
		_queue_row(i, queue_row_rect(i), fr, i == cur)
	var br := Rect2(18, QUEUE_Y + 34 + game.queue.size() * QUEUE_ROW, 304, QUEUE_ROW - 8)
	Art.card(self, br, Color("e8e2dc"), fr + 9, INK, 2.0)
	Icons.draw(self, "boss", br.position + Vector2(32, br.size.y * 0.5), 44.0)
	_t(br.position + Vector2(62, 26), Skills.EVENT_NAMES["boss"], 16)
	_t(br.position + Vector2(62, 46), "в %s · не двигается" % mmss(game.BOSS_AT), 13, Color(INK, 0.65))
	if not dragging.is_empty():
		var i: int = dragging["from"]
		var p: Vector2 = game.paw["pos"]
		var r := Rect2(p - Vector2(dragging["grab"]), queue_row_rect(i).size)
		_queue_row(i, r, fr, false, true)


func _active_row() -> int:
	if game.event.is_empty():
		return -1
	return int(game.event.get("qi", -1))


func _queue_row(i: int, r: Rect2, fr: int, active: bool, lifted: bool = false) -> void:
	var q: Dictionary = game.queue[i]
	var type: String = q["type"]
	var locked: bool = game.queue_locked(i)
	var done: bool = q.has("done")
	var fill := Color(1, 0.96, 0.86) if not locked else Color("ece6dc")
	if active:
		fill = Color("ffe9b0")
	if lifted:
		fill = Color(1, 0.93, 0.7)
		draw_rect(Rect2(r.position + Vector2(6, 6), r.size), Color(0, 0, 0, 0.15))
	Art.card(self, r, fill, fr + i, INK, 3.0 if lifted or active else 2.0)
	var a := 0.45 if done and not active else 1.0
	Icons.draw(self, type, r.position + Vector2(32, r.size.y * 0.5), 44.0 + (4.0 * sin(Time.get_ticks_msec() * 0.008) if active else 0.0), a)
	_t(r.position + Vector2(62, 26), Skills.EVENT_NAMES[type], 16, Color(INK, a))
	var at: float = q["at"]
	var sub := "в %s" % mmss(at)
	if active:
		sub = "идёт: %d с" % int(ceil(float(game.event["left"])))
	elif done:
		match String(q.get("result", "")):
			"ok":
				sub = "герой прошёл"
			"fail":
				sub = "СОРВАНО"
			"skip":
				sub = "герой не рискнул"
			_:
				sub = "прошёл"
	elif locked:
		sub = "через %d с · зафиксирован" % int(ceil(at - game.time))
	_t(r.position + Vector2(62, 46), sub, 13, Color(INK, 0.65 * a))
	if not locked:
		for k in 3:
			draw_line(r.position + Vector2(r.size.x - 26, 22 + k * 7), r.position + Vector2(r.size.x - 12, 22 + k * 7), Color(INK, 0.4), 2.0)
	if game.paw["pos"].distance_to(r.get_center()) < 60.0 and game.drag.is_empty():
		_t(Vector2(24, QUEUE_Y + 386), Skills.EVENT_DESC[type], 13, Color(INK, 0.75))


# ---------- правая полоса ----------

func _draw_top(h: Hero, fr: int) -> void:
	var x := RIGHT.position.x
	Art.card(self, Rect2(x + 10, 10, 320, 150), PANEL, fr + 5)
	var left: float = game.RUN_LENGTH - game.time
	Art.text_c(self, font, Vector2(x + 170, 58), mmss(left), 44, INK if left > 30.0 else Color("b23a2e"))
	Art.text_c(self, font, Vector2(x + 170, 80), "до конца забега", 13, Color(INK, 0.6))
	var nxt: float = game.next_horde - game.time
	Art.text_c(self, font, Vector2(x + 170, 106), "Орда: уровень %d · гонг через %s" % [game.horde_level, mmss(nxt)], 15, Color("3f6fb5"))
	var hero_p := h.power() * 2.0 + float(h.level)
	var horde_p: float = float(game.horde_level) * 4.0 + game.player_damage / 20.0 + 2.0
	var k: float = hero_p / (hero_p + horde_p)
	var bar := Rect2(x + 26, 122, 288, 16)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * k, bar.size.y)), Color("9fd28c"))
	draw_rect(Rect2(bar.position + Vector2(bar.size.x * k, 0), Vector2(bar.size.x * (1.0 - k), bar.size.y)), Color("a7bfe6"))
	draw_rect(bar, INK, false, 1.5)
	draw_line(Vector2(bar.position.x + bar.size.x * k, bar.position.y - 4), Vector2(bar.position.x + bar.size.x * k, bar.end.y + 4), INK, 3.0)
	_t(Vector2(x + 28, 152), "мощь героя", 11)
	_t(Vector2(x + 254, 152), "мощь орды", 11)


func _draw_thoughts(fr: int) -> void:
	var x := RIGHT.position.x
	Art.card(self, Rect2(x + 10, 168, 320, 360), PANEL, fr + 6)
	_t(Vector2(x + 24, 194), "Мысли героя", 16)
	var y := 220.0
	var i := 0
	for th in game.thoughts:
		if y > 512.0:
			break
		var a := 1.0 - i * 0.07
		var s: String = th["text"]
		var lines := 1 if Art.text_w(font, s, 14) < 290.0 else 2
		draw_multiline_string(font, Vector2(x + 24, y), s, HORIZONTAL_ALIGNMENT_LEFT, 296, 14, 2, Color(INK, a))
		y += 18.0 * lines + 6.0
		i += 1


const BTN := {
	"throw": ["grab", "Рогатка", "ЛКМ/ПКМ", "носок, тапок: оттяни и отпусти"],
	"ram": ["ram", "Таран лапкой", "мышь", "резкий взмах в попугая"],
	"millet": ["millet", "Подмена проса", "ЛКМ", "клик по колоску"],
	"book": ["book", "Книга с полки", "Q", "тень 1,2 с, −15% здоровья"],
	"basket": ["basket", "Корзина белья", "W", "носки и тапки у стены"],
}


func _draw_buttons(h: Hero, fr: int) -> void:
	var x := RIGHT.position.x
	var edge: bool = h.hp_frac() < 0.2 and game.over == ""
	var vis: Array = []
	for k in game.ABILITY_ORDER:
		if game.ability_visible(k):
			vis.append(k)
	var height := 50.0 + vis.size() * 74.0
	Art.card(self, Rect2(x + 10, 536, 320, height), PANEL, fr + 7)
	_t(Vector2(x + 24, 560), "Ваши руки", 16)
	var y := 572.0
	for k in vis:
		var dx := _slide("btn_" + k, true, false)
		draw_set_transform(Vector2(dx, 0))
		_ability(k, Vector2(x + 20, y), edge)
		draw_set_transform(Vector2.ZERO)
		y += 74.0
	_t(Vector2(x + 24, 990), "Пробел пауза · M звук · R заново", 13, Color(INK, 0.6))
	_t(Vector2(x + 24, 1010), "F2 ускорить ×3 · F3 мысли ИИ", 13, Color(INK, 0.6))
	_t(Vector2(x + 24, 1030), "Esc отмена меню", 13, Color(INK, 0.6))


func _ability(k: String, p: Vector2, edge: bool) -> void:
	var info: Array = BTN[k]
	var on: bool = game.ability_unlocked(k)
	var cd := 0.0
	var cd_max := 1.0
	var sub: String = info[3]
	match k:
		"throw":
			cd = game.throw_cd
			cd_max = game.THROW_CD
		"ram":
			cd = game.paw_bruise
			cd_max = game.PAW_BRUISE
			if not on:
				sub = "откроется через %s" % mmss(game.RAM_UNLOCK - game.time)
		"millet":
			cd = game.millet_cd
			cd_max = game.MILLET_CD
			if not on:
				sub = "ждёт первый крупный колосок"
		"book":
			cd = game.meteor_cd
			cd_max = game.METEOR_CD
			if not on:
				sub = "откроется через %s" % mmss(game.BOOK_UNLOCK - game.time)
		"basket":
			cd = game.wave_cd
			cd_max = game.WAVE_CD
			if not on:
				sub = "откроется через %s" % mmss(game.WAVE_UNLOCK - game.time)
	_button(p, info[0], info[1], info[2], sub, cd, cd_max, on, edge and k != "throw")


func _button(p: Vector2, icon: String, title: String, key: String, sub: String, cd: float, cd_max: float, unlocked: bool, glow: bool) -> void:
	var r := Rect2(p, Vector2(300, 66))
	var ready := unlocked and cd <= 0.0
	var fill := Color(1, 0.97, 0.9) if ready else Color(0.9, 0.88, 0.84)
	Art.card(self, r, fill, Art.frame() + icon.hash() % 31, INK, 2.0)
	if not ready and unlocked and cd_max > 0.0:
		draw_rect(Rect2(r.position + Vector2(3, 3), Vector2((r.size.x - 6) * (1.0 - cd / cd_max), r.size.y - 6)), Color(0.6, 0.5, 0.85, 0.18))
	if glow and ready:
		var a := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.012)
		Art.outline(self, Art.wobbly_rect(r.grow(4), Art.frame() + 5, 1.0), Color(0.9, 0.3, 0.2, a), 3.0)
	Icons.draw(self, icon, r.position + Vector2(34, 33), 50.0, 1.0 if unlocked else 0.4)
	_t(r.position + Vector2(68, 26), title, 17, INK if unlocked else Color(INK, 0.5))
	var kw := Art.text_w(font, key, 13) + 12.0
	var kr := Rect2(Vector2(r.end.x - kw - 8, r.position.y + 8), Vector2(kw, 20))
	draw_rect(kr, Color(1, 1, 1, 0.8))
	draw_rect(kr, INK, false, 1.5)
	_t(kr.position + Vector2(6, 15), key, 13)
	var sub_txt := sub
	if unlocked and cd > 0.0:
		sub_txt = "%s · %.0f с" % [sub, ceil(cd)]
	_t(r.position + Vector2(68, 50), sub_txt, 13, Color(INK, 0.7))


# ---------- поверх поля ----------

func _draw_event_card(f: Dictionary) -> void:
	var t: float = f["t"]
	var k := clampf(t / 0.3, 0.0, 1.0)
	var a := k * (1.0 - clampf((t - 2.4) / 0.6, 0.0, 1.0))
	var sc := 0.7 + 0.3 * (1.0 - pow(1.0 - k, 3.0))
	var c := Vector2(960, 290)
	var r := Rect2(c - Vector2(260, 80) * sc, Vector2(520, 160) * sc)
	Art.card(self, r, Color(1, 0.95, 0.8, 0.97 * a), Art.frame(), Color(INK, a), 3.0)
	for i in 10:
		var ang := TAU * i / 10.0 + Time.get_ticks_msec() * 0.001
		Icons._star(self, c + Vector2(cos(ang) * 290.0, sin(ang) * 100.0) * sc, 6.0, Color("f6d84c"), a)
	var type: String = f["type"]
	Icons.draw(self, type, r.position + Vector2(64, 80) * sc, 84.0 * sc, a)
	_t(r.position + Vector2(120, 50) * sc, "Ивент: " + String(Skills.EVENT_NAMES[type]), int(26 * sc), Color(0.55, 0.35, 0.05, a))
	_t(r.position + Vector2(120, 82) * sc, Skills.EVENT_DESC[type], int(17 * sc), Color(INK, a))
	_t(r.position + Vector2(120, 122) * sc, "Награда герою:", int(17 * sc), Color(INK, 0.8 * a))
	Icons.draw(self, f["fruit"], r.position + Vector2(300, 116) * sc, 40.0 * sc, a)
	_t(r.position + Vector2(328, 122) * sc, "+ опыт   ·   сорвите!", int(17 * sc), Color(0.7, 0.2, 0.15, a))


func _draw_reward_fly(f: Dictionary) -> void:
	var k: float = clampf(float(f["t"]) / float(f["dur"]), 0.0, 1.0)
	var a: Vector2 = f["pos"]
	var b: Vector2 = f["to"]
	var mid := a.lerp(b, 0.5) + Vector2(0, -220)
	var p := a.lerp(mid, k).lerp(mid.lerp(b, k), k)
	Art.fill_blob(self, p, 30, 30, Color(1, 0.9, 0.4, 0.4 * (1.0 - k * 0.5)))
	Icons.draw(self, f["fruit"], p, 46.0 + 10.0 * sin(k * PI), 1.0)


func _draw_banners() -> void:
	var y := 150.0
	for b in game.banners:
		var t: float = b["t"]
		var d: float = b["dur"]
		var a := clampf(t / 0.15, 0.0, 1.0) * (1.0 - clampf((t - (d - 0.4)) / 0.4, 0.0, 1.0))
		var sc := 1.0 + 0.25 * maxf(0.0, 1.0 - t / 0.2)
		var col: Color = b["color"]
		col.a = a
		Art.text_c(self, font, Vector2(960, y), b["text"], int(float(b["size"]) * sc), col, Color(1, 0.98, 0.93, a), 8)
		y += float(b["size"]) + 14.0


func _draw_vignettes(h: Hero) -> void:
	var f: Rect2 = game.FIELD
	if game.over == "" and game.phase == "play" and h.hp_frac() < 0.2:
		var a := 0.18 + 0.12 * sin(Time.get_ticks_msec() * 0.012)
		_frame(f, Color(0.85, 0.15, 0.1, a), 26.0)
		Art.text_c(self, font, Vector2(960, 110), "На волоске!", 28, Color(0.75, 0.15, 0.1, 0.9), Color(1, 0.97, 0.9, 0.9), 6)
	if game.power_flash > 0.0:
		_frame(f, Color(0.75, 0.1, 0.08, game.power_flash), 60.0)


func _frame(f: Rect2, col: Color, w: float) -> void:
	draw_rect(Rect2(f.position, Vector2(f.size.x, w)), col)
	draw_rect(Rect2(Vector2(f.position.x, f.end.y - w), Vector2(f.size.x, w)), col)
	draw_rect(Rect2(f.position + Vector2(0, w), Vector2(w, f.size.y - 2 * w)), col)
	draw_rect(Rect2(Vector2(f.end.x - w, f.position.y + w), Vector2(w, f.size.y - 2 * w)), col)


func _overlay(title: String, sub: String) -> void:
	draw_rect(game.FIELD, Color(0.2, 0.15, 0.1, 0.35))
	var r := Rect2(720, 470, 480, 140)
	Art.card(self, r, PANEL, Art.frame())
	Art.text_c(self, font, Vector2(960, 528), title, 38, INK)
	Art.text_c(self, font, Vector2(960, 572), sub, 17, Color(INK, 0.7))


func _draw_end() -> void:
	var o: Dictionary = game.outro
	if not o.is_empty() and not bool(o["done"]):
		# сначала — забрать яйцо или перья
		var t: float = o["t"]
		if t > 1.2:
			var msg := "Кликните по яйцу: награда и вам, и попугаю" if game.over == "hero_dead" else "Кеша улетел. Соберите выпавшие перья"
			Art.text_c(self, font, Vector2(960, 230), msg, 24, Color("8a5a1e"), Color(1, 0.98, 0.9, 0.95), 8)
		return
	draw_rect(game.FIELD, Color(0.2, 0.15, 0.1, 0.4))
	var r := Rect2(560, 150, 800, 780)
	Art.card(self, r, PANEL, Art.frame(), INK, 3.0)
	var h: Hero = game.hero
	if game.over == "hero_dead":
		Art.text_c(self, font, Vector2(960, 212), "Попался!", 46, Color("b23a2e"))
		Art.text_c(self, font, Vector2(960, 248), "Кеша повержен на %s" % mmss(game.time), 20, INK)
	else:
		Art.text_c(self, font, Vector2(960, 212), "Кеша выжил", 46, Color("4f8f3a"))
		Art.text_c(self, font, Vector2(960, 248), "Все 5 минут. В следующий раз ловите его на жадности.", 18, INK)
	var y := 290.0
	if not o.is_empty() and o["reward"].size() == 2:
		Art.card(self, Rect2(600, y - 22, 720, 104), Color(1, 0.95, 0.8), Art.frame() + 2, INK, 2.0)
		Art.text_c(self, font, Vector2(960, y + 2), "Из яйца — награда обоим:", 17, Color(INK, 0.7))
		Art.text_c(self, font, Vector2(960, y + 32), "Попугаю: " + String(o["reward"][0]), 17, Color("4f8f3a"))
		Art.text_c(self, font, Vector2(960, y + 60), "Вам: " + String(o["reward"][1]), 17, Color("6a4fb3"))
		y += 112.0
	var stats := [
		"Ваш урон по герою: %d · загоны: %d · перьев всего: %d" % [int(game.player_damage), game.combos, int(game.save.get("feathers", 0))],
		"Книги %d/%d · тараны %d · броски в цель %d · подмены %d · сорвано ивентов %d" % [game.meteor_hits, game.meteors_cast, game.rams, game.throws_hit, game.tricks, game.events_denied],
		"Герой: уровень %d · ивентов %d · пылесос %s" % [h.level, h.events_done, "сломан" if game.boss_defeated else "цел"],
	]
	for s in stats:
		Art.text_c(self, font, Vector2(960, y), s, 16, INK)
		y += 26.0
	y += 12.0
	_t(Vector2(600, y), "Что по Кеше било (за забег)", 17)
	_t(Vector2(980, y), "Чем бил Кеша", 17)
	y += 8.0
	_shares_list(Vector2(600, y), game.dmg_by_src, Hero.SRC_TEXT, Color("c25b4a"))
	_shares_list(Vector2(980, y), game.dealt_by_src, Skills.NAMES, Color("4f8f3a"))
	y += 170.0
	_t(Vector2(600, y), "Кеша запомнил (учится из забега в забег)", 17, Color("4f79a8"))
	y += 24.0
	var mem: Dictionary = game.save.get("memory", {})
	var notes := _memory_lines(mem)
	for s in notes:
		_t(Vector2(600, y), "· " + s, 15, Color(INK, 0.85))
		y += 22.0
	Art.text_c(self, font, Vector2(960, 905), "R — новый забег", 18, Color(INK, 0.7))


func _shares_list(p: Vector2, d: Dictionary, names: Dictionary, col: Color) -> void:
	var tot := 0.0
	for k in d:
		tot += float(d[k])
	if tot <= 0.0:
		_t(p + Vector2(0, 22), "—", 15, Color(INK, 0.5))
		return
	var keys := d.keys()
	keys.sort_custom(func(a, b): return float(d[a]) > float(d[b]))
	for i in mini(6, keys.size()):
		var k: String = keys[i]
		var sh := float(d[k]) / tot
		var y := p.y + 20.0 + i * 24.0
		draw_rect(Rect2(p.x, y - 13, 150.0 * sh, 16), Color(col, 0.35))
		_t(Vector2(p.x + 4, y), "%s  %d%%" % [String(names.get(k, k)), int(round(sh * 100.0))], 14)


func _memory_lines(mem: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var taken: Dictionary = mem.get("taken", {})
	var dealt: Dictionary = mem.get("dealt", {})
	if taken.is_empty():
		out.append("пока ничего — память наполнится после этого забега")
		return out
	var tk := taken.keys()
	tk.sort_custom(func(a, b): return float(taken[a]) > float(taken[b]))
	var parts: Array[String] = []
	for k in tk.slice(0, 3):
		parts.append("%s %d%%" % [String(Hero.SRC_TEXT.get(k, k)), int(round(float(taken[k]) * 100.0))])
	out.append("чаще всего бьют: " + ", ".join(parts) + " — следит за этим внимательнее")
	var dk := dealt.keys()
	dk.sort_custom(func(a, b): return float(dealt[a]) > float(dealt[b]))
	var best: Array[String] = []
	for k in dk:
		if k != "peck" and best.size() < 2:
			best.append(String(Skills.NAMES.get(k, k)))
	if best.size() > 0:
		out.append("лучше всего заходят: " + ", ".join(best) + " — будет брать охотнее")
	var trick := float(taken.get("trap", 0.0)) + float(taken.get("rotten", 0.0)) + float(taken.get("missile", 0.0))
	if trick > 0.05:
		out.append("крупное просо подозрительное — доверяет ему меньше")
	out.append("забегов в памяти: %d" % int(mem.get("runs", 0)))
	return out


func _draw_paw(fr: int) -> void:
	var off: Vector2 = game.world.position
	for tr in game.paw_trail:
		var a := clampf(float(tr["t"]) / 0.3, 0.0, 1.0)
		draw_line(Vector2(tr["a"]) + off, Vector2(tr["b"]) + off, Color(INK, 0.35 * a), 2.0, true)
	var p: Vector2 = game.paw["pos"] + off
	var bruised: bool = game.paw_bruise > 0.0
	var holding: bool = game.held_e != null
	var m := get_global_mouse_position()
	if bruised:
		draw_dashed_line(p, m, Color(INK, 0.35), 1.5, 6.0)
		draw_circle(m, 3.0, Color(INK, 0.4))
	if holding:
		# рогатка: резинка от предмета к лапке, стрелка — куда и как сильно полетит
		var anc: Vector2 = game.sling_anchor + off
		var nrm := (p - anc).normalized().rotated(PI * 0.5) * 14.0
		draw_line(anc + nrm, p, Color("8a5a3a"), 3.0, true)
		draw_line(anc - nrm, p, Color("8a5a3a"), 3.0, true)
		var v: Vector2 = game.throw_vector()
		if v != Vector2.ZERO:
			var power: float = v.length() / game.SOCK_SPEED
			var end: Vector2 = anc + v.normalized() * (50.0 + 220.0 * power)
			var col := Color(0.42, 0.31, 0.7).lerp(Color(0.9, 0.35, 0.1), power)
			draw_dashed_line(anc, end, Color(col, 0.9), 3.0 + 3.0 * power, 10.0)
			draw_polyline(PackedVector2Array([end + v.normalized().rotated(2.5) * 16.0, end, end + v.normalized().rotated(-2.5) * 16.0]), col, 4.0)
		var k: float = clampf(game.hold_t / game.HOLD_TIME, 0.0, 1.0)
		var br := Rect2(p + Vector2(-26, -44), Vector2(52, 7))
		draw_rect(br, Color(1, 1, 1, 0.85))
		draw_rect(Rect2(br.position, Vector2(br.size.x * k, br.size.y)), Color("e0a92e") if k > 0.35 else Color("d95c4a"))
		draw_rect(br, INK, false, 1.5)
	var fill := Color("d9dbe8") if bruised else Color("fffaf2")
	var sd := 77 + fr
	# поджатые пальцы: идёт откат броска или лапка держит носок
	var curl := 0.0
	if holding:
		curl = 4.0
	elif game.throw_cd > 0.0:
		curl = 2.0 + 2.0 * clampf(game.throw_cd / game.THROW_CD, 0.0, 1.0)
	var toes := [Vector2(-13, -10), Vector2(-5, -17), Vector2(5, -17), Vector2(13, -10)]
	for k in 4:
		var tp: Vector2 = p + Vector2(toes[k]) * (1.0 - curl * 0.05) + Vector2(0, curl)
		Art.blob(self, tp, 5.5, 6.0 - curl * 0.3, fill, 3.0, sd + k)
		draw_circle(tp + Vector2(0, 1), 2.4, Color("f3a7b5"))
	Art.blob(self, p + Vector2(0, 4), 15.0, 12.5, fill, 3.0, sd)
	Art.fill_blob(self, p + Vector2(0, 6), 7.0, 5.5, Color("f3a7b5"))
	if bruised:
		for k in 3:
			var a := Time.get_ticks_msec() * 0.006 + k * TAU / 3.0
			var sp := p + Vector2(cos(a) * 20.0, -24 + sin(a) * 6.0)
			draw_circle(sp, 2.5, Color("f6cd56"))
			draw_arc(sp, 2.5, 0, TAU, 8, INK, 1.0)
	elif game.time >= game.RAM_UNLOCK and game.paw_vel.length() > game.RAM_SPEED and not holding:
		draw_arc(p + Vector2(0, -2), 26.0, 0, TAU, 24, Color(0.42, 0.31, 0.7, 0.6), 2.5, true)
