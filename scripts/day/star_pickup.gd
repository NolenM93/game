class_name StarPickup
extends Area3D

signal collected

var bob := randf() * TAU
var taken := false
var mesh: Node3D


func _ready() -> void:
	monitoring = true
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.85
	cs.shape = s
	add_child(cs)
	mesh = Node3D.new()
	add_child(mesh)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("FFE27A")
	mat.emission_enabled = true
	mat.emission = Color("FFD24A")
	mat.emission_energy_multiplier = 2.8
	mat.roughness = 0.22
	mat.rim_enabled = true
	mat.rim = 0.6
	_ball(Vector3.ZERO, 0.34, mat)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.1
	torus.outer_radius = 0.42
	torus.rings = 16
	torus.ring_segments = 12
	ring.mesh = torus
	ring.rotation_degrees = Vector3(70, 0, 0)
	ring.material_override = mat
	mesh.add_child(ring)
	var light := OmniLight3D.new()
	light.light_color = Color("FFE6A0")
	light.light_energy = 2.0
	light.omni_range = 5.5
	add_child(light)
	body_entered.connect(_touch)


func _ball(pos: Vector3, radius: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	mi.position = pos
	mi.material_override = mat
	mesh.add_child(mi)


func _process(delta: float) -> void:
	if taken:
		return
	bob += delta * 2.3
	mesh.position.y = 0.12 + sin(bob) * 0.2
	mesh.rotate_y(delta * 1.7)


func _touch(n: Node) -> void:
	if taken or not n.is_in_group("kid"):
		return
	taken = true
	AudioDirector.play("pickup")
	collected.emit()
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(2.1, 2.1, 2.1), 0.14)
	tw.tween_callback(queue_free)
