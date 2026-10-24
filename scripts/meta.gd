class_name Meta
extends RefCounted
## Мета между забегами. Игрок открывает инструменты за перья, попугай сам тратит собранное просо
## на прокачку, выбирает 2 квеста из 6 и копит достижения. Экономика рассчитана так,
## чтобы всё убранное со старта открывалось примерно за 10 забегов.

## Исследования игрока: ярусы открываются по очереди.
const PLAYER := [
	{"key": "millet", "name": "Подмена проса", "desc": "клик по колоску: капкан, тухлое, яйцо, снаряд", "cost": 5, "tier": 0, "icon": "millet"},
	{"key": "book", "name": "Книга с полки", "desc": "Q: тень и удар по площади", "cost": 6, "tier": 0, "icon": "book"},
	{"key": "basket", "name": "Корзина-ловушка", "desc": "W: накрывает попугая на 2 с", "cost": 8, "tier": 1, "icon": "basket"},
	{"key": "block", "name": "Запрет умения", "desc": "на уровне попугая запрещаете 1 карту из 3", "cost": 8, "tier": 1, "icon": "ram"},
	{"key": "event3", "name": "Третий ивент", "desc": "ещё одна ловушка-возможность до босса", "cost": 5, "tier": 2, "icon": "circle"},
	{"key": "event4", "name": "Четвёртый ивент", "desc": "и ещё одна", "cost": 6, "tier": 2, "icon": "glow"},
]

## Прокачка рогатки: сила натяга и ветки. На забег выбирается одна ветка.
const SLING := [
	{"key": "power1", "name": "Тугая резинка", "desc": "натяг длиннее, бросок быстрее", "cost": 4, "req": "", "branch": false, "icon": "grab"},
	{"key": "power2", "name": "Резинка из шины", "desc": "ещё длиннее и быстрее", "cost": 6, "req": "power1", "branch": false, "icon": "grab"},
	{"key": "fire", "name": "Огненный носок", "desc": "ветка: носок разгорается, урон растёт с дальностью", "cost": 5, "req": "", "branch": true, "icon": "chili"},
	{"key": "knock", "name": "Тапок-выбивала", "desc": "ветка: тапок выбивает фрукты, издалека — два", "cost": 5, "req": "", "branch": true, "icon": "apple"},
	{"key": "splash", "name": "Шлепок", "desc": "ветка: слабый натяг бьёт по площади (скоро)", "cost": 0, "req": "", "branch": true, "icon": "out", "soon": true},
]

## Прокачка попугая за просо: он покупает сам, по своим приоритетам.
const PARROT := [
	{"key": "hp", "name": "Крепкие перья", "desc": "+15 здоровья", "base": 160, "max": 6},
	{"key": "dmg", "name": "Острый клюв", "desc": "+10% урона", "base": 200, "max": 6},
	{"key": "speed", "name": "Быстрые лапки", "desc": "+5% скорости", "base": 160, "max": 4},
	{"key": "magnet", "name": "Длинная шея", "desc": "+15% радиус сбора", "base": 120, "max": 3},
	{"key": "start", "name": "Разминка", "desc": "+1 стартовый уровень", "base": 460, "max": 3},
	{"key": "eye", "name": "Зоркий глаз", "desc": "+1 слот внимания", "base": 1150, "max": 1},
]

const ACHIEVEMENTS := [
	{"key": "boss", "name": "Сломать пылесос", "stat": "boss_kills", "target": 1},
	{"key": "boss5", "name": "Пылесосная гроза", "stat": "boss_kills", "target": 5},
	{"key": "kills", "name": "Гроза носков", "stat": "kills", "target": 3000},
	{"key": "events", "name": "Ивентолог", "stat": "events", "target": 12},
	{"key": "chests", "name": "Кормушечник", "stat": "chests", "target": 15},
	{"key": "millet", "name": "Богач", "stat": "millet", "target": 8000},
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
	return {"unlocked": {}, "parrot": {"bank": 0, "up": {}}, "stats": {}, "quests": [], "last": {}, "sling": {"owned": {}, "branch": ""}}


static func sling_owned(meta: Dictionary, key: String) -> bool:
	return meta.get("sling", {}).get("owned", {}).has(key)


static func sling_power(meta: Dictionary) -> int:
	return (1 if sling_owned(meta, "power1") else 0) + (1 if sling_owned(meta, "power2") else 0)


static func sling_branch(meta: Dictionary) -> String:
	return String(meta.get("sling", {}).get("branch", ""))


static func up_cost(item: Dictionary, lvl: int) -> int:
	return int(float(item["base"]) * pow(1.85, lvl))


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
