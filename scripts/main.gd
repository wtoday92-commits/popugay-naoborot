extends Node2D
## Пятиминутный забег: комната с мебелью, орда, ивенты из очереди, босс-пылесос на 4:00.
## Игрок: лапка (толчок, таран, хватка и бросок носков), меню над колоском проса,
## кнопки Q (книга) и W (корзина белья). Запуск с `-- --sim` гоняет забег без графики с ботом.

const M := 40.0
const SCREEN := Vector2(1920, 1080)
const FIELD := Rect2(340, 0, 1240, 1080)
const RUN_LENGTH := 300.0
const HORDE_STEP := 60.0
const ENRAGE_AT := 360.0
const HORDE_HP_GONG := 0.08
const HORDE_HP_LEVEL := 0.03
const HORDE_DMG_LEVEL := 0.015
const BOSS_AT := 240.0
const EVENT_SLOTS := [40.0, 95.0, 150.0, 200.0]
const EVENT_WARN := 10.0
const GLOW_NEED := 5
const METEOR_CD := 12.0
const BASKET_DELAY := 2.0
const BASKET_R := 1.4 * M
const BASKET_TRAP := 2.0
const BASKET_FOLLOW := 75.0
const METEOR_DELAY := 1.2
const METEOR_R := 2.5 * M
const WAVE_UNLOCK := 180.0
const BOOK_UNLOCK := 120.0
const HOLD_TIME := 2.5
const HELD_SPEED := 230.0
const INTRO_TIME := 2.8
const WAVE_CD := 25.0
const RAM_UNLOCK := 20.0
const RAM_SPEED := 1500.0
const MILLET_CD := 30.0
const PAW_PUSH_R := 1.5 * M
const PAW_HIT_R := 26.0
const PAW_PUSH_MAX := 12
const PAW_BRUISE := 1.6
const GRAB_R := 28.0
const THROW_CD := 3.0
const MAX_ENEMIES := 160
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
	{"name": "Носок", "hp": 14.0, "speed": 1.6, "dmg": 5.0, "r": 11.0, "push": 1.0, "xp": 1},
	{"name": "Клубок", "hp": 9.0, "speed": 3.4, "dmg": 4.0, "r": 10.0, "push": 1.0, "xp": 1},
	{"name": "Тапок", "hp": 60.0, "speed": 0.9, "dmg": 12.0, "r": 18.0, "push": 0.5, "xp": 4},
	{"name": "Пульверизатор", "hp": 20.0, "speed": 1.3, "dmg": 5.0, "r": 12.0, "push": 1.0, "xp": 2},
	{"name": "Рука", "hp": 150.0, "speed": 2.0, "dmg": 8.0, "r": 18.0, "push": 0.0, "xp": 0},
	{"name": "Суперносок", "hp": 70.0, "speed": 2.0, "dmg": 9.0, "r": 15.0, "push": 0.6, "xp": 5},
	{"name": "Пылевой зайчик", "hp": 10.0, "speed": 2.6, "dmg": 4.0, "r": 9.0, "push": 1.0, "xp": 1},
	{"name": "Шкатулка", "hp": 80.0, "speed": 2.6, "dmg": 0.0, "r": 16.0, "push": 0.0, "xp": 0},
	{"name": "Пылесос", "hp": 900.0, "speed": 1.1, "dmg": 13.0, "r": 56.0, "push": 0.0, "xp": 0},
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
var next_pack_swarm := 0.0
var next_swarm := 30.0
var next_hand := 30.0
var double_spawn_until := -1.0
var meteor_cd := 0.0
var wave_cd := 0.0
var millet_cd := 0.0
var throw_cd := 0.0
var hold_t := 0.0
var sling_anchor := Vector2.ZERO
var fruit_drops: Array = []
var furniture_bounce := 0.0
var millet_unlocked := false
var phase := "play"
var intro_t := 0.0
var outro := {}
var tut := {}
var save := {}
var first_run := true
var dealt_by_src := {}
var unlock_seen := {}
var learn := false
var meta := {}
var events_total := 2
var run_millet := 0
var fruits_eaten := 0
var enraged := false
var meta_t := 0.0
var unlock_all := false
var mid_bot := false
var prog := false
var _bot_ram := 0.0
var die_at := -1.0
var shot_block := false
var shot_cage := false
var shot_waves := false
var win_at := -1.0
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
var run_log: PackedStringArray = []
var run_log_path := ""
var _log_snap := 10.0
var player_by_tool := {}
var selftest := false
var full_bot := false
var _bot_throw := 0.0
## Статы деревьев штаба для усиленных умений этого забега.
var perks := {}
var twin_ready := true
var twin_refill := false
var combo_flip := false
var run_pstats := {}
var hero_dodges := 0
## Отладка штаба: `--enh=throw,ram` покупает все узлы и усиливает эти деревья, `--waves=socks,calm,...` — составы.
var hq_test: Array = []
var waves_test: Array = []
## Системный курсор-лапка: картинки по состояниям и текущее состояние.
var cursor_imgs := {}
var cursor_state := ""
var _cursor_building := false
var throw_ready_flash := 0.0
var _was_cd := false
## Сложность забега (0 — обычная, 1 — средняя, 2 — сложная) и зоны на полу (пыль, искры пылесоса).
var diff := 0
## Проклятия, действующие в этом забеге.
var curses_on: Array = []
## Скорлупки-мины и вихри попугая.
var mines: Array = []
var tornados: Array = []
var force_bird := ""
var zones: Array = []
var force_diff := -1
var boss_phase2 := false
var _st_done := {}


func _ready() -> void:
	randomize()
	var args := OS.get_cmdline_user_args()
	sim = args.has("--sim")
	sim_bot = not args.has("--nobot")
	selftest = args.has("--selftest")
	learn = args.has("--learn")
	full_bot = args.has("--fullbot")
	unlock_all = args.has("--unlockall") or full_bot
	mid_bot = args.has("--midbot")
	prog = args.has("--prog")
	if prog:
		mid_bot = true
		sim_bot = true
	for a in args:
		if a.begins_with("--shot="):
			shot_at = float(a.substr(7))
		if a == "--shotblock":
			shot_block = true
		if a == "--shotcage":
			shot_cage = true
		if a == "--shotwaves":
			shot_waves = true
		if a.begins_with("--die="):
			die_at = float(a.substr(6))
		if a.begins_with("--win="):
			win_at = float(a.substr(6))
		if a.begins_with("--bird="):
			force_bird = a.substr(7)
		if a.begins_with("--diff="):
			force_diff = int(a.substr(7))
		if a.begins_with("--enh="):
			hq_test = a.substr(6).split(",")
		if a.begins_with("--waves="):
			waves_test = a.substr(8).split(",")
	if sim:
		Save.path = "user://save_sim.json"
	for a in args:
		if a.begins_with("--save="):
			Save.path = "user://" + a.substr(7)
	if shot_at > 0.0:
		Save.path = "user://save_shot.json"
	save = Save.defaults() if (sim and not learn) or shot_at > 0.0 else Save.load_data()
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
		Input.use_accumulated_input = false
		get_tree().root.size_changed.connect(_build_cursors)
		_build_cursors()
	start_run()


func cursor_skin() -> String:
	return String(save.get("cursor", "white"))


func _build_cursors() -> void:
	if _cursor_building:
		return
	_cursor_building = true
	var k := float(DisplayServer.window_get_size().x) / 1920.0
	var px := clampi(int(round(PawCursor.SIZE * clampf(k, 0.5, 1.4))), 32, 128)
	cursor_imgs = await PawCursor.build(self, cursor_skin(), px)
	if shot_at > 0.0:
		cursor_imgs["cd"].save_png("user://cursor_cd.png")
	cursor_state = ""
	_cursor_building = false


## Курсор по состоянию лапки: готова, рогатка в откате, ушиб; с предметом в рогатке лапку рисует игра.
func _update_cursor() -> void:
	if cursor_imgs.is_empty():
		return
	var st := "ready"
	if held_e != null:
		st = "empty"
	elif paw_bruise > 0.0:
		st = "bruised"
	elif throw_cd > 0.0 and phase == "play" and over == "":
		st = "cd"
	if st == cursor_state:
		return
	cursor_state = st
	var img: Image = cursor_imgs[st]
	var hot: Vector2 = PawCursor.HOT * float(img.get_width()) / float(PawCursor.SIZE)
	Input.set_custom_mouse_cursor(img, Input.CURSOR_ARROW, hot)


func new_id() -> int:
	_next_id += 1
	return _next_id


func sfx(name: String, vol: float = 0.0, pitch: float = 1.0) -> void:
	if audio != null:
		audio.play(name, vol, pitch)


func start_run() -> void:
	if hero != null and over == "" and time > 5.0:
		_write_log("прерван")
	run_log = PackedStringArray()
	_log_snap = 10.0
	player_by_tool = {}
	time = 0.0
	for arr in [enemies, gems, chests, meteors, shots, enemy_shots, thrown, missiles, delayed, fx, texts, thoughts, banners, pending, combo_log, paw_trail, fruit_drops]:
		arr.clear()
	_grid.clear()
	horde_level = 1
	next_horde = HORDE_STEP
	spawn_acc = 0.0
	next_swarm = 30.0
	next_pack_swarm = 0.0
	next_hand = 30.0
	double_spawn_until = -1.0
	meteor_cd = 2.0
	wave_cd = 0.0
	millet_cd = 0.0
	throw_cd = 0.0
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
	meta = save.get("meta", Meta.defaults())
	for k in Meta.defaults():
		if not meta.has(k):
			meta[k] = Meta.defaults()[k]
	save["meta"] = meta
	if unlock_all:
		for it in Meta.PLAYER:
			meta["unlocked"][it["key"]] = true
	# старая прокачка рогатки переехала в дерево штаба: перья возвращаются
	if meta.has("sling"):
		var refund := 0
		for k in meta["sling"].get("owned", {}):
			refund += {"power1": 4, "power2": 6, "fire": 5, "knock": 5}.get(k, 0)
		save["feathers"] = int(save.get("feathers", 0)) + refund
		meta.erase("sling")
	if hq_test.size() > 0:
		for it in Meta.PLAYER:
			meta["unlocked"][it["key"]] = true
		var hh := Trees.hq(meta)
		for ab in Trees.ABIL:
			for bi in 3:
				for ni in 7:
					hh["nodes"][Trees.node_id(ab, bi, ni)] = int(Trees.node(ab, bi, ni)[4])
		hh["enh"] = hq_test.duplicate()
	if waves_test.size() > 0:
		var hh := Trees.hq(meta)
		for pkk in Trees.PACKS:
			hh["packs"][pkk["key"]] = true
		for i in mini(waves_test.size(), Trees.SEGMENTS):
			hh["waves"][i] = waves_test[i]
		for ab in Trees.ABIL:
			hh["nodes"][Trees.node_id(ab, 0, 0)] = 3
		# проклятия, которые игрок взял на этот забег, сгорают при старте
	curses_on = []
	if not sim:
		var armed: Array = save.get("armed", [])
		var owned_c: Dictionary = save.get("curses", {})
		for c in armed:
			if int(owned_c.get(c, 0)) > 0:
				owned_c[c] = int(owned_c[c]) - 1
				curses_on.append(c)
		save["armed"] = []
	perks = Trees.perks(meta)
	twin_ready = true
	twin_refill = false
	combo_flip = false
	run_pstats = {}
	hero_dodges = 0
	if force_diff >= 0:
		Diff.data(meta)["unlocked"] = maxi(Diff.unlocked(meta), force_diff)
		Diff.data(meta)["next"] = force_diff
	diff = Diff.next_diff(meta)
	zones.clear()
	mines.clear()
	tornados.clear()
	boss_phase2 = false
	_generate_room()
	queue.clear()
	# ивенты появляются со средней сложности
	events_total = 0
	if diff >= 1:
		events_total = 2 + (1 if Meta.unlocked(meta, "event3") else 0) + (1 if Meta.unlocked(meta, "event4") else 0)
		var slots: Array = [[70.0, 160.0], [50.0, 120.0, 190.0], [40.0, 95.0, 150.0, 200.0]][events_total - 2]
		var types: Array = Skills.EVENTS.duplicate()
		types.shuffle()
		for i in slots.size():
			queue.append({"type": types[i], "at": slots[i]})
	run_millet = 0
	fruits_eaten = 0
	enraged = false
	meta_t = 0.0
	paw["id"] = new_id()
	hero = Hero.new(self)
	var bird := Parrots.next_bird(meta)
	if force_bird != "":
		bird = force_bird
		if not Parrots.owned(meta).has(bird):
			Parrots.owned(meta).append(bird)
	var skill_pool: Array = Meta.parrot_skills(meta)
	if OS.get_cmdline_user_args().has("--allskills"):
		skill_pool = []
		for k in Skills.SKILLS:
			if not Skills.BIRD_SKILLS.has(k):
				skill_pool.append(k)
	hero.apply_meta(meta["parrot"]["up"], meta.get("quests", []), skill_pool, bird, Parrots.perks(meta, bird))
	hero.curses = curses_on.duplicate()
	if curses_on.has("blind"):
		hero.slots = maxi(1, hero.slots - 1)
	if curses_on.has("fragile"):
		hero.hp = hero.max_hp()
	for c in curses_on:
		add_thought("Проклятие: %s." % String(Rewards.CURSES[c]["desc"]))
	for a2 in OS.get_cmdline_user_args():
		if a2.begins_with("--forceskill="):
			for k2 in a2.substr(13).split(","):
				hero.skills[k2] = 3
	hero.pos = floor_rect.get_center()
	if hud != null:
		hud.reset()
	throw_cd = 0.0
	hold_t = 0.0
	millet_unlocked = false
	outro = {}
	tut = {}
	dealt_by_src = {}
	unlock_seen = {}
	first_run = int(save.get("runs", 0)) == 0 and not sim
	hero.learn(save.get("memory", {}) if (not sim or learn) else {})
	if sim:
		phase = "play"
	else:
		# влёт: попугай залетает из-за края экрана, таймер ещё стоит
		phase = "intro"
		intro_t = 0.0
		hero.pos = Vector2(FIELD.position.x - 80, 120)
	Engine.time_scale = game_speed
	add_thought("Цель: сломать пылесос, иначе отсюда не выбраться.")
	var reason := String(Diff.data(meta).get("reason", ""))
	if reason != "":
		add_thought(reason)
	for q in hero.quests:
		add_thought("Квест: %s." % String(Meta.quest_by_key(q).get("name", q)).to_lower())
	for note in hero.memory_notes:
		add_thought(note)


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
	throw_ready_flash = maxf(0.0, throw_ready_flash - real_dt)
	var in_cd := throw_cd > 0.0
	if _was_cd and not in_cd and over == "" and held_e == null:
		# рогатка снова готова: вспышка у лапки и щелчок
		throw_ready_flash = 0.45
		sfx("tick", -6.0, 1.6)
	_was_cd = in_cd
	if not sim:
		_update_cursor()
	shake = maxf(0.0, shake - real_dt * 30.0)
	world.position = Vector2(randf_range(-shake, shake), randf_range(-shake, shake)) if shake > 0.1 else Vector2.ZERO
	if audio != null and hero != null:
		audio.set_tension(1.0 - hero.hp_frac() * 2.0 if over == "" else 0.0)
	if not sim:
		world.queue_redraw()
		hud.queue_redraw()
	if shot_cage and shot_at > 0.0 and time > shot_at - 2.4 and wave_cd <= 0.0 and ability_unlocked("basket"):
		paw["pos"] = hero.pos
		cast_wave()
	if shot_waves and hud != null:
		hud.hq_tab = "waves"
	if not shot_cage and shot_at > 0.0 and time > shot_at - 0.8 and meteor_cd <= 0.0 and ability_unlocked("book"):
		paw["pos"] = hero.pos + Vector2(60, 20)
		cast_meteor()
	if die_at > 0.0 and time >= die_at and over == "":
		hero.hp = 0.0
		hero_died()
	if win_at > 0.0 and time >= win_at and over == "":
		time = RUN_LENGTH
		over = "survived"
		_begin_outro()
	var shot_clock := time + (float(outro.get("t", 0.0)) if not outro.is_empty() else 0.0)
	if shot_at > 0.0 and not outro.is_empty() and float(outro["t"]) > 2.6 and shot_at - time > 4.0:
		if outro.has("roll"):
			if float(outro["roll"]["t"]) > ROLL_END + 0.8:
				_outro_click(Vector2.ZERO)
		else:
			for it in outro["items"]:
				if not it["got"]:
					_outro_click(it["pos"])
	if shot_at > 0.0 and shot_clock >= shot_at:
		# отладочный снимок экрана: `-- --shot=<сек>`
		shot_at = -1.0
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://shot.png")
		print("SHOT ", ProjectSettings.globalize_path("user://shot.png"))
		get_tree().quit()
		return
	_apply_time_scale()
	if phase == "intro":
		if not paused:
			_update_intro(real_dt)
		return
	if over != "":
		_update_outro(real_dt)
		return
	if paused:
		return
	if not tut.is_empty():
		_update_tut(real_dt)
	_step(delta)


func _step(delta: float) -> void:
	time += delta
	meteor_cd = maxf(0.0, meteor_cd - delta)
	wave_cd = maxf(0.0, wave_cd - delta)
	millet_cd = maxf(0.0, millet_cd - delta)
	throw_cd = maxf(0.0, throw_cd - delta)
	combo_cd = maxf(0.0, combo_cd - delta)
	if throw_cd <= 0.0 and twin_refill:
		twin_ready = true
		twin_refill = false
	_check_unlocks()
	_director(delta)
	_update_events(delta)
	_update_paw_threat()
	hero.update(delta)
	_update_enemies(delta)
	_update_shots(delta)
	_update_thrown(delta)
	_update_missiles(delta)
	_update_meteors(delta)
	_update_zones(delta)
	_update_mines(delta)
	_update_delayed()
	_update_pickups(delta)
	_update_fx(delta)
	furniture_bounce = maxf(0.0, furniture_bounce - delta)
	enemies = enemies.filter(func(e): return not e.dead)
	if not menu.is_empty() and bool(menu["gem"]["taken"]):
		menu = {}
	if hero.xp >= hero.xp_next and levelup.is_empty() and over == "":
		begin_levelup()
	_timed_hints()
	if time >= _log_snap:
		_log_snap += 10.0
		log_event("СНИМОК", "здоровье %d/%d · ур. %d · врагов %d · стресс %.2f · режим %s · умения %s · пассивки %s · моды %s" % [int(hero.hp), int(hero.max_hp()), hero.level, enemies.size(), hero.stress, Hero.MODE_NAMES[hero.mode], str(hero.skills), str(hero.general), str(hero.mods.values())])
	if not enraged and boss != null and not boss.dead and time >= ENRAGE_AT:
		# пылесос в ярости: дольше тянуть нельзя
		enraged = true
		boss.speed *= 1.6
		boss.dmg *= 1.5
		banner("Пылесос в ярости!", Color("b23a2e"), 38, 2.5)
		sfx("boss", 0.0, 1.3)


func _timed_hints() -> void:
	var list := [
		[0.5, "throw", "Рогатка: зажмите ЛКМ на носке, оттяните лапку назад и отпустите."],
		[RAM_UNLOCK + 1.0, "ram", "Таран: резко махните лапкой в попугая — он оглохнет на полсекунды."],
		[float(queue[0]["at"]) - 25.0 if queue.size() > 0 else 40.0, "queue", "Ивенты слева можно поменять местами, пока они не начались."],
	]
	if ability_unlocked("book"):
		list.append([BOOK_UNLOCK + 1.0, "book", "Q — уронить книгу с полки туда, где лапка."])
	if ability_unlocked("basket"):
		list.append([WAVE_UNLOCK + 1.0, "basket", "W — клетка: тень 2 с ползёт за лапкой, потом клетка накрывает попугая."])
	for h in list:
		if time >= float(h[0]) and not hints_shown.has(h[1]):
			hints_shown[h[1]] = true
			show_hint(h[2], 7.0)

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
		if mb.pressed and not outro.is_empty() and bool(outro["done"]):
			_meta_action(hud.meta_click(p, true))
			return
		if phase != "play":
			return
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
	if mb.pressed and _try_block(p):
		return
	if mb.pressed and not outro.is_empty():
		if bool(outro["done"]):
			_meta_action(hud.meta_click(p, false))
			return
		_outro_click(p)
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
		if millet_cd <= 0.0 and millet_unlocked and ability_unlocked("millet") and levelup.is_empty():
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
		# ушибленная лапка двигается как обычно, только не таранит
		paw_bruise = maxf(0.0, paw_bruise - dt)
	if held_e != null:
		# рогатка: лапка привязана к резинке и не уходит дальше натяга (и мышь тоже)
		var lim := sling_max()
		if m.distance_to(sling_anchor) > lim:
			p = sling_anchor + (m - sling_anchor).limit_length(lim)
			if not sim:
				get_viewport().warp_mouse(p)
		if not paused and over == "":
			hold_t -= dt
			if hold_t <= 0.0:
				_drop_held()
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
		var pull: Vector2 = (p - sling_anchor).limit_length(sling_max())
		held_e.pos = sling_anchor + pull * 0.15 + Vector2(sin(Time.get_ticks_msec() * 0.03) * 1.5, 0)
	if not paused and over == "" and hero != null and held_e == null:
		_check_ram(old, p, v)


static func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	return Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p)


func _check_ram(a: Vector2, b: Vector2, v: Vector2) -> void:
	if time < RAM_UNLOCK or paw_bruise > 0.0 or hero.ram_immune > 0.0 or not levelup.is_empty():
		return
	var spd := maxf(paw_vel.length(), v.length() * 0.7)
	if spd < RAM_SPEED * (1.0 - pk("ram_easy")):
		return
	if seg_dist(hero.pos, a, b) > PAW_HIT_R + pk("paw_wide") + hero.radius:
		return
	var dir := (b - a).normalized()
	if dir == Vector2.ZERO:
		dir = paw_vel.normalized()
	# увернуться можно, только если лапка в одном из слотов внимания
	if not has_pk("ghost") and hero.focus_ids.has(int(paw["id"])) and randf() < 0.5 + hero.dodge_bonus() - pk("ram_sneak"):
		hero.dodge_paw(dir)
		hero_dodges += 1
		sfx("whoosh", -10.0, 1.6)
		return
	apply_ram(dir)


## Попадание тараном: общее для мыши и бота, со всеми ветками дерева «Таран».
func apply_ram(dir: Vector2) -> void:
	var caught: bool = hero.trapped > 0.0 or hero.stun > 0.0
	if hero.trapped > 0.0:
		pstat_add("ram_trapped")
	hero.rammed(dir)
	hero.knock_vel *= 1.0 + pk("ram_knock")
	hero.stun += pk("ram_stun")
	var dmg := pk("ram_dmg")
	if has_pk("wallslam"):
		var wall := false
		for k in 5:
			var q := hero.pos + dir * (0.6 + 0.5 * k) * M
			if is_blocked(q) or not floor_rect.grow(-hero.radius).has_point(q):
				wall = true
				break
		if wall:
			dmg += 10.0 + pk("wall_dmg")
			hero.stun = maxf(hero.stun, 0.8)
			shake = 9.0
			add_text(hero.pos + Vector2(0, -74), "Об стену!", Color("b23a2e"), 24)
	if has_pk("ghost") and caught:
		dmg *= 2.0
	if dmg > 0.0:
		hero.take_damage(dmg, "paw", "Таран", true)
	if has_pk("dizzy"):
		hero.slow(2.0 + pk("dizzy_len"), 0.4)
	if has_pk("ram_forget"):
		hero.focus.clear()
		hero.focus_ids.clear()
		hero.stress = minf(1.0, hero.stress + pk("ram_forget"))
	if has_pk("rush"):
		for e in enemies_near(hero.pos, (2.0 + pk("rush")) * M, 30):
			if not e.is_big():
				e.rush = 1.5 + pk("rush_len")
				e.rush_k = 1.6 + pk("rush_speed")
	if has_pk("ram_mark"):
		hero.horde_mark_t = 3.0 + pk("mark_len")
		hero.horde_mark_k = 0.3 + pk("mark_horde")
	if has_pk("swarm"):
		for i in 6:
			var q := hero.pos + Vector2.RIGHT.rotated(TAU * i / 6.0) * 1.8 * M
			if not is_blocked(q):
				spawn_enemy(Enemy.T.SOCK, resolve_circle(q, 10.0), true)
		add_fx({"kind": "poof", "pos": hero.pos, "dur": 0.5, "col": Color("f1eee8"), "r": 40.0})
	log_event("ИГРОК", "таран лапкой")
	# «Двойной удар»: каждый второй таран не ушибает лапку
	if has_pk("combo") and not combo_flip:
		combo_flip = true
		paw_bruise = 0.0
	else:
		combo_flip = false
		paw_bruise = maxf(0.5, PAW_BRUISE - pk("ram_bruise"))
	rams += 1
	pstat_add("rams")
	shake = maxf(shake, 5.0)
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
	if throw_cd > 0.0 or not levelup.is_empty():
		return
	if held_e != null or paw_bruise > 0.0 or over != "" or paused or not FIELD.has_point(p):
		return
	var best := grab_target(p)
	if best == null:
		return
	held_e = best
	hold_t = HOLD_TIME + pk("hold")
	sling_anchor = best.pos
	enemies.erase(best)
	best.push_vel = Vector2.ZERO
	sfx("grab", -4.0, randf_range(0.9, 1.1))


## Что схватит лапка в этой точке (ближайший носок, клубок, пылинка или тапок).
func grab_target(p: Vector2) -> Enemy:
	var best: Enemy = null
	var bd := GRAB_R + pk("grab_r")
	for e in enemies_near(p, bd + 12.0, 6):
		if e.grabbable() and p.distance_to(e.pos) < bd + e.radius * 0.5:
			best = e
			bd = p.distance_to(e.pos)
	return best


func _drop_held() -> void:
	if held_e == null:
		return
	var e := held_e
	held_e = null
	e.stun = 0.4
	e.pos = resolve_circle(e.pos, e.radius)
	enemies.append(e)
	throw_cd = 1.0
	sfx("bounce", -10.0, 0.7)


## Рогатка: зажали предмет, оттянули лапку — он летит в обратную сторону, тем быстрее, чем сильнее натянуто.
func throw_vector() -> Vector2:
	if held_e == null:
		return Vector2.ZERO
	var lim := sling_max()
	var pull: Vector2 = (Vector2(paw["pos"]) - sling_anchor).limit_length(lim)
	if pull.length() < 18.0:
		return Vector2.ZERO
	var spd := sling_speed() * pull.length() / lim
	if held_e.type == Enemy.T.SLIPPER:
		spd *= 0.55 * (1.0 + pk("slipper_fast"))
	return -pull.normalized() * spd

func _release_grab(v_override: Vector2 = Vector2.ZERO) -> void:
	if held_e == null:
		return
	var v := v_override if v_override != Vector2.ZERO else throw_vector()
	if v_override != Vector2.ZERO and held_e.type == Enemy.T.SLIPPER:
		v *= 0.55 * (1.0 + pk("slipper_fast"))
	if v.length() < 240.0:
		_drop_held()
		return
	var e := held_e
	held_e = null
	# «Двойная рогатка»: первый заряд — почти без отката
	if has_pk("twin") and twin_ready:
		twin_ready = false
		throw_cd = 0.35
	else:
		throw_cd = throw_cd_full()
		twin_refill = true
	pstat_add("throws")
	thrown.append({"id": new_id(), "pos": e.pos, "vel": v, "e": e, "born": time, "spin": 0.0, "dodged": false, "dist": 0.0, "fire": 0.0})
	# «Носочный залп»: ещё два носка веером
	if has_pk("volley") and e.type != Enemy.T.SLIPPER:
		for a in [-0.2, 0.2]:
			var ex := spawn_enemy(Enemy.T.SOCK, e.pos, true)
			enemies.erase(ex)
			thrown.append({"id": new_id(), "pos": e.pos, "vel": v.rotated(a), "e": ex, "born": time, "spin": 0.0, "dodged": false, "dist": 0.0, "fire": 0.0})
	log_event("ИГРОК", "бросок: %s" % EDEFS[e.type]["name"])
	sfx("throw", -4.0, randf_range(0.9, 1.2))


func _update_thrown(delta: float) -> void:
	for s in thrown:
		var e: Enemy = s["e"]
		var slipper: bool = e.type == Enemy.T.SLIPPER
		var v: Vector2 = s["vel"]
		if s.has("return"):
			# «Тапок-бумеранг»: летит обратно в лапку и сразу готов к новому броску
			var to: Vector2 = paw["pos"]
			s["pos"] = Vector2(s["pos"]).move_toward(to, 1100.0 * delta)
			s["spin"] = float(s["spin"]) + delta * 14.0
			if Vector2(s["pos"]).distance_to(to) < 24.0 or time - float(s["return"]) > 2.0:
				s["done"] = true
				if held_e == null and over == "" and FIELD.has_point(to):
					held_e = e
					e.pos = to
					sling_anchor = to
					hold_t = HOLD_TIME + pk("hold")
					throw_cd = 0.0
					sfx("grab", -4.0, 1.3)
				else:
					e.pos = resolve_circle(to.clamp(floor_rect.position, floor_rect.end), e.radius)
					enemies.append(e)
			continue
		var p: Vector2 = s["pos"] + v * delta
		s["dist"] = float(s["dist"]) + v.length() * delta
		# «Огненный носок»: носок разгорается в полёте, чем дальше — тем больнее
		if not slipper and has_pk("fire"):
			s["fire"] = clampf(float(s["dist"]) / (9.0 * M), 0.0, 1.0)
		s["spin"] = float(s["spin"]) + delta * (10.0 if slipper else 18.0)
		v *= exp(-(0.9 if slipper else 0.45) * delta)
		var land := false
		if is_blocked(p) and has_pk("ricochet") and not s.has("bounced"):
			# «Рикошет»: отражаемся по одной оси и летим дальше
			var op: Vector2 = s["pos"]
			if not is_blocked(Vector2(op.x - v.x * delta, p.y)):
				v.x = -v.x
			elif not is_blocked(Vector2(p.x, op.y - v.y * delta)):
				v.y = -v.y
			else:
				v = -v
			s["bounced"] = true
			p = op
			sfx("bounce", -6.0, 1.6)
			add_fx({"kind": "ring", "pos": p, "r": 16.0, "dur": 0.2, "color": Color(0.42, 0.31, 0.7, 0.9)})
		elif is_blocked(p):
			land = true
			p = resolve_circle(p, e.radius)
			v = -v * 0.3
			sfx("bounce", -10.0, 1.4)
		elif not s["dodged"] and p.distance_to(hero.pos) < hero.radius + e.radius + 40.0 and hero.try_dodge_throw(int(s["id"]), v):
			# заметил летящий предмет — отпрыгнул
			s["dodged"] = true
			hero_dodges += 1
		elif p.distance_to(hero.pos) < hero.radius + e.radius + 4.0:
			hero.wariness["throw"] = minf(0.6, float(hero.wariness["throw"]) + 0.15)
			var dist_m: float = float(s["dist"]) / M
			var nm := String(EDEFS[e.type]["name"]).to_lower()
			var label := ("Огненный " if float(s["fire"]) > 0.6 else "Брошенный ") + nm
			var st := pk("throw_stun")
			if slipper:
				pstat_add("slipper_hits")
				hero.take_damage(6.0 * (1.0 + pk("slipper_dmg")), "throw", label, true)
				# «Тапок-выбивала»: выбивает фрукты, издалека — два
				if has_pk("knock"):
					var n := 2 if dist_m > 9.0 else 1
					if randf() < pk("knock_more"):
						n += 1
					_knock_fruits(n, v.normalized())
				if has_pk("slipper_mark"):
					hero.mark_t = maxf(hero.mark_t, pk("slipper_mark"))
				hero.knocked(v.normalized(), 260.0, 0.3 + pk("slipper_stun") + st)
				if has_pk("boomerang"):
					s["return"] = time
					s["pos"] = p
					s["vel"] = Vector2.ZERO
					throws_hit += 1
					sfx("hit", 0.0, 1.3)
					continue
			elif has_pk("fire"):
				pstat_add("sock_hits")
				var dm := (2.0 + 1.0 * dist_m) * (1.0 + pk("sock_dmg"))
				if float(s["fire"]) > 0.6:
					pstat_add("fire_hits")
					dm *= 1.0 + pk("fire_dmg")
					if has_pk("burn"):
						hero.add_dot(pk("burn"), 3.0, "Поджог")
				hero.take_damage(dm, "throw", label, true)
				hero.knocked(v.normalized(), 180.0, 0.15 + st)
			else:
				pstat_add("sock_hits")
				hero.take_damage((3.0 + 0.3 * dist_m) * (1.0 + pk("sock_dmg")), "throw", label, true)
				hero.knocked(v.normalized(), 140.0, 0.1 + st)
			if has_pk("throw_xp"):
				var lost := mini(hero.xp, int(pk("throw_xp")))
				if lost > 0:
					hero.xp -= lost
					add_text(hero.pos + Vector2(0, -78), "−%d опыта" % lost, Color("6a4fb3"), 18)
			if float(s["fire"]) > 0.6:
					add_fx({"kind": "fire", "pos": hero.pos, "r": 50.0, "dur": 0.4})
			throws_hit += 1
			land = true
			shake = 3.0 + 4.0 * float(s["fire"])
			sfx("hit", 0.0, 1.3)
			sfx("squawk", -4.0, 1.1)
		elif v.length() < 160.0:
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


## Тапок выбивает из попугая случайные фрукты: они отлетают на пол, и он может их подобрать.
func _knock_fruits(n: int, dir: Vector2) -> void:
	for i in n:
		if hero.fruits.is_empty():
			break
		var f: String = hero.fruits[randi() % hero.fruits.size()]
		hero.fruits.erase(f)
		pstat_add("fruits_knocked")
		var to := resolve_circle(hero.pos + dir.rotated(randf_range(-0.8, 0.8)) * randf_range(2.5, 4.5) * M, 12.0)
		fruit_drops.append({"id": new_id(), "pos": hero.pos, "to": to, "fruit": f, "born": time, "life": 12.0, "taken": false, "t": 0.0})
		add_text(hero.pos + Vector2(0, -60 - i * 20), "выбит фрукт!", Color("6a4fb3"), 20)
		hero.say("Мой %s!" % String(Skills.FRUIT_NAMES[f]).to_lower())
		log_event("ИГРОК", "тапок выбил фрукт: %s" % Skills.FRUIT_NAMES[f])



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
				log_event("ИГРОК", "подмена проса: %s" % MENU_NAMES[kind])
				millet_cd = millet_cd_full()
				pstat_add("swaps")
				_finish_tut("millet")
				add_fx({"kind": "sparkle", "pos": g["pos"], "dur": 0.5})
			return
	menu = {}


## «Капканная дорожка»: ещё два капкана в крупном просе рядом (или новые колоски-капканы).
func _trap_path(at: Vector2) -> void:
	var n := 0
	for g in gems:
		if n >= 2:
			break
		if g["big"] and not g["glow"] and not g.has("mod") and not g["taken"] and Vector2(g["pos"]).distance_to(at) < 6.0 * M:
			g["mod"] = "trap"
			n += 1
	while n < 2:
		var q := resolve_circle(at + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(2.0, 3.5) * M, 10.0)
		var g := _drop_gem(q.clamp(floor_rect.position + Vector2(20, 20), floor_rect.end - Vector2(20, 20)), true)
		g["mod"] = "trap"
		g["xp"] = 0
		n += 1


func _launch_missile(p: Vector2) -> void:
	var g: Dictionary = aim["gem"]
	aim = {}
	if g["taken"]:
		return
	g["taken"] = true
	var dir: Vector2 = (p - Vector2(g["pos"])).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	missiles.append({"id": new_id(), "pos": g["pos"], "vel": dir * 7.0 * M * (1.0 + pk("missile_speed")), "bounces": 5 + int(pk("missile_bounce")), "born": time, "life": 14.0})
	_finish_tut("millet")
	log_event("ИГРОК", "просо-снаряд")
	millet_cd = millet_cd_full()
	pstat_add("swaps")
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
			# «Просяной град»: на первом отскоке снаряд делится на три
			if has_pk("hail") and not s.has("split"):
				s["split"] = true
				for a in [-0.5, 0.5]:
					missiles.append({"id": new_id(), "pos": p, "vel": v.rotated(a), "bounces": 2, "born": time, "life": 6.0, "split": true})
			sfx("bounce", -6.0, randf_range(0.9, 1.2))
			add_fx({"kind": "ring", "pos": p, "r": 18.0, "dur": 0.2, "color": Color(0.95, 0.75, 0.25, 0.9)})
		s["pos"] = np
		s["vel"] = v
		if np.distance_to(hero.pos) < hero.radius + 12.0:
			hero.take_damage(10.0 + pk("missile_dmg"), "missile", "Просо-снаряд", true)
			hero.knocked(v.normalized(), 120.0, 0.5 + pk("missile_stun"))
			pstat_add("missile_hits")
			tricks += 1
			s["life"] = 0.0
			sfx("hit", 0.0, 0.9)
		if int(s["bounces"]) < 0 or float(s["life"]) <= 0.0:
			add_fx({"kind": "poof", "pos": np, "dur": 0.5, "col": Color("f5c84c")})
			s["done"] = true
	missiles = missiles.filter(func(s): return not s.has("done"))


# ---------- кнопки игрока ----------

func cast_meteor() -> void:
	if over != "" or paused or meteor_cd > 0.0 or phase != "play" or not ability_unlocked("book") or not levelup.is_empty():
		return
	var p: Vector2 = paw["pos"]
	if not sim and not FIELD.has_point(p):
		return
	meteor_cd = book_cd_full()
	meteors_cast += 1
	pstat_add("book_casts")
	log_event("ИГРОК", "книга (до героя %d м)" % int(p.distance_to(hero.pos) / M))
	p = p.clamp(floor_rect.position, floor_rect.end)
	var pts: Array = [p]
	if has_pk("book_rain"):
		pts = []
		for i in 3:
			pts.append((p + Vector2(0, -1.5 * M).rotated(TAU * i / 3.0)).clamp(floor_rect.position, floor_rect.end))
	for q in pts:
		_add_book(q, METEOR_DELAY - pk("book_fast"))
	if has_pk("book_fake"):
		# ложная тень: с той стороны, куда Кеша побежит от настоящей
		var away := (hero.pos - p).normalized()
		if away == Vector2.ZERO:
			away = Vector2.RIGHT
		for i in 1 + int(pk("book_fake_n")):
			var q: Vector2 = (hero.pos + away.rotated(randf_range(-0.7, 0.7)) * (METEOR_R + 0.8 * M)).clamp(floor_rect.position, floor_rect.end)
			var fm := _add_book(q, METEOR_DELAY - pk("book_fast"))
			fm["fake"] = true
	if has_pk("book_second"):
		delayed.append({"at": time + 1.0, "kind": "book2"})
	sfx("whoosh", -4.0)


func _add_book(p: Vector2, delay: float) -> Dictionary:
	var m := {"id": new_id(), "pos": p, "born": time, "t": 0.0, "delay": delay, "r": METEOR_R * (1.0 + pk("book_r")),
		"landed": false, "land_t": 0.0, "focus_t": -1.0, "notice_t": -1.0, "hide": pk("book_hide")}
	meteors.append(m)
	return m


## Клетка: под лапкой 2 с растёт тень и ползёт за ней, потом сверху падает клетка и накрывает того, кто под ней.
func cast_wave() -> void:
	if over != "" or paused or phase != "play" or not ability_unlocked("basket") or wave_cd > 0.0 or not levelup.is_empty():
		return
	var p: Vector2 = paw["pos"]
	if not sim and not FIELD.has_point(p):
		return
	wave_cd = cage_cd_full()
	pstat_add("baskets")
	log_event("ИГРОК", "клетка")
	p = p.clamp(floor_rect.position, floor_rect.end)
	var delay := maxf(1.0, BASKET_DELAY - pk("cage_fast"))
	var m := {"id": new_id(), "pos": p, "born": time, "t": 0.0, "delay": delay, "r": BASKET_R * (1.0 + pk("cage_r")),
		"landed": false, "land_t": 0.0, "focus_t": -1.0, "notice_t": -1.0, "basket": true, "hide": pk("cage_hide"),
		"trap": cage_trap_time()}
	if has_pk("hunter"):
		m["hidden"] = delay - 0.6
	meteors.append(m)
	sfx("whoosh", -6.0, 0.6)


## Клетка, пока падает, медленно ползёт за лапкой (в прогоне — за целью бота).
func _cage_follow(m: Dictionary, delta: float) -> void:
	var spd := BASKET_FOLLOW * (1.0 + pk("cage_follow")) * (2.0 if has_pk("hunter") else 1.0)
	var to: Vector2 = paw["pos"]
	if sim:
		to = hero.pos + hero.vel * 0.3
	to = to.clamp(floor_rect.position, floor_rect.end)
	m["pos"] = Vector2(m["pos"]).move_toward(to, spd * delta)
	if has_pk("cage_slow") and hero.pos.distance_to(m["pos"]) < float(m["r"]):
		hero.slow(0.15, 0.3 + pk("cage_slow_more"))



# ---------- орда ----------

## Волны по образцу Vampire Survivors: на каждом отрезке — минимум врагов на поле и интервал спавна.
const WAVES := [
	[0.0, 5, 1.8, 0.0, 0.0],
	[30.0, 9, 1.3, 0.0, 0.0],
	[60.0, 14, 1.0, 0.12, 0.0],
	[90.0, 18, 0.9, 0.15, 0.0],
	[120.0, 22, 0.8, 0.18, 0.04],
	[150.0, 26, 0.7, 0.2, 0.05],
	[180.0, 30, 0.65, 0.22, 0.05],
	[210.0, 34, 0.6, 0.22, 0.06],
	[240.0, 20, 0.9, 0.2, 0.04],
	[300.0, 28, 0.7, 0.22, 0.06],
]


func _wave() -> Array:
	var w: Array = WAVES[0]
	for row in WAVES:
		if time >= float(row[0]):
			w = row
	return w


func _director(delta: float) -> void:
	if time >= next_horde:
		horde_level += 1
		next_horde += HORDE_STEP
		banner("Гонг!  Орда: уровень %d" % horde_level, Color("3f6fb5"), 34, 2.4)
		sfx("gong", -4.0)
		for e in enemies:
			e.blue = 0.8
	var w := _wave()
	var cnt_k: float = float(Diff.level(diff)["count"]) * (1.25 if curses_on.has("horde") else 1.0)
	var minimum: int = int(float(w[1]) * cnt_k)
	var interval: float = float(w[2]) / cnt_k
	var pack := Trees.wave_at(meta, time)
	var slip_share := float(w[3])
	var spray_share := float(w[4])
	match pack:
		"socks":
			minimum = int(minimum * 1.15)
			slip_share = 0.0
			spray_share = 0.0
		"slippers":
			minimum = int(minimum * 0.75)
			slip_share = 0.45
		"spray":
			spray_share = 0.33
			slip_share *= 0.5
		"calm":
			minimum = int(minimum * 0.5)
			interval *= 1.8
		"yarn":
			slip_share *= 0.5
			if time >= next_pack_swarm:
				next_pack_swarm = time + 10.0
				var sp := edge_point(10.0 * M)
				add_fx({"kind": "jingle", "pos": sp, "dur": 1.4})
				pending.append({"at": time + 1.2, "type": Enemy.T.YARN, "n": 4 + horde_level, "pos": sp})
	if time >= 30.0 and Trees.wave_at(meta, time - 30.0) == "calm" and pack != "calm":
		minimum = int(minimum * 1.35)
		interval *= 0.75
	if time < double_spawn_until:
		interval *= 0.5
	if enraged:
		interval *= 0.7
	var alive := 0
	for e in enemies:
		if not e.is_big():
			alive += 1
	spawn_acc += delta
	var burst := alive < minimum
	while (spawn_acc >= interval or burst) and enemies.size() < MAX_ENEMIES:
		if not burst:
			spawn_acc -= interval
		var t: int = Enemy.T.SOCK
		var r := randf()
		if r < spray_share:
			t = Enemy.T.SPRAYER
		elif r < spray_share + slip_share:
			t = Enemy.T.SLIPPER
		spawn_enemy(t, edge_point(9.0 * M))
		alive += 1
		burst = alive < minimum
	if time >= next_swarm:
		next_swarm = time + randf_range(30.0, 40.0)
		var p := edge_point(10.0 * M)
		# звон слышен до появления: и герой, и игрок знают, откуда катится рой
		add_fx({"kind": "jingle", "pos": p, "dur": 1.4})
		sfx("jingle", -6.0)
		pending.append({"at": time + 1.2, "type": Enemy.T.YARN, "n": 5 + horde_level, "pos": p})
	if time >= next_hand and (boss == null or boss.dead):
		next_hand = time + 75.0
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
		log_event("БОСС", "пылесос проснулся")
		banner("Робот-пылесос проснулся!", Color("b23a2e"), 40, 3.0)
		sfx("boss")
		shake = 10.0
		add_thought("Это ещё что?! Пылесос! Без него отсюда не выбраться.")

func spawn_enemy(type: int, p: Vector2, from_player: bool = false) -> Enemy:
	var d: Dictionary = EDEFS[type]
	var e := Enemy.new()
	e.id = new_id()
	e.type = type
	e.pos = p
	e.born = time
	var l := float(horde_level - 1)
	# орда растёт и от гонга, и от каждого уровня попугая (как в SurvivorsStarterKit)
	var hl := float(hero.level - 1)
	var hp_k := (1.0 + HORDE_HP_GONG * l) * (1.0 + HORDE_HP_LEVEL * hl)
	if type == Enemy.T.BOSS or type == Enemy.T.BOX:
		hp_k = 1.0 + 0.05 * float(hero.level)
	var dl := Diff.level(diff)
	hp_k *= float(dl["boss_hp"]) if type == Enemy.T.BOSS else float(dl["hp"])
	e.max_hp = float(d["hp"]) * hp_k
	e.hp = e.max_hp
	e.speed = float(d["speed"]) * M * (1.0 + 0.03 * l) * float(dl["speed"])
	e.dmg = float(d["dmg"]) * (1.0 + 0.06 * l) * (1.0 + HORDE_DMG_LEVEL * hl) * float(dl["dmg"])
	if type == Enemy.T.SLIPPER and diff >= 1:
		e.shield = 1
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
		if diff >= 2 and e.type == Enemy.T.SLIPPER and e.shield == 0:
			e.shield_t -= delta
			if e.shield_t <= 0.0:
				e.shield = 1
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
						e.grab_cd = 4.5
						if d < 1.9 * M and hero.held <= 0.0 and e.stun <= 0.0:
							hero.grabbed(e)
							sfx("grab", 0.0, 0.6)
				elif d < 1.5 * M and e.grab_cd <= 0.0 and e.stun <= 0.0:
					# перед хватом приседает и растопыривает пальцы: 0,5 с предупреждения
					e.grab_state = 1
					e.grab_t = 0.3 if diff >= 2 else 0.5
			Enemy.T.BOX:
				e.phase += delta * 10.0
				dir = _flee_dir(e, -dir)
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
		if e.type != Enemy.T.BOSS and e.type != Enemy.T.BOX and spd > 0.0:
			dir = _avoid(e, dir)
		if e.stun > 0.0 or e.tumble > 0.0:
			spd = 0.0
		if e.slow > 0.0:
			spd *= 0.5
		if e.rush > 0.0:
			e.rush -= delta
			spd = maxf(spd, e.speed) * e.rush_k
		if hero.bird == "cockatoo" and d < 1.6 * M and e.type != Enemy.T.BOSS:
			spd *= 0.8
		if spd > 0.0:
			e.move_dir = dir
		e.pos += (dir * spd + e.push_vel) * delta
		e.push_vel *= exp(-3.0 * delta)
		if e.type != Enemy.T.BOSS:
			_separate(e)
			e.pos = resolve_circle(e.pos, e.radius)
		else:
			# пылесос проезжает под мебелью и упирается только в стены
			e.pos = e.pos.clamp(floor_rect.position + Vector2(e.radius, e.radius), floor_rect.end - Vector2(e.radius, e.radius))
		var md := e.radius + hero.radius
		if d < md:
			if e.type != Enemy.T.HAND and e.type != Enemy.T.BOX and e.atk_cd <= 0.0 and not e.is_airborne() and e.tumble <= 0.0 and e.stun <= 0.0:
				e.atk_cd = 0.9
				hero.take_damage(e.dmg, ENAMES[e.type], src_label(e), e.from_player)
				if hero.bperks.has("thorns"):
					damage_enemy(e, 6.0, (e.pos - hero.pos).normalized() * 120.0, true, "thorns")
			if d > 0.5 and e.type != Enemy.T.BOSS:
				e.pos = hp_pos - dir * md


## Обход препятствий: если впереди мебель или стена, юнит забирает вбок (каждый в свою сторону).
func _avoid(e: Enemy, dir: Vector2) -> Vector2:
	var look := e.radius + 16.0
	if not _blocked_r(e.pos + dir * look, e.radius * 0.7):
		return dir
	var side := 1.0 if e.id % 2 == 0 else -1.0
	for a in [0.5, 0.9, 1.3, 1.7, 2.2]:
		for s in [side, -side]:
			var d2 := dir.rotated(a * s)
			if not _blocked_r(e.pos + d2 * look, e.radius * 0.7):
				return d2
	return dir


func _blocked_r(p: Vector2, r: float) -> bool:
	if not floor_rect.grow(-r).has_point(p):
		return true
	for o in obstacles:
		if o.grow(r).has_point(p):
			return true
	return false


## Шкатулка убегает: из 16 направлений выбирает то, что дальше от попугая и не упирается в стену.
func _flee_dir(e: Enemy, away: Vector2) -> Vector2:
	var best := away
	var bs := -INF
	for i in 16:
		var d := Vector2.RIGHT.rotated(TAU * i / 16.0)
		var s := d.dot(away)
		var free := 0
		for k in [1.0, 2.0, 3.5]:
			if _blocked_r(e.pos + d * k * M, e.radius):
				break
			free += 1
		if free == 0:
			continue
		s += 0.6 * free + 0.3 * d.dot(e.move_dir)
		if s > bs:
			bs = s
			best = d
	return best


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
				# сложная: второй рывок сразу за первым
				if diff >= 2 and e.state != 3:
					e.state = 3
					e.state_t = 0.3
					e.dash_dir = (hero.pos - e.pos).normalized()
					return 11.0 * M
				e.state = 0
				e.ability_cd = 3.0
			return 11.0 * M
	return 0.0


## Робот-пылесос: ползёт к попугаю и раз в несколько секунд сам выбирает умение:
## засасывание (тянет героя и просо), таран по линии с предупреждением, плевок пылевыми зайчиками.
func _update_boss(e: Enemy, delta: float, d: float, dir: Vector2) -> float:
	e.phase += delta
	e.ability_cd -= delta
	if diff >= 2 and not boss_phase2 and e.hp < e.max_hp * 0.5:
		boss_phase2 = true
		e.speed *= 1.3
		banner("Пылесос перегрелся!", Color("b23a2e"), 36, 2.4)
		sfx("boss", 0.0, 1.5)
		add_fx({"kind": "ring", "pos": e.pos, "r": 6.0 * M, "dur": 0.6, "color": Color(1.0, 0.75, 0.2, 0.9)})
		add_thought("Он перегрелся и искрит! Осторожно.")
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
			var nxt := e.pos + e.dash_dir * 14.0 * M * delta
			# средняя: за пылесосом стелется пыль; перегретый — оставляет искры
			if diff >= 1 and int(e.phase * 10.0) % 2 == 0:
				_add_zone(e.pos, 1.3 * M, "sparks" if boss_phase2 else "dust", 4.0)
			var hit_wall := not floor_rect.grow(-e.radius - 2.0).has_point(nxt)
			if e.pos.distance_to(hero.pos) < e.radius + hero.radius + 6.0 and hero.stun <= 0.0:
				hero.take_damage(15.0 + horde_level, "boss", "Пылесос", false)
				hero.knocked(e.dash_dir.rotated(PI * 0.5 * signf(randf() - 0.5)), 420.0, 0.35)
				sfx("thud")
				shake = 7.0
			if hit_wall or e.state_t <= 0.0:
				e.state = 0
				e.ability_cd = 2.2 * (0.6 if boss_phase2 else 1.0)
				if boss_phase2 and not hit_wall and e.combo == 0:
					# перегрев: второй рывок подряд
					e.combo = 1
					e.state = 2
					e.state_t = 0.5
					e.dash_dir = (hero.pos - e.pos).normalized()
					return 0.0
				e.combo = 0
				if hit_wall:
					_boss_slam(e)
				return 0.0
			return 14.0 * M
		4:
			e.state_t -= delta
			if e.state_t <= 0.0:
				var nd := 9 if diff >= 1 else 6
				for i in nd:
					var a := TAU * i / float(nd)
					spawn_enemy(Enemy.T.DUST, resolve_circle(e.pos + Vector2(cos(a), sin(a)) * (e.radius + 20.0), 9.0))
				add_fx({"kind": "dust", "pos": e.pos, "r": 70.0, "dur": 0.6})
				sfx("pop", 0.0, 0.5)
				e.state = 0
				e.ability_cd = 3.0
			return 0.0
	return e.speed


## Пылесос врезается в стену так, что всё в комнате подпрыгивает и разлетается от удара.
func _boss_slam(e: Enemy) -> void:
	e.stun = 1.2
	shake = 16.0
	furniture_bounce = 0.7
	sfx("thud", 4.0, 0.6)
	sfx("gong", -6.0, 0.6)
	var c := e.pos + e.dash_dir * e.radius
	add_fx({"kind": "dust", "pos": c, "r": 90.0, "dur": 0.7})
	add_fx({"kind": "ring", "pos": c, "r": 9.0 * M, "dur": 0.6, "color": Color(0.5, 0.45, 0.4, 0.8)})
	for o in enemies:
		if o == e or o.dead:
			continue
		var d := o.pos.distance_to(c)
		if d < 10.0 * M:
			o.push_vel += (o.pos - c).normalized() * (900.0 * (1.0 - d / (10.0 * M)) + 200.0)
			o.tumble = 0.6
	for g in gems:
		var gp: Vector2 = g["pos"]
		var d := gp.distance_to(c)
		if d < 10.0 * M:
			g["pos"] = resolve_circle(gp + (gp - c).normalized() * randf_range(40.0, 140.0) * (1.0 - d / (10.0 * M) + 0.3), 6.0)
	if hero.pos.distance_to(c) < 5.0 * M:
		hero.knocked((hero.pos - c).normalized(), 380.0, 0.25)
	add_thought("Ух, как бахнуло!")


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


func damage_enemy(e: Enemy, amount: float, kb: Vector2, show: bool = true, src: String = "") -> void:
	if e.dead:
		return
	if src != "" and not e.from_player:
		# средняя сложность: носки иногда отскакивают, броня тапка гасит удар
		if e.type == Enemy.T.SOCK and diff >= 1 and randf() < 0.12:
			e.tumble = 0.2
			e.push_vel += kb.normalized().rotated(randf_range(-1.2, 1.2)) * 120.0
			add_fx({"kind": "miss", "pos": e.pos, "dur": 0.35})
			return
		if e.shield > 0:
			e.shield -= 1
			e.shield_t = 6.0
			e.flash = 0.1
			add_fx({"kind": "ring", "pos": e.pos, "r": e.radius + 10.0, "dur": 0.25, "color": Color(0.45, 0.65, 0.9, 0.9)})
			return
	if src != "":
		dealt_by_src[src] = float(dealt_by_src.get(src, 0.0)) + minf(amount, maxf(e.hp, 0.0))
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
			# сложная: клубок распадается на два маленьких
			if diff >= 2 and not e.small:
				for k in 2:
					var y2 := spawn_enemy(Enemy.T.YARN, resolve_circle(e.pos + Vector2(randf_range(-14, 14), randf_range(-14, 14)), 7.0), e.from_player)
					y2.small = true
					y2.radius *= 0.65
					y2.max_hp *= 0.4
					y2.hp = y2.max_hp
					y2.xp = 0
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
			if over == "":
				over = "survived"
				_write_log("герой сломал пылесос")
				_begin_outro()
			log_event("БОСС", "пылесос сломан")
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
	if big and not glow and not millet_unlocked and Meta.unlocked(meta, "millet"):
		millet_unlocked = true
		unlock_ability("millet")
		if not sim and not bool(save.get("tut_millet", false)):
			tut = {"kind": "millet", "gem": g, "t": 0.0}
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
		if s.has("boomer") and time - float(s["born"]) > float(s["boomer"]) and not s.has("back"):
			# бумеранг разворачивается и летит к попугаю, задевая всех снова
			s["back"] = true
			s["hit"] = []
		if s.has("back"):
			v = (hero.pos - Vector2(s["pos"])).normalized() * v.length()
			if Vector2(s["pos"]).distance_to(hero.pos) < 20.0:
				s["life"] = 0.0
				continue
		var np: Vector2 = s["pos"] + v * delta
		s["life"] = float(s["life"]) - delta
		if is_blocked(np) and s.has("boomer"):
			pass
		elif is_blocked(np):
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
		var sr: float = s.get("r", 6.0)
		var ssrc: String = s.get("src", "feather")
		for e in enemies_near(np, 30.0 + sr, 6):
			var hit: Array = s["hit"]
			if hit.has(e.id) or np.distance_to(e.pos) > e.radius + sr:
				continue
			hit.append(e.id)
			damage_enemy(e, float(s["dmg"]), v.normalized() * 80.0, true, ssrc)
			if ssrc == "crestfan":
				hero.skill_hits += 1
			if float(s.get("stun", 0.0)) > 0.0:
				e.stun = maxf(e.stun, float(s["stun"]))
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
			if diff >= 1:
				hero.slow(1.5, 0.25)
	enemy_shots = enemy_shots.filter(func(s): return float(s["life"]) > 0.0)


func _update_meteors(delta: float) -> void:
	for m in meteors:
		if not m["landed"]:
			m["t"] = float(m["t"]) + delta
			if m.has("basket"):
				_cage_follow(m, delta)
			if float(m["t"]) >= float(m["delay"]):
				_meteor_land(m)
		else:
			var was: float = m["land_t"]
			m["land_t"] = was + delta
			if m.has("caught"):
				var tt: float = m["trap"]
				if float(m["land_t"]) < tt:
					hero.pos = m["pos"]
					pstat_add("cage_time", delta)
					if has_pk("cage_scatter"):
						for g in gems:
							var gd: Vector2 = Vector2(g["pos"]) - Vector2(m["pos"])
							if not g["taken"] and gd.length() < 4.5 * M and gd.length() > 1.0:
								g["pos"] = (Vector2(g["pos"]) + gd.normalized() * 140.0 * delta).clamp(floor_rect.position + Vector2(12, 12), floor_rect.end - Vector2(12, 12))
				elif was < tt and has_pk("washer"):
					# «Стиральная машина»: Кеша выходит, шатаясь, и роняет фрукт
					hero.slow(3.0, 0.5)
					_knock_fruits(1, Vector2.RIGHT.rotated(randf() * TAU))
					hero.say("Голова кружится…")
	meteors = meteors.filter(func(m): return not m["landed"] or float(m["land_t"]) < (float(m.get("trap", BASKET_TRAP)) + 0.3 if m.has("basket") else 0.9))


func _meteor_land(m: Dictionary) -> void:
	m["landed"] = true
	m["land_t"] = 0.0
	if m.has("basket"):
		_basket_land(m)
		return
	var p: Vector2 = m["pos"]
	var r: float = m["r"]
	if m.has("fake"):
		add_fx({"kind": "poof", "pos": p, "dur": 0.4, "col": Color(0.9, 0.85, 0.78), "r": 16.0})
		return
	shake = 9.0
	sfx("thud")
	add_fx({"kind": "dust", "pos": p, "r": r, "dur": 0.5})
	var hd := hero.pos.distance_to(p)
	if hd <= 2.0 * M:
		pstat_add("book_near")
	if hd <= r + hero.radius * 0.5:
		meteor_hits += 1
		pstat_add("book_hits")
		hero.wariness["meteor"] = float(hero.wariness["meteor"]) + 0.25
		hero.say("Ай! Не заметил книгу." if float(m["notice_t"]) < 0.0 else "Не успел увернуться от книги!")
		hero.take_damage(hero.max_hp() * (0.15 + pk("book_dmg")), "meteor", "Книга с полки", true)
		if has_pk("book_stun"):
			hero.stun = maxf(hero.stun, 1.0 + pk("book_stun_len"))
		if has_pk("book_mark"):
			hero.mark_t = maxf(hero.mark_t, pk("book_mark"))
		sfx("squawk")
	elif float(m["notice_t"]) >= 0.0 and hd < r + 2.0 * M:
		_sim_dodged += 1
		hero_dodges += 1
		pstat_add("book_dodged")
	if has_pk("book_dust") and hd <= r + 1.0 * M:
		hero.slow(pk("book_dust"), 0.3)
	for e in enemies_near(p, r, 999):
		if e.type == Enemy.T.BOSS:
			damage_enemy(e, 60.0, Vector2.ZERO)
			continue
		if not has_pk("book_soft"):
			e.stun = 1.0
			e.push_vel += (e.pos - p).normalized() * 200.0 * e.push_factor
	if has_pk("book_pull"):
		# «Сквозняк»: враги вокруг тянутся к месту удара — к Кеше, если он рядом
		for e in enemies_near(p, r * 2.6, 999):
			if not e.is_big():
				e.push_vel += (p - e.pos).normalized() * 260.0 * (1.0 + pk("pull_more")) * e.push_factor


func _basket_land(m: Dictionary) -> void:
	shake = 6.0
	sfx("thud", 0.0, 1.3)
	var p: Vector2 = m["pos"]
	var r: float = m["r"]
	var tt: float = m["trap"]
	if hero.pos.distance_to(p) <= r:
		m["caught"] = true
		hero.trapped = tt
		hero.pos = p
		tricks += 1
		pstat_add("caught")
		_register_hit("trap")
		hero.say("Меня поймали в клетку!")
		log_event("ИГРОК", "клетка накрыла попугая")
		add_text(p + Vector2(0, -60), "Попался в клетку!", Color("6a4fb3"), 24)
		if has_pk("cage_shock"):
			hero.add_dot(4.0 + pk("shock_dps"), tt, "Прутья под током")
		if has_pk("cage_stress"):
			hero.stress = minf(1.0, hero.stress + pk("cage_stress"))
		for i in int(pk("cage_socks")):
			var e := spawn_enemy(Enemy.T.SOCK, p + Vector2.RIGHT.rotated(TAU * i / 3.0) * 16.0, true)
			e.atk_cd = 0.3
	else:
		hero.say("Мимо, клетка.")
	for e in enemies_near(p, r, 999):
		if not e.is_big() and not e.from_player:
			e.stun = tt
	if has_pk("laundry"):
		# «Бельевая лавина»: кольцо носков вокруг клетки
		var n := 6 + int(pk("laundry_n"))
		for i in n:
			var q := p + Vector2.RIGHT.rotated(TAU * i / float(n)) * (r + 0.6 * M)
			if not is_blocked(q) and floor_rect.has_point(q):
				var e := spawn_enemy(Enemy.T.SOCK, resolve_circle(q, 10.0), true)
				e.speed *= 1.0 + pk("laundry_fast")


func _add_zone(p: Vector2, r: float, kind: String, life: float) -> void:
	for z in zones:
		if z["kind"] == kind and Vector2(z["pos"]).distance_to(p) < r * 0.6:
			z["t"] = 0.0
			return
	zones.append({"pos": p, "r": r, "kind": kind, "t": 0.0, "life": life, "id": new_id(), "born": time})


## Пыль замедляет попугая, искры жгут. Кеша видит зоны и обходит их.
func _update_mines(delta: float) -> void:
	for m in mines:
		m["t"] = float(m["t"]) + delta
		if float(m["t"]) < 0.5:
			continue
		var mp: Vector2 = m["pos"]
		if enemies_near(mp, 18.0, 1).is_empty():
			continue
		for e in enemies_near(mp, float(m["r"]), 999):
			damage_enemy(e, float(m["dmg"]), (e.pos - mp).normalized() * 260.0, true, "mines")
		if m["frag"]:
			for j in 5:
				shots.append({"pos": mp, "vel": Vector2.RIGHT.rotated(TAU * j / 5.0) * 8.0 * M, "dmg": float(m["dmg"]) * 0.3, "pierce": 2, "life": 0.5,
					"hit": [], "bounce": 0, "homing": false, "ice": false, "src": "mines", "kind": "shard", "born": time})
		add_fx({"kind": "poof", "pos": mp, "dur": 0.45, "col": Color("fff6e0"), "r": float(m["r"]) * 0.5})
		add_fx({"kind": "ring", "pos": mp, "r": float(m["r"]), "dur": 0.3, "color": Color(1.0, 0.8, 0.4, 0.9)})
		sfx("pop", -6.0, 0.7)
		m["done"] = true
	mines = mines.filter(func(m): return not m.has("done"))
	for t in tornados:
		t["t"] = float(t["t"]) + delta
		var tp: Vector2 = t["pos"]
		# бредёт к ближайшей толпе, не отходя далеко от попугая
		var ts := enemies_near(tp, 4.0 * M, 1)
		var want: Vector2 = Vector2(t["dir"])
		if not ts.is_empty():
			want = (ts[0].pos - tp).normalized()
		if tp.distance_to(hero.pos) > 4.0 * M:
			want = (hero.pos - tp).normalized()
		t["dir"] = Vector2(t["dir"]).lerp(want, clampf(delta * 2.0, 0.0, 1.0)).normalized()
		t["pos"] = resolve_circle(tp + Vector2(t["dir"]) * 1.6 * M * delta, 12.0)
		for e in enemies_near(tp, 2.2 * M, 999):
			var d: float = e.pos.distance_to(tp)
			if not e.is_big():
				e.push_vel += (tp - e.pos).normalized() * float(t["pull"]) * delta * 10.0
			if d < 1.0 * M:
				damage_enemy(e, float(t["dps"]) * delta, Vector2.ZERO, false, "tornado")
	tornados = tornados.filter(func(t): return float(t["t"]) < float(t["life"]))


func _update_zones(delta: float) -> void:
	for z in zones:
		z["t"] = float(z["t"]) + delta
		if hero.pos.distance_to(z["pos"]) < float(z["r"]):
			if z["kind"] == "dust":
				hero.slow(0.2, 0.35)
			elif z["kind"] == "sparks":
				hero.add_dot(6.0, 0.6, "Искры пылесоса")
	zones = zones.filter(func(z): return float(z["t"]) < float(z["life"]))


func _update_delayed() -> void:
	for d in delayed:
		if time < float(d["at"]):
			continue
		match d["kind"]:
			"echo":
				hero.scream_at(float(d["r"]), float(d["dmg"]))
			"nut", "star":
				var q: Vector2 = d["pos"]
				for e in enemies_near(q, float(d["r"]), 999):
					damage_enemy(e, float(d["dmg"]), (e.pos - q).normalized() * 160.0, true, "nut" if d["kind"] == "nut" and not d.has("book") else ("mimic" if d.has("book") else "stars"))
					if float(d.get("stun", 0.0)) > 0.0:
						e.stun = maxf(e.stun, float(d["stun"]))
					if bool(d.get("burn", false)):
						e.burn = 2.0
						e.burn_dps = 3.0
				add_fx({"kind": "dust" if d["kind"] == "nut" else "ring", "pos": q, "r": float(d["r"]), "dur": 0.4, "color": Color(1.0, 0.9, 0.4, 0.9)})
				if d["kind"] == "nut":
					sfx("thud", -12.0, 1.4)
			"mimic":
				hero.mimic_now(int(d["lvl"]), float(d["sk"]))
			"book2":
				# «Второй том»: туда, куда бежит Кеша
				var q: Vector2 = (hero.pos + hero.vel * 0.8).clamp(floor_rect.position, floor_rect.end)
				_add_book(q, 0.8)
				sfx("whoosh", -6.0, 1.2)
			"hatch":
				var e := spawn_enemy(Enemy.T.SUPER, resolve_circle(d["pos"], 15.0), true)
				e.ability_cd = 1.0
				e.max_hp *= 1.0 + pk("egg_hp")
				e.hp = e.max_hp
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
				var tt := 1.0 + pk("trap_time")
				hero.trapped = tt
				pstat_add("traps")
				pstat_add("trap_time", tt)
				if pk("trap_dmg") > 0.0:
					hero.take_damage(pk("trap_dmg"), "trap", "Капкан", true)
				if has_pk("trap_bleed"):
					hero.add_dot(2.0 + pk("bleed_dps"), 4.0, "Рана от капкана")
				if has_pk("trap_mark"):
					hero.mark_t = maxf(hero.mark_t, pk("trap_mark"))
				if has_pk("trap_path"):
					_trap_path(Vector2(g["pos"]))
				hero.say("Ай! Капкан! Это просо подозрительное.")
				add_fx({"kind": "trap", "pos": hero.pos, "dur": 1.0})
				sfx("trap")
				_register_hit("trap")
				add_text(hero.pos + Vector2(0, -50), "Капкан!", Color("6a4fb3"), 24)
			"rotten":
				pstat_add("rottens")
				hero.take_damage(8.0 + pk("rotten_dmg"), "rotten", "Тухлое просо", true)
				if has_pk("rotten_slow"):
					hero.slow(pk("rotten_slow"), 0.35)
				if has_pk("rotten_xp"):
					var lost := int(float(hero.xp) * (0.3 + pk("rotten_xp_more")))
					hero.xp -= lost
					if lost > 0:
						add_text(hero.pos + Vector2(0, -78), "−%d опыта" % lost, Color("6a4fb3"), 18)
				if has_pk("stink"):
					hero.add_dot(pk("stink"), 3.0, "Вонь")
				if has_pk("rot_harvest"):
					hero.rot_left = 5
				hero.say("Фу! Тухлое!")
				add_fx({"kind": "stink", "pos": hero.pos, "dur": 1.2})
				sfx("rotten")
			"egg":
				hero.say("Это было яйцо?!")
				pstat_add("eggs")
				delayed.append({"at": time + 0.6, "kind": "hatch", "pos": g["pos"]})
				if has_pk("egg_twin"):
					delayed.append({"at": time + 0.9, "kind": "hatch", "pos": Vector2(g["pos"]) + Vector2(24, 0)})
				add_fx({"kind": "egg", "pos": g["pos"], "dur": 0.6})
				sfx("egg")
		return
	if hero.rot_left > 0 and not g["glow"]:
		# «Гнилой урожай»: колосок испорчен
		hero.rot_left -= 1
		hero.take_damage(3.0, "rotten", "Гнилой колосок", true)
		add_fx({"kind": "stink", "pos": hero.pos, "dur": 0.8})
		return
	hero.gain_xp(int(g["xp"]))
	run_millet += int(g["xp"])
	if g["glow"] and not event.is_empty() and event["type"] == "glow":
		event["got"] = int(event["got"]) + 1
		sfx("chime", -6.0, 1.5)
		add_text(g["pos"] + Vector2(0, -20), "%d/%d" % [int(event["got"]), GLOW_NEED], Color("2f8fa8"), 20)
	else:
		sfx("pickup", -16.0, randf_range(0.9, 1.3))


func _update_pickups(delta: float) -> void:
	for f in fruit_drops:
		f["t"] = float(f["t"]) + delta
		f["life"] = float(f["life"]) - delta
		var k := clampf(float(f["t"]) / 0.5, 0.0, 1.0)
		if k < 1.0:
			f["pos"] = Vector2(f["pos"]).lerp(f["to"], k)
		if float(f["life"]) <= 0.0:
			f["taken"] = true
	fruit_drops = fruit_drops.filter(func(f): return not f["taken"])
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
	log_event("ИВЕНТ", "начался: %s" % Skills.EVENT_NAMES[type])
	event = {"type": type, "id": new_id(), "born": time, "left": 30.0, "fruit": Skills.FRUITS[randi() % Skills.FRUITS.size()]}
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
	add_fx({"kind": "event_card", "pos": Vector2(960, 300), "dur": 3.0, "type": type, "fruit": event["fruit"]})
	sfx("event")


func _event_reward() -> String:
	var f: String = event.get("fruit", Skills.FRUITS[randi() % Skills.FRUITS.size()])
	var from: Vector2 = event["pos"] if event.has("pos") else hero.pos
	add_fx({"kind": "confetti", "pos": from, "dur": 1.4})
	add_fx({"kind": "reward_fly", "pos": from, "to": Vector2(48 + hero.fruits.size() * 56, 506), "dur": 1.1, "fruit": f})
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
	banner("Кеша прошёл ивент: +%s!" % String(Skills.FRUIT_NAMES[f]).to_lower(), Color("8a5a1e"), 30, 2.4)
	sfx("win", -6.0)
	_end_event()


func _event_fail() -> void:
	var ok_ignore: bool = event["type"] == "altar"
	_mark_result("skip" if ok_ignore else "fail")
	if not ok_ignore:
		events_denied += 1
		banner("СОРВАНО: %s" % Skills.EVENT_NAMES[event["type"]], Color("b23a2e"), 34, 2.4)
		add_fx({"kind": "stamp", "pos": event["pos"] if event.has("pos") else hero.pos, "dur": 2.0})
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
	fruits_eaten += 1
	sfx("fruit")
	add_fx({"kind": "eat", "pos": hero.pos, "dur": 0.6, "fruit": f})
	match f:
		"apple":
			var heal := 40.0 + (20.0 if hero.bperks.has("fruit_love") else 0.0)
			hero.hp = minf(hero.max_hp(), hero.hp + heal)
			add_text(hero.pos + Vector2(0, -50), "+%d" % int(heal), Color("5a9a4a"), 22)
		"chili":
			var rr := 3.5 * M
			for e in enemies_near(hero.pos, rr, 999):
				damage_enemy(e, 40.0 + 4.0 * hero.level, (e.pos - hero.pos).normalized() * 200.0)
				e.burn = 2.0
				e.burn_dps = 6.0
			add_fx({"kind": "fire", "pos": hero.pos, "r": rr, "dur": 0.6})
			sfx("fire")
		"carrot":
			hero.speed_t = 8.0 if hero.bperks.has("fruit_love") else 5.0
		"grape":
			hero.xp += hero.xp_next
		"lemon":
			hero.shield_hits = 3


# ---------- левелап героя: замедление и видимый выбор ----------

const LU_PICK := 1.2
const LU_SLOW := 1.8
const LU_END := 2.4
const SLING_BASE := 130.0
const SLING_STEP := 30.0
const SOCK_SPEED_BASE := 1150.0
const SOCK_SPEED_STEP := 250.0


func sling_max() -> float:
	return SLING_BASE * (1.0 + pk("sling_len"))


func sling_speed() -> float:
	return SOCK_SPEED_BASE * (1.0 + pk("sling_len"))


func pk(k: String) -> float:
	return float(perks.get(k, 0.0))


func has_pk(k: String) -> bool:
	return perks.has(k)


## Счётчики игрока для условий узлов штаба (копятся всегда, даже без усиления).
func pstat_add(k: String, n: float = 1.0) -> void:
	run_pstats[k] = float(run_pstats.get(k, 0.0)) + n


func curse_cd() -> float:
	return 0.75 if curses_on.has("quick") else 1.0


func throw_cd_full() -> float:
	return maxf(1.0, THROW_CD - pk("throw_cd")) * curse_cd()


func book_cd_full() -> float:
	var cd := maxf(4.0, METEOR_CD - pk("book_cd"))
	if has_pk("librarian") and hero != null and hero.hp_frac() < 0.5:
		cd *= 0.5
	return cd * curse_cd()


func cage_cd_full() -> float:
	return maxf(8.0, WAVE_CD - pk("cage_cd")) * curse_cd()


func millet_cd_full() -> float:
	return maxf(10.0, MILLET_CD - pk("millet_cd")) * curse_cd()


func cage_trap_time() -> float:
	return BASKET_TRAP + pk("cage_time")


func _make_cards() -> Array:
	var pool: Array = []
	var h := hero
	for k in Skills.SKILLS:
		if not h.pool.has(k) and not h.skills.has(k):
			continue
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
	if held_e != null:
		_drop_held()
	menu = {}
	aim = {}
	hero.consume_level()
	if not sim:
		add_text(hero.pos + Vector2(0, -96), "орда крепнет: +%d%%" % int(round(HORDE_HP_LEVEL * 100.0 * float(hero.level - 1))), Color("3f6fb5"), 16)
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
	var first: bool = not bool(save.get("tut_block", false))
	levelup = {"cards": cards, "scores": scored, "chosen": best, "t": 0.0, "applied": false, "level": hero.level,
		"blocked": -1, "tut": first, "need_block": cards.size() > 1 and not sim and ability_unlocked("block"), "wait": 0.0}
	if sim and (full_bot or prog) and cards.size() > 1 and ability_unlocked("block"):
		_block_card(best)
	hero.choosing = true
	sfx("level", -4.0)


func _apply_time_scale() -> void:
	var k := 1.0
	if not levelup.is_empty() and (levelup_block_open() or float(levelup["t"]) < LU_SLOW):
		# с запретом игра застывает, без него — только замедляется, пока попугай выбирает
		k = 0.001 if bool(levelup["need_block"]) else 0.3
	if not tut.is_empty():
		k = 0.04
	if over != "" or phase == "intro":
		k = 1.0
	Engine.time_scale = game_speed * k



## Позиция карты выбора на кольце вокруг попугая (для рисования и кликов игрока).
## Позиция карты выбора на кольце вокруг попугая (для рисования и кликов игрока).
func levelup_card_pos(i: int) -> Vector2:
	var n: int = levelup["cards"].size()
	var appear := clampf(float(levelup.get("appear", 0.0)) / 0.3, 0.0, 1.0)
	var ring := 120.0 * (0.6 + 0.4 * appear)
	var a := -PI * 0.5 + TAU * float(i) / float(n)
	return levelup_center() + Vector2(cos(a), sin(a)) * ring


## Центр кольца: у попугая, но не ближе 200 px к краю поля, чтобы карты и подсказки помещались.
func levelup_center() -> Vector2:
	return hero.pos.clamp(FIELD.position + Vector2(210, 230), FIELD.end - Vector2(210, 200))



## Окно игрока: пока попугай думает, можно ткнуть в одну карту и запретить её.
## Сначала игрок запрещает одно умение (без таймера), потом попугай выбирает из оставшихся.
func levelup_block_open() -> bool:
	return not levelup.is_empty() and bool(levelup["need_block"]) and int(levelup["blocked"]) < 0

func _try_block(p: Vector2) -> bool:
	if not levelup_block_open():
		return false
	for i in levelup["cards"].size():
		if p.distance_to(levelup_card_pos(i)) < 34.0:
			_block_card(i)
			return true
	return false


func _block_card(i: int) -> void:
	levelup["blocked"] = i
	var c: Dictionary = levelup["cards"][i]
	var best := -1
	for j in levelup["cards"].size():
		if j != i and (best < 0 or float(levelup["scores"][j]["score"]) > float(levelup["scores"][best]["score"])):
			best = j
	var was_fav: bool = int(levelup["chosen"]) == i
	if best >= 0:
		levelup["chosen"] = best
	if was_fav:
		hero.say("Эй! Я хотел %s!" % String(Skills.NAMES[c["key"]]))
	log_event("ИГРОК", "запрет умения: %s" % Skills.NAMES[c["key"]])
	sfx("trap", -4.0, 1.3)
	levelup["t"] = 0.0
	if bool(levelup["tut"]) and not sim:
		save["tut_block"] = true
		Save.store(save)

func _update_levelup(real_dt: float) -> void:
	if levelup.is_empty() or paused or over != "":
		return
	levelup["appear"] = float(levelup.get("appear", 0.0)) + real_dt
	if levelup_block_open():
		levelup["wait"] = float(levelup["wait"]) + real_dt
		if shot_at > 0.0 and float(levelup["wait"]) > 0.8:
			if shot_block:
				# снимок экрана запрета: лапка над картой, чтобы видно было подсказку
				paw["pos"] = levelup_card_pos(1)
				shot_at = time
			else:
				_block_card(int(levelup["chosen"]))
		return # игра стоит, пока игрок не запретит одно умение
	levelup["t"] = float(levelup["t"]) + real_dt
	var t: float = levelup["t"]
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
	log_event("УРОН", "%s −%.0f → %d/%d" % [label, a, int(hero.hp), int(hero.max_hp())])
	if from_player or src == "meteor" or src == "paw":
		player_by_tool[label] = int(player_by_tool.get(label, 0)) + int(round(a))
	dmg_by_src[src] = int(dmg_by_src.get(src, 0)) + int(a)
	var mine := from_player or src == "meteor" or src == "paw"
	if mine:
		player_damage += a
		add_text(hero.pos + Vector2(randf_range(-12, 12), -48), "−%d" % int(round(a)), Color("6a4fb3"), 22 + mini(10, int(a / 4.0)))
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
	_write_log("герой повержен")
	_begin_outro()
	hero.say("...Попался.")
	banner("ПОПАЛСЯ!", Color("b23a2e"), 56, 3.0)
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
					damage_enemy(e, float(f["dps"]) * delta, Vector2.ZERO, false, "mirror")
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
	log_event("МЫСЛЬ", s)
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
	if sim_bot and over == "" and meteor_cd <= 0.0 and ability_unlocked("book") and time > 5.0:
		paw["pos"] = hero.pos + hero.vel * 0.8 + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		cast_meteor()
	if (full_bot or mid_bot) and over == "":
		_full_bot()
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
		print("ДАННЫЕ ", JSON.stringify({"over": over, "time": snappedf(time, 0.1), "level": hero.level, "boss_hp": (boss.hp / boss.max_hp if boss != null and not boss.dead else 0.0), "boss": boss_defeated, "skills": hero.skills, "mods": hero.mods.values(), "general": hero.general, "taken": dmg_by_src, "dealt": dealt_by_src, "events": hero.events_done, "events_total": events_total, "millet": run_millet, "feathers": save.get("feathers", 0), "up": meta["parrot"]["up"], "quests": hero.quests, "player_dmg": int(player_damage), "unlocked": meta["unlocked"].keys(), "hq": Trees.bought_total(meta), "diff": diff, "dunl": Diff.unlocked(meta), "bird": hero.bird, "birds": Parrots.owned(meta).size(), "enh": Trees.hq(meta)["enh"], "pskills": Meta.parrot_skills(meta), "plan": hero.plan, "kills": kills, "chests": hero.chests_opened, "fruits": fruits_eaten, "rams": rams, "hp_frac": hero.hp_frac(), "qall": _all_quests()}))
		get_tree().quit()


## Самопроверка взаимодействий игрока без мыши: `-- --sim --nobot --selftest`.
func _selftest_step() -> void:
	var steps := [
		[3.0, "queue"], [8.0, "throw"], [12.0, "trap"], [20.0, "rotten"], [28.0, "egg"],
		[36.0, "missile"], [45.0, "throw"], [125.0, "meteor"], [182.0, "wave"],
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
				var held := held_e != null
				_release_grab((hero.pos - s.pos).normalized() * 1200.0)
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
	if over != "" or time > 190.0:
		print("ТЕСТ итог: бросков в цель %d, подмен сработало %d, урон игрока %d, урон по герою %s" % [throws_hit, tricks, int(player_damage), str(dmg_by_src)])
		get_tree().quit()


# ---------- журнал забега ----------

func log_event(kind: String, text: String) -> void:
	if sim:
		return
	run_log.append("%6.1f  %-7s %s" % [time, kind, text])


## Пишет журнал в user://runs/ (на Windows: %APPDATA%/Godot/app_userdata/Попугай наоборот/runs).
func _write_log(result: String) -> void:
	if sim or run_log.is_empty():
		return
	DirAccess.make_dir_recursive_absolute("user://runs")
	var stamp := Time.get_datetime_string_from_system(false, true).replace(":", "-").replace(" ", "_")
	run_log_path = "user://runs/run_%s.txt" % stamp
	var f := FileAccess.open(run_log_path, FileAccess.WRITE)
	if f == null:
		return
	f.store_line("Забег: %s на %s" % [result, Hud.mmss(time)])
	f.store_line("Герой: уровень %d, здоровье %d/%d, умения %s, пассивки %s, моды %s" % [hero.level, int(hero.hp), int(hero.max_hp()), str(hero.skills), str(hero.general), str(hero.mods.values())])
	f.store_line("Урон по герою по источникам: %s" % str(dmg_by_src))
	f.store_line("Урон от игрока по инструментам: %s" % str(player_by_tool))
	f.store_line("Книги: %d из %d · тараны: %d · броски в цель: %d · подмены: %d · ивенты пройдено %d, сорвано %d · пылесос %s" % [meteor_hits, meteors_cast, rams, throws_hit, tricks, hero.events_done, events_denied, "сломан" if boss_defeated else ("жив" if boss != null else "не появился")])
	f.store_line("")
	for line in run_log:
		f.store_line(line)
	f.close()


## «Сильный игрок» для прогонов: бросает носки, подменяет просо, опрокидывает корзину.
func _full_bot() -> void:
	_build_grid()
	if mid_bot and time >= _bot_ram and time > 10.0:
		# таран: средний игрок попадает не всегда, а попугай уворачивается, если смотрит на лапку
		_bot_ram = time + randf_range(6.0, 10.0)
		if randf() < 0.6 and hero.ram_immune <= 0.0:
			paw_bruise = PAW_BRUISE
			rams += 1
			if hero.focus.size() < 3 or randf() < 0.5:
				rams -= 1
				apply_ram(Vector2.RIGHT.rotated(randf() * TAU))
	if time >= _bot_throw:
		_bot_throw = time + (randf_range(3.5, 6.0) if mid_bot else randf_range(2.0, 3.5))
		for e in enemies_near(hero.pos, 7.0 * M, 20):
			if e.grabbable() and e.pos.distance_to(hero.pos) > 3.0 * M and (e.type != Enemy.T.SLIPPER or hero.fruits.size() > 0):
				_try_grab(e.pos)
				if held_e != null:
					var spread := 90.0 if mid_bot else 40.0
					var aim := hero.pos + hero.vel * 0.3 + Vector2(randf_range(-spread, spread), randf_range(-spread, spread))
					_release_grab((aim - held_e.pos).normalized() * 1200.0)
				break
	if millet_cd <= 0.0 and millet_unlocked:
		for g in gems:
			if g["big"] and not g["glow"] and not g.has("mod") and Vector2(g["pos"]).distance_to(hero.pos) < 6.0 * M:
				g["mod"] = ["trap", "rotten", "egg"][randi() % 3]
				millet_cd = millet_cd_full()
				pstat_add("swaps")
				break
	if wave_cd <= 0.0 and ability_unlocked("basket") and (not mid_bot or prog):
		paw["pos"] = hero.pos + hero.vel * 1.4
		cast_wave()
	if not millet_unlocked:
		return



# ---------- влёт, обучение, кнопки по ходу забега ----------

const ABILITY_ORDER := ["throw", "ram", "millet", "book", "basket"]


func ability_unlocked(k: String) -> bool:
	match k:
		"throw", "ram":
			return true
		"millet":
			return Meta.unlocked(meta, "millet") and millet_unlocked
		"book":
			return Meta.unlocked(meta, k) and time >= BOOK_UNLOCK
		"basket":
			return Meta.unlocked(meta, k) and time >= WAVE_UNLOCK
		"block":
			return Meta.unlocked(meta, k)
	return false


## Инструменты открываются по ходу забега, как раньше: таран 0:20, книга 2:00, клетка 3:00.
func _check_unlocks() -> void:
	if time >= RAM_UNLOCK:
		unlock_ability("ram")
	if Meta.unlocked(meta, "book") and time >= BOOK_UNLOCK:
		unlock_ability("book")
	if Meta.unlocked(meta, "basket") and time >= WAVE_UNLOCK:
		unlock_ability("basket")



## Когда кнопка открывается: в первом забеге она появляется с анимацией, потом видна серой заранее.
## Кнопки исследованных инструментов видны всегда; закрытые в мете — не показываются.
func ability_visible(k: String) -> bool:
	if k == "throw" or k == "ram":
		return true
	return Meta.unlocked(meta, k)

func unlock_ability(k: String) -> void:
	if unlock_seen.has(k):
		return
	unlock_seen[k] = Time.get_ticks_msec() / 1000.0
	var names := {"ram": "таран лапкой", "millet": "подмена проса", "book": "книга с полки [Q]", "basket": "клетка [W]"}
	if names.has(k) and not sim:
		banner("Новое умение: " + String(names[k]), Color("6a4fb3"), 30, 2.4)
		sfx("level", -8.0, 1.2)


func _update_intro(dt: float) -> void:
	intro_t += dt
	var k := clampf(intro_t / (INTRO_TIME - 0.6), 0.0, 1.0)
	var e := 1.0 - pow(1.0 - k, 3.0)
	var a := Vector2(FIELD.position.x - 80, 120)
	var b := Vector2(900, 660)
	var mid := Vector2(700, 200)
	hero.pos = a.lerp(mid, e).lerp(mid.lerp(b, e), e)
	hero.heading = (b - a).normalized()
	hero.bob += dt * 20.0
	if intro_t >= INTRO_TIME:
		phase = "play"
		hero.pos = b
		banner("Старт!", Color("4f8f3a"), 44, 1.4)
		sfx("gong", -6.0, 1.3)
		hero.say("Ну, поехали.")


func _update_tut(dt: float) -> void:
	tut["t"] = float(tut["t"]) + dt
	if shot_at > 0.0 and float(tut["t"]) > 1.5:
		_finish_tut(tut["kind"])
		return
	if tut["kind"] == "millet" and bool(tut["gem"]["taken"]):
		_finish_tut("millet")


func _finish_tut(kind: String) -> void:
	if tut.is_empty() or tut["kind"] != kind:
		return
	tut = {}
	if kind == "millet":
		save["tut_millet"] = true
		Save.store(save)


# ---------- финал: улёт попугая, яйцо или перья ----------

const ROLL_L := 2.6
const ROLL_R0 := 0.9
const ROLL_R := 3.7
const ROLL_END := 4.3


func _begin_outro() -> void:
	held_e = null
	menu = {}
	aim = {}
	levelup = {}
	tut = {}
	if not event.is_empty():
		_end_event()
	var player_won: bool = over == "hero_dead"
	var feathers := Meta.feathers_for(player_damage, events_denied, player_won) + int(Diff.level(diff)["feathers"])
	_save_run(feathers)
	if sim:
		return
	outro = {"t": 0.0, "start": hero.pos, "items": [], "opened": false, "reward": [], "done": false, "feathers": feathers}
	if player_won:
		hero.hp = 1.0
		outro["items"].append({"kind": "egg", "pos": hero.pos, "vel": Vector2(0, -60), "landed": false, "got": false})
		hero.say("Аааа! Улетаю!")
	else:
		for i in feathers:
			outro["items"].append({"kind": "feather", "pos": hero.pos + Vector2(randf_range(-40, 40), 0), "vel": Vector2(randf_range(-40, 40), -40), "landed": false, "got": false, "sway": randf() * TAU})
		hero.say("Пылесос сломан! Я свободен, улетаю.")

func _update_outro(dt: float) -> void:
	if outro.is_empty():
		return
	outro["t"] = float(outro["t"]) + dt
	if bool(outro["done"]):
		meta_t += dt
	var t: float = outro["t"]
	_update_fx(dt)
	if outro.has("roll"):
		_update_roll(dt)
	var won: bool = over == "hero_dead"
	# попугай улетает: при поражении — в панике прямо вверх, при победе — гордо вбок и вверх
	var v := Vector2(0, -60.0 - 900.0 * t) if won else Vector2(260.0 + 200.0 * t, -220.0 - 300.0 * t)
	hero.pos += v * dt
	hero.heading = v.normalized()
	hero.bob += dt * 30.0
	if won and int(t * 10.0) % 2 == 0:
		add_fx({"kind": "poof", "pos": hero.pos + Vector2(randf_range(-10, 10), 10), "dur": 0.6, "col": Color("7cc46a"), "r": 6.0})
	var floor_y := float(outro["start"].y) + 20.0
	for it in outro["items"]:
		if it["landed"] or it["got"]:
			continue
		var iv: Vector2 = it["vel"]
		if it["kind"] == "feather":
			it["sway"] = float(it["sway"]) + dt * 3.0
			iv = Vector2(sin(float(it["sway"])) * 60.0, 70.0)
		else:
			iv.y += 900.0 * dt
		it["vel"] = iv
		var np: Vector2 = Vector2(it["pos"]) + iv * dt
		if np.y >= floor_y:
			np.y = floor_y
			it["landed"] = true
			sfx("bounce", -6.0, 0.8 if it["kind"] == "egg" else 1.6)
		it["pos"] = np
	_apply_time_scale()


## Рулетка: лента замедляется, на каждом проезде награды — щелчок, на остановке — вспышка цвета редкости.
func roll_pos(side: int, t: float) -> float:
	var t0 := 0.0 if side == 0 else ROLL_R0
	var dur := ROLL_L if side == 0 else ROLL_R - ROLL_R0
	var k := clampf((t - t0) / dur, 0.0, 1.0)
	return float(Rewards.STOP) * (1.0 - pow(1.0 - k, 4.0))


func _update_roll(dt: float) -> void:
	var ro: Dictionary = outro["roll"]
	ro["t"] = float(ro["t"]) + dt
	var t: float = ro["t"]
	for side in 2:
		var pos := int(floor(roll_pos(side, t) + 0.5))
		if pos != int(ro["tick"][side]):
			ro["tick"][side] = pos
			sfx("tick", -10.0, 1.0 + 0.04 * pos)
		var stop_t := ROLL_L if side == 0 else ROLL_R
		if t >= stop_t and not bool(ro["stopped"][side]):
			ro["stopped"][side] = true
			var rw: Dictionary = ro["left"] if side == 0 else ro["right"]
			var r := int(rw["rarity"])
			sfx("level", -2.0, 0.9 + 0.15 * r)
			if r >= 2:
				sfx("win", -4.0, 1.0 + 0.1 * r)
			shake = 3.0 + 3.0 * r


func _outro_click(p: Vector2) -> void:
	if outro.has("roll"):
		var ro: Dictionary = outro["roll"]
		if float(ro["t"]) < ROLL_END:
			ro["t"] = ROLL_END
			ro["stopped"] = [true, true]
			return
		outro.erase("roll")
		Save.store(save)
		meta_t = 0.0
		outro["done"] = true
		return
	for it in outro["items"]:
		if it["got"] or Vector2(it["pos"]).distance_to(p) > 34.0:
			continue
		it["got"] = true
		if it["kind"] == "egg":
			# яйцо — рулетка: слева награда игроку, справа попугаю, цвет — редкость
			save["feathers"] = int(save.get("feathers", 0)) + int(outro["feathers"])
			var a := Rewards.roll_player(save)
			var b := Rewards.roll_parrot(meta)
			Rewards.apply_player(save, a)
			Rewards.apply_parrot(meta, b)
			outro["roll"] = {"t": 0.0, "left": a, "right": b, "lreel": Rewards.reel(a, "player"), "rreel": Rewards.reel(b, "parrot"), "tick": [0, 0], "stopped": [false, false]}
			var rw: Array = save.get("rewards", [])
			rw.append({"hero": b["label"], "player": a["label"]})
			save["rewards"] = rw.slice(maxi(0, rw.size() - 30))
			save["meta"] = meta
			add_fx({"kind": "confetti", "pos": it["pos"], "dur": 1.4})
			sfx("egg")
		else:
			save["feathers"] = int(save.get("feathers", 0)) + 1
			add_fx({"kind": "sparkle", "pos": it["pos"], "dur": 0.5})
			sfx("pickup", -4.0, 0.8)
		Save.store(save)
	if outro.has("roll"):
		return
	if not outro.is_empty() and not bool(outro["done"]):
		var left := 0
		for it in outro["items"]:
			if not it["got"]:
				left += 1
		if left == 0:
			meta_t = 0.0
	var all := true
	for it in outro["items"]:
		if not it["got"]:
			all = false
	outro["done"] = all


## Итоги забега: память попугая учится на том, что его било и чем он бил.
## Итоги забега: память попугая, его прокачка за просо, квесты, достижения, перья игрока.
func _save_run(feathers: int) -> void:
	if sim and not learn:
		return
	save["runs"] = int(save.get("runs", 0)) + 1
	var mem: Dictionary = save.get("memory", {"runs": 0, "taken": {}, "dealt": {}, "deaths": {}})
	mem["runs"] = int(mem.get("runs", 0)) + 1
	mem["taken"] = Save.blend(mem.get("taken", {}), Save.shares(dmg_by_src))
	# эффективность умений: доля урона на уровень умения
	var eff := {}
	for k in dealt_by_src:
		var lv := maxi(1, hero.lvl_of(k)) if k != "peck" else 1
		eff[k] = float(dealt_by_src[k]) / float(lv)
	mem["dealt"] = Save.blend(mem.get("dealt", {}), Save.shares(eff))
	# сколько раз брал каждое умение и чем кончилось — чтобы не зациклиться на одном
	var picks: Dictionary = mem.get("picks", {})
	var wins: Dictionary = mem.get("wins", {})
	for k in hero.skills:
		picks[k] = int(picks.get(k, 0)) + 1
		if boss_defeated:
			wins[k] = int(wins.get(k, 0)) + 1
	mem["picks"] = picks
	mem["wins"] = wins
	var plans: Array = mem.get("plans", [])
	if hero.plan.size() > 0:
		plans.append(hero.plan[0])
	mem["plans"] = plans.slice(maxi(0, plans.size() - 8))
	if over == "hero_dead":
		var top := ""
		var tv := 0.0
		for k in dmg_by_src:
			if float(dmg_by_src[k]) > tv:
				tv = float(dmg_by_src[k])
				top = k
		var deaths: Dictionary = mem.get("deaths", {})
		deaths[top] = int(deaths.get(top, 0)) + 1
		mem["deaths"] = deaths
	save["memory"] = mem
	# итоги для квестов и достижений
	var r := {
		"boss": boss_defeated, "time": time, "hp_frac": hero.hp_frac(), "chests": hero.chests_opened,
		"events": hero.events_done, "events_total": events_total, "kills": kills, "millet": run_millet,
		"throw_dmg": float(dmg_by_src.get("throw", 0)), "fruits": fruits_eaten, "level": hero.level, "rams": rams,
	}
	# счётчики игрока для условий штаба
	var ps: Dictionary = meta.get("pstats", {})
	for k in run_pstats:
		ps[k] = float(ps.get(k, 0.0)) + float(run_pstats[k])
	ps["rams_run"] = maxf(float(ps.get("rams_run", 0.0)), float(run_pstats.get("rams", 0.0)))
	if over == "hero_dead":
		ps["wins"] = float(ps.get("wins", 0.0)) + 1.0
	meta["pstats"] = ps
	var st: Dictionary = meta["stats"]
	st["dodges"] = int(st.get("dodges", 0)) + hero_dodges
	st["kills"] = int(st.get("kills", 0)) + kills
	st["boss_kills"] = int(st.get("boss_kills", 0)) + (1 if boss_defeated else 0)
	st["events"] = int(st.get("events", 0)) + hero.events_done
	st["chests"] = int(st.get("chests", 0)) + hero.chests_opened
	st["millet"] = int(st.get("millet", 0)) + run_millet
	var last := {"won": boss_defeated, "millet": run_millet, "quest_results": [], "bought": [], "offer": [], "picked": [], "feathers": feathers}
	var bank := int(float(run_millet) * float(Diff.level(diff)["millet"]))
	for q in hero.quests:
		var ok := Meta.quest_done(q, r)
		last["quest_results"].append([q, ok])
		if ok:
			bank += int(Meta.quest_by_key(q)["reward"])
	meta["parrot"]["bank"] = int(meta["parrot"]["bank"]) + bank
	last["ach_new"] = Meta.claim_achievements(meta)
	last["diff"] = diff
	last["diff_msg"] = Diff.record(meta, diff, boss_defeated, time)
	last["bird"] = hero.bird
	Parrots.record(meta, hero.bird, boss_defeated, time, kills, hero_dodges, hero.skill_hits)
	Diff.choose(meta, hero.greed0)
	Parrots.choose(meta)
	last["bought"] = Meta.parrot_shop(meta, mem)
	# квесты появляются только с третьего забега, чтобы не вываливать всё сразу
	if int(save["runs"]) >= 2:
		var pool: Array = []
		for q in Meta.QUESTS:
			pool.append(q["key"])
		pool.shuffle()
		last["offer"] = pool.slice(0, 6)
		last["picked"] = Meta.choose_quests(last["offer"], hero.greed0, mem)
	meta["quests"] = last["picked"]
	meta["last"] = last
	if sim:
		# в прогоне прогрессии игрок получает перья сразу и покупает самое дешёвое доступное
		save["feathers"] = int(save.get("feathers", 0)) + feathers
		var again := true
		while again:
			again = false
			for it in Meta.PLAYER:
				if not Meta.unlocked(meta, it["key"]) and Meta.tier_open(meta, int(it["tier"])) and int(save["feathers"]) >= int(it["cost"]):
					save["feathers"] = int(save["feathers"]) - int(it["cost"])
					meta["unlocked"][it["key"]] = true
					again = true
					break
		if Trees.hq_open(meta):
			Trees.bot_buy(meta, save, ["throw", "book", "ram", "basket", "millet"])
	save["meta"] = meta
	Save.store(save)


## Действия на экране меты: исследования, узлы штаба, усиление, волны.
func _meta_action(act: String) -> void:
	if act == "":
		return
	var parts := act.split(":")
	match parts[0]:
		"new":
			start_run()
		"buy":
			buy_unlock(parts[1])
		"tab":
			hud.hq_tab = parts[1]
			sfx("tick", -6.0, 1.1)
		"abil":
			hud.hq_abil = parts[1]
			sfx("tick", -6.0, 1.2)
		"enh":
			Trees.toggle_enh(meta, parts[1])
			Save.store(save)
			sfx("tick", 0.0, 1.4)
		"node":
			buy_node(parts[1], int(parts[2]), int(parts[3]))
		"slot":
			_cycle_slot(int(parts[1]), 1 if parts[2] == "next" else -1)
		"pack":
			buy_pack(parts[1])
		"chest":
			hud.chest_open = not hud.chest_open
			sfx("tick", -4.0, 0.9)
		"skin":
			if save.get("cursors", ["white"]).has(parts[1]):
				save["cursor"] = parts[1]
				Save.store(save)
				cursor_imgs = {}
				_build_cursors()
				sfx("tick", 0.0, 1.3)
		"curse":
			var armed: Array = save.get("armed", [])
			if armed.has(parts[1]):
				armed.erase(parts[1])
			elif int(save.get("curses", {}).get(parts[1], 0)) > 0 and armed.size() < Rewards.MAX_ARMED:
				armed.append(parts[1])
			save["armed"] = armed
			Save.store(save)
			sfx("tick", 0.0, 1.1)


func buy_node(ab: String, bi: int, ni: int) -> bool:
	var f := int(save.get("feathers", 0))
	if Trees.why_not(meta, f, ab, bi, ni) != "":
		sfx("fail", -8.0, 1.4)
		return false
	var id := Trees.node_id(ab, bi, ni)
	var cur := Trees.lvl(meta, id)
	save["feathers"] = f - Trees.cost(ni, cur)
	Trees.hq(meta)["nodes"][id] = cur + 1
	# первое дерево сразу становится усиленным, чтобы купленное работало
	var h := Trees.hq(meta)
	if h["enh"].size() < Trees.enh_slots(meta) and not h["enh"].has(ab):
		h["enh"].append(ab)
	save["meta"] = meta
	Save.store(save)
	sfx("level", -4.0)
	return true


func buy_pack(key: String) -> bool:
	var pk_info := Trees.pack(key)
	if Trees.pack_owned(meta, key):
		return false
	var f := int(save.get("feathers", 0))
	if Trees.cond_progress(meta, pk_info["cond"]) < 1.0 or f < int(pk_info["cost"]):
		sfx("fail", -8.0, 1.4)
		return false
	save["feathers"] = f - int(pk_info["cost"])
	Trees.hq(meta)["packs"][key] = true
	Save.store(save)
	sfx("level", -4.0)
	return true


func _cycle_slot(i: int, dir: int) -> void:
	var h := Trees.hq(meta)
	var owned: Array = []
	for pkk in Trees.PACKS:
		if Trees.pack_owned(meta, pkk["key"]):
			owned.append(pkk["key"])
	var cur: int = owned.find(h["waves"][i])
	h["waves"][i] = owned[posmod(cur + dir, owned.size())]
	Save.store(save)
	sfx("tick", -4.0, 1.0 + 0.05 * i)


## Покупка исследования игрока за перья (экран после забега).
func buy_unlock(key: String) -> bool:
	for it in Meta.PLAYER:
		if it["key"] != key or Meta.unlocked(meta, key) or not Meta.tier_open(meta, int(it["tier"])):
			continue
		if int(save.get("feathers", 0)) < int(it["cost"]):
			sfx("fail", -8.0, 1.4)
			return false
		save["feathers"] = int(save["feathers"]) - int(it["cost"])
		meta["unlocked"][key] = true
		save["meta"] = meta
		Save.store(save)
		sfx("level", -4.0)
		return true
	return false



# ---------- комната: каждый забег немного другая ----------

const FURN_TEMPLATES := [
	["sofa", Vector2(300, 110), 34.0, "wall"], ["shelf", Vector2(90, 300), 60.0, "side"], ["table", Vector2(180, 110), 26.0, "free"],
	["armchair", Vector2(150, 140), 38.0, "any"], ["plant", Vector2(70, 70), 50.0, "any"], ["stool", Vector2(64, 64), 30.0, "free"],
	["boxes", Vector2(120, 100), 50.0, "any"], ["lamp", Vector2(54, 54), 80.0, "free"], ["books", Vector2(80, 60), 26.0, "any"],
	["toys", Vector2(110, 90), 32.0, "any"], ["nightstand", Vector2(108, 120), 40.0, "wall"], ["catbed", Vector2(160, 110), 20.0, "wall"],
	["chair", Vector2(90, 90), 44.0, "free"],
]
## Минимальный проход между мебелью и до стен: шире, чем нужно, чтобы толпа не застревала
## и у попугая не было узких «коридоров», где он косит орду.
const ROOM_GAP := 150.0


func _generate_room() -> void:
	furniture = []
	obstacles.clear()
	var f := floor_rect
	var center := f.get_center()
	var temps: Array = FURN_TEMPLATES.duplicate()
	temps.shuffle()
	var want := randi_range(9, 12)
	# полка с книгами всегда есть: оттуда падают книги
	temps.sort_custom(func(a, b): return a[0] == "shelf" and b[0] != "shelf")
	for t in temps:
		if furniture.size() >= want:
			break
		var size: Vector2 = t[1]
		var place: String = t[3]
		for attempt in 40:
			var r := Rect2()
			var side := randi() % 4
			if place == "side":
				side = 2 + randi() % 2
			if place == "free" or (place == "any" and randf() < 0.5):
				r = Rect2(Vector2(randf_range(f.position.x + ROOM_GAP, f.end.x - ROOM_GAP - size.x), randf_range(f.position.y + ROOM_GAP, f.end.y - ROOM_GAP - size.y)), size)
			else:
				var sz := size if side < 2 else Vector2(size.y, size.x) if place != "side" else size
				match side:
					0:
						r = Rect2(Vector2(randf_range(f.position.x, f.end.x - sz.x), f.position.y), sz)
					1:
						r = Rect2(Vector2(randf_range(f.position.x, f.end.x - sz.x), f.end.y - sz.y), sz)
					2:
						r = Rect2(Vector2(f.position.x, randf_range(f.position.y, f.end.y - sz.y)), sz)
					_:
						r = Rect2(Vector2(f.end.x - sz.x, randf_range(f.position.y, f.end.y - sz.y)), sz)
			if _room_ok(r, center):
				furniture.append([r, t[0], t[2]])
				obstacles.append(r)
				break
	rug_pos = center + Vector2(randf_range(-160, 160), randf_range(-120, 120))


var rug_pos := Vector2(880, 660)


## Мебель не ставим впритык: до другой мебели и до стены — либо вплотную к стене, либо широкий проход.
func _room_ok(r: Rect2, center: Vector2) -> bool:
	var f := floor_rect
	if not f.encloses(r):
		return false
	if r.grow(140.0).has_point(center):
		return false
	for o in obstacles:
		if _rect_gap(r, o) < ROOM_GAP:
			return false
	var gaps := [r.position.x - f.position.x, f.end.x - r.end.x, r.position.y - f.position.y, f.end.y - r.end.y]
	for g in gaps:
		if g > 0.5 and g < ROOM_GAP:
			return false
	return true


static func _rect_gap(a: Rect2, b: Rect2) -> float:
	var dx := maxf(0.0, maxf(a.position.x - b.end.x, b.position.x - a.end.x))
	var dy := maxf(0.0, maxf(a.position.y - b.end.y, b.position.y - a.end.y))
	return sqrt(dx * dx + dy * dy)


## Для тестов: какие квесты были бы выполнены в этом забеге.
func _all_quests() -> Dictionary:
	var r := {
		"boss": boss_defeated, "time": time, "hp_frac": hero.hp_frac(), "chests": hero.chests_opened,
		"events": hero.events_done, "events_total": events_total, "kills": kills, "millet": run_millet,
		"throw_dmg": float(dmg_by_src.get("throw", 0)), "fruits": fruits_eaten, "level": hero.level, "rams": rams,
	}
	var out := {}
	for q in Meta.QUESTS:
		out[q["key"]] = Meta.quest_done(q["key"], r)
	return out
