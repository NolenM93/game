class_name HarborPup
extends CharacterBody3D

const FX = preload("res://scripts/day/arena_fx.gd")

var kid: Node3D
var vis: Node3D
var yip_t := 2.5
var nip_cd := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	floor_snap_length = 0.2
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 0.55
	cs.shape = cap
	cs.position.y = 0.3
	cs.rotation_degrees.z = 90
	add_child(cs)
	vis = Node3D.new()
	add_child(vis)
	var fur := _mat(Color("C9853A"))
	var dark := _mat(Color("3A2414"))
	_ball(Vector3(0, 0.32, 0), Vector3(0.72, 0.48, 0.98), fur)
	_ball(Vector3(0, 0.44, 0.44), Vector3(0.44, 0.44, 0.44), fur)
	_ball(Vector3(-0.16, 0.64, 0.4), Vector3(0.16, 0.3, 0.12), dark)
	_ball(Vector3(0.16, 0.64, 0.4), Vector3(0.16, 0.3, 0.12), dark)
	_ball(Vector3(-0.1, 0.48, 0.58), Vector3(0.085, 0.085, 0.06), _mat(Color.WHITE))
	_ball(Vector3(0.1, 0.48, 0.58), Vector3(0.085, 0.085, 0.06), _mat(Color.WHITE))
	_ball(Vector3(0, 0.4, 0.62), Vector3(0.11, 0.09, 0.11), _mat(Color("E56BA0")))
	_ball(Vector3(0, 0.3, -0.58), Vector3(0.13, 0.13, 0.3), fur)


func _physics_process(delta: float) -> void:
	if kid == null or not is_instance_valid(kid):
		return
	nip_cd = maxf(0.0, nip_cd - delta)
	var to := kid.global_position - global_position
	to.y = 0.0
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = 0.0
	if to.length() > 2.4:
		var n := to.normalized()
		velocity.x = n.x * 5.4
		velocity.z = n.z * 5.4
		vis.rotation.y = lerp_angle(vis.rotation.y, atan2(n.x, n.z), 0.22)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)
	if global_position.y < 0.18:
		velocity.y = maxf(velocity.y, 4.0)
		if to.length() > 0.2:
			var n2 := to.normalized()
			velocity.x = n2.x * 5.0
			velocity.z = n2.z * 5.0
	move_and_slide()
	if global_position.y < -4.0 and kid:
		global_position = kid.global_position + Vector3(1.4, 0.8, 1.4)
		velocity = Vector3.ZERO
	vis.position.y = sin(Time.get_ticks_msec() * 0.01) * 0.035
	yip_t -= delta
	if yip_t <= 0.0 and to.length() < 3.0:
		AudioDirector.play("yip", 1.05)
		yip_t = randf_range(7.0, 14.0)
	_nip()


func _nip() -> void:
	if nip_cd > 0.0:
		return
	var best: Node3D = null
	var best_d := 1.7
	for n in get_tree().get_nodes_in_group("foe"):
		if n is Node3D:
			var d: float = global_position.distance_to((n as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = n
	if best and best.has_method("receive_hit"):
		best.receive_hit(self, 1, 7.5)
		nip_cd = 1.6
		AudioDirector.play("yip", 1.3)
		FX.burst(get_parent(), global_position + Vector3(0, 0.4, 0), Color("C9853A"), 6, 1.2)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.72
	return m


func _ball(pos: Vector3, sc: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	mi.mesh = s
	mi.position = pos
	mi.scale = sc
	mi.material_override = mat
	vis.add_child(mi)
