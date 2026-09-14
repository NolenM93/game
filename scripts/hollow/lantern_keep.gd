extends StaticBody3D

const FX = preload("res://scripts/hollow/hollow_fx.gd")

signal ruined
signal hurt(hp: int, max_hp: int)

var hp := 100
var max_hp := 100
var bite_cd := 0.0
var vis: Node3D
var lamp: OmniLight3D
var wash: OmniLight3D
var flame: MeshInstance3D
var glass_mat: StandardMaterial3D
var tag: Label3D
var dead := false
var wobble := 0.0


func _ready() -> void:
	add_to_group("keep")
	collision_layer = 32
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.6, 2.4, 2.6)
	cs.shape = box
	cs.position.y = 1.2
	add_child(cs)
	vis = Node3D.new()
	add_child(vis)
	var stone := Color("4A4E55")
	var wood := Color("3A2418")
	# Stone steps
	_box(Vector3(0, 0.17, 0), Vector3(3.0, 0.34, 3.0), stone.darkened(0.1))
	_box(Vector3(0, 0.48, 0), Vector3(2.3, 0.28, 2.3), stone)
	_box(Vector3(0, 0.66, 0), Vector3(1.4, 0.1, 1.4), stone.lightened(0.08))
	# Posts and beams
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(Vector3(0.92 * sx, 1.75, 0.92 * sz), Vector3(0.18, 2.3, 0.18), wood)
			_box(Vector3(0.92 * sx, 0.68, 0.92 * sz), Vector3(0.3, 0.12, 0.3), stone.lightened(0.1))
	_box(Vector3(0, 2.86, 0), Vector3(2.2, 0.14, 0.14), wood)
	_box(Vector3(0, 2.86, 0), Vector3(0.14, 0.14, 2.2), wood)
	# Layered roof
	_box(Vector3(0, 3.0, 0), Vector3(2.8, 0.16, 2.8), Color("2A1C14"))
	_box(Vector3(0, 3.18, 0), Vector3(2.0, 0.16, 2.0), Color("32221A"))
	_box(Vector3(0, 3.36, 0), Vector3(1.2, 0.16, 1.2), Color("2A1C14"))
	_box(Vector3(0, 3.55, 0), Vector3(0.22, 0.26, 0.22), Color("C4A24A"))
	# Hanging lantern
	_box(Vector3(0, 2.6, 0), Vector3(0.05, 0.4, 0.05), Color("1A1410"))
	_box(Vector3(0, 2.42, 0), Vector3(0.62, 0.08, 0.62), Color("1A1410"))
	_box(Vector3(0, 1.78, 0), Vector3(0.62, 0.08, 0.62), Color("1A1410"))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(Vector3(0.27 * sx, 2.1, 0.27 * sz), Vector3(0.05, 0.64, 0.05), Color("1A1410"))
	var glass := MeshInstance3D.new()
	var gb := BoxMesh.new()
	gb.size = Vector3(0.5, 0.58, 0.5)
	glass.mesh = gb
	glass.position = Vector3(0, 2.1, 0)
	glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(1.0, 0.72, 0.35, 0.45)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.emission_enabled = true
	glass_mat.emission = Color("FF8A3A")
	glass_mat.emission_energy_multiplier = 1.6
	glass_mat.roughness = 0.15
	glass.material_override = glass_mat
	vis.add_child(glass)
	flame = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.36
	flame.mesh = sm
	flame.position = Vector3(0, 2.08, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("FFE27A")
	mat.emission_enabled = true
	mat.emission = Color("FFB347")
	mat.emission_energy_multiplier = 4.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame.material_override = mat
	vis.add_child(flame)
	lamp = OmniLight3D.new()
	lamp.position = Vector3(0, 2.1, 0)
	lamp.light_color = Color("FFB36A")
	lamp.light_energy = 7.5
	lamp.omni_range = 16.0
	lamp.shadow_enabled = true
	add_child(lamp)
	wash = OmniLight3D.new()
	wash.position = Vector3(0, 4.2, 0)
	wash.light_color = Color("FFC890")
	wash.light_energy = 2.2
	wash.omni_range = 28.0
	wash.shadow_enabled = false
	add_child(wash)
	tag = Label3D.new()
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.font_size = 40
	tag.outline_size = 12
	tag.position.y = 4.1
	tag.no_depth_test = true
	if Art.font_emoji:
		tag.font = Art.font_emoji
	add_child(tag)
	var zone := Area3D.new()
	zone.monitoring = true
	zone.collision_mask = 4
	zone.collision_layer = 0
	var zcs := CollisionShape3D.new()
	var zbox := BoxShape3D.new()
	zbox.size = Vector3(3.4, 2.2, 3.4)
	zcs.shape = zbox
	zcs.position.y = 1.0
	zone.add_child(zcs)
	add_child(zone)
	zone.body_entered.connect(func(n):
		if n.is_in_group("zed") and n.has_method("start_chew"):
			n.start_chew(self)
	)
	_refresh()


func chew(dmg: int) -> void:
	if dead:
		return
	hp = maxi(0, hp - dmg)
	lamp.light_energy = 2.0
	wobble = 1.0
	FX.spark(get_parent(), global_position + Vector3(0, 2.1, 0))
	AudioDirector.play_at("hurt", global_position, 0.7)
	hurt.emit(hp, max_hp)
	_refresh()
	if hp <= 0:
		dead = true
		FX.boom(get_parent(), global_position + Vector3(0, 1.5, 0))
		AudioDirector.play("lose")
		ruined.emit()


func heal(n: int) -> void:
	if dead:
		return
	var before := hp
	hp = mini(max_hp, hp + n)
	if hp > before:
		FX.float_text(get_parent(), global_position + Vector3(0, 2.6, 0), "+%d 🏮" % (hp - before), Color("FFE27A"), 40)
		FX.ring(get_parent(), global_position, Color(1.0, 0.8, 0.45, 0.7), 3.0, 0.5)
	hurt.emit(hp, max_hp)
	_refresh()


func _process(delta: float) -> void:
	var frac := float(hp) / float(max_hp)
	var t := Time.get_ticks_msec() * 0.001
	if lamp:
		var flicker := 1.0 + sin(t * 9.0) * 0.04 + sin(t * 23.0) * 0.03
		if frac < 0.3:
			flicker *= 0.75 + 0.25 * sin(t * 14.0)
		lamp.light_energy = move_toward(lamp.light_energy, 7.5 * (0.45 + 0.55 * frac) * flicker, delta * 8.0)
		lamp.omni_range = 12.0 + 6.0 * frac
	if wash:
		wash.light_energy = 2.2 * (0.35 + 0.65 * frac)
	if flame:
		var s := 1.0 + sin(t * 11.0) * 0.08
		flame.scale = Vector3(s, 1.0 + sin(t * 7.0) * 0.12, s)
	if wobble > 0.0 and vis:
		wobble = maxf(0.0, wobble - delta * 3.0)
		vis.rotation.z = sin(t * 40.0) * 0.02 * wobble
		vis.rotation.x = cos(t * 37.0) * 0.02 * wobble


func _refresh() -> void:
	if tag:
		if hp >= max_hp:
			tag.text = ""
		else:
			tag.text = "🏮 %d" % hp
			tag.modulate = Color("FFB347") if hp > 30 else Color("E24B4B")


func _box(pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.82
	mi.material_override = m
	vis.add_child(mi)
