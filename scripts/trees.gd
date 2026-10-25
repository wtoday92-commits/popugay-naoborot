class_name Trees
extends RefCounted
## Штаб игрока: открывается, когда куплены все 6 базовых исследований.
## У каждого умения 3 ветки по 7 узлов: корень → 2 боковых → ключевой → 2 боковых → вершина.
## До ключевого и до вершины можно дойти через любой из двух боковых узлов, как в деревьях диаблоидов.
## Ключевые узлы и вершины сначала надо «заслужить» условием, потом купить за перья.
## В забеге работают только деревья двух выбранных «усиленных» умений.

const ABIL := ["throw", "ram", "millet", "book", "basket"]
const ABIL_NAMES := {"throw": "Рогатка", "ram": "Таран", "millet": "Подмена проса", "book": "Книга", "basket": "Клетка"}
const ABIL_ICON := {"throw": "grab", "ram": "ram", "millet": "millet", "book": "book", "basket": "basket"}

## Цены по позиции узла в ветке (за каждый уровень).
const COSTS := [[5, 8, 11], [10, 15], [10, 15], [22], [16, 24], [16, 24], [45]]
## Сколько куплено узлов в штабе — когда открываются следующие деревья, вкладка волн и второй слот усиления.
const OPEN_AT := {"throw": 0, "ram": 3, "book": 7, "millet": 11, "basket": 15}
const WAVES_AT := 3
const SECOND_SLOT_AT := 7

## Узел: [название, описание, стат, значение за уровень, уровней, условие или []]
## Условие: [счётчик игрока, цель, текст].
const BRANCHES := {
	"throw": [
		{"key": "sock", "name": "Носок", "nodes": [
			["Плотная вязка", "+20% урона носком", "sock_dmg", 0.2, 3, []],
			["Длинная резинка", "+15% к натягу и скорости броска", "sling_len", 0.15, 2, []],
			["Незаметный бросок", "попугай на 10% реже уворачивается от броска", "throw_sneak", 0.1, 2, []],
			["Огненный носок", "носок разгорается в полёте: чем дальше летит, тем больнее", "fire", 1.0, 1, ["sock_hits", 40, "попасть носком 40 раз"]],
			["Жаркое пламя", "+25% урона огненного носка", "fire_dmg", 0.25, 2, []],
			["Поджог", "огненный носок поджигает: 1,5 урона в секунду 3 с", "burn", 1.5, 2, []],
			["Носочный залп", "носок летит тройкой веером", "volley", 1.0, 1, ["fire_hits", 15, "15 раз попасть огненным носком"]],
		]},
		{"key": "slipper", "name": "Тапок", "nodes": [
			["Подошва", "+25% урона тапком", "slipper_dmg", 0.25, 3, []],
			["Тяжёлый каблук", "+0,25 с оглушения от тапка", "slipper_stun", 0.25, 2, []],
			["Лёгкий тапок", "тапок летит на 15% быстрее", "slipper_fast", 0.15, 2, []],
			["Тапок-выбивала", "тапок выбивает из попугая фрукт, издалека два", "knock", 1.0, 1, ["slipper_hits", 15, "попасть тапком 15 раз"]],
			["Ещё фрукт", "+30% шанс выбить лишний фрукт", "knock_more", 0.3, 2, []],
			["Метка тапка", "попавший тапок помечает попугая на 2 с: ваш урон +25%", "slipper_mark", 2.0, 2, []],
			["Тапок-бумеранг", "после попадания тапок возвращается в лапку: сразу новый бросок", "boomerang", 1.0, 1, ["fruits_knocked", 10, "выбить 10 фруктов"]],
		]},
		{"key": "sling", "name": "Рогатка", "nodes": [
			["Быстрая перезарядка", "−0,3 с отката рогатки", "throw_cd", 0.3, 3, []],
			["Цепкая хватка", "+1 с, пока предмет можно держать", "hold", 1.0, 2, []],
			["Широкая лапка", "хватает предметы с большего расстояния", "grab_r", 10.0, 2, []],
			["Рикошет", "предмет отскакивает от мебели и летит дальше", "ricochet", 1.0, 1, ["throws", 100, "сделать 100 бросков"]],
			["Оглушение", "+0,2 с оглушения от любого броска", "throw_stun", 0.2, 2, []],
			["Выбить опыт", "попадание выбивает у попугая 2 опыта", "throw_xp", 2.0, 2, []],
			["Двойная рогатка", "два заряда: второй бросок можно сделать сразу", "twin", 1.0, 1, ["wins", 3, "победить попугая 3 раза"]],
		]},
	],
	"ram": [
		{"key": "claws", "name": "Когти", "nodes": [
			["Когти", "таран ранит: +4 урона", "ram_dmg", 4.0, 3, []],
			["Тяжёлая лапа", "+30% к отбрасыванию", "ram_knock", 0.3, 2, []],
			["Быстрое заживление", "лапка заживает на 0,6 с быстрее", "ram_bruise", 0.6, 2, []],
			["Об стену!", "таран у стены или мебели: +10 урона и оглушение 0,8 с", "wallslam", 1.0, 1, ["rams", 30, "протаранить попугая 30 раз"]],
			["Твёрдая стена", "+5 урона удара об стену", "wall_dmg", 5.0, 2, []],
			["Долгое оглушение", "+0,25 с оглушения от тарана", "ram_stun", 0.25, 2, []],
			["Двойной удар", "после тарана лапка 2 с не ушиблена: можно ударить снова", "combo", 1.0, 1, ["rams_run", 8, "8 таранов за один забег"]],
		]},
		{"key": "agility", "name": "Ловкость", "nodes": [
			["Лёгкий замах", "таран срабатывает при меньшей скорости мыши", "ram_easy", 0.08, 3, []],
			["Широкая лапа", "попасть тараном проще", "paw_wide", 6.0, 2, []],
			["Внезапность", "попугай на 12% реже уворачивается от лапки", "ram_sneak", 0.12, 2, []],
			["Головокружение", "после тарана попугай 2 с замедлен на 40%", "dizzy", 1.0, 1, ["rams", 60, "протаранить попугая 60 раз"]],
			["Долгое кружение", "+1 с головокружения", "dizzy_len", 1.0, 2, []],
			["Сбить с мысли", "таран сбивает внимание попугая и добавляет стресса", "ram_forget", 0.15, 2, []],
			["Лапа-призрак", "от тарана не увернуться, по оглушённому — двойной урон", "ghost", 1.0, 1, ["ram_trapped", 3, "протаранить пойманного попугая 3 раза"]],
		]},
		{"key": "horde", "name": "Клич", "nodes": [
			["Клич", "после тарана враги рядом бросаются на попугая", "rush", 1.0, 3, []],
			["Ярость стаи", "+20% скорости бросившихся врагов", "rush_speed", 0.2, 2, []],
			["Долгий клич", "+0,7 с ярости стаи", "rush_len", 0.7, 2, []],
			["Кошачья метка", "таран помечает попугая на 3 с: орда бьёт на 30% сильнее", "ram_mark", 1.0, 1, ["rams", 40, "протаранить попугая 40 раз"]],
			["Глубокая метка", "+15% урона орды по метке", "mark_horde", 0.15, 2, []],
			["Длинная метка", "+1 с метки", "mark_len", 1.0, 2, []],
			["Хоровод", "таран вызывает 6 носков вокруг попугая", "swarm", 1.0, 1, ["wins", 5, "победить попугая 5 раз"]],
		]},
	],
	"millet": [
		{"key": "trap", "name": "Капкан", "nodes": [
			["Тугая пружина", "+0,3 с капкана", "trap_time", 0.3, 3, []],
			["Зубчатый капкан", "капкан ранит на 4", "trap_dmg", 4.0, 2, []],
			["Быстрая подмена", "−3 с отката подмены", "millet_cd", 3.0, 2, []],
			["Ржавый капкан", "капкан оставляет рану: 2 урона в секунду 4 с", "trap_bleed", 1.0, 1, ["traps", 15, "поймать попугая капканом 15 раз"]],
			["Глубокая рана", "+1 урон в секунду от раны", "bleed_dps", 1.0, 2, []],
			["Пометка", "капкан помечает попугая на 2 с: ваш урон +25%", "trap_mark", 2.0, 2, []],
			["Капканная дорожка", "сработавший капкан прячет ещё 2 в просе рядом", "trap_path", 1.0, 1, ["trap_time", 40, "держать попугая в капканах 40 с"]],
		]},
		{"key": "rotten", "name": "Тухлое", "nodes": [
			["Совсем тухлое", "+4 урона тухлого проса", "rotten_dmg", 4.0, 3, []],
			["Тошнота", "тухлое замедляет попугая на 1,5 с", "rotten_slow", 1.5, 2, []],
			["Быстрая подмена", "−3 с отката подмены", "millet_cd", 3.0, 2, []],
			["Отравление", "тухлое отнимает 30% опыта до уровня", "rotten_xp", 1.0, 1, ["rottens", 15, "накормить попугая тухлым 15 раз"]],
			["Сильный яд", "+15% отнятого опыта", "rotten_xp_more", 0.15, 2, []],
			["Вонь", "облако вони: 2 урона в секунду 3 с", "stink", 2.0, 2, []],
			["Гнилой урожай", "следующие 5 колосков у попугая тоже тухлые: без опыта и −3 здоровья", "rot_harvest", 1.0, 1, ["swaps", 60, "подменить просо 60 раз"]],
		]},
		{"key": "missile", "name": "Снаряд и яйцо", "nodes": [
			["Тяжёлое зерно", "+4 урона снаряда", "missile_dmg", 4.0, 3, []],
			["Упругое зерно", "+2 отскока снаряда", "missile_bounce", 2.0, 2, []],
			["Быстрое зерно", "снаряд на 20% быстрее", "missile_speed", 0.2, 2, []],
			["Два яйца", "из подложенного яйца вылупляются двое", "egg_twin", 1.0, 1, ["eggs", 10, "подложить попугаю 10 яиц"]],
			["Злые птенцы", "+30% здоровья птенцов", "egg_hp", 0.3, 2, []],
			["Оглушающее зерно", "снаряд оглушает на 0,3 с", "missile_stun", 0.3, 2, []],
			["Просяной град", "снаряд на первом отскоке делится на три", "hail", 1.0, 1, ["missile_hits", 15, "попасть снарядом 15 раз"]],
		]},
	],
	"book": [
		{"key": "heavy", "name": "Тяжёлый том", "nodes": [
			["Толстый том", "+3% от здоровья попугая", "book_dmg", 0.03, 3, []],
			["Большой формат", "+12% радиуса книги", "book_r", 0.12, 2, []],
			["Ближе полка", "−1 с отката книги", "book_cd", 1.0, 2, []],
			["Энциклопедия", "книга оглушает попугая на 1 с", "book_stun", 1.0, 1, ["book_hits", 15, "попасть книгой 15 раз"]],
			["Твёрдый переплёт", "+0,3 с оглушения книгой", "book_stun_len", 0.3, 2, []],
			["Ещё толще", "+3% от здоровья попугая", "book_dmg", 0.03, 2, []],
			["Второй том", "через секунду падает второй том туда, куда бежит попугай", "book_second", 1.0, 1, ["book_hits", 40, "попасть книгой 40 раз"]],
		]},
		{"key": "sneaky", "name": "Тихая полка", "nodes": [
			["Быстрое падение", "книга падает на 0,08 с быстрее", "book_fast", 0.08, 3, []],
			["Бледная тень", "попугай замечает тень книги позже", "book_hide", 0.15, 2, []],
			["Ближе полка", "−1 с отката книги", "book_cd", 1.0, 2, []],
			["Ложная тень", "рядом появляется ложная тень: попугай шарахается прямо под книгу", "book_fake", 1.0, 1, ["book_dodged", 20, "попугай увернулся от книги 20 раз"]],
			["Ещё тень", "+1 ложная тень", "book_fake_n", 1.0, 2, []],
			["Тише", "попугай замечает тень ещё позже", "book_hide", 0.15, 2, []],
			["Книжный дождь", "Q роняет три книги треугольником", "book_rain", 1.0, 1, ["book_casts", 60, "уронить 60 книг"]],
		]},
		{"key": "dust", "name": "Пыль страниц", "nodes": [
			["Пыльные страницы", "пыль замедляет попугая рядом с местом удара на 1 с", "book_dust", 1.0, 3, []],
			["Мягкий переплёт", "книга больше не оглушает врагов: орда не отвлекается", "book_soft", 1.0, 1, []],
			["Закладка", "книга помечает попугая на 2 с: ваш урон +25%", "book_mark", 2.0, 2, []],
			["Сквозняк", "книга стягивает врагов к месту удара", "book_pull", 1.0, 1, ["book_near", 25, "уронить книгу в 2 м от попугая 25 раз"]],
			["Сильный сквозняк", "+50% силы сквозняка", "pull_more", 0.5, 2, []],
			["Пыльная буря", "пыль замедляет ещё на 1 с", "book_dust", 1.0, 2, []],
			["Библиотекарь", "когда у попугая меньше половины здоровья, книга перезаряжается вдвое быстрее", "librarian", 1.0, 1, ["wins", 5, "победить попугая 5 раз"]],
		]},
	],
	"basket": [
		{"key": "cage", "name": "Прутья", "nodes": [
			["Крепкие прутья", "+0,4 с в клетке", "cage_time", 0.4, 3, []],
			["Шире клетка", "+12% радиуса клетки", "cage_r", 0.12, 2, []],
			["Ловкий прицел", "клетка ползёт за курсором на 30% быстрее", "cage_follow", 0.3, 2, []],
			["Прутья под током", "в клетке попугай получает 4 урона в секунду", "cage_shock", 1.0, 1, ["cage_time", 30, "держать попугая в клетке 30 с"]],
			["Сильный ток", "+2 урона в секунду в клетке", "shock_dps", 2.0, 2, []],
			["Быстрая клетка", "−3 с отката клетки", "cage_cd", 3.0, 2, []],
			["Ворованное просо", "пока попугай в клетке, просо вокруг разлетается от него", "cage_scatter", 1.0, 1, ["cage_time", 120, "держать попугая в клетке 120 с"]],
		]},
		{"key": "shadow", "name": "Тень", "nodes": [
			["Быстрое падение", "клетка падает на 0,15 с быстрее", "cage_fast", 0.15, 3, []],
			["Тусклая тень", "попугай замечает клетку позже", "cage_hide", 0.2, 2, []],
			["Шире клетка", "+12% радиуса клетки", "cage_r", 0.12, 2, []],
			["Ловчая тень", "под тенью клетки попугай замедлен на 30%", "cage_slow", 1.0, 1, ["baskets", 30, "уронить клетку 30 раз"]],
			["Вязкая тень", "+15% замедления под тенью", "cage_slow_more", 0.15, 2, []],
			["Ещё быстрее", "клетка падает на 0,15 с быстрее", "cage_fast", 0.15, 2, []],
			["Охотник", "клетка ползёт вдвое быстрее, тень видна только в последние 0,6 с", "hunter", 1.0, 1, ["caught", 15, "поймать попугая клеткой 15 раз"]],
		]},
		{"key": "laundry", "name": "Бельё", "nodes": [
			["Носки внутри", "при поимке в клетке появляется носок за уровень", "cage_socks", 1.0, 3, []],
			["Тесно", "поимка добавляет попугаю 15% стресса", "cage_stress", 0.15, 2, []],
			["Быстрая клетка", "−3 с отката клетки", "cage_cd", 3.0, 2, []],
			["Бельевая лавина", "при падении клетки вокруг высыпается кольцо из 6 носков", "laundry", 1.0, 1, ["caught", 8, "поймать попугая клеткой 8 раз"]],
			["Больше белья", "+3 носка в лавине", "laundry_n", 3.0, 2, []],
			["Злые носки", "носки из клетки на 25% быстрее", "laundry_fast", 0.25, 2, []],
			["Стиральная машина", "после клетки попугай 3 с кружится (−50% скорости) и роняет фрукт", "washer", 1.0, 1, ["wins", 8, "победить попугая 8 раз"]],
		]},
	],
}

## Ряд и колонка узла по индексу в ветке: 0 — корень, 3 — ключевой, 6 — вершина.
const LAYOUT := [Vector2(0, 0), Vector2(-1, 1), Vector2(1, 1), Vector2(0, 2), Vector2(-1, 3), Vector2(1, 3), Vector2(0, 4)]

## Волны: игрок расставляет состав каждого 30-секундного отрезка до пылесоса.
const SEGMENTS := 8
const PACKS := [
	{"key": "mix", "name": "Смесь", "desc": "обычный состав", "cost": 0, "cond": []},
	{"key": "socks", "name": "Носочный вал", "desc": "только носки, на 15% больше", "cost": 0, "cond": []},
	{"key": "slippers", "name": "Тапочный марш", "desc": "много тапок, врагов на 25% меньше", "cost": 15, "cond": []},
	{"key": "yarn", "name": "Клубочный рой", "desc": "рои клубков каждые 10 с", "cost": 20, "cond": []},
	{"key": "spray", "name": "Брызгалки", "desc": "треть орды — брызгалки", "cost": 25, "cond": ["throws", 60, "сделать 60 бросков"]},
	{"key": "calm", "name": "Затишье", "desc": "врагов вдвое меньше, следующий отрезок на 35% гуще", "cost": 30, "cond": ["wins", 2, "победить попугая 2 раза"]},
]


static func defaults() -> Dictionary:
	return {"nodes": {}, "enh": [], "waves": [], "packs": {"mix": true, "socks": true}}


static func hq(meta: Dictionary) -> Dictionary:
	if not meta.has("hq"):
		meta["hq"] = defaults()
	var h: Dictionary = meta["hq"]
	for k in defaults():
		if not h.has(k):
			h[k] = defaults()[k]
	while h["waves"].size() < SEGMENTS:
		h["waves"].append("mix")
	return h


## Штаб открыт, когда куплены все базовые исследования.
static func hq_open(meta: Dictionary) -> bool:
	if Diff.unlocked(meta) < 2:
		return false
	for it in Meta.PLAYER:
		if not Meta.unlocked(meta, it["key"]):
			return false
	return true


static func node_id(ab: String, bi: int, ni: int) -> String:
	return "%s.%d.%d" % [ab, bi, ni]


static func lvl(meta: Dictionary, id: String) -> int:
	return int(hq(meta)["nodes"].get(id, 0))


static func bought_total(meta: Dictionary) -> int:
	var n := 0
	for k in hq(meta)["nodes"]:
		n += int(hq(meta)["nodes"][k])
	return n


static func tree_open(meta: Dictionary, ab: String) -> bool:
	return hq_open(meta) and bought_total(meta) >= int(OPEN_AT[ab])


static func waves_open(meta: Dictionary) -> bool:
	return hq_open(meta) and bought_total(meta) >= WAVES_AT


static func enh_slots(meta: Dictionary) -> int:
	return 2 if bought_total(meta) >= SECOND_SLOT_AT else 1


static func node(ab: String, bi: int, ni: int) -> Array:
	return BRANCHES[ab][bi]["nodes"][ni]


## Узел доступен по дереву: корень всегда, боковые — после корня, ключевой — после любого бокового и т.д.
static func reachable(meta: Dictionary, ab: String, bi: int, ni: int) -> bool:
	var L := func(i: int) -> int: return lvl(meta, node_id(ab, bi, i))
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


static func cond_progress(meta: Dictionary, cond: Array) -> float:
	if cond.is_empty():
		return 1.0
	return clampf(float(pstat(meta, cond[0])) / float(cond[1]), 0.0, 1.0)


static func pstat(meta: Dictionary, k: String) -> int:
	return int(meta.get("pstats", {}).get(k, 0))


static func cost(ni: int, cur: int) -> int:
	var c: Array = COSTS[ni]
	return int(c[mini(cur, c.size() - 1)])


## Почему нельзя купить: "" — можно.
static func why_not(meta: Dictionary, feathers: int, ab: String, bi: int, ni: int) -> String:
	var n := node(ab, bi, ni)
	var cur := lvl(meta, node_id(ab, bi, ni))
	if cur >= int(n[4]):
		return "максимум"
	if not reachable(meta, ab, bi, ni):
		return "сначала узел выше"
	if cond_progress(meta, n[5]) < 1.0:
		return "условие: " + String(n[5][2])
	if feathers < cost(ni, cur):
		return "не хватает перьев"
	return ""


## Сумма статов из деревьев усиленных умений — то, что работает в забеге.
static func perks(meta: Dictionary) -> Dictionary:
	var out := {}
	if not hq_open(meta):
		return out
	for ab in hq(meta)["enh"]:
		if not BRANCHES.has(ab):
			continue
		for bi in BRANCHES[ab].size():
			for ni in 7:
				var l := lvl(meta, node_id(ab, bi, ni))
				if l > 0:
					var n := node(ab, bi, ni)
					out[n[2]] = float(out.get(n[2], 0.0)) + float(n[3]) * l
	return out


static func toggle_enh(meta: Dictionary, ab: String) -> void:
	var e: Array = hq(meta)["enh"]
	if e.has(ab):
		e.erase(ab)
	elif tree_open(meta, ab):
		e.append(ab)
		while e.size() > enh_slots(meta):
			e.pop_front()


## Составы: обычные и по одному на каждый выбитый юнит.
static func all_packs(meta: Dictionary) -> Array:
	var out: Array = PACKS.duplicate()
	for u in Units.LIST:
		if Units.owned(meta).has(u["key"]):
			out.append({"key": "u_" + u["key"], "name": u["plural"], "desc": u["desc"], "cost": 0, "cond": [], "unit": true})
	return out


static func pack(key: String) -> Dictionary:
	for p in PACKS:
		if p["key"] == key:
			return p
	if key.begins_with("u_"):
		var u := Units.by_key(key.substr(2))
		if not u.is_empty():
			return {"key": key, "name": u["plural"], "desc": u["desc"], "cost": 0, "cond": [], "unit": true}
	return PACKS[0]


static func pack_owned(meta: Dictionary, key: String) -> bool:
	if key.begins_with("u_"):
		return Units.owned(meta).has(key.substr(2))
	return hq(meta)["packs"].has(key)


## Состав отрезка: что идёт в каждые 30 с до пылесоса.
static func wave_at(meta: Dictionary, t: float) -> String:
	if not waves_open(meta):
		return "mix"
	var seg := int(t / 30.0)
	if seg < 0 or seg >= SEGMENTS:
		return "mix"
	var k := String(hq(meta)["waves"][seg])
	return k if pack_owned(meta, k) else "mix"


## Бот прогона прогрессии: выбирает усиленные умения и покупает самый дешёвый доступный узел.
static func bot_buy(meta: Dictionary, save: Dictionary, prefer: Array) -> void:
	var h := hq(meta)
	for ab in prefer:
		if h["enh"].size() < enh_slots(meta) and tree_open(meta, ab) and not h["enh"].has(ab):
			h["enh"].append(ab)
	var guard := 0
	while guard < 50:
		guard += 1
		var best := []
		var bc := 99999
		for ab in h["enh"]:
			for bi in 3:
				for ni in 7:
					if why_not(meta, int(save["feathers"]), ab, bi, ni) == "":
						var c := cost(ni, lvl(meta, node_id(ab, bi, ni)))
						# ключевые узлы и вершины в приоритете
						var w := c - (20 if ni == 3 or ni == 6 else 0)
						if w < bc:
							bc = w
							best = [ab, bi, ni]
		if best.is_empty():
			# открыть следующее дерево, если усиление ещё не выбрано
			for ab in prefer:
				if h["enh"].size() < enh_slots(meta) and tree_open(meta, ab) and not h["enh"].has(ab):
					h["enh"].append(ab)
			break
		var id := node_id(best[0], best[1], best[2])
		save["feathers"] = int(save["feathers"]) - cost(best[2], lvl(meta, id))
		h["nodes"][id] = lvl(meta, id) + 1
