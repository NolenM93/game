class_name HeroCamera
extends Camera2D

var hero: Node2D
var dip := 0.0
var look := Vector2.ZERO
var hub_lock := Vector2(960, 540)


func _ready() -> void:
	enabled = true
	make_current()
	position_smoothing_enabled = true
	position_smoothing_speed = 6.5
	limit_smoothed = true
	drag_horizontal_enabled = true
	drag_left_margin = 0.18
	drag_right_margin = 0.18
	drag_vertical_enabled = true
	drag_top_margin = 0.22
	drag_bottom_margin = 0.28


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
		position_smoothing_enabled = false
		drag_horizontal_enabled = false
		drag_vertical_enabled = false
		zoom = Vector2.ONE
		offset = hub_lock - hero.global_position
		return
	position_smoothing_enabled = true
	drag_horizontal_enabled = true
	drag_vertical_enabled = true
	zoom = zoom.lerp(Vector2.ONE, delta * 6.0)
	look = look.lerp(Vector2(face * 90.0, clampf(v.y * 0.03, -40.0, 50.0)), delta * 3.2)
	limit_bottom = 1400
	limit_top = -800
	limit_left = -200
	dip = move_toward(dip, 0.0, delta * 50.0)
	offset = look + Vector2(0, dip) + Juice.shake_pos


func land() -> void:
	if Game.in_hub:
		return
	dip = 8.0
