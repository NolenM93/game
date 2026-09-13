class_name ArenaFoe
extends CharacterBody3D

const FX = preload("res://scripts/day/arena_fx.gd")

signal popped

var kind := "grump"
var target: Node3D
var hp := 3
var max_hp := 3
var move_speed := 3.4
var vis: Node3D
var tag: Label3D
var state := "chase"
var wind := 0.0
var stun := 0.0
var strike := 0.0
var hop := 0.0
var i_frames := 0.0
var squish := 1.0
var ring_r := 13.2
var dead := false


func setup(p_kind: String, p_target: Node3D) -> void:
	kind = p_kind
	target = p_target
	match kind:
		"hopper":
			hp = 3
			move_speed = 4.2
		"champ":
			hp = 8
			move_speed = 2.7
		_:
			hp = 3
			move_speed = 3.5
	max_hp = hp


func _ready() -> void:
	add_to_group("foe")
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 0.22
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	if kind == "champ":
		cap.radius = 0.62
		cap.height = 1.7
		cs.position.y = 0.88
	else:
		cap.radius = 0.42
		cap.height = 1.15
		cs.position.y = 0.62
	cs.shape = cap
	add_child(cs)
	_build_look()
	tag = Label3D.new()
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.font_size = 42
	tag.outline_size = 10
	tag.outline_modulate = Color(0.1, 0.1, 0.14, 0.9)
	tag.position.y = 1.85 if kind != "champ" else 2.45
	add_child(tag)
	_refresh_tag()


func _build_look() -> void:
	vis = Node3D.new()
	add_child(vis)
	var body: Color
	var pants: Color
	match kind:
		"hopper":
			body = Color("7DCFC4")
			pants = Color("2F6B62")
		"champ":
			body = Color("E24B4B")
			pants = Color("3A2414")
		_:
			body = Color("B07CFF")
			pants = Color("4A3370")
	var skin := _mat(Color("E8B48A"))
	var ink := _mat(Color("1A1520"))
	var sc := 1.45 if kind == "champ" else 1.0
	_mesh(vis, CapsuleMesh.new(), Vector3(0, 0.64, 0) * sc, Vector3(0.86, 0.76, 0.86) * sc, _mat(body))
	_mesh(vis, CapsuleMesh.new(), Vector3(-0.48, 0.72, 0.04) * sc, Vector3(0.3, 0.38, 0.3) * sc, _mat(body))
	_mesh(vis, CapsuleMesh.new(), Vector3(0.48, 0.72, 0.04) * sc, Vector3(0.3, 0.38, 0.3) * sc, _mat(body))
	_mesh(vis, SphereMesh.new(), Vector3(0, 1.28, 0.04) * sc, Vector3(0.68, 0.68, 0.68) * sc, skin)
	_mesh(vis, SphereMesh.new(), Vector3(0, 1.44, -0.06) * sc, Vector3(0.72, 0.34, 0.68) * sc, ink)
	_mesh(vis, SphereMesh.new(), Vector3(-0.16, 1.32, 0.28) * sc, Vector3(0.12, 0.08, 0.06) * sc, ink)
	_mesh(vis, SphereMesh.new(), Vector3(0.16, 1.32, 0.28) * sc, Vector3(0.12, 0.08, 0.06) * sc, ink)
	_mesh(vis, BoxMesh.new(), Vector3(-0.18, 1.44, 0.22) * sc, Vector3(0.18, 0.06, 0.08) * sc, ink)
	_mesh(vis, BoxMesh.new(), Vector3(0.18, 1.44, 0.22) * sc, Vector3(0.18, 0.06, 0.08) * sc, ink)
	_mesh(vis, CapsuleMesh.new(), Vector3(0, 0.28, 0) * sc, Vector3(0.74, 0.44, 0.74) * sc, _mat(pants))
	if kind == "champ":
		_mesh(vis, TorusMesh.new(), Vector3(0, 0.82, 0) * sc, Vector3(0.7, 0.7, 0.7) * sc, _mat(Color("F4C542")))
	if kind == "hopper":
		_mesh(vis, CapsuleMesh.new(), Vector3(-0.18, 0.18, 0.04) * sc, Vector3(0.22, 0.7, 0.22) * sc, _mat(pants))
		_mesh(vis, CapsuleMesh.new(), Vector3(0.18, 0.18, 0.04) * sc, Vector3(0.22, 0.7, 0.22) * sc, _mat(pants))


func _physics_process(delta: float) -> void:
	if dead:
		return
	i_frames = maxf(0.0, i_frames - delta)
	stun = maxf(0.0, stun - delta)
	hop = maxf(0.0, hop - delta)
	if vis:
		vis.visible = i_frames <= 0.0 or fmod(i_frames, 0.12) > 0.06
	if not is_on_floor():
		velocity.y -= 26.0 * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0

	var xz := Vector2(global_position.x, global_position.z)
	if global_position.y < 0.2 or xz.length() > ring_r + 2.4:
		_ko(true)
		return

	if stun > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
		move_and_slide()
		_squash(delta)
		return

	if target == null or not is_instance_valid(target):
		move_and_slide()
		return

	var to := target.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	var dir := to.normalized() if dist > 0.05 else Vector3.FORWARD

	if xz.length() > ring_r - 1.6:
		var inward := Vector3(-xz.x, 0.0, -xz.y).normalized()
		dir = (dir + inward * 1.6).normalized()

	match state:
		"windup":
			wind -= delta
			velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
			if vis:
				vis.scale = Vector3(1.12, 0.9, 1.12)
			if wind <= 0.0:
				state = "strike"
				strike = 0.22
				velocity = dir * (10.0 if kind != "champ" else 8.0)
				velocity.y = 2.2
				AudioDirector.play("whoosh", 0.9)
		"strike":
			strike -= delta
			_try_hit_player()
			if strike <= 0.0:
				state = "chase"
				hop = 0.55
		_:
			state = "chase"
			if vis:
				vis.rotation.y = lerp_angle(vis.rotation.y, atan2(dir.x, dir.z), 0.2)
			if kind == "hopper" and hop <= 0.0 and is_on_floor() and dist < 10.0:
				velocity = dir * 6.5
				velocity.y = 7.8
				hop = 1.35
				AudioDirector.play("jump", 0.82)
			elif dist > 1.55:
				velocity.x = dir.x * move_speed
				velocity.z = dir.z * move_speed
			else:
				velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
				velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)
				if hop <= 0.0:
					state = "windup"
					wind = 0.42 if kind != "champ" else 0.55
					hop = 0.8
					AudioDirector.play("charge", 1.2)

	move_and_slide()
	_squash(delta)


func _try_hit_player() -> void:
	if target == null or not target.has_method("receive_hit"):
		return
	var d := global_position.distance_to(target.global_position)
	var reach := 1.7 if kind != "champ" else 2.15
	if d <= reach:
		target.receive_hit(self, 1, 8.5)


func receive_hit(source: Node3D, damage: int, knock: float) -> bool:
	if dead or i_frames > 0.0:
		return false
	hp -= maxi(damage, 1)
	i_frames = 0.28
	stun = 0.38
	state = "chase"
	var away := global_position - source.global_position
	away.y = 0.0
	if away.length() < 0.05:
		away = Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)
	away = away.normalized()
	velocity = away * knock
	velocity.y = 4.8 + knock * 0.12
	squish = 0.62
	AudioDirector.play("hit", randf_range(0.92, 1.12))
	FX.burst(get_parent(), global_position + Vector3(0, 0.9, 0), Color("FFE27A"), 8, 1.8)
	_refresh_tag()
	if hp <= 0:
		_ko(false)
	return true


func bounce(power: float = 12.0) -> void:
	velocity.y = power
	squish = 0.7


func _ko(water: bool) -> void:
	if dead:
		return
	dead = true
	collision_layer = 0
	AudioDirector.play("thud", 1.05)
	if water:
		FX.splash(get_parent(), Vector3(global_position.x, 0.3, global_position.z))
	else:
		FX.burst(get_parent(), global_position + Vector3(0, 0.8, 0), Color("B07CFF"), 18, 2.6)
	popped.emit()
	queue_free()


func _refresh_tag() -> void:
	if tag == null:
		return
	var n := maxi(hp, 0)
	if n <= 0:
		tag.text = ""
		return
	var s := ""
	for i in n:
		s += "●"
	tag.text = s
	tag.modulate = Color("FFE27A") if kind == "champ" else Color("FF9AD8")


func _squash(delta: float) -> void:
	squish = move_toward(squish, 1.0, delta * 4.0)
	if vis and state != "windup":
		vis.scale = Vector3(2.0 - squish, squish, 2.0 - squish)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.62
	m.rim_enabled = true
	m.rim = 0.26
	return m


func _mesh(parent: Node3D, mesh: PrimitiveMesh, pos: Vector3, sc: Vector3, mat: Material) -> void:
	if mesh is SphereMesh:
		(mesh as SphereMesh).radius = 0.5
		(mesh as SphereMesh).height = 1.0
	elif mesh is CapsuleMesh:
		(mesh as CapsuleMesh).radius = 0.5
		(mesh as CapsuleMesh).height = 1.4
	elif mesh is TorusMesh:
		(mesh as TorusMesh).inner_radius = 0.08
		(mesh as TorusMesh).outer_radius = 0.42
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.scale = sc
	mi.material_override = mat
	parent.add_child(mi)
