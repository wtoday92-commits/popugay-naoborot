class_name Meta
extends RefCounted
## Мета между забегами. Игрок открывает инструменты за перья, попугай сам тратит собранное просо
## на прокачку, выбирает 2 квеста из 6 и копит достижения. Экономика рассчитана так,
## чтобы всё убранное со старта открывалось примерно за 10 забегов.

## Исследования игрока: ярусы открываются по очереди.
const PLAYER := [
	{"key": "millet", "name": "Подмена проса", "desc": "клик по колоску: капкан, тухлое, яйцо, снаряд", "cost": 6, "tier": 0, "icon": "millet"},
	{"key": "book", "name": "Книга с полки", "desc": "Q: тень и удар по площади", "cost": 7, "tier": 0, "icon": "book"},
	{"key": "basket", "name": "Клетка", "desc": "W: клетка ползёт за лапкой и накрывает попугая на 2 с", "cost": 9, "tier": 1, "icon": "basket"},
	{"key": "block", "name": "Запрет умения", "desc": "на уровне попугая запрещаете 1 карту из 3", "cost": 9, "tier": 1, "icon": "ram"},
	{"key": "event3", "name": "Третий ивент", "desc": "ещё одна ловушка-возможность до босса", "cost": 7, "tier": 2, "icon": "circle"},
	{"key": "event4", "name": "Четвёртый ивент", "desc": "и ещё одна", "cost": 8, "tier": 2, "icon": "glow"},
]

## Прокачка попугая за просо: он покупает сам, по своим приоритетам.
## Пункты открываются этапами по мере того, сколько он уже потратил (stage), чтобы не вываливать всё сразу.
const PARROT := [
	{"key": "hp", "name": "Крепкие перья", "desc": "+15 здоровья", "base": 160, "max": 8, "stage": 0},
	{"key": "dmg", "name": "Острый клюв", "desc": "+10% урона", "base": 200, "max": 8, "stage": 0},
	{"key": "speed", "name": "Быстрые лапки", "desc": "+5% скорости", "base": 160, "max": 5, "stage": 0},
	{"key": "magnet", "name": "Длинная шея", "desc": "+15% радиус сбора", "base": 250, "max": 3, "stage": 1},
	{"key": "start", "name": "Разминка", "desc": "+1 стартовый уровень", "base": 900, "max": 3, "stage": 1},
	{"key": "armor", "name": "Плотный пух", "desc": "−4% любого урона", "base": 600, "max": 5, "stage": 1},
	{"key": "regen", "name": "Самолечение", "desc": "+0,25 здоровья в секунду", "base": 900, "max": 4, "stage": 2},
	{"key": "dodge", "name": "Чуткие перья", "desc": "+5% шанс увернуться от бросков и лапки", "base": 900, "max": 4, "stage": 2},
	{"key": "xp", "name": "Прилежание", "desc": "+6% опыта", "base": 800, "max": 4, "stage": 2},
	{"key": "eye", "name": "Зоркий глаз", "desc": "+1 слот внимания", "base": 3000, "max": 1, "stage": 3},
	{"key": "luck", "name": "Удача", "desc": "+3% шанс двойного урона", "base": 1200, "max": 3, "stage": 3},
]
## Сколько проса надо потратить, чтобы открылся этап.
const PARROT_STAGES := [0, 1500, 6000, 15000]
## Умения, с которыми Кеша приходит в первый раз; остальные открываются просом или достижениями.
const START_SKILLS := ["feather", "bell", "orbit", "mirror"]
const PARROT_SKILLS := [
	{"key": "scream", "name": "Крик", "cost": 1400, "stage": 1, "ach": ""},
	{"key": "zap", "name": "Искра", "cost": 0, "stage": 0, "ach": "boss3"},
]

## Достижения Кеши: каждое что-то даёт (просо или новое умение).
const ACHIEVEMENTS := [
	{"key": "boss", "name": "Сломать пылесос", "stat": "boss_kills", "target": 1, "millet": 300},
	{"key": "dodger", "name": "Ловкач", "stat": "dodges", "target": 60, "millet": 400},
	{"key": "kills", "name": "Гроза носков", "stat": "kills", "target": 3000, "millet": 600},
	{"key": "events", "name": "Ивентолог", "stat": "events", "target": 12, "millet": 400},
	{"key": "boss3", "name": "Пылесосный мастер", "stat": "boss_kills", "target": 3, "skill": "zap"},
	{"key": "chests", "name": "Кормушечник", "stat": "chests", "target": 15, "millet": 500},
	{"key": "boss10", "name": "Пылесосная гроза", "stat": "boss_kills", "target": 10, "millet": 1500},
	{"key": "millet", "name": "Богач", "stat": "millet", "target": 15000, "millet": 1000},
]


## Квесты попугая. Пороги выставлены по прогонам: обычные выполняются в 40–65% забегов,
## «трудные» (пылесос) — в 20–25%, но за них больше проса. risk ≈ доля забегов, где квест не выполнен.
const QUESTS := [
	{"key": "boss_fast", "name": "Сломать пылесос до 5:00", "reward": 400, "risk": 0.75},
	{"key": "boss_hp", "name": "Сломать пылесос, сохранив треть здоровья", "reward": 400, "risk": 0.75},
	{"key": "chests3", "name": "Открыть 3 кормушки", "reward": 170, "risk": 0.5},
	{"key": "event1", "name": "Пройти хотя бы 1 ивент", "reward": 140, "risk": 0.35},
	{"key": "kills400", "name": "Победить 400 врагов", "reward": 170, "risk": 0.5},
	{"key": "millet480", "name": "Собрать 480 проса", "reward": 170, "risk": 0.5},
	{"key": "nothrow", "name": "Получить меньше 20 урона от бросков", "reward": 200, "risk": 0.5},
	{"key": "fruit1", "name": "Съесть хотя бы 1 фрукт", "reward": 140, "risk": 0.35},
	{"key": "level13", "name": "Дойти до 13 уровня", "reward": 170, "risk": 0.45},
	{"key": "noram10", "name": "Попасть под таран не больше 10 раз", "reward": 170, "risk": 0.5},
]


static func defaults() -> Dictionary:
	return {"unlocked": {}, "parrot": {"bank": 0, "up": {}, "spent": 0, "skills": START_SKILLS.duplicate(), "ach": {}}, "stats": {}, "quests": [], "last": {}, "pstats": {}}


static func parrot_stage(meta: Dictionary) -> int:
	var sp := int(meta["parrot"].get("spent", 0))
	var st := 0
	for i in PARROT_STAGES.size():
		if sp >= int(PARROT_STAGES[i]):
			st = i
	return st


static func parrot_skills(meta: Dictionary) -> Array:
	return meta["parrot"].get("skills", START_SKILLS.duplicate())


static func up_cost(item: Dictionary, lvl: int) -> int:
	return int(float(item["base"]) * pow(2.2, lvl))


## Ярус открыт, когда куплено всё в предыдущем ярусе.
static func tier_open(meta: Dictionary, tier: int) -> bool:
	if tier == 0:
		return true
	# дальше исследования открываются вместе с успехами Кеши: со средней комнаты
	if Diff.unlocked(meta) < 1:
		return false
	for it in PLAYER:
		if int(it["tier"]) == tier - 1 and not meta["unlocked"].has(it["key"]):
			return false
	return true


static func unlocked(meta: Dictionary, key: String) -> bool:
	return meta.get("unlocked", {}).has(key)


## Перья за забег: 3 за участие, до 3 за урон по попугаю, по одному за сорванный ивент, +3 за победу.
static func feathers_for(player_damage: float, events_denied: int, player_won: bool) -> int:
	return 3 + mini(3, int(player_damage / 45.0)) + events_denied + (3 if player_won else 0)


static func quest_done(key: String, r: Dictionary) -> bool:
	match key:
		"boss_fast":
			return bool(r["boss"]) and float(r["time"]) < 300.0
		"boss_hp":
			return bool(r["boss"]) and float(r["hp_frac"]) >= 0.33
		"chests3":
			return int(r["chests"]) >= 3
		"event1":
			return int(r["events"]) >= 1
		"kills400":
			return int(r["kills"]) >= 400
		"millet480":
			return int(r["millet"]) >= 480
		"nothrow":
			return float(r["throw_dmg"]) < 20.0
		"fruit1":
			return int(r["fruits"]) >= 1
		"level13":
			return int(r["level"]) >= 13
		"noram10":
			return int(r["rams"]) <= 10
	return false


static func quest_by_key(key: String) -> Dictionary:
	for q in QUESTS:
		if q["key"] == key:
			return q
	return {}


## Попугай выбирает 2 квеста из 6: жадный тянется к награде, осторожный — к безопасным,
## а то, что его часто ломало (броски, таран), обходит стороной.
static func choose_quests(offer: Array, greed: float, memory: Dictionary) -> Array:
	var taken: Dictionary = memory.get("taken", {})
	var scored: Array = []
	for k in offer:
		var q := quest_by_key(k)
		# ожидаемая награда с поправкой на характер: жадный меньше боится риска
		var s := float(q["reward"]) / 100.0 * pow(1.0 - float(q["risk"]), 2.0 - greed) + randf_range(-0.25, 0.25)
		if k == "nothrow":
			s -= 4.0 * float(taken.get("throw", 0.0))
		if k == "noram10":
			s -= 4.0 * float(taken.get("paw", 0.0))
		scored.append([s, k])
	scored.sort_custom(func(a, b): return a[0] > b[0])
	return [scored[0][1], scored[1][1]]


## Достижения выдают награду один раз; возвращает подписи новых.
static func claim_achievements(meta: Dictionary) -> Array:
	var p: Dictionary = meta["parrot"]
	if not p.has("ach"):
		p["ach"] = {}
	if not p.has("skills"):
		p["skills"] = START_SKILLS.duplicate()
	var out: Array = []
	for a in ACHIEVEMENTS:
		if p["ach"].has(a["key"]) or float(meta["stats"].get(a["stat"], 0)) < float(a["target"]):
			continue
		p["ach"][a["key"]] = true
		if a.has("skill"):
			if not p["skills"].has(a["skill"]):
				p["skills"].append(a["skill"])
			out.append("%s: новое умение «%s»" % [a["name"], Skills.NAMES[a["skill"]]])
		else:
			p["bank"] = int(p["bank"]) + int(a["millet"])
			out.append("%s: +%d проса" % [a["name"], int(a["millet"])])
	return out


## Попугай тратит просо сам: сначала то, что лечит его главную беду, потом по кругу.
static func parrot_shop(meta: Dictionary, memory: Dictionary) -> Array:
	var bought: Array = []
	var p: Dictionary = meta["parrot"]
	var ups: Dictionary = p["up"]
	var taken: Dictionary = memory.get("taken", {})
	var order := ["hp", "dmg", "speed", "armor", "start", "magnet", "regen", "xp", "dodge", "eye", "luck"]
	if float(taken.get("meteor", 0.0)) + float(taken.get("throw", 0.0)) + float(taken.get("paw", 0.0)) > 0.35:
		order = ["speed", "dodge", "hp", "armor", "eye", "dmg", "start", "regen", "magnet", "xp", "luck"]
	elif float(taken.get("boss", 0.0)) > 0.25:
		order = ["dmg", "hp", "start", "luck", "speed", "armor", "xp", "regen", "magnet", "eye", "dodge"]
	var guard := 0
	while guard < 60:
		guard += 1
		var stage := parrot_stage(meta)
		# новое умение за просо — первым делом, как только хватает
		var any := false
		for sk in PARROT_SKILLS:
			if int(sk["cost"]) > 0 and int(sk["stage"]) <= stage and not p["skills"].has(sk["key"]) and int(p["bank"]) >= int(sk["cost"]):
				p["bank"] = int(p["bank"]) - int(sk["cost"])
				p["spent"] = int(p.get("spent", 0)) + int(sk["cost"])
				p["skills"].append(sk["key"])
				bought.append("умение «%s»" % sk["name"])
				any = true
		if any:
			continue
		# общий пункт: первый по приоритету, который ещё не на максимуме
		var gen: Dictionary = {}
		var gen_cost := 1 << 30
		for k in order:
			var item: Dictionary = {}
			for it in PARROT:
				if it["key"] == k:
					item = it
			if int(item["stage"]) > stage or int(ups.get(k, 0)) >= int(item["max"]):
				continue
			gen = item
			gen_cost = up_cost(item, int(ups.get(k, 0)))
			break
		# узел дерева попугая, за которого он пойдёт следующим (остальные — дороже по приоритету)
		var nb := Parrots.next_bird(meta)
		var node_pick := []
		var node_w := 1 << 30
		for b in Parrots.owned(meta):
			var bn := Parrots.best_node(meta, b)
			if bn.is_empty():
				continue
			var w := int(float(bn[2]) * (1.0 if b == nb else 1.6))
			if w < node_w:
				node_w = w
				node_pick = [b, bn[0], bn[1], bn[2]]
		if not node_pick.is_empty() and node_w < gen_cost and int(p["bank"]) >= int(node_pick[3]):
			var id := Parrots.node_id(node_pick[0], node_pick[1], node_pick[2])
			p["bank"] = int(p["bank"]) - int(node_pick[3])
			p["spent"] = int(p.get("spent", 0)) + int(node_pick[3])
			Parrots.data(meta)["nodes"][id] = Parrots.lvl(meta, id) + 1
			bought.append("%s: %s" % [Parrots.bird(node_pick[0])["name"], Parrots.node(node_pick[0], node_pick[1], node_pick[2])[0]])
			continue
		if not gen.is_empty() and int(p["bank"]) >= gen_cost:
			var lvl := int(ups.get(gen["key"], 0))
			p["bank"] = int(p["bank"]) - gen_cost
			p["spent"] = int(p.get("spent", 0)) + gen_cost
			ups[gen["key"]] = lvl + 1
			bought.append("%s ур. %d" % [gen["name"], lvl + 1])
			continue
		break
	return bought
