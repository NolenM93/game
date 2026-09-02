extends Node2D

func _ready() -> void:
	var def := {
		"id": "sandbox", "title": "Gym", "district": "midtown", "layout": "arena",
		"length": 2800, "weather": "clear", "features": ["swing", "smash", "fuel"],
		"waves": [{"at": 900, "e": [["scraper", 2], ["drone", 1]]}],
		"objectives": [], "dare": {}, "tokens": [], "comics": []
	}
	var b := LevelBuilder.new()
	add_child(b)
	b.build(def)
	var dummy := TrainingDummy.new()
	add_child(dummy)
	dummy.global_position = Vector2(400, 840)
	var hid := str(SaveManager.active.get("last_hero", "sling"))
	var hero: HeroBase
	match hid:
		"titan":
			hero = Titan.new()
		"forge":
			hero = Forge.new()
		_:
			hero = Sling.new()
	add_child(hero)
	hero.global_position = b.spawn_point()
	var l := Label.new()
	l.text = "SANDBOX  •  1/2/3 swap heroes  •  Start returns to title"
	l.position = Vector2(40, 20)
	l.z_index = 80
	l.add_theme_font_size_override("font_size", 24)
	add_child(l)
	set_meta("hero", hero)
	set_meta("spawn", b.spawn_point())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		Game.show_title()
	if event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_1:
				_swap("sling")
			KEY_2:
				_swap("titan")
			KEY_3:
				_swap("forge")


func _swap(id: String) -> void:
	var old: Node = get_meta("hero")
	var pos: Vector2 = old.global_position if old else get_meta("spawn")
	if old:
		old.queue_free()
	var hero: HeroBase
	match id:
		"titan":
			hero = Titan.new()
		"forge":
			hero = Forge.new()
		_:
			hero = Sling.new()
	add_child(hero)
	hero.global_position = pos
	SaveManager.active["last_hero"] = id
	set_meta("hero", hero)
