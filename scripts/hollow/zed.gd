extends CharacterBody3D

const FX = preload("res://scripts/hollow/hollow_fx.gd")

signal popped(kind: String, pos: Vector3)

var kind := "shambler"
var keep: Node3D
var hunter: Node3D
var vis: Node3D
var core := 8
var speed := 2.45
var chew_cd := 0.0
var swipe_cd := 0.0
var slow := 0.0
var stun := 0.0
var i_frames := 0.0
var crawling := false
var dead := false
var slam_t := 0.0
var air_slam := false
var groan_t := randf() * 4.0
var chewing: Node = null
var parts: Dictionary = {}
var skin := Color("6E8A4A")
var shirt := Color("3A4630")
var walk_t := 0.0
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D


func setup(p_kind: String, p_keep: Node3D, p_hunter: Node3D) -> void:
	kind = p_kind
	keep = p_keep
	hunter = p_hunter
	match kind:
		"runner":
			core = 5
			speed = 5.15
			skin = Color("8FB05A")
			shirt = Color("4A3220")
		"lunk":
			core = 22
			speed = 1.65
			skin = Color("5A6A48")
			shirt = Color("3A3020")
		"mayor":
			core = 48
			speed = 1.9
			skin = Color("7A8A5A")
			shirt = Color("2A2438")
		_:
			core = 8
			speed = 2.45
			skin = Color("6E8A4A")
			shirt = Color("3A4630")
	skin = skin.lerp(Color("4A5A38"), randf() * 0.25)


func _ready() -> void:
	add_to_group("zed")
	collision_layer = 4
	collision_mask = 1 | 16 | 32
	floor_snap_length = 0.2
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	var sc := 1.0
	if kind == "lunk":
		sc = 1.4
	elif kind == "mayor":
		sc = 1.55
	elif kind == "runner":
		sc = 0.88
	cap.radius = 0.38 * sc
	cap.height = 1.2 * sc
	cs.shape = cap
	cs.position.y = 0.65 * sc
	add_child(cs)
	_build(sc)
	groan_t = randf_range(1.5, 5.0)


func _build(sc: float) -> void:
	vis = Node3D.new()
	add_child(vis)
	if kind == "shambler":
		vis.rotation.x = 0.18
	elif kind == "runner":
		vis.rotation.x = 0.28
	var pants := shirt.darkened(0.18)
	var bone := Color("C8C4A8")
	var ink := Color("1A1814")
	var glow := Color("FFE27A")
	# hips
	_part("torso", _limb(Vector3(0, 0.78, 0) * sc), 99)
	var torso: Node3D = parts["torso"]["node"]
	_box(torso, Vector3(0, 0.02, 0.02) * sc, Vector3(0.46, 0.5, 0.3) * sc, shirt)
	_box(torso, Vector3(0, -0.18, 0.0) * sc, Vector3(0.4, 0.18, 0.26) * sc, pants)
	_box(torso, Vector3(-0.12, 0.08, 0.16) * sc, Vector3(0.16, 0.22, 0.06) * sc, shirt.lightened(0.08))
	if kind == "lunk":
		_box(torso, Vector3(0, 0.08, 0) * sc, Vector3(0.62, 0.55, 0.42) * sc, shirt)
		_box(torso, Vector3(-0.28, 0.28, 0.02) * sc, Vector3(0.22, 0.16, 0.28) * sc, Color("4A4030"))
		_box(torso, Vector3(0.28, 0.28, 0.02) * sc, Vector3(0.22, 0.16, 0.28) * sc, Color("4A4030"))
	if kind == "mayor":
		_box(torso, Vector3(0, 0.04, -0.06) * sc, Vector3(0.52, 0.62, 0.22) * sc, shirt)
		_box(torso, Vector3(-0.16, -0.22, -0.12) * sc, Vector3(0.16, 0.4, 0.08) * sc, shirt)
		_box(torso, Vector3(0.16, -0.22, -0.12) * sc, Vector3(0.16, 0.4, 0.08) * sc, shirt)
		_box(torso, Vector3(0, 0.08, 0.16) * sc, Vector3(0.38, 0.08, 0.04) * sc, Color("C4A24A"))
	if kind == "runner":
		_box(torso, Vector3(0, 0.18, -0.02) * sc, Vector3(0.38, 0.28, 0.32) * sc, Color("3A2A20"))
	# head
	_part("head", _limb(Vector3(0, 1.28, 0.06) * sc), 3 if kind == "lunk" or kind == "mayor" else 2)
	var head: Node3D = parts["head"]["node"]
	if kind == "lunk":
		_ball(head, Vector3(0, 0.02, 0) * sc, 0.28 * sc, Color("E07020"), true)
		_box(head, Vector3(-0.08, 0.02, 0.22) * sc, Vector3(0.08, 0.05, 0.04) * sc, ink)
		_box(head, Vector3(0.08, 0.02, 0.22) * sc, Vector3(0.08, 0.05, 0.04) * sc, ink)
		_box(head, Vector3(0, -0.08, 0.22) * sc, Vector3(0.14, 0.04, 0.04) * sc, ink)
		_cyl(head, Vector3(0, 0.28, 0) * sc, Vector3(0.05, 0.16, 0.05) * sc, Color("3A8A3A"))
	else:
		_ball(head, Vector3(0, 0.02, 0) * sc, 0.26 * sc, skin)
		_box(head, Vector3(0, -0.12, 0.08) * sc, Vector3(0.18, 0.1, 0.16) * sc, skin.darkened(0.08))
		_box(head, Vector3(-0.08, 0.04, 0.2) * sc, Vector3(0.1, 0.08, 0.06) * sc, ink)
		_box(head, Vector3(0.08, 0.04, 0.2) * sc, Vector3(0.1, 0.08, 0.06) * sc, ink)
		_ball(head, Vector3(-0.08, 0.04, 0.22) * sc, 0.05 * sc, glow, true)
		_ball(head, Vector3(0.08, 0.04, 0.22) * sc, 0.05 * sc, glow, true)
		_box(head, Vector3(0, -0.14, 0.16) * sc, Vector3(0.14, 0.04, 0.08) * sc, bone)
		_box(head, Vector3(-0.1, 0.1, 0.04) * sc, Vector3(0.08, 0.03, 0.16) * sc, ink)
	if kind == "mayor":
		_part("hat", _limb(Vector3(0, 1.52, 0.04) * sc), 2)
		var hat: Node3D = parts["hat"]["node"]
		_cyl(hat, Vector3(0, 0.12, 0) * sc, Vector3(0.28, 0.28, 0.28) * sc, Color("1A1520"))
		_cyl(hat, Vector3(0, 0.0, 0) * sc, Vector3(0.42, 0.05, 0.42) * sc, Color("1A1520"))
		_box(hat, Vector3(0, 0.08, 0.22) * sc, Vector3(0.16, 0.04, 0.04) * sc, Color("C4A24A"))
	# arms
	arm_l = _limb(Vector3(-0.28, 0.98, 0.04) * sc)
	arm_r = _limb(Vector3(0.28, 0.98, 0.04) * sc)
	_part("arm_l", arm_l, 2)
	_part("arm_r", arm_r, 2)
	_box(arm_l, Vector3(0, 0, 0) * sc, Vector3(0.16, 0.16, 0.16) * sc, shirt)
	_cap(arm_l, Vector3(-0.04, -0.2, 0.06) * sc, Vector3(0.14, 0.36, 0.14) * sc, skin)
	_cap(arm_l, Vector3(-0.02, -0.42, 0.1) * sc, Vector3(0.12, 0.28, 0.12) * sc, skin)
	_box(arm_l, Vector3(-0.04, -0.56, 0.16) * sc, Vector3(0.1, 0.08, 0.16) * sc, skin.darkened(0.1))
	_box(arm_r, Vector3(0, 0, 0) * sc, Vector3(0.16, 0.16, 0.16) * sc, shirt)
	_cap(arm_r, Vector3(0.04, -0.2, 0.06) * sc, Vector3(0.14, 0.36, 0.14) * sc, skin)
	_cap(arm_r, Vector3(0.02, -0.42, 0.12) * sc, Vector3(0.12, 0.28, 0.12) * sc, skin)
	_box(arm_r, Vector3(0.04, -0.56, 0.18) * sc, Vector3(0.1, 0.08, 0.16) * sc, skin.darkened(0.1))
	arm_l.rotation_degrees.x = 18.0 if kind != "runner" else 40.0
	arm_r.rotation_degrees.x = -8.0 if kind != "runner" else 28.0
	arm_l.rotation_degrees.z = 16.0
	arm_r.rotation_degrees.z = -12.0
	# legs
	leg_l = _limb(Vector3(-0.12, 0.62, 0.0) * sc)
	leg_r = _limb(Vector3(0.12, 0.62, 0.0) * sc)
	_part("leg_l", leg_l, 2)
	_part("leg_r", leg_r, 2)
	_cap(leg_l, Vector3(0, -0.16, 0.02) * sc, Vector3(0.16, 0.32, 0.16) * sc, pants)
	_cap(leg_l, Vector3(0, -0.4, 0.04) * sc, Vector3(0.14, 0.26, 0.14) * sc, pants)
	_box(leg_l, Vector3(0, -0.56, 0.06) * sc, Vector3(0.16, 0.1, 0.26) * sc, ink)
	_cap(leg_r, Vector3(0, -0.16, 0.02) * sc, Vector3(0.16, 0.32, 0.16) * sc, pants)
	_cap(leg_r, Vector3(0, -0.4, 0.04) * sc, Vector3(0.14, 0.26, 0.14) * sc, pants)
	_box(leg_r, Vector3(0, -0.56, 0.06) * sc, Vector3(0.16, 0.1, 0.26) * sc, Color("3A2A1C") if kind != "runner" else Color("4A2018"))


func _part(id: String, n: Node3D, hp: int) -> void:
	parts[id] = {"node": n, "hp": hp, "on": true}


func _limb(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	vis.add_child(n)
	return n


func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3.ONE
	mi.mesh = b
	mi.position = pos
	mi.scale = size
	mi.material_override = _mat(color)
	parent.add_child(mi)
	return mi


func _cap(parent: Node3D, pos: Vector3, sc: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CapsuleMesh.new()
	c.radius = 0.5
	c.height = 1.4
	mi.mesh = c
	mi.position = pos
	mi.scale = sc
	mi.material_override = _mat(color)
	parent.add_child(mi)
	return mi


func _ball(parent: Node3D, pos: Vector3, r: float, color: Color, lit: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	mi.mesh = s
	mi.position = pos
	var m := _mat(color)
	if lit:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 1.8
	mi.material_override = m
	parent.add_child(mi)
	return mi


func _cyl(parent: Node3D, pos: Vector3, sc: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.5
	c.bottom_radius = 0.5
	c.height = 1.0
	mi.mesh = c
	mi.position = pos
	mi.scale = sc
	mi.material_override = _mat(color)
	parent.add_child(mi)
	return mi


func _physics_process(delta: float) -> void:
	if dead:
		return
	i_frames = maxf(0.0, i_frames - delta)
	slow = maxf(0.0, slow - delta)
	stun = maxf(0.0, stun - delta)
	chew_cd = maxf(0.0, chew_cd - delta)
	swipe_cd = maxf(0.0, swipe_cd - delta)
	slam_t = maxf(0.0, slam_t - delta)
	groan_t -= delta
	if groan_t <= 0.0:
		AudioDirector.play("groan", randf_range(0.7, 1.15))
		groan_t = randf_range(3.5, 7.5)
	if vis:
		vis.visible = i_frames <= 0.0 or fmod(i_frames, 0.1) > 0.05
	if not is_on_floor():
		velocity.y -= 26.0 * delta

	if stun > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
		move_and_slide()
		return

	var mul := 0.38 if slow > 0.0 else 1.0
	if crawling:
		mul *= 0.42
		if vis:
			vis.rotation.x = lerp_angle(vis.rotation.x, deg_to_rad(78.0), 0.12)
			vis.position.y = 0.15
	var spd := speed * mul

	var goal := _goal()
	var to := goal - global_position
	to.y = 0.0
	var dist := to.length()
	var dir := to.normalized() if dist > 0.08 else Vector3.FORWARD

	if vis and not crawling:
		vis.rotation.y = lerp_angle(vis.rotation.y, atan2(dir.x, dir.z), 0.16)
		walk_t += delta * clampf(spd * 2.2, 3.0, 9.0)
		var swing := sin(walk_t) * 0.45
		if kind == "runner":
			swing *= 1.25
		if arm_l and parts.has("arm_l") and parts["arm_l"]["on"]:
			arm_l.rotation.x = deg_to_rad(18.0) + swing
		if arm_r and parts.has("arm_r") and parts["arm_r"]["on"]:
			arm_r.rotation.x = deg_to_rad(-8.0) - swing
		if leg_l and parts.has("leg_l") and parts["leg_l"]["on"]:
			leg_l.rotation.x = swing * 0.8
		if leg_r and parts.has("leg_r") and parts["leg_r"]["on"]:
			leg_r.rotation.x = -swing * 0.8

	if kind == "mayor" and slam_t <= 0.0 and hunter and global_position.distance_to(hunter.global_position) < 5.0:
		slam_t = 5.5
		air_slam = true
		velocity = dir * 3.0
		velocity.y = 7.5
		AudioDirector.play("whoom", 0.8)

	var blocked := _front_build(dir)
	if blocked and blocked.has_method("chew"):
		velocity.x = 0.0
		velocity.z = 0.0
		if chew_cd <= 0.0:
			chew_cd = 0.7
			blocked.chew(4)
			AudioDirector.play("thud", 1.3)
	elif keep and global_position.distance_to(keep.global_position) < 2.4:
		velocity.x = 0.0
		velocity.z = 0.0
		if chew_cd <= 0.0 and keep.has_method("chew"):
			chew_cd = 0.85
			keep.chew(3 if kind != "lunk" else 6)
	else:
		if hunter and is_instance_valid(hunter) and _wants_hunter() and global_position.distance_to(hunter.global_position) < 1.55:
			velocity.x = 0.0
			velocity.z = 0.0
			if swipe_cd <= 0.0:
				swipe_cd = 1.05
				if hunter.has_method("receive_hit"):
					hunter.receive_hit(self, 1, 7.5)
				AudioDirector.play("whoosh", 0.7)
		else:
			velocity.x = dir.x * spd
			velocity.z = dir.z * spd
	move_and_slide()
	if air_slam and is_on_floor():
		air_slam = false
		if hunter and global_position.distance_to(hunter.global_position) < 3.4 and hunter.has_method("receive_hit"):
			hunter.receive_hit(self, 1, 10.0)
		FX.burst(get_parent(), global_position, Color("5A5E62"), 10, 1.6)
		AudioDirector.play("thud", 0.6)
	if global_position.y < -2.5:
		_die()


func _goal() -> Vector3:
	if hunter and is_instance_valid(hunter) and _wants_hunter():
		return hunter.global_position
	if keep:
		return keep.global_position
	return Vector3.ZERO


func _wants_hunter() -> bool:
	if hunter == null or not is_instance_valid(hunter):
		return false
	var hd: float = global_position.distance_to(hunter.global_position)
	if kind == "runner":
		return hd < 12.0
	if keep:
		var kd: float = global_position.distance_to(keep.global_position)
		return hd < 4.5 and hd + 1.5 < kd
	return hd < 4.0


func _front_build(dir: Vector3) -> Node:
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.7, 0), global_position + Vector3(0, 0.7, 0) + dir * 1.35)
	q.collision_mask = 16
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit and hit.get("collider") is Node:
		return hit.get("collider")
	return null


func start_chew(node: Node) -> void:
	chewing = node


func apply_slow(t: float) -> void:
	slow = maxf(slow, t)
	if vis:
		vis.scale = Vector3(1.08, 0.9, 1.08)


func receive_shot(pos: Vector3, dir: Vector3, dmg: int, knock: float, style: String = "") -> void:
	if dead:
		return
	if style == "wire" and i_frames > 0.0:
		return
	i_frames = 0.08 if style == "wire" or style == "spikes" else 0.12
	var limb := _nearest(pos)
	if limb != "" and parts[limb]["on"]:
		parts[limb]["hp"] -= dmg
		if parts[limb]["hp"] <= 0:
			_detach(limb, dir)
		else:
			FX.spark(get_parent(), pos)
	core -= dmg if limb != "head" else int(ceil(float(dmg) * 1.6))
	if limb == "head":
		FX.float_text(get_parent(), pos, "HEAD!", Color("FFE27A"))
	stun = 0.12
	var push := dir
	push.y = 0.0
	if push.length() < 0.05:
		push = -vis.global_transform.basis.z
	velocity += push.normalized() * knock
	velocity.y = maxf(velocity.y, 2.2)
	AudioDirector.play("hit2", randf_range(0.85, 1.2))
	if core <= 0:
		_die()
		return
	_crawl_check()


func _nearest(pos: Vector3) -> String:
	var best := ""
	var best_d := 0.85
	for id in parts.keys():
		if id == "torso":
			continue
		var p: Dictionary = parts[id]
		if not p["on"]:
			continue
		var n: Node3D = p["node"]
		if n == null or not is_instance_valid(n):
			continue
		var d: float = n.global_position.distance_to(pos)
		if d < best_d:
			best_d = d
			best = id
	return best


func _detach(id: String, dir: Vector3) -> void:
	var p: Dictionary = parts[id]
	if not p["on"]:
		return
	p["on"] = false
	var n: Node3D = p["node"]
	n.visible = false
	var col := skin
	for c in n.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).material_override is StandardMaterial3D:
			col = ((c as MeshInstance3D).material_override as StandardMaterial3D).albedo_color
			break
	FX.fling_bit(get_parent(), n.global_transform, col, 0.22, dir)
	FX.goo(get_parent(), n.global_position)
	AudioDirector.play("limb", randf_range(0.9, 1.25))
	var label := id.replace("_", " ").to_upper()
	if id == "head":
		label = "BONK!"
	elif id.begins_with("arm"):
		label = "ARM!"
	elif id.begins_with("leg"):
		label = "WHOOPS!"
	elif id == "hat":
		label = "HAT!"
	FX.float_text(get_parent(), n.global_position, label, Color("D4FF8A"))
	if get_parent().has_method("add_candy"):
		get_parent().add_candy(1, n.global_position)
	_crawl_check()


func _crawl_check() -> void:
	var legs := 0
	if parts.has("leg_l") and parts["leg_l"]["on"]:
		legs += 1
	if parts.has("leg_r") and parts["leg_r"]["on"]:
		legs += 1
	if legs <= 0 and not crawling:
		crawling = true
		FX.float_text(get_parent(), global_position, "CRAWLER!", Color("C9A0FF"))


func _die() -> void:
	if dead:
		return
	dead = true
	collision_layer = 0
	for id in parts.keys():
		var p: Dictionary = parts[id]
		if p["on"] and p["node"]:
			var n: Node3D = p["node"]
			var col := skin
			for c in n.get_children():
				if c is MeshInstance3D and (c as MeshInstance3D).material_override is StandardMaterial3D:
					col = ((c as MeshInstance3D).material_override as StandardMaterial3D).albedo_color
					break
			FX.fling_bit(get_parent(), n.global_transform, col, 0.2, Vector3(randf_range(-1, 1), 1, randf_range(-1, 1)))
	FX.goo(get_parent(), global_position + Vector3(0, 0.8, 0))
	AudioDirector.play("thud", 0.7)
	popped.emit(kind, global_position)
	queue_free()


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.7
	m.rim_enabled = true
	m.rim = 0.32
	return m
