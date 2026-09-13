class_name RestoreLight
extends Area2D

var index := 0
var on := false
var glow: Sprite2D


func build() -> void:
	add_to_group("restore_light")
	collision_layer = 128
	collision_mask = 2 | 8
	monitoring = true
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(40, 70)
	cs.shape = r
	add_child(cs)
	glow = Sprite2D.new()
	glow.texture = Art.soft_light()
	glow.modulate = Color(0.22, 0.28, 0.4, 0.55)
	glow.scale = Vector2(0.22, 0.5)
	add_child(glow)
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
	for m in get_tree().get_nodes_in_group("mission_runner"):
		if m.has_method("can_restore"):
			if not m.can_restore(index):
				VFX.text_pop(get_parent(), global_position, "Wrong order", Color("FFAA88"))
				return false
	on = true
	glow.modulate = Color("E8C45ACC")
	add_to_group("light_on")
	AudioDirector.play("spark")
	VFX.ring(get_parent(), global_position, Color("E8C45A"), 70.0)
	for m in get_tree().get_nodes_in_group("mission_runner"):
		if m.has_method("notify_restore"):
			m.notify_restore(index)
	return true
