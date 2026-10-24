class_name PawCursor
extends Node2D
## Кошачья лапка как системный курсор: картинки рисуются один раз в SubViewport,
## а дальше ОС двигает курсор без задержки кадра. Нарисованная лапка остаётся только для рогатки.

## Расцветки лапки: награды из яйца открывают новые.
const SKINS := {
	"white": {"name": "Белая лапка", "fill": Color("fffaf2"), "pad": Color("f3a7b5"), "stripe": Color(0, 0, 0, 0)},
	"ginger": {"name": "Рыжая лапка", "fill": Color("f2b26b"), "pad": Color("e98a7a"), "stripe": Color("d98b3e")},
	"black": {"name": "Чёрная лапка", "fill": Color("4a4446"), "pad": Color("c97a8a"), "stripe": Color(0, 0, 0, 0)},
	"grey": {"name": "Серая полосатая", "fill": Color("b9b6b4"), "pad": Color("e8a0ae"), "stripe": Color("85817f")},
	"calico": {"name": "Трёхцветная", "fill": Color("fffaf2"), "pad": Color("f3a7b5"), "stripe": Color("e8a25a")},
	"siamese": {"name": "Сиамская", "fill": Color("efe0c8"), "pad": Color("9a6f6a"), "stripe": Color("7a5a4a")},
}
const SIZE := 72
const HOT := Vector2(36, 40)

var skin := "white"
var state := "ready"


## Сама лапка: подушечка, четыре пальчика, у полосатых — полоски. curl > 0 — пальцы поджаты.
static func draw_paw(ci: CanvasItem, p: Vector2, sk: Dictionary, curl: float, dim: bool, sc: float = 1.0) -> void:
	var fill: Color = sk["fill"]
	var pad: Color = sk["pad"]
	if dim:
		fill = fill.lerp(Color("c9cad6"), 0.6)
		pad = pad.lerp(Color("b0b0bc"), 0.6)
	var toes := [Vector2(-13, -10), Vector2(-5, -17), Vector2(5, -17), Vector2(13, -10)]
	for k in 4:
		var tp: Vector2 = p + (Vector2(toes[k]) * (1.0 - curl * 0.05) + Vector2(0, curl)) * sc
		Art.blob(ci, tp, 5.5 * sc, (6.0 - curl * 0.3) * sc, fill, 2.6 * sc, 31 + k)
		ci.draw_circle(tp + Vector2(0, 1) * sc, 2.4 * sc, pad)
	Art.blob(ci, p + Vector2(0, 4) * sc, 15.0 * sc, 12.5 * sc, fill, 2.6 * sc, 30)
	var st: Color = sk["stripe"]
	if st.a > 0.0:
		ci.draw_line(p + Vector2(-11, 0) * sc, p + Vector2(-6, 8) * sc, st, 2.5 * sc, true)
		ci.draw_line(p + Vector2(11, 0) * sc, p + Vector2(6, 8) * sc, st, 2.5 * sc, true)
	Art.fill_blob(ci, p + Vector2(0, 6) * sc, 7.0 * sc, 5.5 * sc, pad)
	# точка прицела: ровно туда попадает клик
	ci.draw_circle(p, 2.0 * sc, Color(Art.INK, 0.85))


func _draw() -> void:
	var sk: Dictionary = SKINS.get(skin, SKINS["white"])
	var sc := float(SIZE) / 72.0
	match state:
		"ready":
			draw_paw(self, HOT, sk, 0.0, false, sc)
		"cd":
			draw_paw(self, HOT, sk, 4.0, true, sc)
		"bruised":
			draw_paw(self, HOT, sk, 1.0, true, sc)
			for k in 3:
				var sp := HOT + Vector2(-12 + k * 12, -30) * sc
				draw_circle(sp, 3.0 * sc, Color("f6cd56"))
				draw_arc(sp, 3.0 * sc, 0, TAU, 8, Art.INK, 1.0)
		"empty":
			pass


## Рисует все состояния одной расцветки и возвращает {состояние: Image}.
static func build(parent: Node, skin_key: String, px: int) -> Dictionary:
	var out := {}
	var vp := SubViewport.new()
	vp.size = Vector2i(SIZE, SIZE)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var pc := PawCursor.new()
	pc.skin = skin_key
	vp.add_child(pc)
	parent.add_child(vp)
	for st in ["ready", "cd", "bruised", "empty"]:
		pc.state = st
		pc.queue_redraw()
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		if px != SIZE:
			img.resize(px, px, Image.INTERPOLATE_LANCZOS)
		out[st] = img
	vp.queue_free()
	return out
