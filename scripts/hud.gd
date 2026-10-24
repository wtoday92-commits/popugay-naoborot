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
const QUEUE_Y := 598.0
const QUEUE_ROW := 74.0
const APPEAR := 0.45

var game
var font: Font
var _shown := {}
## Штаб: открытая вкладка и выбранное умение в деревьях.
var hq_tab := "trees"
## Сундук на экране меты: расцветки лапки и проклятия.
var chest_open := false
var hq_abil := "throw"


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
	var q_vis: bool = playing and game.queue.size() > 0 and (not game.first_run or game.time >= game.EVENT_SLOTS[0] - 25.0)
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
	Art.card(self, Rect2(10, 10, 320, 168), PANEL, fr)
	var nm := String(Parrots.bird(h.bird)["name"])
	_t(Vector2(24, 40), nm, 24)
	_t(Vector2(34 + Art.text_w(font, nm, 24), 39), "уровень %d" % h.level, 16, Color(INK, 0.7))
	_bar(Rect2(24, 50, 292, 8), float(h.xp) / float(h.xp_next), Color("f2cd5c"), "")
	_bar(Rect2(24, 66, 292, 22), h.hp_frac(), C_HP if h.hp_frac() >= 0.2 else Color("d95c4a"), "Здоровье %d/%d" % [int(ceil(h.hp)), int(h.max_hp())])
	_bar(Rect2(24, 94, 292, 14), h.stress, C_STRESS, "Стресс")
	_t(Vector2(24, 134), String(Hero.MODE_NAMES[h.mode]).capitalize(), 17)
	# внимание: точки по числу слотов, закрашены занятые
	_t(Vector2(24, 160), "внимание", 13, Color("4f79a8"))
	for i in h.slots:
		var c := Vector2(100 + i * 16, 155)
		draw_circle(c, 5.0, Color("4f79a8") if i < h.focus.size() else Color(0, 0, 0, 0.1))
		draw_arc(c, 5.0, 0, TAU, 12, Color("4f79a8"), 1.2)
	if h.plan.size() > 0:
		_t(Vector2(210, 136), "план", 13, Color(INK, 0.6))
		Icons.draw(self, h.plan[0], Vector2(276, 140), 40.0)


func _draw_skills(h: Hero, fr: int) -> void:
	Art.card(self, Rect2(10, 186, 320, 200), PANEL, fr + 1)
	_t(Vector2(24, 210), "Умения", 16)
	_t(Vector2(174, 210), "Пассивки", 16)
	var keys: Array = h.skills.keys()
	for i in 3:
		var y := 248.0 + i * 46.0
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
		var y := 248.0 + i * 46.0
		if i < gk.size():
			Icons.draw(self, gk[i], Vector2(194, y), 42.0)
			_pips(Vector2(220, y - 4), int(h.general[gk[i]]), Skills.MAX_GEN_LVL)
		else:
			_slot(Vector2(194, y), 38.0)
	var hover := _hover_skill(keys, gk, h)
	if hover != "":
		_t(Vector2(24, 380), "%s: %s" % [Skills.NAMES[hover], Skills.DESC[hover]], 13, Color(INK, 0.8))


func _draw_fruits(h: Hero, fr: int) -> void:
	Art.card(self, Rect2(10, 394, 320, 84), PANEL, fr + 2)
	_t(Vector2(24, 418), "Фрукты (ест сам)", 16)
	for i in 3:
		var c := Vector2(48 + i * 56, 450)
		if i < h.fruits.size():
			Icons.draw(self, h.fruits[i], c, 44.0)
		else:
			_slot(c, 40.0)
	if h.fruits.size() > 0:
		draw_multiline_string(font, Vector2(206, 440), Skills.FRUIT_DESC[h.fruits[0]], HORIZONTAL_ALIGNMENT_LEFT, 116, 12, 2, Color(INK, 0.7))
	if h.shield_hits > 0:
		_t(Vector2(206, 460), "щит: %d" % h.shield_hits, 12, Color("9a8a10"))


func _draw_goals(h: Hero, fr: int) -> void:
	Art.card(self, Rect2(10, 486, 320, 104), PANEL, fr + 3)
	_t(Vector2(24, 510), "Цели", 16)
	var dead: bool = game.over == "hero_dead"
	_goal(Vector2(24, 534), "Сломать пылесос", game.boss_defeated, dead)
	var y := 558.0
	for q in h.quests:
		var info: Dictionary = Meta.quest_by_key(q)
		_goal(Vector2(24, y), String(info.get("name", q)), false, false)
		y += 24.0
	if h.quests.is_empty():
		_t(Vector2(44, 558), "квесты появятся с третьего забега", 13, Color(INK, 0.5))

func _hover_skill(keys: Array, gk: Array, h: Hero) -> String:
	var p: Vector2 = game.paw["pos"]
	for i in keys.size():
		if p.distance_to(Vector2(42, 248 + i * 46)) < 21.0:
			return keys[i]
		if h.mods.has(keys[i]) and p.distance_to(Vector2(128, 248 + i * 46)) < 18.0:
			return h.mods[keys[i]]
	for i in gk.size():
		if p.distance_to(Vector2(194, 248 + i * 46)) < 21.0:
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
	var box := Rect2(10, QUEUE_Y, 320, 44.0 + (game.queue.size() + 1) * QUEUE_ROW + 30.0)
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
		_t(Vector2(24, QUEUE_Y + 34.0 + (game.queue.size() + 1) * QUEUE_ROW + 20.0), Skills.EVENT_DESC[type], 13, Color(INK, 0.75))


# ---------- правая полоса ----------

func _draw_top(h: Hero, fr: int) -> void:
	var x := RIGHT.position.x
	Art.card(self, Rect2(x + 10, 10, 320, 150), PANEL, fr + 5)
	var b: Enemy = game.boss
	if b == null:
		var left: float = game.BOSS_AT - game.time
		Art.text_c(self, font, Vector2(x + 170, 58), mmss(left), 44, INK if left > 30.0 else Color("b23a2e"))
		Art.text_c(self, font, Vector2(x + 170, 80), "до пылесоса · " + String(Diff.level(game.diff)["short"]), 13, Color(Diff.level(game.diff)["color"]))
	elif not b.dead:
		Art.text_c(self, font, Vector2(x + 170, 52), "ПЫЛЕСОС", 34, Color("b23a2e"))
		var enr: bool = game.enraged
		var sub := "в ярости!" if enr else "ярость через %s" % mmss(game.ENRAGE_AT - game.time)
		Art.text_c(self, font, Vector2(x + 170, 80), "здоровье %d%% · %s" % [int(100.0 * b.hp / b.max_hp), sub], 13, Color(INK, 0.7))
	else:
		Art.text_c(self, font, Vector2(x + 170, 58), "сломан", 36, Color("4f8f3a"))
	var nxt: float = game.next_horde - game.time
	Art.text_c(self, font, Vector2(x + 170, 106), "Орда ур. %d · гонг через %s" % [game.horde_level, mmss(nxt)], 14, Color("3f6fb5"))
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
	Art.card(self, Rect2(x + 10, 168, 320, 196), PANEL, fr + 6)
	_t(Vector2(x + 24, 194), "Мысли", 16)
	var y := 220.0
	var i := 0
	for th in game.thoughts:
		if y > 350.0 or i >= 5:
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
	"basket": ["basket", "Клетка", "W", "тень ползёт за лапкой"],
}


func _draw_buttons(h: Hero, fr: int) -> void:
	var x := RIGHT.position.x
	var edge: bool = h.hp_frac() < 0.2 and game.over == ""
	var vis: Array = []
	for k in game.ABILITY_ORDER:
		if game.ability_visible(k):
			vis.append(k)
	var height := 50.0 + vis.size() * 74.0
	Art.card(self, Rect2(x + 10, 372, 320, height), PANEL, fr + 7)
	_t(Vector2(x + 24, 396), "Ваши руки", 16)
	var y := 408.0
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
	if o.has("roll"):
		_draw_roll(o["roll"])
		return
	if not o.is_empty() and not bool(o["done"]):
		# сначала — забрать яйцо или перья
		var t: float = o["t"]
		if t > 1.2:
			var msg := "Кликните по яйцу: награда и вам, и попугаю" if game.over == "hero_dead" else "%s улетел. Соберите выпавшие перья" % String(Parrots.bird(game.hero.bird)["name"])
			Art.text_c(self, font, Vector2(960, 230), msg, 24, Color("8a5a1e"), Color(1, 0.98, 0.9, 0.95), 8)
		return
	_draw_meta()


# ---------- мета: сначала экран попугая, потом выезжает экран игрока ----------

const META_PARROT := Rect2(975, 40, 920, 960)
const META_PLAYER := Rect2(25, 40, 920, 960)
const NEW_RUN := Rect2(810, 1010, 300, 56)
const CHEST_BTN := Rect2(500, 1010, 290, 56)
const CHEST := Rect2(460, 250, 1000, 560)


func _meta_t() -> float:
	return float(game.meta_t)


func _draw_meta() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color(0.93, 0.89, 0.82, 0.96))
	var t := _meta_t()
	var kp := _ease(clampf(t / 0.5, 0.0, 1.0))
	draw_set_transform(Vector2((1.0 - kp) * 900.0, 0))
	_draw_parrot_meta(t)
	draw_set_transform(Vector2.ZERO)
	var kl := _ease(clampf((t - 1.4) / 0.5, 0.0, 1.0))
	if t > 1.4:
		draw_set_transform(Vector2((kl - 1.0) * 900.0, 0))
		_draw_player_meta(t - 1.4)
		draw_set_transform(Vector2.ZERO)
	if t > 2.0:
		var ch: Dictionary = game.save.get("curses", {})
		var n_curses := 0
		for k in ch:
			n_curses += int(ch[k])
		var hc: bool = CHEST_BTN.has_point(game.paw["pos"])
		Art.card(self, CHEST_BTN, Color(1, 0.93, 0.7) if hc or chest_open else PANEL, Art.frame() + 7, INK, 2.5)
		var armed: Array = game.save.get("armed", [])
		var lbl := "Сундук" + (" · проклятий %d" % n_curses if n_curses > 0 else "")
		if armed.size() > 0:
			lbl = "Сундук · взято %d" % armed.size()
		Art.text_c(self, font, CHEST_BTN.get_center() + Vector2(0, 7), lbl, 18, INK)
		if chest_open:
			_draw_chest()
		var hov: bool = NEW_RUN.has_point(game.paw["pos"])
		Art.card(self, NEW_RUN, Color(1, 0.93, 0.7) if hov else PANEL, Art.frame(), INK, 3.0)
		Art.text_c(self, font, NEW_RUN.get_center() + Vector2(0, 8), "Новый забег  [R]", 22, INK)


static func _ease(k: float) -> float:
	var c1 := 1.70158
	return 1.0 + (c1 + 1.0) * pow(k - 1.0, 3.0) + c1 * pow(k - 1.0, 2.0)


func _draw_parrot_meta(t: float) -> void:
	var r := META_PARROT
	Art.card(self, r, PANEL, Art.frame(), INK, 3.0)
	var meta: Dictionary = game.meta
	var last: Dictionary = meta.get("last", {})
	var x := r.position.x + 30
	var y := r.position.y + 50
	var lb := String(last.get("bird", "budgie"))
	_bird_icon(lb, Vector2(x + 26, y - 12), 56.0)
	_t(Vector2(x + 64, y), "%s после забега" % String(Parrots.bird(lb)["name"]), 30)
	var res := "сломал пылесос и улетел" if bool(last.get("won", false)) else "попался"
	_t(Vector2(x + 400, y - 2), res, 20, Color("4f8f3a") if bool(last.get("won", false)) else Color("b23a2e"))
	y += 40
	_t(Vector2(x, y), "Собрал проса: %d · в копилке: %d" % [int(last.get("millet", 0)), int(meta["parrot"]["bank"])], 17)
	y += 30
	# лестница сложностей и выбор Кеши на следующий забег
	var top := Diff.unlocked(meta)
	var nd := Diff.next_diff(meta)
	for d in Diff.LEVELS.size():
		var lv: Dictionary = Diff.LEVELS[d]
		var cr := Rect2(x + d * 150, y, 140, 34)
		var open := d <= top
		var cur := d == nd
		Art.card(self, cr, Color(lv["color"], 0.25) if cur else (PANEL if open else Color(0.9, 0.88, 0.84)), Art.frame() + 100 + d, INK if open else Color(INK, 0.35), 2.5 if cur else 1.4)
		Art.text_c(self, font, cr.get_center() + Vector2(0, 6), String(lv["name"]) if open else "???", 15, INK if open else Color(INK, 0.4))
	var kc := Rect2(x + 450, y, 140, 34)
	Art.card(self, kc, Color(0.9, 0.88, 0.84), Art.frame() + 104, Color(INK, 0.35), 1.4)
	Art.text_c(self, font, kc.get_center() + Vector2(0, 6), "Кухня · скоро", 14, Color(INK, 0.4))
	y += 56
	var dmsg := String(last.get("diff_msg", ""))
	if dmsg != "":
		_t(Vector2(x, y), "★ " + dmsg, 16, Color("b07a1e"))
		y += 24
	_t(Vector2(x, y), "Дальше — %s. %s" % [String(Diff.level(nd)["short"]), String(Diff.data(meta).get("reason", ""))], 15, Color(INK, 0.75))
	y += 30
	# попугаи: кто есть, сколько вложено в его дерево, кто идёт следующим
	var nb := Parrots.next_bird(meta)
	var bx := x
	for b in Parrots.ORDER:
		var have: bool = Parrots.owned(meta).has(b)
		var br := Rect2(bx, y - 4, 200, 56)
		var on: bool = b == nb
		Art.card(self, br, Color(1, 0.93, 0.7) if on else (PANEL if have else Color(0.9, 0.88, 0.84)), Art.frame() + 110, INK if have else Color(INK, 0.3), 2.5 if on else 1.3)
		if have:
			_bird_icon(b, br.position + Vector2(30, 30), 44.0)
			_t(br.position + Vector2(60, 24), String(Parrots.bird(b)["name"]), 15)
			_t(br.position + Vector2(60, 44), "дерево %d/39" % Parrots.bought_total(meta, b) + (" · идёт" if on else ""), 12, Color(INK, 0.6))
		else:
			Art.text_c(self, font, br.get_center() + Vector2(0, 6), "? из яйца", 14, Color(INK, 0.4))
		bx += 210
	y += 70
	var breason := String(Parrots.data(meta).get("reason", ""))
	if breason != "" and Parrots.owned(meta).size() > 1:
		_t(Vector2(x, y + 6), breason, 14, Color(INK, 0.65))
		y += 34
	# квесты прошлого забега
	var qr: Array = last.get("quest_results", [])
	if qr.size() > 0:
		_t(Vector2(x, y), "Квесты забега:", 17)
		y += 26
		for q in qr:
			var info: Dictionary = Meta.quest_by_key(q[0])
			var ok: bool = q[1]
			_t(Vector2(x + 16, y), ("✓ " if ok else "✗ ") + String(info.get("name", q[0])) + ("  +%d проса" % int(info.get("reward", 0)) if ok else ""), 15, Color("4f8f3a") if ok else Color(INK, 0.55))
			y += 22
		y += 8
	# прокачка за просо
	_t(Vector2(x, y), "Прокачал за просо:", 17)
	y += 26
	var bought: Array = last.get("bought", [])
	if bought.is_empty():
		_t(Vector2(x + 16, y), "пока копит", 15, Color(INK, 0.55))
		y += 22
	else:
		_t(Vector2(x + 16, y), ", ".join(bought), 15, Color("4f8f3a"))
		y += 22
	var ach_new: Array = last.get("ach_new", [])
	for line in ach_new:
		_t(Vector2(x + 16, y), "★ " + String(line), 15, Color("b07a1e"))
		y += 22
	y += 6
	# прокачка: только открытые этапы, следующий — подсказкой
	var stage := Meta.parrot_stage(meta)
	var col := 0
	for it in Meta.PARROT:
		if int(it["stage"]) > stage:
			continue
		var lvl := int(meta["parrot"]["up"].get(it["key"], 0))
		var px := x + col * 290
		_t(Vector2(px, y + 18), "%s" % it["name"], 15)
		_bar(Rect2(px, y + 26, 200, 10), float(lvl) / float(it["max"]), Color("e0a92e"), "")
		_t(Vector2(px + 208, y + 36), "%d/%d" % [lvl, int(it["max"])], 12, Color(INK, 0.6))
		col += 1
		if col == 3:
			col = 0
			y += 46
	if col != 0:
		y += 46
	if stage + 1 < Meta.PARROT_STAGES.size():
		_t(Vector2(x, y + 10), "Новые улучшения откроются, когда попугай потратит %d проса (сейчас %d)" % [int(Meta.PARROT_STAGES[stage + 1]), int(meta["parrot"].get("spent", 0))], 14, Color(INK, 0.6))
		y += 26
	# умения, которые Кеша уже знает
	var known := Meta.parrot_skills(meta)
	var names: Array[String] = []
	for k in known:
		names.append(String(Skills.NAMES.get(k, k)))
	draw_multiline_string(font, Vector2(x, y + 14), "Умения попугая: " + ", ".join(names), HORIZONTAL_ALIGNMENT_LEFT, 600, 15, 2, INK)
	var locked := 0
	for sk in Meta.PARROT_SKILLS:
		if not known.has(sk["key"]):
			locked += 1
	if locked > 0:
		_t(Vector2(x + 560, y + 14), "ещё %d — за просо и достижения" % locked, 14, Color(INK, 0.55))
	y += 50
	# достижения: выполненные свёрнуты, видны 4 ближайших
	var st: Dictionary = meta["stats"]
	var done := 0
	var show: Array = []
	for a2 in Meta.ACHIEVEMENTS:
		if float(st.get(a2["stat"], 0)) >= float(a2["target"]):
			done += 1
		elif show.size() < 4:
			show.append(a2)
	_t(Vector2(x, y), "Достижения  %d/%d" % [done, Meta.ACHIEVEMENTS.size()], 17)
	y += 14
	for i in show.size():
		var a3: Dictionary = show[i]
		var v := float(st.get(a3["stat"], 0))
		var k := clampf(v / float(a3["target"]), 0.0, 1.0)
		var ax := x + (i % 2) * 430
		var ay := y + 14 + int(i / 2) * 40
		var rw := ("умение «%s»" % Skills.NAMES[a3["skill"]]) if a3.has("skill") else ("+%d проса" % int(a3["millet"]))
		_t(Vector2(ax, ay + 12), String(a3["name"]), 14)
		_bar(Rect2(ax + 160, ay, 130, 14), k, Color("e8b84a"), "%d/%d" % [int(minf(v, float(a3["target"]))), int(a3["target"])])
		_t(Vector2(ax + 298, ay + 12), rw, 12, Color(INK, 0.6))
	y += 14 + 2 * 40 + 12
	# выбор квестов: 6 на выбор, попугай берёт 2 сам
	var offer: Array = last.get("offer", [])
	if offer.is_empty():
		_t(Vector2(x, y), "Квесты откроются с третьего забега", 17, Color(INK, 0.6))
		return
	_t(Vector2(x, y), "Квесты на следующий забег: попугай выбирает 2 из 6", 17)
	y += 16
	var picked: Array = last.get("picked", [])
	for i in offer.size():
		var appear := clampf((t - 0.6 - i * 0.15) / 0.3, 0.0, 1.0)
		if appear <= 0.0:
			continue
		var q: Dictionary = Meta.quest_by_key(offer[i])
		var qr2 := Rect2(x + (i % 3) * 288, y + int(i / 3) * 92, 276, 82)
		var chosen: bool = picked.has(offer[i]) and t > 1.8
		var fill := Color(1, 0.93, 0.68) if chosen else Color(1, 0.98, 0.93)
		Art.card(self, qr2, Color(fill, appear), Art.frame() + i, Color(INK, appear), 3.0 if chosen else 1.5)
		draw_multiline_string(font, qr2.position + Vector2(12, 26), String(q["name"]), HORIZONTAL_ALIGNMENT_LEFT, 252, 15, 2, Color(INK, appear))
		_t(qr2.position + Vector2(12, 72), "+%d проса" % int(q["reward"]), 13, Color(0.55, 0.4, 0.1, appear))
		if chosen:
			_t(qr2.position + Vector2(196, 72), "выбрал", 13, Color("4f8f3a"))


func _draw_player_meta(t: float) -> void:
	if Trees.hq_open(game.meta):
		_draw_hq(t)
		return
	var r := META_PLAYER
	Art.card(self, r, PANEL, Art.frame() + 3, INK, 3.0)
	var x := r.position.x + 30
	var y := r.position.y + 50
	_t(Vector2(x, y), "Ваши исследования", 30)
	var feathers := int(game.save.get("feathers", 0))
	Icons._glyph(self, "feather", Vector2(x + 380, y - 10), 0.9, 1.0)
	_t(Vector2(x + 400, y - 2), "%d перьев" % feathers, 22, Color("4f8f3a"))
	y += 30
	var last: Dictionary = game.meta.get("last", {})
	_t(Vector2(x, y), "За забег: +%d перьев · ваш урон по попугаю %d · сорвано ивентов %d" % [int(last.get("feathers", 0)), int(game.player_damage), game.events_denied], 15, Color(INK, 0.7))
	y += 30
	var meta: Dictionary = game.meta
	var shown_locked := false
	for tier in 3:
		var open := Meta.tier_open(meta, tier)
		var items: Array = []
		for it in Meta.PLAYER:
			if int(it["tier"]) == tier:
				items.append(it)
		var tier_lbl := "Ярус %d" % (tier + 1)
		if tier > 0 and Diff.unlocked(meta) < 1:
			tier_lbl += " · откроется, когда попугай дойдёт до средней комнаты"
		_t(Vector2(x, unlock_rect(tier, 0).position.y - 8), tier_lbl, 17, INK if open else Color(INK, 0.4))
		for i in items.size():
			var it: Dictionary = items[i]
			var cr := unlock_rect(tier, i)
			var have := Meta.unlocked(meta, it["key"])
			var can: bool = open and not have and feathers >= int(it["cost"])
			var hov: bool = cr.has_point(game.paw["pos"])
			var fill := Color(0.9, 0.97, 0.88) if have else (Color(1, 0.93, 0.7) if can and hov else (PANEL if open else Color(0.9, 0.88, 0.84)))
			Art.card(self, cr, fill, Art.frame() + tier * 3 + i, INK if open else Color(INK, 0.4), 2.5 if can else 1.8)
			if open:
				Icons.draw(self, it["icon"], cr.position + Vector2(48, cr.size.y * 0.5), 60.0, 1.0 if have or can else 0.6)
				_t(cr.position + Vector2(92, 34), String(it["name"]), 19)
				draw_multiline_string(font, cr.position + Vector2(92, 58), String(it["desc"]), HORIZONTAL_ALIGNMENT_LEFT, 300, 14, 2, Color(INK, 0.75))
				var tag := "открыто" if have else "%d перьев" % int(it["cost"])
				_t(cr.position + Vector2(92, 98), tag, 15, Color("4f8f3a") if have else (Color("8a5a1e") if can else Color(INK, 0.5)))
			else:
				Art.text_c(self, font, cr.get_center() + Vector2(0, 8), "???", 26, Color(INK, 0.35))
		y = unlock_rect(tier, 0).end.y + 10
		if not open and not shown_locked:
			shown_locked = true
	if Diff.unlocked(meta) < 2 and Meta.tier_open(meta, 2) and Meta.unlocked(meta, "event4"):
		Art.text_c(self, font, Vector2(r.get_center().x, unlock_rect(2, 0).end.y + 30), "Всё исследовано. Копите перья: штаб откроется, когда попугай дойдёт до сложной комнаты", 16, Color("8a5a1e"))
	elif shown_locked or not Meta.tier_open(meta, 2):
		Art.text_c(self, font, Vector2(r.get_center().x, unlock_rect(2, 0).end.y + 30), "Разблокируйте контент выше, чтобы открыть дальнейшие исследования", 16, Color(INK, 0.65))
	else:
		Art.text_c(self, font, Vector2(r.get_center().x, unlock_rect(2, 0).end.y + 30), "Всё исследовано: следующий экран — штаб с деревьями умений", 16, Color("8a5a1e"))
	var tr := Rect2(r.position.x + 30, r.position.y + 760, 860, 150)
	Art.card(self, tr, Color(0.9, 0.88, 0.84), Art.frame() + 40, Color(INK, 0.4), 1.8)
	Art.text_c(self, font, tr.get_center() + Vector2(0, -12), "Штаб", 26, Color(INK, 0.45))
	Art.text_c(self, font, tr.get_center() + Vector2(0, 20), "откроется, когда попугай дойдёт до сложной комнаты и будут куплены все исследования выше", 15, Color(INK, 0.45))


func unlock_rect(tier: int, i: int) -> Rect2:
	var r := META_PLAYER
	return Rect2(r.position.x + 30 + i * 440, r.position.y + 140 + tier * 170, 420, 120)


## Клики на экране меты: покупка исследования, штаб или новый забег.
func meta_click(p: Vector2, rmb: bool = false) -> String:
	if _meta_t() > 2.0 and NEW_RUN.has_point(p) and not rmb:
		return "new"
	if _meta_t() > 2.0 and CHEST_BTN.has_point(p) and not rmb:
		return "chest"
	if chest_open:
		if rmb or not CHEST.has_point(p):
			return "chest"
		var own: Array = game.save.get("cursors", ["white"])
		var i := 0
		for k in PawCursor.SKINS:
			if chest_skin_rect(i).has_point(p) and own.has(k):
				return "skin:" + k
			i += 1
		i = 0
		for k in Rewards.CURSES:
			if chest_curse_rect(i).has_point(p):
				return "curse:" + k
			i += 1
		return ""
	if _meta_t() < 1.6:
		return ""
	if Trees.hq_open(game.meta):
		return _hq_click(p, rmb)
	if rmb:
		return ""
	for tier in 3:
		var i := 0
		for it in Meta.PLAYER:
			if int(it["tier"]) != tier:
				continue
			if unlock_rect(tier, i).has_point(p):
				return "buy:" + String(it["key"])
			i += 1
	return ""


# ---------- сундук ----------

func chest_skin_rect(i: int) -> Rect2:
	return Rect2(CHEST.position.x + 30 + i * 158, CHEST.position.y + 90, 146, 130)


func chest_curse_rect(i: int) -> Rect2:
	return Rect2(CHEST.position.x + 30 + (i % 3) * 316, CHEST.position.y + 300 + int(i / 3) * 110, 304, 98)


func _draw_chest() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color(0, 0, 0, 0.25))
	Art.card(self, CHEST, PANEL, Art.frame() + 11, INK, 3.0)
	var save: Dictionary = game.save
	var mp: Vector2 = game.paw["pos"]
	_t(CHEST.position + Vector2(30, 50), "Лапка", 24)
	_t(CHEST.position + Vector2(140, 50), "расцветки выпадают из яйца", 15, Color(INK, 0.6))
	var own: Array = save.get("cursors", ["white"])
	var cur := String(save.get("cursor", "white"))
	var i := 0
	for k in PawCursor.SKINS:
		var r := chest_skin_rect(i)
		var have: bool = own.has(k)
		var on: bool = k == cur
		Art.card(self, r, Color(1, 0.93, 0.7) if on else (PANEL if have else Color(0.9, 0.88, 0.84)), Art.frame() + 20 + i, INK if have else Color(INK, 0.35), 3.0 if on else 1.6)
		if have:
			PawCursor.draw_paw(self, r.get_center() + Vector2(0, -6), PawCursor.SKINS[k], 0.0, false, 1.4)
			Art.text_c(self, font, r.position + Vector2(r.size.x * 0.5, r.size.y - 12), String(PawCursor.SKINS[k]["name"]), 13, INK)
		else:
			Art.text_c(self, font, r.get_center() + Vector2(0, 8), "?", 30, Color(INK, 0.35))
		i += 1
	_t(CHEST.position + Vector2(30, 280), "Проклятия на следующий забег", 24)
	var armed: Array = save.get("armed", [])
	_t(CHEST.position + Vector2(420, 280), "можно взять до %d, сгорают при старте" % Rewards.MAX_ARMED, 15, Color(INK, 0.6))
	var cs: Dictionary = save.get("curses", {})
	i = 0
	for k in Rewards.CURSES:
		var r := chest_curse_rect(i)
		var n := int(cs.get(k, 0))
		var on: bool = armed.has(k)
		var hov := r.has_point(mp)
		Art.card(self, r, Color(0.88, 0.8, 1.0) if on else (Color(1, 0.96, 0.85) if hov and n > 0 else (PANEL if n > 0 else Color(0.9, 0.88, 0.84))), Art.frame() + 30 + i, INK if n > 0 else Color(INK, 0.35), 3.0 if on else 1.6)
		_curse_icon(r.position + Vector2(40, 49), 26.0, n > 0)
		_t(r.position + Vector2(76, 34), String(Rewards.CURSES[k]["name"]), 17, INK if n > 0 else Color(INK, 0.45))
		draw_multiline_string(font, r.position + Vector2(76, 56), String(Rewards.CURSES[k]["desc"]), HORIZONTAL_ALIGNMENT_LEFT, 214, 13, 2, Color(INK, 0.7 if n > 0 else 0.4))
		_t(r.position + Vector2(232, 34), ("взято" if on else "×%d" % n), 15, Color("6a4fb3") if on else Color(INK, 0.6))
		i += 1
	Art.text_c(self, font, Vector2(CHEST.get_center().x, CHEST.end.y - 18), "Клик мимо окна — закрыть", 14, Color(INK, 0.5))


func _curse_icon(c: Vector2, r: float, on: bool) -> void:
	var a := 1.0 if on else 0.35
	draw_circle(c, r, Color(0.35, 0.22, 0.5, a))
	draw_arc(c, r, 0, TAU, 24, Color(INK, a), 2.0, true)
	# глаз проклятия
	Art.fill_blob(self, c, r * 0.65, r * 0.38, Color(0.95, 0.9, 1.0, a))
	draw_circle(c, r * 0.22, Color(0.55, 0.2, 0.7, a))
	draw_circle(c, r * 0.1, Color(0.1, 0.05, 0.15, a))


## Значок любой награды: перья, лапка, проклятие, просо, умение, попугай.
func _reward_icon(it: Dictionary, c: Vector2, sz: float) -> void:
	match String(it["kind"]):
		"feathers":
			for k in 3:
				Icons._glyph(self, "feather", c + Vector2(-12 + k * 12, 4 - absf(k - 1) * 8), sz / 44.0, 1.0)
		"skin":
			PawCursor.draw_paw(self, c + Vector2(0, 4), PawCursor.SKINS.get(it["value"], PawCursor.SKINS["white"]), 0.0, false, sz / 34.0)
		"curse":
			_curse_icon(c, sz * 0.45, true)
		"millet":
			for k in 3:
				Icons._glyph(self, "millet", c + Vector2(-12 + k * 12, 0), sz / 50.0, 1.0)
		"skill":
			Icons.draw(self, String(it["value"]), c, sz, 1.0)
		"bird":
			_bird_icon(String(it["value"]), c, sz)


## Портрет попугая для наград и экрана Кеши.
func _bird_icon(b: String, c: Vector2, sz: float) -> void:
	var col: Dictionary = Parrots.bird(b)["col"]
	var k := sz / 80.0
	Art.blob(self, c + Vector2(-6, 14) * k, 22 * k, 20 * k, col["body"], 3.0, 3)
	Art.blob(self, c + Vector2(6, -12) * k, 20 * k, 19 * k, col["head"], 3.0, 4)
	if col.has("face"):
		Art.fill_blob(self, c + Vector2(13, -13) * k, 9 * k, 8 * k, col["face"])
	if col.has("owl"):
		Art.fill_blob(self, c + Vector2(13, -10) * k, 12 * k, 11 * k, Color(col["head"]).lightened(0.25))
	if col["crest"] == "tall":
		for j in 5:
			var base := c + Vector2(0, -28) * k
			var tip := base + Vector2(-14 + j * 5, -26 + absf(j - 2) * 5) * k
			draw_line(base, tip, Color("f2cf3a"), 5.0 * k, true)
	draw_circle(c + Vector2(13, -15) * k, 4.5 * k, Color.WHITE)
	draw_circle(c + Vector2(14, -15) * k, 3.0 * k, INK)
	var bk := PackedVector2Array([c + Vector2(22, -12) * k, c + Vector2(31, -7) * k, c + Vector2(24, 0) * k])
	draw_colored_polygon(bk, col["beak"])
	Art.outline(self, bk, INK, 2.0)
	var tl := PackedVector2Array([c + Vector2(-20, 20) * k, c + Vector2(-38, 34) * k, c + Vector2(-16, 30) * k])
	draw_colored_polygon(tl, col["tail1"])
	Art.outline(self, tl, INK, 2.0)


## Рулетка яйца: экран пополам, слева ваша награда, справа — награда Кеши.
func _draw_roll(ro: Dictionary) -> void:
	var t: float = ro["t"]
	draw_rect(Rect2(0, 0, 1920, 1080), Color(0.12, 0.09, 0.08, 0.96))
	draw_line(Vector2(960, 60), Vector2(960, 1020), Color(1, 1, 1, 0.25), 3.0)
	for side in 2:
		var x0 := 0.0 if side == 0 else 960.0
		var rw: Dictionary = ro["left"] if side == 0 else ro["right"]
		var reel_items: Array = ro["lreel"] if side == 0 else ro["rreel"]
		var stopped: bool = ro["stopped"][side]
		var r := int(rw["rarity"])
		var rc: Color = Rewards.rarity_col(r)
		var cx := x0 + 480.0
		var title := "Ваша награда"
		if side == 1:
			title = "Награда %s" % String(Parrots.bird(game.hero.bird)["gen"])
		Art.text_c(self, font, Vector2(cx, 150), title, 36, Color(1, 0.97, 0.9))
		var cy := 470.0
		if stopped:
			var since0: float = t - (game.ROLL_L if side == 0 else game.ROLL_R)
			var burst0 := clampf(since0 / 0.5, 0.0, 1.0)
			for j in 16:
				var a0 := TAU * j / 16.0 + since0 * 0.6
				var len0 := (180.0 + 70.0 * r) * (0.4 + 0.6 * burst0)
				draw_line(Vector2(cx, cy) + Vector2(cos(a0), sin(a0)) * 100.0, Vector2(cx, cy) + Vector2(cos(a0), sin(a0)) * (100.0 + len0), Color(rc, 0.5), 6.0 + 3.0 * r, true)
		# лента
		var pos: float = game.roll_pos(side, t)
		var step := 170.0
		var band := Rect2(x0 + 30, cy - 95, 900, 190)
		draw_rect(band, Color(0.1, 0.08, 0.07, 0.92))
		for i in reel_items.size():
			var dx := (float(i) - pos) * step
			if absf(dx) > 470.0:
				continue
			var it: Dictionary = reel_items[i]
			var ic: Color = Rewards.rarity_col(int(it["rarity"]))
			var fade := 1.0 - clampf((absf(dx) - 250.0) / 220.0, 0.0, 1.0)
			var cr := Rect2(Vector2(cx + dx - 70, cy - 70), Vector2(140, 140))
			draw_rect(cr, Color(ic, 0.35 * fade))
			draw_rect(cr, Color(ic, fade), false, 4.0)
			if fade > 0.05:
				_reward_icon(it, cr.get_center(), 80.0)
		# рамка-прицел: пока крутится — мигает всеми цветами, на остановке — цвет редкости
		var fc := rc
		if not stopped:
			fc = Rewards.rarity_col(int(t * 12.0) % 4)
		var fr := Rect2(Vector2(cx - 86, cy - 86), Vector2(172, 172))
		draw_rect(fr, fc, false, 7.0)
		draw_colored_polygon(PackedVector2Array([Vector2(cx - 16, cy - 108), Vector2(cx + 16, cy - 108), Vector2(cx, cy - 88)]), fc)
		if stopped:
			var since: float = t - (game.ROLL_L if side == 0 else game.ROLL_R)
			# вспышка и лучи цвета редкости
			var burst := clampf(since / 0.5, 0.0, 1.0)
			draw_rect(fr.grow(10.0 * (1.0 - burst)), Color(rc, 0.6 * (1.0 - burst)), false, 6.0)
			Art.text_c(self, font, Vector2(cx, 640), String(Rewards.RARITY[r]["name"]).to_upper(), 28, rc, Color(0, 0, 0, 0.6), 6)
			Art.text_c(self, font, Vector2(cx, 700), String(rw["label"]), 30, Color(1, 0.97, 0.9), Color(0, 0, 0, 0.6), 6)
			if side == 0:
				Art.text_c(self, font, Vector2(cx, 748), "и +%d перьев за забег" % int(game.outro.get("feathers", 0)), 20, Color(1, 0.97, 0.9, 0.75))
			if r >= 2:
				for j in 18:
					var a2 := float(j) * 2.39
					var q := Vector2(cx, cy) + Vector2(cos(a2), sin(a2)) * (120.0 + 260.0 * burst) + Vector2(0, 200.0 * burst * burst)
					draw_rect(Rect2(q, Vector2(8, 4)), Color(rc.lightened(0.3), 1.0 - burst))
	if t >= game.ROLL_END:
		Art.text_c(self, font, Vector2(960, 950), "Клик — продолжить", 22, Color(1, 0.97, 0.9, 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.005)))
	else:
		Art.text_c(self, font, Vector2(960, 950), "клик — пропустить", 16, Color(1, 0.97, 0.9, 0.4))


# ---------- штаб ----------

const HQ_NODE_R := [22.0, 20.0, 20.0, 28.0, 20.0, 20.0, 34.0]
const C_OWN := Color("cfe8c4")
const C_CAN := Color(1, 0.88, 0.5)


func hq_tab_rect(i: int) -> Rect2:
	return Rect2(META_PLAYER.position.x + 30 + i * 240, META_PLAYER.position.y + 92, 228, 44)


func hq_abil_rect(i: int) -> Rect2:
	return Rect2(META_PLAYER.position.x + 30 + i * 174, META_PLAYER.position.y + 150, 164, 84)


func hq_star_rect(i: int) -> Rect2:
	var r := hq_abil_rect(i)
	return Rect2(r.end.x - 34, r.position.y + 4, 30, 30)


func hq_node_pos(bi: int, ni: int) -> Vector2:
	var lay: Vector2 = Trees.LAYOUT[ni]
	var cx := META_PLAYER.position.x + 30 + 143 + bi * 292
	return Vector2(cx + lay.x * 72.0, META_PLAYER.position.y + 340 + lay.y * 106.0)


func hq_slot_rect(i: int) -> Rect2:
	return Rect2(META_PLAYER.position.x + 30 + (i % 4) * 216, META_PLAYER.position.y + 190 + int(i / 4) * 118, 206, 104)


func hq_pack_rect(i: int) -> Rect2:
	return Rect2(META_PLAYER.position.x + 30 + (i % 2) * 432, META_PLAYER.position.y + 470 + int(i / 2) * 100, 422, 90)


func _hq_click(p: Vector2, rmb: bool) -> String:
	var meta: Dictionary = game.meta
	if not rmb:
		if hq_tab_rect(0).has_point(p):
			return "tab:trees"
		if hq_tab_rect(1).has_point(p) and Trees.waves_open(meta):
			return "tab:waves"
	if hq_tab == "waves" and Trees.waves_open(meta):
		for i in Trees.SEGMENTS:
			if hq_slot_rect(i).has_point(p):
				return "slot:%d:%s" % [i, "prev" if rmb else "next"]
		if not rmb:
			for i in Trees.PACKS.size():
				if hq_pack_rect(i).has_point(p):
					return "pack:" + String(Trees.PACKS[i]["key"])
		return ""
	if rmb:
		return ""
	for i in Trees.ABIL.size():
		var ab: String = Trees.ABIL[i]
		if not Trees.tree_open(meta, ab):
			continue
		if hq_star_rect(i).has_point(p):
			return "enh:" + ab
		if hq_abil_rect(i).has_point(p):
			return "abil:" + ab
	if Trees.tree_open(meta, hq_abil):
		for bi in 3:
			for ni in 7:
				if hq_node_pos(bi, ni).distance_to(p) < float(HQ_NODE_R[ni]) + 4.0:
					return "node:%s:%d:%d" % [hq_abil, bi, ni]
	return ""


func _draw_hq(t: float) -> void:
	var r := META_PLAYER
	var meta: Dictionary = game.meta
	Art.card(self, r, PANEL, Art.frame() + 3, INK, 3.0)
	var x := r.position.x + 30
	var y := r.position.y + 50
	_t(Vector2(x, y), "Штаб", 30)
	var feathers := int(game.save.get("feathers", 0))
	Icons._glyph(self, "feather", Vector2(x + 380, y - 10), 0.9, 1.0)
	_t(Vector2(x + 400, y - 2), "%d перьев" % feathers, 22, Color("4f8f3a"))
	var last: Dictionary = meta.get("last", {})
	_t(Vector2(x + 560, y - 2), "за забег +%d" % int(last.get("feathers", 0)), 16, Color(INK, 0.6))
	_t(Vector2(x, y + 26), "Улучшений куплено: %d" % Trees.bought_total(meta), 14, Color(INK, 0.6))
	var mp: Vector2 = game.paw["pos"]
	# вкладки
	var wopen := Trees.waves_open(meta)
	if hq_tab == "waves" and not wopen:
		hq_tab = "trees"
	for i in 2:
		var tr := hq_tab_rect(i)
		var on := (i == 0 and hq_tab == "trees") or (i == 1 and hq_tab == "waves")
		var avail := i == 0 or wopen
		Art.card(self, tr, Color(1, 0.93, 0.7) if on else (PANEL if avail else Color(0.9, 0.88, 0.84)), Art.frame() + 50 + i, INK if avail else Color(INK, 0.4), 2.5 if on else 1.5)
		var label := "Деревья умений" if i == 0 else ("Волны" if wopen else "Волны · после %d улучшений" % Trees.WAVES_AT)
		Art.text_c(self, font, tr.get_center() + Vector2(0, 7), label, 18 if avail else 14, INK if avail else Color(INK, 0.5))
	if hq_tab == "waves":
		_draw_hq_waves(meta, feathers, mp)
	else:
		_draw_hq_trees(meta, feathers, mp)


func _draw_hq_trees(meta: Dictionary, feathers: int, mp: Vector2) -> void:
	var r := META_PLAYER
	var h := Trees.hq(meta)
	var enh: Array = h["enh"]
	if not Trees.tree_open(meta, hq_abil):
		hq_abil = "throw"
	var teaser_shown := false
	for i in Trees.ABIL.size():
		var ab: String = Trees.ABIL[i]
		var cr := hq_abil_rect(i)
		var open := Trees.tree_open(meta, ab)
		if not open:
			# закрытые деревья: видно только ближайшее, остальные — силуэтом
			if not teaser_shown:
				Art.card(self, cr, Color(0.9, 0.88, 0.84), Art.frame() + 60 + i, Color(INK, 0.35), 1.5)
				teaser_shown = true
				Art.text_c(self, font, cr.get_center() + Vector2(0, -6), "???", 22, Color(INK, 0.4))
				Art.text_c(self, font, cr.get_center() + Vector2(0, 18), "после %d улучшений" % int(Trees.OPEN_AT[ab]), 13, Color(INK, 0.5))
			continue
		var sel := ab == hq_abil
		var is_enh := enh.has(ab)
		Art.card(self, cr, Color(1, 0.93, 0.7) if sel else PANEL, Art.frame() + 60 + i, INK, 3.0 if sel else 1.8)
		Icons.draw(self, Trees.ABIL_ICON[ab], cr.position + Vector2(32, 34), 42.0, 1.0)
		_t(cr.position + Vector2(8, 74), String(Trees.ABIL_NAMES[ab]), 15)
		# звезда: усиленное на забег
		var sr := hq_star_rect(i)
		var hov := sr.has_point(mp)
		Icons._star(self, sr.get_center(), 13.0, Color("f2c14e") if is_enh else (Color(1, 1, 1) if hov else Color(0.85, 0.82, 0.76)), 1.0)
	var names: Array[String] = []
	for ab in enh:
		names.append(String(Trees.ABIL_NAMES[ab]))
	var slots := Trees.enh_slots(meta)
	var msg := "Усилены на забег (★): %s · слотов %d/%d" % [", ".join(names) if names.size() > 0 else "ничего", enh.size(), slots]
	if slots < 2:
		msg += " · второй слот после %d улучшений" % Trees.SECOND_SLOT_AT
	_t(Vector2(r.position.x + 30, r.position.y + 262), msg, 15, Color("8a5a1e") if enh.size() > 0 else Color("b23a2e"))
	var ab: String = hq_abil
	var active := enh.has(ab)
	if not active:
		_t(Vector2(r.position.x + 30, r.position.y + 284), "Это дерево сейчас не усилено: купленное в нём заработает, когда отметите звезду.", 13, Color(INK, 0.6))
	var tip := []
	for bi in 3:
		var br: Dictionary = Trees.BRANCHES[ab][bi]
		var hx := hq_node_pos(bi, 0).x
		Art.text_c(self, font, Vector2(hx, r.position.y + 310), String(br["name"]), 18, INK)
		# связи
		for ni in 7:
			var a := hq_node_pos(bi, ni)
			var reqs: Array = [[], [0], [0], [1, 2], [3], [3], [4, 5]][ni]
			for rq in reqs:
				var b := hq_node_pos(bi, rq)
				var on := Trees.lvl(meta, Trees.node_id(ab, bi, rq)) > 0
				draw_line(b, a, Color(INK, 0.75) if on else Color(INK, 0.18), 3.0 if on else 2.0, true)
		for ni in 7:
			var c := hq_node_pos(bi, ni)
			var rr: float = HQ_NODE_R[ni]
			var n: Array = Trees.node(ab, bi, ni)
			var lv := Trees.lvl(meta, Trees.node_id(ab, bi, ni))
			var mx := int(n[4])
			var reach := Trees.reachable(meta, ab, bi, ni)
			var why := Trees.why_not(meta, feathers, ab, bi, ni)
			var fill := Color(0.88, 0.86, 0.82)
			if lv >= mx:
				fill = Color("9fcf8c")
			elif lv > 0:
				fill = C_OWN
			elif why == "":
				fill = C_CAN.lerp(Color(1, 0.97, 0.85), 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006))
			elif reach:
				fill = PANEL
			var shape: PackedVector2Array
			if ni == 3:
				shape = PackedVector2Array([c + Vector2(0, -rr), c + Vector2(rr, 0), c + Vector2(0, rr), c + Vector2(-rr, 0)])
			elif ni == 6:
				shape = PackedVector2Array()
				for k in 12:
					var ang := -PI * 0.5 + TAU * k / 12.0
					shape.append(c + Vector2(cos(ang), sin(ang)) * (rr if k % 2 == 0 else rr * 0.72))
			else:
				shape = Art.ellipse_pts(c, rr, rr, ni + bi * 7, 0.04, 16)
			draw_colored_polygon(shape, fill)
			Art.outline(self, shape, INK if reach or lv > 0 else Color(INK, 0.35), 2.5 if why == "" else 1.8)
			if reach or lv > 0:
				if ni == 3 or ni == 6:
					Icons._glyph(self, Trees.ABIL_ICON[ab], c, 0.55 if ni == 3 else 0.7, 1.0)
				else:
					Art.text_c(self, font, c + Vector2(0, 6), "%d/%d" % [lv, mx], 14, INK)
				var cond: Array = n[5]
				if not cond.is_empty() and lv == 0:
					var k := Trees.cond_progress(meta, cond)
					draw_arc(c, rr + 6, -PI * 0.5, -PI * 0.5 + TAU * k, 32, Color("6a4fb3"), 3.0, true)
					if k < 1.0:
						draw_arc(c, rr + 6, -PI * 0.5 + TAU * k, PI * 1.5, 32, Color(0.42, 0.31, 0.7, 0.2), 3.0, true)
				var lw := Art.text_w(font, String(n[0]), 12)
				draw_rect(Rect2(c + Vector2(-lw * 0.5 - 4, rr + 6), Vector2(lw + 8, 16)), PANEL)
				Art.text_c(self, font, c + Vector2(0, rr + 18), String(n[0]), 12, INK if reach else Color(INK, 0.5))
			else:
				Art.text_c(self, font, c + Vector2(0, 6), "?", 16, Color(INK, 0.35))
			if c.distance_to(mp) < rr + 4.0:
				tip = [bi, ni]
	# подсказка по узлу под курсором
	var tr := Rect2(r.position.x + 30, r.position.y + 846, 860, 92)
	Art.card(self, tr, Color(1, 0.98, 0.9), Art.frame() + 70, Color(INK, 0.6), 1.5)
	if tip.is_empty():
		_t(tr.position + Vector2(14, 28), "Наведите на узел дерева. Ромб — ключевая пассивка, звезда — вершина ветки.", 15, Color(INK, 0.65))
		_t(tr.position + Vector2(14, 54), "К ключевому узлу и вершине ведут два пути: хватит любого из боковых узлов.", 15, Color(INK, 0.65))
		_t(tr.position + Vector2(14, 80), "Ключевые узлы сначала надо заслужить в забегах (фиолетовая дуга — прогресс условия).", 15, Color(INK, 0.65))
		return
	var bi2: int = tip[0]
	var ni2: int = tip[1]
	var n2: Array = Trees.node(ab, bi2, ni2)
	var lv2 := Trees.lvl(meta, Trees.node_id(ab, bi2, ni2))
	var reach2 := Trees.reachable(meta, ab, bi2, ni2)
	if not reach2 and lv2 == 0:
		_t(tr.position + Vector2(14, 30), "Скрытый узел", 18)
		_t(tr.position + Vector2(14, 58), "Откроется, когда купите узел выше по ветке.", 15, Color(INK, 0.7))
		return
	var kind := "вершина ветки" if ni2 == 6 else ("ключевая пассивка" if ni2 == 3 else "улучшение")
	_t(tr.position + Vector2(14, 28), "%s · %s · уровень %d/%d" % [String(n2[0]), kind, lv2, int(n2[4])], 18)
	_t(tr.position + Vector2(14, 54), String(n2[1]), 15, Color(INK, 0.8))
	var why2 := Trees.why_not(meta, feathers, ab, bi2, ni2)
	var cond2: Array = n2[5]
	var line := ""
	if lv2 >= int(n2[4]):
		line = "куплено полностью"
	else:
		line = "цена %d перьев" % Trees.cost(ni2, lv2)
		if not cond2.is_empty():
			line += " · условие: %s (%d/%d)" % [String(cond2[2]), mini(Trees.pstat(meta, cond2[0]), int(cond2[1])), int(cond2[1])]
		if why2 == "":
			line += " · кликните, чтобы купить"
		elif why2 == "не хватает перьев":
			line += " · не хватает перьев"
	_t(tr.position + Vector2(14, 80), line, 14, Color("8a5a1e") if why2 == "" else Color(INK, 0.65))


func _draw_hq_waves(meta: Dictionary, feathers: int, mp: Vector2) -> void:
	var r := META_PLAYER
	var h := Trees.hq(meta)
	_t(Vector2(r.position.x + 30, r.position.y + 172), "Состав орды по 30 секунд до пылесоса. ЛКМ — следующий состав, ПКМ — предыдущий.", 15, Color(INK, 0.7))
	for i in Trees.SEGMENTS:
		var cr := hq_slot_rect(i)
		var pkk: Dictionary = Trees.pack(h["waves"][i])
		var hov := cr.has_point(mp)
		var is_mix: bool = pkk["key"] == "mix"
		Art.card(self, cr, Color(1, 0.93, 0.7) if hov else (PANEL if is_mix else Color(0.93, 0.9, 1.0)), Art.frame() + 80 + i, INK, 2.0)
		_t(cr.position + Vector2(12, 24), "%s–%s" % [mmss(i * 30.0), mmss(i * 30.0 + 30.0)], 14, Color(INK, 0.6))
		_t(cr.position + Vector2(12, 52), String(pkk["name"]), 18)
		draw_multiline_string(font, cr.position + Vector2(12, 74), String(pkk["desc"]), HORIZONTAL_ALIGNMENT_LEFT, 186, 12, 2, Color(INK, 0.65))
	_t(Vector2(r.position.x + 30, r.position.y + 458), "Составы орды", 17)
	for i in Trees.PACKS.size():
		var pkk: Dictionary = Trees.PACKS[i]
		var cr := hq_pack_rect(i)
		var own := Trees.pack_owned(meta, pkk["key"])
		var cond_ok := Trees.cond_progress(meta, pkk["cond"]) >= 1.0
		var can: bool = not own and cond_ok and feathers >= int(pkk["cost"])
		var hov := cr.has_point(mp)
		Art.card(self, cr, C_OWN if own else (C_CAN if can and hov else (PANEL if cond_ok else Color(0.9, 0.88, 0.84))), Art.frame() + 90 + i, INK if cond_ok or own else Color(INK, 0.45), 2.5 if can else 1.6)
		_t(cr.position + Vector2(14, 28), String(pkk["name"]), 18, INK if cond_ok or own else Color(INK, 0.5))
		draw_multiline_string(font, cr.position + Vector2(14, 50), String(pkk["desc"]), HORIZONTAL_ALIGNMENT_LEFT, 300, 13, 2, Color(INK, 0.7))
		var tag := "есть"
		if not own:
			tag = "%d перьев" % int(pkk["cost"])
			if not cond_ok:
				var cd: Array = pkk["cond"]
				tag = "условие: %s (%d/%d)" % [String(cd[2]), mini(Trees.pstat(meta, cd[0]), int(cd[1])), int(cd[1])]
		_t(cr.position + Vector2(14 if not cond_ok and not own else 300, 82), tag, 13, Color("4f8f3a") if own else (Color("8a5a1e") if can else Color(INK, 0.55)))


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


## Лапка — системный курсор (без задержки). Здесь — только то, что вокруг неё:
## резинка рогатки, кольцо отката, вспышка готовности, кольцо тарана.
func _draw_paw(fr: int) -> void:
	var off: Vector2 = game.world.position
	for tr in game.paw_trail:
		var a := clampf(float(tr["t"]) / 0.3, 0.0, 1.0)
		draw_line(Vector2(tr["a"]) + off, Vector2(tr["b"]) + off, Color(INK, 0.35 * a), 2.0, true)
	var p: Vector2 = game.paw["pos"]
	var holding: bool = game.held_e != null
	var sk: Dictionary = PawCursor.SKINS.get(game.cursor_skin(), PawCursor.SKINS["white"])
	if holding:
		var anc: Vector2 = game.sling_anchor + off
		p += off
		var nrm := (p - anc).normalized().rotated(PI * 0.5) * 14.0
		draw_line(anc + nrm, p, Color("8a5a3a"), 3.0, true)
		draw_line(anc - nrm, p, Color("8a5a3a"), 3.0, true)
		var v: Vector2 = game.throw_vector()
		if v != Vector2.ZERO:
			var power: float = v.length() / game.sling_speed()
			var end: Vector2 = anc + v.normalized() * (50.0 + 220.0 * power)
			var col := Color(0.42, 0.31, 0.7).lerp(Color(0.9, 0.35, 0.1), power)
			draw_dashed_line(anc, end, Color(col, 0.9), 3.0 + 3.0 * power, 10.0)
			draw_polyline(PackedVector2Array([end + v.normalized().rotated(2.5) * 16.0, end, end + v.normalized().rotated(-2.5) * 16.0]), col, 4.0)
		var k: float = clampf(game.hold_t / (game.HOLD_TIME + game.pk("hold")), 0.0, 1.0)
		var br := Rect2(p + Vector2(-26, -44), Vector2(52, 7))
		draw_rect(br, Color(1, 1, 1, 0.85))
		draw_rect(Rect2(br.position, Vector2(br.size.x * k, br.size.y)), Color("e0a92e") if k > 0.35 else Color("d95c4a"))
		draw_rect(br, INK, false, 1.5)
		PawCursor.draw_paw(self, p, sk, 4.0, false)
		return
	if game.cursor_imgs.is_empty():
		# пока картинки курсора не готовы (или в снимках) — рисуем лапку сами
		PawCursor.draw_paw(self, p, sk, 4.0 if game.throw_cd > 0.0 else 0.0, game.throw_cd > 0.0 or game.paw_bruise > 0.0)
	if game.over != "" or game.phase != "play":
		return
	# откат рогатки: кольцо вокруг лапки заполняется, пока не будет готово
	if game.throw_cd > 0.0:
		var k2: float = 1.0 - clampf(game.throw_cd / game.throw_cd_full(), 0.0, 1.0)
		draw_arc(p, 30.0, 0, TAU, 32, Color(INK, 0.18), 5.0, true)
		draw_arc(p, 30.0, -PI * 0.5, -PI * 0.5 + TAU * k2, 32, Color(0.42, 0.31, 0.7, 0.85), 5.0, true)
	if game.throw_ready_flash > 0.0:
		var f: float = game.throw_ready_flash / 0.45
		draw_arc(p, 30.0 + 18.0 * (1.0 - f), 0, TAU, 32, Color(0.42, 0.31, 0.7, f), 4.0, true)
	if game.paw_bruise <= 0.0 and game.time >= game.RAM_UNLOCK and game.paw_vel.length() > game.RAM_SPEED * (1.0 - game.pk("ram_easy")):
		draw_arc(p + Vector2(0, -2), 26.0, 0, TAU, 24, Color(0.42, 0.31, 0.7, 0.6), 2.5, true)
