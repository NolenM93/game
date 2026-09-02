extends Node

var hitstop_left := 0.0
var shake_pos := Vector2.ZERO
var shake_amp := 0.0
var time_scale_stack := 0


func _process(delta: float) -> void:
	if shake_amp > 0.0:
		shake_amp = maxf(0.0, shake_amp - delta * 18.0)
		shake_pos = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amp * Settings.shake
	else:
		shake_pos = Vector2.ZERO


func punch(amount: float = 10.0) -> void:
	shake_amp = maxf(shake_amp, amount)


func hitstop(seconds: float = 0.06) -> void:
	if time_scale_stack > 0:
		return
	time_scale_stack += 1
	Engine.time_scale = 0.08
	await get_tree().create_timer(seconds, true, false, true).timeout
	Engine.time_scale = 1.0
	time_scale_stack = max(0, time_scale_stack - 1)


func flash_modulate(node: CanvasItem, color: Color, t: float = 0.08) -> void:
	if Settings.reduced_flash:
		return
	if node == null:
		return
	var old := node.modulate
	node.modulate = color
	await get_tree().create_timer(t).timeout
	if is_instance_valid(node):
		node.modulate = old
