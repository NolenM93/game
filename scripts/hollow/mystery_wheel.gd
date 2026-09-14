class_name HollowWheel
extends Area3D

const PackData = preload("res://scripts/hollow/pack.gd")
const FX = preload("res://scripts/hollow/hollow_fx.gd")

const COST := 28
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

var disc: Node3D
var lamp: OmniLight3D
var spinning := false
var near := false
var world: Node


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 2.6
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
	_post(Vector3(0, 0.7, 0), Vector3(0.22, 1.4, 0.22), Color("3A2418"))
	_post(Vector3(0, 1.45, 0), Vector3(0.55, 0.16, 0.55), Color("2A1C14"))
	disc = Node3D.new()
	disc.position = Vector3(0, 2.15, 0)
	add_child(disc)
	var hub := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.22
	cyl.height = 0.28
	hub.mesh = cyl
	hub.rotation_degrees.x = 90.0
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color("C4A05A")
	hm.metallic = 0.4
	hub.material_override = hm
	disc.add_child(hub)
	var colors := [
		Color("C45A20"), Color("FFE27A"), Color("6AA84A"), Color("5A7AD4"),
		Color("E24B4B"), Color("B070D0"), Color("3A2A1C"), Color("FFB347")
	]
	for i in 8:
		var wedge := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.42, 0.12, 1.05)
		wedge.mesh = box
		wedge.position = Vector3(0, 0, 0.55)
		wedge.rotation.y = TAU * i / 8.0
		# offset each box out from center along its facing
		wedge.position = Vector3(sin(wedge.rotation.y), 0, cos(wedge.rotation.y)) * 0.7
		var wm := StandardMaterial3D.new()
		wm.albedo_color = colors[i]
		wm.roughness = 0.45
		wm.emission_enabled = true
		wm.emission = colors[i]
		wm.emission_energy_multiplier = 0.25
		wedge.material_override = wm
		disc.add_child(wedge)
	var rim := MeshInstance3D.new()
	var torm := TorusMesh.new()
	torm.inner_radius = 1.12
	torm.outer_radius = 1.28
	torm.rings = 24
	rim.mesh = torm
	rim.rotation_degrees.x = 90.0
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color("C4A05A")
	rm.metallic = 0.35
	rim.material_override = rm
	disc.add_child(rim)
	var pointer := MeshInstance3D.new()
	var pb := BoxMesh.new()
	pb.size = Vector3(0.12, 0.18, 0.34)
	pointer.mesh = pb
	pointer.position = Vector3(0, 3.42, 0.15)
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color("FFF6D8")
	pointer.material_override = pm
	add_child(pointer)
	_post(Vector3(0, 3.28, 0), Vector3(0.5, 0.1, 0.5), Color("2A1C14"))
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var post := CollisionShape3D.new()
	var cyls := CylinderShape3D.new()
	cyls.radius = 0.38
	cyls.height = 3.2
	post.shape = cyls
	post.position.y = 1.6
	body.add_child(post)
	add_child(body)
	lamp = OmniLight3D.new()
	lamp.position = Vector3(0, 2.3, 0.4)
	lamp.light_color = Color("FFB347")
	lamp.light_energy = 1.8
	lamp.omni_range = 6.0
	add_child(lamp)
	var tag := Label3D.new()
	tag.text = "🎡  MYSTERY WHEEL"
	tag.font_size = 42
	tag.outline_size = 8
	tag.position = Vector3(0, 3.85, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color("FFE27A")
	if Art.font_emoji:
		tag.font = Art.font_emoji
	add_child(tag)
	var cost := Label3D.new()
	cost.text = "%d 🪙  a spin" % COST
	cost.font_size = 28
	cost.outline_size = 6
	cost.position = Vector3(0, 0.28, 0.7)
	cost.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	cost.modulate = Color("FFE27A")
	if Art.font_emoji:
		cost.font = Art.font_emoji
	add_child(cost)


func _post(pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	mi.material_override = m
	add_child(mi)


func _process(delta: float) -> void:
	if lamp:
		lamp.light_energy = 1.5 + sin(Time.get_ticks_msec() * 0.004) * 0.4
	if not spinning and disc:
		disc.rotate_y(delta * 0.35)


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
	var extra := TAU * randf_range(4.5, 7.2)
	tw.tween_property(disc, "rotation:y", disc.rotation.y + extra, 2.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		spinning = false
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
	var hunter: Node = null
	for n in get_tree().get_nodes_in_group("hunter"):
		hunter = n
		break
	var named := str(it.get("name", id))
	if hunter and hunter.has_method("take_loot") and hunter.take_loot(it):
		if world and world.has_method("_show"):
			world._show("WHEEL  ·  %s" % named)
	else:
		if world and world.has_method("_spawn_loot"):
			world._spawn_loot(global_position + Vector3(0, 0.4, 1.2), id)
		if world and world.has_method("_show"):
			world._show("WHEEL  ·  %s" % named)
	FX.ring(get_parent(), global_position, Color(1.0, 0.75, 0.35, 0.8), 2.4, 0.45)
	FX.float_text(get_parent(), global_position + Vector3(0, 2.6, 0), named, Color("FFE27A"), 40)
	AudioDirector.play("win", 1.15)
