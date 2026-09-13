extends Node2D

var hero: HeroBase
var prompt: Label
var status: Label
var spot := ""
var spots: Dictionary = {}
var opened := false
var room_w := 1920.0
var floor_y := 860.0


func _ready() -> void:
	Game.in_hub = true
	AudioDirector.play_music("hub")
	var wall := Sprite2D.new()
	wall.texture = Art.tex("bg_hub")
	wall.centered = false
	wall.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if wall.texture:
		var sc := 1920.0 / float(wall.texture.get_width())
		wall.scale = Vector2(sc, sc)
		room_w = float(wall.texture.get_width()) * sc
		var painted_h := float(wall.texture.get_height()) * sc
		wall.position = Vector2(0, 1080.0 - painted_h)
		floor_y = 1080.0 - painted_h * 0.18
	wall.z_index = -20
	add_child(wall)
	WorldProps.static_rect(self, Rect2(-40, floor_y, room_w + 80, 280), Color.BLACK, [], "", false)
	WorldProps.static_rect(self, Rect2(-40, 0, 40, 1080), Color.BLACK, [], "", false)
	WorldProps.static_rect(self, Rect2(room_w, 0, 40, 1080), Color.BLACK, [], "", false)
	_spot("board", Vector2(room_w * 0.34, floor_y - 10), "Mission Board")
	_spot("bench", Vector2(room_w * 0.46, floor_y - 10), "Upgrade Bench")
	_spot("closet", Vector2(room_w * 0.58, floor_y - 10), "Costume Closet")
	_spot("dummy", Vector2(room_w * 0.68, floor_y - 10), "Training Dummy")
	_spot("gallery", Vector2(room_w * 0.84, floor_y - 10), "Comic Shelf")
	var dummy := TrainingDummy.new()
	add_child(dummy)
	dummy.global_position = Vector2(room_w * 0.68, floor_y - 8)
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
	hero.global_position = Vector2(220, floor_y - 20)
	if hero.cam:
		hero.cam.hub_lock = Vector2(room_w * 0.5, 540)
	var hud := CanvasLayer.new()
	hud.layer = 20
	add_child(hud)
	var hud_root := Control.new()
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(hud_root)
	status = UIKit.label(hud_root, _status(), Vector2(48, 36), 22, Color("F3E6D0"))
	prompt = UIKit.label(hud_root, "", Vector2(560, 980), 32, UIKit.GOLD, true)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.size = Vector2(800, 48)


func _status() -> String:
	return "Spark %d     Story %d / 12     Tokens %d / 15%s" % [
		int(SaveManager.active.get("spark", 0)),
		_count_story(),
		SaveManager.active.get("tokens", []).size(),
		"     NG+" if SaveManager.active.get("ng_plus") else ""
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
	r.size = Vector2(150, 200)
	cs.shape = r
	a.add_child(cs)
	var glow := Sprite2D.new()
	glow.name = "Glow"
	glow.texture = Art.soft_light()
	glow.modulate = Color(0.91, 0.77, 0.35, 0.0)
	glow.scale = Vector2(0.62, 0.16)
	glow.position = Vector2(0, 28)
	a.add_child(glow)
	a.body_entered.connect(func(b):
		if b is HeroBase:
			spot = id
	)
	a.body_exited.connect(func(b):
		if b is HeroBase and spot == id:
			spot = ""
	)
	add_child(a)
	spots[id] = {"title": title, "glow": glow}


func _physics_process(_delta: float) -> void:
	Game.in_hub = true
	Game.hub_interact_armed = spot != "" and not opened
	for id in spots:
		var g: Sprite2D = spots[id]["glow"]
		var on := id == spot
		g.modulate.a = move_toward(g.modulate.a, 0.55 if on else 0.0, 0.1)


func _process(_delta: float) -> void:
	if status:
		status.text = _status()
	if prompt == null:
		return
	if spot != "":
		prompt.text = "A   •   " + str(spots[spot]["title"])
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
		"board":
			opened = true
			Game.show_board("story")
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
			VFX.text_pop(self, hero.global_position, "Hit the dummy!", Color("E8C45A"))
