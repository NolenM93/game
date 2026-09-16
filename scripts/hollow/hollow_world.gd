extends Node3D

const Hunter = preload("res://scripts/hollow/hunter.gd")
const Zed = preload("res://scripts/hollow/zed.gd")
const Grave = preload("res://scripts/hollow/grave.gd")
const Keep = preload("res://scripts/hollow/lantern_keep.gd")
const Build = preload("res://scripts/hollow/buildable.gd")
const FX = preload("res://scripts/hollow/hollow_fx.gd")
const PackData = preload("res://scripts/hollow/pack.gd")
const LootDrop = preload("res://scripts/hollow/loot.gd")
const Wheel = preload("res://scripts/hollow/mystery_wheel.gd")
const Town = preload("res://scripts/hollow/town.gd")
const PowerDrop = preload("res://scripts/hollow/powerup.gd")

const SAVE_PATH := "user://hollow_best.cfg"
const GRID := 1.85
const FIRST_PREP := 40.0
const NEXT_PREP := 34.0

var hunter
var keep
var graves: Array = []
var candy := 70
var coins := 500
var wave := 0
var alive := 0
var kills := 0
var to_spawn: Array = []
var spawn_t := 0.0
var prep := FIRST_PREP
var fighting := false
var over := false
var over_t := 0.0
var won := false
var started := false
var best_wave := 0
var cells := {}
var hud: Label
var hearts: Label
var gear: Label
var next_lbl: Label
var lantern_lbl: Label
var hint: Label
var banner: Label
var count_lbl: Label
var bar: ColorRect
var bar_bg: ColorRect
var card: Control
var card_title: Label
var card_body: Label
var card_prompt: Label
var hint_t := 18.0
var banner_t := 0.0
var last_tick := -1
var env: Environment
var fireflies: Array[MeshInstance3D] = []
var bats: Array[Dictionary] = []
var mist: Array[MeshInstance3D] = []
var fog_base := 0.012
var hill_pads: Array[Vector3] = []
var zone_rings: Array[MeshInstance3D] = []
var ground_mat: StandardMaterial3D
var stone_mat: StandardMaterial3D
var sky_mat: ProceduralSkyMaterial
var sun: DirectionalLight3D
var fill: DirectionalLight3D
var moon_root: Node3D
var star_meshes: Array[MeshInstance3D] = []
var rain: CPUParticles3D
var day_clock := 0.78
var lightning_t := 8.0
var weather := 1
var weather_t := 32.0
var last_weather := -1
var lightning_flash := 0.0
var wheel
var lamp_posts: Array[OmniLight3D] = []
var town
var power_on := false
var town_open := false
var insta_t := 0.0
var double_t := 0.0
var round_lbl: Label
var buff_lbl: Label
var points_lbl: Label


func _ready() -> void:
	InputSetup.ensure()
	_load_best()
	AudioDirector.play_music("hollow")
	Game.in_combat = false
	ground_mat = _noise_material([Color("1A2417"), Color("28371F"), Color("3A4E2C")], 0.05, 0.02, 7)
	stone_mat = _noise_material([Color("34363C"), Color("484A52"), Color("5A5C64")], 0.12, 0.05, 3)
	_sky()
	_ground()
	_hills()
	_yard()
	_town()
	_woods()
	_bats()
	_mist()
	_keep()
	_graves()
	_hunter()
	_wheel()
	_weather()
	_build_zone()
	_hud()
	Input.joy_connection_changed.connect(func(_id, _on): _set_control_hint())
	hunter.locked = true
	_show_start_card()


# --- state helpers -------------------------------------------------------------

func lantern_frac() -> float:
	if keep and keep.get("hp") != null and keep.get("max_hp"):
		return float(keep.hp) / float(keep.max_hp)
	return 1.0


func snap_build(p: Vector3) -> Vector3:
	var x := snappedf(p.x, GRID)
	var z := snappedf(p.z, GRID)
	return Vector3(x, _ground_y(Vector3(x, 0, z)), z)


func can_build(p: Vector3, cost: int) -> bool:
	if over or not started or candy < cost:
		return false
	var s := snap_build(p)
	var r := Vector2(s.x, s.z).length()
	if r < 3.4 or r > 24.0:
		return false
	if cells.has(_key(s)):
		return false
	for g in graves:
		if g is Node3D and Vector2(g.global_position.x - s.x, g.global_position.z - s.z).length() < 1.45:
			return false
	if hunter and Vector2(hunter.global_position.x - s.x, hunter.global_position.z - s.z).length() < 1.15:
		return false
	return true


func try_build(kind: String, p: Vector3, cost: int) -> bool:
	var s := snap_build(p)
	if not can_build(s, cost):
		AudioDirector.play("ui", 0.6)
		return false
	candy -= cost
	var b = Build.new()
	b.setup(kind)
	b.position = s
	if hunter and hunter.has_method("build_yaw"):
		b.rotation.y = hunter.build_yaw()
	cells[_key(s)] = b
	b.tree_exiting.connect(func():
		cells.erase(_key(s))
	)
	add_child(b)
	AudioDirector.play_at("build", s, randf_range(0.95, 1.08))
	FX.wood(self, s + Vector3(0, 0.4, 0))
	FX.ring(self, s, Color(0.8, 1.0, 0.6, 0.6), 1.2, 0.25)
	_refresh()
	return true


func show_build_zone(on: bool) -> void:
	for r in zone_rings:
		r.visible = on


func add_candy(n: int, pos: Vector3 = Vector3.ZERO) -> void:
	candy += n
	if pos != Vector3.ZERO:
		FX.float_text(self, pos, "+%d 🍬" % n, Color("FFB347"), 40)
	_refresh()


func add_coins(n: int, pos: Vector3 = Vector3.ZERO) -> void:
	coins += n
	if pos != Vector3.ZERO:
		FX.float_text(self, pos + Vector3(0, 0.5, 0), "+%d 🪙" % n, Color("FFE27A"), 34)
	_refresh()


func spend_coins(n: int) -> bool:
	if coins < n:
		return false
	coins -= n
	_refresh()
	return true


func try_wheel() -> bool:
	return try_interact()


func try_interact() -> bool:
	if wheel and wheel.try_spin():
		return true
	if town:
		for s in town.stations:
			if s and s.has_method("try_use") and s.try_use():
				return true
	return false


func _open_town() -> void:
	town_open = true
	_show("TOWN OPEN")
	AudioDirector.play("win", 0.85)


func _on_power() -> void:
	power_on = true
	if town and town.has_method("set_power"):
		town.set_power(true)
	_show("POWER ON")
	if env:
		env.ambient_light_energy = maxf(env.ambient_light_energy, 0.7)


func apply_powerup(kind: String, pos: Vector3) -> void:
	match kind:
		"maxammo":
			if hunter and hunter.has_method("fill_all_ammo"):
				hunter.fill_all_ammo()
			_show("MAX AMMO")
		"instakill":
			insta_t = 22.0
			_show("INSTA-KILL")
		"double":
			double_t = 22.0
			_show("DOUBLE POINTS")
		"nuke":
			_nuke(pos)
		"carpenter":
			if keep and keep.has_method("heal"):
				keep.heal(40)
			_show("CARPENTER")
	AudioDirector.play("win", 1.1)
	FX.ring(self, pos, Color(1.0, 0.85, 0.4, 0.85), 3.2, 0.45)
	_refresh()


func _nuke(pos: Vector3) -> void:
	_show("NUKE")
	FX.flash(self, pos, Color("FF8A3A"), 14.0, 18.0, 0.6)
	var n := 0
	for z in get_tree().get_nodes_in_group("zed"):
		if z == null or bool(z.get("dead")):
			continue
		z.dead = true
		z.collision_layer = 0
		n += 1
		kills += 1
		alive = maxi(0, alive - 1)
		z.queue_free()
	add_coins(400 + n * 10, pos)


func player_down() -> void:
	var chew := 12
	if hunter and hunter.has_method("has_perk") and hunter.has_perk("revive"):
		chew = 4
	if keep and keep.has_method("chew"):
		keep.chew(chew)
	_show("DOWN! The lantern flickered...")
	AudioDirector.play("alarm", 0.8)


func _key(p: Vector3) -> String:
	return "%d,%d" % [int(round(p.x / GRID)), int(round(p.z / GRID))]


func _load_best() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK:
		best_wave = int(cf.get_value("hollow", "best_wave", 0))


func _save_best() -> void:
	var cf := ConfigFile.new()
	cf.load(SAVE_PATH)
	cf.set_value("hollow", "best_wave", best_wave)
	cf.save(SAVE_PATH)


# --- environment ---------------------------------------------------------------

func _sky() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sky_mat = sm
	sm.sky_top_color = Color("0A0E1E")
	sm.sky_horizon_color = Color("3A2A44")
	sm.sky_curve = 0.09
	sm.ground_bottom_color = Color("08080C")
	sm.ground_horizon_color = Color("1A1420")
	sm.sun_angle_max = 4.0
	sky.sky_material = sm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("2E3C66")
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.15
	env.ssao_enabled = true
	env.ssao_intensity = 1.3
	env.ssao_radius = 1.2
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.15
	env.glow_hdr_threshold = 1.0
	env.fog_enabled = true
	env.fog_light_color = Color("2A3048")
	env.fog_density = 0.0035
	env.fog_aerial_perspective = 0.6
	env.fog_sky_affect = 0.25
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = fog_base
	env.volumetric_fog_albedo = Color("7A7898")
	env.volumetric_fog_emission = Color("0E0A16")
	env.volumetric_fog_emission_energy = 0.4
	env.volumetric_fog_length = 120.0
	env.volumetric_fog_sky_affect = 0.15
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, 38, 0)
	sun.light_color = Color("9FB6E8")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sun)
	fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-42, 38 + 180, 0)
	fill.light_color = Color("3C5A6E")
	fill.light_energy = 0.28
	fill.shadow_enabled = false
	fill.light_specular = 0.0
	add_child(fill)
	_moon()
	_stars()


func _moon() -> void:
	moon_root = Node3D.new()
	add_child(moon_root)
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
	moon_root.add_child(moon)
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
		moon_root.add_child(c)
	var glow := OmniLight3D.new()
	glow.position = Vector3(-70, 90, -60)
	glow.light_color = Color("E8DCC0")
	glow.light_energy = 8.0
	glow.omni_range = 80.0
	moon_root.add_child(glow)


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
		star_meshes.append(mi)


## Triplanar noise material: breaks up the big flat CSG surfaces without any art assets.
func _noise_material(ramp: Array, uv_scale: float, freq: float, seed_v: int) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = seed_v
	noise.frequency = freq
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.2
	var tex := NoiseTexture2D.new()
	tex.width = 512
	tex.height = 512
	tex.seamless = true
	tex.noise = noise
	var grad := Gradient.new()
	grad.set_color(0, ramp[0])
	grad.set_color(1, ramp[ramp.size() - 1])
	for i in range(1, ramp.size() - 1):
		grad.add_point(float(i) / float(ramp.size() - 1), ramp[i])
	tex.color_ramp = grad
	var ntex := NoiseTexture2D.new()
	ntex.width = 256
	ntex.height = 256
	ntex.seamless = true
	ntex.as_normal_map = true
	ntex.bump_strength = 6.0
	ntex.noise = noise
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	m.roughness = 0.95
	m.normal_enabled = true
	m.normal_texture = ntex
	m.normal_scale = 0.55
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m


func _ground() -> void:
	_cyl(Vector3(0, 0.2, 0), 78.0, 0.9, Color("1A2016"), true, null, ground_mat)
	_cyl(Vector3(0, 0.58, 0), 62.0, 0.28, Color("243022"), true, null, ground_mat)
	_cyl(Vector3(0, 0.72, 0), 6.4, 0.08, Color("4A4E55"), false, null, stone_mat)
	# Worn dirt paths from the graves to the lantern; decoration only. Built from a few
	# staggered, slightly skewed strips so they read as trodden earth rather than planks.
	var dirt_mat := _noise_material([Color("2E2519"), Color("3E3222"), Color("4A3D2C")], 0.09, 0.04, 11)
	for i in 4:
		var a := TAU * (i * 5) / 18.0
		for j in 3:
			var path := CSGBox3D.new()
			var w: float = [2.4, 1.7, 1.2][j]
			var len: float = [11.5, 13.5, 15.0][j]
			var r: float = [11.0, 12.5, 13.0][j]
			var skew: float = [0.0, 0.06, -0.05][j]
			path.size = Vector3(w, 0.03, len)
			path.position = Vector3(cos(a) * r, 0.74 + 0.004 * j, sin(a) * r)
			path.rotation.y = -a + PI * 0.5 + skew
			path.material = dirt_mat
			path.use_collision = false
			add_child(path)


func _hills() -> void:
	var cottages := [
		{"xz": Vector3(28, 0, 14), "loot": ["ammo", "heart", "ammo"]},
		{"xz": Vector3(-30, 0, -10), "loot": ["ammo", "candy", "oil"]},
		{"xz": Vector3(16, 0, -32), "loot": ["ammo", "candy", "heart"]},
		{"xz": Vector3(-20, 0, 30), "loot": ["ammo", "ammo", "oil"]},
		{"xz": Vector3(36, 0, -22), "loot": ["ammo", "candy", "ammo"]},
		{"xz": Vector3(-38, 0, 18), "loot": ["ammo", "heart", "candy"]},
	]
	for h in cottages:
		_shed(_plot(h["xz"]), h["loot"])
	_chapel(_plot(Vector3(2, 0, -38), 10.6, 4.4))
	_shed(_plot(Vector3(12.5, 0, -34.0)), ["oil", "ammo", "candy"])
	for i in 14:
		var a := TAU * i / 14.0 + 0.11
		# Buried so they read as distant hills, not floating orbs.
		_sphere(Vector3(cos(a) * 92.0, -10.0, sin(a) * 92.0), randf_range(18.0, 26.0), Color("12160F"), false)


func _plot(xz: Vector3, wide: float = 6.2, deep: float = 5.4) -> Vector3:
	var gy := 0.72
	# Tops sit at lawn height so there is no curb to climb.
	_box(Vector3(xz.x, gy - 1.7, xz.z), Vector3(wide, 3.4, deep), Color("3A3E46"), true, null, stone_mat)
	_box(Vector3(xz.x, gy - 0.5, xz.z), Vector3(wide + 1.2, 1.0, deep + 1.2), Color("1E281C"), true, null, ground_mat)
	var top := Vector3(xz.x, gy, xz.z)
	hill_pads.append(top)
	return top


func _chapel(pad: Vector3) -> void:
	_box(pad + Vector3(0, 3.35, 0), Vector3(9.0, 7.0, 2.2), Color("2A2430"), true)
	_box(pad + Vector3(-3.2, 7.35, 0), Vector3(2.8, 2.6, 1.6), Color("1A1520"), true)
	_box(pad + Vector3(3.2, 7.35, 0), Vector3(2.8, 2.6, 1.6), Color("1A1520"), true)
	_box(pad + Vector3(0, 9.55, 0), Vector3(1.4, 3.2, 1.4), Color("3A2A22"), false)
	var pane := _lit(Color("7A5AC8", 0.55), 1.6)
	_box(pad + Vector3(-1.8, 3.2, 1.14), Vector3(1.1, 1.6, 0.08), Color("7A5AC8", 0.55), false, null, pane)
	_box(pad + Vector3(1.8, 3.2, 1.14), Vector3(1.1, 1.6, 0.08), Color("7A5AC8", 0.55), false, null, pane)
	var glass := OmniLight3D.new()
	glass.position = pad + Vector3(0, 4.5, 1.6)
	glass.light_color = Color("7A5AC8")
	glass.light_energy = 2.2
	glass.omni_range = 12.0
	add_child(glass)
	lamp_posts.append(glass)


func _shed(pad: Vector3, loot: Array) -> void:
	var n := Node3D.new()
	n.position = pad
	var toward := Vector3(-pad.x, 0, -pad.z)
	if toward.length() > 0.2:
		n.rotation.y = atan2(toward.x, toward.z)
	add_child(n)
	_box(Vector3(0, 0.04, 0), Vector3(4.6, 0.08, 3.8), Color("3A2A1C"), true, n)
	_box(Vector3(0, 1.45, -1.82), Vector3(4.6, 2.5, 0.18), Color("4A3424"), true, n)
	_box(Vector3(-2.22, 1.45, 0), Vector3(0.18, 2.5, 3.8), Color("4A3424"), true, n)
	_box(Vector3(2.22, 1.45, 0), Vector3(0.18, 2.5, 3.8), Color("4A3424"), true, n)
	_box(Vector3(-1.5, 1.45, 1.82), Vector3(1.5, 2.5, 0.18), Color("4A3424"), true, n)
	_box(Vector3(1.5, 1.45, 1.82), Vector3(1.5, 2.5, 0.18), Color("4A3424"), true, n)
	_box(Vector3(-0.82, 2.15, 1.82), Vector3(0.16, 1.1, 0.22), Color("2A1C14"), false, n)
	_box(Vector3(0.82, 2.15, 1.82), Vector3(0.16, 1.1, 0.22), Color("2A1C14"), false, n)
	_box(Vector3(0, 2.8, 0), Vector3(5.0, 0.16, 4.2), Color("2A1C14"), true, n)
	_box(Vector3(0, 3.15, 0), Vector3(3.2, 0.18, 3.0), Color("3A2418"), false, n)
	_cyl(Vector3(-1.9, 1.4, -1.5), 0.12, 2.6, Color("2A1C14"), false, n)
	_cyl(Vector3(1.9, 1.4, -1.5), 0.12, 2.6, Color("2A1C14"), false, n)
	var pane := _lit(Color("FFB347", 0.5), 1.1)
	_box(Vector3(-2.23, 1.7, -0.45), Vector3(0.06, 0.7, 0.7), Color("FFB347", 0.5), false, n, pane)
	_box(Vector3(2.23, 1.7, -0.45), Vector3(0.06, 0.7, 0.7), Color("FFB347", 0.5), false, n, pane)
	_box(Vector3(-1.1, 1.75, -1.84), Vector3(0.7, 0.7, 0.06), Color("FFB347", 0.5), false, n, pane)
	_box(Vector3(0, 0.03, 2.45), Vector3(2.6, 0.06, 1.3), Color("3A2A1C"), false, n)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 2.2, 0)
	lamp.light_color = Color("FF8A3A")
	lamp.light_energy = 1.6
	lamp.omni_range = 8.0
	n.add_child(lamp)
	lamp_posts.append(lamp)
	_pumpkin(n.to_global(Vector3(2.9, 0.0, 2.8)))
	_box(Vector3(-2.9, 0.45, 0.8), Vector3(0.9, 0.7, 0.9), Color("6A3A22"), true, n)
	var spots := [Vector3(0.0, 0.22, 2.55), Vector3(0.85, 0.22, 2.65), Vector3(-0.85, 0.22, 2.65)]
	for i in loot.size():
		var id := str(loot[i])
		var local: Vector3 = spots[i % spots.size()]
		_spawn_loot(n.to_global(local), id)


func _town() -> void:
	town = Town.new()
	add_child(town)
	town.setup(self)


func _in_street(p: Vector3) -> bool:
	if p.x > 8.0 and p.x < 72.0 and absf(p.z) < 7.5:
		return true
	if p.x > 30.0 and p.x < 72.0 and absf(p.z) < 22.0:
		return true
	return false


func _yard() -> void:
	# Broken cemetery fence around the inner yard, not a cage.
	for i in 18:
		if i % 5 == 0:
			continue
		var a := TAU * i / 18.0
		var p := Vector3(cos(a) * 21.0, 0, sin(a) * 21.0)
		var gy := _ground_y(p)
		_box(Vector3(p.x, gy + 1.1, p.z), Vector3(0.16, 2.2, 0.16), Color("2A2E34"), true)
		_sphere(Vector3(p.x, gy + 2.24, p.z), 0.14, Color("3A3E44"), false)
		if i % 2 == 0:
			var rail := CSGBox3D.new()
			rail.size = Vector3(0.08, 0.08, 3.4)
			rail.position = Vector3(p.x, gy + 1.95, p.z)
			rail.rotation.y = -a
			rail.material = _mat(Color("3A3E44"))
			rail.use_collision = false
			add_child(rail)
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


func _build_zone() -> void:
	for spec in [[23.85, 24.15, Color(1.0, 0.72, 0.3, 0.42)], [3.25, 3.5, Color(1.0, 0.45, 0.3, 0.45)]]:
		var mi := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = spec[0]
		tm.outer_radius = spec[1]
		tm.rings = 96
		tm.ring_segments = 6
		mi.mesh = tm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = spec[2]
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.material_override = m
		mi.position = Vector3(0, 0.78, 0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		add_child(mi)
		zone_rings.append(mi)


func _woods() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for i in 70:
		var a := rng.randf() * TAU
		var r := rng.randf_range(28.0, 68.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if Vector2(p.x, p.z).length() < 20.0:
			continue
		if _in_street(p):
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
		var p := Vector3(cos(a) * 26.0, 0, sin(a) * 26.0)
		if _in_street(p):
			continue
		_dead_tree(p)


func _pumpkin(at: Vector3) -> void:
	var gy := _ground_y(at)
	var pos := Vector3(at.x, gy + 0.4, at.z)
	_sphere(pos, 0.42, Color("E07020"), false)
	_cyl(pos + Vector3(0, 0.42, 0), 0.06, 0.22, Color("3A8A3A"), false)
	var face := Node3D.new()
	face.position = pos
	face.rotation.y = atan2(-at.x, -at.z)
	add_child(face)
	_box(Vector3(-0.11, 0.08, 0.36), Vector3(0.09, 0.07, 0.05), Color("1A1520"), false, face)
	_box(Vector3(0.11, 0.08, 0.36), Vector3(0.09, 0.07, 0.05), Color("1A1520"), false, face)
	_box(Vector3(0, -0.06, 0.38), Vector3(0.2, 0.04, 0.04), Color("1A1520"), false, face)
	var glow := OmniLight3D.new()
	glow.position = pos + Vector3(0, 0.1, 0.2)
	glow.light_color = Color("FF9A30")
	glow.light_energy = 0.55
	glow.omni_range = 2.4
	glow.shadow_enabled = false
	add_child(glow)


func _lamp_post(at: Vector3) -> void:
	var gy := _ground_y(at)
	_cyl(Vector3(at.x, gy + 1.15, at.z), 0.07, 2.3, Color("2A1C14"), true)
	_box(Vector3(at.x, gy + 2.28, at.z), Vector3(0.36, 0.08, 0.36), Color("3A2418"), false)
	_box(Vector3(at.x, gy + 2.5, at.z), Vector3(0.24, 0.36, 0.24), Color("FFB347", 0.55), false)
	_box(Vector3(at.x, gy + 2.7, at.z), Vector3(0.3, 0.06, 0.3), Color("3A2418"), false)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(at.x, gy + 2.5, at.z)
	lamp.light_color = Color("FF9A48")
	lamp.light_energy = 2.2
	lamp.omni_range = 8.0
	add_child(lamp)
	lamp_posts.append(lamp)


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
		m.albedo_color = Color(0.45, 0.42, 0.55, 0.08)
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
	# Canopies are seen from above, so they need enough value to read as foliage under moonlight.
	_sphere(pos + Vector3(0, 1.55, 0), 1.8, Color("2C4A32"), false)
	_sphere(pos + Vector3(0.9, 1.25, -0.5), 1.1, Color("223C28"), false)
	_sphere(pos + Vector3(-0.7, 1.35, 0.4), 0.95, Color("264430"), false)


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
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	for r in rings.size():
		for i in counts[r]:
			var a := TAU * float(i) / float(counts[r]) + r * 0.17
			var pos := Vector3(cos(a) * rings[r], 0, sin(a) * rings[r])
			if _in_street(pos):
				continue
			var g = Grave.new()
			g.variant = rng.randi_range(0, 2)
			g.position = Vector3(pos.x, _ground_y(pos), pos.z)
			g.rotation.y = a + PI
			g.burst.connect(_spawn_at.bind(g))
			add_child(g)
			graves.append(g)
	for spec in [
		Vector3(42, 0, -18), Vector3(54, 0, -18), Vector3(42, 0, 18), Vector3(54, 0, 18),
		Vector3(48, 0, -22), Vector3(48, 0, 22), Vector3(66, 0, 4), Vector3(66, 0, -4)
	]:
		var g = Grave.new()
		g.in_town = true
		g.variant = rng.randi_range(0, 2)
		g.position = Vector3(spec.x, _ground_y(spec), spec.z)
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


func _wheel() -> void:
	wheel = Wheel.new()
	wheel.world = self
	var gy := _ground_y(Vector3(4.6, 0, 5.2))
	_box(Vector3(4.6, gy - 0.55, 5.2), Vector3(2.4, 1.1, 2.4), Color("3A3E46"), true, null, stone_mat)
	wheel.position = Vector3(4.6, gy, 5.2)
	add_child(wheel)


func _weather() -> void:
	rain = CPUParticles3D.new()
	rain.emitting = false
	rain.amount = 700
	rain.lifetime = 0.7
	rain.explosiveness = 0.0
	rain.randomness = 0.4
	rain.local_coords = false
	rain.direction = Vector3(0.18, -1.0, 0.04)
	rain.spread = 6.0
	rain.gravity = Vector3(0, -28, 0)
	rain.initial_velocity_min = 12.0
	rain.initial_velocity_max = 18.0
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(18.0, 1.0, 18.0)
	var streak := BoxMesh.new()
	streak.size = Vector3(0.025, 0.42, 0.025)
	rain.mesh = streak
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(0.75, 0.82, 0.95, 0.45)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.disable_fog = true
	rain.material_override = rm
	add_child(rain)


# --- HUD -----------------------------------------------------------------------

func _label(root: Control, pos: Vector2, size: int, color: Color, title_font: bool = false) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	var f: Font = Art.font_title if title_font else Art.font_body
	if f:
		l.add_theme_font_override("font", f)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08, 0.95))
	l.add_theme_constant_override("outline_size", maxi(4, int(size * 0.28)))
	root.add_child(l)
	return l


func _hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	_label(root, Vector2(48, 22), 28, Color("FFB347"), true).text = "LANTERN HOLLOW"
	points_lbl = _label(root, Vector2(48, 62), 42, Color("FFE27A"), true)
	buff_lbl = _label(root, Vector2(48, 112), 20, Color("E24B4B"))
	round_lbl = Label.new()
	round_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	round_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	round_lbl.offset_left = -360
	round_lbl.offset_right = -40
	round_lbl.offset_top = 24
	round_lbl.offset_bottom = 80
	round_lbl.add_theme_font_size_override("font_size", 40)
	if Art.font_title:
		round_lbl.add_theme_font_override("font", Art.font_title)
	round_lbl.add_theme_color_override("font_color", Color("E24B4B"))
	round_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.02, 0.95))
	round_lbl.add_theme_constant_override("outline_size", 10)
	root.add_child(round_lbl)
	hearts = _label(root, Vector2(48, 9000), 18, Color("E56BA0"))
	lantern_lbl = _label(root, Vector2(48, 9000), 16, Color("FFB347"))
	bar_bg = ColorRect.new()
	bar_bg.visible = false
	root.add_child(bar_bg)
	bar = ColorRect.new()
	bar.visible = false
	root.add_child(bar)
	hud = _label(root, Vector2(48, 9000), 18, Color("D4E0C8"))
	next_lbl = Label.new()
	next_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	next_lbl.offset_left = -420
	next_lbl.offset_right = 420
	next_lbl.offset_top = -202
	next_lbl.offset_bottom = -174
	next_lbl.add_theme_font_size_override("font_size", 22)
	if Art.font_body:
		next_lbl.add_theme_font_override("font", Art.font_body)
	next_lbl.add_theme_color_override("font_color", Color("FFE27A"))
	next_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08, 0.95))
	next_lbl.add_theme_constant_override("outline_size", 8)
	root.add_child(next_lbl)
	gear = _label(root, Vector2(48, 9000), 18, Color("FFE27A"))
	hint = Label.new()
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.offset_left = 0
	hint.offset_top = -248
	hint.offset_bottom = -216
	hint.offset_right = 1920
	hint.add_theme_font_size_override("font_size", 18)
	if Art.font_body:
		hint.add_theme_font_override("font", Art.font_body)
	hint.add_theme_color_override("font_color", Color(0.85, 0.88, 0.8, 0.9))
	hint.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08, 0.9))
	hint.add_theme_constant_override("outline_size", 6)
	root.add_child(hint)
	_set_control_hint()
	banner = Label.new()
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.offset_left = -560
	banner.offset_right = 560
	banner.offset_top = -260
	banner.offset_bottom = -100
	banner.pivot_offset = Vector2(560, 80)
	banner.add_theme_font_size_override("font_size", 64)
	if Art.font_title:
		banner.add_theme_font_override("font", Art.font_title)
	banner.add_theme_color_override("font_color", Color("FFB347"))
	banner.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.1, 0.95))
	banner.add_theme_constant_override("outline_size", 14)
	banner.modulate.a = 0.0
	root.add_child(banner)
	count_lbl = Label.new()
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_lbl.set_anchors_preset(Control.PRESET_CENTER)
	count_lbl.offset_left = -200
	count_lbl.offset_right = 200
	count_lbl.offset_top = -420
	count_lbl.offset_bottom = -260
	count_lbl.pivot_offset = Vector2(200, 80)
	count_lbl.add_theme_font_size_override("font_size", 96)
	if Art.font_title:
		count_lbl.add_theme_font_override("font", Art.font_title)
	count_lbl.add_theme_color_override("font_color", Color("FFF6D8"))
	count_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.1, 0.95))
	count_lbl.add_theme_constant_override("outline_size", 16)
	count_lbl.visible = false
	root.add_child(count_lbl)
	_card(root)
	_refresh()


func _card(root: Control) -> void:
	card = Control.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.visible = false
	root.add_child(card)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(dim)
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -430
	panel.offset_right = 430
	panel.offset_top = -300
	panel.offset_bottom = 300
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.08, 0.11, 0.94)
	sb.border_color = Color("FFB347")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(18)
	sb.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", sb)
	card.add_child(panel)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 34
	col.offset_right = -34
	col.offset_top = 26
	col.offset_bottom = -26
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)
	card_title = Label.new()
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title.add_theme_font_size_override("font_size", 54)
	if Art.font_title:
		card_title.add_theme_font_override("font", Art.font_title)
	card_title.add_theme_color_override("font_color", Color("FFB347"))
	card_title.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08, 0.95))
	card_title.add_theme_constant_override("outline_size", 12)
	col.add_child(card_title)
	card_body = Label.new()
	card_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_body.add_theme_font_size_override("font_size", 22)
	if Art.font_body:
		card_body.add_theme_font_override("font", Art.font_body)
	card_body.add_theme_color_override("font_color", Color("E8E2D0"))
	col.add_child(card_body)
	card_prompt = Label.new()
	card_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_prompt.add_theme_font_size_override("font_size", 26)
	if Art.font_body:
		card_prompt.add_theme_font_override("font", Art.font_body)
	card_prompt.add_theme_color_override("font_color", Color("FFE27A"))
	col.add_child(card_prompt)


func _show_start_card() -> void:
	if card == null:
		return
	card.visible = true
	card_title.text = "LANTERN HOLLOW"
	var controls := ""
	if InputSetup.pad_connected():
		controls = "LS move  ·  RS look  ·  RT shoot  ·  B bat swing\nY build  ·  LB / RB items  ·  X reload  ·  View inventory\nE buy / Santa's sack / power  ·  L3 call round  ·  RS click FP"
	else:
		controls = "WASD move  ·  Mouse aim  ·  Click shoot  ·  V bat\nTab build  ·  1-9 hotbar  ·  R reload  ·  E inventory or buy\nEnter call round  ·  F first-person  ·  Scroll zoom"
	var best := ""
	if best_wave > 0:
		best = "\n\nBest run: wave %d" % best_wave
	card_body.text = "Zombies hunt you. Nothing else. Kill them for points, close the round, spend coins in town.\n\nClear debris to open Hollow Street. Hit the power, buy wall guns, drink perks, dip Santa's sack for a random prize.\nCandy still builds traps. Coins buy everything in town.\n\n" + controls + best
	card_prompt.text = "Click or press A to begin"


func _show_over_card() -> void:
	if card == null:
		return
	card.visible = true
	card_title.text = "THE LANTERN WENT OUT"
	card_body.text = "You held the hollow for %d wave%s and popped %d zombies.\n\nBest run: wave %d" % [wave, "" if wave == 1 else "s", kills, best_wave]
	card_prompt.text = "Click or press A to try again"


func _start() -> void:
	started = true
	card.visible = false
	if hunter:
		hunter.locked = false
		hunter._shoot_held = true
		if hunter.has_method("_sync_mouse"):
			hunter._sync_mouse()
	hint_t = 18.0
	if hint:
		hint.modulate.a = 1.0
	_show("HOLD THE LANTERN")
	AudioDirector.play("confirm", 1.1)


func _process(delta: float) -> void:
	_tick_sky(delta)
	_tick_weather(delta)
	if insta_t > 0.0:
		insta_t = maxf(0.0, insta_t - delta)
		if insta_t == 0.0:
			_show("INSTA-KILL OVER")
	if double_t > 0.0:
		double_t = maxf(0.0, double_t - delta)
		if double_t == 0.0:
			_show("DOUBLE POINTS OVER")
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
		var gust := 1.0 + (0.8 if weather == 1 else 0.0) + (1.8 if weather == 2 else 0.0)
		mist[i].position.x += sin(t * 0.15 + i) * delta * 0.6 * gust
		mist[i].position.z += cos(t * 0.12 + i) * delta * 0.5 * gust
	if not started:
		if Input.is_action_just_pressed("shoot") or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_confirm") or Input.is_action_just_pressed("build_mode"):
			_start()
		return
	if over:
		over_t += delta
		return
	if not fighting:
		if Input.is_action_just_pressed("call_wave") and prep > 3.2:
			prep = 3.2
			_show("HERE THEY COME")
			AudioDirector.play("alarm", 0.7)
		prep -= delta
		var sec := ceili(prep)
		if sec <= 5 and sec >= 1:
			count_lbl.visible = true
			if sec != last_tick:
				last_tick = sec
				count_lbl.text = str(sec)
				count_lbl.scale = Vector2(1.35, 1.35)
				var tw := create_tween()
				tw.tween_property(count_lbl, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				AudioDirector.play("ui", 0.8 + 0.06 * (5 - sec))
		else:
			count_lbl.visible = false
		if prep <= 0.0:
			_begin_wave()
	else:
		count_lbl.visible = false
		spawn_t -= delta
		if spawn_t <= 0.0 and to_spawn.size() > 0:
			_wake_next()
			spawn_t = _spawn_gap(wave)
		if to_spawn.is_empty() and alive <= 0:
			_wave_clear()
	_refresh()


func _wave_clear() -> void:
	fighting = false
	Game.in_combat = false
	prep = NEXT_PREP
	last_tick = -1
	add_candy(8 + wave * 2, keep.global_position + Vector3(0, 2.2, 0) if keep else Vector3.ZERO)
	add_coins(400 + wave * 100, keep.global_position + Vector3(0, 2.8, 0) if keep else Vector3.ZERO)
	if keep and keep.has_method("heal"):
		keep.heal(15)
	if wave > best_wave:
		best_wave = wave
		_save_best()
	if env:
		env.volumetric_fog_density = clampf(fog_base + wave * 0.0015, fog_base, 0.028)
	if wave == 8 and not won:
		won = true
		_show("THE HOLLOW GOES QUIET... keep going")
		AudioDirector.play("win")
	else:
		_show("ROUND %d CLEAR" % wave)
		AudioDirector.play("confirm")
	_refresh()


func _begin_wave() -> void:
	wave += 1
	fighting = true
	Game.in_combat = true
	to_spawn = _roster(wave)
	alive = 0
	spawn_t = 1.15
	if hunter and hunter.has_method("shake"):
		hunter.shake(0.25)
	var title := "ROUND  %d" % wave
	if wave == 5:
		title = "THE MAYOR WALKS"
	elif wave == 8:
		title = "HORDE NIGHT"
	_show(title)
	AudioDirector.play("boss" if wave == 5 else "alarm", 0.85)
	_refresh()


func _roster(w: int) -> Array:
	var r: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 1701 + w * 97
	# Wave 1 is a long trickle of shamblers. Count climbs every round and caps so late
	# hordes stay dense without melting the frame rate.
	var n := mini(12 + w * 4, 60)
	for i in n:
		if w >= 5 and i == 0:
			r.append("mayor")
		elif w >= 3 and i % 7 == 0:
			r.append("lunk")
		elif w >= 2 and i % 4 == 0:
			r.append("skel" if rng.randf() < 0.4 else "runner")
		else:
			r.append("skel" if rng.randf() < 0.48 else "shambler")
	return r


func _spawn_gap(w: int) -> float:
	# ~2 s between graves on wave 1, tightening to 0.3 s once speed has hit its cap.
	var t := clampf(float(maxi(w, 1) - 1) / 11.0, 0.0, 1.0)
	return lerpf(2.0, 0.3, t)


func _preview(w: int) -> String:
	var counts := {}
	for k in _roster(w):
		counts[k] = int(counts.get(k, 0)) + 1
	var parts := PackedStringArray()
	for k in ["shambler", "skel", "runner", "lunk", "mayor"]:
		if not counts.has(k):
			continue
		var n: int = counts[k]
		match k:
			"shambler":
				parts.append("%d Shambler%s" % [n, "" if n == 1 else "s"])
			"skel":
				parts.append("%d Skeleton%s" % [n, "" if n == 1 else "s"])
			"runner":
				parts.append("%d Runner%s" % [n, "" if n == 1 else "s"])
			"lunk":
				parts.append("%d Lunk%s" % [n, "" if n == 1 else "s"])
			"mayor":
				parts.append("THE MAYOR")
	return "  ·  ".join(parts)


func _wake_next() -> void:
	if to_spawn.is_empty() or graves.is_empty():
		return
	var kind: String = to_spawn.pop_front()
	var pool: Array = []
	for g in graves:
		if g == null:
			continue
		if bool(g.get("in_town")) and not town_open:
			continue
		pool.append(g)
	if pool.is_empty():
		pool = graves
	var g = pool[randi() % pool.size()]
	if g.has_method("wake"):
		g.wake(kind)


func _spawn_at(kind: String, g: Node3D) -> void:
	if over:
		return
	var z = Zed.new()
	z.setup(kind, keep, hunter, wave)
	z.position = g.global_position + Vector3(0, 0.2, 0.7)
	z.popped.connect(_on_pop)
	add_child(z)
	alive += 1
	FX.goo(self, z.global_position)
	AudioDirector.play_at("splat", z.global_position, randf_range(0.6, 0.8))
	_refresh()


func _on_pop(kind: String, pos: Vector3, head: bool = false, style: String = "") -> void:
	alive = maxi(0, alive - 1)
	kills += 1
	var pay := 3
	if kind == "runner":
		pay = 2
	elif kind == "skel":
		pay = 4
	elif kind == "lunk":
		pay = 6
	elif kind == "mayor":
		pay = 15
	add_candy(pay, pos)
	var bits := 60
	if kind == "runner":
		bits = 50
	elif kind == "skel":
		bits = 70
	elif kind == "lunk":
		bits = 80
	elif kind == "mayor":
		bits = 250
	if head:
		bits += 50
	if style == "bat":
		bits = 130
	if double_t > 0.0:
		bits *= 2
	add_coins(bits, pos)
	if randf() < 0.12 and kind != "mayor":
		_drop_power(pos)
	_refresh()


func _drop_power(pos: Vector3) -> void:
	var roll := randf()
	var id := "maxammo"
	if roll < 0.18:
		id = "nuke"
	elif roll < 0.36:
		id = "instakill"
	elif roll < 0.58:
		id = "double"
	elif roll < 0.72:
		id = "carpenter"
	var drop = PowerDrop.new()
	drop.setup(id)
	drop.world = self
	drop.position = pos + Vector3(0, 0.4, 0)
	add_child(drop)


func _on_ruined() -> void:
	over = true
	over_t = 0.0
	Game.in_combat = false
	if wave > best_wave:
		best_wave = wave
		_save_best()
	if hunter:
		hunter.locked = true
		hunter.shake(0.8)
		if hunter.has_method("_sync_mouse"):
			hunter._sync_mouse()
	_show("THE LANTERN WENT OUT")
	count_lbl.visible = false
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_callback(_show_over_card)


func _unhandled_input(event: InputEvent) -> void:
	if over and over_t > 1.8 and (event.is_action_pressed("ui_confirm") or event.is_action_pressed("jump") or event.is_action_pressed("shoot") or event.is_action_pressed("pause")):
		get_tree().reload_current_scene()


func _set_control_hint() -> void:
	if hint == null:
		return
	if InputSetup.pad_connected():
		hint.text = "LS move   RS look   RT shoot   B bat   Y build   E buy / inventory   X reload   L3 round"
	else:
		hint.text = "WASD move   Mouse aim   Click shoot   1-9 hotbar   E buy / inventory   Tab build   Enter round   F first-person"


func _show(text: String) -> void:
	if banner:
		banner.text = text
		banner.modulate.a = 1.0
		banner.scale = Vector2(1.18, 1.18)
		var tw := create_tween()
		tw.tween_property(banner, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	banner_t = 2.4


func _refresh() -> void:
	if points_lbl:
		points_lbl.text = "%d" % coins
	if round_lbl:
		if not started:
			round_lbl.text = ""
		elif fighting:
			round_lbl.text = "ROUND %d" % wave
		else:
			round_lbl.text = "ROUND %d" % maxi(wave, 1)
	if buff_lbl:
		var bits: PackedStringArray = []
		if insta_t > 0.0:
			bits.append("💀 INSTA")
		if double_t > 0.0:
			bits.append("x2 POINTS")
		if hunter and hunter.has_method("perk_line"):
			var extra: String = hunter.perk_line()
			if extra != "":
				bits.append(extra)
		buff_lbl.text = "   ".join(bits)
	if next_lbl:
		var prompt := _interact_prompt()
		if prompt != "":
			next_lbl.text = prompt
		elif hunter and hunter.build_on:
			next_lbl.text = "BUILD  %s  (%d 🍬)" % [hunter.names_build[hunter.build_i], hunter.build_cost[hunter.build_i]]
		elif not fighting and not over and started:
			next_lbl.text = _preview(wave + 1)
		else:
			next_lbl.text = ""
	if hunter and hunter.pack_ui and hunter.pack_ui.has_method("refresh_hud"):
		hunter.pack_ui.refresh_hud()


func _interact_prompt() -> String:
	if over:
		return ""
	if wheel and wheel.near:
		if wheel.spinning:
			return ""
		return "E  Santa's Sack  ·  %d 🪙" % int(wheel.COST)
	if town:
		for s in town.stations:
			if s and bool(s.near):
				if s.has_method("prompt"):
					return str(s.prompt())
	return ""


# --- primitives ---------------------------------------------------------------

func _tick_sky(delta: float) -> void:
	# Full day in ~3.5 minutes. 0 = midnight, 0.5 = noon.
	day_clock = fmod(day_clock + delta / 210.0, 1.0)
	var elev := -cos(day_clock * TAU)
	var night := clampf((-elev + 0.15) / 0.55, 0.0, 1.0)
	var dusk := clampf(1.0 - absf(elev) * 2.2, 0.0, 1.0)
	var overcast := 0.0
	if weather == 1:
		overcast = 0.4
	elif weather == 2:
		overcast = 0.7
	lightning_flash = maxf(0.0, lightning_flash - delta * 7.0)
	if sun:
		sun.rotation_degrees = Vector3(-elev * 72.0, 38.0, 0.0)
		if elev > 0.08:
			sun.light_color = Color("E8D2A8").lerp(Color("FFB070"), dusk).lerp(Color("6A7080"), overcast)
			sun.light_energy = (0.55 + elev * 1.15) * (1.0 - overcast * 0.65) + lightning_flash * 2.4
		else:
			sun.light_color = Color("9FB6E8").lerp(Color("4A5060"), overcast)
			sun.light_energy = (0.35 + (1.0 - night) * 0.4) * (1.0 - overcast * 0.4) + lightning_flash * 2.8
	if fill:
		fill.light_energy = 0.12 + (1.0 - night) * 0.22 * (1.0 - overcast * 0.5)
		fill.light_color = Color("3C5A6E").lerp(Color("C8B090"), 1.0 - night)
	if sky_mat:
		sky_mat.sky_top_color = Color("87A0C8").lerp(Color("0A0E1E"), night).lerp(Color("C45A40"), dusk * 0.45).lerp(Color("2A3040"), overcast)
		sky_mat.sky_horizon_color = Color("C8B090").lerp(Color("3A2A44"), night).lerp(Color("E07040"), dusk * 0.7).lerp(Color("4A5060"), overcast)
		sky_mat.ground_horizon_color = Color("4A4038").lerp(Color("1A1420"), night)
		sky_mat.ground_bottom_color = Color("1A1814").lerp(Color("08080C"), night)
		sky_mat.sky_energy_multiplier = lerpf(1.05, 0.42, maxf(night * 0.5, overcast))
	if env:
		env.ambient_light_color = Color("8A9AB8").lerp(Color("2E3C66"), night)
		env.ambient_light_energy = lerpf(0.95, 0.48, night) * (1.0 - overcast * 0.25) + lightning_flash * 1.6
		env.fog_light_color = Color("A8B0C4").lerp(Color("2A3048"), night)
		env.tonemap_exposure = lerpf(1.12, 0.98, night)
	if moon_root:
		moon_root.visible = night > 0.28
		moon_root.rotation_degrees = Vector3(elev * 55.0, -28.0, 0.0)
	for s in star_meshes:
		s.visible = night > 0.45 and overcast < 0.55
	for i in fireflies.size():
		if is_instance_valid(fireflies[i]):
			fireflies[i].visible = night > 0.28
	var lamp_e := lerpf(0.45, 2.4, night) + lightning_flash * 0.8
	for l in lamp_posts:
		if is_instance_valid(l):
			l.light_energy = lamp_e


func _tick_weather(delta: float) -> void:
	weather_t -= delta
	if weather_t <= 0.0:
		weather = 0 if weather != 0 else (1 if randf() < 0.55 else 2)
		weather_t = randf_range(28.0, 70.0) if weather == 0 else randf_range(18.0, 40.0)
	if weather != last_weather:
		last_weather = weather
		if rain:
			var amt := 0.45 if weather == 1 else 1.0
			rain.amount = int(280 + 720 * amt)
			rain.emitting = weather != 0
			rain.initial_velocity_min = 12.0 + 8.0 * amt
			rain.initial_velocity_max = 18.0 + 10.0 * amt
		if started:
			if weather == 1:
				_show("DRIZZLE")
			elif weather == 2:
				_show("STORM")
	var rain_amt := 0.0
	if weather == 1:
		rain_amt = 0.45
	elif weather == 2:
		rain_amt = 1.0
	if rain and hunter:
		rain.global_position = hunter.global_position + Vector3(0, 9.0, 0)
		rain.direction = Vector3(0.22 + sin(Time.get_ticks_msec() * 0.0004) * 0.12, -1.0, 0.05)
	if env:
		var extra := 0.004 * rain_amt
		env.volumetric_fog_density = fog_base + extra + (0.004 if day_clock < 0.2 or day_clock > 0.8 else 0.0)
	lightning_t -= delta
	if weather == 2 and lightning_t <= 0.0:
		lightning_t = randf_range(6.0, 16.0)
		_lightning()
	elif weather != 2:
		lightning_t = 8.0


func _lightning() -> void:
	lightning_flash = 1.0
	AudioDirector.play("whoom", randf_range(0.35, 0.5))
	var tw := create_tween()
	tw.tween_interval(0.12)
	tw.tween_callback(func():
		lightning_flash = 0.35
	)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	if c.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _lit(c: Color, energy: float = 1.2) -> StandardMaterial3D:
	var m := _mat(c)
	m.emission_enabled = true
	m.emission = Color(c.r, c.g, c.b)
	m.emission_energy_multiplier = energy
	return m


func _spawn_loot(pos: Vector3, id: String) -> void:
	var loot = LootDrop.new()
	var count := 1
	if id == "ammo":
		count = 8
	elif id == "candy":
		count = 10
	elif id == "heart" or id == "oil":
		count = 1
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


func _box(pos: Vector3, size: Vector3, color: Color, coll: bool, host: Node = null, mat: Material = null) -> void:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.material = mat if mat else _mat(color)
	b.use_collision = coll
	(host if host else self).add_child(b)


func _cyl(pos: Vector3, radius: float, height: float, color: Color, coll: bool, host: Node = null, mat: Material = null) -> void:
	var c := CSGCylinder3D.new()
	c.radius = radius
	c.height = height
	c.sides = 16 if radius < 10.0 else 48
	c.position = pos
	c.material = mat if mat else _mat(color)
	c.use_collision = coll
	(host if host else self).add_child(c)


func _sphere(pos: Vector3, radius: float, color: Color, coll: bool, host: Node = null, mat: Material = null) -> void:
	var s := CSGSphere3D.new()
	s.radius = radius
	s.radial_segments = 14 if radius < 10.0 else 28
	s.rings = 8 if radius < 10.0 else 14
	s.position = pos
	s.material = mat if mat else _mat(color)
	s.use_collision = coll
	(host if host else self).add_child(s)
