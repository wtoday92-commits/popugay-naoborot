class_name Skills
extends RefCounted
## Умения и пассивки попугая. На старте: не больше 3 умений, 3 общих пассивок
## и по одной особой пассивке на каждое взятое умение (из 5 вариантов).

const SKILLS := ["feather", "bell", "mirror", "scream", "orbit", "zap"]
const GENERAL := ["wings", "fluff", "shell", "magnet", "beak", "luck"]
const MAX_SKILLS := 3
const MAX_GENERAL := 3
const MAX_SKILL_LVL := 5
const MAX_GEN_LVL := 3

## Особые пассивки: меняют, как работает конкретное умение.
const MODS := {
	"feather": ["feather_bounce", "feather_fan", "feather_pierce", "feather_homing", "feather_ice"],
	"bell": ["bell_wide", "bell_stun", "bell_pull", "bell_push", "bell_armor"],
	"mirror": ["mirror_chain", "mirror_double", "mirror_burn", "mirror_long", "mirror_blind"],
	"scream": ["scream_echo", "scream_stun", "scream_wide", "scream_fast", "scream_fear"],
	"orbit": ["orbit_more", "orbit_fast", "orbit_wide", "orbit_knock", "orbit_fire"],
	"zap": ["zap_chain", "zap_stun", "zap_fork", "zap_fast", "zap_long"],
}

const NAMES := {
	"peck": "Клевок",
	"feather": "Перья",
	"bell": "Колокольчик",
	"mirror": "Зеркальце",
	"scream": "Крик",
	"orbit": "Карусель",
	"zap": "Искра",
	"wings": "Лёгкие крылья",
	"fluff": "Пух",
	"shell": "Скорлупка",
	"magnet": "Магнит",
	"beak": "Крепкий клюв",
	"luck": "Счастливое перо",
	"feather_bounce": "Рикошет",
	"feather_fan": "Веер",
	"feather_pierce": "Насквозь",
	"feather_homing": "Самонаведение",
	"feather_ice": "Ледяные перья",
	"bell_wide": "Громкий звон",
	"bell_stun": "Оглушающий звон",
	"bell_pull": "Манящий звон",
	"bell_push": "Отталкивающий звон",
	"bell_armor": "Звонкая броня",
	"mirror_chain": "Отражения",
	"mirror_double": "Двойной зайчик",
	"mirror_burn": "Прожигание",
	"mirror_long": "Дальний луч",
	"mirror_blind": "Ослепление",
	"scream_echo": "Эхо",
	"scream_stun": "Оглушающий крик",
	"scream_wide": "Ор на всю комнату",
	"scream_fast": "Частый крик",
	"scream_fear": "Испуг",
	"orbit_more": "Больше игрушек",
	"orbit_fast": "Быстрая карусель",
	"orbit_wide": "Широкий круг",
	"orbit_knock": "Тяжёлые игрушки",
	"orbit_fire": "Горячие игрушки",
	"zap_chain": "Длинная цепь",
	"zap_stun": "Удар током",
	"zap_fork": "Развилка",
	"zap_fast": "Наэлектризованный пух",
	"zap_long": "Дальний разряд",
}

const DESC := {
	"peck": "бьёт клювом ближайшего",
	"feather": "стреляет перьями",
	"bell": "аура звона вокруг",
	"mirror": "солнечный луч насквозь",
	"scream": "волна крика по кругу",
	"orbit": "игрушки кружат вокруг",
	"zap": "статическая искра скачет по врагам",
	"wings": "+12% скорости",
	"fluff": "+20 здоровья",
	"shell": "−1 урон от ударов",
	"magnet": "+35% радиус сбора",
	"beak": "+12% урона",
	"luck": "+8% шанс двойного урона",
	"feather_bounce": "перья отскакивают от стен",
	"feather_fan": "+2 пера веером",
	"feather_pierce": "+3 пробивания",
	"feather_homing": "перья доворачивают к цели",
	"feather_ice": "замедляют врагов",
	"bell_wide": "аура шире на 40%",
	"bell_stun": "раз в 3 с оглушает",
	"bell_pull": "тянет врагов в ауру",
	"bell_push": "раз в 2 с отбрасывает",
	"bell_armor": "−30% урона, если рядом враги",
	"mirror_chain": "луч отражается на 2 врагов",
	"mirror_double": "второй луч назад",
	"mirror_burn": "оставляет горящую полосу",
	"mirror_long": "луч длиннее и шире",
	"mirror_blind": "оглушает на 0,6 с",
	"scream_echo": "повтор крика через 0,5 с",
	"scream_stun": "оглушает на 0,5 с",
	"scream_wide": "радиус +35%",
	"scream_fast": "откат −35%",
	"scream_fear": "враги убегают 1,5 с",
	"orbit_more": "+2 игрушки",
	"orbit_fast": "крутятся на 60% быстрее",
	"orbit_wide": "круг шире",
	"orbit_knock": "сильно отбрасывают",
	"orbit_fire": "поджигают врагов",
	"zap_chain": "+3 прыжка искры",
	"zap_stun": "оглушает на 0,3 с",
	"zap_fork": "первая искра раздваивается",
	"zap_fast": "откат −35%",
	"zap_long": "прыжок на 50% дальше",
}

## База: сила карты по таблице тиров (1–10).
const TIER := {
	"feather": 6.0, "bell": 6.0, "mirror": 5.5, "scream": 5.0, "orbit": 5.5, "zap": 5.5,
	"wings": 4.0, "fluff": 4.0, "shell": 4.0, "magnet": 3.0, "beak": 4.5, "luck": 3.5,
}

## Ответ на игрока: от чего получал урон → что начинает ценить.
const RESPONSE := {
	"meteor": ["wings", "shell", "luck"],
	"swarm": ["bell", "scream", "orbit", "zap", "bell_push", "scream_fear", "orbit_knock", "zap_chain"],
	"tank": ["mirror", "feather", "beak", "mirror_burn", "feather_pierce"],
	"shooter": ["feather", "fluff", "feather_homing"],
	"trick": ["magnet", "luck", "shell"],
}
const RESPONSE_TEXT := {
	"meteor": "меня бьют книги и лапка",
	"swarm": "толпа давит",
	"tank": "толстые враги",
	"shooter": "меня обстреливают",
	"trick": "меня обманывают",
}
const AREA := ["bell", "scream", "orbit", "zap"]

## Фрукты и овощи: награды за ивенты, герой съедает их сам по ситуации.
const FRUITS := ["apple", "chili", "carrot", "grape", "lemon"]
const FRUIT_NAMES := {
	"apple": "Яблоко", "chili": "Перец чили", "carrot": "Морковка", "grape": "Виноград", "lemon": "Лимон",
}
const FRUIT_DESC := {
	"apple": "лечит 40",
	"chili": "огненный круг вокруг",
	"carrot": "скорость +50% на 5 с",
	"grape": "мгновенный уровень",
	"lemon": "кислый щит на 3 удара",
}

## Ивенты на карте: игрок может переставлять их в очереди слева.
const EVENTS := ["circle", "glow", "box", "altar"]
const EVENT_NAMES := {
	"circle": "Пятно солнца",
	"glow": "Светящееся просо",
	"box": "Шкатулка-беглянка",
	"altar": "Лакомство на столе",
	"boss": "Робот-пылесос",
}
const EVENT_DESC := {
	"circle": "постоять в пятне и победить 20 врагов",
	"glow": "собрать 5 светящихся зёрен",
	"box": "догнать и разбить шкатулку",
	"altar": "уровень сразу, но орда ×2 на 15 с",
	"boss": "жирный босс со своими умениями",
}


static func is_skill(k: String) -> bool:
	return SKILLS.has(k)


static func is_general(k: String) -> bool:
	return GENERAL.has(k)


static func mod_parent(k: String) -> String:
	var i := k.find("_")
	return k.substr(0, i) if i > 0 else ""


static func category(src: String) -> String:
	match src:
		"meteor", "paw", "throw", "missile":
			return "meteor"
		"sock", "yarn", "dust", "super":
			return "swarm"
		"slipper", "hand", "boss":
			return "tank"
		"sprayer":
			return "shooter"
		"trap", "rotten":
			return "trick"
	return "swarm"
