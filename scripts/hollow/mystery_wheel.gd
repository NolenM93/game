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

var pot: Node3D
var liquid: MeshInstance3D
var lamp: OmniLight3D
var bubbles: Array[MeshInstance3D] = []
var mist: CPUParticles3D
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
	pot = Node3D.new()
	add_child(pot)
	var iron := _mat(Color("1C241C"), 0.38)
	iron.metallic = 0.78
	iron.clearcoat_enabled = true
	iron.clearcoat = 0.28
	var rust := _mat(Color("4A3220"), 0.82)
	rust.metallic = 0.35
	var rim := _mat(Color("2A3228"), 0.32)
	rim.metallic = 0.85
	# Three iron legs.
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.4
		_mesh_cyl(pot, Vector3(cos(a) * 0.52, 0.28, sin(a) * 0.52), 0.07, 0.62, rust)
	# Belly of the cauldron.
	_mesh_cyl(pot, Vector3(0.0, 0.72, 0.0), 0.78, 0.92, iron, 0.92)
	_mesh_sphere(pot, Vector3(0.0, 0.42, 0.0), 0.82, iron, Vector3(1.05, 0.55, 1.05))
	_mesh_torus(pot, Vector3(0.0, 1.16, 0.0), 0.72, 0.92, rim)
	# Green bubbling liquor.
	liquid = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.74
	disc.bottom_radius = 0.74
	disc.height = 0.1
	disc.radial_segments = 20
	liquid.mesh = disc
	liquid.position = Vector3(0, 0.98, 0)
	var goo := StandardMaterial3D.new()
	goo.albedo_color = Color(0.12, 0.72, 0.28, 0.78)
	goo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	goo.roughness = 0.18
	goo.metallic = 0.12
	goo.emission_enabled = true
	goo.emission = Color("3AEA6A")
	goo.emission_energy_multiplier = 1.85
	liquid.material_override = goo
	pot.add_child(liquid)
	var blob := _mat(Color("2ADA5A", 0.55), 0.22)
	blob.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blob.emission_enabled = true
	blob.emission = Color("4AFF78")
	blob.emission_energy_multiplier = 1.4
	for i in 8:
		var b := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = randf_range(0.04, 0.09)
		s.height = s.radius * 2.0
		b.mesh = s
		b.material_override = blob
		b.position = Vector3(randf_range(-0.38, 0.38), randf_range(0.85, 1.2), randf_range(-0.38, 0.38))
		b.set_meta("spd", randf_range(0.35, 0.85))
		pot.add_child(b)
		bubbles.append(b)
	mist = CPUParticles3D.new()
	mist.position = Vector3(0, 1.02, 0)
	mist.amount = 36
	mist.lifetime = 1.35
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mist.emission_sphere_radius = 0.42
	mist.direction = Vector3(0, 1, 0)
	mist.spread = 18.0
	mist.gravity = Vector3(0, 0.8, 0)
	mist.initial_velocity_min = 0.25
	mist.initial_velocity_max = 0.8
	mist.scale_amount_min = 0.04
	mist.scale_amount_max = 0.12
	mist.color = Color(0.28, 0.9, 0.4, 0.7)
	var pm := SphereMesh.new()
	pm.radius = 0.06
	pm.height = 0.12
	mist.mesh = pm
	pot.add_child(mist)
	var tag := Label3D.new()
	tag.text = "CAULDRON"
	tag.font_size = 40
	tag.outline_size = 8
	tag.position = Vector3(0, 2.55, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color("7EFF9A")
	if Art.font_title:
		tag.font = Art.font_title
	add_child(tag)
	cost_tag = Label3D.new()
	cost_tag.text = "%d 🪙  a dip" % COST
	cost_tag.font_size = 28
	cost_tag.outline_size = 6
	cost_tag.position = Vector3(0, 0.18, 1.15)
	cost_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	cost_tag.modulate = Color("7EFF9A")
	if Art.font_emoji:
		cost_tag.font = Art.font_emoji
	add_child(cost_tag)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var post := CollisionShape3D.new()
	var cyls := CylinderShape3D.new()
	cyls.radius = 0.9
	cyls.height = 1.25
	post.shape = cyls
	post.position.y = 0.7
	body.add_child(post)
	add_child(body)
	lamp = OmniLight3D.new()
	lamp.position = Vector3(0, 1.35, 0)
	lamp.light_color = Color("4AFF78")
	lamp.light_energy = 2.4
	lamp.omni_range = 7.5
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


func _mesh_cyl(host: Node3D, pos: Vector3, radius: float, height: float, mat: Material, top: float = -1.0) -> void:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = radius if top < 0.0 else top
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = 16
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


func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if c.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _process(delta: float) -> void:
	if lamp:
		lamp.light_energy = 2.1 + sin(Time.get_ticks_msec() * 0.006) * 0.55
	if liquid:
		liquid.rotation.y += delta * 0.55
		liquid.position.y = 0.98 + sin(Time.get_ticks_msec() * 0.004) * 0.035
	for b in bubbles:
		if b == null:
			continue
		b.position.y += delta * float(b.get_meta("spd", 0.5))
		if b.position.y > 1.55:
			b.position = Vector3(randf_range(-0.38, 0.38), 0.82, randf_range(-0.38, 0.38))
			b.set_meta("spd", randf_range(0.35, 0.9))


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
	if mist:
		mist.amount = 70
		mist.initial_velocity_max = 1.4
	var tw := create_tween()
	tw.set_parallel(false)
	if liquid:
		tw.tween_property(liquid, "scale", Vector3(1.12, 1.55, 1.12), 0.45).set_trans(Tween.TRANS_SINE)
		tw.tween_property(liquid, "scale", Vector3.ONE, 0.55)
	else:
		tw.tween_interval(1.0)
	tw.tween_callback(func():
		spinning = false
		if mist:
			mist.amount = 36
			mist.initial_velocity_max = 0.8
		_pay(prize)
	)
	AudioDirector.play("confirm", 0.8)
	AudioDirector.play_at("whoosh", global_position, 0.7)
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
	var mouth := global_position + Vector3(0, 0.92, 0)
	var hover := global_position + Vector3(0, 2.48, 0)
	loot.position = mouth
	var host: Node = get_parent() if get_parent() else self
	host.add_child(loot)
	if loot.has_method("rise_and_hover"):
		loot.rise_and_hover(hover)
	if world and world.has_method("_show"):
		world._show("CAULDRON  ·  %s" % named)
	FX.ring(host, hover, Color(0.3, 0.95, 0.4, 0.85), 2.2, 0.55)
	FX.float_text(host, mouth + Vector3(0, 0.8, 0), named, Color("7EFF9A"), 40)
	AudioDirector.play("win", 1.15)
	AudioDirector.play_at("whoosh", mouth, 0.9)
