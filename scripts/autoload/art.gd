extends Node

var _tex: Dictionary = {}
var font_title: Font
var font_body: Font
var font_emoji: Font


func _ready() -> void:
	# System fonts always render on Windows. Custom files are an upgrade.
	var body := SystemFont.new()
	body.font_names = PackedStringArray(["Segoe UI", "Arial", "Tahoma"])
	font_body = body
	var title := SystemFont.new()
	title.font_names = PackedStringArray(["Segoe UI Black", "Segoe UI", "Arial Black", "Arial"])
	font_title = title
	var ms_title: Font = load("res://assets/fonts/Montserrat-ExtraBold.ttf")
	var ms_body: Font = load("res://assets/fonts/Montserrat-Bold.ttf")
	if ms_title:
		font_title = ms_title
	if ms_body:
		font_body = ms_body
	elif ms_title:
		font_body = ms_title
	font_emoji = SystemFont.new()
	font_emoji.font_names = PackedStringArray(["Segoe UI Emoji", "Segoe UI Symbol", "Segoe UI", "Apple Color Emoji", "Noto Color Emoji"])
	_with_emoji(font_body)
	_with_emoji(font_title)
	var th := Theme.new()
	th.default_font = font_body
	th.default_font_size = 22
	th.set_font("font", "Button", font_body)
	th.set_font("font", "Label", font_body)
	th.set_font("font", "RichTextLabel", font_body)
	get_tree().root.theme = th
	soft_light()


func _with_emoji(f: Font) -> void:
	if f == null or font_emoji == null:
		return
	if not f.fallbacks.has(font_emoji):
		f.fallbacks.append(font_emoji)


func combat_scale(kind: String) -> float:
	match kind:
		"sling", "forge":
			return display_height(kind) / 118.0
		"titan":
			return display_height(kind) / 132.0
		_:
			return display_height(kind) / 76.0


func soft_light() -> Texture2D:
	if _tex.has("_light"):
		return _tex["_light"]
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	var c := Vector2(128, 128)
	for y in 256:
		for x in 256:
			var d := Vector2(x, y).distance_to(c) / 128.0
			var a := clampf(1.0 - d, 0.0, 1.0)
			a *= a
			img.set_pixel(x, y, Color(1, 1, 1, a))
	var t := ImageTexture.create_from_image(img)
	_tex["_light"] = t
	return t


func tex(id: String) -> Texture2D:
	if _tex.has(id):
		return _tex[id]
	var path := "res://assets/art/%s.png" % id
	if ResourceLoader.exists(path):
		var t: Texture2D = load(path)
		if t:
			_tex[id] = t
			return t
	_tex[id] = null
	return null


func actor_id(kind: String, pose: String = "idle") -> String:
	match kind:
		"sling", "titan", "forge":
			return "hero_%s_%s" % [kind, pose]
		"civilian":
			return "civilian"
		"dummy":
			return "dummy"
		"riptide":
			return "boss_riptide"
		"drain", "overload", "brownout", "gridlock":
			return "boss_drain"
		"drainling", "grabber", "bomber":
			return "enemy_drainling"
		"scraper", "elite_pulse":
			return "enemy_scraper"
		"drone", "turret":
			return "enemy_drone"
		"shieldbot":
			return "enemy_shieldbot"
		"leaper":
			return "enemy_leaper"
		"seeker":
			return "enemy_seeker"
		_:
			return "enemy_scraper"


func display_height(kind: String) -> float:
	match kind:
		"sling", "forge":
			return 268.0
		"titan":
			return 300.0
		"civilian":
			return 180.0
		"dummy":
			return 220.0
		"riptide", "drain", "overload", "gridlock", "brownout":
			return 340.0
		"elite_pulse", "shieldbot":
			return 180.0
		"drone", "turret":
			return 110.0
		_:
			return 150.0


func district_bg(id: String) -> String:
	match id:
		"docks":
			return "bg_docks"
		"grid":
			return "bg_grid"
		_:
			return "bg_midtown"


func ground_tex(id: String) -> String:
	match id:
		"docks":
			return "tex_docks"
		"grid":
			return "tex_grid"
		_:
			return "tex_rooftop"


func sprite(id: String, height: float = 0.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	s.texture = tex(id)
	if s.texture and height > 0.0:
		var th := float(s.texture.get_height())
		if th > 1.0:
			s.scale = Vector2.ONE * (height / th)
	s.centered = true
	return s


func tiled_rect(parent: Node, rect: Rect2, tex_id: String, z: int = 0, modulate: Color = Color.WHITE) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex(tex_id)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	s.centered = false
	s.position = rect.position
	s.z_index = z
	s.modulate = modulate
	if s.texture:
		s.scale = Vector2(rect.size.x / float(s.texture.get_width()), rect.size.y / float(s.texture.get_height()))
	parent.add_child(s)
	return s


func backdrop(parent: Node, tex_id: String, length: float, y: float = -120.0, motion: Vector2 = Vector2(0.18, 0.55)) -> void:
	var t := tex(tex_id)
	if t == null:
		return
	var pb := ParallaxBackground.new()
	parent.add_child(pb)
	var layer := ParallaxLayer.new()
	layer.motion_scale = motion
	var w := 1920.0
	var h := 1080.0
	var sc := h / float(t.get_height())
	w = float(t.get_width()) * sc
	layer.motion_mirroring = Vector2(w, 0)
	var s := Sprite2D.new()
	s.texture = t
	s.centered = false
	s.position = Vector2(-200, y)
	s.scale = Vector2(sc, sc)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	layer.add_child(s)
	pb.add_child(layer)
	# cover long levels with extra copies in case mirroring fails on some GPUs
	var extra := ParallaxLayer.new()
	extra.motion_scale = motion * Vector2(0.55, 1.0)
	extra.modulate = Color(1, 1, 1, 0.55)
	extra.motion_mirroring = Vector2(w * 1.4, 0)
	var s2 := Sprite2D.new()
	s2.texture = t
	s2.centered = false
	s2.position = Vector2(-100, y + 80)
	s2.scale = Vector2(sc * 1.15, sc * 0.85)
	s2.flip_h = true
	s2.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	extra.add_child(s2)
	pb.add_child(extra)
	var _len := length


var _pbr: Dictionary = {}


func surface(kind: String) -> StandardMaterial3D:
	if _pbr.has(kind):
		return _pbr[kind]
	var m: StandardMaterial3D
	match kind:
		"grass":
			m = _noise_pbr([Color("243818"), Color("3E5C28"), Color("5C7A38"), Color("2A401C"), Color("6A8844")], 0.55, 0.08, 7, 0.86, 0.0, 8.0)
		"dirt":
			m = _noise_pbr([Color("3A2C1C"), Color("4E3A26"), Color("6A4C32"), Color("2E2418")], 0.7, 0.11, 11, 0.9, 0.0, 7.0)
		"asphalt":
			m = _noise_pbr([Color("1A1C20"), Color("26282E"), Color("34363C"), Color("16181C")], 0.9, 0.14, 19, 0.42, 0.06, 4.5)
			m.clearcoat_enabled = true
			m.clearcoat = 0.62
			m.clearcoat_roughness = 0.16
		"walk":
			m = _noise_pbr([Color("4A4840"), Color("5E5C52"), Color("6E6C62"), Color("3E3C36")], 0.85, 0.09, 5, 0.68, 0.0, 5.5)
		"brick":
			m = _brick_pbr(Color("6A3A2C"), Color("8E5640"), Color("C4B49A"))
		"brick_dark":
			m = _brick_pbr(Color("3E302C"), Color("5C443C"), Color("9A8C78"))
		"brick_red":
			m = _brick_pbr(Color("6A2C1C"), Color("A04830"), Color("B4A48C"))
		"wood":
			m = _wood_pbr(Color("5A3C24"), Color("7A5834"), Color("2E1C12"))
		"plaster":
			m = _noise_pbr([Color("C8B89A"), Color("DDD0BA"), Color("E8DCC8"), Color("B4A488")], 0.72, 0.05, 21, 0.74, 0.0, 2.8)
		"rust":
			m = _noise_pbr([Color("4A2818"), Color("6A3A1C"), Color("8A4A28"), Color("32180E")], 0.8, 0.1, 8, 0.62, 0.42, 9.0)
		"metal":
			m = _noise_pbr([Color("3A4046"), Color("4E565E"), Color("6A727A"), Color("24282C")], 1.1, 0.07, 3, 0.28, 0.86, 3.2)
			m.clearcoat_enabled = true
			m.clearcoat = 0.4
			m.clearcoat_roughness = 0.22
			m.anisotropy_enabled = true
			m.anisotropy = 0.28
		"stone":
			m = _noise_pbr([Color("3A3C42"), Color("4C4E56"), Color("5E6068"), Color("32343A")], 0.75, 0.06, 3, 0.78, 0.02, 6.5)
		"roof":
			m = _noise_pbr([Color("241C16"), Color("3A2C22"), Color("4A382C"), Color("1A1410")], 0.8, 0.09, 17, 0.66, 0.08, 5.5)
		"bark":
			m = _wood_pbr(Color("241810"), Color("3A281C"), Color("100C0A"))
		"leaf":
			m = _noise_pbr([Color("1E3A1C"), Color("2E5228"), Color("3A6230"), Color("183216")], 0.62, 0.12, 13, 0.72, 0.0, 4.0)
			m.backlight_enabled = true
			m.backlight = Color("7CB85A")
			m.subsurf_scatter_enabled = true
			m.subsurf_scatter_strength = 0.16
		"leather":
			m = _noise_pbr([Color("3A281C"), Color("4E3824"), Color("624830"), Color("2A1C14")], 1.4, 0.1, 15, 0.55, 0.0, 3.5)
		"cloth":
			m = _noise_pbr([Color("2A2C28"), Color("3A3C36"), Color("32342E"), Color("22241E")], 1.6, 0.14, 23, 0.8, 0.0, 2.2)
		_:
			m = _noise_pbr([Color("5A5A5A"), Color("7A7A7A")], 0.8, 0.08, 1, 0.75, 0.0, 4.0)
	_pbr[kind] = m
	return m


func micro_normal() -> Texture2D:
	if _tex.has("_micro_n"):
		return _tex["_micro_n"]
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = 404
	noise.frequency = 0.085
	noise.fractal_octaves = 3
	var ntex := NoiseTexture2D.new()
	ntex.width = 512
	ntex.height = 512
	ntex.seamless = true
	ntex.as_normal_map = true
	ntex.bump_strength = 2.4
	ntex.noise = noise
	_tex["_micro_n"] = ntex
	return ntex


func skin(c: Color, wet: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = lerpf(0.62, 0.38, wet)
	m.metallic = 0.0
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.45
	m.subsurf_scatter_skin_mode = true
	return m


func glass(c: Color, energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.15
	m.roughness = 0.08
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.refraction_enabled = true
	m.refraction_scale = 0.02
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = energy
	return m


func _noise_pbr(ramp: Array, uv_scale: float, freq: float, seed_v: int, rough: float, metal: float, bump: float) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = seed_v
	noise.frequency = freq
	noise.fractal_octaves = 5
	noise.fractal_lacunarity = 2.15
	noise.fractal_gain = 0.52
	var tex := NoiseTexture2D.new()
	tex.width = 1024
	tex.height = 1024
	tex.seamless = true
	tex.noise = noise
	var grad := Gradient.new()
	grad.set_color(0, ramp[0])
	grad.set_color(1, ramp[ramp.size() - 1])
	for i in range(1, ramp.size() - 1):
		grad.add_point(float(i) / float(ramp.size() - 1), ramp[i])
	tex.color_ramp = grad
	var ntex := NoiseTexture2D.new()
	ntex.width = 1024
	ntex.height = 1024
	ntex.seamless = true
	ntex.as_normal_map = true
	ntex.bump_strength = bump
	ntex.noise = noise
	var rough_noise := FastNoiseLite.new()
	rough_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	rough_noise.seed = seed_v + 90
	rough_noise.frequency = freq * 1.7
	rough_noise.fractal_octaves = 3
	var rtex := NoiseTexture2D.new()
	rtex.width = 512
	rtex.height = 512
	rtex.seamless = true
	rtex.noise = rough_noise
	var rgrad := Gradient.new()
	rgrad.set_color(0, Color(0.72, 0.72, 0.72))
	rgrad.set_color(1, Color(1.0, 1.0, 1.0))
	rtex.color_ramp = rgrad
	var ao_noise := FastNoiseLite.new()
	ao_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	ao_noise.seed = seed_v + 17
	ao_noise.frequency = freq * 0.45
	ao_noise.fractal_octaves = 3
	var atex := NoiseTexture2D.new()
	atex.width = 512
	atex.height = 512
	atex.seamless = true
	atex.noise = ao_noise
	var agrad := Gradient.new()
	agrad.set_color(0, Color(0.62, 0.62, 0.62))
	agrad.set_color(1, Color(1.0, 1.0, 1.0))
	atex.color_ramp = agrad
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.roughness_texture = rtex
	m.roughness = rough
	m.metallic = metal
	m.metallic_specular = 0.55
	m.normal_enabled = true
	m.normal_texture = ntex
	m.normal_scale = clampf(bump * 0.1, 0.45, 1.15)
	m.ao_enabled = true
	m.ao_texture = atex
	m.ao_light_affect = 0.42
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	m.uv2_triplanar = true
	m.uv2_scale = Vector3(uv_scale * 4.5, uv_scale * 4.5, uv_scale * 4.5)
	m.detail_enabled = true
	m.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	m.detail_normal = micro_normal()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	return m


func _brick_pbr(dark: Color, light: Color, mortar: Color) -> StandardMaterial3D:
	var w := 512
	var h := 512
	var albedo := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var height := Image.create(w, h, false, Image.FORMAT_RF)
	var rough := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var ao := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var bw := 64.0
	var bh := 28.0
	var gap := 3.2
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	var noise := FastNoiseLite.new()
	noise.seed = 33
	noise.frequency = 0.02
	noise.fractal_octaves = 3
	for y in h:
		var row := int(floor(float(y) / bh))
		var off := 0.0 if row % 2 == 0 else bw * 0.5
		var brick_hue := rng.randf()
		for x in w:
			var lx := fmod(float(x) + off, bw)
			var ly := fmod(float(y), bh)
			if lx < 0.4:
				brick_hue = rng.randf()
			var mortar_px := lx < gap or ly < gap or lx > bw - 0.6 or ly > bh - 0.6
			var n := noise.get_noise_2d(float(x), float(y)) * 0.5 + 0.5
			var edge := minf(minf(lx, ly), minf(bw - lx, bh - ly)) / 4.0
			var col: Color
			var ht: float
			var rg: float
			if mortar_px:
				col = mortar.darkened(0.08 + n * 0.12)
				if n < 0.18:
					col = col.lerp(Color("3E5A32"), 0.55)
				ht = 0.18
				rg = 0.92
			else:
				col = dark.lerp(light, 0.2 + brick_hue * 0.45 + n * 0.2)
				col = col.darkened(clampf(0.22 - edge, 0.0, 0.22))
				ht = 0.68 + n * 0.22 + clampf(edge, 0.0, 0.12)
				rg = 0.72 + n * 0.16
			albedo.set_pixel(x, y, col)
			height.set_pixel(x, y, Color(ht, ht, ht))
			rough.set_pixel(x, y, Color(rg, rg, rg))
			var a := clampf(0.5 + ht * 0.55, 0.42, 1.0)
			ao.set_pixel(x, y, Color(a, a, a))
	return _finish_baked(albedo, height, rough, ao, 7.2, 0.84, 0.62, 1.05)


func _wood_pbr(a: Color, b: Color, dark: Color) -> StandardMaterial3D:
	var w := 512
	var h := 512
	var albedo := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var height := Image.create(w, h, false, Image.FORMAT_RF)
	var rough := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var ao := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 14
	noise.frequency = 0.02
	noise.fractal_octaves = 4
	for y in h:
		for x in w:
			var n := noise.get_noise_2d(float(x) * 0.28, float(y) * 1.6)
			var pore := noise.get_noise_2d(float(x) * 2.4, float(y) * 0.4)
			var ring := sin(float(x) * 0.09 + n * 7.0) * 0.5 + 0.5
			var streak := 0.85 + 0.15 * sin(float(y) * 0.35)
			var col := a.lerp(b, ring).lerp(dark, clampf(absf(n) * 0.65, 0.0, 0.4))
			col = col.darkened(clampf(-pore, 0.0, 0.12))
			col = Color(col.r * streak, col.g * streak, col.b * streak)
			albedo.set_pixel(x, y, col)
			var ht := 0.35 + ring * 0.5 + pore * 0.08
			height.set_pixel(x, y, Color(ht, 0, 0))
			var rg := clampf(0.62 + (1.0 - ring) * 0.22 + absf(pore) * 0.08, 0.45, 0.95)
			rough.set_pixel(x, y, Color(rg, rg, rg))
			var occ := clampf(0.58 + ht * 0.42, 0.45, 1.0)
			ao.set_pixel(x, y, Color(occ, occ, occ))
	return _finish_baked(albedo, height, rough, ao, 5.4, 0.72, 0.48, 0.8)


func _finish_baked(albedo: Image, height: Image, rough: Image, ao: Image, bump: float, rough_bias: float, uv_scale: float, normal_scale: float) -> StandardMaterial3D:
	albedo.generate_mipmaps()
	rough.generate_mipmaps()
	ao.generate_mipmaps()
	var ntex := _normal_tex(height, bump)
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(albedo)
	m.roughness_texture = ImageTexture.create_from_image(rough)
	m.roughness = rough_bias
	m.normal_enabled = true
	m.normal_texture = ntex
	m.normal_scale = normal_scale
	m.ao_enabled = true
	m.ao_texture = ImageTexture.create_from_image(ao)
	m.ao_light_affect = 0.5
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	m.uv2_triplanar = true
	m.uv2_scale = Vector3(uv_scale * 3.5, uv_scale * 3.5, uv_scale * 3.5)
	m.detail_enabled = true
	m.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	m.detail_normal = micro_normal()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	return m


func _normal_tex(height: Image, strength: float) -> ImageTexture:
	var w := height.get_width()
	var h := height.get_height()
	var nimg := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var l := height.get_pixel(posmod(x - 1, w), y).r
			var r := height.get_pixel(posmod(x + 1, w), y).r
			var u := height.get_pixel(x, posmod(y - 1, h)).r
			var d := height.get_pixel(x, posmod(y + 1, h)).r
			var vx := (l - r) * strength
			var vy := (u - d) * strength
			var vz := 1.0
			var ln := sqrt(vx * vx + vy * vy + vz * vz)
			nimg.set_pixel(x, y, Color(vx / ln * 0.5 + 0.5, vy / ln * 0.5 + 0.5, vz / ln * 0.5 + 0.5))
	nimg.generate_mipmaps()
	return ImageTexture.create_from_image(nimg)
