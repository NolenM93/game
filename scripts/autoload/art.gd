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
