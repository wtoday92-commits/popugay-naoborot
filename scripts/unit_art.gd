class_name UnitArt
extends RefCounted
## Рисунки новых юнитов: один и тот же код для поля, наград и сундука.

const INK := Art.INK


## key — ключ юнита, p — центр, s — масштаб, t — время для анимации, st — состояние (0 обычное, 1 замах),
## dir — куда смотрит, tint — подкраска (вспышка при ударе и т. п.).
static func draw(ci: CanvasItem, key: String, p: Vector2, s: float, t: float, st: int = 0, dir: Vector2 = Vector2.RIGHT, tint: Color = Color(1, 1, 1, 0)) -> void:
	var col := func(c: Color) -> Color: return c.lerp(Color(tint, 1.0), tint.a)
	match key:
		"remote":
			# телевизионный пульт: тёмный корпус, цветные кнопки, на замахе мигает красный диод
			var body := Art.rot_rect(p, 14 * s, 30 * s, 0.25)
			ci.draw_colored_polygon(body, col.call(Color("4a4f5a")))
			Art.outline(ci, body, INK, 2.5)
			for k in 3:
				ci.draw_circle(p + Vector2(-3 + k * 3, 2 + k * 2).rotated(0.25) * s, 1.8 * s, [Color("e8574a"), Color("8fd46a"), Color("f2c14e")][k])
			ci.draw_circle(p + Vector2(1, -11).rotated(0.25) * s, 2.4 * s, Color(1.0, 0.2, 0.2, 1.0 if st == 1 and int(t * 10) % 2 == 0 else 0.4))
		"pillow":
			# подушка: пухлый прямоугольник с уголками и пуговкой
			var w := 26.0 * s
			var h := 18.0 * s * (1.0 + 0.04 * sin(t * 3.0))
			var pts := PackedVector2Array([p + Vector2(-w, -h), p + Vector2(0, -h * 0.8), p + Vector2(w, -h), p + Vector2(w * 0.85, 0), p + Vector2(w, h), p + Vector2(0, h * 0.8), p + Vector2(-w, h), p + Vector2(-w * 0.85, 0)])
			ci.draw_colored_polygon(pts, col.call(Color("f3ecf6")))
			Art.outline(ci, pts, INK, 3.0)
			ci.draw_circle(p, 3.0 * s, Color("c9a7d6"))
			for k in 2:
				ci.draw_circle(p + Vector2(-8 + k * 16, -5) * s, 1.6 * s, INK)
		"ball":
			# мячик-попрыгунчик: красный с белой полосой, крутится
			ci.draw_circle(p, 10.0 * s, col.call(Color("e8574a")))
			ci.draw_arc(p, 10.0 * s, 0, TAU, 20, INK, 2.5, true)
			var a := t * 12.0
			ci.draw_arc(p, 6.0 * s, a, a + PI, 10, Color("fff6e0"), 3.0 * s, true)
		"cable":
			# провод-змейка рисуется отдельно (хвост), здесь — вилка-голова
			var d := dir.normalized()
			var head := Art.rot_rect(p, 18 * s, 13 * s, d.angle())
			ci.draw_colored_polygon(head, col.call(Color("2f2f36")))
			Art.outline(ci, head, INK, 2.0)
			for k in [-1.0, 1.0]:
				var b: Vector2 = p + d * 9.0 * s + d.orthogonal() * 3.5 * s * k
				ci.draw_line(b, b + d * 7.0 * s, Color("d9c27a"), 2.5 * s)
			if st == 1:
				for k in 3:
					var q := p + Vector2(cos(t * 20.0 + k * 2.1), sin(t * 20.0 + k * 2.1)) * 16.0 * s
					ci.draw_line(p, q, Color(1.0, 0.95, 0.4, 0.9), 1.5)
		"alarm":
			# будильник: круглый, два колокольчика, при звонке трясётся
			var shake := sin(t * 60.0) * 2.0 * s if st == 1 else 0.0
			var c := p + Vector2(shake, 0)
			for k in [-1.0, 1.0]:
				ci.draw_circle(c + Vector2(9.0 * k, -12) * s, 5.0 * s, Color("d9ae4f"))
				ci.draw_arc(c + Vector2(9.0 * k, -12) * s, 5.0 * s, 0, TAU, 10, INK, 2.0)
			ci.draw_circle(c, 13.0 * s, col.call(Color("e8574a")))
			ci.draw_circle(c, 10.0 * s, Color("fff8ea"))
			ci.draw_arc(c, 13.0 * s, 0, TAU, 24, INK, 2.5, true)
			ci.draw_line(c, c + Vector2(0, -7) * s, INK, 2.0)
			ci.draw_line(c, c + Vector2(5, 2) * s, INK, 2.0)
		"sponge":
			# губка: жёлтая с зелёным верхом и дырочками
			var r := Rect2(p - Vector2(13, 9) * s, Vector2(26, 18) * s)
			ci.draw_rect(r, col.call(Color("f2d45c")))
			ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 6 * s)), Color("6fb35a"))
			ci.draw_rect(r, INK, false, 2.5)
			for k in 4:
				ci.draw_circle(p + Vector2(-8 + k * 5, 3 + (k % 2) * 3) * s, 1.4 * s, Color("c9a63a"))
		"car":
			# заводная машинка: кузов, колёса, ключик сзади крутится
			var d := dir.normalized()
			var body := Art.rot_rect(p, 26 * s, 15 * s, d.angle())
			ci.draw_colored_polygon(body, col.call(Color("5f8fd6")))
			Art.outline(ci, body, INK, 2.5)
			for k in [-1.0, 1.0]:
				for j in [-1.0, 1.0]:
					ci.draw_circle(p + d * 8.0 * s * j + d.orthogonal() * 8.0 * s * k, 3.5 * s, INK)
			var key_p := p - d * 16.0 * s
			var ka := t * (20.0 if st == 2 else 5.0)
			ci.draw_line(key_p - Vector2(cos(ka), sin(ka)) * 6.0 * s, key_p + Vector2(cos(ka), sin(ka)) * 6.0 * s, Color("d9ae4f"), 3.0 * s)
			if st == 1:
				ci.draw_dashed_line(p, p + d * 90.0 * s, Color(0.85, 0.3, 0.2, 0.7), 2.5, 8.0)
