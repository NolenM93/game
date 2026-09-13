extends Area3D

const FX = preload("res://scripts/hollow/hollow_fx.gd")

var vel := Vector3.ZERO
var kind := "gloop"
var life := 2.6
var dmg := 3
var host: Node3D


func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 1 | 4 | 16
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.22 if kind == "gloop" else 0.18
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
	else:
		mat.albedo_color = Color("FFB347")
		mat.emission_enabled = true
		mat.emission = Color("FF8A3A")
		mat.emission_energy_multiplier = 2.0
	mi.material_override = mat
	add_child(mi)
	body_entered.connect(_hit)


func _physics_process(delta: float) -> void:
	if kind == "rocket":
		vel.y -= 16.0 * delta
	global_position += vel * delta
	life -= delta
	if life <= 0.0:
		if kind == "rocket":
			_boom()
		queue_free()


func _hit(n: Node) -> void:
	if n.has_method("receive_shot"):
		n.receive_shot(global_position, vel.normalized(), dmg, 7.0, kind)
		if kind == "gloop" and n.has_method("apply_slow"):
			n.apply_slow(2.8)
	if kind == "rocket":
		_boom()
	else:
		if host:
			FX.spark(host, global_position)
	queue_free()


func _boom() -> void:
	if host:
		FX.boom(host, global_position)
		AudioDirector.play("explode", 0.95)
	var sh := SphereShape3D.new()
	sh.radius = 3.2
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = sh
	q.transform = Transform3D(Basis(), global_position)
	q.collision_mask = 4
	var hits := get_world_3d().direct_space_state.intersect_shape(q, 16)
	for h in hits:
		var n: Object = h.get("collider")
		if n is Node and (n as Node).has_method("receive_shot"):
			var away: Vector3 = ((n as Node3D).global_position - global_position)
			away.y = 0.2
			(n as Node).receive_shot((n as Node3D).global_position, away.normalized(), 9, 12.0, "rocket")
