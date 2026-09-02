extends Node

var world: Node2D
var ui: CanvasLayer
var in_combat := false
var in_hub := false
var hub_interact_armed := false
var challenge_mods: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputSetup.ensure()
	world = Node2D.new()
	world.name = "WorldHost"
	add_child(world)
	ui = CanvasLayer.new()
	ui.name = "UIHost"
	ui.layer = 60
	add_child(ui)
	show_title()


func _process(delta: float) -> void:
	if SaveManager.slot_index >= 0:
		SaveManager.active["playtime"] = float(SaveManager.active.get("playtime", 0.0)) + delta


func consume_hub_interact() -> bool:
	return in_hub and hub_interact_armed


func _wipe() -> void:
	get_tree().paused = false
	in_hub = false
	in_combat = false
	challenge_mods = {}
	for c in world.get_children():
		c.queue_free()
	for c in ui.get_children():
		c.queue_free()


func show_title() -> void:
	_wipe()
	AudioDirector.play_music("title")
	ui.add_child((load("res://scripts/ui/title_screen.gd") as GDScript).new())


func show_slots(new_game: bool) -> void:
	call_deferred("_show_slots_now", new_game)


func _show_slots_now(new_game: bool) -> void:
	_wipe()
	var s = (load("res://scripts/ui/slot_select.gd") as GDScript).new()
	ui.add_child(s)
	s.setup(new_game)


func show_hub() -> void:
	call_deferred("_show_hub_now")


func _show_hub_now() -> void:
	_wipe()
	SaveManager.save_now()
	world.add_child((load("res://scripts/hub/harbor_hq.gd") as GDScript).new())


func show_board(kind: String) -> void:
	call_deferred("_show_board_now", kind)


func _show_board_now(kind: String) -> void:
	_wipe()
	var b = (load("res://scripts/ui/board_menu.gd") as GDScript).new()
	ui.add_child(b)
	b.setup(kind)


func show_hero_select(mission: Dictionary) -> void:
	call_deferred("_show_hero_now", mission)


func _show_hero_now(mission: Dictionary) -> void:
	_wipe()
	var h = (load("res://scripts/ui/hero_select.gd") as GDScript).new()
	ui.add_child(h)
	h.setup(mission)


func start_mission(def: Dictionary, hero_id: String) -> void:
	call_deferred("_start_mission_now", def, hero_id)


func _start_mission_now(def: Dictionary, hero_id: String) -> void:
	_wipe()
	if def.is_empty():
		_show_hub_now()
		return
	var m: MissionRunner = (load("res://scripts/mission/mission_runner.gd") as GDScript).new()
	world.add_child(m)
	m.setup(def, hero_id)


func show_results(res: Dictionary) -> void:
	call_deferred("_show_results_now", res)


func _show_results_now(res: Dictionary) -> void:
	for c in ui.get_children():
		c.queue_free()
	var r = (load("res://scripts/ui/results_screen.gd") as GDScript).new()
	ui.add_child(r)
	r.setup(res)


func show_credits(res: Dictionary) -> void:
	call_deferred("_show_credits_now", res)


func _show_credits_now(res: Dictionary) -> void:
	_wipe()
	var c = (load("res://scripts/ui/credits_screen.gd") as GDScript).new()
	ui.add_child(c)
	c.setup(res)


func show_sandbox() -> void:
	call_deferred("_show_sandbox_now")


func _show_sandbox_now() -> void:
	_wipe()
	if SaveManager.slot_index < 0:
		SaveManager.use_slot(0, true)
	world.add_child((load("res://scripts/world/sandbox.gd") as GDScript).new())


func show_upgrades() -> void:
	call_deferred("_show_upgrades_now")


func _show_upgrades_now() -> void:
	_wipe()
	ui.add_child((load("res://scripts/ui/upgrade_menu.gd") as GDScript).new())


func show_closet() -> void:
	call_deferred("_show_closet_now")


func _show_closet_now() -> void:
	_wipe()
	ui.add_child((load("res://scripts/ui/closet_menu.gd") as GDScript).new())


func show_gallery() -> void:
	call_deferred("_show_gallery_now")


func _show_gallery_now() -> void:
	_wipe()
	ui.add_child((load("res://scripts/ui/gallery_menu.gd") as GDScript).new())


func open_options(host: Node = null) -> void:
	var o = (load("res://scripts/ui/options_menu.gd") as GDScript).new()
	ui.add_child(o)
	o.setup(host)
