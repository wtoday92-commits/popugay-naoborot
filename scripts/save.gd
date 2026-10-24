class_name Save
extends RefCounted
## Сохранение между забегами: счётчик забегов, обучение игрока, перья, память попугая.
## Файл: user://save.json (на Windows %APPDATA%/Godot/app_userdata/Попугай наоборот/save.json).

static var path := "user://save.json"


static func defaults() -> Dictionary:
	return {
		"runs": 0,
		"tut_block": false,
		"tut_millet": false,
		"feathers": 0,
		"rewards": [],
		# память попугая: средние доли полученного урона по источникам и нанесённого по умениям
		"memory": {"runs": 0, "taken": {}, "dealt": {}, "deaths": {}},
	}


static func load_data() -> Dictionary:
	var d := defaults()
	if not FileAccess.file_exists(path):
		return d
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return d
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return d
	for k in parsed:
		d[k] = parsed[k]
	return d


static func store(d: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d, "\t"))


## Скользящее среднее долей: новая доля весит 40%, память — 60%.
static func blend(old: Dictionary, fresh: Dictionary, w: float = 0.4) -> Dictionary:
	var out := {}
	for k in old:
		out[k] = float(old[k]) * (1.0 - w)
	for k in fresh:
		out[k] = float(out.get(k, 0.0)) + float(fresh[k]) * w
	return out


static func shares(d: Dictionary) -> Dictionary:
	var tot := 0.0
	for k in d:
		tot += float(d[k])
	var out := {}
	if tot <= 0.0:
		return out
	for k in d:
		out[k] = float(d[k]) / tot
	return out
