extends AnimatableBody3D

var stops: PackedFloat32Array = PackedFloat32Array([0.14, 3.52, 7.04])
var idx := 0
var target := 0.14
var moving := false
var dwell := 0.0
var speed := 2.55


func _ready() -> void:
	add_to_group("lift")
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.05, 0.16, 2.15)
	cs.shape = box
	add_child(cs)
	var floor_m: Material = Art.surface("metal")
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.05, 0.16, 2.15)
	mi.mesh = mesh
	mi.material_override = floor_m
	add_child(mi)
	var rail := Art.surface("rust")
	_rail(Vector3(-0.98, 0.55, 0), Vector3(0.06, 1.05, 2.15), rail)
	_rail(Vector3(0, 0.55, -1.04), Vector3(2.0, 1.05, 0.06), rail)
	_rail(Vector3(0, 0.55, 1.04), Vector3(2.0, 1.05, 0.06), rail)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 1.35, 0)
	lamp.light_color = Color("FFE0B0")
	lamp.light_energy = 0.55
	lamp.omni_range = 3.0
	add_child(lamp)
	var tag := Label3D.new()
	tag.text = "ELEVATOR"
	tag.font_size = 22
	tag.outline_size = 4
	tag.position = Vector3(0.92, 0.85, 0)
	tag.rotation.y = PI * 0.5
	tag.modulate = Color("FFE27A")
	if Art.font_title:
		tag.font = Art.font_title
	add_child(tag)


func setup(p_stops: PackedFloat32Array, px: float = -4.2, pz: float = 0.0) -> void:
	stops = p_stops
	idx = 0
	target = stops[0]
	position = Vector3(px, target, pz)


func _rail(pos: Vector3, size: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = mat
	add_child(mi)


func _physics_process(delta: float) -> void:
	if moving:
		position.y = move_toward(position.y, target, speed * delta)
		if absf(position.y - target) < 0.025:
			position.y = target
			moving = false
			dwell = 0.0
		return
	if _hunter_on():
		dwell += delta
		if dwell >= 1.05:
			_go_next()
	else:
		dwell = 0.0


func _go_next() -> void:
	idx = (idx + 1) % stops.size()
	target = stops[idx]
	moving = true
	AudioDirector.play_at("whoosh", global_position, 0.7)


func call_floor(i: int) -> void:
	i = clampi(i, 0, stops.size() - 1)
	if idx == i and not moving:
		return
	idx = i
	target = stops[idx]
	moving = true
	AudioDirector.play_at("whoosh", global_position, 0.55)


func try_use() -> bool:
	var h := _hunter()
	if h == null:
		return false
	if _hunter_on():
		if not moving:
			_go_next()
		return true
	for i in stops.size():
		if h.global_position.distance_to(_call_world(i)) < 1.85:
			call_floor(i)
			return true
	return false


func near_prompt() -> bool:
	var h := _hunter()
	if h == null:
		return false
	if _hunter_on():
		return true
	for i in stops.size():
		if h.global_position.distance_to(_call_world(i)) < 1.85:
			return true
	return false


func _call_world(i: int) -> Vector3:
	var b := get_parent() as Node3D
	if b == null:
		return global_position
	return b.to_global(Vector3(-3.08, stops[i] + 1.1, 0.92))


func _hunter_on() -> bool:
	var h := _hunter()
	if h == null:
		return false
	var lp := to_local(h.global_position)
	return absf(lp.x) < 1.1 and absf(lp.z) < 1.2 and lp.y > -0.05 and lp.y < 2.15


func _hunter() -> Node3D:
	return get_tree().get_first_node_in_group("hunter") as Node3D
