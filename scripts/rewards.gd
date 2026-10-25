class_name Rewards
extends RefCounted
## Награды из яйца: рулетка с редкостью. Слева — награда игроку, справа — попугаю.

const RARITY := [
	{"key": "common", "name": "Обычная", "col": Color("9aa0a6"), "w": 60.0},
	{"key": "rare", "name": "Редкая", "col": Color("3f8fd8"), "w": 27.0},
	{"key": "epic", "name": "Эпическая", "col": Color("9b59d0"), "w": 10.0},
	{"key": "legendary", "name": "Легендарная", "col": Color("f2b01e"), "w": 3.0},
	{"key": "mythic", "name": "Сверхредкая", "col": Color("e8453c"), "w": 0.0},
]

## Проклятия: одноразовые, игрок включает их перед забегом.
const CURSES := {
	"heavy": {"name": "Тяжёлые лапки", "desc": "попугай на 12% медленнее"},
	"blind": {"name": "Пелена", "desc": "у попугая на 1 слот внимания меньше"},
	"fragile": {"name": "Хрупкие перья", "desc": "у попугая на 25 здоровья меньше"},
	"horde": {"name": "Голодная орда", "desc": "врагов на 25% больше"},
	"hungry": {"name": "Пустой колосок", "desc": "попугай получает на 25% меньше опыта"},
	"quick": {"name": "Шустрые руки", "desc": "откаты ваших умений на 25% короче"},
}
const MAX_ARMED := 2


static func rarity_col(r: int) -> Color:
	return RARITY[r]["col"]


static func _roll_rarity(bonus_leg: float = 0.0) -> int:
	var tot := 0.0
	for r in RARITY:
		tot += float(r["w"])
	tot += bonus_leg
	var x := randf() * tot
	for i in RARITY.size():
		var w := float(RARITY[i]["w"]) + (bonus_leg if i == 3 else 0.0)
		if x < w:
			return i
		x -= w
	return 0


static func missing_skins(save: Dictionary) -> Array:
	var own: Array = save.get("cursors", ["white"])
	var out: Array = []
	for k in PawCursor.SKINS:
		if not own.has(k):
			out.append(k)
	return out


## Проклятия появляются только после того, как комната пройдена целиком (дорога на кухню),
## и выпадают только в забегах на сложной комнате и выше.
static func curses_open(meta: Dictionary) -> bool:
	return int(Diff.data(meta).get("beaten", 0)) > 0


## Награда игроку. {rarity, kind, value, label}. Новые юниты — сверхредкая награда.
static func roll_player(save: Dictionary, meta: Dictionary, diff: int) -> Dictionary:
	var miss_units := Units.missing(meta)
	var since := int(save.get("eggs_since_unit", 0))
	if miss_units.size() > 0 and randf() < 0.012 + 0.003 * float(since):
		save["eggs_since_unit"] = 0
		var u: String = miss_units[randi() % miss_units.size()]
		return {"rarity": 4, "kind": "unit", "value": u, "label": "Новый юнит: %s!" % Units.by_key(u)["name"]}
	save["eggs_since_unit"] = since + 1
	var r := _roll_rarity()
	var curse_ok := curses_open(meta) and diff >= 2
	var keys := CURSES.keys()
	var curse: String = keys[randi() % keys.size()]
	match r:
		0:
			var n := randi_range(4, 6)
			return {"rarity": r, "kind": "feathers", "value": n, "label": "+%d перьев" % n}
		1:
			if curse_ok and randf() < 0.4:
				return {"rarity": r, "kind": "curse", "value": curse, "n": 1, "label": "Проклятие «%s»" % CURSES[curse]["name"]}
			return {"rarity": r, "kind": "feathers", "value": 9, "label": "+9 перьев"}
		2:
			var ms := missing_skins(save)
			if ms.size() > 0:
				var sk: String = ms[randi() % ms.size()]
				return {"rarity": r, "kind": "skin", "value": sk, "feathers": 6, "label": "Новая лапка: %s" % PawCursor.SKINS[sk]["name"]}
			if curse_ok:
				return {"rarity": r, "kind": "curse", "value": curse, "n": 2, "label": "Проклятие «%s» ×2" % CURSES[curse]["name"]}
			return {"rarity": r, "kind": "feathers", "value": 14, "label": "+14 перьев"}
		_:
			var ms := missing_skins(save)
			if ms.size() > 0:
				var sk: String = ms[randi() % ms.size()]
				return {"rarity": r, "kind": "skin", "value": sk, "feathers": 15, "label": "%s и +15 перьев" % PawCursor.SKINS[sk]["name"]}
			return {"rarity": r, "kind": "feathers", "value": 25, "label": "+25 перьев"}


## Награда попугаю: просо, изредка новое умение, совсем редко — новый попугай.
## Чем дольше не было легендарки, тем выше шанс (+0,6% за яйцо).
static func roll_parrot(meta: Dictionary) -> Dictionary:
	var p: Dictionary = meta["parrot"]
	var since := int(p.get("eggs_since_leg", 0))
	var r := _roll_rarity(0.6 * float(since))
	var miss_birds: Array = []
	for b in Parrots.ORDER:
		if not Parrots.owned(meta).has(b):
			miss_birds.append(b)
	var miss_skills: Array = []
	for k in Skills.EGG_SKILLS:
		if not Meta.parrot_skills(meta).has(k):
			miss_skills.append(k)
	if r == 3:
		p["eggs_since_leg"] = 0
		if miss_birds.size() > 0:
			var b: String = miss_birds[randi() % miss_birds.size()]
			return {"rarity": r, "kind": "bird", "value": b, "label": "Новый попугай: %s!" % Parrots.bird(b)["name"]}
		if miss_skills.size() > 0:
			var k: String = miss_skills[randi() % miss_skills.size()]
			return {"rarity": r, "kind": "skill", "value": k, "label": "Умение «%s»" % Skills.NAMES[k]}
		return {"rarity": r, "kind": "millet", "value": 2000, "label": "+2000 проса"}
	p["eggs_since_leg"] = since + 1
	if r == 2 and miss_skills.size() > 0:
		var k: String = miss_skills[randi() % miss_skills.size()]
		return {"rarity": r, "kind": "skill", "value": k, "label": "Умение «%s»" % Skills.NAMES[k]}
	var amount: int = [150, 400, 900][r]
	return {"rarity": r, "kind": "millet", "value": amount, "label": "+%d проса" % amount}


static func apply_player(save: Dictionary, rw: Dictionary) -> void:
	match rw["kind"]:
		"feathers":
			save["feathers"] = int(save.get("feathers", 0)) + int(rw["value"])
		"skin":
			var own: Array = save.get("cursors", ["white"])
			if not own.has(rw["value"]):
				own.append(rw["value"])
			save["cursors"] = own
		"unit":
			var us := Units.owned(save["meta"])
			if not us.has(rw["value"]):
				us.append(rw["value"])
		"curse":
			var cs: Dictionary = save.get("curses", {})
			cs[rw["value"]] = int(cs.get(rw["value"], 0)) + int(rw.get("n", 1))
			save["curses"] = cs
	if rw.has("feathers"):
		save["feathers"] = int(save.get("feathers", 0)) + int(rw["feathers"])


static func apply_parrot(meta: Dictionary, rw: Dictionary) -> void:
	var p: Dictionary = meta["parrot"]
	match rw["kind"]:
		"millet":
			p["bank"] = int(p["bank"]) + int(rw["value"])
		"skill":
			if not p["skills"].has(rw["value"]):
				p["skills"].append(rw["value"])
		"bird":
			var own := Parrots.owned(meta)
			if not own.has(rw["value"]):
				own.append(rw["value"])


## Лента рулетки: случайные награды разной редкости, выпавшая — на позиции STOP.
const STOP := 22


static func reel(final: Dictionary, side: String, curses: bool = false) -> Array:
	var out: Array = []
	for i in STOP + 4:
		var r := _roll_rarity(6.0)
		var it := {"rarity": r}
		if side == "player":
			it["kind"] = ["feathers", "curse" if curses else "feathers", "skin", "unit"][r]
			if it["kind"] == "unit":
				it["rarity"] = 4
				it["value"] = Units.LIST[randi() % Units.LIST.size()]["key"]
			else:
				it["value"] = "" if it["kind"] == "feathers" else (CURSES.keys()[randi() % CURSES.size()] if it["kind"] == "curse" else PawCursor.SKINS.keys()[randi() % PawCursor.SKINS.size()])
		else:
			it["kind"] = ["millet", "millet", "skill", "bird"][r]
			it["value"] = "" if it["kind"] == "millet" else (Skills.EGG_SKILLS[randi() % Skills.EGG_SKILLS.size()] if it["kind"] == "skill" else Parrots.ORDER[1 + randi() % 3])
		out.append(it)
	out[STOP] = final
	return out
