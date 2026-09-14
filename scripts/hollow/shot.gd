extends Area3D

const FX = preload("res://scripts/hollow/hollow_fx.gd")

var vel := Vector3.ZERO
var kind := "gloop"
var life := 2.6
var dmg := 3
var host: Node3D
var trail_t := 0.0
var light: OmniLight3D


func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 1 | 4 | 16
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.22 if kind == "gloop" else (0.26 if kind == "hex" else 0.18)
	cs.shape = s
	add_child(cs)
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = s.radius
	mesh.height = s.radius * 2.0
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if kind == "gloop":
		mat.albedo_color = Color("8BE05A")
		mi.scale = Vector3(1.0, 0.8, 1.25)
	elif kind == "hex":
		mat.albedo_color = Color("C080E8")
		mat.emission_enabled = true
		mat.emission = Color("B070D0")
		mat.emission_energy_multiplier = 2.4
		light = OmniLight3D.new()
		light.light_color = Color("C080E8")
		light.light_energy = 3.2
		light.omni_range = 7.0
		light.shadow_enabled = false
		add_child(light)
	else:
		mat.albedo_color = Color("FFB347")
		mat.emission_enabled = true
		mat.emission = Color("FF8A3A")
		mat.emission_energy_multiplier = 2.0
		light = OmniLight3D.new()
		light.light_color = Color("FF9A4A")
		light.light_energy = 2.2
		light.omni_range = 5.0
		light.shadow_enabled = false
		add_child(light)
	mi.material_override = mat
	add_child(mi)
	body_entered.connect(_hit)


func _physics_process(delta: float) -> void:
	if kind == "rocket" or kind == "hex":
		vel.y -= (16.0 if kind == "rocket" else 10.0) * delta
		if Vector2(vel.x, vel.z).length() > 0.3:
			look_at(global_position + vel, Vector3.UP)
	global_position += vel * delta
	life -= delta
	trail_t -= delta
	if trail_t <= 0.0:
		trail_t = 0.03 if kind == "rocket" else 0.07
		if kind == "rocket":
			FX.burst(host, global_position, Color(0.55, 0.5, 0.48, 0.7), 1, 0.35)
		elif kind == "hex":
			FX.burst(host, global_position, Color(0.7, 0.4, 0.9, 0.75), 1, 0.4)
		else:
			FX.burst(host, global_position, Color(0.5, 0.85, 0.35, 0.6), 1, 0.25)
	if life <= 0.0:
		if kind == "rocket" or kind == "hex":
			_boom()
		queue_free()


func _hit(n: Node) -> void:
	if n.has_method("receive_shot"):
		n.receive_shot(global_position, vel.normalized(), dmg, 7.0, kind)
		if kind == "gloop" and n.has_method("apply_slow"):
			n.apply_slow(2.8)
	if kind == "rocket" or kind == "hex":
		_boom()
	else:
		if host:
			FX.burst(host, global_position, Color("8BE05A"), 8, 1.6)
			AudioDirector.play_at("splat", global_position, randf_range(1.2, 1.5))
	queue_free()


func _boom() -> void:
	if host:
		if kind == "hex":
			FX.flash(host, global_position, Color("C080E8"), 10.0, 8.0, 0.45)
			FX.ring(host, global_position, Color(0.75, 0.4, 1.0, 0.8), 3.6, 0.4)
			FX.burst(host, global_position, Color("B070D0"), 16, 2.4)
			AudioDirector.play_at("whoom", global_position, 0.7)
		else:
			FX.boom(host, global_position)
			AudioDirector.play_at("explode", global_position, 0.95)
	for h in get_tree().get_nodes_in_group("hunter"):
		if h is Node3D and h.has_method("shake"):
			var d: float = (h as Node3D).global_position.distance_to(global_position)
			h.shake(clampf(0.55 - d * 0.04, 0.08, 0.55))
	var sh := SphereShape3D.new()
	sh.radius = 3.8 if kind == "hex" else 3.2
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = sh
	q.transform = Transform3D(Basis(), global_position)
	q.collision_mask = 4
	var hits := get_world_3d().direct_space_state.intersect_shape(q, 16)
	var style := "hex" if kind == "hex" else "rocket"
	var boom_dmg := 6 if kind == "hex" else 9
	for h in hits:
		var n: Object = h.get("collider")
		if n is Node and (n as Node).has_method("receive_shot"):
			var away: Vector3 = ((n as Node3D).global_position - global_position)
			away.y = 0.2
			(n as Node).receive_shot((n as Node3D).global_position + Vector3(0, 0.7, 0), away.normalized(), boom_dmg, 12.0, style)
