class_name Meta
extends RefCounted
## Мета между забегами. Игрок открывает инструменты за перья, попугай сам тратит собранное просо
## на прокачку, выбирает 2 квеста из 6 и копит достижения. Экономика рассчитана так,
## чтобы всё убранное со старта открывалось примерно за 10 забегов.

## Исследования игрока: ярусы открываются по очереди.
const PLAYER := [
	{"key": "millet", "name": "Подмена проса", "desc": "клик по колоску: капкан, тухлое, яйцо, снаряд", "cost": 6, "tier": 0, "icon": "millet"},
	{"key": "book", "name": "Книга с полки", "desc": "Q: тень и удар по площади", "cost": 8, "tier": 0, "icon": "book"},
	{"key": "basket", "name": "Корзина-ловушка", "desc": "W: накрывает попугая на 2 с", "cost": 10, "tier": 1, "icon": "basket"},
	{"key": "block", "name": "Запрет умения", "desc": "на уровне попугая запрещаете 1 карту из 3", "cost": 10, "tier": 1, "icon": "ram"},
	{"key": "event3", "name": "Третий ивент", "desc": "ещё одна ловушка-возможность до босса", "cost": 7, "tier": 2, "icon": "circle"},
	{"key": "event4", "name": "Четвёртый ивент", "desc": "и ещё одна", "cost": 9, "tier": 2, "icon": "glow"},
]

## Прокачка попугая за просо: он покупает сам, по своим приоритетам.
const PARROT := [
	{"key": "hp", "name": "Крепкие перья", "desc": "+15 здоровья", "base": 160, "max": 6},
	{"key": "dmg", "name": "Острый клюв", "desc": "+10% урона", "base": 200, "max": 6},
	{"key": "speed", "name": "Быстрые лапки", "desc": "+5% скорости", "base": 150, "max": 4},
	{"key": "magnet", "name": "Длинная шея", "desc": "+15% радиус сбора", "base": 120, "max": 3},
	{"key": "start", "name": "Разминка", "desc": "+1 стартовый уровень", "base": 450, "max": 3},
	{"key": "eye", "name": "Зоркий глаз", "desc": "+1 слот внимания", "base": 1100, "max": 1},
]

const ACHIEVEMENTS := [
	{"key": "boss", "name": "Сломать пылесос", "stat": "boss_kills", "target": 1},
	{"key": "boss5", "name": "Пылесосная гроза", "stat": "boss_kills", "target": 5},
	{"key": "kills", "name": "Гроза носков", "stat": "kills", "target": 3000},
	{"key": "events", "name": "Ивентолог", "stat": "events", "target": 12},
	{"key": "chests", "name": "Кормушечник", "stat": "chests", "target": 15},
	{"key": "millet", "name": "Богач", "stat": "millet", "target": 8000},
]

const QUESTS := [
	{"key": "boss_fast", "name": "Сломать пылесос до 5:00", "reward": 320, "risk": 0.8},
	{"key": "hp_half", "name": "Победить, сохранив половину здоровья", "reward": 280, "risk": 0.7},
	{"key": "chests2", "name": "Открыть 2 кормушки", "reward": 200, "risk": 0.4},
	{"key": "events_all", "name": "Пройти все ивенты", "reward": 300, "risk": 0.6},
	{"key": "kills400", "name": "Победить 400 врагов", "reward": 200, "risk": 0.3},
	{"key": "millet700", "name": "Собрать 700 проса", "reward": 220, "risk": 0.3},
	{"key": "nothrow", "name": "Получить меньше 25 урона от бросков", "reward": 260, "risk": 0.6},
	{"key": "fruits2", "name": "Съесть 2 фрукта", "reward": 160, "risk": 0.3},
	{"key": "level12", "name": "Дойти до 12 уровня", "reward": 220, "risk": 0.4},
	{"key": "noram", "name": "Ни разу не попасть под таран", "reward": 180, "risk": 0.5},
]


static func defaults() -> Dictionary:
	return {"unlocked": {}, "parrot": {"bank": 0, "up": {}}, "stats": {}, "quests": [], "last": {}}


static func up_cost(item: Dictionary, lvl: int) -> int:
	return int(float(item["base"]) * pow(1.5, lvl))


## Ярус открыт, когда куплено всё в предыдущем ярусе.
static func tier_open(meta: Dictionary, tier: int) -> bool:
	if tier == 0:
		return true
	for it in PLAYER:
		if int(it["tier"]) == tier - 1 and not meta["unlocked"].has(it["key"]):
			return false
	return true


static func unlocked(meta: Dictionary, key: String) -> bool:
	return meta.get("unlocked", {}).has(key)


## Перья за забег: 2 за участие, до 3 за урон по попугаю, по одному за сорванный ивент, +3 за победу.
static func feathers_for(player_damage: float, events_denied: int, player_won: bool) -> int:
	return 2 + mini(3, int(player_damage / 45.0)) + events_denied + (3 if player_won else 0)


static func quest_done(key: String, r: Dictionary) -> bool:
	match key:
		"boss_fast":
			return bool(r["boss"]) and float(r["time"]) < 300.0
		"hp_half":
			return bool(r["boss"]) and float(r["hp_frac"]) >= 0.5
		"chests2":
			return int(r["chests"]) >= 2
		"events_all":
			return int(r["events"]) >= int(r["events_total"]) and int(r["events_total"]) > 0
		"kills400":
			return int(r["kills"]) >= 400
		"millet700":
			return int(r["millet"]) >= 700
		"nothrow":
			return float(r["throw_dmg"]) < 25.0
		"fruits2":
			return int(r["fruits"]) >= 2
		"level12":
			return int(r["level"]) >= 12
		"noram":
			return int(r["rams"]) == 0
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
		var s := float(q["reward"]) / 100.0 * (0.6 + greed) - float(q["risk"]) * (1.6 - greed) + randf_range(-0.4, 0.4)
		if k == "nothrow":
			s -= 4.0 * float(taken.get("throw", 0.0))
		if k == "noram":
			s -= 4.0 * float(taken.get("paw", 0.0))
		scored.append([s, k])
	scored.sort_custom(func(a, b): return a[0] > b[0])
	return [scored[0][1], scored[1][1]]


## Попугай тратит просо сам: сначала то, что лечит его главную беду, потом по кругу.
static func parrot_shop(meta: Dictionary, memory: Dictionary) -> Array:
	var bought: Array = []
	var p: Dictionary = meta["parrot"]
	var ups: Dictionary = p["up"]
	var taken: Dictionary = memory.get("taken", {})
	var hurt := 0.0
	for k in taken:
		hurt += float(taken[k])
	var order := ["hp", "dmg", "speed", "start", "magnet", "eye"]
	if float(taken.get("meteor", 0.0)) + float(taken.get("throw", 0.0)) > 0.35:
		order = ["speed", "hp", "eye", "dmg", "start", "magnet"]
	elif float(taken.get("boss", 0.0)) > 0.25:
		order = ["dmg", "hp", "start", "speed", "magnet", "eye"]
	var guard := 0
	while guard < 20:
		guard += 1
		var any := false
		for k in order:
			var item: Dictionary = {}
			for it in PARROT:
				if it["key"] == k:
					item = it
			var lvl := int(ups.get(k, 0))
			if lvl >= int(item["max"]):
				continue
			var cost := up_cost(item, lvl)
			if int(p["bank"]) >= cost:
				p["bank"] = int(p["bank"]) - cost
				ups[k] = lvl + 1
				bought.append("%s ур. %d" % [item["name"], lvl + 1])
				any = true
				break
		if not any:
			break
	return bought
