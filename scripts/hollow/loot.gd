class_name HollowLoot
extends Area3D

const GunArt = preload("res://scripts/hollow/gun_art.gd")

var item: Dictionary = {}
var _base_y := 0.0
var _spin := 0.7
var vis: Node3D
var _seated := false
var _popping := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	_spin = randf_range(0.45, 0.85)
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 0.9
	cs.shape = sh
	cs.position.y = 0.35
	add_child(cs)
	_mesh()
	body_entered.connect(_grab)
	_base_y = position.y
	call_deferred("_sit")


func setup(it: Dictionary) -> void:
	item = it.duplicate(true)


func pop_out(land: Vector3) -> void:
	_popping = true
	_seated = false
	var start := global_position
	var peak := (start + land) * 0.5 + Vector3(0, 1.15, 0)
	var tw := create_tween()
	tw.tween_property(self, "global_position", peak, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", land, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_popping = false
		_sit()
	)


func _mesh() -> void:
	vis = Node3D.new()
	add_child(vis)
	var id := str(item.get("id", ""))
	GunArt.attach(vis, id, 1.15)
	var glow := OmniLight3D.new()
	glow.light_color = item.get("color", Color("FFE27A"))
	glow.light_energy = 0.45
	glow.omni_range = 2.4
	glow.position.y = 0.4
	add_child(glow)


func _sit() -> void:
	if not is_inside_tree() or _popping:
		return
	var from := global_position + Vector3(0, 1.4, 0)
	var to := global_position + Vector3(0, -8.0, 0)
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit:
		global_position.y = hit.position.y + 0.08
	_base_y = position.y
	_seated = true


func _process(delta: float) -> void:
	if not _seated:
		return
	if vis:
		vis.rotate_y(delta * _spin)
	position.y = _base_y + sin(Time.get_ticks_msec() * 0.003 + float(get_instance_id() % 12)) * 0.05


func _grab(body: Node3D) -> void:
	if item.is_empty():
		return
	if not body.is_in_group("hunter") or not body.has_method("take_loot"):
		return
	if body.take_loot(item):
		item = {}
		queue_free()
