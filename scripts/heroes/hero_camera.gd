class_name HeroCamera
extends Camera2D

var hero: Node2D
var dip := 0.0
var look := Vector2.ZERO


func _ready() -> void:
	enabled = true
	make_current()
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0
	limit_smoothed = true


func _process(delta: float) -> void:
	if hero == null:
		return
	var face := 1.0
	if "facing" in hero:
		face = float(hero.facing)
	var v := Vector2.ZERO
	if "velocity" in hero:
		v = hero.velocity
	if Game.in_hub:
		zoom = zoom.lerp(Vector2(0.86, 0.86), delta * 6.0)
		look = look.lerp(Vector2(face * 48.0, -70.0), delta * 4.0)
		limit_bottom = 1080
		limit_top = -40
		limit_left = -200
	else:
		zoom = zoom.lerp(Vector2.ONE, delta * 6.0)
		look = look.lerp(Vector2(face * 160.0, clampf(v.y * 0.05, -80.0, 90.0)), delta * 4.0)
		limit_bottom = 1400
		limit_top = -800
		limit_left = -200
	dip = move_toward(dip, 0.0, delta * 40.0)
	offset = look + Vector2(0, dip) + Juice.shake_pos


func land() -> void:
	dip = 18.0
