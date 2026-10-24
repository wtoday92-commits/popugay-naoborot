class_name Diff
extends RefCounted
## Сложности комнаты. Как «Проклятие» в Vampire Survivors: каждая ступень поднимает здоровье, число,
## скорость и урон врагов и даёт больше проса (как бонус золота в Hyper). Плюс на каждой ступени
## враги получают новое свойство, а пылесос — новую механику.
## Следующая сложность открывается, когда Кеша проходит предыдущую. Куда идти — он решает сам.

const BIOMES := [
	{"key": "room", "name": "Комната", "ready": true},
	{"key": "kitchen", "name": "Кухня", "ready": false},
]

const LEVELS := [
	{"name": "Обычная", "short": "обычная комната", "acc": "обычную комнату", "prep": "обычной комнате", "hp": 1.0, "count": 1.0, "speed": 1.0, "dmg": 1.0, "boss_hp": 1.0, "millet": 1.0, "feathers": 0, "color": Color("4f8f3a")},
	{"name": "Средняя", "short": "средняя комната", "acc": "среднюю комнату", "prep": "средней комнате", "hp": 1.3, "count": 1.15, "speed": 1.05, "dmg": 1.15, "boss_hp": 1.35, "millet": 1.35, "feathers": 1, "color": Color("c98a1e")},
	{"name": "Сложная", "short": "сложная комната", "acc": "сложную комнату", "prep": "сложной комнате", "hp": 1.65, "count": 1.3, "speed": 1.1, "dmg": 1.3, "boss_hp": 1.75, "millet": 1.8, "feathers": 2, "color": Color("b23a2e")},
]

## Что нового у врагов на каждой ступени (копится: на сложной действует всё сразу).
const TRAITS := [
	[],
	[
		["Носки уворачиваются", "иногда носок отскакивает от удара"],
		["Тапки в броне", "броня тапка гасит первый удар"],
		["Липкие брызги", "брызги пульверизатора замедляют Кешу"],
		["Пылесос пылит", "после рывка остаются облака пыли, а плевок — 9 пылинок"],
	],
	[
		["Клубки делятся", "разбитый клубок распадается на два маленьких"],
		["Двойной рывок", "суперноски прыгают дважды подряд"],
		["Быстрая рука", "рука хватает почти без замаха"],
		["Броня восстанавливается", "броня тапка возвращается через 6 с"],
		["Перегрев пылесоса", "на половине здоровья пылесос ускоряется, рвётся дважды и оставляет искры"],
	],
]


static func level(d: int) -> Dictionary:
	return LEVELS[clampi(d, 0, LEVELS.size() - 1)]


static func data(meta: Dictionary) -> Dictionary:
	if not meta.has("diff"):
		meta["diff"] = {"unlocked": 0, "next": 0, "hist": {}, "reason": "", "beaten": 0}
	return meta["diff"]


static func unlocked(meta: Dictionary) -> int:
	return int(data(meta)["unlocked"])


static func next_diff(meta: Dictionary) -> int:
	return clampi(int(data(meta)["next"]), 0, unlocked(meta))


static func hist(meta: Dictionary, d: int) -> Dictionary:
	var h: Dictionary = data(meta)["hist"]
	var k := str(d)
	if not h.has(k):
		h[k] = {"runs": 0, "wins": 0, "time": 0.0, "last_time": -1.0, "last_won": false}
	return h[k]


## Итоги забега: история по сложности и открытие следующей.
static func record(meta: Dictionary, d: int, won: bool, t: float) -> String:
	var h := hist(meta, d)
	h["runs"] = int(h["runs"]) + 1
	h["wins"] = int(h["wins"]) + (1 if won else 0)
	h["time"] = float(h["time"]) + t
	h["last_time"] = t
	h["last_won"] = won
	var dd := data(meta)
	if won and d == unlocked(meta):
		if d + 1 < LEVELS.size():
			dd["unlocked"] = d + 1
			return "Открыта %s комната!" % String(LEVELS[d + 1]["name"]).to_lower()
		elif int(dd.get("beaten", 0)) == 0:
			dd["beaten"] = 1
			return "Комната пройдена целиком! Следующая локация — кухня (скоро)."
	return ""


## Кеша сам выбирает, куда идти: оценивает, сколько проса он там соберёт, с поправкой
## на то, как долго там выживал. Новая сложность манит (он ещё не знает, насколько там тяжело),
## но если быстро попался — вернётся подкачаться на предыдущую.
static func choose(meta: Dictionary, greed: float) -> int:
	var top := unlocked(meta)
	var best := 0
	var bv := -INF
	var why := ""
	for d in top + 1:
		var h := hist(meta, d)
		var n := int(h["runs"])
		var surv := 0.85
		var winr := 0.5
		if n > 0:
			# свежий опыт весит больше: среднее с последним забегом
			var avg := float(h["time"]) / float(n) / 300.0
			surv = clampf(0.5 * avg + 0.5 * float(h["last_time"]) / 300.0, 0.0, 1.0)
			winr = (float(h["wins"]) + 0.5) / (float(n) + 1.0)
		var v := float(LEVELS[d]["millet"]) * (0.25 + 0.75 * surv) * (0.6 + winr)
		if n == 0:
			v += 0.6 + 0.4 * greed
		elif float(h["last_time"]) < 150.0 and not bool(h["last_won"]):
			v *= 0.55
		v += randf_range(-0.12, 0.12)
		if v > bv:
			bv = v
			best = d
	var hb := hist(meta, best)
	if int(hb["runs"]) == 0:
		why = "Новая комната! Не знаю, что там, но проса должно быть больше."
	elif best < top and float(hist(meta, top)["last_time"]) < 150.0 and not bool(hist(meta, top)["last_won"]):
		why = "В %s меня быстро поймали. Подкачаюсь пока в %s." % [LEVELS[top]["prep"], LEVELS[best]["prep"]]
	elif best == top:
		why = "Иду в %s: там больше проса." % LEVELS[best]["acc"]
	else:
		why = "В %s надёжнее." % LEVELS[best]["prep"]
	data(meta)["next"] = best
	data(meta)["reason"] = why
	return best
