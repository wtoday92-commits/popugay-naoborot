extends Node2D
## Пятиминутный забег: комната с мебелью, орда, ивенты из очереди, босс-пылесос на 4:00.
## Игрок: лапка (толчок, таран, хватка и бросок носков), меню над колоском проса,
## кнопки Q (книга) и W (корзина белья). Запуск с `-- --sim` гоняет забег без графики с ботом.

const M := 40.0
const SCREEN := Vector2(1920, 1080)
const FIELD := Rect2(340, 0, 1240, 1080)
const RUN_LENGTH := 300.0
const HORDE_STEP := 50.0
const BOSS_AT := 240.0
const EVENT_SLOTS := [40.0, 95.0, 150.0, 200.0]
const EVENT_WARN := 10.0
const GLOW_NEED := 5
const METEOR_CD := 12.0
const METEOR_DELAY := 1.2
const METEOR_R := 2.5 * M
const WAVE_UNLOCK := 60.0
const WAVE_CD := 30.0
const RAM_UNLOCK := 20.0
const RAM_SPEED := 1500.0
const MILLET_CD := 30.0
const PAW_PUSH_R := 1.5 * M
const PAW_HIT_R := 26.0
const PAW_PUSH_MAX := 12
const PAW_BRUISE := 4.0
const PAW_BRUISED_SPEED := 380.0
const GRAB_R := 28.0
const MAX_ENEMIES := 170
const MAX_GEMS := 400
const CELL := 40.0
const MENU_R := 64.0
const MENU_OPTS := ["trap", "rotten", "egg", "missile"]
const MENU_NAMES := {"trap": "Капкан", "rotten": "Тухлое", "egg": "Яйцо", "missile": "Снаряд"}
const MENU_DESC := {
	"trap": "оглушит на 1 с",
	"rotten": "−8 здоровья, без опыта",
	"egg": "вылупится суперносок",
	"missile": "выбери направление",
}

const ENAMES := ["sock", "yarn", "slipper", "sprayer", "hand", "super", "dust", "box", "boss"]
const EDEFS := [
	{"name": "Носок", "hp": 10.0, "speed": 1.7, "dmg": 5.0, "r": 11.0, "push": 1.0, "xp": 1},
	{"name": "Клубок", "hp": 6.0, "speed": 3.6, "dmg": 3.0, "r": 10.0, "push": 1.0, "xp": 1},
	{"name": "Тапок", "hp": 45.0, "speed": 0.9, "dmg": 11.0, "r": 18.0, "push": 0.5, "xp": 3},
	{"name": "Пульверизатор", "hp": 14.0, "speed": 1.3, "dmg": 5.0, "r": 12.0, "push": 1.0, "xp": 2},
	{"name": "Рука", "hp": 150.0, "speed": 2.0, "dmg": 12.0, "r": 18.0, "push": 0.0, "xp": 0},
	{"name": "Суперносок", "hp": 60.0, "speed": 2.0, "dmg": 9.0, "r": 15.0, "push": 0.6, "xp": 5},
	{"name": "Пылевой зайчик", "hp": 8.0, "speed": 2.6, "dmg": 4.0, "r": 9.0, "push": 1.0, "xp": 1},
	{"name": "Шкатулка", "hp": 70.0, "speed": 2.6, "dmg": 0.0, "r": 16.0, "push": 0.0, "xp": 0},
	{"name": "Пылесос", "hp": 1700.0, "speed": 1.1, "dmg": 16.0, "r": 56.0, "push": 0.0, "xp": 0},
]

var floor_rect := Rect2(372, 34, 1176, 1012)
## Мебель: [прямоугольник основания, вид, высота]. Основание — препятствие для всех.
var furniture: Array = [
	[Rect2(420, 34, 300, 110), "sofa", 34.0],
	[Rect2(1458, 140, 90, 300), "shelf", 60.0],
	[Rect2(1060, 470, 180, 110), "table", 26.0],
	[Rect2(400, 830, 150, 140), "armchair", 38.0],
	[Rect2(840, 34, 70, 70), "plant", 50.0],
	[Rect2(760, 400, 64, 64), "stool", 30.0],
	[Rect2(1300, 880, 120, 100), "boxes", 50.0],
	[Rect2(580, 560, 54, 54), "lamp", 80.0],
	[Rect2(960, 760, 80, 60), "books", 26.0],
	[Rect2(680, 930, 110, 90), "toys", 32.0],
	[Rect2(1440, 640, 108, 120), "nightstand", 40.0],
	[Rect2(1080, 936, 160, 110), "catbed", 20.0],
	[Rect2(500, 330, 90, 90), "chair", 44.0],
]
var obstacles: Array[Rect2] = []

var time := 0.0
var hero: Hero
var enemies: Array[Enemy] = []
var gems: Array = []
var chests: Array = []
var meteors: Array = []
var shots: Array = []
var enemy_shots: Array = []
var thrown: Array = []
var missiles: Array = []
var delayed: Array = []
var fx: Array = []
var texts: Array = []
var thoughts: Array = []
var banners: Array = []
var pending: Array = []
var horde_level := 1
var next_horde := HORDE_STEP
var spawn_acc := 0.0
var next_swarm := 30.0
var next_hand := 30.0
var double_spawn_until := -1.0
var meteor_cd := 0.0
var wave_cd := 0.0
var millet_cd := 0.0
var paw := {"id": 0, "pos": Vector2(960, 700), "born": 0.0}
var paw_vel := Vector2.ZERO
var paw_bruise := 0.0
var paw_threat := false
var paw_seen_until := -1.0
var paw_trail: Array = []
var held_e: Enemy = null
var menu := {}
var aim := {}
var queue: Array = []
var event := {}
var event_announced := -1
var boss: Enemy = null
var boss_announced := false
var boss_defeated := false
var drag := {}
var levelup := {}
var power_flash := 0.0
var game_speed := 1.0
var paused := false
var over := ""
var kills := 0
var player_damage := 0.0
var chests_denied := 0
var events_denied := 0
var tricks := 0
var throws_hit := 0
var meteors_cast := 0
var meteor_hits := 0
var rams := 0
var combo_log: Array = []
var combo_cd := 0.0
var combos := 0
var shake := 0.0
var debug := false
var sim := false
var sim_bot := true
var hint := ""
var hint_t := 0.0
var hints_shown := {}
var world: WorldView
var hud: Hud
var audio: Sfx
var _next_id := 1
var _grid := {}
var _sim_report := 30.0
var _sim_dodged := 0
var dmg_by_src := {}
var shot_at := -1.0
var selftest := false
var _st_done := {}


func _ready() -> void:
	randomize()
	var args := OS.get_cmdline_user_args()
	sim = args.has("--sim")
	sim_bot = not args.has("--nobot")
	selftest = args.has("--selftest")
	for a in args:
		if a.begins_with("--shot="):
			shot_at = float(a.substr(7))
	for f in furniture:
		obstacles.append(f[0])
	world = WorldView.new()
	world.game = self
	add_child(world)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.game = self
	layer.add_child(hud)
	if not sim:
		audio = Sfx.new()
		add_child(audio)
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	start_run()


func new_id() -> int:
	_next_id += 1
	return _next_id


func sfx(name: String, vol: float = 0.0, pitch: float = 1.0) -> void:
	if audio != null:
		audio.play(name, vol, pitch)


func start_run() -> void:
	time = 0.0
	for arr in [enemies, gems, chests, meteors, shots, enemy_shots, thrown, missiles, delayed, fx, texts, thoughts, banners, pending, combo_log, paw_trail]:
		arr.clear()
	_grid.clear()
	horde_level = 1
	next_horde = HORDE_STEP
	spawn_acc = 0.0
	next_swarm = 30.0
	next_hand = 30.0
	double_spawn_until = -1.0
	meteor_cd = 2.0
	wave_cd = 0.0
	millet_cd = 0.0
	paw_bruise = 0.0
	held_e = null
	menu = {}
	aim = {}
	event = {}
	event_announced = -1
	boss = null
	boss_announced = false
	boss_defeated = false
	drag = {}
	levelup = {}
	power_flash = 0.0
	paused = false
	over = ""
	kills = 0
	player_damage = 0.0
	chests_denied = 0
	events_denied = 0
	tricks = 0
	throws_hit = 0
	meteors_cast = 0
	meteor_hits = 0
	rams = 0
	combos = 0
	combo_cd = 0.0
	hints_shown = {}
	dmg_by_src = {}
	queue.clear()
	var types: Array = Skills.EVENTS.duplicate()
	types.shuffle()
	for i in EVENT_SLOTS.size():
		queue.append({"type": types[i], "at": EVENT_SLOTS[i]})
	paw["id"] = new_id()
	hero = Hero.new(self)
	hero.pos = Vector2(900, 660)
	Engine.time_scale = game_speed
	add_thought("Цели: выжить 5 минут, открыть 2 кормушки, пройти 3 ивента.")
	show_hint("Лапка толкает носки. Зажмите ЛКМ на носке и бросьте его в попугая.", 7.0)


# ---------- цикл ----------

func _process(delta: float) -> void:
	var real_dt := delta / maxf(Engine.time_scale, 0.0001)
	if sim:
		_sim_step()
	else:
		_update_paw(real_dt)
	_update_levelup(real_dt)
	for b in banners:
		b["t"] = float(b["t"]) + real_dt
	banners = banners.filter(func(b): return float(b["t"]) < float(b["dur"]))
	hint_t = maxf(0.0, hint_t - real_dt)
	power_flash = maxf(0.0, power_flash - real_dt)
	shake = maxf(0.0, shake - real_dt * 30.0)
	world.position = Vector2(randf_range(-shake, shake), randf_range(-shake, shake)) if shake > 0.1 else Vector2.ZERO
	if audio != null and hero != null:
		audio.set_tension(1.0 - hero.hp_frac() * 2.0 if over == "" else 0.0)
	if not sim:
		world.queue_redraw()
		hud.queue_redraw()
	if shot_at > 0.0 and time > shot_at - 0.8 and meteor_cd <= 0.0:
		paw["pos"] = hero.pos + Vector2(60, 20)
		cast_meteor()
	if shot_at > 0.0 and time >= shot_at:
		# отладочный снимок экрана: `-- --shot=<сек>`
		shot_at = -1.0
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shot.png")
		print("SHOT ", ProjectSettings.globalize_path("user://shot.png"))
		get_tree().quit()
		return
	if paused or over != "":
		return
	_step(delta)


func _step(delta: float) -> void:
	time += delta
	meteor_cd = maxf(0.0, meteor_cd - delta)
	wave_cd = maxf(0.0, wave_cd - delta)
	millet_cd = maxf(0.0, millet_cd - delta)
	combo_cd = maxf(0.0, combo_cd - delta)
	_director(delta)
	_update_events(delta)
	_update_paw_threat()
	_paw_push(delta)
	hero.update(delta)
	_update_enemies(delta)
	_update_shots(delta)
	_update_thrown(delta)
	_update_missiles(delta)
	_update_meteors(delta)
	_update_delayed()
	_update_pickups(delta)
	_update_fx(delta)
	enemies = enemies.filter(func(e): return not e.dead)
	if not menu.is_empty() and bool(menu["gem"]["taken"]):
		menu = {}
	if hero.xp >= hero.xp_next and levelup.is_empty() and over == "":
		begin_levelup()
	_timed_hints()
	if time >= RUN_LENGTH and over == "":
		over = "survived"
		add_thought("Пять минут! Я выжил.")
		sfx("fail")


func _timed_hints() -> void:
	var list := [
		[RAM_UNLOCK, "ram", "Таран! Резко махните лапкой в попугая: он оглохнет на полсекунды."],
		[12.0, "millet", "Кликните ЛКМ по крупному колоску: капкан, тухлое, яйцо или снаряд. Попугай не видит подмены."],
		[WAVE_UNLOCK, "wave", "W — опрокинуть корзину белья у стены, к которой ближе лапка."],
		[EVENT_SLOTS[0] - 25.0, "queue", "Ивенты слева можно перетаскивать, пока они не начались."],
	]
	for h in list:
		if time >= float(h[0]) and not hints_shown.has(h[1]):
			hints_shown[h[1]] = true
			show_hint(h[2], 7.0)
			if h[1] == "wave":
				banner("Новая кнопка: корзина белья [W]", Color("6a4fb3"), 30, 2.5)


func _unhandled_input(event_in: InputEvent) -> void:
	var mb := event_in as InputEventMouseButton
	if mb != null:
		_mouse_button(mb)
		return
	var k := event_in as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_Q, KEY_1:
			cast_meteor()
		KEY_W, KEY_2:
			cast_wave()
		KEY_SPACE, KEY_P:
			if over == "":
				paused = not paused
		KEY_ESCAPE:
			if not menu.is_empty() or not aim.is_empty():
				menu = {}
				aim = {}
			elif over == "":
				paused = not paused
		KEY_R, KEY_ENTER:
			start_run()
		KEY_M:
			if audio != null:
				audio.set_muted(not audio.muted)
		KEY_F2:
			game_speed = 3.0 if game_speed == 1.0 else 1.0
			Engine.time_scale = game_speed
		KEY_F3:
			debug = not debug


func _mouse_button(mb: InputEventMouseButton) -> void:
	var p: Vector2 = paw["pos"]
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		if mb.pressed and (not menu.is_empty() or not aim.is_empty()):
			menu = {}
			aim = {}
			return
		if mb.pressed:
			_try_grab(p)
		else:
			_release_grab()
		return
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		if p.x < FIELD.position.x:
			drag = hud.queue_press(p)
			return
		if over != "" or paused:
			return
		if not aim.is_empty():
			_launch_missile(p)
			return
		if not menu.is_empty():
			_menu_click(p)
			return
		if millet_cd <= 0.0:
			var g = _gem_at(p)
			if g != null:
				menu = {"gem": g, "t": 0.0}
				sfx("tick")
				return
		_try_grab(p)
	else:
		if not drag.is_empty():
			hud.queue_release(drag, p)
			drag = {}
			return
		_release_grab()


# ---------- лапка ----------

func _update_paw(dt: float) -> void:
	var m := get_global_mouse_position().clamp(Vector2.ZERO, SCREEN)
	var old: Vector2 = paw["pos"]
	var p := m
	if paw_bruise > 0.0:
		paw_bruise = maxf(0.0, paw_bruise - dt)
		# ушибленная лапка отстаёт от мыши
		p = old.move_toward(m, PAW_BRUISED_SPEED * dt)
	paw["pos"] = p
	if not menu.is_empty():
		menu["t"] = float(menu["t"]) + dt
	if dt <= 0.0:
		return
	var v := (p - old) / dt
	paw_vel = paw_vel.lerp(v, clampf(dt * 30.0, 0.0, 1.0))
	if v.length() > 600.0 and paw_bruise <= 0.0 and FIELD.has_point(p):
		paw_trail.append({"a": old, "b": p, "t": 0.3})
	for tr in paw_trail:
		tr["t"] = float(tr["t"]) - dt
	paw_trail = paw_trail.filter(func(tr): return float(tr["t"]) > 0.0)
	if held_e != null:
		held_e.pos = p + Vector2(0, 16) + Vector2(sin(time * 20.0) * 3.0, 0)
	if not paused and over == "" and hero != null and held_e == null:
		_check_ram(old, p, v)


static func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	return Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p)


func _check_ram(a: Vector2, b: Vector2, v: Vector2) -> void:
	if time < RAM_UNLOCK or paw_bruise > 0.0 or hero.ram_immune > 0.0:
		return
	var spd := maxf(paw_vel.length(), v.length() * 0.7)
	if spd < RAM_SPEED:
		return
	if seg_dist(hero.pos, a, b) > PAW_HIT_R + hero.radius:
		return
	var dir := (b - a).normalized()
	if dir == Vector2.ZERO:
		dir = paw_vel.normalized()
	# увернуться можно, только если лапка в одном из слотов внимания
	if hero.focus_ids.has(int(paw["id"])) and randf() < 0.5:
		hero.dodge_paw(dir)
		sfx("whoosh", -10.0, 1.6)
		return
	hero.rammed(dir)
	paw_bruise = PAW_BRUISE
	rams += 1
	shake = 5.0
	_register_hit("paw")
	sfx("ram")
	add_text(hero.pos + Vector2(0, -50), "Таран!", Color("6a4fb3"), 26)


func _update_paw_threat() -> void:
	var was := paw_threat
	paw_threat = false
	if time >= RAM_UNLOCK and paw_bruise <= 0.0 and held_e == null:
		var pp: Vector2 = paw["pos"]
		var to_h := hero.pos - pp
		var d := to_h.length()
		if d < 6.0 * M and d > 1.0:
			paw_threat = paw_vel.dot(to_h / d) > RAM_SPEED * 0.55
	if paw_threat:
		if not was and time > paw_seen_until:
			paw["born"] = time
		paw_seen_until = time + 0.5


## Быстрая лапка, летящая к попугаю, борется за слот внимания ещё полсекунды.
func paw_seen() -> bool:
	return paw_bruise <= 0.0 and time < paw_seen_until


func _paw_push(delta: float) -> void:
	if paw_bruise > 0.0 or held_e != null:
		return
	var spd := paw_vel.length()
	if spd < 40.0:
		return
	var dir := paw_vel / spd
	var pp: Vector2 = paw["pos"]
	var cand: Array = []
	for e in enemies_near(pp, PAW_PUSH_R, 999):
		if e.push_factor > 0.0:
			cand.append(e)
	if cand.size() > PAW_PUSH_MAX:
		cand.resize(PAW_PUSH_MAX)
	for e in cand:
		# сила пропорциональна скорости курсора, но не больше 60% скорости юнита
		var want: Vector2 = dir * minf(spd * 0.3, 0.6 * e.top_speed()) * e.push_factor
		e.push_vel = e.push_vel.lerp(want, clampf(delta * 12.0, 0.0, 1.0))
		e.tumble = 0.35


func _try_grab(p: Vector2) -> void:
	if held_e != null or paw_bruise > 0.0 or over != "" or paused or not FIELD.has_point(p):
		return
	var best: Enemy = null
	var bd := GRAB_R
	for e in enemies_near(p, GRAB_R + 12.0, 6):
		if e.grabbable() and p.distance_to(e.pos) < bd + e.radius * 0.5:
			best = e
			bd = p.distance_to(e.pos)
	if best == null:
		return
	held_e = best
	enemies.erase(best)
	best.push_vel = Vector2.ZERO
	sfx("grab", -4.0, randf_range(0.9, 1.1))


func _release_grab() -> void:
	if held_e == null:
		return
	var e := held_e
	held_e = null
	var v := paw_vel.limit_length(1500.0)
	if v.length() < 260.0:
		e.stun = 0.4
		e.pos = resolve_circle(e.pos, e.radius)
		enemies.append(e)
		return
	thrown.append({"id": new_id(), "pos": e.pos, "vel": v, "e": e, "born": time, "spin": 0.0})
	sfx("throw", -4.0, randf_range(0.9, 1.2))


func _update_thrown(delta: float) -> void:
	for s in thrown:
		var e: Enemy = s["e"]
		var v: Vector2 = s["vel"]
		var p: Vector2 = s["pos"] + v * delta
		s["spin"] = float(s["spin"]) + delta * 18.0
		v *= exp(-1.3 * delta)
		var land := false
		if is_blocked(p):
			land = true
			p = resolve_circle(p, e.radius)
			v = -v * 0.3
			sfx("bounce", -10.0, 1.4)
		elif p.distance_to(hero.pos) < hero.radius + e.radius + 4.0:
			# попадание носком: немного урона и толчок
			var dmg := 6.0 + float(horde_level)
			hero.take_damage(dmg, "throw", "Брошенный %s" % String(EDEFS[e.type]["name"]).to_lower(), true)
			hero.knocked(v.normalized(), 180.0, 0.15)
			throws_hit += 1
			land = true
			shake = 3.0
			sfx("hit", 0.0, 1.3)
			sfx("squawk", -4.0, 1.1)
		elif v.length() < 140.0:
			land = true
		s["pos"] = p
		s["vel"] = v
		if land:
			e.pos = p
			e.stun = 0.6
			e.tumble = 0.4
			enemies.append(e)
			s["done"] = true
	thrown = thrown.filter(func(s): return not s.has("done"))


# ---------- меню над колоском ----------

func _gem_at(p: Vector2):
	var best = null
	var bd := 26.0
	for g in gems:
		if g["big"] and not g["glow"] and not g.has("mod"):
			var d := p.distance_to(g["pos"])
			if d < bd:
				bd = d
				best = g
	return best


func menu_button_pos(i: int) -> Vector2:
	var c: Vector2 = menu["gem"]["pos"]
	var dirs := [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
	return c + dirs[i] * MENU_R


func _menu_click(p: Vector2) -> void:
	for i in MENU_OPTS.size():
		if p.distance_to(menu_button_pos(i)) < 26.0:
			var kind: String = MENU_OPTS[i]
			var g: Dictionary = menu["gem"]
			menu = {}
			sfx("tick", 0.0, 1.3)
			if kind == "missile":
				aim = {"gem": g}
				show_hint("Кликните, куда полетит снаряд.", 3.0)
			else:
				g["mod"] = kind
				millet_cd = MILLET_CD
				add_fx({"kind": "sparkle", "pos": g["pos"], "dur": 0.5})
			return
	menu = {}


func _launch_missile(p: Vector2) -> void:
	var g: Dictionary = aim["gem"]
	aim = {}
	if g["taken"]:
		return
	g["taken"] = true
	var dir: Vector2 = (p - Vector2(g["pos"])).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	missiles.append({"id": new_id(), "pos": g["pos"], "vel": dir * 7.0 * M, "bounces": 5, "born": time, "life": 14.0})
	millet_cd = MILLET_CD
	sfx("throw", 0.0, 0.8)


func _update_missiles(delta: float) -> void:
	for s in missiles:
		var v: Vector2 = s["vel"]
		var p: Vector2 = s["pos"]
		var np := p + v * delta
		s["life"] = float(s["life"]) - delta
		if is_blocked(np):
			# отскок: пробуем отразить по одной оси
			if not is_blocked(Vector2(p.x - v.x * delta, np.y)):
				v.x = -v.x
			elif not is_blocked(Vector2(np.x, p.y - v.y * delta)):
				v.y = -v.y
			else:
				v = -v
			s["bounces"] = int(s["bounces"]) - 1
			np = p + v * delta
			sfx("bounce", -6.0, randf_range(0.9, 1.2))
			add_fx({"kind": "ring", "pos": p, "r": 18.0, "dur": 0.2, "color": Color(0.95, 0.75, 0.25, 0.9)})
		s["pos"] = np
		s["vel"] = v
		if np.distance_to(hero.pos) < hero.radius + 12.0:
			hero.take_damage(10.0, "missile", "Просо-снаряд", true)
			hero.knocked(v.normalized(), 120.0, 0.5)
			tricks += 1
			s["life"] = 0.0
			sfx("hit", 0.0, 0.9)
		if int(s["bounces"]) < 0 or float(s["life"]) <= 0.0:
			add_fx({"kind": "poof", "pos": np, "dur": 0.5, "col": Color("f5c84c")})
			s["done"] = true
	missiles = missiles.filter(func(s): return not s.has("done"))


# ---------- кнопки игрока ----------

func cast_meteor() -> void:
	if over != "" or paused or meteor_cd > 0.0:
		return
	var p: Vector2 = paw["pos"]
	if not sim and not FIELD.has_point(p):
		return
	meteor_cd = METEOR_CD
	meteors_cast += 1
	p = p.clamp(floor_rect.position, floor_rect.end)
	meteors.append({"id": new_id(), "pos": p, "born": time, "t": 0.0, "delay": METEOR_DELAY, "r": METEOR_R,
		"landed": false, "land_t": 0.0, "focus_t": -1.0, "notice_t": -1.0})
	sfx("whoosh", -4.0)


func cast_wave() -> void:
	if over != "" or paused or time < WAVE_UNLOCK or wave_cd > 0.0:
		return
	wave_cd = WAVE_CD
	var p: Vector2 = paw["pos"]
	var f := floor_rect
	var dl := p.x - f.position.x
	var dr := f.end.x - p.x
	var dtp := p.y - f.position.y
	var db := f.end.y - p.y
	var mn := minf(minf(dl, dr), minf(dtp, db))
	var base: Vector2
	var along: Vector2
	if mn == dl:
		base = Vector2(f.position.x + 24, clampf(p.y, f.position.y + 170, f.end.y - 170))
		along = Vector2(0, 1)
	elif mn == dr:
		base = Vector2(f.end.x - 24, clampf(p.y, f.position.y + 170, f.end.y - 170))
		along = Vector2(0, 1)
	elif mn == dtp:
		base = Vector2(clampf(p.x, f.position.x + 170, f.end.x - 170), f.position.y + 24)
		along = Vector2(1, 0)
	else:
		base = Vector2(clampf(p.x, f.position.x + 170, f.end.x - 170), f.end.y - 24)
		along = Vector2(1, 0)
	for i in 14:
		var q := resolve_circle(base + along * randf_range(-160.0, 160.0), 12.0)
		if is_blocked(q):
			q = edge_point(0.0)
		spawn_enemy(Enemy.T.SLIPPER if i < 2 else Enemy.T.SOCK, q, true)
	add_fx({"kind": "basket", "pos": base, "dur": 1.2})
	banner("Корзина белья опрокинулась!", Color("6a4fb3"), 28, 1.8)
	sfx("whoosh", 0.0, 0.7)


# ---------- орда ----------

func _director(delta: float) -> void:
	if time >= next_horde:
		horde_level += 1
		next_horde += HORDE_STEP
		banner("Гонг!  Орда: уровень %d" % horde_level, Color("3f6fb5"), 34, 2.4)
		sfx("gong", -4.0)
		for e in enemies:
			e.blue = 0.8
	var rate := (1.0 + time / 60.0 * 0.5) * (1.0 + 0.08 * float(horde_level - 1))
	if time < double_spawn_until:
		rate *= 2.0
	if boss != null and not boss.dead:
		rate *= 0.6
	spawn_acc += rate * delta
	while spawn_acc >= 1.0:
		spawn_acc -= 1.0
		if enemies.size() >= MAX_ENEMIES:
			continue
		var t: int = Enemy.T.SOCK
		var r := randf()
		if time > 100.0 and r < 0.06:
			t = Enemy.T.SPRAYER
		elif time > 60.0 and r < 0.26:
			t = Enemy.T.SLIPPER
		spawn_enemy(t, edge_point(9.0 * M))
	if time >= next_swarm:
		next_swarm = time + randf_range(25.0, 35.0)
		var p := edge_point(10.0 * M)
		# звон слышен до появления: и герой, и игрок знают, откуда катится рой
		add_fx({"kind": "jingle", "pos": p, "dur": 1.4})
		sfx("jingle", -6.0)
		pending.append({"at": time + 1.2, "type": Enemy.T.YARN, "n": 6 + horde_level, "pos": p})
	if time >= next_hand and (boss == null or boss.dead):
		next_hand = time + 60.0
		var e := spawn_enemy(Enemy.T.HAND, edge_point(10.0 * M))
		e.carries_chest = true
		banner("Рука несёт кормушку", Color("b07a1e"), 26, 2.0)
	for pd in pending:
		if time >= float(pd["at"]):
			for i in int(pd["n"]):
				var q: Vector2 = pd["pos"] + Vector2(randf_range(-40, 40), randf_range(-40, 40))
				spawn_enemy(int(pd["type"]), resolve_circle(q, 10.0), bool(pd.get("from_player", false)))
			pd["at"] = INF
	pending = pending.filter(func(pd): return float(pd["at"]) < INF)
	if not boss_announced and time >= BOSS_AT - EVENT_WARN:
		boss_announced = true
		banner("Через 10 с проснётся робот-пылесос", Color("b23a2e"), 30, 3.0)
		sfx("event")
	if boss == null and time >= BOSS_AT:
		boss = spawn_enemy(Enemy.T.BOSS, Vector2(floor_rect.get_center().x, floor_rect.position.y + 200))
		boss.ability_cd = 2.5
		banner("Робот-пылесос проснулся!", Color("b23a2e"), 40, 3.0)
		sfx("boss")
		shake = 10.0
		add_thought("Это ещё что?! Пылесос!")


func spawn_enemy(type: int, p: Vector2, from_player: bool = false) -> Enemy:
	var d: Dictionary = EDEFS[type]
	var e := Enemy.new()
	e.id = new_id()
	e.type = type
	e.pos = p
	e.born = time
	var l := float(horde_level - 1)
	var hp_k := 1.0 + 0.12 * l
	if type == Enemy.T.BOSS or type == Enemy.T.BOX:
		hp_k = 1.0 + 0.1 * float(hero.level)
	e.max_hp = float(d["hp"]) * hp_k
	e.hp = e.max_hp
	e.speed = float(d["speed"]) * M * (1.0 + 0.03 * l)
	e.dmg = float(d["dmg"]) * (1.0 + 0.1 * l)
	e.radius = d["r"]
	e.push_factor = d["push"]
	e.xp = d["xp"]
	e.phase = randf()
	e.from_player = from_player
	enemies.append(e)
	return e


func edge_point(min_dist: float) -> Vector2:
	var f := floor_rect
	var best := f.position + Vector2(20, 20)
	var bd := -1.0
	for i in 16:
		var p: Vector2
		match randi() % 4:
			0:
				p = Vector2(randf_range(f.position.x + 20, f.end.x - 20), f.position.y + 18)
			1:
				p = Vector2(randf_range(f.position.x + 20, f.end.x - 20), f.end.y - 18)
			2:
				p = Vector2(f.position.x + 18, randf_range(f.position.y + 20, f.end.y - 20))
			_:
				p = Vector2(f.end.x - 18, randf_range(f.position.y + 20, f.end.y - 20))
		if is_blocked(p):
			continue
		var d := p.distance_to(hero.pos)
		if d >= min_dist:
			return p
		if d > bd:
			bd = d
			best = p
	return best


func random_floor_point(margin: float = 80.0) -> Vector2:
	for i in 30:
		var p := Vector2(randf_range(floor_rect.position.x + margin, floor_rect.end.x - margin), randf_range(floor_rect.position.y + margin, floor_rect.end.y - margin))
		if not is_blocked(p) and _clearance(p) > margin * 0.6:
			return p
	return floor_rect.get_center()


func _clearance(p: Vector2) -> float:
	var m := 9999.0
	for o in obstacles:
		var q := Vector2(clampf(p.x, o.position.x, o.end.x), clampf(p.y, o.position.y, o.end.y))
		m = minf(m, p.distance_to(q))
	return m


func _build_grid() -> void:
	_grid.clear()
	for e in enemies:
		if e.dead:
			continue
		var k := Vector2i(int(e.pos.x / CELL), int(e.pos.y / CELL))
		if _grid.has(k):
			_grid[k].append(e)
		else:
			_grid[k] = [e]


## Враги в радиусе, ближайшие первыми. Крупные (босс) попадают по краю тела.
func enemies_near(p: Vector2, r: float, limit: int) -> Array:
	var out: Array = []
	var r2 := r * r
	var x0 := int((p.x - r) / CELL)
	var x1 := int((p.x + r) / CELL)
	var y0 := int((p.y - r) / CELL)
	var y1 := int((p.y + r) / CELL)
	for gx in range(x0, x1 + 1):
		for gy in range(y0, y1 + 1):
			var cell = _grid.get(Vector2i(gx, gy))
			if cell == null:
				continue
			for e in cell:
				if e.dead or e.type == Enemy.T.BOSS:
					continue
				var d2: float = p.distance_squared_to(e.pos)
				if d2 < r2:
					out.append([d2, e])
	if boss != null and not boss.dead:
		var bd := p.distance_to(boss.pos) - boss.radius
		if bd < r:
			out.append([maxf(bd, 0.0) * maxf(bd, 0.0), boss])
	out.sort_custom(func(a, b): return a[0] < b[0])
	var res: Array = []
	for i in mini(limit, out.size()):
		res.append(out[i][1])
	return res


func _update_enemies(delta: float) -> void:
	_build_grid()
	var hp_pos := hero.pos
	for e in enemies:
		if e.dead:
			continue
		e.flash = maxf(0.0, e.flash - delta)
		e.blue = maxf(0.0, e.blue - delta)
		e.atk_cd -= delta
		e.stun = maxf(0.0, e.stun - delta)
		e.slow = maxf(0.0, e.slow - delta)
		e.fear = maxf(0.0, e.fear - delta)
		e.tumble = maxf(0.0, e.tumble - delta)
		e.orbit_cd = maxf(0.0, e.orbit_cd - delta)
		if e.burn > 0.0:
			e.burn -= delta
			damage_enemy(e, e.burn_dps * delta, Vector2.ZERO, false)
			if e.dead:
				continue
		var to_h := hp_pos - e.pos
		var d := to_h.length()
		var dir := to_h / maxf(d, 0.001)
		var spd := e.speed
		match e.type:
			Enemy.T.SOCK:
				e.phase = fmod(e.phase + delta * 1.1, 1.0)
				spd = e.speed * 2.8 if e.is_airborne() else 0.0
			Enemy.T.SUPER:
				spd = _update_super(e, delta, d, dir)
				if e.state == 2:
					dir = e.dash_dir
			Enemy.T.YARN:
				dir = dir.rotated(sin(time * 3.0 + float(e.id)) * 0.35)
				e.phase += delta * 12.0
				e.trail.push_front(e.pos)
				if e.trail.size() > 8:
					e.trail.pop_back()
			Enemy.T.DUST:
				e.phase += delta * 6.0
				dir = dir.rotated(sin(time * 5.0 + float(e.id)) * 0.5)
			Enemy.T.SLIPPER:
				e.phase = fmod(e.phase + delta * 1.4, 1.0)
			Enemy.T.SPRAYER:
				e.shoot_cd -= delta
				if d < 4.5 * M:
					dir = -dir
				elif d < 7.0 * M:
					spd = 0.0
				if d < 8.0 * M and e.shoot_cd <= 0.0 and e.stun <= 0.0:
					e.shoot_cd = 4.5
					enemy_shots.append({"id": new_id(), "pos": e.pos, "vel": to_h / maxf(d, 0.001) * 3.0 * M, "dmg": e.dmg,
						"life": 4.0, "born": time, "r": 13.0, "from_player": e.from_player})
			Enemy.T.HAND:
				e.grab_cd -= delta
				e.phase = fmod(e.phase + delta * 2.5, 1.0)
				if e.grab_state == 1:
					spd = 0.0
					e.grab_t -= delta
					if e.grab_t <= 0.0:
						e.grab_state = 0
						e.grab_cd = 2.5
						if d < 1.9 * M and hero.held <= 0.0 and e.stun <= 0.0:
							hero.grabbed(e)
							sfx("grab", 0.0, 0.6)
				elif d < 1.5 * M and e.grab_cd <= 0.0 and e.stun <= 0.0:
					# перед хватом приседает и растопыривает пальцы: 0,5 с предупреждения
					e.grab_state = 1
					e.grab_t = 0.5
			Enemy.T.BOX:
				e.phase += delta * 10.0
				var away := -dir
				var c := floor_rect.get_center() - e.pos
				dir = (away + c.normalized() * clampf(1.0 - _wall_dist(e.pos) / (3.0 * M), 0.0, 1.0) * 1.6).normalized()
				dir = dir.rotated(sin(time * 2.0) * 0.5)
				e.shoot_cd -= delta
				if e.shoot_cd <= 0.0:
					e.shoot_cd = 0.6
					_drop_gem(e.pos, false)
			Enemy.T.BOSS:
				spd = _update_boss(e, delta, d, dir)
				if e.state == 3:
					dir = e.dash_dir
		if e.fear > 0.0:
			dir = -dir
		if e.stun > 0.0 or e.tumble > 0.0:
			spd = 0.0
		if e.slow > 0.0:
			spd *= 0.5
		if spd > 0.0:
			e.move_dir = dir
		e.pos += (dir * spd + e.push_vel) * delta
		e.push_vel *= exp(-3.0 * delta)
		if e.type != Enemy.T.BOSS:
			_separate(e)
		e.pos = resolve_circle(e.pos, e.radius)
		var md := e.radius + hero.radius
		if d < md:
			if e.type != Enemy.T.HAND and e.type != Enemy.T.BOX and e.atk_cd <= 0.0 and not e.is_airborne() and e.tumble <= 0.0 and e.stun <= 0.0:
				e.atk_cd = 0.9
				hero.take_damage(e.dmg, ENAMES[e.type], src_label(e), e.from_player)
			if d > 0.5 and e.type != Enemy.T.BOSS:
				e.pos = hp_pos - dir * md


func _wall_dist(p: Vector2) -> float:
	var f := floor_rect
	return minf(minf(p.x - f.position.x, f.end.x - p.x), minf(p.y - f.position.y, f.end.y - p.y))


## Суперносок из «яйца»: прыгает быстрее и раз в 3 с делает рывок с предупреждением.
func _update_super(e: Enemy, delta: float, d: float, dir: Vector2) -> float:
	e.phase = fmod(e.phase + delta * 1.6, 1.0)
	e.ability_cd -= delta
	match e.state:
		0:
			if d < 6.0 * M and e.ability_cd <= 0.0 and e.stun <= 0.0:
				e.state = 1
				e.state_t = 0.45
				e.dash_dir = dir
			return e.speed * 2.4 if e.is_airborne() else 0.0
		1:
			e.state_t -= delta
			if e.state_t <= 0.0:
				e.state = 2
				e.state_t = 0.35
				sfx("dash", -6.0)
			return 0.0
		_:
			e.state_t -= delta
			if e.state_t <= 0.0:
				e.state = 0
				e.ability_cd = 3.0
			return 11.0 * M
	return 0.0


## Робот-пылесос: ползёт к попугаю и раз в несколько секунд сам выбирает умение:
## засасывание (тянет героя и просо), таран по линии с предупреждением, плевок пылевыми зайчиками.
func _update_boss(e: Enemy, delta: float, d: float, dir: Vector2) -> float:
	e.phase += delta
	e.ability_cd -= delta
	match e.state:
		0:
			if e.ability_cd <= 0.0 and e.stun <= 0.0:
				var r := randf()
				if r < 0.38 and d < 9.0 * M:
					e.state = 1
					e.state_t = 2.6
					sfx("suck", -2.0)
					add_thought("Пылесос засасывает! Держусь.")
				elif r < 0.75:
					e.state = 2
					e.state_t = 0.9
					e.dash_dir = dir
					sfx("event", -8.0, 0.7)
				else:
					e.state = 4
					e.state_t = 0.6
			return e.speed
		1:
			e.state_t -= delta
			if d < 9.0 * M:
				hero.pull_vel += -dir * 1.7 * M
			for g in gems:
				var gp: Vector2 = g["pos"]
				if gp.distance_to(e.pos) < 7.0 * M:
					g["pos"] = gp.move_toward(e.pos, 3.0 * M * delta)
					if gp.distance_to(e.pos) < e.radius:
						g["taken"] = true
			for o in enemies_near(e.pos, 6.0 * M, 40):
				if o != e and not o.is_big():
					o.push_vel += (e.pos - o.pos).normalized() * 40.0 * delta * 10.0
			if e.state_t <= 0.0:
				e.state = 0
				e.ability_cd = 2.5
			return 0.0
		2:
			e.state_t -= delta
			if e.state_t <= 0.0:
				e.state = 3
				e.state_t = 1.4
				sfx("dash", 0.0, 0.5)
			return 0.0
		3:
			e.state_t -= delta
			var nxt := e.pos + e.dash_dir * 9.0 * M * delta
			var hit_wall := not floor_rect.grow(-e.radius - 2.0).has_point(nxt)
			for o in obstacles:
				if o.grow(e.radius - 6.0).has_point(nxt):
					hit_wall = true
			if e.pos.distance_to(hero.pos) < e.radius + hero.radius + 6.0 and hero.stun <= 0.0:
				hero.take_damage(20.0 + 2.0 * horde_level, "boss", "Пылесос", false)
				hero.knocked(e.dash_dir.rotated(PI * 0.5 * signf(randf() - 0.5)), 420.0, 0.35)
				sfx("thud")
				shake = 7.0
			if hit_wall or e.state_t <= 0.0:
				e.state = 0
				e.ability_cd = 2.2
				if hit_wall:
					e.stun = 1.0
					shake = 8.0
					sfx("thud", 0.0, 0.7)
					add_fx({"kind": "dust", "pos": e.pos + e.dash_dir * e.radius, "r": 50.0, "dur": 0.5})
				return 0.0
			return 9.0 * M
		4:
			e.state_t -= delta
			if e.state_t <= 0.0:
				for i in 6:
					var a := TAU * i / 6.0
					spawn_enemy(Enemy.T.DUST, resolve_circle(e.pos + Vector2(cos(a), sin(a)) * (e.radius + 20.0), 9.0))
				add_fx({"kind": "dust", "pos": e.pos, "r": 70.0, "dur": 0.6})
				sfx("pop", 0.0, 0.5)
				e.state = 0
				e.ability_cd = 3.0
			return 0.0
	return e.speed


func _separate(e: Enemy) -> void:
	var cx := int(e.pos.x / CELL)
	var cy := int(e.pos.y / CELL)
	var push := Vector2.ZERO
	for gx in range(cx - 1, cx + 2):
		for gy in range(cy - 1, cy + 2):
			var cell = _grid.get(Vector2i(gx, gy))
			if cell == null:
				continue
			for o in cell:
				if o == e or o.dead:
					continue
				var dv: Vector2 = e.pos - o.pos
				var md: float = e.radius + o.radius
				var l2 := dv.length_squared()
				if l2 < md * md and l2 > 0.0001:
					var l := sqrt(l2)
					push += dv / l * (md - l) * 0.5
	if boss != null and not boss.dead and e != boss:
		var dv := e.pos - boss.pos
		var md := e.radius + boss.radius
		if dv.length() < md and dv.length() > 0.01:
			e.pos = boss.pos + dv.normalized() * md
	e.pos += push.limit_length(8.0)


func src_label(e: Enemy) -> String:
	var n: String = EDEFS[e.type]["name"]
	return n + " из вашей волны" if e.from_player else n


func damage_enemy(e: Enemy, amount: float, kb: Vector2, show: bool = true) -> void:
	if e.dead:
		return
	e.hp -= amount
	if show:
		e.flash = 0.1
	if e.push_factor > 0.0:
		e.push_vel += kb * e.push_factor
	if e.hp <= 0.0:
		_kill(e)


func _kill(e: Enemy) -> void:
	e.dead = true
	kills += 1
	if hero.mode == Hero.Mode.EVENT and not event.is_empty() and event["type"] == "circle":
		if hero.pos.distance_to(event["pos"]) < float(event["r"]):
			event["kills"] = float(event["kills"]) + 1.0
	add_fx({"kind": "poof", "pos": e.pos, "dur": 0.35, "col": Color("f1eee8"), "r": e.radius})
	sfx("pop", -12.0, randf_range(0.8, 1.3))
	match e.type:
		Enemy.T.SOCK, Enemy.T.DUST:
			_drop_gem(e.pos, false)
		Enemy.T.YARN:
			if randf() < 0.6:
				_drop_gem(e.pos, false)
		Enemy.T.SLIPPER, Enemy.T.SUPER:
			_drop_gem(e.pos, true)
		Enemy.T.SPRAYER:
			_drop_gem(e.pos + Vector2(-5, 0), false)
			_drop_gem(e.pos + Vector2(5, 0), false)
		Enemy.T.HAND:
			if e.carries_chest:
				chests.append({"id": new_id(), "pos": e.pos, "born": time, "life": 30.0, "taken": false})
				add_thought("Рука уронила кормушку!")
			_drop_gem(e.pos + Vector2(-14, 8), true)
			_drop_gem(e.pos + Vector2(14, 8), true)
		Enemy.T.BOX:
			_event_success()
			for i in 6:
				_drop_gem(e.pos + Vector2(randf_range(-30, 30), randf_range(-30, 30)), i < 2)
		Enemy.T.BOSS:
			boss_defeated = true
			banner("Пылесос сломан!", Color("4f8f3a"), 42, 3.0)
			add_thought("Я сломал пылесос! Я легенда!")
			hero.add_fruit(Skills.FRUITS[randi() % Skills.FRUITS.size()])
			hero.add_fruit("apple")
			hero.xp += 40
			shake = 12.0
			sfx("win", -4.0)
			for i in 10:
				_drop_gem(e.pos + Vector2(randf_range(-60, 60), randf_range(-60, 60)), true)


func _drop_gem(p: Vector2, big: bool, glow: bool = false) -> Dictionary:
	var g := {"id": new_id(), "pos": p, "big": big, "glow": glow, "xp": 5 if big else 1, "born": time, "taken": false}
	gems.append(g)
	return g


# ---------- снаряды, книги, подбор ----------

func _update_shots(delta: float) -> void:
	for s in shots:
		var v: Vector2 = s["vel"]
		if s["homing"]:
			var ts := enemies_near(s["pos"], 4.0 * M, 1)
			if not ts.is_empty():
				var want: Vector2 = (ts[0].pos - Vector2(s["pos"])).normalized() * v.length()
				v = v.lerp(want, clampf(delta * 6.0, 0.0, 1.0))
		var np: Vector2 = s["pos"] + v * delta
		s["life"] = float(s["life"]) - delta
		if is_blocked(np):
			if int(s["bounce"]) > 0:
				s["bounce"] = int(s["bounce"]) - 1
				var p: Vector2 = s["pos"]
				if not is_blocked(Vector2(p.x - v.x * delta, np.y)):
					v.x = -v.x
				elif not is_blocked(Vector2(np.x, p.y - v.y * delta)):
					v.y = -v.y
				else:
					v = -v
				np = p + v * delta
			else:
				s["life"] = 0.0
				continue
		s["pos"] = np
		s["vel"] = v
		for e in enemies_near(np, 30.0, 4):
			var hit: Array = s["hit"]
			if hit.has(e.id) or np.distance_to(e.pos) > e.radius + 6.0:
				continue
			hit.append(e.id)
			damage_enemy(e, float(s["dmg"]), v.normalized() * 80.0)
			if s["ice"]:
				e.slow = 1.5
			s["pierce"] = int(s["pierce"]) - 1
			if int(s["pierce"]) <= 0:
				s["life"] = 0.0
				break
	shots = shots.filter(func(s): return float(s["life"]) > 0.0)
	for s in enemy_shots:
		s["pos"] += s["vel"] * delta
		s["life"] = float(s["life"]) - delta
		var sp: Vector2 = s["pos"]
		if is_blocked(sp):
			s["life"] = 0.0
		elif sp.distance_to(hero.pos) < hero.radius + float(s["r"]):
			s["life"] = 0.0
			var lbl := "Пульверизатор из вашей волны" if s["from_player"] else "Пульверизатор"
			hero.take_damage(float(s["dmg"]), "sprayer", lbl, bool(s["from_player"]))
	enemy_shots = enemy_shots.filter(func(s): return float(s["life"]) > 0.0)


func _update_meteors(delta: float) -> void:
	for m in meteors:
		if not m["landed"]:
			m["t"] = float(m["t"]) + delta
			if float(m["t"]) >= float(m["delay"]):
				_meteor_land(m)
		else:
			m["land_t"] = float(m["land_t"]) + delta
	meteors = meteors.filter(func(m): return not m["landed"] or float(m["land_t"]) < 0.9)


func _meteor_land(m: Dictionary) -> void:
	m["landed"] = true
	m["land_t"] = 0.0
	shake = 9.0
	sfx("thud")
	var p: Vector2 = m["pos"]
	add_fx({"kind": "dust", "pos": p, "r": METEOR_R, "dur": 0.5})
	if hero.pos.distance_to(p) <= METEOR_R + hero.radius * 0.5:
		meteor_hits += 1
		hero.wariness["meteor"] = float(hero.wariness["meteor"]) + 0.25
		hero.say("Ай! Не заметил книгу." if float(m["notice_t"]) < 0.0 else "Не успел увернуться от книги!")
		hero.take_damage(hero.max_hp() * 0.15, "meteor", "Книга с полки", true)
		sfx("squawk")
	elif float(m["notice_t"]) >= 0.0 and hero.pos.distance_to(p) < METEOR_R + 2.0 * M:
		_sim_dodged += 1
	for e in enemies_near(p, METEOR_R, 999):
		if e.type == Enemy.T.BOSS:
			damage_enemy(e, 60.0, Vector2.ZERO)
			continue
		e.stun = 1.0
		e.push_vel += (e.pos - p).normalized() * 200.0 * e.push_factor


func _update_delayed() -> void:
	for d in delayed:
		if time < float(d["at"]):
			continue
		match d["kind"]:
			"echo":
				hero.scream_at(float(d["r"]), float(d["dmg"]))
			"hatch":
				var e := spawn_enemy(Enemy.T.SUPER, resolve_circle(d["pos"], 15.0), true)
				e.ability_cd = 1.0
				add_fx({"kind": "poof", "pos": d["pos"], "dur": 0.5, "col": Color("fff6e0"), "r": 20.0})
				sfx("egg")
		d["done"] = true
	delayed = delayed.filter(func(d): return not d.has("done"))


func on_gem_taken(g: Dictionary) -> void:
	if g.has("mod"):
		tricks += 1
		hero.wariness["millet"] = minf(0.8, float(hero.wariness["millet"]) + 0.3)
		match g["mod"]:
			"trap":
				hero.trapped = 1.0
				hero.say("Ай! Капкан! Это просо подозрительное.")
				add_fx({"kind": "trap", "pos": hero.pos, "dur": 1.0})
				sfx("trap")
				_register_hit("trap")
				add_text(hero.pos + Vector2(0, -50), "Капкан!", Color("6a4fb3"), 24)
			"rotten":
				hero.take_damage(8.0, "rotten", "Тухлое просо", true)
				hero.say("Фу! Тухлое!")
				add_fx({"kind": "stink", "pos": hero.pos, "dur": 1.2})
				sfx("rotten")
			"egg":
				hero.say("Это было яйцо?!")
				delayed.append({"at": time + 0.6, "kind": "hatch", "pos": g["pos"]})
				add_fx({"kind": "egg", "pos": g["pos"], "dur": 0.6})
				sfx("egg")
		return
	hero.xp += int(g["xp"])
	if g["glow"] and not event.is_empty() and event["type"] == "glow":
		event["got"] = int(event["got"]) + 1
		sfx("chime", -6.0, 1.5)
		add_text(g["pos"] + Vector2(0, -20), "%d/%d" % [int(event["got"]), GLOW_NEED], Color("2f8fa8"), 20)
	else:
		sfx("pickup", -16.0, randf_range(0.9, 1.3))


func _update_pickups(delta: float) -> void:
	gems = gems.filter(func(g): return not g["taken"])
	while gems.size() > MAX_GEMS:
		gems.pop_front()
	for c in chests:
		c["life"] = float(c["life"]) - delta
		if float(c["life"]) <= 0.0 and not c["taken"]:
			c["taken"] = true
			chests_denied += 1
			add_fx({"kind": "stamp", "pos": c["pos"], "dur": 2.0})
			add_thought("Кормушка пропала... Обидно.")
			sfx("fail")
	chests = chests.filter(func(c): return not c["taken"])


func open_chest(c: Dictionary) -> void:
	c["taken"] = true
	hero.chests_opened += 1
	var got: Array = []
	var keys: Array = []
	for k in hero.skills:
		if int(hero.skills[k]) < Skills.MAX_SKILL_LVL:
			keys.append(k)
	for k in hero.general:
		if int(hero.general[k]) < Skills.MAX_GEN_LVL:
			keys.append(k)
	var rare := randf() < 0.15
	for i in (2 if rare else 1):
		if keys.is_empty():
			break
		var k: String = keys[randi() % keys.size()]
		var lvl := hero.lvl_of(k) + 1
		hero.apply_card({"key": k, "lvl": lvl, "kind": "skill" if Skills.is_skill(k) else "general"})
		got.append("%s ур. %d" % [Skills.NAMES[k], lvl])
		if lvl >= (Skills.MAX_SKILL_LVL if Skills.is_skill(k) else Skills.MAX_GEN_LVL):
			keys.erase(k)
	if got.is_empty():
		var f: String = Skills.FRUITS[randi() % Skills.FRUITS.size()]
		hero.add_fruit(f)
		got.append(Skills.FRUIT_NAMES[f])
	hero.say("Кормушка: %s." % ", ".join(got))
	sfx("chime")
	if rare:
		power_flash = 0.6
		banner("Он нашёл силу", Color("b23a2e"), 34, 2.0)


# ---------- ивенты ----------

func event_progress() -> float:
	if event.is_empty():
		return 0.0
	match event["type"]:
		"circle":
			return clampf(float(event["kills"]) / float(event["need"]), 0.0, 1.0)
		"glow":
			return clampf(float(event["got"]) / float(GLOW_NEED), 0.0, 1.0)
		"box":
			for e in enemies:
				if e.type == Enemy.T.BOX:
					return clampf(1.0 - e.hp / e.max_hp, 0.0, 1.0)
	return 0.0


func next_queue_index() -> int:
	for i in queue.size():
		if not queue[i].has("done"):
			return i
	return -1


func queue_locked(i: int) -> bool:
	return time >= float(queue[i]["at"]) - EVENT_WARN or queue[i].has("done")


func _update_events(delta: float) -> void:
	var i := next_queue_index()
	if i >= 0 and event.is_empty():
		var q: Dictionary = queue[i]
		if event_announced != i and time >= float(q["at"]) - EVENT_WARN:
			event_announced = i
			banner("Через 10 с: %s" % Skills.EVENT_NAMES[q["type"]], Color("b07a1e"), 28, 2.5)
			sfx("event", -4.0)
		if time >= float(q["at"]):
			q["done"] = true
			_start_event(q["type"])
			event["qi"] = i
	if event.is_empty():
		return
	event["left"] = float(event["left"]) - delta
	match event["type"]:
		"circle":
			if hero.pos.distance_to(event["pos"]) > float(event["r"]):
				# вышел — прогресс тает
				event["kills"] = maxf(0.0, float(event["kills"]) - 1.0 * delta)
			if float(event["kills"]) >= float(event["need"]):
				_event_success()
				return
		"glow":
			if int(event["got"]) >= GLOW_NEED:
				_event_success()
				return
		"altar":
			if hero.pos.distance_to(event["pos"]) < hero.radius + 20.0:
				hero.xp += hero.xp_next
				double_spawn_until = time + 15.0
				banner("Герой взял лакомство: орда ×2 на 15 с!", Color("b23a2e"), 28, 2.5)
				_event_success()
				return
	if float(event["left"]) <= 0.0:
		_event_fail()


func _start_event(type: String) -> void:
	event = {"type": type, "id": new_id(), "born": time, "left": 30.0}
	match type:
		"circle":
			event["pos"] = random_floor_point(140.0)
			event["r"] = 3.5 * M
			event["kills"] = 0.0
			event["need"] = 20.0
		"glow":
			event["left"] = 30.0
			event["got"] = 0
			for k in 8:
				_drop_gem(random_floor_point(60.0), false, true)
		"box":
			event["left"] = 20.0
			var e := spawn_enemy(Enemy.T.BOX, edge_point(8.0 * M))
			e.shoot_cd = 0.6
		"altar":
			event["left"] = 20.0
			event["pos"] = random_floor_point(100.0)
	banner(Skills.EVENT_NAMES[type] + "!", Color("b07a1e"), 34, 2.0)
	sfx("event")


func _event_reward() -> String:
	var f: String = Skills.FRUITS[randi() % Skills.FRUITS.size()]
	hero.add_fruit(f)
	hero.xp += 15 + 3 * hero.level
	return f


func _event_success() -> void:
	if event.is_empty():
		return
	var f := _event_reward()
	hero.events_done += 1
	_mark_result("ok")
	add_thought("%s: готово! Получил %s." % [Skills.EVENT_NAMES[event["type"]], String(Skills.FRUIT_NAMES[f]).to_lower()])
	banner("Герой прошёл ивент: +%s" % String(Skills.FRUIT_NAMES[f]).to_lower(), Color("8a5a1e"), 26, 2.0)
	sfx("chime")
	_end_event()


func _event_fail() -> void:
	var ok_ignore: bool = event["type"] == "altar"
	_mark_result("skip" if ok_ignore else "fail")
	if not ok_ignore:
		events_denied += 1
		banner("СОРВАНО: %s" % Skills.EVENT_NAMES[event["type"]], Color("b23a2e"), 32, 2.2)
		add_thought("Не успел: %s. Обидно." % Skills.EVENT_NAMES[event["type"]])
		sfx("fail")
	else:
		add_thought("Лакомство подозрительное. Пропущу.")
	_end_event()


func _end_event() -> void:
	match event["type"]:
		"glow":
			for g in gems:
				if g["glow"]:
					g["taken"] = true
		"box":
			for e in enemies:
				if e.type == Enemy.T.BOX and not e.dead:
					e.dead = true
					add_fx({"kind": "poof", "pos": e.pos, "dur": 0.5, "col": Color("c98fb0"), "r": 20.0})
	event["taken"] = true
	event = {}


func _mark_result(r: String) -> void:
	if event.has("qi"):
		queue[int(event["qi"])]["result"] = r


## Перестановка ивентов в очереди (перетаскивание в левой полосе).
func move_queue(from: int, to: int) -> void:
	if from == to or from < 0 or to < 0 or from >= queue.size() or to >= queue.size():
		return
	if queue_locked(from) or queue_locked(to):
		return
	var a: String = queue[from]["type"]
	queue[from]["type"] = queue[to]["type"]
	queue[to]["type"] = a
	sfx("tick", 0.0, 1.2)


# ---------- фрукты ----------

func on_fruit_eaten(f: String) -> void:
	sfx("fruit")
	add_fx({"kind": "eat", "pos": hero.pos, "dur": 0.6, "fruit": f})
	match f:
		"apple":
			hero.hp = minf(hero.max_hp(), hero.hp + 40.0)
			add_text(hero.pos + Vector2(0, -50), "+40", Color("5a9a4a"), 22)
		"chili":
			var rr := 3.5 * M
			for e in enemies_near(hero.pos, rr, 999):
				damage_enemy(e, 40.0 + 4.0 * hero.level, (e.pos - hero.pos).normalized() * 200.0)
				e.burn = 2.0
				e.burn_dps = 6.0
			add_fx({"kind": "fire", "pos": hero.pos, "r": rr, "dur": 0.6})
			sfx("fire")
		"carrot":
			hero.speed_t = 5.0
		"grape":
			hero.xp += hero.xp_next
		"lemon":
			hero.shield_hits = 3


# ---------- левелап героя: замедление и видимый выбор ----------

const LU_SLOW := 2.6
const LU_PICK := 1.8
const LU_END := 4.2


func _make_cards() -> Array:
	var pool: Array = []
	var h := hero
	for k in Skills.SKILLS:
		if h.skills.has(k):
			if int(h.skills[k]) < Skills.MAX_SKILL_LVL:
				pool.append({"key": k, "lvl": int(h.skills[k]) + 1, "new": false, "kind": "skill"})
		elif h.skills.size() < Skills.MAX_SKILLS:
			pool.append({"key": k, "lvl": 1, "new": true, "kind": "skill"})
	for k in Skills.GENERAL:
		if h.general.has(k):
			if int(h.general[k]) < Skills.MAX_GEN_LVL:
				pool.append({"key": k, "lvl": int(h.general[k]) + 1, "new": false, "kind": "general"})
		elif h.general.size() < Skills.MAX_GENERAL:
			pool.append({"key": k, "lvl": 1, "new": true, "kind": "general"})
	# особая пассивка: одна на умение, из пяти вариантов предлагаются два
	for s in h.skills:
		if not h.mods.has(s):
			var opts: Array = Skills.MODS[s].duplicate()
			opts.shuffle()
			for m in opts.slice(0, 2):
				pool.append({"key": m, "lvl": 1, "new": true, "kind": "mod"})
	pool.shuffle()
	return pool.slice(0, 3)


func begin_levelup() -> void:
	hero.consume_level()
	var cards := _make_cards()
	if cards.is_empty():
		hero.hp = minf(hero.max_hp(), hero.hp + 20.0)
		return
	var scored: Array = []
	var best := 0
	for i in cards.size():
		var r: Dictionary = hero.score_card(cards[i])
		scored.append(r)
		if float(r["score"]) > float(scored[best]["score"]):
			best = i
	levelup = {"cards": cards, "scores": scored, "chosen": best, "t": 0.0, "applied": false, "level": hero.level}
	hero.choosing = true
	sfx("level", -4.0)


func _update_levelup(real_dt: float) -> void:
	if levelup.is_empty():
		if not paused:
			Engine.time_scale = game_speed
		return
	if paused or over != "":
		return
	levelup["t"] = float(levelup["t"]) + real_dt
	var t: float = levelup["t"]
	Engine.time_scale = game_speed * (0.3 if t < LU_SLOW else 1.0)
	if t >= LU_PICK and not levelup.has("picked"):
		levelup["picked"] = true
		sfx("chime", -6.0)
	if t >= LU_SLOW and not levelup["applied"]:
		levelup["applied"] = true
		var c: Dictionary = levelup["cards"][int(levelup["chosen"])]
		var r: Dictionary = levelup["scores"][int(levelup["chosen"])]
		hero.apply_card(c)
		hero.choosing = false
		var nm: String = Skills.NAMES[c["key"]]
		if not c["new"]:
			nm += " ур. %d" % int(c["lvl"])
		hero.say("Беру %s: %s." % [nm, r["reason"]])
	if t >= LU_END:
		levelup = {}


# ---------- урон по герою и награды игроку ----------

func on_hero_damaged(a: float, src: String, label: String, from_player: bool) -> void:
	dmg_by_src[src] = int(dmg_by_src.get(src, 0)) + int(a)
	var mine := from_player or src == "meteor" or src == "paw"
	if mine:
		player_damage += a
		add_text(hero.pos + Vector2(randf_range(-12, 12), -48), "%s: −%d" % [label, int(round(a))], Color("b23a2e"), 22)
	else:
		add_text(hero.pos + Vector2(randf_range(-12, 12), -40), "−%d" % int(round(a)), Color("7a5a4a"), 15)
	if a >= 3.0:
		sfx("squawk", -10.0, randf_range(0.95, 1.2))
	var kind := src
	if from_player and not ["throw", "rotten", "missile", "meteor", "paw"].has(src):
		kind = "wave"
	_register_hit(kind)


## «Загон»: три разных источника урона за 5 секунд.
func _register_hit(src: String) -> void:
	combo_log.append([time, src])
	combo_log = combo_log.filter(func(c): return float(c[0]) > time - 5.0)
	var kinds := {}
	var has_mine := false
	for c in combo_log:
		kinds[c[1]] = true
		if ["meteor", "paw", "wave", "throw", "trap", "rotten", "missile"].has(c[1]):
			has_mine = true
	if kinds.size() >= 3 and has_mine and combo_cd <= 0.0:
		combo_cd = 6.0
		combos += 1
		banner("ЗАГОН!", Color("b23a2e"), 44, 1.6)
		sfx("gong", -6.0, 1.5)


func hero_died() -> void:
	if over != "":
		return
	over = "hero_dead"
	hero.say("...Попался.")
	banner("ПОПАЛСЯ!", Color("b23a2e"), 56, 99.0)
	sfx("win")


func last_chance() -> float:
	if time > RUN_LENGTH - 50.0 and (hero.chests_opened < 2 or hero.events_done < 3):
		return clampf((time - (RUN_LENGTH - 50.0)) / 50.0, 0.0, 1.0)
	return 0.0


# ---------- геометрия комнаты ----------

func is_blocked(p: Vector2) -> bool:
	if not floor_rect.grow(-10.0).has_point(p):
		return true
	for o in obstacles:
		if o.grow(10.0).has_point(p):
			return true
	return false


func resolve_circle(p: Vector2, r: float) -> Vector2:
	p.x = clampf(p.x, floor_rect.position.x + r, floor_rect.end.x - r)
	p.y = clampf(p.y, floor_rect.position.y + r, floor_rect.end.y - r)
	for o in obstacles:
		var q := Vector2(clampf(p.x, o.position.x, o.end.x), clampf(p.y, o.position.y, o.end.y))
		var dv := p - q
		var l := dv.length()
		if l < r:
			if l > 0.001:
				p = q + dv / l * r
			else:
				var c := o.get_center()
				var dx := (o.size.x * 0.5 + r) - absf(p.x - c.x)
				var dy := (o.size.y * 0.5 + r) - absf(p.y - c.y)
				if dx < dy:
					p.x += dx * signf(p.x - c.x if p.x != c.x else 1.0)
				else:
					p.y += dy * signf(p.y - c.y if p.y != c.y else 1.0)
	return p


# ---------- эффекты и тексты ----------

func add_fx(f: Dictionary) -> void:
	f["t"] = 0.0
	fx.append(f)


func _update_fx(delta: float) -> void:
	for f in fx:
		f["t"] = float(f["t"]) + delta
		if f["kind"] == "burnline":
			var a: Vector2 = f["pos"]
			var b: Vector2 = f["to"]
			for e in enemies_near(a.lerp(b, 0.5), a.distance_to(b) * 0.5 + 20.0, 999):
				if seg_dist(e.pos, a, b) < e.radius + 12.0:
					damage_enemy(e, float(f["dps"]) * delta, Vector2.ZERO, false)
	fx = fx.filter(func(f): return float(f["t"]) < float(f["dur"]))
	for t in texts:
		t["t"] = float(t["t"]) + delta
		t["pos"] += Vector2(0, -28.0 * delta)
	texts = texts.filter(func(t): return float(t["t"]) < 1.2)


func add_text(p: Vector2, s: String, col: Color, size: int) -> void:
	if texts.size() > 40:
		texts.pop_front()
	texts.append({"pos": p, "text": s, "color": col, "size": size, "t": 0.0})


func add_thought(s: String) -> void:
	if thoughts.size() > 0 and thoughts[0]["text"] == s:
		return
	thoughts.push_front({"text": s, "time": time})
	if thoughts.size() > 12:
		thoughts.pop_back()
	if sim:
		print("%6.1f  %s" % [time, s])


func banner(s: String, col: Color, size: int, dur: float) -> void:
	banners.append({"text": s, "color": col, "size": size, "dur": dur, "t": 0.0})
	if banners.size() > 4:
		banners.pop_front()


func show_hint(s: String, dur: float) -> void:
	hint = s
	hint_t = dur


# ---------- безглавая проверка баланса ----------

func _sim_step() -> void:
	if hero == null:
		return
	if selftest:
		_selftest_step()
	if sim_bot and over == "" and meteor_cd <= 0.0 and time > 5.0:
		paw["pos"] = hero.pos + hero.vel * 0.8 + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		cast_meteor()
	if time >= _sim_report:
		_sim_report += 30.0
		print("[%3d c] HP %3d/%3d  ур.%2d  орда %d  врагов %3d  режим %s  стресс %.2f  умения %s  моды %s  фрукты %s  ивенты %d  кормушки %d  книги %d/%d" % [
			int(time), int(hero.hp), int(hero.max_hp()), hero.level, horde_level, enemies.size(),
			Hero.MODE_NAMES[hero.mode], hero.stress, str(hero.skills), str(hero.mods.values()), str(hero.fruits),
			hero.events_done, hero.chests_opened, meteor_hits, meteors_cast])
	if over != "":
		print("ИТОГ: %s на %d c. Уровень %d, умения %s, общие %s, моды %s. Босс %s. Ивенты: пройдено %d, сорвано %d. Книги %d/%d. Убито %d. Кормушек %d." % [
			over, int(time), hero.level, str(hero.skills), str(hero.general), str(hero.mods.values()),
			"сломан" if boss_defeated else ("жив" if boss != null else "не появился"), hero.events_done, events_denied,
			meteor_hits, meteors_cast, kills, hero.chests_opened])
		print("УРОН ПО ГЕРОЮ: ", dmg_by_src)
		get_tree().quit()


## Самопроверка взаимодействий игрока без мыши: `-- --sim --nobot --selftest`.
func _selftest_step() -> void:
	var steps := [
		[3.0, "queue"], [8.0, "throw"], [12.0, "trap"], [20.0, "rotten"], [28.0, "egg"],
		[36.0, "missile"], [45.0, "throw"], [62.0, "wave"], [70.0, "meteor"],
	]
	for st in steps:
		var key := "%s@%d" % [st[1], int(st[0])]
		if time < float(st[0]) or _st_done.has(key):
			continue
		_st_done[key] = true
		match st[1]:
			"queue":
				var before: String = queue[1]["type"]
				move_queue(1, 2)
				print("ТЕСТ очередь: %s -> %s" % [before, queue[2]["type"]])
			"throw":
				var s := spawn_enemy(Enemy.T.SOCK, resolve_circle(hero.pos + Vector2(160, 0), 11.0))
				_build_grid()
				_try_grab(s.pos)
				paw_vel = (hero.pos - s.pos).normalized() * 1200.0
				var held := held_e != null
				_release_grab()
				print("ТЕСТ бросок: схватил=%s, летит=%d" % [held, thrown.size()])
			"trap", "rotten", "egg":
				var g := _drop_gem(resolve_circle(hero.pos + hero.heading * 30.0, 6.0), true)
				millet_cd = 0.0
				menu = {"gem": g, "t": 1.0}
				_menu_click(menu_button_pos(MENU_OPTS.find(st[1])))
				print("ТЕСТ подмена %s: mod=%s, откат=%.0f" % [st[1], g.get("mod", "-"), millet_cd])
			"missile":
				var g := _drop_gem(resolve_circle(hero.pos + Vector2(-200, 0), 6.0), true)
				millet_cd = 0.0
				menu = {"gem": g, "t": 1.0}
				_menu_click(menu_button_pos(3))
				_launch_missile(hero.pos)
				print("ТЕСТ снаряд: летит=%d" % missiles.size())
			"wave":
				var n := enemies.size()
				cast_wave()
				print("ТЕСТ корзина: +%d врагов" % (enemies.size() - n))
			"meteor":
				paw["pos"] = hero.pos
				meteor_cd = 0.0
				cast_meteor()
				print("ТЕСТ книга: %d" % meteors.size())
	if over != "" or time > 90.0:
		print("ТЕСТ итог: бросков в цель %d, подмен сработало %d, урон игрока %d, урон по герою %s" % [throws_hit, tricks, int(player_damage), str(dmg_by_src)])
		get_tree().quit()
