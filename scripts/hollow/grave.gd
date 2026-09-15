extends Node3D

signal burst(kind: String)

var slab: Node3D
var glow: OmniLight3D
var rumble := 0.0
var queued := ""
var variant := 0
var dirt: MeshInstance3D
var in_town := false


func _ready() -> void:
	add_to_group("grave")
	slab = Node3D.new()
	add_child(slab)
	var lean := randf_range(-6.0, 6.0)
	slab.rotation_degrees.z = lean
	var stone := Color("5A5E62").lerp(Color("6E7378"), randf())
	match variant:
		1:
			# Cross
			_stone(Vector3(0, 0.1, -0.12), Vector3(0.9, 0.16, 0.5), stone.darkened(0.1))
			_stone(Vector3(0, 0.9, -0.12), Vector3(0.22, 1.6, 0.18), stone)
			_stone(Vector3(0, 1.28, -0.12), Vector3(0.8, 0.2, 0.18), stone)
		2:
			# Rounded slab with a chipped top
			_stone(Vector3(0, 0.12, 0), Vector3(1.15, 0.18, 0.7), stone.darkened(0.12))
			_stone(Vector3(0, 0.72, -0.12), Vector3(0.8, 1.1, 0.18), stone)
			var cap := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.4
			cm.bottom_radius = 0.4
			cm.height = 0.18
			cap.mesh = cm
			cap.position = Vector3(0, 1.27, -0.12)
			cap.rotation_degrees.x = 90.0
			cap.material_override = _rock(stone)
			slab.add_child(cap)
			_stone(Vector3(0.26, 1.5, -0.12), Vector3(0.22, 0.18, 0.2), stone.darkened(0.2))
		_:
			_stone(Vector3(0, 0.12, 0), Vector3(1.15, 0.18, 0.7), stone.darkened(0.12))
			_stone(Vector3(0, 0.85, -0.12), Vector3(0.75, 1.35, 0.18), stone)
			_stone(Vector3(0, 1.55, -0.12), Vector3(0.28, 0.35, 0.16), stone.lightened(0.1))
	# Dirt mound in front of the stone: this is where the zed claws out.
	dirt = MeshInstance3D.new()
	var dm := SphereMesh.new()
	dm.radius = 0.5
	dm.height = 1.0
	dirt.mesh = dm
	dirt.position = Vector3(0, -0.02, 0.62)
	dirt.scale = Vector3(1.05, 0.34, 1.5)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("2A2018")
	m.roughness = 1.0
	dirt.material_override = m
	add_child(dirt)
	glow = OmniLight3D.new()
	glow.light_color = Color("7DCF58")
	glow.light_energy = 0.0
	glow.omni_range = 4.5
	glow.position = Vector3(0, 0.4, 0.6)
	add_child(glow)


func _rock(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.88
	return m


func _stone(pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = _rock(color)
	slab.add_child(mi)


func wake(kind: String) -> void:
	queued = kind
	rumble = 1.15
	AudioDirector.play_at("charge", global_position, 0.55)


func _process(delta: float) -> void:
	if rumble <= 0.0:
		return
	rumble -= delta
	var base_lean := 0.0
	slab.rotation_degrees.z = base_lean + sin(Time.get_ticks_msec() * 0.04) * 6.0
	slab.position.y = sin(Time.get_ticks_msec() * 0.05) * 0.08
	if dirt:
		var k := 1.0 - rumble / 1.15
		dirt.scale = Vector3(1.05, 0.34 + 0.4 * k, 1.5)
	glow.light_energy = 3.2 * (1.0 - rumble / 1.15)
	if rumble <= 0.0:
		slab.rotation_degrees.z = 0.0
		slab.position.y = 0.0
		if dirt:
			dirt.scale = Vector3(1.05, 0.34, 1.5)
		glow.light_energy = 0.0
		burst.emit(queued)
		queued = ""
