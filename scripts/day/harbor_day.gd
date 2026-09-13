class_name HarborDay
extends Node3D

const Kid = preload("res://scripts/day/kid_player.gd")
const Star = preload("res://scripts/day/star_pickup.gd")
const Pup = preload("res://scripts/day/harbor_pup.gd")
const Foe = preload("res://scripts/day/arena_foe.gd")

var kid: CharacterBody3D
var stars := 0
var wave := 0
var alive := 0
var next_wave_in := 2.4
var won := false
var hud: Label
var hearts: Label
var title: Label
var hint: Label
var banner: Label
var hint_t := 10.0
var banner_t := 0.0
var clouds: Array[MeshInstance3D] = []


func _ready() -> void:
	InputSetup.ensure()
	AudioDirector.play_music("arena")
	_sky()
	_water()
	_arena()
	_scenery()
	_clouds()
	_bounds()
	_player()
	_pup()
	_hud()
	_show_banner("FIGHT!")


func _sky() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("6EB8FF")
	sm.sky_horizon_color = Color("FFE4C2")
	sm.sky_curve = 0.08
	sm.ground_bottom_color = Color("3E9A72")
	sm.ground_horizon_color = Color("F3D9A6")
	sm.sun_angle_max = 28.0
	sm.sun_curve = 0.04
	sky.sky_material = sm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 1.05
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 1.08
	e.ssao_enabled = true
	e.ssao_radius = 1.4
	e.ssao_intensity = 0.5
	e.glow_enabled = true
	e.glow_intensity = 0.42
	e.glow_bloom = 0.08
	e.fog_enabled = true
	e.fog_light_color = Color("D4ECFF")
	e.fog_density = 0.0024
	e.fog_aerial_perspective = 0.55
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.4
	sun.light_color = Color("FFF4E2")
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	sun.shadow_bias = 0.04
	add_child(sun)


func _water() -> void:
	var mi := MeshInstance3D.new()
	var p := PlaneMesh.new()
	p.size = Vector2(260, 260)
	p.subdivide_width = 4
	p.subdivide_depth = 4
	mi.mesh = p
	mi.position = Vector3(0, 0.04, 0)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.22, 0.58, 0.78, 0.78)
	m.roughness = 0.06
	m.metallic = 0.12
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.refraction_enabled = true
	m.refraction_scale = 0.03
	mi.material_override = m
	add_child(mi)


func _arena() -> void:
	_cyl(Vector3(0, 0.32, 0), 16.8, 0.72, Color("EBD4A4"), true)
	_cyl(Vector3(0, 0.78, 0), 14.0, 0.3, Color("7CC85C"), true)
	_cyl(Vector3(0, 0.95, 0), 5.6, 0.06, Color("F4C542"), false)
	_cyl(Vector3(0, 0.97, 0), 2.3, 0.05, Color("F7F3EC"), false)
	for i in 8:
		var a := TAU * i / 8.0
		_cyl(Vector3(cos(a) * 13.6, 1.15, sin(a) * 13.6), 0.16, 1.1, Color("F7F3EC"), true)
		_cyl(Vector3(cos(a) * 13.6, 1.72, sin(a) * 13.6), 0.22, 0.18, Color("E24B4B"), false)
	_tramp(Vector3(0, 1.08, -8.2))
	_box(Vector3(8.2, 1.15, 6.4), Vector3(1.4, 0.7, 1.4), Color("C48A4A"), true)
	_box(Vector3(-7.6, 1.15, 5.8), Vector3(1.2, 0.55, 1.2), Color("8A9098"), true)
	_box(Vector3(-6.8, 1.15, -7.2), Vector3(1.5, 0.6, 1.1), Color("C48A4A"), true)


func _scenery() -> void:
	_sphere(Vector3(22, 0.1, -16), 5.2, Color("EBD4A4"), true)
	_cyl(Vector3(22, 0.7, -16), 3.2, 1.1, Color("8A9098"), true)
	_cyl(Vector3(22, 2.7, -16), 1.15, 5.2, Color("F7F3EC"), true)
	_cyl(Vector3(22, 1.8, -16), 1.2, 1.0, Color("E24B4B"), true)
	_cyl(Vector3(22, 3.7, -16), 1.2, 1.0, Color("E24B4B"), true)
	_cyl(Vector3(22, 5.15, -16), 1.35, 0.65, Color("E24B4B"), true)
	_sphere(Vector3(22, 5.75, -16), 0.7, Color("FFE27A"), false)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(22, 5.8, -16)
	lamp.light_color = Color("FFE6A8")
	lamp.light_energy = 5.0
	lamp.omni_range = 18.0
	add_child(lamp)

	_sphere(Vector3(-21, 0.2, -12), 6.0, Color("7CC85C"), true)
	_house(Vector3(-20, 2.2, -11), Color("F4A07A"), Color("F7F3EC"))
	_house(Vector3(-23, 2.2, -13.5), Color("F2D56B"), Color("7BB7E0"))
	_house(Vector3(-18.5, 2.2, -14.5), Color("E989B3"), Color("FFF4CC"))

	_sphere(Vector3(-18, 0.15, 14), 5.5, Color("7CC85C"), true)
	_sphere(Vector3(-18, 0.9, 14), 3.6, Color("7CC85C"), true)
	var slide := CSGBox3D.new()
	slide.size = Vector3(2.1, 0.2, 7.5)
	slide.position = Vector3(-17.2, 2.1, 11.4)
	slide.rotation_degrees = Vector3(30, 20, 0)
	slide.material = _mat(Color("3B7CFF"))
	slide.use_collision = true
	add_child(slide)

	var wood := Color("C48A4A")
	_box(Vector3(0, 0.7, 22), Vector3(3.4, 0.22, 8), wood, true)
	_box(Vector3(0, 0.62, 26.5), Vector3(2.6, 0.4, 3.8), Color("D08A48"), true)
	_box(Vector3(0, 1.05, 25.6), Vector3(0.85, 0.65, 0.85), Color("F7F3EC"), true)
	for x in [-1.4, 1.4]:
		_box(Vector3(x, 0.3, 20), Vector3(0.2, 0.9, 0.2), Color("8A5A32"), true)
		_box(Vector3(x, 0.3, 24), Vector3(0.2, 0.9, 0.2), Color("8A5A32"), true)

	for p in [Vector3(22, 1.8, -12.5), Vector3(-21, 1.85, -8.5), Vector3(-15.5, 1.85, 12), Vector3(-24, 1.85, -12)]:
		_tree(p)
	_sphere(Vector3(19, 0.5, 10), 1.0, Color("9AA3A8"), true)
	_sphere(Vector3(-15, 0.45, 18), 0.9, Color("8B949A"), true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var cols := [Color("E56BA0"), Color("F4C542"), Color("7DCFC4"), Color("F07040")]
	for i in 28:
		var a := rng.randf() * TAU
		var r := rng.randf_range(14.2, 16.2)
		_sphere(Vector3(cos(a) * r, 1.02, sin(a) * r), 0.14, cols[i % cols.size()], false)


func _clouds() -> void:
	var spots := [
		Vector3(-18, 16, -10), Vector3(8, 18, 14), Vector3(22, 17, -8),
		Vector3(-6, 19, 20), Vector3(14, 15.5, 22)
	]
	for p in spots:
		var mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 2.4
		s.height = 2.2
		mi.mesh = s
		mi.position = p
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(1, 1, 1, 0.92)
		m.roughness = 1.0
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		clouds.append(mi)
		_sphere(p + Vector3(2.1, -0.2, 0.4), 1.7, Color(1, 1, 1, 0.9), false)
		_sphere(p + Vector3(-1.8, -0.15, -0.3), 1.5, Color(1, 1, 1, 0.9), false)


func _bounds() -> void:
	for i in 16:
		var a := TAU * i / 16.0
		var b := StaticBody3D.new()
		b.collision_layer = 1
		b.position = Vector3(cos(a) * 42.0, 2.5, sin(a) * 42.0)
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(4, 10, 10)
		cs.shape = box
		cs.rotation.y = -a
		b.add_child(cs)
		add_child(b)


func _player() -> void:
	kid = Kid.new()
	kid.position = Vector3(0, 2.4, 3)
	kid.hp_changed.connect(_on_hp)
	add_child(kid)


func _pup() -> void:
	var pup = Pup.new()
	pup.position = Vector3(2.0, 1.6, 4.5)
	pup.kid = kid
	add_child(pup)


func _hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	title = Label.new()
	title.text = "HARBOR DAY"
	title.position = Vector2(56, 32)
	title.add_theme_font_size_override("font_size", 52)
	if Art.font_title:
		title.add_theme_font_override("font", Art.font_title)
	title.add_theme_color_override("font_color", Color("FFF6D8"))
	title.add_theme_color_override("font_outline_color", Color(0.12, 0.18, 0.22, 0.92))
	title.add_theme_constant_override("outline_size", 10)
	root.add_child(title)
	hearts = Label.new()
	hearts.position = Vector2(56, 96)
	hearts.add_theme_font_size_override("font_size", 34)
	if Art.font_body:
		hearts.add_theme_font_override("font", Art.font_body)
	hearts.add_theme_color_override("font_color", Color("E56BA0"))
	hearts.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.14, 0.9))
	hearts.add_theme_constant_override("outline_size", 8)
	root.add_child(hearts)
	hud = Label.new()
	hud.position = Vector2(56, 140)
	hud.add_theme_font_size_override("font_size", 30)
	if Art.font_body:
		hud.add_theme_font_override("font", Art.font_body)
	hud.add_theme_color_override("font_color", Color("FFE27A"))
	hud.add_theme_color_override("font_outline_color", Color(0.1, 0.14, 0.18, 0.92))
	hud.add_theme_constant_override("outline_size", 8)
	root.add_child(hud)
	hint = Label.new()
	hint.text = "Stick to run     A / Space jump     X / Click punch     Y spin"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.offset_left = 56
	hint.offset_bottom = -48
	hint.offset_top = -96
	hint.offset_right = 1600
	hint.add_theme_font_size_override("font_size", 24)
	if Art.font_body:
		hint.add_theme_font_override("font", Art.font_body)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	hint.add_theme_color_override("font_outline_color", Color(0.08, 0.1, 0.14, 0.88))
	hint.add_theme_constant_override("outline_size", 6)
	root.add_child(hint)
	banner = Label.new()
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.offset_left = -400
	banner.offset_right = 400
	banner.offset_top = -80
	banner.offset_bottom = 80
	banner.add_theme_font_size_override("font_size", 72)
	if Art.font_title:
		banner.add_theme_font_override("font", Art.font_title)
	banner.add_theme_color_override("font_color", Color("FFF6D8"))
	banner.add_theme_color_override("font_outline_color", Color(0.12, 0.16, 0.2, 0.95))
	banner.add_theme_constant_override("outline_size", 12)
	root.add_child(banner)
	_on_hp(5, 5)
	_refresh()


func _process(delta: float) -> void:
	if hint_t > 0.0:
		hint_t -= delta
		if hint and hint_t < 1.6:
			hint.modulate.a = hint_t / 1.6
	if title:
		title.modulate.a = clampf(1.2 - (10.0 - hint_t) * 0.22, 0.35, 1.0)
	if banner_t > 0.0:
		banner_t -= delta
		if banner:
			banner.modulate.a = clampf(banner_t / 0.4, 0.0, 1.0) if banner_t < 0.4 else 1.0
	for i in clouds.size():
		var c := clouds[i]
		c.position.x += delta * (0.35 + i * 0.08)
		if c.position.x > 40.0:
			c.position.x = -40.0
	if alive <= 0:
		next_wave_in -= delta
		if next_wave_in <= 0.0:
			_start_wave()


func _start_wave() -> void:
	wave += 1
	var roster: Array = []
	match wave:
		1:
			roster = ["grump", "grump"]
		2:
			roster = ["grump", "hopper"]
		3:
			roster = ["grump", "grump", "hopper"]
		4:
			roster = ["champ"]
		_:
			roster = ["grump", "hopper", "grump"]
			if wave % 3 == 0:
				roster.append("champ")
			if wave >= 6:
				roster.append("hopper")
	alive = roster.size()
	_show_banner("WAVE  %d" % wave if wave != 4 else "CHAMP!")
	AudioDirector.play("confirm" if wave != 4 else "boss", 1.05)
	for i in roster.size():
		var a := TAU * float(i) / float(roster.size()) + 0.35
		_spawn_foe(roster[i], Vector3(cos(a) * 8.5, 2.3, sin(a) * 8.5))
	_refresh()


func _spawn_foe(kind: String, pos: Vector3) -> void:
	var f = Foe.new()
	f.setup(kind, kid)
	f.position = pos
	f.popped.connect(_on_foe_popped.bind(f, kind))
	add_child(f)


func _on_foe_popped(f: Node3D, kind: String) -> void:
	alive = maxi(0, alive - 1)
	stars += 1 if kind != "champ" else 2
	var drops := 2 if kind == "champ" else 1
	var origin := Vector3.ZERO
	if is_instance_valid(f):
		origin = f.global_position
	origin.y = maxf(origin.y, 1.4)
	var xz := Vector2(origin.x, origin.z)
	if xz.length() > 11.5:
		xz = xz.normalized() * 11.0
		origin.x = xz.x
		origin.z = xz.y
	for i in drops:
		var s = Star.new()
		s.position = origin + Vector3(randf_range(-0.5, 0.5), 0.2 * i, randf_range(-0.5, 0.5))
		s.collected.connect(_on_star)
		add_child(s)
	if alive <= 0:
		next_wave_in = 2.2
		if wave == 4 and not won:
			won = true
			AudioDirector.play("win")
			_show_banner("YOU WIN!")
			if hint:
				hint.text = "Keep going — more rivals keep jumping in."
				hint.modulate.a = 1.0
				hint_t = 8.0
	_refresh()


func _on_star() -> void:
	if kid and kid.has_method("heal"):
		kid.heal(1)


func _on_hp(hp: int, max_hp: int) -> void:
	if hearts == null:
		return
	var s := "Hearts  "
	for i in max_hp:
		s += "●" if i < hp else "○"
	hearts.text = s


func _show_banner(text: String) -> void:
	if banner:
		banner.text = text
		banner.modulate.a = 1.0
	banner_t = 1.8


func _refresh() -> void:
	if hud:
		hud.text = "Wave  %d      Stars  %d      Rivals  %d" % [maxi(wave, 1), stars, alive]


func _tramp(pos: Vector3) -> void:
	_cyl(pos, 1.55, 0.28, Color("E56BA0"), true)
	_cyl(pos + Vector3(0, 0.12, 0), 1.25, 0.12, Color("FFE27A"), false)
	var a := Area3D.new()
	a.position = pos + Vector3(0, 0.45, 0)
	a.collision_mask = 6
	a.monitoring = true
	var cs := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = 1.4
	s.height = 0.7
	cs.shape = s
	a.add_child(cs)
	a.body_entered.connect(func(n):
		if n.has_method("bounce"):
			n.bounce(13.5)
	)
	add_child(a)


func _house(pos: Vector3, wall: Color, roof: Color) -> void:
	_box(pos, Vector3(3.3, 2.25, 3.3), wall, true)
	var r := CSGBox3D.new()
	r.size = Vector3(4.0, 1.25, 4.0)
	r.position = pos + Vector3(0, 1.65, 0)
	r.rotation_degrees = Vector3(0, 45, 0)
	r.material = _mat(roof)
	r.use_collision = true
	add_child(r)
	_box(pos + Vector3(0, -0.15, 1.75), Vector3(0.72, 1.25, 0.16), Color("6B3A18"), true)
	_box(pos + Vector3(-0.85, 0.25, 1.68), Vector3(0.55, 0.45, 0.08), Color("FFF6D8"), false)
	_box(pos + Vector3(0.85, 0.25, 1.68), Vector3(0.55, 0.45, 0.08), Color("FFF6D8"), false)


func _tree(pos: Vector3) -> void:
	_cyl(pos, 0.3, 1.7, Color("7A4A28"), true)
	_sphere(pos + Vector3(0, 1.55, 0), 1.45, Color("3FA35A"), true)
	_sphere(pos + Vector3(0.5, 1.75, 0.25), 0.95, Color("58B86A"), false)
	_sphere(pos + Vector3(-0.4, 1.65, -0.2), 0.8, Color("4AAD62"), false)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.68
	m.metallic = 0.0
	if c.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _box(pos: Vector3, size: Vector3, color: Color, coll: bool) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.material = _mat(color)
	b.use_collision = coll
	add_child(b)
	return b


func _cyl(pos: Vector3, radius: float, height: float, color: Color, coll: bool) -> CSGCylinder3D:
	var c := CSGCylinder3D.new()
	c.radius = radius
	c.height = height
	c.sides = 16
	c.position = pos
	c.material = _mat(color)
	c.use_collision = coll
	add_child(c)
	return c


func _sphere(pos: Vector3, radius: float, color: Color, coll: bool) -> CSGSphere3D:
	var s := CSGSphere3D.new()
	s.radius = radius
	s.radial_segments = 16
	s.rings = 10
	s.position = pos
	s.material = _mat(color)
	s.use_collision = coll
	add_child(s)
	return s
