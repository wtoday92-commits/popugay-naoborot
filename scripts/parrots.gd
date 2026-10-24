class_name Parrots
extends RefCounted
## Попугаи, за которых играет ИИ. Новые выпадают из яйца с очень маленьким шансом.
## У каждого — особенность, своё умение (только у него в колоде) и своё дерево прокачки за просо,
## ключевые узлы которого открываются достижениями именно в забегах за этого попугая.

const ORDER := ["budgie", "jaco", "cockatoo", "kakapo"]

const BIRDS := {
	"budgie": {
		"name": "Кеша", "gen": "Кеши", "kind": "волнистый попугайчик", "skill": "",
		"trait": "Рывок: уворачивается от бросков и лапки",
		"hp": 1.0, "speed": 1.0, "slots": 0, "knock": 1.0, "dodge": 1.0, "notice": 0.0, "scale": 1.0,
		"col": {"body": Color("79c85f"), "belly": Color("a8dd8c"), "wing": Color("4f9a45"), "bars": Color("1f3d22"),
			"head": Color("f7dc4f"), "stripes": Color("4a3c1c"), "tail1": Color("2f6e6a"), "tail2": Color("3f8f7a"),
			"beak": Color("f0a64a"), "cere": Color("6d8fd6"), "cheek": Color("8a6fd0"), "crest": "small", "feet": Color("e58a9a")},
	},
	"jaco": {
		"name": "Жако", "gen": "Жако", "kind": "серый жако", "skill": "mimic",
		"trait": "Умник: +1 слот внимания и замечает тени быстрее, но на 8% медленнее",
		"hp": 1.0, "speed": 0.92, "slots": 1, "knock": 1.0, "dodge": 1.0, "notice": 0.15, "scale": 1.05,
		"col": {"body": Color("9ea3a8"), "belly": Color("c4c8cc"), "wing": Color("7b8086"), "bars": Color("5b6066"),
			"head": Color("b8bcc0"), "stripes": Color("8a8f95"), "tail1": Color("d23b2e"), "tail2": Color("e8574a"),
			"beak": Color("2b2b2b"), "cere": Color("9ea3a8"), "cheek": Color(0, 0, 0, 0), "crest": "none", "feet": Color("8a8f95"),
			"face": Color("eef0f2")},
	},
	"cockatoo": {
		"name": "Какаду", "gen": "Какаду", "kind": "белый какаду", "skill": "crestfan",
		"trait": "Хохол дыбом: при здоровье ниже 40% урон +30%, а враги вплотную медленнее на 20%",
		"hp": 0.95, "speed": 1.05, "slots": 0, "knock": 1.0, "dodge": 0.9, "notice": 0.0, "scale": 1.1,
		"col": {"body": Color("f4f2ec"), "belly": Color("ffffff"), "wing": Color("e6e2d8"), "bars": Color("c9c3b5"),
			"head": Color("faf8f2"), "stripes": Color(0, 0, 0, 0), "tail1": Color("e9e4d6"), "tail2": Color("f4f0e4"),
			"beak": Color("4a4a50"), "cere": Color("f4f2ec"), "cheek": Color(0, 0, 0, 0), "crest": "tall", "feet": Color("9a9aa0")},
	},
	"kakapo": {
		"name": "Какапо", "gen": "Какапо", "kind": "совиный попугай", "skill": "boom",
		"trait": "Тяжеловес: +40% здоровья и почти не отлетает от ударов, но медленнее и не уворачивается",
		"hp": 1.4, "speed": 0.85, "slots": 0, "knock": 0.3, "dodge": 0.0, "notice": 0.0, "scale": 1.18,
		"col": {"body": Color("8aa84a"), "belly": Color("c8c46a"), "wing": Color("6e8a38"), "bars": Color("2f3a18"),
			"head": Color("b9a95a"), "stripes": Color("4d4a2a"), "tail1": Color("5f7a30"), "tail2": Color("7a9640"),
			"beak": Color("d8cfb8"), "cere": Color("b9a95a"), "cheek": Color(0, 0, 0, 0), "crest": "none", "feet": Color("a89a8a"),
			"spots": Color("e0d36a"), "owl": true},
	},
}

## Деревья попугаев: по 3 ветки по 7 узлов, как у игрока. Цены — в просе.
const COSTS := [[300, 600, 1200], [900, 1800], [900, 1800], [3000], [2400, 4800], [2400, 4800], [9000]]
## [название, описание, стат, значение за уровень, уровней, условие или []]; условие — [счётчик за этого попугая, цель, текст].
const TREES := {
	"budgie": [
		{"name": "Рывок", "nodes": [
			["Лёгкое тельце", "+4% шанс увернуться", "dodge", 0.04, 3, []],
			["Быстрые лапки", "+4% скорости", "speed_pct", 0.04, 2, []],
			["Отдышка", "+0,2 здоровья в секунду", "regen", 0.2, 2, []],
			["Ловкач", "+15% шанс увернуться от бросков и лапки", "evasion", 1.0, 1, ["dodges", 40, "увернуться 40 раз"]],
			["Ещё быстрее", "+4% скорости", "speed_pct", 0.04, 2, []],
			["Чутьё", "+4% шанс увернуться", "dodge", 0.04, 2, []],
			["Второе дыхание", "после нового уровня 3 с бегает на 50% быстрее", "rally", 1.0, 1, ["wins", 5, "сломать 5 пылесосов"]],
		]},
		{"name": "Клюв", "nodes": [
			["Острый клюв", "+5% урона", "dmg_pct", 0.05, 3, []],
			["Меткость", "+3% двойного урона", "crit", 0.03, 2, []],
			["Любопытство", "+5% опыта", "xp_pct", 0.05, 2, []],
			["Счастливчик", "+10% двойного урона", "lucky", 1.0, 1, ["kills", 1500, "победить 1500 врагов"]],
			["Ещё острее", "+5% урона", "dmg_pct", 0.05, 2, []],
			["Учёба", "+5% опыта", "xp_pct", 0.05, 2, []],
			["Ярость", "ниже 30% здоровья урон +40%", "berserk", 1.0, 1, ["boss", 3, "сломать 3 пылесоса"]],
		]},
		{"name": "Пух", "nodes": [
			["Густой пух", "+5% здоровья", "hp_pct", 0.05, 3, []],
			["Плотные перья", "−3% урона", "armor_pct", 0.03, 2, []],
			["Самолечение", "+0,2 здоровья в секунду", "regen", 0.2, 2, []],
			["Второй шанс", "раз за забег при смерти восстанавливает 35% здоровья", "second_wind", 1.0, 1, ["runs", 15, "сыграть 15 забегов"]],
			["Ещё пух", "+5% здоровья", "hp_pct", 0.05, 2, []],
			["Броня", "−3% урона", "armor_pct", 0.03, 2, []],
			["Железные перья", "−25% урона от инструментов игрока", "iron", 1.0, 1, ["wins", 10, "сломать 10 пылесосов"]],
		]},
	],
	"jaco": [
		{"name": "Передразнивание", "nodes": [
			["Хороший слух", "+10% силы передразнивания", "skill_pct", 0.1, 3, []],
			["Быстрая память", "−8% отката передразнивания", "skill_cd", 0.08, 2, []],
			["Громкий голос", "+10% силы передразнивания", "skill_pct", 0.1, 2, []],
			["Врождённое", "начинает забег с передразниванием", "innate", 1.0, 1, ["skill_hits", 60, "передразнить 60 раз"]],
			["Звонче", "+10% силы передразнивания", "skill_pct", 0.1, 2, []],
			["Ещё быстрее", "−8% отката передразнивания", "skill_cd", 0.08, 2, []],
			["Мастер пародий", "передразнивание сразу 3 уровня", "master", 1.0, 1, ["wins", 5, "сломать 5 пылесосов за Жако"]],
		]},
		{"name": "Ум", "nodes": [
			["Наблюдательность", "+5% опыта", "xp_pct", 0.05, 3, []],
			["Расчёт", "+5% урона", "dmg_pct", 0.05, 2, []],
			["Осторожность", "−3% урона", "armor_pct", 0.03, 2, []],
			["Предвидение", "замечает книгу и клетку мгновенно", "foresight", 1.0, 1, ["dodges", 40, "увернуться 40 раз за Жако"]],
			["Ещё опыт", "+5% опыта", "xp_pct", 0.05, 2, []],
			["Ещё урон", "+5% урона", "dmg_pct", 0.05, 2, []],
			["Сосредоточенность", "+1 слот внимания", "focus", 1.0, 1, ["kills", 2000, "победить 2000 врагов за Жако"]],
		]},
		{"name": "Перья", "nodes": [
			["Густые перья", "+5% здоровья", "hp_pct", 0.05, 3, []],
			["Самолечение", "+0,2 здоровья в секунду", "regen", 0.2, 2, []],
			["Ловкость", "+4% шанс увернуться", "dodge", 0.04, 2, []],
			["Второй шанс", "раз за забег при смерти восстанавливает 35% здоровья", "second_wind", 1.0, 1, ["runs", 15, "15 забегов за Жако"]],
			["Ещё перья", "+5% здоровья", "hp_pct", 0.05, 2, []],
			["Ещё лечение", "+0,2 здоровья в секунду", "regen", 0.2, 2, []],
			["Колючие перья", "враги, кусающие Жако, получают 6 урона", "thorns", 1.0, 1, ["boss", 3, "сломать 3 пылесоса за Жако"]],
		]},
	],
	"cockatoo": [
		{"name": "Гребень", "nodes": [
			["Пышный гребень", "+10% силы веера", "skill_pct", 0.1, 3, []],
			["Резкий взмах", "−8% отката веера", "skill_cd", 0.08, 2, []],
			["Длинные перья", "+10% силы веера", "skill_pct", 0.1, 2, []],
			["Врождённое", "начинает забег с веером из гребня", "innate", 1.0, 1, ["skill_hits", 300, "попасть веером 300 раз"]],
			["Ещё пышнее", "+10% силы веера", "skill_pct", 0.1, 2, []],
			["Ещё резче", "−8% отката веера", "skill_cd", 0.08, 2, []],
			["Мастер гребня", "веер сразу 3 уровня", "master", 1.0, 1, ["wins", 5, "сломать 5 пылесосов за Какаду"]],
		]},
		{"name": "Крик", "nodes": [
			["Громкость", "+5% урона", "dmg_pct", 0.05, 3, []],
			["Меткость", "+3% двойного урона", "crit", 0.03, 2, []],
			["Задор", "+4% скорости", "speed_pct", 0.04, 2, []],
			["Ярость", "ниже 30% здоровья урон +40%", "berserk", 1.0, 1, ["kills", 1500, "победить 1500 врагов за Какаду"]],
			["Ещё громче", "+5% урона", "dmg_pct", 0.05, 2, []],
			["Ещё меткость", "+3% двойного урона", "crit", 0.03, 2, []],
			["Счастливчик", "+10% двойного урона", "lucky", 1.0, 1, ["boss", 3, "сломать 3 пылесоса за Какаду"]],
		]},
		{"name": "Перья", "nodes": [
			["Густые перья", "+5% здоровья", "hp_pct", 0.05, 3, []],
			["Самолечение", "+0,2 здоровья в секунду", "regen", 0.2, 2, []],
			["Плотные перья", "−3% урона", "armor_pct", 0.03, 2, []],
			["Колючие перья", "враги, кусающие Какаду, получают 6 урона", "thorns", 1.0, 1, ["runs", 15, "15 забегов за Какаду"]],
			["Ещё перья", "+5% здоровья", "hp_pct", 0.05, 2, []],
			["Ещё лечение", "+0,2 здоровья в секунду", "regen", 0.2, 2, []],
			["Вампир", "каждый клевок лечит 1 здоровье", "vamp", 1.0, 1, ["wins", 8, "сломать 8 пылесосов за Какаду"]],
		]},
	],
	"kakapo": [
		{"name": "Бумканье", "nodes": [
			["Глубокий голос", "+10% силы бумканья", "skill_pct", 0.1, 3, []],
			["Частое бумканье", "−8% отката бумканья", "skill_cd", 0.08, 2, []],
			["Мощная грудь", "+10% силы бумканья", "skill_pct", 0.1, 2, []],
			["Врождённое", "начинает забег с бумканьем", "innate", 1.0, 1, ["skill_hits", 400, "задеть бумканьем 400 врагов"]],
			["Ещё глубже", "+10% силы бумканья", "skill_pct", 0.1, 2, []],
			["Ещё чаще", "−8% отката бумканья", "skill_cd", 0.08, 2, []],
			["Мастер бумканья", "бумканье сразу 3 уровня", "master", 1.0, 1, ["wins", 5, "сломать 5 пылесосов за Какапо"]],
		]},
		{"name": "Тяжесть", "nodes": [
			["Толстые бока", "+6% здоровья", "hp_pct", 0.06, 3, []],
			["Плотные перья", "−3% урона", "armor_pct", 0.03, 2, []],
			["Сила", "+5% урона", "dmg_pct", 0.05, 2, []],
			["Железные перья", "−25% урона от инструментов игрока", "iron", 1.0, 1, ["runs", 15, "15 забегов за Какапо"]],
			["Ещё бока", "+6% здоровья", "hp_pct", 0.06, 2, []],
			["Ещё броня", "−3% урона", "armor_pct", 0.03, 2, []],
			["Второй шанс", "раз за забег при смерти восстанавливает 35% здоровья", "second_wind", 1.0, 1, ["wins", 5, "сломать 5 пылесосов за Какапо"]],
		]},
		{"name": "Ночная птица", "nodes": [
			["Отдых", "+0,2 здоровья в секунду", "regen", 0.2, 3, []],
			["Нюх", "+15% радиус сбора", "magnet_pct", 0.15, 2, []],
			["Любопытство", "+5% опыта", "xp_pct", 0.05, 2, []],
			["Фруктоед", "фрукты лечат на 20 больше и действуют дольше", "fruit_love", 1.0, 1, ["kills", 1500, "победить 1500 врагов за Какапо"]],
			["Ещё отдых", "+0,2 здоровья в секунду", "regen", 0.2, 2, []],
			["Ещё нюх", "+15% радиус сбора", "magnet_pct", 0.15, 2, []],
			["Вампир", "каждый клевок лечит 1 здоровье", "vamp", 1.0, 1, ["boss", 3, "сломать 3 пылесоса за Какапо"]],
		]},
	],
}


static func bird(key: String) -> Dictionary:
	return BIRDS.get(key, BIRDS["budgie"])


static func data(meta: Dictionary) -> Dictionary:
	var p: Dictionary = meta["parrot"]
	if not p.has("birds"):
		p["birds"] = {"owned": ["budgie"], "next": "budgie", "nodes": {}, "stats": {}, "recent": [], "reason": ""}
	return p["birds"]


static func owned(meta: Dictionary) -> Array:
	return data(meta)["owned"]


static func next_bird(meta: Dictionary) -> String:
	var n := String(data(meta).get("next", "budgie"))
	return n if owned(meta).has(n) else "budgie"


static func stat(meta: Dictionary, b: String, k: String) -> float:
	return float(data(meta)["stats"].get(b, {}).get(k, 0.0))


static func add_stat(meta: Dictionary, b: String, k: String, v: float) -> void:
	var st: Dictionary = data(meta)["stats"]
	if not st.has(b):
		st[b] = {}
	st[b][k] = float(st[b].get(k, 0.0)) + v


static func node_id(b: String, bi: int, ni: int) -> String:
	return "%s.%d.%d" % [b, bi, ni]


static func lvl(meta: Dictionary, id: String) -> int:
	return int(data(meta)["nodes"].get(id, 0))


static func node(b: String, bi: int, ni: int) -> Array:
	return TREES[b][bi]["nodes"][ni]


static func reachable(meta: Dictionary, b: String, bi: int, ni: int) -> bool:
	var L := func(i: int) -> int: return lvl(meta, node_id(b, bi, i))
	match ni:
		0:
			return true
		1, 2:
			return L.call(0) > 0
		3:
			return L.call(1) > 0 or L.call(2) > 0
		4, 5:
			return L.call(3) > 0
		6:
			return L.call(4) > 0 or L.call(5) > 0
	return false


static func cond_ok(meta: Dictionary, b: String, cond: Array) -> bool:
	return cond.is_empty() or stat(meta, b, cond[0]) >= float(cond[1])


static func cost(ni: int, cur: int) -> int:
	var c: Array = COSTS[ni]
	return int(c[mini(cur, c.size() - 1)])


## Самый дешёвый узел, который Кеша может купить для этого попугая (или []).
static func best_node(meta: Dictionary, b: String) -> Array:
	var best := []
	var bc := 1 << 30
	for bi in 3:
		for ni in 7:
			var n := node(b, bi, ni)
			var cur := lvl(meta, node_id(b, bi, ni))
			if cur >= int(n[4]) or not reachable(meta, b, bi, ni) or not cond_ok(meta, b, n[5]):
				continue
			var c := cost(ni, cur)
			if c < bc:
				bc = c
				best = [bi, ni, c]
	return best


static func bought_total(meta: Dictionary, b: String) -> int:
	var n := 0
	for bi in 3:
		for ni in 7:
			n += lvl(meta, node_id(b, bi, ni))
	return n


## Сумма статов дерева выбранного попугая.
static func perks(meta: Dictionary, b: String) -> Dictionary:
	var out := {}
	if not TREES.has(b):
		return out
	for bi in 3:
		for ni in 7:
			var l := lvl(meta, node_id(b, bi, ni))
			if l > 0:
				var n := node(b, bi, ni)
				out[n[2]] = float(out.get(n[2], 0.0)) + float(n[3]) * l
	return out


## Кем быть в следующем забеге: у кого лучше получается выживать, тот в приоритете,
## но новенький манит, а три раза подряд одним и тем же надоедает.
static func choose(meta: Dictionary) -> String:
	var d := data(meta)
	var own: Array = owned(meta)
	var recent: Array = d.get("recent", [])
	var best := "budgie"
	var bv := -INF
	for b in own:
		var runs := stat(meta, b, "runs")
		var v := 0.0
		if runs <= 0.0:
			v = 2.0
		else:
			var surv := stat(meta, b, "time") / runs / 300.0
			var winr := (stat(meta, b, "wins") + 0.5) / (runs + 1.0)
			v = surv + 1.2 * winr + 0.04 * float(bought_total(meta, b))
		var rep := 0
		for r in recent.slice(maxi(0, recent.size() - 3)):
			if r == b:
				rep += 1
		v -= 0.35 * rep
		v += randf_range(-0.25, 0.25)
		if v > bv:
			bv = v
			best = b
	d["next"] = best
	var nm := String(bird(best)["name"])
	if stat(meta, best, "runs") <= 0.0:
		d["reason"] = "%s впервые выходит в комнату." % nm
	elif own.size() > 1:
		d["reason"] = "Следующим идёт %s: у него неплохо получается." % nm
	else:
		d["reason"] = ""
	return best


static func record(meta: Dictionary, b: String, won: bool, t: float, kills: int, dodges: int, skill_hits: int) -> void:
	add_stat(meta, b, "runs", 1.0)
	add_stat(meta, b, "time", t)
	add_stat(meta, b, "kills", float(kills))
	add_stat(meta, b, "dodges", float(dodges))
	add_stat(meta, b, "skill_hits", float(skill_hits))
	if won:
		add_stat(meta, b, "wins", 1.0)
		add_stat(meta, b, "boss", 1.0)
	var r: Array = data(meta)["recent"]
	r.append(b)
	data(meta)["recent"] = r.slice(maxi(0, r.size() - 6))
