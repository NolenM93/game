extends Node3D

const Hunter = preload("res://scripts/hollow/hunter.gd")
const Zed = preload("res://scripts/hollow/zed.gd")
const Grave = preload("res://scripts/hollow/grave.gd")
const Keep = preload("res://scripts/hollow/lantern_keep.gd")
const Build = preload("res://scripts/hollow/buildable.gd")
const FX = preload("res://scripts/hollow/hollow_fx.gd")
const PackData = preload("res://scripts/hollow/pack.gd")
const LootDrop = preload("res://scripts/hollow/loot.gd")

var hunter
var keep
var graves: Array = []
var candy := 70
var wave := 0
var alive := 0
var to_spawn: Array = []
var spawn_t := 0.0
var prep := 40.0
var fighting := false
var over := false
var won := false
var cells := {}
var hud: Label
var hearts: Label
var gear: Label
var hint: Label
var banner: Label
var bar: ColorRect
var bar_bg: ColorRect
var hint_t := 18.0
var banner_t := 0.0
var env: Environment
var fireflies: Array[MeshInstance3D] = []
var bats: Array[Dictionary] = []
var mist: Array[MeshInstance3D] = []
var fog_base := 0.038
var hill_pads: Array[Vector3] = []


func _ready() -> void:
	InputSetup.ensure()
	AudioDirector.play_music("hollow")
	_sky()
	_ground()
	_hills()
	_yard()
	_woods()
	_bats()
	_mist()
	_keep()
	_graves()
	_hunter()
	_hud()
	_show("FORTIFY THE LANTERN")


func lantern_frac() -> float:
	if keep and keep.get("hp") != null and keep.get("max_hp"):
		return float(keep.hp) / float(keep.max_hp)
	return 1.0


func snap_build(p: Vector3) -> Vector3:
	var g := 1.85
	return Vector3(snappedf(p.x, g), 0.82, snappedf(p.z, g))


func can_build(p: Vector3, cost: int) -> bool:
	if over or candy < cost:
		return false
	var s := snap_build(p)
	if Vector2(s.x, s.z).length() < 3.2:
		return false
	if Vector2(s.x, s.z).length() > 24.0:
		return false
	return not cells.has(_key(s))


func try_build(kind: String, p: Vector3, cost: int) -> bool:
	var s := snap_build(p)
	if not can_build(s, cost):
		AudioDirector.play("ui", 0.6)
		return false
	candy -= cost
	var b = Build.new()
	b.setup(kind)
	b.position = s
	if hunter:
		b.rotation.y = hunter.cam_yaw
	cells[_key(s)] = b
	b.tree_exiting.connect(func():
		cells.erase(_key(s))
	)
	add_child(b)
	AudioDirector.play("build")
	FX.wood(self, s + Vector3(0, 0.4, 0))
	_refresh()
	return true


func add_candy(n: int, pos: Vector3 = Vector3.ZERO) -> void:
	candy += n
	if pos != Vector3.ZERO:
		FX.float_text(self, pos, "+%d 🍬" % n, Color("FFB347"))
	_refresh()


func player_down() -> void:
	if keep and keep.has_method("chew"):
		keep.chew(12)
	_show("DOWN! The lantern flickered...")
	AudioDirector.play("alarm", 0.8)


func _key(p: Vector3) -> String:
	return "%d,%d" % [int(round(p.x / 1.85)), int(round(p.z / 1.85))]


func _sky() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("05060F")
	sm.sky_horizon_color = Color("3A1A22")
	sm.sky_curve = 0.07
	sm.ground_bottom_color = Color("050608")
	sm.ground_horizon_color = Color("1A1014")
	sm.sun_angle_max = 4.0
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("1A2238")
	env.ambient_light_energy = 0.16
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.88
	env.ssao_enabled = true
	env.ssao_intensity = 1.8
	env.glow_enabled = true
	env.glow_intensity = 0.85
	env.glow_bloom = 0.22
	env.fog_enabled = true
	env.fog_light_color = Color("2A1A28")
	env.fog_density = 0.016
	env.fog_aerial_perspective = 0.85
	env.fog_sky_affect = 0.35
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = fog_base
	env.volumetric_fog_albedo = Color("2A2438")
	env.volumetric_fog_emission = Color("140C18")
	env.volumetric_fog_length = 160.0
	env.volumetric_fog_sky_affect = 0.2
	we.environment = env
	add_child(we)
	var moonlit := DirectionalLight3D.new()
	moonlit.rotation_degrees = Vector3(-42, 52, 0)
	moonlit.light_color = Color("A8C4F0")
	moonlit.light_energy = 0.55
	moonlit.shadow_enabled = true
	moonlit.directional_shadow_max_distance = 180.0
	add_child(moonlit)
	_moon()
	_stars()


func _moon() -> void:
	var moon := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 16.0
	sph.height = 32.0
	moon.mesh = sph
	moon.position = Vector3(-90, 110, -80)
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.albedo_color = Color("F0E6C8")
	mm.disable_fog = true
	moon.material_override = mm
	moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(moon)
	for crater in [Vector3(-6, 4, 12), Vector3(8, -5, 10), Vector3(-2, 9, 8)]:
		var c := MeshInstance3D.new()
		var cs := SphereMesh.new()
		cs.radius = 3.2
		cs.height = 6.4
		c.mesh = cs
		c.position = moon.position + crater
		var cm := StandardMaterial3D.new()
		cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cm.albedo_color = Color("C8B898")
		cm.disable_fog = true
		c.material_override = cm
		c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(c)
	var glow := OmniLight3D.new()
	glow.position = Vector3(-70, 90, -60)
	glow.light_color = Color("E8DCC0")
	glow.light_energy = 8.0
	glow.omni_range = 80.0
	add_child(glow)


func _stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 140:
		var mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = rng.randf_range(0.35, 1.1)
		s.height = s.radius * 2.0
		mi.mesh = s
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.15, 1.0), rng.randf_range(-1, 1)).normalized()
		mi.position = dir * rng.randf_range(220.0, 320.0)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1, 1, 1, rng.randf_range(0.45, 1.0))
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.disable_fog = true
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)


func _ground() -> void:
	_cyl(Vector3(0, 0.2, 0), 78.0, 0.9, Color("1A2016"), true)
	_cyl(Vector3(0, 0.58, 0), 62.0, 0.28, Color("243022"), true)
	_cyl(Vector3(0, 0.72, 0), 6.4, 0.08, Color("4A4E55"), false)


func _hills() -> void:
	var hills := [
		{"xz": Vector3(42, 0, 18), "h": 2.5, "r": 36.0, "loot": ["gun_nailer", "ammo", "ammo"]},
		{"xz": Vector3(-44, 0, -12), "h": 2.4, "r": 34.0, "loot": ["gun_gloop", "candy", "ammo"]},
		{"xz": Vector3(20, 0, -44), "h": 2.6, "r": 38.0, "loot": ["gun_rocket", "ammo", "candy"]},
		{"xz": Vector3(-26, 0, 44), "h": 2.3, "r": 34.0, "loot": ["gun_shotgun", "ammo", "ammo"]},
		{"xz": Vector3(54, 0, -28), "h": 2.5, "r": 36.0, "loot": ["ammo", "ammo", "candy"]},
		{"xz": Vector3(-56, 0, 24), "h": 2.4, "r": 35.0, "loot": ["gun_nailer", "candy", "ammo"]},
		{"xz": Vector3(10, 0, 54), "h": 2.2, "r": 33.0, "loot": ["bat", "ammo", "candy"]},
		{"xz": Vector3(-16, 0, -52), "h": 2.4, "r": 34.0, "loot": ["gun_gloop", "ammo", "candy"]}
	]
	for h in hills:
		var pad: Vector3 = _mound(h["xz"], h["h"], h["r"])
		_shed(pad, h["loot"])
	var chapel_pad := _mound(Vector3(2, 0, -62), 2.8, 40.0)
	_chapel(chapel_pad)
	_shed(chapel_pad + Vector3(7.5, 0, 2.5), ["gun_rocket", "ammo", "candy"])
	for i in 14:
		var a := TAU * i / 14.0 + 0.11
		_sphere(Vector3(cos(a) * 92.0, 4.0, sin(a) * 92.0), randf_range(16.0, 24.0), Color("12160F"), false)


func _mound(xz: Vector3, height: float, radius: float) -> Vector3:
	var ground := 0.7
	var cy := ground - radius + height
	_sphere(Vector3(xz.x, cy, xz.z), radius, Color("1E281C"), true)
	_sphere(Vector3(xz.x + radius * 0.12, cy - 0.6, xz.z + radius * 0.08), radius * 0.7, Color("243022"), true)
	var top := Vector3(xz.x, ground + height, xz.z)
	hill_pads.append(top)
	_cyl(top + Vector3(0, -0.08, 0), 6.4, 0.32, Color("2A3224"), true)
	return top


func _chapel(pad: Vector3) -> void:
	_box(pad + Vector3(0, 3.4, 0), Vector3(9.0, 7.0, 2.2), Color("2A2430"), true)
	_box(pad + Vector3(-3.2, 7.4, 0), Vector3(2.8, 2.6, 1.6), Color("1A1520"), true)
	_box(pad + Vector3(3.2, 7.4, 0), Vector3(2.8, 2.6, 1.6), Color("1A1520"), true)
	_box(pad + Vector3(0, 9.6, 0), Vector3(1.4, 3.2, 1.4), Color("3A2A22"), false)


func _shed(pad: Vector3, loot: Array) -> void:
	var n := Node3D.new()
	n.position = pad
	var toward := Vector3(-pad.x, 0, -pad.z)
	if toward.length() > 0.2:
		n.rotation.y = atan2(toward.x, toward.z)
	add_child(n)
	_box(Vector3(0, 0.12, 0), Vector3(4.6, 0.24, 3.8), Color("3A2A1C"), true, n)
	_box(Vector3(0, 1.45, -1.82), Vector3(4.6, 2.5, 0.18), Color("4A3424"), true, n)
	_box(Vector3(-2.22, 1.45, 0), Vector3(0.18, 2.5, 3.8), Color("4A3424"), true, n)
	_box(Vector3(2.22, 1.45, 0), Vector3(0.18, 2.5, 3.8), Color("4A3424"), true, n)
	_box(Vector3(-1.5, 1.45, 1.82), Vector3(1.5, 2.5, 0.18), Color("4A3424"), true, n)
	_box(Vector3(1.5, 1.45, 1.82), Vector3(1.5, 2.5, 0.18), Color("4A3424"), true, n)
	_box(Vector3(0, 2.8, 0), Vector3(5.0, 0.16, 4.2), Color("2A1C14"), true, n)
	_box(Vector3(0, 3.15, 0), Vector3(3.2, 0.18, 3.0), Color("3A2418"), false, n)
	_cyl(Vector3(-1.9, 1.4, -1.5), 0.12, 2.6, Color("2A1C14"), false, n)
	_cyl(Vector3(1.9, 1.4, -1.5), 0.12, 2.6, Color("2A1C14"), false, n)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 2.2, 0)
	lamp.light_color = Color("FF8A3A")
	lamp.light_energy = 1.4
	lamp.omni_range = 7.0
	n.add_child(lamp)
	_pumpkin(n.to_global(Vector3(2.4, 1.0, 2.2)))
	_box(Vector3(-2.9, 0.55, 0.8), Vector3(0.9, 0.8, 0.9), Color("6A3A22"), true, n)
	var spots := [Vector3(0.0, 0.28, 2.45), Vector3(0.85, 0.28, 2.55), Vector3(-0.85, 0.28, 2.55)]
	for i in loot.size():
		var id := str(loot[i])
		var local: Vector3 = spots[i % spots.size()]
		_spawn_loot(n.to_global(local), id)


func _yard() -> void:
	# Broken cemetery fence around the inner yard, not a cage.
	for i in 18:
		if i % 5 == 0:
			continue
		var a := TAU * i / 18.0
		var p := Vector3(cos(a) * 21.0, 0, sin(a) * 21.0)
		var gy := _ground_y(p)
		_box(Vector3(p.x, gy + 1.1, p.z), Vector3(0.16, 2.2, 0.16), Color("2A2E34"), true)
		if i % 2 == 0:
			_box(Vector3(p.x, gy + 1.95, p.z), Vector3(2.2, 0.08, 0.08), Color("3A3E44"), false)
	_sit_box(Vector3(-5.2, 0, 4.0), Vector3(1.8, 1.2, 1.2), Color("3A342C"), true)
	_sit_box(Vector3(6.4, 0, -3.2), Vector3(1.4, 1.4, 2.2), Color("4A4E55"), true)
	_sit_box(Vector3(3.2, 0, 8.5), Vector3(2.4, 0.7, 1.1), Color("2A241C"), true)
	for p in [
		Vector3(7.5, 0, 2.2), Vector3(-8.2, 0, -1.4), Vector3(12.0, 0, -6.5),
		Vector3(-11.5, 0, 8.0), Vector3(15.5, 0, 11.0), Vector3(-14.5, 0, -10.5),
		Vector3(9.5, 0, 16.0), Vector3(-18.0, 0, 6.0)
	]:
		_pumpkin(p)
	for i in 6:
		var a := TAU * i / 6.0 + 0.5
		_lamp_post(Vector3(cos(a) * 8.5, 0, sin(a) * 8.5))
	for i in 28:
		var ff := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.06
		s.height = 0.12
		ff.mesh = s
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color("FFE27A")
		m.emission_enabled = true
		m.emission = Color("FFE27A")
		m.disable_fog = true
		ff.material_override = m
		var xz := Vector3(randf_range(-40, 40), 0, randf_range(-40, 40))
		ff.position = Vector3(xz.x, _ground_y(xz) + randf_range(1.4, 2.6), xz.z)
		add_child(ff)
		fireflies.append(ff)
	for i in 20:
		var a := TAU * i / 20.0
		var b := StaticBody3D.new()
		b.collision_layer = 1
		b.position = Vector3(cos(a) * 76.0, 4.0, sin(a) * 76.0)
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(6, 16, 14)
		cs.shape = box
		cs.rotation.y = -a
		b.add_child(cs)
		add_child(b)


func _woods() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for i in 70:
		var a := rng.randf() * TAU
		var r := rng.randf_range(28.0, 68.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if Vector2(p.x, p.z).length() < 20.0:
			continue
		var blocked := false
		for pad in hill_pads:
			if Vector2(p.x - pad.x, p.z - pad.z).length() < 10.0:
				blocked = true
				break
		if blocked:
			continue
		if rng.randf() < 0.35:
			_dead_tree(p)
		else:
			_tree(p)
	for i in 8:
		var a := TAU * i / 8.0 + 0.4
		_dead_tree(Vector3(cos(a) * 26.0, 0, sin(a) * 26.0))


func _pumpkin(at: Vector3) -> void:
	var gy := _ground_y(at)
	var pos := Vector3(at.x, gy + 0.42, at.z)
	_sphere(pos, 0.42, Color("E07020"), false)
	_cyl(pos + Vector3(0, 0.42, 0), 0.06, 0.22, Color("3A8A3A"), false)
	_box(pos + Vector3(-0.1, 0.08, 0.32), Vector3(0.08, 0.06, 0.05), Color("1A1520"), false)
	_box(pos + Vector3(0.1, 0.08, 0.32), Vector3(0.08, 0.06, 0.05), Color("1A1520"), false)


func _lamp_post(at: Vector3) -> void:
	var gy := _ground_y(at)
	_cyl(Vector3(at.x, gy + 1.15, at.z), 0.07, 2.3, Color("2A1C14"), true)
	_box(Vector3(at.x, gy + 2.28, at.z), Vector3(0.36, 0.08, 0.36), Color("3A2418"), false)
	_sphere(Vector3(at.x, gy + 2.42, at.z), 0.2, Color("FFB347"), false)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(at.x, gy + 2.42, at.z)
	lamp.light_color = Color("FF8A3A")
	lamp.light_energy = 1.6
	lamp.omni_range = 6.5
	add_child(lamp)


func _bats() -> void:
	for i in 22:
		var n := Node3D.new()
		add_child(n)
		var body := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.2
		sph.height = 0.28
		body.mesh = sph
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color("0C0C10")
		bm.roughness = 0.9
		body.material_override = bm
		n.add_child(body)
		var wl := _bat_wing(Vector3(-0.28, 0, 0), -1)
		var wr := _bat_wing(Vector3(0.28, 0, 0), 1)
		n.add_child(wl)
		n.add_child(wr)
		bats.append({
			"n": n,
			"l": wl,
			"r": wr,
			"c": Vector3(randf_range(-40, 40), randf_range(7, 18), randf_range(-40, 40)),
			"rad": randf_range(10.0, 24.0),
			"spd": randf_range(0.55, 1.2),
			"ph": randf() * TAU
		})


func _bat_wing(pos: Vector3, side: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.85, 0.05, 0.38)
	mi.mesh = b
	mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("121218")
	mi.material_override = m
	mi.scale.x = side
	return mi


func _mist() -> void:
	for i in 12:
		var mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = randf_range(6.0, 11.0)
		s.height = s.radius * 1.1
		mi.mesh = s
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(0.35, 0.32, 0.42, 0.11)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(randf_range(-50, 50), randf_range(1.2, 3.5), randf_range(-50, 50))
		add_child(mi)
		mist.append(mi)


func _tree(xz: Vector3) -> void:
	var gy := _ground_y(xz)
	var pos := Vector3(xz.x, gy + 1.55, xz.z)
	_cyl(pos, 0.32, 3.1, Color("1A1210"), true)
	_sphere(pos + Vector3(0, 1.55, 0), 1.8, Color("152016"), false)
	_sphere(pos + Vector3(0.9, 1.25, -0.5), 1.1, Color("10180F"), false)
	_sphere(pos + Vector3(-0.7, 1.35, 0.4), 0.95, Color("121C10"), false)


func _dead_tree(xz: Vector3) -> void:
	var gy := _ground_y(xz)
	var pos := Vector3(xz.x, gy + 2.05, xz.z)
	_cyl(pos, 0.22, 4.1, Color("1A1410"), true)
	_box(pos + Vector3(0.7, 0.5, 0), Vector3(1.6, 0.12, 0.12), Color("1A1410"), false)
	_box(pos + Vector3(-0.5, 1.1, 0.2), Vector3(1.2, 0.1, 0.1), Color("1A1410"), false)
	_box(pos + Vector3(0.2, 1.8, -0.6), Vector3(0.12, 0.12, 1.4), Color("1A1410"), false)


func _keep() -> void:
	keep = Keep.new()
	keep.position = Vector3(0, 0.82, 0)
	keep.hurt.connect(func(_h, _m): _refresh())
	keep.ruined.connect(_on_ruined)
	add_child(keep)


func _graves() -> void:
	var rings := [16.5, 24.5, 34.0]
	var counts := [10, 12, 14]
	for r in rings.size():
		for i in counts[r]:
			var a := TAU * float(i) / float(counts[r]) + r * 0.17
			var g = Grave.new()
			g.position = Vector3(cos(a) * rings[r], _ground_y(Vector3(cos(a) * rings[r], 0, sin(a) * rings[r])), sin(a) * rings[r])
			g.rotation.y = a + PI
			g.burst.connect(_spawn_at.bind(g))
			add_child(g)
			graves.append(g)


func _hunter() -> void:
	hunter = Hunter.new()
	hunter.world = self
	hunter.position = Vector3(0, 2.2, 5.5)
	hunter.hp_changed.connect(func(_a, _b): _refresh())
	hunter.loadout_changed.connect(_refresh)
	add_child(hunter)


func _hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var title := Label.new()
	title.text = "LANTERN HOLLOW"
	title.position = Vector2(48, 24)
	title.add_theme_font_size_override("font_size", 40)
	if Art.font_title:
		title.add_theme_font_override("font", Art.font_title)
	title.add_theme_color_override("font_color", Color("FFB347"))
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08, 0.95))
	title.add_theme_constant_override("outline_size", 10)
	root.add_child(title)
	hearts = Label.new()
	hearts.position = Vector2(48, 72)
	hearts.add_theme_font_size_override("font_size", 26)
	if Art.font_body:
		hearts.add_theme_font_override("font", Art.font_body)
	hearts.add_theme_color_override("font_color", Color("E56BA0"))
	hearts.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08, 0.95))
	hearts.add_theme_constant_override("outline_size", 7)
	root.add_child(hearts)
	hud = Label.new()
	hud.position = Vector2(48, 106)
	hud.add_theme_font_size_override("font_size", 24)
	if Art.font_body:
		hud.add_theme_font_override("font", Art.font_body)
	hud.add_theme_color_override("font_color", Color("D4E0C8"))
	hud.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08, 0.95))
	hud.add_theme_constant_override("outline_size", 7)
	root.add_child(hud)
	gear = Label.new()
	gear.position = Vector2(48, 168)
	gear.add_theme_font_size_override("font_size", 22)
	if Art.font_body:
		gear.add_theme_font_override("font", Art.font_body)
	gear.add_theme_color_override("font_color", Color("FFE27A"))
	gear.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08, 0.95))
	gear.add_theme_constant_override("outline_size", 7)
	root.add_child(gear)
	bar_bg = ColorRect.new()
	bar_bg.color = Color(0.08, 0.08, 0.1, 0.7)
	bar_bg.position = Vector2(48, 146)
	bar_bg.size = Vector2(280, 14)
	root.add_child(bar_bg)
	bar = ColorRect.new()
	bar.color = Color("FFB347")
	bar.position = Vector2(48, 146)
	bar.size = Vector2(280, 14)
	root.add_child(bar)
	hint = Label.new()
	hint.text = "Mouse aim     WASD move     scroll zoom     E pack     Y / Tab build"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.offset_left = 48
	hint.offset_top = -90
	hint.offset_bottom = -40
	hint.offset_right = 1700
	hint.add_theme_font_size_override("font_size", 20)
	if Art.font_body:
		hint.add_theme_font_override("font", Art.font_body)
	hint.add_theme_color_override("font_color", Color(0.85, 0.88, 0.8, 0.9))
	hint.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08, 0.9))
	hint.add_theme_constant_override("outline_size", 6)
	root.add_child(hint)
	banner = Label.new()
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.offset_left = -520
	banner.offset_right = 520
	banner.offset_top = -90
	banner.offset_bottom = 90
	banner.add_theme_font_size_override("font_size", 64)
	if Art.font_title:
		banner.add_theme_font_override("font", Art.font_title)
	banner.add_theme_color_override("font_color", Color("FFB347"))
	banner.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.1, 0.95))
	banner.add_theme_constant_override("outline_size", 14)
	root.add_child(banner)
	_refresh()


func _process(delta: float) -> void:
	if hint_t > 0.0:
		hint_t -= delta
		if hint and hint_t < 1.5:
			hint.modulate.a = hint_t / 1.5
	if banner_t > 0.0:
		banner_t -= delta
		if banner:
			banner.modulate.a = clampf(banner_t, 0.0, 1.0)
	for i in fireflies.size():
		var f := fireflies[i]
		f.position.y += sin(Time.get_ticks_msec() * 0.002 + i) * delta * 0.4
		f.position.x += sin(Time.get_ticks_msec() * 0.001 + i * 0.7) * delta * 0.35
	var t := Time.get_ticks_msec() * 0.001
	for b in bats:
		var n: Node3D = b["n"]
		var ang: float = t * b["spd"] + b["ph"]
		var c: Vector3 = b["c"]
		n.position = c + Vector3(cos(ang) * b["rad"], sin(t * 1.6 + b["ph"]) * 1.4, sin(ang) * b["rad"] * 0.72)
		n.rotation.y = -ang + PI * 0.5
		b["l"].rotation.z = sin(t * 22.0 + b["ph"]) * 0.85
		b["r"].rotation.z = -sin(t * 22.0 + b["ph"]) * 0.85
	for i in mist.size():
		mist[i].position.x += sin(t * 0.15 + i) * delta * 0.6
		mist[i].position.z += cos(t * 0.12 + i) * delta * 0.5
	if over:
		return
	if not fighting:
		prep -= delta
		if prep <= 0.0:
			_begin_wave()
	else:
		spawn_t -= delta
		if spawn_t <= 0.0 and to_spawn.size() > 0:
			_wake_next()
			spawn_t = clampf(0.55 - wave * 0.03, 0.22, 0.55)
		if to_spawn.is_empty() and alive <= 0:
			fighting = false
			prep = 34.0
			add_candy(8 + wave * 2)
			if wave == 8 and not won:
				won = true
				_show("THE HOLLOW GOES QUIET... keep going")
				AudioDirector.play("win")
			else:
				_show("WAVE CLEAR  —  fortify")
			AudioDirector.play("confirm")
	_refresh()


func _begin_wave() -> void:
	wave += 1
	fighting = true
	to_spawn = _roster(wave)
	alive = 0
	spawn_t = 0.2
	if env:
		env.volumetric_fog_density = clampf(fog_base + wave * 0.004, 0.038, 0.09)
	var title := "WAVE  %d" % wave
	if wave == 5:
		title = "THE MAYOR WALKS"
	elif wave == 8:
		title = "HORDE NIGHT"
	_show(title)
	AudioDirector.play("boss" if wave == 5 else "alarm", 0.85)
	_refresh()


func _roster(w: int) -> Array:
	var r: Array = []
	var n := 6 + w * 2
	if w >= 8:
		n = 12 + w
	for i in n:
		if w >= 5 and i == 0:
			r.append("mayor")
		elif w >= 3 and i % 6 == 0:
			r.append("lunk")
		elif w >= 2 and i % 3 == 0:
			r.append("runner")
		else:
			r.append("shambler")
	return r


func _wake_next() -> void:
	if to_spawn.is_empty() or graves.is_empty():
		return
	var kind: String = to_spawn.pop_front()
	var g = graves[randi() % graves.size()]
	if g.has_method("wake"):
		g.wake(kind)


func _spawn_at(kind: String, g: Node3D) -> void:
	if over:
		return
	var z = Zed.new()
	z.setup(kind, keep, hunter)
	z.position = g.global_position + Vector3(0, 0.2, 0.7)
	z.popped.connect(_on_pop)
	add_child(z)
	alive += 1
	FX.goo(self, z.global_position)
	_refresh()


func _on_pop(kind: String, pos: Vector3) -> void:
	alive = maxi(0, alive - 1)
	var pay := 3
	if kind == "runner":
		pay = 2
	elif kind == "lunk":
		pay = 6
	elif kind == "mayor":
		pay = 15
	add_candy(pay, pos)
	_refresh()


func _on_ruined() -> void:
	over = true
	_show("THE LANTERN WENT OUT")
	if hint:
		hint.text = "Press Enter / Start to watch again"
		hint.modulate.a = 1.0
		hint_t = 999.0


func _unhandled_input(event: InputEvent) -> void:
	if over and (event.is_action_pressed("ui_confirm") or event.is_action_pressed("jump")):
		get_tree().reload_current_scene()


func _show(text: String) -> void:
	if banner:
		banner.text = text
		banner.modulate.a = 1.0
	banner_t = 2.2


func _refresh() -> void:
	if hearts and hunter:
		var s := "Hunter  "
		for i in hunter.max_hp:
			s += "●" if i < hunter.hp else "○"
		hearts.text = s
	if hud:
		if not fighting and not over:
			var sec := maxi(0, ceili(prep))
			hud.text = "🍬  %d      BUILD  %d:%02d      Wave  %d" % [candy, int(sec / 60), sec % 60, wave]
		else:
			hud.text = "🍬  %d      Wave  %d      Walking  %d" % [candy, wave, alive]
	if bar and keep:
		bar.size.x = 280.0 * clampf(float(keep.hp) / float(keep.max_hp), 0.0, 1.0)
		bar.color = Color("FFB347") if keep.hp > 30 else Color("E24B4B")
	if gear and hunter:
		if hunter.build_on:
			var lines := "BUILD  "
			for i in hunter.names_build.size():
				var mark := ">" if i == hunter.build_i else " "
				var ic: String = hunter.icons_build[i] if i < hunter.icons_build.size() else "•"
				lines += "%s%d %s (%d)   " % [mark, i + 1, ic, hunter.build_cost[i]]
			gear.text = lines
		else:
			var held: String = hunter._held_name() if hunter.has_method("_held_name") else hunter.names_gun[hunter.gun]
			var extra := ""
			if hunter.pack and str(hunter.pack.equipped().get("kind", "")) == "gun":
				extra = "   %d/%d" % [int(hunter.pack.equipped().get("ammo", 0)), int(hunter.pack.equipped().get("mag", 0))]
			gear.text = "%s%s      E pack   1-9 hotbar   Y build" % [held, extra]


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	if c.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _spawn_loot(pos: Vector3, id: String) -> void:
	var loot = LootDrop.new()
	var count := 1
	if id == "ammo":
		count = 8
	elif id == "candy":
		count = 10
	loot.setup(PackData.make(id, count))
	loot.position = pos
	add_child(loot)


func _ground_y(p: Vector3) -> float:
	if not is_inside_tree():
		return 0.72
	var space := get_world_3d().direct_space_state
	if space == null:
		return 0.72
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, 48.0, p.z), Vector3(p.x, -8.0, p.z))
	q.collision_mask = 1
	var hit := space.intersect_ray(q)
	if hit:
		return float(hit.position.y)
	return 0.72


func _sit_box(xz: Vector3, size: Vector3, color: Color, coll: bool) -> void:
	var gy := _ground_y(xz)
	_box(Vector3(xz.x, gy + size.y * 0.5, xz.z), size, color, coll)


func _box(pos: Vector3, size: Vector3, color: Color, coll: bool, host: Node = null) -> void:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.material = _mat(color)
	b.use_collision = coll
	(host if host else self).add_child(b)


func _cyl(pos: Vector3, radius: float, height: float, color: Color, coll: bool, host: Node = null) -> void:
	var c := CSGCylinder3D.new()
	c.radius = radius
	c.height = height
	c.sides = 16
	c.position = pos
	c.material = _mat(color)
	c.use_collision = coll
	(host if host else self).add_child(c)


func _sphere(pos: Vector3, radius: float, color: Color, coll: bool, host: Node = null) -> void:
	var s := CSGSphere3D.new()
	s.radius = radius
	s.radial_segments = 14
	s.rings = 8
	s.position = pos
	s.material = _mat(color)
	s.use_collision = coll
	(host if host else self).add_child(s)
