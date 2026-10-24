class_name Skills
extends RefCounted
## Умения и пассивки попугая. На старте: не больше 3 умений, 3 общих пассивок
## и по одной особой пассивке на каждое взятое умение (из 5 вариантов).

const SKILLS := ["feather", "bell", "mirror", "scream", "orbit", "zap",
	"seed", "boomer", "gust", "mines", "song", "nut", "crest", "tornado", "stars", "laser",
	"mimic", "crestfan", "boom"]
## Новые умения: выпадают Кеше из яйца (эпическая награда).
const EGG_SKILLS := ["seed", "boomer", "gust", "mines", "song", "nut", "crest", "tornado", "stars", "laser"]
## Умения конкретных попугаев: в колоде только у своего.
const BIRD_SKILLS := {"mimic": "jaco", "crestfan": "cockatoo", "boom": "kakapo"}
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
	"seed": ["seed_triple", "seed_pierce", "seed_fast"],
	"boomer": ["boomer_two", "boomer_wide", "boomer_slow"],
	"gust": ["gust_wide", "gust_far", "gust_stun"],
	"mines": ["mines_more", "mines_big", "mines_frag"],
	"song": ["song_heal", "song_wide", "song_sleep"],
	"nut": ["nut_two", "nut_big", "nut_stun"],
	"crest": ["crest_more", "crest_fast", "crest_spiky"],
	"tornado": ["tornado_two", "tornado_long", "tornado_pull"],
	"stars": ["stars_more", "stars_big", "stars_burn"],
	"laser": ["laser_chain", "laser_burn", "laser_long"],
	"mimic": ["mimic_double", "mimic_strong", "mimic_fast"],
	"crestfan": ["crestfan_more", "crestfan_stun", "crestfan_far"],
	"boom": ["boom_stun", "boom_wide", "boom_fast"],
}

const NAMES := {
	"peck": "Клевок",
	"feather": "Перья",
	"bell": "Колокольчик",
	"mirror": "Зеркальце",
	"scream": "Крик",
	"orbit": "Карусель",
	"zap": "Искра",
	"seed": "Семечки",
	"boomer": "Перо-бумеранг",
	"gust": "Ветерок",
	"mines": "Скорлупки",
	"song": "Песенка",
	"nut": "Орех",
	"crest": "Хохолок-щит",
	"tornado": "Вихрь",
	"stars": "Звездопад",
	"laser": "Лазерная указка",
	"mimic": "Передразнивание",
	"crestfan": "Веер из гребня",
	"boom": "Бумканье",
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
	"seed_triple": "Тройка семечек",
	"seed_pierce": "Крепкая шелуха",
	"seed_fast": "Скорострел",
	"boomer_two": "Два бумеранга",
	"boomer_wide": "Широкое перо",
	"boomer_slow": "Ледяное перо",
	"gust_wide": "Широкий ветер",
	"gust_far": "Дальний ветер",
	"gust_stun": "Сбивающий ветер",
	"mines_more": "Больше скорлупок",
	"mines_big": "Большой взрыв",
	"mines_frag": "Осколки",
	"song_heal": "Целебная песенка",
	"song_wide": "Громкая песенка",
	"song_sleep": "Колыбельная",
	"nut_two": "Два ореха",
	"nut_big": "Грецкий орех",
	"nut_stun": "Оглушающий орех",
	"crest_more": "Второй щит",
	"crest_fast": "Быстрый хохолок",
	"crest_spiky": "Колючий хохолок",
	"tornado_two": "Два вихря",
	"tornado_long": "Долгий вихрь",
	"tornado_pull": "Затягивающий вихрь",
	"stars_more": "Больше звёзд",
	"stars_big": "Крупные звёзды",
	"stars_burn": "Горячие звёзды",
	"laser_chain": "Отражённый луч",
	"laser_burn": "Прожигающий луч",
	"laser_long": "Дальний луч",
	"mimic_double": "Дважды",
	"mimic_strong": "Громкая пародия",
	"mimic_fast": "Быстрая пародия",
	"crestfan_more": "Пышный веер",
	"crestfan_stun": "Ослепляющий веер",
	"crestfan_far": "Дальний веер",
	"boom_stun": "Оглушающий бум",
	"boom_wide": "Раскатистый бум",
	"boom_fast": "Частый бум",
}

const DESC := {
	"peck": "бьёт клювом ближайшего",
	"feather": "стреляет перьями",
	"bell": "аура звона вокруг",
	"mirror": "солнечный луч насквозь",
	"scream": "волна крика по кругу",
	"orbit": "игрушки кружат вокруг",
	"zap": "статическая искра скачет по врагам",
	"seed": "часто плюётся семечками",
	"boomer": "перо улетает и возвращается",
	"gust": "порыв ветра конусом",
	"mines": "оставляет взрывные скорлупки",
	"song": "аура замедляет и ранит",
	"nut": "кидает орех в толпу",
	"crest": "щит из хохолка, при ударе — вспышка",
	"tornado": "вихрь бродит по толпе",
	"stars": "звёзды падают на врагов",
	"laser": "красная точка жжёт ближайшего",
	"mimic": "повторяет ваш последний трюк против орды",
	"crestfan": "веер перьев из гребня",
	"boom": "низкий бум отбрасывает всех",
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
	"seed_triple": "три семечки веером",
	"seed_pierce": "+2 пробивания",
	"seed_fast": "стреляет на 40% чаще",
	"boomer_two": "второй бумеранг",
	"boomer_wide": "задевает шире",
	"boomer_slow": "замедляет врагов",
	"gust_wide": "конус шире",
	"gust_far": "дальность +50%",
	"gust_stun": "оглушает на 0,4 с",
	"mines_more": "+3 скорлупки",
	"mines_big": "взрыв шире на 50%",
	"mines_frag": "взрыв разбрасывает осколки",
	"song_heal": "лечит 1 здоровье в секунду",
	"song_wide": "аура шире на 40%",
	"song_sleep": "раз в 5 с усыпляет",
	"nut_two": "+1 орех",
	"nut_big": "взрыв шире на 50%",
	"nut_stun": "оглушает на 0,8 с",
	"crest_more": "+1 заряд щита",
	"crest_fast": "заряжается на 35% быстрее",
	"crest_spiky": "вспышка вдвое сильнее",
	"tornado_two": "два вихря",
	"tornado_long": "+3 с жизни вихря",
	"tornado_pull": "тянет сильнее",
	"stars_more": "+2 звезды",
	"stars_big": "звёзды шире на 50%",
	"stars_burn": "поджигают",
	"laser_chain": "луч отражается на второго",
	"laser_burn": "поджигает",
	"laser_long": "+3 м дальности",
	"mimic_double": "повторяет дважды",
	"mimic_strong": "+50% силы",
	"mimic_fast": "откат −35%",
	"crestfan_more": "+4 пера в веере",
	"crestfan_stun": "оглушает на 0,3 с",
	"crestfan_far": "перья летят дальше",
	"boom_stun": "оглушает на 0,6 с",
	"boom_wide": "радиус +40%",
	"boom_fast": "откат −35%",
}

## База: сила карты по таблице тиров (1–10).
const TIER := {
	"feather": 6.0, "bell": 6.0, "mirror": 5.5, "scream": 5.0, "orbit": 5.5, "zap": 5.5,
	"seed": 5.5, "boomer": 5.5, "gust": 5.0, "mines": 5.0, "song": 5.0, "nut": 5.5, "crest": 5.0, "tornado": 5.5, "stars": 5.5, "laser": 5.5,
	"mimic": 6.0, "crestfan": 6.0, "boom": 6.0,
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
const AREA := ["bell", "scream", "orbit", "zap", "gust", "mines", "song", "tornado", "boom"]

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
