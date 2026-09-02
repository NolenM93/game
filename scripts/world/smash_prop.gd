class_name SmashProp
extends RigidBody2D

var hp := 2
var vis: CanvasItem


func build(color: Color) -> void:
	add_to_group("smashable")
	collision_layer = 1
	collision_mask = 1
	lock_rotation = true
	freeze = true
	mass = 4.0
	gravity_scale = 1.2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(52, 42)
	cs.shape = r
	add_child(cs)
	var spr := Art.sprite("prop_crate", 52.0)
	if spr.texture:
		vis = spr
		add_child(spr)
	else:
		var box := ColorRect.new()
		box.size = Vector2(46, 46)
		box.position = Vector2(-23, -23)
		box.color = color
		vis = box
		add_child(box)


func receive_hit(data: Dictionary, _from: Vector2, _src: Node) -> void:
	hp -= int(data.get("dmg", 1))
	var kn: Vector2 = data.get("knock", Vector2.UP * 200)
	freeze = false
	apply_central_impulse(kn * 1.4)
	if vis:
		vis.modulate = vis.modulate.lightened(0.15)
	AudioDirector.play("thud", 1.2)
	if _src is HeroBase:
		_src.bump_stat("smashes")
	if hp <= 0:
		_break()


func launch(v: Vector2) -> void:
	freeze = false
	linear_velocity = v
	hp = 0
	get_tree().create_timer(0.35).timeout.connect(_break)


func _break() -> void:
	VFX.burst(get_parent(), global_position, Color("C47A4A"), 10, 200.0)
	add_to_group("destroyed")
	queue_free()
