class_name HollowWheel
extends Area3D

const PackData = preload("res://scripts/hollow/pack.gd")
const LootDrop = preload("res://scripts/hollow/loot.gd")
const FX = preload("res://scripts/hollow/hollow_fx.gd")

const COST := 200

const WEIGHTS := [
	["ammo", 20],
	["candy", 12],
	["heart", 10],
	["oil", 8],
	["gun_nailer", 12],
	["gun_gloop", 10],
	["gun_rocket", 8],
	["gun_stake", 8],
	["gun_hex", 7],
	["gun_frost", 5],
]

var sack: Node3D
var lamp: OmniLight3D
var spinning := false
var near := false
var world: Node
var cost_tag: Label3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 2.8
	cs.shape = sh
	cs.position.y = 1.0
	add_child(cs)
	body_entered.connect(func(n):
		if n.is_in_group("hunter"):
			near = true
	)
	body_exited.connect(func(n):
		if n.is_in_group("hunter"):
			near = false
	)
	_build()


func _build() -> void:
	sack = Node3D.new()
	sack.position = Vector3(0, 0, 0)
	add_child(sack)
	var red := _mat(Color("C43A32"), 0.78)
	red.emission_enabled = true
	red.emission = Color("8A2018")
	red.emission_energy_multiplier = 0.18
	var white := _mat(Color("F4EEE4"), 0.92)
	var gold := _mat(Color("C4A05A"), 0.45)
	gold.metallic = 0.55
	var dark := _mat(Color("2A140E"), 0.9)
	# Slumped sack body.
	_mesh_sphere(sack, Vector3(0.08, 0.95, 0.04), 0.95, red, Vector3(1.22, 1.08, 1.12))
	_mesh_sphere(sack, Vector3(-0.12, 0.55, 0.1), 0.72, red, Vector3(1.15, 0.95, 1.1))
	_mesh_sphere(sack, Vector3(0.22, 0.62, -0.18), 0.55, red, Vector3(1.05, 1.0, 1.08))
	# Cinched mouth.
	_mesh_cyl(sack, Vector3(0.0, 1.72, 0.12), 0.38, 0.16, gold)
	_mesh_sphere(sack, Vector3(0.0, 1.88, 0.18), 0.34, dark, Vector3(1.15, 0.55, 1.05))
	# White fur trim.
	_mesh_torus(sack, Vector3(0.0, 1.68, 0.12), 0.34, 0.48, white)
	# Gold drawstring hanging down the front.
	_mesh_cyl(sack, Vector3(0.18, 1.28, 0.52), 0.035, 0.85, gold)
	_mesh_sphere(sack, Vector3(0.18, 0.82, 0.58), 0.08, gold)
	_mesh_cyl(sack, Vector3(-0.16, 1.22, 0.5), 0.035, 0.7, gold)
	_mesh_sphere(sack, Vector3(-0.16, 0.86, 0.55), 0.08, gold)
	# Gift tag.
	_mesh_box(sack, Vector3(0.42, 1.35, 0.38), Vector3(0.28, 0.36, 0.04), Color("FFF6D8"))
	var tag := Label3D.new()
	tag.text = "🎅  SANTA'S SACK"
	tag.font_size = 40
	tag.outline_size = 8
	tag.position = Vector3(0, 2.55, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color("FFE27A")
	if Art.font_emoji:
		tag.font = Art.font_emoji
	add_child(tag)
	cost_tag = Label3D.new()
	cost_tag.text = "%d 🪙  a dip" % COST
	cost_tag.font_size = 28
	cost_tag.outline_size = 6
	cost_tag.position = Vector3(0, 0.22, 0.95)
	cost_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	cost_tag.modulate = Color("FFE27A")
	if Art.font_emoji:
		cost_tag.font = Art.font_emoji
	add_child(cost_tag)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var post := CollisionShape3D.new()
	var cyls := CylinderShape3D.new()
	cyls.radius = 0.85
	cyls.height = 1.9
	post.shape = cyls
	post.position.y = 0.95
	body.add_child(post)
	add_child(body)
	lamp = OmniLight3D.new()
	lamp.position = Vector3(0, 1.7, 0.55)
	lamp.light_color = Color("FFB347")
	lamp.light_energy = 1.6
	lamp.omni_range = 6.5
	add_child(lamp)


func _mesh_sphere(host: Node3D, pos: Vector3, radius: float, mat: Material, scl: Vector3 = Vector3.ONE) -> void:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 16
	s.rings = 10
	mi.mesh = s
	mi.position = pos
	mi.scale = scl
	mi.material_override = mat
	host.add_child(mi)


func _mesh_cyl(host: Node3D, pos: Vector3, radius: float, height: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = 12
	mi.mesh = c
	mi.position = pos
	mi.material_override = mat
	host.add_child(mi)


func _mesh_torus(host: Node3D, pos: Vector3, inner: float, outer: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 18
	t.ring_segments = 10
	mi.mesh = t
	mi.position = pos
	mi.rotation_degrees.x = 90.0
	mi.material_override = mat
	host.add_child(mi)


func _mesh_box(host: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = _mat(color, 0.85)
	host.add_child(mi)


func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _process(delta: float) -> void:
	if lamp:
		lamp.light_energy = 1.4 + sin(Time.get_ticks_msec() * 0.004) * 0.35
	if not spinning and sack:
		var t := Time.get_ticks_msec() * 0.002
		sack.rotation_degrees.y = sin(t) * 3.0
		sack.scale = Vector3.ONE * (1.0 + sin(t * 1.4) * 0.02)


func try_spin() -> bool:
	if not near or spinning:
		return near
	if world == null or not world.has_method("spend_coins"):
		return near
	if not world.spend_coins(COST):
		if world.has_method("_show"):
			world._show("NEED  %d  COINS" % COST)
		AudioDirector.play("ui", 0.55)
		return true
	spinning = true
	var prize := _pick()
	var tw := create_tween()
	tw.set_parallel(false)
	tw.tween_property(sack, "scale", Vector3(1.18, 0.82, 1.18), 0.18).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sack, "scale", Vector3(0.9, 1.22, 0.9), 0.22)
	tw.tween_property(sack, "rotation_degrees:z", 12.0, 0.12)
	tw.tween_property(sack, "rotation_degrees:z", -12.0, 0.12)
	tw.tween_property(sack, "rotation_degrees:z", 8.0, 0.1)
	tw.tween_property(sack, "rotation_degrees:z", 0.0, 0.16)
	tw.tween_property(sack, "scale", Vector3(1.08, 1.12, 1.08), 0.18)
	tw.tween_callback(func():
		spinning = false
		if sack:
			sack.scale = Vector3.ONE
			sack.rotation_degrees.z = 0.0
		_pay(prize)
	)
	AudioDirector.play("confirm", 0.8)
	return true


func _pick() -> String:
	var total := 0
	for w in WEIGHTS:
		total += int(w[1])
	var roll := randi() % total
	var acc := 0
	for w in WEIGHTS:
		acc += int(w[1])
		if roll < acc:
			return str(w[0])
	return "ammo"


func _pay(id: String) -> void:
	var count := 1
	if id == "ammo":
		count = 12
	elif id == "candy":
		count = 18
	var it: Dictionary = PackData.make(id, count)
	var named := str(it.get("name", id))
	var loot = LootDrop.new()
	loot.setup(it)
	var mouth := global_position + Vector3(0, 1.7, 0.25)
	var land := global_position + Vector3(0, 0.25, 2.05)
	loot.position = mouth
	var host: Node = get_parent() if get_parent() else self
	host.add_child(loot)
	if loot.has_method("pop_out"):
		loot.pop_out(land)
	if world and world.has_method("_show"):
		world._show("SACK  ·  %s" % named)
	FX.ring(host, land, Color(1.0, 0.45, 0.28, 0.85), 2.2, 0.4)
	FX.float_text(host, mouth + Vector3(0, 0.8, 0), named, Color("FFE27A"), 40)
	AudioDirector.play("win", 1.15)
	AudioDirector.play_at("whoosh", mouth, 0.9)
