class_name HollowLoot
extends Area3D

var item: Dictionary = {}
var _base_y := 0.0
var _spin := 0.7
var vis: Node3D
var _seated := false


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


func _mesh() -> void:
	vis = Node3D.new()
	add_child(vis)
	var id := str(item.get("id", ""))
	match id:
		"bat":
			_box(Vector3(0, 0.28, 0), Vector3(0.11, 0.11, 0.95), Color("C48A4A"))
			_box(Vector3(0, 0.28, -0.38), Vector3(0.16, 0.16, 0.2), Color("3A2A1C"))
		"ammo":
			_box(Vector3(0, 0.16, 0), Vector3(0.28, 0.16, 0.38), Color("C45A20"))
			_sphere(Vector3(-0.08, 0.28, 0.04), 0.1, Color("FFE27A"))
			_sphere(Vector3(0.1, 0.26, -0.06), 0.09, Color("FFB347"))
		"candy":
			_sphere(Vector3(0, 0.24, 0), 0.2, Color("FF8A3A"))
			_box(Vector3(0, 0.24, 0), Vector3(0.42, 0.06, 0.16), Color("FFE27A"))
		"gun_shotgun":
			_box(Vector3(0, 0.28, 0.1), Vector3(0.16, 0.08, 0.72), Color("3A2A1C"))
			_box(Vector3(-0.05, 0.28, 0.42), Vector3(0.05, 0.05, 0.22), Color("1A140E"))
			_box(Vector3(0.05, 0.28, 0.42), Vector3(0.05, 0.05, 0.22), Color("1A140E"))
			_box(Vector3(0, 0.16, -0.18), Vector3(0.09, 0.18, 0.16), Color("5A3A22"))
		"gun_nailer":
			_box(Vector3(0, 0.3, 0.16), Vector3(0.06, 0.06, 0.95), Color("6A7078"))
			_box(Vector3(0, 0.2, -0.16), Vector3(0.09, 0.16, 0.16), Color("1A140E"))
			_box(Vector3(0, 0.3, 0.62), Vector3(0.03, 0.03, 0.16), Color("D4FF8A"))
		"gun_gloop":
			_sphere(Vector3(0, 0.3, 0.02), 0.22, Color("6AA84A"))
			_box(Vector3(0, 0.3, 0.32), Vector3(0.1, 0.1, 0.36), Color("3A4630"))
			_sphere(Vector3(0, 0.3, 0.52), 0.1, Color("8BE05A"))
		"gun_rocket":
			_box(Vector3(0, 0.28, 0.12), Vector3(0.16, 0.16, 0.7), Color("C45A20"))
			_sphere(Vector3(0, 0.28, -0.24), 0.16, Color("FFB347"))
			_box(Vector3(0, 0.28, 0.5), Vector3(0.08, 0.04, 0.16), Color("FFE27A"))
		"gun_stake":
			_box(Vector3(0, 0.3, 0.18), Vector3(0.07, 0.07, 1.1), Color("5A3A28"))
			_box(Vector3(0, 0.3, 0.72), Vector3(0.14, 0.03, 0.24), Color("8A8E94"))
			_box(Vector3(0, 0.16, -0.28), Vector3(0.12, 0.22, 0.16), Color("1A140E"))
		"gun_hex":
			_box(Vector3(0, 0.2, -0.08), Vector3(0.08, 0.08, 0.42), Color("3A2418"))
			_sphere(Vector3(0, 0.42, 0.22), 0.22, Color("B070D0"))
			_box(Vector3(0, 0.64, 0.22), Vector3(0.3, 0.08, 0.3), Color("C4A05A"))
		"gun_frost":
			_box(Vector3(0, 0.3, 0.16), Vector3(0.06, 0.06, 0.92), Color("7EC8E8"))
			_box(Vector3(0, 0.38, 0.16), Vector3(0.12, 0.04, 0.16), Color("DEEEF8"))
			_box(Vector3(0, 0.2, -0.16), Vector3(0.09, 0.16, 0.16), Color("DEEEF8"))
		"heart":
			_cyl_mesh(Vector3(0, 0.16, 0), 0.22, 0.1, Color("C48A4A"))
			_cyl_mesh(Vector3(0, 0.24, 0), 0.18, 0.08, Color("E07020"))
			_sphere(Vector3(-0.06, 0.3, 0.04), 0.08, Color("E56BA0"))
			_sphere(Vector3(0.06, 0.3, 0.04), 0.08, Color("E56BA0"))
		"oil":
			_cyl_mesh(Vector3(0, 0.28, 0), 0.11, 0.42, Color("C45A20"))
			_sphere(Vector3(0, 0.28, 0), 0.09, Color("FFB347"))
			_cyl_mesh(Vector3(0, 0.52, 0), 0.07, 0.1, Color("3A2418"))
			_sphere(Vector3(0, 0.6, 0), 0.06, Color("FFE27A"))
		_:
			_box(Vector3(0, 0.26, 0), Vector3(0.34, 0.34, 0.34), item.get("color", Color("FFE27A")))
	var tag := Label3D.new()
	tag.text = str(item.get("icon", "•"))
	tag.font_size = 72
	tag.outline_size = 10
	tag.position.y = 1.05
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.modulate = Color("FFF6D8")
	if Art.font_emoji:
		tag.font = Art.font_emoji
	vis.add_child(tag)
	var glow := OmniLight3D.new()
	glow.light_color = item.get("color", Color("FFE27A"))
	glow.light_energy = 0.7
	glow.omni_range = 3.0
	glow.position.y = 0.4
	add_child(glow)


func _sit() -> void:
	if not is_inside_tree():
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


func _box(pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = _mat(color)
	vis.add_child(mi)


func _sphere(pos: Vector3, radius: float, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	mi.mesh = s
	mi.position = pos
	mi.material_override = _mat(color)
	vis.add_child(mi)


func _cyl_mesh(pos: Vector3, radius: float, height: float, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	mi.mesh = c
	mi.position = pos
	mi.material_override = _mat(color)
	vis.add_child(mi)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.48
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.35
	return m
