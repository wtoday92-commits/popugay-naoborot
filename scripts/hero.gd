class_name Hero
extends RefCounted
## ИИ попугая по ГДД, часть 2: три слота внимания, поля опасности и интереса,
## режимы с инерцией (2 раза в секунду), контекстное руление по 16 лучам (30 раз в секунду),
## жадность, страх, выбор перков с ответом на действия игрока.

enum Mode { FARM, GOAL, HUNT, RETREAT, PANIC }
const MODE_NAMES := ["фарм", "к цели", "охота", "отход", "ПАНИКА"]
const M := 40.0
const NDIR := 16
const SLOTS := 3
const VIEW := 12.0 * M

# Характер первого героя: «упрямый коллекционер».
var greed0 := 0.55
var stubborn := 0.7
var caution := 0.4
var curiosity := 0.5
var perfection := 0.6
var plan: Array[String] = ["bell", "fluff"]

var game
var pos := Vector2.ZERO
var heading := Vector2.RIGHT
var desired := Vector2.RIGHT
var vel := Vector2.ZERO
var knock_vel := Vector2.ZERO
var dodge_vel := Vector2.ZERO
var dodge_t := 0.0
var radius := 18.0
var hp := 100.0
var level := 1
var xp := 0
var xp_next := 6
var stress := 0.0
var greed := 0.55
var mode: int = Mode.FARM
var mode_time := 0.0
var target = null
var target_kind := ""
var target_u := 0.0
var target_d0 := 1.0
var focus: Array = []
var focus_ids: Array[int] = []
var near: Array[Enemy] = []
var nearest_d := 99999.0
var choosing := false
var stun := 0.0
var held := 0.0
var ram_immune := 0.0
var hurt := 0.0
var opening := 0.0
var opening_chest = null
var instant := false
var dodging := false
var think_t := 0.0
var attn_t := 0.0
var steer_t := 0.0
var think_now := false
var spike_cd := 0.0
var panic_exit_t := -10.0
var waltz_dir := 1.0
var waltz_t := 30.0
var wander := Vector2.ZERO
var wander_t := 0.0
var stuck_t := 0.0
var stuck_ref := Vector2.ZERO
var unstick_t := 0.0
var unstick_dir := Vector2.ZERO
var weapons := {"peck": 1}
var passives := {}
var cds := {}
var dmg_log: Array = []
var wariness := {"paw": 0.0, "meteor": 0.0}
var closedness := 0.0
var danger_here := 0.0
var horde_center := Vector2.ZERO
var horde_count := 0
var horde_obj := {"id": -1, "pos": Vector2.ZERO, "born": -10.0}
var chests_opened := 0
var bob := 0.0
var dirs: Array[Vector2] = []
var dbg_D := PackedFloat32Array()
var dbg_I := PackedFloat32Array()
var dbg_thr := 0.8


func _init(g) -> void:
	game = g
	for i in NDIR:
		dirs.append(Vector2.RIGHT.rotated(TAU * float(i) / float(NDIR)))
	dbg_D.resize(NDIR)
	dbg_I.resize(NDIR)
	horde_obj["id"] = g.new_id()
	hp = max_hp()


# ---------- характеристики ----------

func lvl_of(k: String) -> int:
	if weapons.has(k):
		return int(weapons[k])
	return int(passives.get(k, 0))


func max_hp() -> float:
	return 100.0 + 20.0 * lvl_of("fluff")


func speed() -> float:
	return 3.2 * M * (1.0 + 0.12 * lvl_of("wings"))


func dmg_mult() -> float:
	return 1.0 + 0.12 * lvl_of("beak")


func armor() -> float:
	return float(lvl_of("shell"))


func magnet() -> float:
	return 1.6 * M * (1.0 + 0.35 * lvl_of("magnet"))


func hp_frac() -> float:
	return hp / max_hp()


func power() -> float:
	var s := 0.0
	for k in weapons:
		s += float(weapons[k])
	for k in passives:
		s += float(passives[k]) * 0.5
	return 1.0 + s * 0.5


## Желаемое расстояние до фронта орды: билд видно по тому, как герой двигается.
func weapon_range() -> float:
	if weapons.has("feather") or weapons.has("mirror"):
		return 4.5 * M
	if weapons.has("bell"):
		return 1.5 * M
	return 2.0 * M


static func opos(o) -> Vector2:
	if o is Enemy:
		return o.pos
	return o["pos"]


static func oid(o) -> int:
	if o is Enemy:
		return o.id
	return int(o["id"])


static func oborn(o) -> float:
	if o is Enemy:
		return o.born
	return float(o["born"])


func valid(o) -> bool:
	if o == null:
		return false
	if o is Enemy:
		return not o.dead
	return not bool(o.get("taken", false))


func say(s: String) -> void:
	game.add_thought(s)


# ---------- главный шаг ----------

func update(delta: float) -> void:
	var t: float = game.time
	stun = maxf(0.0, stun - delta)
	held = maxf(0.0, held - delta)
	ram_immune = maxf(0.0, ram_immune - delta)
	hurt = maxf(0.0, hurt - delta)
	hp = minf(max_hp(), hp + 0.3 * delta)
	spike_cd = maxf(0.0, spike_cd - delta)
	for k in wariness:
		wariness[k] = maxf(0.0, float(wariness[k]) - 0.01 * delta)
	waltz_t -= delta
	if waltz_t <= 0.0:
		waltz_t = randf_range(20.0, 40.0)
		waltz_dir = -waltz_dir
		if mode == Mode.FARM:
			say("Меняю направление обхода.")
	_scan_near()
	attn_t -= delta
	if attn_t <= 0.0:
		attn_t = 0.1
		_attention()
	_notice_meteors()
	_update_stress(delta)
	_update_greed()
	mode_time += delta
	think_t -= delta
	if think_t <= 0.0 or think_now:
		think_t = 0.5
		think_now = false
		_think()
	steer_t -= delta
	if steer_t <= 0.0:
		steer_t = 1.0 / 30.0
		_steer()
	_move(delta)
	_weapons(delta)
	_pickups(delta)
	while dmg_log.size() > 0 and float(dmg_log[0][0]) < t - 120.0:
		dmg_log.pop_front()


func _scan_near() -> void:
	near.clear()
	var sum := Vector2.ZERO
	var n := 0
	nearest_d = 99999.0
	var near_r2 := 10.0 * M * 10.0 * M
	var horde_r2 := 8.0 * M * 8.0 * M
	for e in game.enemies:
		if e.dead:
			continue
		var d2 := pos.distance_squared_to(e.pos)
		if d2 < near_r2:
			near.append(e)
		if d2 < horde_r2 and e.type != Enemy.T.HAND:
			sum += e.pos
			n += 1
			nearest_d = minf(nearest_d, sqrt(d2))
	horde_count = n
	if n > 0:
		horde_center = sum / float(n)
		horde_obj["pos"] = horde_center


# ---------- восприятие и внимание ----------

func view_radius() -> float:
	return VIEW * (0.7 if stress > 0.7 else 1.0)


func _attention() -> void:
	if choosing:
		return # во время выбора перка все слоты заморожены
	var t: float = game.time
	var view := view_radius()
	var cands: Array = []
	for m in game.meteors:
		if not m["landed"]:
			_cand(cands, m, 0.2, view, t)
	if game.paw_seen():
		_cand(cands, game.paw, 2.0 + 2.0 * float(wariness["paw"]), view, t)
	for e in near:
		if e.type == Enemy.T.HAND:
			_cand(cands, e, 1.4 + (2.0 if e.grab_state == 1 else 0.0), view, t)
	for c in game.chests:
		_cand(cands, c, 1.2, view, t)
	for a in game.apples:
		_cand(cands, a, 0.3 + 1.5 * (1.0 - hp_frac()), view, t)
	for g in game.gems:
		if g["big"]:
			_cand(cands, g, 0.6, view, t)
	for s in game.enemy_shots:
		_cand(cands, s, 0.9, view, t)
	if horde_count > 0:
		_cand(cands, horde_obj, 1.0 + minf(float(horde_count), 30.0) * 0.03, view, t)
	cands.sort_custom(func(a, b): return a["s"] > b["s"])
	var nf: Array = []
	var ids: Array[int] = []
	# Туннель жадности: вцепившийся герой прибивает один слот к цели.
	if (mode == Mode.GOAL or mode == Mode.HUNT) and greed > 0.6 and valid(target):
		nf.append(target)
		ids.append(oid(target))
	for c in cands:
		if nf.size() >= SLOTS:
			break
		var cid: int = c["id"]
		if ids.has(cid):
			continue
		nf.append(c["o"])
		ids.append(cid)
	focus = nf
	focus_ids = ids
	for m in game.meteors:
		if ids.has(int(m["id"])) and float(m["focus_t"]) < 0.0:
			m["focus_t"] = t


func _cand(cands: Array, o, base: float, view: float, t: float) -> void:
	var p := opos(o)
	var d := pos.distance_to(p)
	if d > view:
		return
	var age := t - oborn(o)
	var nov := 1.0 if age < 1.0 else maxf(0.0, 1.0 - (age - 1.0) / 2.0)
	var s := base + nov + (1.0 - d / view)
	var id := oid(o)
	if focus_ids.has(id):
		s += 0.8 # липкость фокуса
	cands.append({"o": o, "id": id, "s": s})


## Тень книги: в фокусе замечается за 0,25 с, вне фокуса — за 0,7 с.
func _notice_meteors() -> void:
	var t: float = game.time
	for m in game.meteors:
		if m["landed"] or float(m["notice_t"]) >= 0.0:
			continue
		var p: Vector2 = m["pos"]
		var ft: float = m["focus_t"]
		var ok := false
		if ft >= 0.0 and t >= ft + 0.3:
			ok = true
		elif t >= float(m["born"]) + 0.7 and pos.distance_to(p) < view_radius():
			ok = true
		if ok:
			m["notice_t"] = t
			if pos.distance_to(p) < float(m["r"]) + 1.5 * M:
				say("Книга сверху! Уворачиваюсь.")
				steer_t = 0.0


# ---------- поля опасности ----------

func danger_at(p: Vector2, with_meteors: bool = true) -> float:
	if game.is_blocked(p):
		return 2.0
	var d := 0.0
	var hpk := 6.0 / maxf(hp, 10.0)
	for e in near:
		var c := e.pos
		var re := 2.5 * M
		var w := clampf(e.dmg * hpk, 0.08, 1.0)
		match e.type:
			Enemy.T.BALL:
				re = 4.0 * M
				c += e.move_dir * 1.5 * M
			Enemy.T.SLIPPER:
				re = 3.0 * M
			Enemy.T.SPRAYER:
				re = 2.0 * M
			Enemy.T.HAND:
				if e.grab_state == 1:
					re = 2.5 * M
					w = 1.2
				else:
					re = 5.0 * M
					w *= 0.6
		var dist := p.distance_to(c)
		if dist < re:
			d += w * (1.0 - dist / re)
	for m in game.meteors:
		if with_meteors and not m["landed"] and float(m["notice_t"]) >= 0.0:
			if p.distance_to(m["pos"]) < float(m["r"]) + 1.0 * M:
				d += 2.0
	for s in game.enemy_shots:
		var sp: Vector2 = s["pos"]
		if focus_ids.has(int(s["id"])) or pos.distance_to(sp) < 3.0 * M:
			for k in 3:
				var q: Vector2 = sp + s["vel"] * (0.5 * k)
				var dq := p.distance_to(q)
				if dq < 1.5 * M:
					d += 0.7 * (1.0 - dq / (1.5 * M))
					break
	if game.paw_threat:
		var pp: Vector2 = game.paw["pos"]
		var q: Vector2 = pp + game.paw_vel.normalized() * M
		var dq := p.distance_to(q)
		if dq < 2.0 * M:
			d += 0.9 * (1.0 - dq / (2.0 * M))
	return d


func _update_stress(delta: float) -> void:
	var t: float = game.time
	var recent := 0.0
	for i in range(dmg_log.size() - 1, -1, -1):
		var r: Array = dmg_log[i]
		if float(r[0]) < t - 1.0:
			break
		recent += float(r[2])
	var ts := 0.35 * minf(danger_here, 1.5) + 0.6 * closedness + 0.3 * pow(1.0 - hp_frac(), 1.5) + 3.0 * recent / max_hp()
	if dodging:
		ts += 0.2
	ts = clampf(ts, 0.0, 1.0)
	# страх растёт быстро и спадает медленно: «инерция страха»
	var tau := 0.3 if ts > stress else 3.0
	stress += (ts - stress) * (1.0 - exp(-delta / tau))
	if recent > 0.1 * max_hp() and spike_cd <= 0.0:
		spike_cd = 0.5
		think_now = true


func _sunk_cost() -> float:
	if (mode == Mode.GOAL or mode == Mode.HUNT) and valid(target):
		return clampf(1.0 - pos.distance_to(opos(target)) / maxf(target_d0, 1.0), 0.0, 1.0)
	return 0.0


func _update_greed() -> void:
	var q := 0.0
	if (target_kind == "chest" or target_kind == "hand") and chests_opened < 3:
		q = 1.0
	var lc: float = game.last_chance()
	greed = clampf(greed0 + 0.2 * q + 0.35 * _sunk_cost() * stubborn + 0.4 * lc - 0.45 * stress - 0.25 * (1.0 - hp_frac()), 0.0, 1.0)


# ---------- точки интереса и намерение ----------

func _path_risk(p: Vector2) -> float:
	var s := 0.0
	for i in range(1, 9):
		s += minf(danger_at(pos.lerp(p, float(i) / 8.0)), 1.0)
	s += minf(danger_at(p), 1.0)
	return clampf(s / 9.0, 0.0, 1.0)


func _utility(p: Vector2, v: float, n: float, q: float, e_exp: float) -> Array:
	var r := _path_risk(p)
	var d := pos.distance_to(p)
	var u := v * n * q * pow(maxf(0.0, 1.0 - r), e_exp) / (1.0 + d / (12.0 * M))
	return [u, r]


func _best_poi() -> Dictionary:
	var best := {}
	var bu := 0.0
	var view := view_radius()
	# осторожный возводит риск в степень 2,3, жадный — в 0,3
	var e_exp := lerpf(2.3, 0.3, greed)
	var q_goal := 1.0
	if chests_opened < 3:
		q_goal = 1.0 + 0.5 * perfection / 0.6
		if game.last_chance() > 0.0:
			q_goal = 2.5
	for c in game.chests:
		var r := _utility(c["pos"], 25.0, 1.0, q_goal, e_exp)
		if r[0] > bu:
			bu = r[0]
			best = {"o": c, "kind": "chest", "u": r[0], "risk": r[1]}
	for e in near:
		if e.type == Enemy.T.HAND and e.carries_chest:
			var n := clampf(power() / maxf(e.hp / 40.0, 0.5), 0.0, 2.0)
			var r := _utility(e.pos, 18.0, n, q_goal, e_exp)
			if r[0] > bu:
				bu = r[0]
				best = {"o": e, "kind": "hand", "u": r[0], "risk": r[1]}
	var hpf := hp_frac()
	if hpf < 0.95:
		for a in game.apples:
			if pos.distance_to(a["pos"]) < view:
				var r := _utility(a["pos"], 30.0, pow(1.0 - hpf, 2.0), 1.0, e_exp)
				if r[0] > bu:
					bu = r[0]
					best = {"o": a, "kind": "apple", "u": r[0], "risk": r[1]}
	var prog := float(xp) / float(xp_next)
	var checked := 0
	for g in game.gems:
		if g["big"] and checked < 8 and pos.distance_to(g["pos"]) < view:
			checked += 1
			var r := _utility(g["pos"], 8.0, 1.0 + 2.0 * prog * prog, 1.0, e_exp)
			if r[0] > bu:
				bu = r[0]
				best = {"o": g, "kind": "gem", "u": r[0], "risk": r[1]}
	return best


static func risk_word(r: float) -> String:
	if r < 0.25:
		return "низкий"
	if r < 0.55:
		return "средний"
	return "высокий"


func _set_mode(m: int, msg: String = "") -> void:
	if m == mode:
		return
	mode = m
	mode_time = 0.0
	if msg != "":
		say(msg)


func _think() -> void:
	if not valid(target):
		target = null
		target_kind = ""
	var open_dirs := NDIR - int(round(closedness * NDIR))
	if mode == Mode.PANIC:
		if open_dirs >= 8 and stress < 0.6 and mode_time > 1.0:
			_set_mode(Mode.FARM, "Вырвался. Дышу.")
			panic_exit_t = game.time
		else:
			return
	if game.time - panic_exit_t < 2.0:
		pass # сразу после выхода из паники не впадает в неё снова
	elif stress > 0.85 or closedness > 0.7:
		target = null
		target_kind = ""
		_set_mode(Mode.PANIC, "Окружили! Ищу щель!")
		return
	var hpf := hp_frac()
	var flee_thr := lerpf(0.35, 0.15, greed)
	var poi := _best_poi()
	var u := [0.0, 0.0, 0.0, 0.0, 0.0]
	u[Mode.FARM] = 0.45 if stress < 0.4 else 0.3
	if not poi.is_empty() and float(poi["u"]) > 6.0:
		var uu := clampf(float(poi["u"]) / 20.0, 0.4, 1.0)
		if poi["kind"] == "hand":
			u[Mode.HUNT] = uu
		else:
			u[Mode.GOAL] = uu
	var must_flee := stress > 0.6 or hpf < flee_thr
	u[Mode.RETREAT] = 0.95 if must_flee else 0.0
	if mode != Mode.PANIC:
		u[mode] += 0.1 + 0.15 * stubborn + 0.4 * stubborn * _sunk_cost()
	var best := 0
	for i in 5:
		if u[i] > u[best]:
			best = i
	# минимальное время в режиме — 1,5 с (бегство его перебивает)
	if mode_time < 1.5 and best != mode and not (best == Mode.RETREAT and must_flee):
		best = mode
	if best == Mode.GOAL or best == Mode.HUNT:
		if poi.is_empty():
			best = Mode.FARM
		else:
			var new_t = poi["o"]
			var switching := not valid(target) or oid(new_t) != oid(target)
			if switching and valid(target) and best == mode and float(poi["u"]) < target_u * 1.3:
				switching = false
			if switching:
				target = new_t
				target_kind = poi["kind"]
				target_d0 = maxf(pos.distance_to(opos(new_t)), 1.0)
				_say_target(poi)
			if switching or oid(new_t) == oid(target):
				target_u = float(poi["u"])
	elif best != mode:
		target = null
		target_kind = ""
	var names := ["Кружу орду, собираю просо.", "", "", "Слишком горячо. Отхожу.", ""]
	if best == Mode.RETREAT and hpf < flee_thr:
		names[Mode.RETREAT] = "Здоровье %d%%. Ухожу и ищу яблоко." % int(hpf * 100.0)
	_set_mode(best, names[best])


func _say_target(poi: Dictionary) -> void:
	var p := opos(poi["o"])
	var dm := int(round(pos.distance_to(p) / M))
	var rw := risk_word(float(poi["risk"]))
	match poi["kind"]:
		"chest":
			say("Кормушка в %d м. Риск %s. Иду." % [dm, rw])
		"hand":
			say("Рука несёт кормушку! Охочусь.")
		"apple":
			say("Долька яблока в %d м. Риск %s." % [dm, rw])
		"gem":
			say("Колосок проса в %d м. Беру." % dm)


# ---------- движение: контекстное руление ----------

func _steer() -> void:
	var I := PackedFloat32Array()
	I.resize(NDIR)
	I.fill(0.0)
	var D := PackedFloat32Array()
	D.resize(NDIR)
	var closed := 0
	for i in NDIR:
		var dv := dirs[i]
		var a := danger_at(pos + dv * M)
		var b := danger_at(pos + dv * 2.0 * M)
		var c := danger_at(pos + dv * 4.0 * M)
		D[i] = maxf(a, maxf(b * 0.6, c * 0.3))
		# тень книги — временная преграда: она не делает героя «окружённым»
		if danger_at(pos + dv * 4.0 * M, false) > 0.8 or (b > 1.5 and danger_at(pos + dv * 2.0 * M, false) > 1.5):
			closed += 1
	closedness = float(closed) / float(NDIR)
	danger_here = danger_at(pos, false)

	var goals: Array = []
	var tp := Vector2.ZERO
	var has_t := valid(target)
	if has_t:
		tp = opos(target)
	match mode:
		Mode.FARM:
			_farm_goals(goals)
		Mode.GOAL:
			if has_t:
				goals.append([(tp - pos).normalized(), 1.0])
		Mode.HUNT:
			if has_t:
				var to_t := tp - pos
				var dt := to_t.length()
				var want := weapon_range() + 0.5 * M
				var n := to_t / maxf(dt, 1.0)
				var tangent := Vector2(-n.y, n.x) * waltz_dir
				goals.append([(n * clampf((dt - want) / want, -1.0, 1.0) * 1.5 + tangent * 0.5).normalized(), 1.0])
		Mode.RETREAT:
			var away := pos - horde_center if horde_count > 0 else Vector2.ZERO
			if away.length() > 1.0:
				goals.append([away.normalized(), 1.0])
			var best_a = null
			var bd := 99999.0
			for ap in game.apples:
				var d := pos.distance_to(ap["pos"])
				if d < bd:
					bd = d
					best_a = ap
			if best_a != null:
				goals.append([(opos(best_a) - pos).normalized(), 1.2])
			goals.append([(game.floor_rect.get_center() - pos).normalized(), 0.3 * _edge_factor()])
	if mode == Mode.PANIC:
		var gap := _widest_gap(D, 0.8 - 0.4 * stress)
		if gap != Vector2.ZERO:
			goals.append([gap, 1.0])
	if mode != Mode.PANIC:
		var gr := 4.0 * M
		for g in game.gems:
			var gp: Vector2 = g["pos"]
			var d := pos.distance_to(gp)
			if d < gr and d > 1.0:
				goals.append([(gp - pos) / d, 0.2 * float(g["xp"]) / (1.0 + d / M)])
	for gl in goals:
		var gv: Vector2 = gl[0]
		var gw: float = gl[1]
		for i in NDIR:
			I[i] += gw * maxf(0.0, dirs[i].dot(gv))

	var thr := 0.8 - 0.4 * stress
	var lam := (1.0 + 2.0 * stress) * (0.5 + caution)
	dbg_D = D
	dbg_I = I
	dbg_thr = thr
	var sc := PackedFloat32Array()
	sc.resize(NDIR)
	var best_i := -1
	var best_s := -INF
	for i in NDIR:
		sc[i] = I[i] - lam * D[i]
		if D[i] > thr:
			continue
		if sc[i] > best_s:
			best_s = sc[i]
			best_i = i

	# Уворот от замеченной тени игнорирует сглаживание.
	var esc := _meteor_escape()
	instant = false
	if esc != Vector2.ZERO:
		var bi := -1
		var bd := -9.0
		for i in NDIR:
			if D[i] < 1.9:
				var s := dirs[i].dot(esc) - 0.1 * D[i]
				if s > bd:
					bd = s
					bi = i
		desired = dirs[bi] if bi >= 0 else esc
		instant = true
		dodging = true
		return
	dodging = false

	if best_i == -1:
		var mi := 0
		for i in NDIR:
			if D[i] < D[mi]:
				mi = i
		desired = dirs[mi]
		if mode != Mode.PANIC:
			target = null
			target_kind = ""
			_set_mode(Mode.PANIC, "Все пути закрыты! Паника!")
		return

	# держим курс, если новое направление лучше меньше чем на 10%
	var ci := _dir_index(heading)
	if D[ci] <= thr and best_s < sc[ci] + 0.1 * absf(sc[ci]) + 0.02:
		best_i = ci
		best_s = sc[ci]
	var l := (best_i + NDIR - 1) % NDIR
	var r := (best_i + 1) % NDIR
	var off := 0.0
	if D[l] <= thr and D[r] <= thr:
		var den := sc[l] - 2.0 * best_s + sc[r]
		if absf(den) > 0.0001:
			off = clampf(0.5 * (sc[l] - sc[r]) / den, -0.5, 0.5)
	desired = Vector2.RIGHT.rotated(TAU * (float(best_i) + off) / float(NDIR))
	if mode == Mode.PANIC:
		desired = desired.rotated(randf_range(-0.26, 0.26))
	# подбор: последние 2 м до награды идёт по прямой
	if mode == Mode.GOAL and has_t and pos.distance_to(tp) < 2.0 * M:
		desired = (tp - pos).normalized()


func _farm_goals(goals: Array) -> void:
	var center: Vector2 = game.floor_rect.get_center()
	var ef := _edge_factor()
	if ef > 0.0:
		goals.append([(center - pos).normalized(), ef * 0.9])
	if horde_count == 0:
		wander_t -= 1.0 / 30.0
		if wander_t <= 0.0 or pos.distance_to(wander) < 40.0:
			wander_t = 5.0
			wander = game.random_floor_point()
		goals.append([(wander - pos).normalized(), 0.4 + 0.4 * curiosity])
		return
	var to_c := horde_center - pos
	var dc := to_c.length()
	if dc < 1.0:
		return
	var n := to_c / dc
	# «Вальс»: широкий круг вокруг толпы
	var tangent := Vector2(-n.y, n.x) * waltz_dir
	var want := weapon_range()
	var radial := clampf((nearest_d - want) / want, -1.0, 1.0)
	goals.append([(tangent + n * radial * 1.3).normalized(), 1.0])


## Середина самой широкой цепочки открытых направлений: паника ищет щель.
func _widest_gap(D: PackedFloat32Array, thr: float) -> Vector2:
	var best_len := 0
	var best_mid := 0.0
	for start in NDIR:
		if D[start] > thr or D[(start + NDIR - 1) % NDIR] <= thr:
			continue
		var n := 0
		while n < NDIR and D[(start + n) % NDIR] <= thr:
			n += 1
		if n > best_len:
			best_len = n
			best_mid = float(start) + float(n - 1) * 0.5
	if best_len == 0:
		var all_open := true
		for i in NDIR:
			if D[i] > thr:
				all_open = false
		return (pos - horde_center).normalized() if all_open and horde_count > 0 else Vector2.ZERO
	return Vector2.RIGHT.rotated(TAU * best_mid / float(NDIR))


func _edge_factor() -> float:
	var f: Rect2 = game.floor_rect
	var m := minf(minf(pos.x - f.position.x, f.end.x - pos.x), minf(pos.y - f.position.y, f.end.y - pos.y))
	return clampf(1.0 - m / (3.0 * M), 0.0, 1.0)


func _meteor_escape() -> Vector2:
	var best := Vector2.ZERO
	var best_left := 99.0
	for m in game.meteors:
		if m["landed"] or float(m["notice_t"]) < 0.0:
			continue
		var p: Vector2 = m["pos"]
		var d := pos.distance_to(p)
		if d < float(m["r"]) + radius + 4.0:
			var left: float = float(m["delay"]) - float(m["t"])
			if left < best_left:
				best_left = left
				best = (pos - p).normalized() if d > 1.0 else Vector2.RIGHT.rotated(randf() * TAU)
	return best


func _dir_index(v: Vector2) -> int:
	return posmod(int(round(v.angle() / (TAU / float(NDIR)))), NDIR)


func _move(delta: float) -> void:
	if dodge_t > 0.0:
		dodge_t -= delta
		pos = game.resolve_circle(pos + dodge_vel * delta, radius)
	if stun > 0.0 or held > 0.0:
		pos = game.resolve_circle(pos + knock_vel * delta, radius)
		knock_vel *= exp(-8.0 * delta)
		vel = Vector2.ZERO
		return
	if opening > 0.0:
		opening -= delta
		vel = Vector2.ZERO
		if opening <= 0.0:
			if valid(opening_chest):
				game.open_chest(opening_chest)
			opening_chest = null
		return
	stuck_t += delta
	if stuck_t >= 1.0:
		if pos.distance_to(stuck_ref) < 14.0 and mode != Mode.PANIC:
			unstick_t = 0.6
			var open: Array[Vector2] = []
			for i in NDIR:
				if dbg_D[i] <= dbg_thr:
					open.append(dirs[i])
			unstick_dir = open[randi() % open.size()] if open.size() > 0 else Vector2.RIGHT.rotated(randf() * TAU)
		stuck_t = 0.0
		stuck_ref = pos
	var want := desired
	if unstick_t > 0.0 and not instant:
		unstick_t -= delta
		want = unstick_dir
	if instant:
		heading = want
	else:
		var a := heading.angle_to(want)
		var mr := deg_to_rad(720.0) * delta
		heading = heading.rotated(clampf(a, -mr, mr))
	vel = heading * speed()
	bob += delta * 14.0
	pos = game.resolve_circle(pos + vel * delta, radius)


# ---------- оружие ----------

func _weapons(delta: float) -> void:
	if held > 0.0:
		return
	for k in weapons.keys():
		var cd: float = float(cds.get(k, 0.0)) - delta
		cds[k] = cd
		if cd > 0.0:
			continue
		var lvl: int = weapons[k]
		match k:
			"peck":
				var rng := (2.1 + 0.15 * lvl) * M
				var ts: Array = game.enemies_near(pos, rng, 1 + int(lvl / 2))
				if ts.is_empty():
					cds[k] = 0.1
					continue
				for e in ts:
					game.damage_enemy(e, (9.0 + 3.0 * lvl) * dmg_mult(), (e.pos - pos).normalized() * 120.0)
				game.add_fx({"kind": "peck", "pos": pos, "to": ts[0].pos, "dur": 0.15})
				cds[k] = 0.6 - 0.04 * lvl
			"feather":
				var ts: Array = game.enemies_near(pos, 8.0 * M, 1)
				if ts.is_empty():
					cds[k] = 0.2
					continue
				var count := 1 + int((lvl - 1) / 2)
				var base: Vector2 = (ts[0].pos - pos).normalized()
				for j in count:
					var dir := base.rotated((float(j) - float(count - 1) * 0.5) * 0.18)
					game.shots.append({"pos": pos, "vel": dir * 9.0 * M, "dmg": (7.0 + 3.0 * lvl) * dmg_mult(), "pierce": 1 + int(lvl / 2), "life": 1.2, "hit": []})
				cds[k] = 1.25 - 0.1 * lvl
			"bell":
				var rr := (1.6 + 0.25 * lvl) * M
				for e in game.enemies_near(pos, rr, 999):
					game.damage_enemy(e, (2.0 + 1.5 * lvl) * dmg_mult(), Vector2.ZERO)
				cds[k] = 0.5
			"mirror":
				var ts: Array = game.enemies_near(pos, 7.0 * M, 6)
				if ts.is_empty():
					cds[k] = 0.2
					continue
				var e0: Enemy = ts[randi() % ts.size()]
				var dir: Vector2 = (e0.pos - pos).normalized()
				var b := pos + dir * 9.0 * M
				for e in game.enemies_near(pos.lerp(b, 0.5), 4.6 * M, 999):
					if Geometry2D.get_closest_point_to_segment(e.pos, pos, b).distance_to(e.pos) < e.radius + 0.45 * M:
						game.damage_enemy(e, (12.0 + 6.0 * lvl) * dmg_mult(), dir * 60.0)
				game.add_fx({"kind": "beam", "pos": pos, "to": b, "dur": 0.25})
				cds[k] = 2.4 - 0.25 * lvl
			"scream":
				var rr := (2.4 + 0.4 * lvl) * M
				var ts: Array = game.enemies_near(pos, rr, 999)
				if ts.size() < 4:
					cds[k] = 0.3
					continue
				for e in ts:
					game.damage_enemy(e, (8.0 + 5.0 * lvl) * dmg_mult(), (e.pos - pos).normalized() * 260.0)
				game.add_fx({"kind": "ring", "pos": pos, "r": rr, "dur": 0.35, "color": Color(0.55, 0.45, 0.85, 0.8)})
				cds[k] = 5.0 - 0.5 * lvl


func _pickups(delta: float) -> void:
	var mr := magnet()
	for g in game.gems:
		var gp: Vector2 = g["pos"]
		var d := pos.distance_to(gp)
		if d < mr:
			g["pos"] = gp.move_toward(pos, (260.0 + (mr - d) * 5.0) * delta)
		if d < radius + 6.0:
			g["taken"] = true
			xp += int(g["xp"])
	for a in game.apples:
		if pos.distance_to(a["pos"]) < radius + 12.0:
			a["taken"] = true
			hp = minf(max_hp(), hp + 25.0)
			game.add_text(pos + Vector2(0, -40), "+25", Color("5a9a4a"), 18)
			if mode == Mode.RETREAT:
				say("Яблочко. Уже лучше.")
	if opening <= 0.0 and opening_chest == null:
		for c in game.chests:
			if pos.distance_to(c["pos"]) < radius + 18.0:
				# замирает на 0,3 с на открытие: лучший момент для книги
				opening = 0.3
				opening_chest = c
				break


# ---------- урон и реакции ----------

func take_damage(amount: float, src: String, label: String, from_player: bool) -> void:
	if game.over != "":
		return
	var a := amount if src == "meteor" else maxf(1.0, amount - armor())
	hp -= a
	hurt = 0.2
	dmg_log.append([game.time, src, a])
	game.on_hero_damaged(a, src, label, from_player)
	if hp <= 0.0:
		hp = 0.0
		game.hero_died()


func rammed(dir: Vector2) -> void:
	stun = 0.5
	ram_immune = 1.5
	knock_vel = dir * 8.0 * M
	opening = 0.0
	opening_chest = null
	stress = minf(1.0, stress + 0.15)
	wariness["paw"] = float(wariness["paw"]) + 0.25
	say("Ой! Лапка!")


func dodge_paw(dir: Vector2) -> void:
	var side := Vector2(-dir.y, dir.x)
	if randf() < 0.5:
		side = -side
	dodge_vel = side * 6.0 * M
	dodge_t = 0.2
	ram_immune = 0.6
	stress = minf(1.0, stress + 0.2)
	say("Лапка! Увернулся.")


func grabbed(e: Enemy) -> void:
	held = 1.0
	opening = 0.0
	opening_chest = null
	take_damage(e.dmg, "hand", "Рука", e.from_player)
	say("Рука схватила! Вырываюсь.")


# ---------- перки ----------

func _damage_shares() -> Dictionary:
	var tot := 0.0
	var by := {}
	for r in dmg_log:
		var cat := Perks.category(r[1])
		by[cat] = float(by.get(cat, 0.0)) + float(r[2])
		tot += float(r[2])
	if tot <= 0.0:
		return {}
	for k in by:
		by[k] = float(by[k]) / tot
	return by


func score_card(card: Dictionary) -> Dictionary:
	var k: String = card["key"]
	var s: float = Perks.TIER[k]
	var reason := "сильная карта"
	if plan.has(k):
		s += 4.0
		reason = "по плану билда"
	var has_area := false
	for a in Perks.AREA:
		if weapons.has(a):
			has_area = true
	if Perks.AREA.has(k) and has_area:
		s += 1.5
	var has_single := false
	for a in Perks.SINGLE:
		if weapons.has(a) or passives.has(a):
			has_single = true
	if Perks.SINGLE.has(k) and has_single:
		s += 0.8
	var shares := _damage_shares()
	var best_r := 0.0
	var best_txt := ""
	for cat in shares:
		var resp: Array = Perks.RESPONSE[cat]
		if resp.has(k):
			var r := 5.0 * float(shares[cat])
			if r > best_r:
				best_r = r
				best_txt = Perks.RESPONSE_TEXT[cat]
	s += best_r
	if best_r > 1.5:
		reason = best_txt
	if card["new"]:
		if Perks.is_weapon(k):
			s += 2.0 if level < 7 else -1.0
		else:
			s += 1.5 if level >= 7 else 0.0
	elif level >= 7:
		s += 1.0
	s += randf_range(-0.5, 0.5)
	return {"score": s, "reason": reason}


func consume_level() -> void:
	xp -= xp_next
	level += 1
	xp_next = int(5.0 + level * 5.0 + 0.35 * level * level)
	game.on_hero_level()


func apply_card(card: Dictionary) -> void:
	var k: String = card["key"]
	var l: int = card["lvl"]
	if Perks.is_weapon(k):
		weapons[k] = l
	else:
		passives[k] = l
		if k == "fluff":
			hp += 20.0
