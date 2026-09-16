extends CharacterBody3D

const FX = preload("res://scripts/hollow/hollow_fx.gd")

signal popped(kind: String, pos: Vector3)

var kind := "shambler"
var keep: Node3D
var hunter: Node3D
var vis: Node3D
var core := 8
var max_core := 8
var speed := 2.45
var wave := 1
var sc := 1.0
var chew_cd := 0.0
var swipe_cd := 0.0
var slow := 0.0
var stun := 0.0
var i_frames := 0.0
var flash_t := 0.0
var flash_on := false
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
var mats: Array[StandardMaterial3D] = []
var hp_root: Node3D
var hp_fill: MeshInstance3D
var hp_show := 0.0
var last_head := false
var last_style := ""
var wander := Vector3.ZERO
var wander_t := 0.0


func setup(p_kind: String, p_keep: Node3D, p_hunter: Node3D, p_wave: int = 1) -> void:
	kind = p_kind
	keep = p_keep
	hunter = p_hunter
	wave = maxi(1, p_wave)
	match kind:
		"runner":
			core = 5
			speed = 5.15
			skin = Color("8A7A62")
			shirt = Color("4A3220")
		"lunk":
			core = 22
			speed = 1.65
			skin = Color("6A7A58")
			shirt = Color("3A3020")
		"mayor":
			core = 48
			speed = 1.9
			skin = Color("8A8A72")
			shirt = Color("2A2438")
		"skel":
			core = 7
			speed = 2.85
			skin = Color("E4DCC0")
			shirt = Color("5A4030")
		_:
			core = 8
			speed = 2.45
			skin = Color("7A8A62")
			shirt = Color("3A4630")
	max_core = core
	# Wave 1 is a crawl (~26% of cap). Speed ramps linearly and hard-caps at wave 12.
	var t := clampf(float(wave - 1) / 11.0, 0.0, 1.0)
	speed *= lerpf(0.26, 1.0, t) * randf_range(0.94, 1.06)
	if kind != "skel":
		var rot: Array[Color] = [Color("7A8A62"), Color("8A7A68"), Color("6E7A58"), Color("9A8880"), Color("6A6258")]
		skin = rot[randi() % rot.size()].lerp(Color("4A5A38"), randf() * 0.22)


func _ready() -> void:
	add_to_group("zed")
	collision_layer = 4
	collision_mask = 1 | 16
	floor_snap_length = 0.55
	floor_max_angle = deg_to_rad(62.0)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	sc = 1.0
	if kind == "lunk":
		sc = 1.4
	elif kind == "mayor":
		sc = 1.55
	elif kind == "runner":
		sc = 0.88
	elif kind == "skel":
		sc = 1.04
	cap.radius = 0.38 * sc
	cap.height = 1.2 * sc
	cs.shape = cap
	cs.position.y = 0.65 * sc
	add_child(cs)
	_build()
	_hp_bar()
	groan_t = randf_range(1.5, 5.0)


## World point shots should aim at: roughly the sternum.
func aim_center() -> Vector3:
	return global_position + Vector3(0, 0.72 * sc, 0)


func _hp_bar() -> void:
	hp_root = Node3D.new()
	hp_root.position = Vector3(0, 1.75 * sc, 0)
	add_child(hp_root)
	var bg := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.9, 0.11)
	bg.mesh = q
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.albedo_color = Color(0.06, 0.05, 0.08, 0.85)
	bm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bm.billboard_keep_scale = true
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.no_depth_test = true
	bm.render_priority = 3
	bg.material_override = bm
	bg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hp_root.add_child(bg)
	hp_fill = MeshInstance3D.new()
	var q2 := QuadMesh.new()
	q2.size = Vector2(0.84, 0.07)
	q2.center_offset = Vector3(0.42, 0, 0)
	hp_fill.mesh = q2
	hp_fill.position = Vector3(-0.42, 0, 0.001)
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color("8BE05A")
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fm.billboard_keep_scale = true
	fm.no_depth_test = true
	fm.render_priority = 4
	hp_fill.material_override = fm
	hp_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hp_root.add_child(hp_fill)
	hp_root.visible = false


func _refresh_hp() -> void:
	if hp_fill == null:
		return
	var f := clampf(float(core) / float(max_core), 0.0, 1.0)
	hp_fill.scale.x = maxf(f, 0.01)
	var m: StandardMaterial3D = hp_fill.material_override
	m.albedo_color = Color("8BE05A") if f > 0.5 else (Color("FFB347") if f > 0.25 else Color("E24B4B"))
	hp_show = 3.0
	hp_root.visible = true


func _build() -> void:
	vis = Node3D.new()
	add_child(vis)
	if kind == "skel":
		_build_skel()
		return
	if kind == "shambler":
		vis.rotation.x = 0.12
	elif kind == "runner":
		vis.rotation.x = 0.34
	elif kind == "lunk":
		vis.rotation.x = 0.08
	var pants := shirt.darkened(0.22)
	var bone := Color("D8D0B4")
	var rot := skin.darkened(0.18)
	var blood := Color("4A1814")
	# hips / torso
	_part("torso", _limb(Vector3(0, 0.78, 0) * sc), 99)
	var torso: Node3D = parts["torso"]["node"]
	_cyl(torso, Vector3(0, 0.34, 0.02) * sc, Vector3(0.12, 0.16, 0.12) * sc, skin)
	if kind == "lunk":
		_box(torso, Vector3(0, 0.06, 0.02) * sc, Vector3(0.58, 0.52, 0.38) * sc, shirt)
		_ball(torso, Vector3(0, -0.06, 0.12) * sc, 0.22 * sc, rot)
		_box(torso, Vector3(-0.26, 0.22, 0.04) * sc, Vector3(0.2, 0.14, 0.24) * sc, shirt.darkened(0.1))
		_box(torso, Vector3(0.26, 0.22, 0.04) * sc, Vector3(0.2, 0.14, 0.24) * sc, shirt.darkened(0.1))
		_box(torso, Vector3(0, -0.22, 0.0) * sc, Vector3(0.5, 0.2, 0.3) * sc, pants)
	elif kind == "mayor":
		_box(torso, Vector3(0, 0.08, -0.04) * sc, Vector3(0.5, 0.62, 0.28) * sc, shirt)
		_box(torso, Vector3(-0.18, -0.18, -0.1) * sc, Vector3(0.16, 0.48, 0.08) * sc, shirt)
		_box(torso, Vector3(0.18, -0.18, -0.1) * sc, Vector3(0.16, 0.48, 0.08) * sc, shirt)
		_box(torso, Vector3(0, 0.12, 0.14) * sc, Vector3(0.36, 0.08, 0.04) * sc, Color("C4A24A"))
		_box(torso, Vector3(0, -0.02, 0.12) * sc, Vector3(0.22, 0.28, 0.06) * sc, Color("3A2A48"))
		_box(torso, Vector3(0, -0.22, 0.0) * sc, Vector3(0.4, 0.18, 0.26) * sc, Color("1A1520"))
	else:
		_box(torso, Vector3(0, 0.06, 0.02) * sc, Vector3(0.42, 0.46, 0.26) * sc, shirt)
		_box(torso, Vector3(0, -0.2, 0.0) * sc, Vector3(0.38, 0.16, 0.24) * sc, pants)
		_box(torso, Vector3(0, 0.04, 0.14) * sc, Vector3(0.22, 0.26, 0.05) * sc, skin)
		for i in 4:
			_box(torso, Vector3(0, 0.16 - i * 0.07, 0.16) * sc, Vector3(0.2, 0.024, 0.03) * sc, bone)
		_box(torso, Vector3(-0.08, -0.04, 0.14) * sc, Vector3(0.1, 0.12, 0.04) * sc, blood)
		if kind == "runner":
			_box(torso, Vector3(0, 0.16, -0.02) * sc, Vector3(0.34, 0.22, 0.28) * sc, Color("3A2A20"))
			_box(torso, Vector3(0.1, 0.02, 0.12) * sc, Vector3(0.12, 0.2, 0.06) * sc, rot)
	_box(torso, Vector3(-0.2, 0.24, 0.0) * sc, Vector3(0.12, 0.08, 0.18) * sc, skin)
	_box(torso, Vector3(0.2, 0.24, 0.0) * sc, Vector3(0.12, 0.08, 0.18) * sc, skin)
	# head
	_part("head", _limb(Vector3(0, 1.3, 0.05) * sc), 3 if kind == "lunk" or kind == "mayor" else 2)
	var head: Node3D = parts["head"]["node"]
	_ball(head, Vector3(0, 0.04, 0.02) * sc, (0.24 if kind == "lunk" else 0.21) * sc, skin)
	_box(head, Vector3(0, -0.12, 0.06) * sc, Vector3(0.16, 0.12, 0.16) * sc, rot)
	_box(head, Vector3(-0.08, 0.05, 0.17) * sc, Vector3(0.09, 0.07, 0.06) * sc, Color("1C1410"))
	_box(head, Vector3(0.08, 0.05, 0.17) * sc, Vector3(0.09, 0.07, 0.06) * sc, Color("1C1410"))
	_ball(head, Vector3(-0.08, 0.05, 0.2) * sc, 0.032 * sc, Color("C8C090"))
	_ball(head, Vector3(0.08, 0.05, 0.2) * sc, 0.032 * sc, Color("C8C090"))
	_ball(head, Vector3(-0.08, 0.05, 0.22) * sc, 0.014 * sc, Color("1A120C"))
	_ball(head, Vector3(0.08, 0.05, 0.22) * sc, 0.014 * sc, Color("1A120C"))
	_box(head, Vector3(0, 0.02, 0.2) * sc, Vector3(0.05, 0.07, 0.06) * sc, rot)
	_box(head, Vector3(-0.21, 0.04, 0.0) * sc, Vector3(0.04, 0.08, 0.05) * sc, skin)
	_box(head, Vector3(0.21, 0.04, 0.0) * sc, Vector3(0.04, 0.08, 0.05) * sc, skin)
	_box(head, Vector3(0, -0.16, 0.14) * sc, Vector3(0.12, 0.03, 0.04) * sc, blood)
	_box(head, Vector3(0, -0.13, 0.15) * sc, Vector3(0.1, 0.024, 0.03) * sc, bone)
	_box(head, Vector3(0.02, 0.18, -0.02) * sc, Vector3(0.26, 0.06, 0.22) * sc, Color("2A221C"))
	_box(head, Vector3(-0.1, 0.02, 0.08) * sc, Vector3(0.08, 0.1, 0.04) * sc, rot.darkened(0.1))
	if kind == "mayor":
		_part("hat", _limb(Vector3(0, 1.54, 0.04) * sc), 2)
		var hat: Node3D = parts["hat"]["node"]
		_cyl(hat, Vector3(0, 0.12, 0) * sc, Vector3(0.28, 0.28, 0.28) * sc, Color("1A1520"))
		_cyl(hat, Vector3(0, 0.0, 0) * sc, Vector3(0.42, 0.05, 0.42) * sc, Color("1A1520"))
		_box(hat, Vector3(0, 0.08, 0.22) * sc, Vector3(0.16, 0.04, 0.04) * sc, Color("C4A24A"))
	# arms
	arm_l = _limb(Vector3(-0.28, 0.98, 0.04) * sc)
	arm_r = _limb(Vector3(0.28, 0.98, 0.04) * sc)
	_part("arm_l", arm_l, 2)
	_part("arm_r", arm_r, 2)
	_box(arm_l, Vector3(0, 0, 0) * sc, Vector3(0.14, 0.14, 0.14) * sc, shirt)
	_cap(arm_l, Vector3(-0.03, -0.18, 0.05) * sc, Vector3(0.13, 0.34, 0.13) * sc, skin)
	_cap(arm_l, Vector3(-0.02, -0.4, 0.1) * sc, Vector3(0.11, 0.26, 0.11) * sc, skin)
	_box(arm_l, Vector3(-0.04, -0.54, 0.16) * sc, Vector3(0.1, 0.07, 0.14) * sc, rot)
	_box(arm_l, Vector3(-0.06, -0.56, 0.22) * sc, Vector3(0.03, 0.03, 0.08) * sc, skin)
	_box(arm_l, Vector3(-0.02, -0.56, 0.22) * sc, Vector3(0.03, 0.03, 0.09) * sc, skin)
	_box(arm_l, Vector3(0.02, -0.56, 0.21) * sc, Vector3(0.03, 0.03, 0.07) * sc, skin)
	_box(arm_r, Vector3(0, 0, 0) * sc, Vector3(0.14, 0.14, 0.14) * sc, shirt)
	_cap(arm_r, Vector3(0.03, -0.18, 0.05) * sc, Vector3(0.13, 0.34, 0.13) * sc, skin)
	_cap(arm_r, Vector3(0.02, -0.4, 0.12) * sc, Vector3(0.11, 0.26, 0.11) * sc, skin)
	_box(arm_r, Vector3(0.04, -0.54, 0.18) * sc, Vector3(0.1, 0.07, 0.14) * sc, rot)
	_box(arm_r, Vector3(0.06, -0.56, 0.24) * sc, Vector3(0.03, 0.03, 0.08) * sc, skin)
	_box(arm_r, Vector3(0.02, -0.56, 0.24) * sc, Vector3(0.03, 0.03, 0.09) * sc, skin)
	_box(arm_r, Vector3(-0.02, -0.56, 0.22) * sc, Vector3(0.03, 0.03, 0.07) * sc, skin)
	arm_l.rotation_degrees.x = 22.0 if kind != "runner" else 42.0
	arm_r.rotation_degrees.x = -10.0 if kind != "runner" else 30.0
	arm_l.rotation_degrees.z = 14.0
	arm_r.rotation_degrees.z = -12.0
	# legs
	leg_l = _limb(Vector3(-0.12, 0.62, 0.0) * sc)
	leg_r = _limb(Vector3(0.12, 0.62, 0.0) * sc)
	_part("leg_l", leg_l, 2)
	_part("leg_r", leg_r, 2)
	_cap(leg_l, Vector3(0, -0.16, 0.02) * sc, Vector3(0.15, 0.32, 0.15) * sc, pants)
	_cap(leg_l, Vector3(0, -0.4, 0.04) * sc, Vector3(0.13, 0.26, 0.13) * sc, pants)
	_box(leg_l, Vector3(0, -0.56, 0.07) * sc, Vector3(0.16, 0.1, 0.26) * sc, Color("2A1C14"))
	_cap(leg_r, Vector3(0, -0.16, 0.02) * sc, Vector3(0.15, 0.32, 0.15) * sc, pants)
	_cap(leg_r, Vector3(0, -0.4, 0.04) * sc, Vector3(0.13, 0.26, 0.13) * sc, pants)
	_box(leg_r, Vector3(0, -0.56, 0.07) * sc, Vector3(0.16, 0.1, 0.26) * sc, Color("3A2418") if kind != "runner" else Color("4A2018"))
	_box(leg_r, Vector3(0.02, -0.28, 0.08) * sc, Vector3(0.08, 0.16, 0.04) * sc, rot)


func _build_skel() -> void:
	var bone := Color("E8E0C4")
	var dark := Color("C8C0A4")
	var rust := Color("6A3A22")
	var ink := Color("1A1410")
	var glow := Color("C43A32")
	vis.rotation.x = 0.04
	_part("torso", _limb(Vector3(0, 0.8, 0) * sc), 99)
	var torso: Node3D = parts["torso"]["node"]
	_cyl(torso, Vector3(0, 0.08, 0) * sc, Vector3(0.07, 0.42, 0.07) * sc, bone)
	_box(torso, Vector3(0, -0.16, 0) * sc, Vector3(0.32, 0.1, 0.18) * sc, dark)
	_box(torso, Vector3(0, 0.28, 0) * sc, Vector3(0.28, 0.08, 0.16) * sc, bone)
	for i in 5:
		var y := 0.18 - i * 0.07
		_box(torso, Vector3(0, y, 0.1) * sc, Vector3(0.28 - i * 0.02, 0.03, 0.04) * sc, bone)
		_box(torso, Vector3(-0.12, y, 0.02) * sc, Vector3(0.04, 0.03, 0.16) * sc, dark)
		_box(torso, Vector3(0.12, y, 0.02) * sc, Vector3(0.04, 0.03, 0.16) * sc, dark)
	_box(torso, Vector3(0, -0.22, 0.02) * sc, Vector3(0.22, 0.08, 0.12) * sc, rust)
	_box(torso, Vector3(-0.18, 0.26, 0.02) * sc, Vector3(0.14, 0.08, 0.18) * sc, rust)
	_box(torso, Vector3(0.2, 0.24, 0.02) * sc, Vector3(0.1, 0.06, 0.14) * sc, rust)
	_part("head", _limb(Vector3(0, 1.32, 0.04) * sc), 2)
	var head: Node3D = parts["head"]["node"]
	_ball(head, Vector3(0, 0.06, 0.0) * sc, 0.2 * sc, bone)
	_box(head, Vector3(0, -0.1, 0.04) * sc, Vector3(0.16, 0.1, 0.14) * sc, dark)
	_box(head, Vector3(-0.07, 0.06, 0.16) * sc, Vector3(0.08, 0.07, 0.05) * sc, ink)
	_box(head, Vector3(0.07, 0.06, 0.16) * sc, Vector3(0.08, 0.07, 0.05) * sc, ink)
	_ball(head, Vector3(-0.07, 0.06, 0.18) * sc, 0.028 * sc, glow, true)
	_ball(head, Vector3(0.07, 0.06, 0.18) * sc, 0.028 * sc, glow, true)
	_box(head, Vector3(0, 0.02, 0.18) * sc, Vector3(0.04, 0.06, 0.05) * sc, dark)
	_box(head, Vector3(0, -0.14, 0.12) * sc, Vector3(0.14, 0.04, 0.08) * sc, bone)
	for t in 5:
		_box(head, Vector3(-0.08 + t * 0.04, -0.12, 0.16) * sc, Vector3(0.028, 0.05, 0.03) * sc, Color("F4F0DC"))
	_box(head, Vector3(0, 0.2, 0.0) * sc, Vector3(0.22, 0.06, 0.22) * sc, rust)
	_box(head, Vector3(0, 0.16, 0.12) * sc, Vector3(0.16, 0.04, 0.08) * sc, rust)
	arm_l = _limb(Vector3(-0.26, 1.02, 0.02) * sc)
	arm_r = _limb(Vector3(0.26, 1.02, 0.02) * sc)
	_part("arm_l", arm_l, 2)
	_part("arm_r", arm_r, 2)
	_cyl(arm_l, Vector3(-0.02, -0.16, 0.04) * sc, Vector3(0.05, 0.32, 0.05) * sc, bone)
	_cyl(arm_l, Vector3(-0.02, -0.4, 0.1) * sc, Vector3(0.045, 0.28, 0.045) * sc, dark)
	_box(arm_l, Vector3(-0.02, -0.54, 0.14) * sc, Vector3(0.08, 0.06, 0.1) * sc, bone)
	_cyl(arm_r, Vector3(0.02, -0.16, 0.04) * sc, Vector3(0.05, 0.32, 0.05) * sc, bone)
	_cyl(arm_r, Vector3(0.02, -0.4, 0.1) * sc, Vector3(0.045, 0.28, 0.045) * sc, dark)
	_box(arm_r, Vector3(0.02, -0.54, 0.16) * sc, Vector3(0.08, 0.06, 0.1) * sc, bone)
	_box(arm_r, Vector3(0.04, -0.42, 0.42) * sc, Vector3(0.05, 0.05, 0.72) * sc, Color("4A5058"))
	_box(arm_r, Vector3(0.04, -0.42, 0.78) * sc, Vector3(0.02, 0.12, 0.22) * sc, Color("8A9098"))
	_box(arm_r, Vector3(0.04, -0.42, 0.08) * sc, Vector3(0.07, 0.08, 0.12) * sc, rust)
	arm_l.rotation_degrees.x = 8.0
	arm_r.rotation_degrees.x = -72.0
	arm_l.rotation_degrees.z = 18.0
	arm_r.rotation_degrees.z = -8.0
	leg_l = _limb(Vector3(-0.1, 0.58, 0.0) * sc)
	leg_r = _limb(Vector3(0.1, 0.58, 0.0) * sc)
	_part("leg_l", leg_l, 2)
	_part("leg_r", leg_r, 2)
	_cyl(leg_l, Vector3(0, -0.16, 0.02) * sc, Vector3(0.055, 0.32, 0.055) * sc, bone)
	_cyl(leg_l, Vector3(0, -0.4, 0.04) * sc, Vector3(0.05, 0.28, 0.05) * sc, dark)
	_box(leg_l, Vector3(0, -0.56, 0.08) * sc, Vector3(0.1, 0.06, 0.18) * sc, rust)
	_cyl(leg_r, Vector3(0, -0.16, 0.02) * sc, Vector3(0.055, 0.32, 0.055) * sc, bone)
	_cyl(leg_r, Vector3(0, -0.4, 0.04) * sc, Vector3(0.05, 0.28, 0.05) * sc, dark)
	_box(leg_r, Vector3(0, -0.56, 0.08) * sc, Vector3(0.1, 0.06, 0.18) * sc, rust)


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


func _cap(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CapsuleMesh.new()
	c.radius = 0.5
	c.height = 1.4
	mi.mesh = c
	mi.position = pos
	mi.scale = size
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
		# Glowing bits keep their own emission; leave them out of the hit flash.
		mats.erase(m)
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 1.8
	mi.material_override = m
	parent.add_child(mi)
	return mi


func _cyl(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.5
	c.bottom_radius = 0.5
	c.height = 1.0
	mi.mesh = c
	mi.position = pos
	mi.scale = size
	mi.material_override = _mat(color)
	parent.add_child(mi)
	return mi


func _set_flash(on: bool) -> void:
	if on == flash_on:
		return
	flash_on = on
	for m in mats:
		if on:
			m.emission_enabled = true
			m.emission = Color(1.0, 0.95, 0.85)
			m.emission_energy_multiplier = 2.2
		else:
			m.emission_enabled = false


func _physics_process(delta: float) -> void:
	if dead:
		return
	i_frames = maxf(0.0, i_frames - delta)
	slow = maxf(0.0, slow - delta)
	stun = maxf(0.0, stun - delta)
	chew_cd = maxf(0.0, chew_cd - delta)
	swipe_cd = maxf(0.0, swipe_cd - delta)
	slam_t = maxf(0.0, slam_t - delta)
	flash_t = maxf(0.0, flash_t - delta)
	_set_flash(flash_t > 0.0)
	if hp_show > 0.0:
		hp_show -= delta
		if hp_show <= 0.0 and hp_root:
			hp_root.visible = false
	groan_t -= delta
	if groan_t <= 0.0:
		AudioDirector.play_at("groan", global_position, randf_range(0.7, 1.15) * (0.8 if sc > 1.2 else 1.0) * (1.35 if kind == "skel" else 1.0))
		groan_t = randf_range(3.5, 7.5)
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
	# Loose crowd behaviour: don't stack inside each other, drift a little.
	wander_t -= delta
	if wander_t <= 0.0:
		wander_t = randf_range(0.8, 1.8)
		wander = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * randf_range(0.0, 0.35)
	var steer := dir + _separation() + wander
	if steer.length() > 0.05:
		dir = steer.normalized()

	if vis and not crawling:
		vis.rotation.y = lerp_angle(vis.rotation.y, atan2(dir.x, dir.z), 0.16)
		walk_t += delta * clampf(spd * 3.2, 1.15, 9.5)
		var swing := sin(walk_t) * 0.45
		if kind == "runner":
			swing *= 1.25
		if kind == "skel":
			if arm_l and parts.has("arm_l") and parts["arm_l"]["on"]:
				arm_l.rotation.x = deg_to_rad(10.0) + swing * 0.35
			if arm_r and parts.has("arm_r") and parts["arm_r"]["on"]:
				arm_r.rotation.x = deg_to_rad(-70.0)
		else:
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
		AudioDirector.play_at("whoom", global_position, 0.8)

	var reach := 1.72 if kind == "skel" else 1.55
	if hunter and is_instance_valid(hunter) and global_position.distance_to(hunter.global_position) < reach:
		velocity.x = 0.0
		velocity.z = 0.0
		if swipe_cd <= 0.0:
			swipe_cd = 1.05
			_lunge()
			if hunter.has_method("receive_hit"):
				hunter.receive_hit(self, 1, 7.5)
			AudioDirector.play_at("whoosh", global_position, 0.7)
	else:
		var accel := 16.0 if kind == "runner" else 9.0
		velocity.x = move_toward(velocity.x, dir.x * spd, accel * delta)
		velocity.z = move_toward(velocity.z, dir.z * spd, accel * delta)
	move_and_slide()
	if air_slam and is_on_floor():
		air_slam = false
		if hunter and global_position.distance_to(hunter.global_position) < 3.4 and hunter.has_method("receive_hit"):
			hunter.receive_hit(self, 1, 10.0)
		if hunter and hunter.has_method("shake"):
			hunter.shake(0.45)
		FX.burst(get_parent(), global_position, Color("5A5E62"), 10, 1.6)
		AudioDirector.play_at("thud", global_position, 0.6)
	if global_position.y < -2.5:
		_die()


func _lunge() -> void:
	if vis == null:
		return
	var tw := create_tween()
	tw.tween_property(vis, "position:z", 0.22 * sc, 0.08)
	tw.tween_property(vis, "position:z", 0.0, 0.18)


func _separation() -> Vector3:
	var push := Vector3.ZERO
	var r := 0.95 * sc
	for n in get_tree().get_nodes_in_group("zed"):
		if n == self or not (n is Node3D):
			continue
		var o := (n as Node3D).global_position
		var d := global_position - o
		d.y = 0.0
		var l := d.length()
		if l < 0.01:
			push += Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * 0.3
		elif l < r:
			push += d / l * ((r - l) / r) * 0.9
	return push


func _goal() -> Vector3:
	if hunter and is_instance_valid(hunter):
		return hunter.global_position
	return global_position


func _wants_hunter() -> bool:
	return hunter != null and is_instance_valid(hunter)


func start_chew(_node: Node) -> void:
	pass


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
	flash_t = 0.09
	var limb := _nearest(pos)
	var headshot := limb == "head"
	last_head = headshot
	last_style = style
	if hunter and is_instance_valid(hunter) and hunter.world and float(hunter.world.get("insta_t")) > 0.0:
		dmg = maxi(dmg, 999)
	if limb != "" and parts[limb]["on"]:
		parts[limb]["hp"] -= dmg
		if parts[limb]["hp"] <= 0:
			_detach(limb, dir)
		else:
			FX.spark(get_parent(), pos)
	var real := dmg if not headshot else int(ceil(float(dmg) * 1.6))
	if style == "stake":
		real = int(ceil(float(real) * 1.15))
		stun = 0.45
	elif style == "frost":
		apply_slow(3.4)
		flash_t = 0.16
	elif style == "hex":
		flash_t = 0.22
		apply_slow(0.8)
	elif style == "nailer":
		stun = maxf(stun, 0.18)
	core -= real
	if style != "wire" and style != "spikes":
		if headshot:
			FX.float_text(get_parent(), pos, "HEAD! %d" % real, Color("FFE27A"), 44)
		else:
			FX.float_text(get_parent(), pos + Vector3(randf_range(-0.3, 0.3), 0, 0), str(real), Color("FFF6D8"), 30)
	if style == "stake":
		stun = maxf(stun, 0.45)
	elif style != "frost":
		stun = maxf(stun, 0.12)
	var push := dir
	push.y = 0.0
	if push.length() < 0.05:
		push = -vis.global_transform.basis.z
	velocity += push.normalized() * knock
	velocity.y = maxf(velocity.y, 2.2)
	AudioDirector.play_at("hit2", global_position, randf_range(0.85, 1.2))
	_refresh_hp()
	if core <= 0:
		_die()
		return
	_crawl_check()


func _nearest(pos: Vector3) -> String:
	var best := ""
	var best_d := 0.85 * sc
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
	FX.fling_bit(get_parent(), n.global_transform, col, 0.22 * sc, dir)
	FX.goo(get_parent(), n.global_position)
	AudioDirector.play_at("limb", global_position, randf_range(0.9, 1.25))
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
	_set_flash(false)
	if hp_root:
		hp_root.visible = false
	for id in parts.keys():
		var p: Dictionary = parts[id]
		if p["on"] and p["node"]:
			var n: Node3D = p["node"]
			var col := skin
			for c in n.get_children():
				if c is MeshInstance3D and (c as MeshInstance3D).material_override is StandardMaterial3D:
					col = ((c as MeshInstance3D).material_override as StandardMaterial3D).albedo_color
					break
			FX.fling_bit(get_parent(), n.global_transform, col, 0.2 * sc, Vector3(randf_range(-1, 1), 1, randf_range(-1, 1)))
	FX.goo(get_parent(), global_position + Vector3(0, 0.8, 0))
	AudioDirector.play_at("splat", global_position, randf_range(0.85, 1.1) * (0.75 if sc > 1.2 else 1.0))
	if hunter and is_instance_valid(hunter) and hunter.has_method("shake"):
		var d: float = global_position.distance_to(hunter.global_position)
		if d < 9.0:
			hunter.shake(0.1 + 0.15 * (sc - 0.8))
	popped.emit(kind, global_position, last_head, last_style)
	queue_free()


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.86 if kind != "skel" else 0.42
	m.rim_enabled = true
	m.rim = 0.32
	mats.append(m)
	return m
