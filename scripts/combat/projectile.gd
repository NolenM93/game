class_name Projectile
extends Area2D

var vel := Vector2.ZERO
var life := 2.0
var data: Dictionary = {}
var source: Node
var bounces := 0
var team := "hero"
var trail_color := Color.WHITE


func _ready() -> void:
	monitoring = true
	collision_layer = 8
	collision_mask = 1 | 4 | 16
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 8.0
	cs.shape = c
	add_child(cs)
	body_entered.connect(_hit)
	area_entered.connect(_hit)
	var glow := Sprite2D.new()
	glow.texture = Art.soft_light()
	glow.modulate = Color(trail_color.r, trail_color.g, trail_color.b, 0.7)
	glow.scale = Vector2(0.14, 0.14)
	add_child(glow)
	z_index = 20


func _process(delta: float) -> void:
	position += vel * delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 9.0, Color.BLACK)
	draw_circle(Vector2.ZERO, 6.0, trail_color)


func _hit(n: Node) -> void:
	if n == source:
		return
	if team == "hero" and n.is_in_group("hero"):
		return
	if team == "enemy" and n.is_in_group("enemy"):
		return
	var target: Node = n
	if n.get_parent() and n.get_parent().has_method("receive_hit"):
		target = n.get_parent()
	if target.has_method("receive_hit"):
		target.receive_hit(data, global_position, source)
		if bounces <= 0:
			VFX.burst(get_parent(), global_position, trail_color, 6, 140.0)
			queue_free()
			return
		bounces -= 1
		vel.y *= -0.9
		vel.x *= 0.9
		return
	if n is StaticBody2D or n is TileMap or n is CharacterBody2D:
		if bounces > 0:
			bounces -= 1
			vel.y *= -0.85
			return
		queue_free()
