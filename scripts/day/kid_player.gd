class_name KidPlayer
extends CharacterBody3D

const FX = preload("res://scripts/day/arena_fx.gd")

signal hp_changed(hp: int, max_hp: int)

var move_speed := 7.8
var jump_v := 8.6
var gravity := 22.0
var cam_yaw := 0.0
var cam_pitch := -20.0
var coyote := 0.0
var jump_buf := 0.0
var spawn := Vector3.ZERO
var vis: Node3D
var spring: SpringArm3D
var squish := 1.0
var look_stick := 0.0
var arm_r: MeshInstance3D
var hp := 5
var max_hp := 5
var i_frames := 0.0
var attack_cd := 0.0
var spin_cd := 0.0
var spinning := 0.0
var slam_armed := false
var punch_t := 0.0
var splash_cd := 0.0
var ring_r := 13.2


func _ready() -> void:
	add_to_group("kid")
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.28
	floor_max_angle = deg_to_rad(55.0)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.18
	cs.shape = cap
	cs.position.y = 0.64
	add_child(cs)
	_build_look()
	_build_cam()
	spawn = global_position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hp_changed.emit(hp, max_hp)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cam_yaw -= event.relative.x * 0.0024
		cam_pitch = clampf(cam_pitch - event.relative.y * 0.002, -38.0, -8.0)
		look_stick = 0.35


func _build_look() -> void:
	vis = Node3D.new()
	vis.name = "Look"
	add_child(vis)
	var skin := _mat(Color("E8B48A"), 0.5)
	var teal := _mat(Color("2BB3A8"), 0.58)
	var ink := _mat(Color("1A1520"), 0.7)
	var pink := _mat(Color("E56BA0"), 0.48)
	var denim := _mat(Color("2A3348"), 0.68)
	var sh := MeshInstance3D.new()
	var disk := CylinderMesh.new()
	disk.top_radius = 0.44
	disk.bottom_radius = 0.44
	disk.height = 0.04
	sh.mesh = disk
	sh.position = Vector3(0, 0.03, 0)
	var shm := _mat(Color(0.05, 0.08, 0.1, 0.32), 1.0)
	shm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sh.material_override = shm
	vis.add_child(sh)
	_mesh(vis, CapsuleMesh.new(), Vector3(0, 0.64, 0), Vector3(0.82, 0.74, 0.82), teal)
	_mesh(vis, CapsuleMesh.new(), Vector3(-0.46, 0.72, 0.02), Vector3(0.28, 0.36, 0.28), teal)
	arm_r = _mesh(vis, CapsuleMesh.new(), Vector3(0.46, 0.72, 0.02), Vector3(0.28, 0.36, 0.28), teal)
	_mesh(vis, SphereMesh.new(), Vector3(0, 1.26, 0.02), Vector3(0.66, 0.66, 0.66), skin)
	_mesh(vis, SphereMesh.new(), Vector3(0, 1.42, -0.04), Vector3(0.7, 0.36, 0.66), ink)
	_mesh(vis, SphereMesh.new(), Vector3(-0.15, 1.3, 0.26), Vector3(0.12, 0.14, 0.08), _mat(Color.WHITE, 0.28))
	_mesh(vis, SphereMesh.new(), Vector3(0.15, 1.3, 0.26), Vector3(0.12, 0.14, 0.08), _mat(Color.WHITE, 0.28))
	_mesh(vis, SphereMesh.new(), Vector3(-0.15, 1.3, 0.3), Vector3(0.055, 0.065, 0.04), ink)
	_mesh(vis, SphereMesh.new(), Vector3(0.15, 1.3, 0.3), Vector3(0.055, 0.065, 0.04), ink)
	_mesh(vis, SphereMesh.new(), Vector3(-0.17, 1.2, 0.24), Vector3(0.13, 0.08, 0.06), _mat(Color("F2A0A8"), 0.55))
	_mesh(vis, SphereMesh.new(), Vector3(0.17, 1.2, 0.24), Vector3(0.13, 0.08, 0.06), _mat(Color("F2A0A8"), 0.55))
	_mesh(vis, CapsuleMesh.new(), Vector3(0, 0.28, 0), Vector3(0.72, 0.44, 0.72), denim)
	_mesh(vis, SphereMesh.new(), Vector3(-0.17, 0.1, 0.1), Vector3(0.22, 0.13, 0.3), pink)
	_mesh(vis, SphereMesh.new(), Vector3(0.17, 0.1, 0.1), Vector3(0.22, 0.13, 0.3), pink)


func _build_cam() -> void:
	spring = SpringArm3D.new()
	spring.spring_length = 9.2
	spring.margin = 0.4
	spring.position = Vector3(0, 1.55, 0)
	var shape := SphereShape3D.new()
	shape.radius = 0.28
	spring.shape = shape
	spring.collision_mask = 1
	add_child(spring)
	var cam := Camera3D.new()
	cam.fov = 62.0
	cam.near = 0.12
	cam.far = 420.0
	spring.add_child(cam)
	cam.current = true


func facing() -> Vector3:
	var f := -vis.global_transform.basis.z
	f.y = 0.0
	if f.length() < 0.05:
		f = -spring.global_transform.basis.z
		f.y = 0.0
	if f.length() < 0.05:
		return Vector3.FORWARD
	return f.normalized()


func _physics_process(delta: float) -> void:
	i_frames = maxf(0.0, i_frames - delta)
	attack_cd = maxf(0.0, attack_cd - delta)
	spin_cd = maxf(0.0, spin_cd - delta)
	spinning = maxf(0.0, spinning - delta)
	punch_t = maxf(0.0, punch_t - delta)
	if vis:
		vis.visible = i_frames <= 0.0 or fmod(i_frames, 0.1) > 0.05
	if arm_r:
		if punch_t > 0.0:
			arm_r.rotation_degrees.x = -95.0
			arm_r.position = Vector3(0.42, 0.78, 0.38)
		else:
			arm_r.rotation_degrees.x = move_toward(arm_r.rotation_degrees.x, 0.0, 420.0 * delta)
			arm_r.position = arm_r.position.lerp(Vector3(0.46, 0.72, 0.02), clampf(delta * 10.0, 0.0, 1.0))

	var look := Vector2(Input.get_axis("aim_left", "aim_right"), Input.get_axis("aim_up", "aim_down"))
	if look.length() > 0.12:
		cam_yaw -= look.x * 1.55 * delta
		cam_pitch = clampf(cam_pitch - look.y * 1.15 * delta, -38.0, -8.0)
		look_stick = 0.5
	else:
		look_stick = maxf(0.0, look_stick - delta)
	spring.rotation.y = cam_yaw
	spring.rotation.x = deg_to_rad(cam_pitch)

	if is_on_floor():
		coyote = 0.16
		if slam_armed:
			slam_armed = false
			_hit_around(global_position + Vector3(0, 0.4, 0), 2.15, 13.0, 5.2)
			FX.punch_flash(get_parent(), global_position + Vector3(0, 0.3, 0))
			AudioDirector.play("thud", 1.15)
	else:
		coyote = maxf(0.0, coyote - delta)
		velocity.y -= gravity * delta
		if velocity.y < 0.0 and not Input.is_action_pressed("jump"):
			velocity.y -= gravity * 0.4 * delta

	if spinning <= 0.0:
		if Input.is_action_just_pressed("jump"):
			jump_buf = 0.16
		else:
			jump_buf = maxf(0.0, jump_buf - delta)
		if jump_buf > 0.0 and coyote > 0.0:
			velocity.y = jump_v
			jump_buf = 0.0
			coyote = 0.0
			squish = 0.78
			AudioDirector.play("jump", 1.06)

		if attack_cd <= 0.0 and (Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("mobility")):
			if is_on_floor():
				_punch()
			else:
				_slam()
		if spin_cd <= 0.0 and Input.is_action_just_pressed("signature"):
			_spin()

	if spinning > 0.0:
		vis.rotate_y(delta * 18.0)
		_hit_around(global_position + Vector3(0, 0.7, 0), 1.85, 11.0, 4.5)

	var input := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	if input.length() > 1.0:
		input = input.normalized()
	var forward := -spring.global_transform.basis.z
	forward.y = 0.0
	if forward.length() > 0.01:
		forward = forward.normalized()
	var right := spring.global_transform.basis.x
	right.y = 0.0
	if right.length() > 0.01:
		right = right.normalized()
	var wish := right * input.x + forward * (-input.y)
	wish.y = 0.0
	var spd := move_speed
	if punch_t > 0.0:
		spd *= 0.55
	if spinning > 0.0:
		spd *= 1.15
	if wish.length() > 0.12:
		wish = wish.normalized()
		var target := atan2(wish.x, wish.z)
		if spinning <= 0.0:
			vis.rotation.y = lerp_angle(vis.rotation.y, target, 1.0 - pow(0.001, delta))
		if is_on_floor() and look_stick <= 0.0 and spinning <= 0.0:
			cam_yaw = lerp_angle(cam_yaw, target, delta * 1.05)
		velocity.x = wish.x * spd
		velocity.z = wish.z * spd
	else:
		velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)

	splash_cd = maxf(0.0, splash_cd - delta)
	if global_position.y < 0.18:
		var home := Vector3(spawn.x, 0.0, spawn.z)
		var to := home - Vector3(global_position.x, 0.0, global_position.z)
		if to.length() > 0.2:
			to = to.normalized()
			velocity.x = to.x * 6.0
			velocity.z = to.z * 6.0
		velocity.y = maxf(velocity.y, 5.0)
		if splash_cd <= 0.0:
			FX.splash(get_parent(), Vector3(global_position.x, 0.25, global_position.z))
			splash_cd = 0.45

	move_and_slide()
	if global_position.y < -6.0:
		global_position = spawn
		velocity = Vector3.ZERO

	squish = move_toward(squish, 1.0, delta * 3.4)
	if vis and spinning <= 0.0:
		vis.scale = Vector3(2.0 - squish, squish, 2.0 - squish)


func _punch() -> void:
	attack_cd = 0.32
	punch_t = 0.18
	var f := facing()
	velocity += f * 5.5
	velocity.y = maxf(velocity.y, 1.5)
	squish = 0.86
	AudioDirector.play("whoosh", 1.15)
	var origin := global_position + Vector3(0, 0.75, 0) + f * 0.95
	FX.punch_flash(get_parent(), origin)
	_hit_around(origin, 1.25, 10.5, 4.2)


func _slam() -> void:
	attack_cd = 0.4
	slam_armed = true
	velocity.y = -15.0
	var f := facing()
	velocity.x += f.x * 3.0
	velocity.z += f.z * 3.0
	AudioDirector.play("whoosh", 0.8)


func _spin() -> void:
	spin_cd = 2.4
	spinning = 0.55
	attack_cd = 0.55
	squish = 0.8
	velocity.y = maxf(velocity.y, 3.5)
	AudioDirector.play("surge", 1.4)


func _hit_around(origin: Vector3, radius: float, knock: float, lift: float) -> void:
	var sh := SphereShape3D.new()
	sh.radius = radius
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = sh
	q.transform = Transform3D(Basis(), origin)
	q.collision_mask = 4
	q.exclude = [get_rid()]
	var hits := get_world_3d().direct_space_state.intersect_shape(q, 12)
	for h in hits:
		var n: Object = h.get("collider")
		if n is Node and (n as Node).has_method("receive_hit"):
			(n as Node).receive_hit(self, 1, knock)
			if n is CharacterBody3D:
				(n as CharacterBody3D).velocity.y = maxf((n as CharacterBody3D).velocity.y, lift)


func receive_hit(source: Node3D, damage: int, knock: float) -> bool:
	if i_frames > 0.0 or spinning > 0.0:
		return false
	hp = maxi(0, hp - maxi(damage, 1))
	i_frames = 1.05
	var away := global_position - source.global_position
	away.y = 0.0
	if away.length() < 0.05:
		away = -facing()
	away = away.normalized()
	velocity = away * knock
	velocity.y = 5.0
	squish = 0.7
	AudioDirector.play("hurt", 1.1)
	FX.burst(get_parent(), global_position + Vector3(0, 0.8, 0), Color("2BB3A8"), 8, 1.6)
	if hp <= 0:
		hp = max_hp
		i_frames = 1.6
		global_position = spawn
		velocity = Vector3.ZERO
		AudioDirector.play("shield", 0.9)
	hp_changed.emit(hp, max_hp)
	return true


func heal(n: int = 1) -> void:
	hp = mini(max_hp, hp + n)
	hp_changed.emit(hp, max_hp)


func bounce(power: float = 12.0) -> void:
	velocity.y = power
	squish = 0.68
	AudioDirector.play("jump", 1.28)


func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	m.rim_enabled = true
	m.rim = 0.28
	m.rim_tint = 0.4
	return m


func _mesh(parent: Node3D, mesh: PrimitiveMesh, pos: Vector3, sc: Vector3, mat: Material) -> MeshInstance3D:
	if mesh is SphereMesh:
		var s: SphereMesh = mesh
		s.radius = 0.5
		s.height = 1.0
	elif mesh is CapsuleMesh:
		var c: CapsuleMesh = mesh
		c.radius = 0.5
		c.height = 1.4
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.scale = sc
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	return mi
