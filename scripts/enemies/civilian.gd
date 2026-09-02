class_name Civilian
extends CharacterBody2D

var follow := false
var rescued := false
var actor: CartoonActor
var gravity := 1900.0


func _ready() -> void:
	add_to_group("civilian")
	collision_layer = 0
	collision_mask = 1
	actor = CartoonActor.new()
	actor.configure("civilian", {"body": Color("F4EFE2"), "skin": Color("F0C8A8"), "outline": Color("142033")})
	add_child(actor)
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(actor.display_h * 0.18, actor.display_h * 0.40)
	cs.shape = r
	cs.position = Vector2(0, actor.foot - r.size.y * 0.5)
	add_child(cs)
	z_index = 7


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	var hero := _hero()
	if follow and hero:
		var dx := hero.global_position.x - global_position.x
		velocity.x = clampf(dx * 3.0, -220.0, 220.0)
		if abs(dx) < 40.0:
			velocity.x = 0
	else:
		velocity.x = 0
	move_and_slide()
	if not rescued and hero and global_position.distance_to(hero.global_position) < 100.0:
		_rescue()


func _rescue() -> void:
	rescued = true
	follow = true
	add_to_group("rescued")
	AudioDirector.play("pickup")
	VFX.text_pop(get_parent(), global_position, "THANKS!", Color("2EE6C7"))
	if SaveManager.active.get("city_upgrades", []).has("civ_glow") or true:
		modulate = Color(1.2, 1.3, 0.9)


func _hero() -> Node2D:
	var hs := get_tree().get_nodes_in_group("hero")
	return hs[0] if hs.size() else null
