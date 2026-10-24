class_name Enemy
extends RefCounted
## Один юнит орды. Данные без узла: двигает и рисует их главный цикл.

enum T { SOCK, BALL, SLIPPER, SPRAYER, HAND }

var type: int = T.SOCK
var id := 0
var pos := Vector2.ZERO
var push_vel := Vector2.ZERO
var move_dir := Vector2.RIGHT
var hp := 10.0
var max_hp := 10.0
var speed := 60.0
var dmg := 5.0
var radius := 11.0
var push_factor := 1.0
var xp := 1
var atk_cd := 0.0
var phase := 0.0
var tumble := 0.0
var flash := 0.0
var blue := 0.0
var stun := 0.0
var born := 0.0
var dead := false
var from_player := false
var carries_chest := false
var shoot_cd := 2.0
var grab_state := 0
var grab_t := 0.0
var grab_cd := 1.0


## Носок в прыжке: летит быстро и не кусается, опасен в момент приземления.
func is_airborne() -> bool:
	return type == T.SOCK and phase > 0.35 and phase < 0.7


## Максимальная скорость юнита: от неё считается предел толчка лапкой.
func top_speed() -> float:
	return speed * 2.8 if type == T.SOCK else speed
