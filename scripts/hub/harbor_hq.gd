extends Node2D

var hero: HeroBase
var prompt: Label
var status: Label
var spot := ""
var spots: Dictionary = {}
var opened := false


func _ready() -> void:
	Game.in_hub = true
	AudioDirector.play_music("hub")
	WorldProps.static_rect(self, Rect2(-200, 820, 3200, 260), Color.BLACK, [], "", false)
	WorldProps.static_rect(self, Rect2(-80, 200, 60, 700), Color.BLACK, [], "", false)
	WorldProps.static_rect(self, Rect2(2900, 200, 60, 700), Color.BLACK, [], "", false)
	var wall := Sprite2D.new()
	wall.texture = Art.tex("bg_hub")
	wall.centered = false
	wall.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if wall.texture:
		var sc := 1100.0 / float(wall.texture.get_height())
		wall.scale = Vector2(sc, sc)
		var wall2 := wall.duplicate()
		wall2.position = Vector2(-200 + wall.texture.get_width() * sc, -40)
		wall2.flip_h = true
		add_child(wall2)
	wall.position = Vector2(-200, -40)
	wall.z_index = -20
	add_child(wall)
	_spot("story", Vector2(420, 780), "Story Board")
	_spot("side", Vector2(860, 780), "Side Board")
	_spot("trial", Vector2(1300, 780), "Hero Trials")
	_spot("challenge", Vector2(1740, 780), "Challenges")
	_spot("bench", Vector2(2180, 780), "Upgrade Bench")
	_spot("closet", Vector2(620, 780), "Costume Closet")
	_spot("gallery", Vector2(1480, 780), "Comic Gallery")
	_spot("dummy", Vector2(2500, 780), "Training Dummy")
	_spot("mira", Vector2(1100, 780), "Mira")
	_spot("coach", Vector2(2320, 780), "Coach")
	_spot("spark", Vector2(980, 780), "Spark-Bot")
	var dummy := TrainingDummy.new()
	add_child(dummy)
	dummy.global_position = Vector2(2500, 780)
	var hid := str(SaveManager.active.get("last_hero", "sling"))
	if not SaveManager.is_hero_unlocked(hid):
		hid = "sling"
	match hid:
		"titan":
			hero = Titan.new()
		"forge":
			hero = Forge.new()
		_:
			hero = Sling.new()
	add_child(hero)
	hero.global_position = Vector2(280, 760)
	var hud := CanvasLayer.new()
	hud.layer = 20
	add_child(hud)
	var hud_root := Control.new()
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(hud_root)
	status = UIKit.label(hud_root, _status(), Vector2(48, 28), 26, Color("F4EFE2"))
	UIKit.label(hud_root, "HARBOR HQ", Vector2(48, 64), 42, Color("F4C542"), true)
	prompt = UIKit.label(hud_root, "", Vector2(0, 0), 32, Color("F4C542"))
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_talk_bubble(Vector2(1080, 430), "Flashlights are on me. Heroes are on you.")
	if SaveManager.overload_ready() and not SaveManager.active.get("overload_beaten", false):
		_talk_bubble(Vector2(820, 430), "A gold stamp appeared on the side board...")


func _status() -> String:
	return "Spark %d   •   Story %d/12   •   Tokens %d/15   •   %s" % [
		int(SaveManager.active.get("spark", 0)),
		_count_story(),
		SaveManager.active.get("tokens", []).size(),
		"NG+" if SaveManager.active.get("ng_plus") else "Hero difficulty: " + Settings.difficulty
	]


func _count_story() -> int:
	var n := 0
	for id in Catalog.story_ids():
		if id in SaveManager.active.get("cleared", []):
			n += 1
	return n


func _spot(id: String, pos: Vector2, title: String) -> void:
	var a := Area2D.new()
	a.position = pos
	a.collision_layer = 128
	a.collision_mask = 2
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(120, 160)
	cs.shape = r
	a.add_child(cs)
	var glow := Sprite2D.new()
	glow.texture = Art.soft_light()
	glow.modulate = Color(0.96, 0.77, 0.26, 0.42)
	glow.scale = Vector2(0.55, 0.18)
	glow.position = Vector2(0, 36)
	a.add_child(glow)
	var l := Label.new()
	l.text = title
	l.position = Vector2(-90, -70)
	l.size = Vector2(180, 36)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", Art.font_body)
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", Color("F4EFE2"))
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.12, 0.9))
	l.add_theme_constant_override("outline_size", 4)
	a.add_child(l)
	a.body_entered.connect(func(b):
		if b is HeroBase:
			spot = id
	)
	a.body_exited.connect(func(b):
		if b is HeroBase and spot == id:
			spot = ""
	)
	add_child(a)
	spots[id] = title


func _talk_bubble(pos: Vector2, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", Art.font_body)
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", Color("F4EFE2"))
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.12, 0.85))
	l.add_theme_constant_override("outline_size", 4)
	add_child(l)


func _physics_process(_delta: float) -> void:
	Game.in_hub = true
	Game.hub_interact_armed = spot != "" and not opened


func _process(_delta: float) -> void:
	if status:
		status.text = _status()
	if prompt == null or hero == null:
		return
	if spot != "":
		prompt.text = "A  •  " + str(spots.get(spot, spot))
		var cam := get_viewport().get_canvas_transform()
		var p: Vector2 = cam * (hero.global_position + Vector2(0, -200))
		prompt.position = p + Vector2(-160, 0)
	else:
		prompt.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if opened or spot == "":
		return
	if event.is_action_pressed("jump") or event.is_action_pressed("ui_confirm"):
		get_viewport().set_input_as_handled()
		_open(spot)


func _open(id: String) -> void:
	if opened:
		return
	AudioDirector.play("ui")
	match id:
		"story":
			opened = true
			Game.show_board("story")
		"side":
			opened = true
			Game.show_board("side")
		"trial":
			opened = true
			Game.show_board("trial")
		"challenge":
			opened = true
			Game.show_board("challenge")
		"bench":
			opened = true
			Game.show_upgrades()
		"closet":
			opened = true
			Game.show_closet()
		"gallery":
			opened = true
			Game.show_gallery()
		"dummy":
			VFX.text_pop(self, hero.global_position, "Hit the dummy!", Color("F4C542"))
		"mira":
			VFX.text_pop(self, hero.global_position, "Bring me panels. I'll tape them up.", Color("C090FF"))
		"coach":
			VFX.text_pop(self, hero.global_position, "Punch dummy. Not donuts.", Color("E89B2D"))
		"spark":
			VFX.text_pop(self, hero.global_position, "BEEP. You are doing great.", Color("3B7CFF"))
