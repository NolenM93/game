class_name ChaseVan
extends CharacterBody2D

var speed := 260.0
var done := false


func _ready() -> void:
	add_to_group("chase_van")
	collision_layer = 0
	collision_mask = 1
	var vis := ColorRect.new()
	vis.size = Vector2(110, 50)
	vis.position = Vector2(-55, -25)
	vis.color = Color("3A3A48")
	add_child(vis)
	var cab := ColorRect.new()
	cab.size = Vector2(40, 30)
	cab.position = Vector2(10, -40)
	cab.color = Color("6CF0E0")
	add_child(cab)
	z_index = 6


func _physics_process(_delta: float) -> void:
	if done:
		velocity.x = 0
		return
	velocity = Vector2(speed, 0)
	move_and_slide()
