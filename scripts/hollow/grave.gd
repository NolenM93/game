extends Node3D

signal burst(kind: String)

var slab: Node3D
var glow: OmniLight3D
var rumble := 0.0
var queued := ""


func _ready() -> void:
	add_to_group("grave")
	slab = Node3D.new()
	add_child(slab)
	_stone(Vector3(0, 0.12, 0), Vector3(1.15, 0.18, 0.7), Color("5A5E62"))
	_stone(Vector3(0, 0.85, -0.12), Vector3(0.75, 1.35, 0.18), Color("6E7378"))
	_stone(Vector3(0, 1.55, -0.12), Vector3(0.28, 0.35, 0.16), Color("8A9096"))
	glow = OmniLight3D.new()
	glow.light_color = Color("7DCF58")
	glow.light_energy = 0.0
	glow.omni_range = 4.5
	glow.position = Vector3(0, 0.4, 0.3)
	add_child(glow)


func _stone(pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.88
	mi.material_override = m
	slab.add_child(mi)


func wake(kind: String) -> void:
	queued = kind
	rumble = 1.15
	AudioDirector.play("charge", 0.55)


func _process(delta: float) -> void:
	if rumble <= 0.0:
		return
	rumble -= delta
	slab.rotation_degrees.z = sin(Time.get_ticks_msec() * 0.04) * 6.0
	slab.position.y = sin(Time.get_ticks_msec() * 0.05) * 0.08
	glow.light_energy = 3.2 * (1.0 - rumble / 1.15)
	if rumble <= 0.0:
		slab.rotation_degrees.z = 0.0
		slab.position.y = 0.0
		glow.light_energy = 0.0
		burst.emit(queued)
		queued = ""
