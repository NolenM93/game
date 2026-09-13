class_name Hitbox
extends Area2D

var data: Dictionary = {}
var source: Node
var ttl: float = 0.12
var _hit: Dictionary = {}


func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 8
	collision_mask = 4 | 16 | 1
	body_entered.connect(_on_enter)
	area_entered.connect(_on_enter)


func setup(p_source: Node, p_data: Dictionary, size: Vector2, p_ttl: float = 0.12) -> void:
	source = p_source
	data = p_data
	ttl = p_ttl
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	add_child(cs)
	z_index = 25


func _physics_process(delta: float) -> void:
	ttl -= delta
	if ttl <= 0.0:
		queue_free()


func _on_enter(n: Node) -> void:
	if n == source or (source and source.is_ancestor_of(n)):
		return
	var id := n.get_instance_id()
	if _hit.has(id):
		return
	_hit[id] = true
	var target: Node = n
	if n.get_parent() and n.get_parent().has_method("receive_hit"):
		target = n.get_parent()
	if target.has_method("receive_hit"):
		target.receive_hit(data, global_position, source)
