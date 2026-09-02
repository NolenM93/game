class_name RestoreLight
extends Area2D

var index := 0
var on := false
var vis: ColorRect
var label: Label


func build() -> void:
	add_to_group("restore_light")
	collision_layer = 128
	collision_mask = 2 | 8
	monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(36, 64)
	cs.shape = r
	add_child(cs)
	vis = ColorRect.new()
	vis.size = Vector2(28, 56)
	vis.position = Vector2(-14, -28)
	vis.color = Color("243056")
	add_child(vis)
	label = Label.new()
	label.text = str(index + 1)
	label.position = Vector2(-8, -48)
	add_child(label)
	body_entered.connect(_touch)
	area_entered.connect(_touch)


func _touch(n: Node) -> void:
	if on:
		return
	if n is HeroBase or (n is Projectile and n.team == "hero") or n is Hitbox:
		try_on()


func try_on() -> bool:
	if on:
		return false
	var ordered := false
	for m in get_tree().get_nodes_in_group("mission_runner"):
		if m.has_method("can_restore"):
			if not m.can_restore(index):
				VFX.text_pop(get_parent(), global_position, "WRONG ORDER", Color("FFAA88"))
				return false
			ordered = true
	on = true
	vis.color = Color("F4C542")
	add_to_group("light_on")
	AudioDirector.play("spark")
	VFX.ring(get_parent(), global_position, Color("F4C542"), 70.0)
	for m in get_tree().get_nodes_in_group("mission_runner"):
		if m.has_method("notify_restore"):
			m.notify_restore(index)
	return true
