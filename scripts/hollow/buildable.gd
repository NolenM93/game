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
	tag.font_size = 28
	tag.outline_size = 8
	tag.position.y = 1.85
	add_child(tag)
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
			_ball(Vector3(0, 1.45, 0), 0.42, Color("E07020"))
			_box(Vector3(0, 1.45, 0.45), Vector3(0.16, 0.16, 0.7), Color("4A4A52"))
			_box(Vector3(-0.18, 1.55, 0.2), Vector3(0.1, 0.08, 0.06), Color("1A1520"))
			_box(Vector3(0.18, 1.55, 0.2), Vector3(0.1, 0.08, 0.06), Color("1A1520"))
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


func _turret(_delta: float) -> void:
	var best: Node3D = null
	var best_d := 14.0
	for n in get_tree().get_nodes_in_group("zed"):
		if n is Node3D:
			var d: float = global_position.distance_to((n as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = n
	if best == null:
		return
	var look := best.global_position
	look.y = vis.global_position.y
	if vis and vis.global_position.distance_to(look) > 0.2:
		vis.look_at(look, Vector3.UP)
	if fire_cd <= 0.0:
		fire_cd = 0.55
		if best.has_method("receive_shot"):
			var dir := (best.global_position - global_position).normalized()
			best.receive_shot(best.global_position + Vector3(0, 0.8, 0), dir, 2, 3.5, "pea")
			FX.tracer(get_parent(), global_position + Vector3(0, 1.45, 0), best.global_position + Vector3(0, 0.9, 0), Color("FFE27A"))
			AudioDirector.play("spark", 0.8)


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


func _hurt(dmg: int) -> void:
	hp -= dmg
	_refresh()
	if hp <= 0:
		FX.wood(get_parent(), global_position + Vector3(0, 0.6, 0))
		AudioDirector.play("thud", 0.85)
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
		tag.text = "HP %d" % maxi(hp, 0)
		tag.modulate = Color("B8C4A8")


func _mat(c: Color) -> StandardMaterial3D:
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
