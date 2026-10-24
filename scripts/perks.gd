class_name Perks
extends RefCounted
## Игрушки (оружие) и пассивки попугая, и как герой оценивает их при левелапе.

const WEAPONS := ["peck", "feather", "bell", "mirror", "scream"]
const PASSIVES := ["wings", "fluff", "shell", "magnet", "beak"]
const MAX_W := 5
const MAX_P := 3
const W_SLOTS := 4
const P_SLOTS := 3

const NAMES := {
	"peck": "Клевок",
	"feather": "Перья",
	"bell": "Колокольчик",
	"mirror": "Зеркальце",
	"scream": "Крик",
	"wings": "Лёгкие крылья",
	"fluff": "Пух",
	"shell": "Скорлупка",
	"magnet": "Кормушка-магнит",
	"beak": "Крепкий клюв",
}

const DESC := {
	"peck": "удар клювом рядом",
	"feather": "летящие перья",
	"bell": "аура звона",
	"mirror": "солнечный зайчик-луч",
	"scream": "волна крика",
	"wings": "+12% скорости",
	"fluff": "+20 здоровья",
	"shell": "−1 урон от ударов",
	"magnet": "+35% радиус сбора",
	"beak": "+12% урона",
}

## База: сила карты по таблице тиров (1–10).
const TIER := {
	"peck": 5.0, "feather": 6.0, "bell": 6.0, "mirror": 5.5, "scream": 5.0,
	"wings": 4.0, "fluff": 4.0, "shell": 4.0, "magnet": 3.0, "beak": 4.5,
}

## Ответ на игрока: от чего получал урон → что начинает ценить.
const RESPONSE := {
	"meteor": ["wings", "shell"],
	"swarm": ["bell", "scream"],
	"tank": ["mirror", "feather", "beak"],
	"shooter": ["feather", "fluff"],
}
const RESPONSE_TEXT := {
	"meteor": "меня бьют книги и лапка",
	"swarm": "толпа давит",
	"tank": "толстые враги",
	"shooter": "меня обстреливают",
}

const AREA := ["bell", "scream"]
const SINGLE := ["mirror", "feather", "beak"]


static func is_weapon(k: String) -> bool:
	return WEAPONS.has(k)


static func category(src: String) -> String:
	match src:
		"meteor", "paw":
			return "meteor"
		"sock", "ball":
			return "swarm"
		"slipper", "hand":
			return "tank"
		"sprayer":
			return "shooter"
	return "swarm"
