class_name Units
extends RefCounted
## Новые юниты комнаты: сверхредкая награда игроку из яйца. Выбитые юниты иногда сами
## попадаются в волнах, а со штабом их можно ставить в состав орды.

const LIST := [
	{"key": "remote", "type": 9, "name": "Пульт", "plural": "Пульты", "desc": "телепортируется поближе к попугаю"},
	{"key": "pillow", "type": 10, "name": "Подушка", "plural": "Подушки", "desc": "толстая, не отлетает, при смерти — облако пуха, вязнешь"},
	{"key": "ball", "type": 11, "name": "Мячик", "plural": "Мячики", "desc": "носится по прямой и отскакивает от стен"},
	{"key": "cable", "type": 12, "name": "Провод", "plural": "Провода", "desc": "ползёт змейкой и бьёт током рядом"},
	{"key": "alarm", "type": 13, "name": "Будильник", "plural": "Будильники", "desc": "звонит и подгоняет орду вокруг"},
	{"key": "sponge", "type": 14, "name": "Губка", "plural": "Губки", "desc": "держится позади и лечит врагов"},
	{"key": "car", "type": 15, "name": "Заводная машинка", "plural": "Машинки", "desc": "кружит рядом и врезается с разгона"},
]


static func by_key(k: String) -> Dictionary:
	for u in LIST:
		if u["key"] == k:
			return u
	return {}


static func owned(meta: Dictionary) -> Array:
	if not meta.has("units"):
		meta["units"] = []
	return meta["units"]


static func missing(meta: Dictionary) -> Array:
	var out: Array = []
	for u in LIST:
		if not owned(meta).has(u["key"]):
			out.append(u["key"])
	return out
