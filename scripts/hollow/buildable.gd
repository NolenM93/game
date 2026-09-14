extends StaticBody3D

const FX = preload("res://scripts/hollow/hollow_fx.gd")

var kind := "fence"
var hp := 40
var max_hp := 40
var vis: Node3D
var tag: Label3D
var fire_cd := 0.0
var fuse := -1.0
var zone: Area3D
var tick := 0.0
var ghost_mat: Material = null
var head: Node3D
var wobble := 0.0


## Builds only the visual meshes (no collision, no logic) so the hunter can show a placement ghost.
func ghost_vis() -> Node3D:
	vis = Node3D.new()
	_mesh()
	var v := vis
	vis = null
	return v


func setup(p_kind: String) -> void:
	kind = p_kind
	match kind:
		"wire":
			hp = 28
		"jack":
			hp = 18
		"turret":
			hp = 34
		"spikes":
			hp = 22
		_:
			hp = 42
	max_hp = hp


func _ready() -> void:
	add_to_group("build")
	collision_layer = 0 if kind == "wire" or kind == "jack" or kind == "spikes" else 16
	collision_mask = 0
	vis = Node3D.new()
	add_child(vis)
	_mesh()
	if kind != "wire" and kind != "jack" and kind != "spikes":
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.7, 1.5, 0.35) if kind == "fence" else Vector3(1.2, 1.1, 1.2)
		if kind == "spikes":
			box.size = Vector3(1.4, 0.45, 1.4)
		cs.shape = box
		cs.position.y = box.size.y * 0.5
		add_child(cs)
	if kind == "wire" or kind == "jack" or kind == "spikes":
		var a := Area3D.new()
		zone = a
		a.monitoring = true
		a.collision_mask = 4
		a.collision_layer = 0
		var cs2 := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 1.15
		cyl.height = 1.4
		cs2.shape = cyl
		cs2.position.y = 0.5
		a.add_child(cs2)
		add_child(a)
		a.body_entered.connect(_touch)
		if kind == "spikes" or kind == "wire":
			a.body_exited.connect(_leave)
	tag = Label3D.new()
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.font_size = 26
	tag.outline_size = 8
	tag.position.y = 1.85
	tag.no_depth_test = true
	if Art.font_emoji:
		tag.font = Art.font_emoji
	add_child(tag)
	# Pop-in so placement feels physical.
	vis.scale = Vector3(1.2, 0.4, 1.2)
	var tw := create_tween()
	tw.tween_property(vis, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_refresh()


func _mesh() -> void:
	match kind:
		"wire":
			_box(Vector3(0, 0.55, 0), Vector3(1.6, 0.08, 0.08), Color("8A9098"))
			_box(Vector3(0, 0.95, 0), Vector3(1.6, 0.08, 0.08), Color("8A9098"))
			_box(Vector3(0, 0.75, 0), Vector3(0.08, 1.1, 0.08), Color("6A7078"))
			_box(Vector3(0.4, 0.75, 0), Vector3(0.06, 1.0, 0.06), Color("C0C6CC"))
			_box(Vector3(-0.4, 0.75, 0), Vector3(0.06, 1.0, 0.06), Color("C0C6CC"))
		"jack":
			_ball(Vector3(0, 0.55, 0), 0.48, Color("E07020"))
			_box(Vector3(0, 1.05, 0), Vector3(0.12, 0.22, 0.12), Color("3A8A3A"))
			_box(Vector3(-0.12, 0.62, 0.38), Vector3(0.1, 0.08, 0.06), Color("1A1520"))
			_box(Vector3(0.12, 0.62, 0.38), Vector3(0.1, 0.08, 0.06), Color("1A1520"))
		"turret":
			_box(Vector3(0, 0.7, 0), Vector3(0.18, 1.4, 0.18), Color("6B3A18"))
			_box(Vector3(0, 0.95, 0), Vector3(1.1, 0.1, 0.1), Color("6B3A18"))
			_box(Vector3(0, 0.06, 0), Vector3(0.6, 0.12, 0.6), Color("3A2A1C"))
			head = Node3D.new()
			head.position = Vector3(0, 1.45, 0)
			vis.add_child(head)
			var keep_vis := vis
			vis = head
			_ball(Vector3.ZERO, 0.42, Color("E07020"))
			_box(Vector3(0, 0.0, 0.45), Vector3(0.16, 0.16, 0.7), Color("4A4A52"))
			_box(Vector3(0, 0.44, 0), Vector3(0.1, 0.2, 0.1), Color("3A8A3A"))
			_box(Vector3(-0.18, 0.1, 0.34), Vector3(0.12, 0.09, 0.06), Color("1A1520"))
			_box(Vector3(0.18, 0.1, 0.34), Vector3(0.12, 0.09, 0.06), Color("1A1520"))
			vis = keep_vis
		"spikes":
			for i in 5:
				var x := -0.5 + i * 0.25
				_box(Vector3(x, 0.35, -0.3), Vector3(0.12, 0.7, 0.12), Color("8A9098"))
				_box(Vector3(x, 0.35, 0.3), Vector3(0.12, 0.7, 0.12), Color("8A9098"))
		_:
			_box(Vector3(-0.7, 0.7, 0), Vector3(0.16, 1.4, 0.16), Color("6B3A18"))
			_box(Vector3(0.7, 0.7, 0), Vector3(0.16, 1.4, 0.16), Color("6B3A18"))
			_box(Vector3(0, 0.55, 0), Vector3(1.55, 0.16, 0.12), Color("C48A4A"))
			_box(Vector3(0, 0.95, 0), Vector3(1.55, 0.16, 0.12), Color("C48A4A"))
			_box(Vector3(0, 1.3, 0), Vector3(1.55, 0.16, 0.12), Color("C48A4A"))


func _physics_process(delta: float) -> void:
	fire_cd = maxf(0.0, fire_cd - delta)
	if wobble > 0.0:
		wobble = maxf(0.0, wobble - delta * 4.0)
		vis.rotation.z = sin(Time.get_ticks_msec() * 0.05) * 0.08 * wobble
		if wobble <= 0.0:
			vis.rotation.z = 0.0
	if kind == "turret":
		_turret(delta)
	if fuse >= 0.0:
		fuse -= delta
		vis.scale = Vector3.ONE * (1.0 + 0.25 * sin(Time.get_ticks_msec() * 0.02))
		if fuse <= 0.0:
			_jack_boom()
	if zone and (kind == "wire" or kind == "spikes"):
		tick -= delta
		if tick <= 0.0:
			tick = 0.4
			for b in zone.get_overlapping_bodies():
				_touch(b)


func _turret(delta: float) -> void:
	var best: Node3D = null
	var best_d := 15.0
	for n in get_tree().get_nodes_in_group("zed"):
		if n is Node3D and not bool(n.get("dead")):
			var d: float = global_position.distance_to((n as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = n
	if head == null:
		return
	if best == null:
		# Idle scan so the crow reads as alive.
		head.rotation.y = lerp_angle(head.rotation.y, sin(Time.get_ticks_msec() * 0.0007) * 0.9, delta * 2.0)
		return
	var to := best.global_position - head.global_position
	var want := atan2(to.x, to.z) - global_rotation.y
	head.rotation.y = lerp_angle(head.rotation.y, want, 1.0 - pow(0.001, delta))
	var aimed := absf(angle_difference(head.rotation.y, want)) < 0.2
	if fire_cd <= 0.0 and aimed:
		fire_cd = 0.55
		if best.has_method("receive_shot"):
			var target: Vector3 = best.call("aim_center") if best.has_method("aim_center") else best.global_position + Vector3(0, 0.8, 0)
			var beak := head.global_position + head.global_transform.basis.z * 0.8
			var dir := (target - beak).normalized()
			best.receive_shot(target, dir, 2, 3.5, "pea")
			FX.tracer(get_parent(), beak, target, Color("FFE27A"))
			AudioDirector.play_at("spark", beak, randf_range(0.75, 0.9))
			head.position.z = -0.12
			var tw := create_tween()
			tw.tween_property(head, "position:z", 0.0, 0.12)


func _touch(n: Node) -> void:
	if not n.is_in_group("zed"):
		return
	match kind:
		"wire":
			if n.has_method("apply_slow"):
				n.apply_slow(0.4)
			if n.has_method("receive_shot"):
				n.receive_shot(n.global_position, Vector3.UP, 1, 0.5, "wire")
			AudioDirector.play("wire", randf_range(0.9, 1.2))
		"spikes":
			if n.has_method("receive_shot"):
				n.receive_shot(n.global_position, Vector3.UP, 2, 1.0, "spikes")
		"jack":
			if fuse < 0.0:
				fuse = 0.45
				AudioDirector.play("charge", 1.3)


func _leave(n: Node) -> void:
	pass


func receive_shot(pos: Vector3, _dir: Vector3, dmg: int, _knock: float, _style: String = "") -> void:
	_hurt(dmg)
	FX.spark(get_parent(), pos)


func chew(dmg: int) -> void:
	_hurt(dmg)
	wobble = 1.0
	FX.burst(get_parent(), global_position + Vector3(0, 0.8, 0), Color("C48A4A"), 4, 1.1)


func _hurt(dmg: int) -> void:
	hp -= dmg
	_refresh()
	if hp <= 0:
		FX.wood(get_parent(), global_position + Vector3(0, 0.6, 0))
		AudioDirector.play_at("thud", global_position, 0.85)
		queue_free()


func _jack_boom() -> void:
	FX.boom(get_parent(), global_position)
	AudioDirector.play("explode", 1.05)
	var sh := SphereShape3D.new()
	sh.radius = 3.4
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = sh
	q.transform = Transform3D(Basis(), global_position)
	q.collision_mask = 4
	var hits := get_world_3d().direct_space_state.intersect_shape(q, 16)
	for h in hits:
		var n: Object = h.get("collider")
		if n is Node and (n as Node).has_method("receive_shot"):
			(n as Node).receive_shot((n as Node3D).global_position, Vector3.UP, 12, 11.0, "rocket")
	queue_free()


func _refresh() -> void:
	if tag:
		# Only nag about HP once the piece has taken a bite.
		if hp >= max_hp:
			tag.text = ""
			return
		var frac := clampf(float(hp) / float(max_hp), 0.0, 1.0)
		var blocks := int(ceil(frac * 6.0))
		var s := ""
		for i in 6:
			s += "▮" if i < blocks else "▯"
		tag.text = s
		tag.modulate = Color("B8C4A8") if frac > 0.5 else (Color("FFB347") if frac > 0.25 else Color("E24B4B"))


func _mat(c: Color) -> Material:
	if ghost_mat:
		return ghost_mat
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.7
	return m


func _box(pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = _mat(color)
	vis.add_child(mi)


func _ball(pos: Vector3, r: float, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	mi.mesh = s
	mi.position = pos
	mi.material_override = _mat(color)
	vis.add_child(mi)
