extends Node2D
## Первый забег: комната, орда, кнопки игрока (книга, корзина белья), кошачья лапка,
## левелапы героя с видимым выбором перка. Запуск с `-- --sim` гоняет забег без графики с ботом.

const M := 40.0
const RUN_LENGTH := 1800.0
const HORDE_STEP := 120.0
const METEOR_CD := 20.0
const METEOR_DELAY := 1.2
const METEOR_R := 2.5 * M
const WAVE_UNLOCK := 180.0
const WAVE_CD := 45.0
const RAM_UNLOCK := 90.0
const RAM_SPEED := 1500.0
const PAW_PUSH_R := 1.5 * M
const PAW_HIT_R := 26.0
const PAW_PUSH_MAX := 12
const PAW_BRUISE := 4.0
const PAW_BRUISED_SPEED := 380.0
const MAX_ENEMIES := 320
const MAX_GEMS := 450
const CELL := 40.0

const ENAMES := ["sock", "ball", "slipper", "sprayer", "hand"]
const EDEFS := [
	{"name": "Носок", "hp": 10.0, "speed": 1.7, "dmg": 5.0, "r": 11.0, "push": 1.0, "xp": 1},
	{"name": "Шарик", "hp": 6.0, "speed": 3.8, "dmg": 3.0, "r": 9.0, "push": 1.0, "xp": 1},
	{"name": "Тапок", "hp": 45.0, "speed": 0.9, "dmg": 11.0, "r": 18.0, "push": 0.5, "xp": 3},
	{"name": "Пульверизатор", "hp": 14.0, "speed": 1.3, "dmg": 7.0, "r": 12.0, "push": 1.0, "xp": 2},
	{"name": "Рука", "hp": 150.0, "speed": 1.9, "dmg": 12.0, "r": 17.0, "push": 0.0, "xp": 0},
]

var floor_rect := Rect2(40, 40, 1520, 820)
var obstacles: Array[Rect2] = [
	Rect2(150, 40, 300, 120),   # диван
	Rect2(1470, 140, 90, 300),  # книжная полка
	Rect2(980, 400, 190, 120),  # журнальный столик
	Rect2(170, 650, 140, 130),  # кресло
	Rect2(760, 40, 70, 70),     # цветок в горшке
	Rect2(1240, 730, 170, 130), # лежанка
]

var time := 0.0
var hero: Hero
var enemies: Array[Enemy] = []
var gems: Array = []
var apples: Array = []
var chests: Array = []
var meteors: Array = []
var shots: Array = []
var enemy_shots: Array = []
var fx: Array = []
var texts: Array = []
var thoughts: Array = []
var banners: Array = []
var pending: Array = []
var horde_level := 1
var next_horde := HORDE_STEP
var spawn_acc := 0.0
var next_swarm := 75.0
var next_hand := 50.0
var meteor_cd := 0.0
var wave_cd := 0.0
var paw := {"id": 0, "pos": Vector2(800, 600), "born": 0.0}
var paw_vel := Vector2.ZERO
var paw_bruise := 0.0
var paw_threat := false
var paw_seen_until := -1.0
var paw_trail: Array = []
var levelup := {}
var power_flash := 0.0
var game_speed := 1.0
var paused := false
var over := ""
var kills := 0
var player_damage := 0.0
var chests_denied := 0
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
var ram_hint := false
var wave_hint := false
var world: WorldView
var hud: Hud
var _next_id := 1
var _grid := {}
var _sim_report := 60.0
var _sim_dodged := 0
var shot_at := -1.0


func _ready() -> void:
	randomize()
	var args := OS.get_cmdline_user_args()
	sim = args.has("--sim")
	sim_bot = not args.has("--nobot")
	for a in args:
		if a.begins_with("--shot="):
			shot_at = float(a.substr(7))
	world = WorldView.new()
	world.game = self
	add_child(world)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	hud.game = self
	layer.add_child(hud)
	if not sim:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	start_run()


func new_id() -> int:
	_next_id += 1
	return _next_id


func start_run() -> void:
	time = 0.0
	enemies.clear()
	gems.clear()
	apples.clear()
	chests.clear()
	meteors.clear()
	shots.clear()
	enemy_shots.clear()
	fx.clear()
	texts.clear()
	thoughts.clear()
	banners.clear()
	pending.clear()
	combo_log.clear()
	_grid.clear()
	horde_level = 1
	next_horde = HORDE_STEP
	spawn_acc = 0.0
	next_swarm = 75.0
	next_hand = 50.0
	meteor_cd = 3.0
	wave_cd = 0.0
	paw_bruise = 0.0
	paw_trail.clear()
	levelup = {}
	power_flash = 0.0
	paused = false
	over = ""
	kills = 0
	player_damage = 0.0
	chests_denied = 0
	meteors_cast = 0
	meteor_hits = 0
	rams = 0
	combos = 0
	combo_cd = 0.0
	ram_hint = false
	wave_hint = false
	paw["id"] = new_id()
	hero = Hero.new(self)
	hero.pos = Vector2(820, 470)
	Engine.time_scale = game_speed
	add_thought("Цели: выжить 30 минут, открыть 3 кормушки.")
	show_hint("Водите мышью: лапка толкает носки.  ЛКМ или 1 — уронить книгу с полки.", 8.0)


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
	combo_cd = maxf(0.0, combo_cd - delta)
	_director(delta)
	_update_paw_threat()
	_paw_push(delta)
	hero.update(delta)
	_update_enemies(delta)
	_update_shots(delta)
	_update_meteors(delta)
	_update_pickups(delta)
	_update_fx(delta)
	enemies = enemies.filter(func(e): return not e.dead)
	if hero.xp >= hero.xp_next and levelup.is_empty() and over == "":
		begin_levelup()
	if time >= RAM_UNLOCK and not ram_hint:
		ram_hint = true
		show_hint("Таран! Резко махните лапкой в попугая — он оглохнет на полсекунды.", 7.0)
	if time >= WAVE_UNLOCK and not wave_hint:
		wave_hint = true
		banner("Новая кнопка: корзина белья", Color("6a4fb3"), 30, 2.5)
		show_hint("ПКМ или 2 — опрокинуть корзину белья у стены, к которой ближе лапка.", 7.0)
	if time >= RUN_LENGTH and over == "":
		over = "survived"
		add_thought("Тридцать минут! Я выжил.")


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_LEFT:
			cast_meteor()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			cast_wave()
		return
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_1, KEY_Q:
			cast_meteor()
		KEY_2, KEY_W:
			cast_wave()
		KEY_SPACE, KEY_P, KEY_ESCAPE:
			if over == "":
				paused = not paused
		KEY_R, KEY_ENTER:
			start_run()
		KEY_F2:
			game_speed = 3.0 if game_speed == 1.0 else 1.0
			Engine.time_scale = game_speed
		KEY_F3:
			debug = not debug


# ---------- лапка ----------

func _update_paw(dt: float) -> void:
	var m := get_global_mouse_position().clamp(Vector2.ZERO, Vector2(1600, 900))
	var old: Vector2 = paw["pos"]
	var p := m
	if paw_bruise > 0.0:
		paw_bruise = maxf(0.0, paw_bruise - dt)
		# ушибленная лапка отстаёт от мыши
		p = old.move_toward(m, PAW_BRUISED_SPEED * dt)
	paw["pos"] = p
	if dt <= 0.0:
		return
	var v := (p - old) / dt
	paw_vel = paw_vel.lerp(v, clampf(dt * 30.0, 0.0, 1.0))
	if v.length() > 600.0 and paw_bruise <= 0.0:
		paw_trail.append({"a": old, "b": p, "t": 0.3})
	for tr in paw_trail:
		tr["t"] = float(tr["t"]) - dt
	paw_trail = paw_trail.filter(func(tr): return float(tr["t"]) > 0.0)
	if not paused and over == "" and hero != null:
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
		return
	hero.rammed(dir)
	paw_bruise = PAW_BRUISE
	rams += 1
	shake = 5.0
	_register_hit("paw")
	add_text(hero.pos + Vector2(0, -44), "Таран!", Color("6a4fb3"), 26)


func _update_paw_threat() -> void:
	var was := paw_threat
	paw_threat = false
	if time >= RAM_UNLOCK and paw_bruise <= 0.0:
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
	if paw_bruise > 0.0:
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


# ---------- кнопки игрока ----------

func cast_meteor() -> void:
	if over != "" or paused or meteor_cd > 0.0:
		return
	meteor_cd = METEOR_CD
	meteors_cast += 1
	var p: Vector2 = paw["pos"]
	p = p.clamp(floor_rect.position, floor_rect.end)
	meteors.append({"id": new_id(), "pos": p, "born": time, "t": 0.0, "delay": METEOR_DELAY, "r": METEOR_R,
		"landed": false, "land_t": 0.0, "focus_t": -1.0, "notice_t": -1.0})


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
		spawn_enemy(Enemy.T.SLIPPER if i < 2 else Enemy.T.SOCK, q, true)
	add_fx({"kind": "basket", "pos": base, "dur": 1.2})
	banner("Корзина белья опрокинулась!", Color("6a4fb3"), 28, 1.8)


# ---------- орда ----------

func _director(delta: float) -> void:
	if time >= next_horde:
		horde_level += 1
		next_horde += HORDE_STEP
		banner("Гонг!  Орда: уровень %d" % horde_level, Color("3f6fb5"), 34, 2.4)
		for e in enemies:
			e.blue = 0.8
	var rate := (1.0 + time / 60.0 * 0.12) * (1.0 + 0.12 * float(horde_level - 1))
	spawn_acc += rate * delta
	while spawn_acc >= 1.0:
		spawn_acc -= 1.0
		if enemies.size() >= MAX_ENEMIES:
			continue
		var t: int = Enemy.T.SOCK
		var r := randf()
		if time > 240.0 and r < 0.10:
			t = Enemy.T.SPRAYER
		elif time > 120.0 and r < 0.24:
			t = Enemy.T.SLIPPER
		spawn_enemy(t, edge_point(9.0 * M))
	if time >= next_swarm:
		next_swarm = time + randf_range(30.0, 45.0)
		var p := edge_point(10.0 * M)
		# звон слышен до появления: и герой, и игрок знают, откуда идёт рой
		add_fx({"kind": "jingle", "pos": p, "dur": 1.4})
		pending.append({"at": time + 1.2, "type": Enemy.T.BALL, "n": 6 + horde_level, "pos": p})
	if time >= next_hand:
		next_hand = time + randf_range(90.0, 110.0)
		var e := spawn_enemy(Enemy.T.HAND, edge_point(10.0 * M))
		e.carries_chest = true
		banner("Рука несёт кормушку", Color("b07a1e"), 26, 2.0)
	for pd in pending:
		if time >= float(pd["at"]):
			for i in int(pd["n"]):
				var q: Vector2 = pd["pos"] + Vector2(randf_range(-40, 40), randf_range(-40, 40))
				spawn_enemy(int(pd["type"]), resolve_circle(q, 10.0))
			pd["at"] = INF
	pending = pending.filter(func(pd): return float(pd["at"]) < INF)


func spawn_enemy(type: int, p: Vector2, from_player: bool = false) -> Enemy:
	var d: Dictionary = EDEFS[type]
	var e := Enemy.new()
	e.id = new_id()
	e.type = type
	e.pos = p
	e.born = time
	var l := float(horde_level - 1)
	e.max_hp = float(d["hp"]) * (1.0 + 0.13 * l)
	e.hp = e.max_hp
	e.speed = float(d["speed"]) * M * (1.0 + 0.03 * l)
	e.dmg = float(d["dmg"]) * (1.0 + 0.08 * l)
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
	for i in 14:
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


func random_floor_point() -> Vector2:
	for i in 20:
		var p := Vector2(randf_range(floor_rect.position.x + 80, floor_rect.end.x - 80), randf_range(floor_rect.position.y + 80, floor_rect.end.y - 80))
		if not is_blocked(p):
			return p
	return floor_rect.get_center()


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


## Враги в радиусе, ближайшие первыми.
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
				if e.dead:
					continue
				var d2: float = p.distance_squared_to(e.pos)
				if d2 < r2:
					out.append([d2, e])
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
		e.tumble = maxf(0.0, e.tumble - delta)
		var to_h := hp_pos - e.pos
		var d := to_h.length()
		var dir := to_h / maxf(d, 0.001)
		var spd := e.speed
		match e.type:
			Enemy.T.SOCK:
				e.phase = fmod(e.phase + delta * 1.1, 1.0)
				spd = e.speed * 2.8 if e.is_airborne() else 0.0
			Enemy.T.BALL:
				dir = dir.rotated(sin(time * 3.0 + float(e.id)) * 0.35)
			Enemy.T.SLIPPER:
				e.phase = fmod(e.phase + delta * 1.4, 1.0)
			Enemy.T.SPRAYER:
				e.shoot_cd -= delta
				if d < 4.5 * M:
					dir = -dir
				elif d < 7.0 * M:
					spd = 0.0
				if d < 8.0 * M and e.shoot_cd <= 0.0 and e.stun <= 0.0:
					e.shoot_cd = 3.2
					enemy_shots.append({"id": new_id(), "pos": e.pos, "vel": to_h / maxf(d, 0.001) * 3.0 * M, "dmg": e.dmg,
						"life": 4.0, "born": time, "r": 13.0, "from_player": e.from_player})
			Enemy.T.HAND:
				e.grab_cd -= delta
				e.phase = fmod(e.phase + delta * 3.0, 1.0)
				if e.grab_state == 1:
					spd = 0.0
					e.grab_t -= delta
					if e.grab_t <= 0.0:
						e.grab_state = 0
						e.grab_cd = 2.5
						if d < 1.9 * M and hero.held <= 0.0 and e.stun <= 0.0:
							hero.grabbed(e)
				elif d < 1.5 * M and e.grab_cd <= 0.0 and e.stun <= 0.0:
					# перед хватом приседает и растопыривает пальцы: 0,5 с предупреждения
					e.grab_state = 1
					e.grab_t = 0.5
		if e.stun > 0.0 or e.tumble > 0.0:
			spd = 0.0
		if spd > 0.0:
			e.move_dir = dir
		e.pos += (dir * spd + e.push_vel) * delta
		e.push_vel *= exp(-3.0 * delta)
		_separate(e)
		e.pos = resolve_circle(e.pos, e.radius)
		var md := e.radius + hero.radius
		if d < md:
			if e.type != Enemy.T.HAND and e.atk_cd <= 0.0 and not e.is_airborne() and e.tumble <= 0.0 and e.stun <= 0.0:
				e.atk_cd = 0.9
				hero.take_damage(e.dmg, ENAMES[e.type], src_label(e), e.from_player)
			if d > 0.5:
				e.pos = hp_pos - dir * md


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
	e.pos += push.limit_length(8.0)


func src_label(e: Enemy) -> String:
	var n: String = EDEFS[e.type]["name"]
	return n + " из вашей волны" if e.from_player else n


func damage_enemy(e: Enemy, amount: float, kb: Vector2) -> void:
	if e.dead:
		return
	e.hp -= amount
	e.flash = 0.1
	if e.push_factor > 0.0:
		e.push_vel += kb * e.push_factor
	if e.hp <= 0.0:
		_kill(e)


func _kill(e: Enemy) -> void:
	e.dead = true
	kills += 1
	match e.type:
		Enemy.T.SOCK:
			_drop_gem(e.pos, false)
		Enemy.T.BALL:
			if randf() < 0.6:
				_drop_gem(e.pos, false)
		Enemy.T.SLIPPER:
			_drop_gem(e.pos, true)
		Enemy.T.SPRAYER:
			_drop_gem(e.pos + Vector2(-5, 0), false)
			_drop_gem(e.pos + Vector2(5, 0), false)
		Enemy.T.HAND:
			if e.carries_chest:
				chests.append({"id": new_id(), "pos": e.pos, "born": time, "life": 40.0, "taken": false})
				add_thought("Рука уронила кормушку!")
			_drop_gem(e.pos + Vector2(-14, 8), true)
			_drop_gem(e.pos + Vector2(14, 8), true)
	if randf() < 0.012 and apples.size() < 3:
		apples.append({"id": new_id(), "pos": e.pos, "born": time, "life": 35.0, "taken": false})


func _drop_gem(p: Vector2, big: bool) -> void:
	gems.append({"id": new_id(), "pos": p, "big": big, "xp": 5 if big else 1, "born": time, "taken": false})


# ---------- снаряды, книги, подбор ----------

func _update_shots(delta: float) -> void:
	for s in shots:
		s["pos"] += s["vel"] * delta
		s["life"] = float(s["life"]) - delta
		var sp: Vector2 = s["pos"]
		if is_blocked(sp):
			s["life"] = 0.0
			continue
		for e in enemies_near(sp, 30.0, 4):
			var hit: Array = s["hit"]
			if hit.has(e.id) or sp.distance_to(e.pos) > e.radius + 6.0:
				continue
			hit.append(e.id)
			damage_enemy(e, float(s["dmg"]), Vector2(s["vel"]).normalized() * 80.0)
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
	var p: Vector2 = m["pos"]
	add_fx({"kind": "dust", "pos": p, "r": METEOR_R, "dur": 0.5})
	if hero.pos.distance_to(p) <= METEOR_R + hero.radius * 0.5:
		meteor_hits += 1
		hero.wariness["meteor"] = float(hero.wariness["meteor"]) + 0.25
		hero.say("Ай! Не заметил книгу." if float(m["notice_t"]) < 0.0 else "Не успел увернуться от книги!")
		hero.take_damage(hero.max_hp() * 0.15, "meteor", "Книга с полки", true)
	elif float(m["notice_t"]) >= 0.0 and hero.pos.distance_to(p) < METEOR_R + 2.0 * M:
		_sim_dodged += 1
	for e in enemies_near(p, METEOR_R, 999):
		e.stun = 1.0
		e.push_vel += (e.pos - p).normalized() * 200.0 * e.push_factor


func _update_pickups(delta: float) -> void:
	gems = gems.filter(func(g): return not g["taken"])
	while gems.size() > MAX_GEMS:
		gems.pop_front()
	for a in apples:
		a["life"] = float(a["life"]) - delta
		if float(a["life"]) <= 0.0:
			a["taken"] = true
	apples = apples.filter(func(a): return not a["taken"])
	for c in chests:
		c["life"] = float(c["life"]) - delta
		if float(c["life"]) <= 0.0 and not c["taken"]:
			c["taken"] = true
			chests_denied += 1
			add_fx({"kind": "stamp", "pos": c["pos"], "dur": 2.0})
			add_thought("Кормушка пропала... Обидно.")
	chests = chests.filter(func(c): return not c["taken"])


func open_chest(c: Dictionary) -> void:
	c["taken"] = true
	hero.chests_opened += 1
	var keys: Array = []
	for k in hero.weapons:
		if int(hero.weapons[k]) < Perks.MAX_W:
			keys.append(k)
	for k in hero.passives:
		if int(hero.passives[k]) < Perks.MAX_P:
			keys.append(k)
	var rare := randf() < 0.15
	var n := 2 if rare else 1
	var got: Array = []
	for i in n:
		if keys.is_empty():
			break
		var k: String = keys[randi() % keys.size()]
		var lvl := hero.lvl_of(k) + 1
		hero.apply_card({"key": k, "lvl": lvl})
		got.append("%s ур. %d" % [Perks.NAMES[k], lvl])
		if (Perks.is_weapon(k) and lvl >= Perks.MAX_W) or (not Perks.is_weapon(k) and lvl >= Perks.MAX_P):
			keys.erase(k)
	if got.is_empty():
		hero.hp = hero.max_hp()
		got.append("полное здоровье")
	hero.say("Кормушка: %s. Кормушек %d/3." % [", ".join(got), mini(hero.chests_opened, 3)])
	if rare:
		power_flash = 0.6
		banner("Он нашёл силу", Color("b23a2e"), 34, 2.0)


# ---------- левелап героя: замедление и видимый выбор ----------

func on_hero_level() -> void:
	pass


func _make_cards() -> Array:
	var pool: Array = []
	var h := hero
	for w in Perks.WEAPONS:
		if h.weapons.has(w):
			if int(h.weapons[w]) < Perks.MAX_W:
				pool.append({"key": w, "lvl": int(h.weapons[w]) + 1, "new": false})
		elif h.weapons.size() < Perks.W_SLOTS:
			pool.append({"key": w, "lvl": 1, "new": true})
	for p in Perks.PASSIVES:
		if h.passives.has(p):
			if int(h.passives[p]) < Perks.MAX_P:
				pool.append({"key": p, "lvl": int(h.passives[p]) + 1, "new": false})
		elif h.passives.size() < Perks.P_SLOTS:
			pool.append({"key": p, "lvl": 1, "new": true})
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


func _update_levelup(real_dt: float) -> void:
	if levelup.is_empty():
		if not paused:
			Engine.time_scale = game_speed
		return
	if paused or over != "":
		return
	levelup["t"] = float(levelup["t"]) + real_dt
	var t: float = levelup["t"]
	Engine.time_scale = game_speed * (0.3 if t < 1.5 else 1.0)
	if t >= 1.5 and not levelup["applied"]:
		levelup["applied"] = true
		var c: Dictionary = levelup["cards"][int(levelup["chosen"])]
		var r: Dictionary = levelup["scores"][int(levelup["chosen"])]
		hero.apply_card(c)
		hero.choosing = false
		var nm: String = Perks.NAMES[c["key"]]
		if not c["new"]:
			nm += " ур. %d" % int(c["lvl"])
		hero.say("Беру %s: %s." % [nm, r["reason"]])
	if t >= 2.8:
		levelup = {}


# ---------- урон по герою и награды игроку ----------

func on_hero_damaged(a: float, src: String, label: String, from_player: bool) -> void:
	var mine := from_player or src == "meteor" or src == "paw"
	if mine:
		player_damage += a
		add_text(hero.pos + Vector2(randf_range(-12, 12), -40), "%s: −%d" % [label, int(round(a))], Color("b23a2e"), 22)
	else:
		add_text(hero.pos + Vector2(randf_range(-12, 12), -34), "−%d" % int(round(a)), Color("7a5a4a"), 15)
	_register_hit("wave" if from_player else src)


## «Загон»: три разных источника урона за 5 секунд.
func _register_hit(src: String) -> void:
	combo_log.append([time, src])
	combo_log = combo_log.filter(func(c): return float(c[0]) > time - 5.0)
	var kinds := {}
	var has_mine := false
	for c in combo_log:
		kinds[c[1]] = true
		if c[1] == "meteor" or c[1] == "paw" or c[1] == "wave":
			has_mine = true
	if kinds.size() >= 3 and has_mine and combo_cd <= 0.0:
		combo_cd = 6.0
		combos += 1
		banner("ЗАГОН!", Color("b23a2e"), 44, 1.6)


func hero_died() -> void:
	if over != "":
		return
	over = "hero_dead"
	hero.say("...Попался.")
	banner("ПОПАЛСЯ!", Color("b23a2e"), 56, 99.0)


func last_chance() -> float:
	if time > 1500.0 and hero.chests_opened < 3:
		return clampf((time - 1500.0) / 300.0, 0.0, 1.0)
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
	if thoughts.size() > 9:
		thoughts.pop_back()
	if sim:
		print("%6.1f  %s" % [time, s])


func banner(s: String, col: Color, size: int, dur: float) -> void:
	banners.append({"text": s, "color": col, "size": size, "dur": dur, "t": 0.0})


func show_hint(s: String, dur: float) -> void:
	hint = s
	hint_t = dur


# ---------- безглавая проверка баланса ----------

func _sim_step() -> void:
	if hero == null:
		return
	if sim_bot and over == "" and meteor_cd <= 0.0 and time > 5.0:
		paw["pos"] = hero.pos + hero.vel * 0.8 + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		cast_meteor()
	if time >= _sim_report:
		_sim_report += 60.0
		print("[%4d c] HP %3d/%3d  ур.%2d  орда %d  врагов %3d  режим %s  стресс %.2f  жадность %.2f  кормушки %d  книги %d/%d" % [
			int(time), int(hero.hp), int(hero.max_hp()), hero.level, horde_level, enemies.size(),
			Hero.MODE_NAMES[hero.mode], hero.stress, hero.greed, hero.chests_opened, meteor_hits, meteors_cast])
	if over != "":
		print("ИТОГ: %s на %d c. Уровень %d, оружие %s, пассивки %s. Книги попали %d из %d, уворотов замечено %d. Убито %d. Кормушек открыто %d, сорвано %d." % [
			over, int(time), hero.level, str(hero.weapons), str(hero.passives), meteor_hits, meteors_cast, _sim_dodged, kills, hero.chests_opened, chests_denied])
		get_tree().quit()
