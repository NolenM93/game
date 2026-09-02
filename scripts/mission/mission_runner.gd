class_name MissionRunner
extends Node2D

signal finished(result: Dictionary)

var def: Dictionary = {}
var hero_id := "sling"
var builder: LevelBuilder
var hero: HeroBase
var hud: Control
var pause_ui: Control
var tut: Control
var started_msec := 0
var paused := false
var done := false
var damage_taken := 0
var continues := 0
var restore_next := 0
var survive_left := 0.0
var defend_left := 0.0
var time_limit := 0.0
var elapsed := 0.0
var obj_done: Dictionary = {}
var comic_over: Control


func setup(p_def: Dictionary, p_hero: String) -> void:
	def = p_def
	hero_id = p_hero
	add_to_group("mission_runner")
	Game.challenge_mods = def.get("modifiers", {})
	builder = LevelBuilder.new()
	add_child(builder)
	builder.build(def)
	match hero_id:
		"titan":
			hero = Titan.new()
		"forge":
			hero = Forge.new()
		_:
			hero = Sling.new()
	add_child(hero)
	hero.global_position = builder.spawn_point()
	if hero.cam:
		hero.cam.limit_right = int(float(def.get("length", 4000))) + 400
		hero.cam.limit_bottom = 1400
	hero.died.connect(_on_died)
	hero.hp_changed.connect(_on_hp)
	hero.tutorial.connect(_tut)
	started_msec = Time.get_ticks_msec()
	for o in def.get("objectives", []):
		if o.get("type") == "survive":
			survive_left = float(o.get("time", 15))
		if o.get("type") == "defend":
			defend_left = 18.0 + 6.0 * float(o.get("waves", 2))
	time_limit = float(def.get("modifiers", {}).get("time_limit", 0.0))
	_hud()
	var cs := str(def.get("comic_start", ""))
	if cs != "" and not cs in SaveManager.active.get("comics_shown", []):
		_comic(cs)
	AudioDirector.play_music(str(def.get("district", "midtown")))
	if def.get("boss", "") != "":
		AudioDirector.play_music("boss")


func _hud() -> void:
	hud = (load("res://scripts/ui/hud.gd") as GDScript).new()
	Game.ui.add_child(hud)
	hud.setup(self)
	pause_ui = (load("res://scripts/ui/pause_menu.gd") as GDScript).new()
	Game.ui.add_child(pause_ui)
	pause_ui.visible = false
	pause_ui.setup(self)
	tut = (load("res://scripts/ui/tutorial_prompt.gd") as GDScript).new()
	Game.ui.add_child(tut)


func _process(delta: float) -> void:
	if done:
		return
	if Input.is_action_just_pressed("pause"):
		toggle_pause()
	if paused:
		return
	elapsed += delta
	if time_limit > 0.0 and elapsed > time_limit:
		_fail("Time's up!")
		return
	if survive_left > 0.0:
		survive_left -= delta
	if defend_left > 0.0:
		defend_left -= delta
	Game.in_combat = _living_enemies() > 0
	if builder.van:
		var dist := hero.global_position.distance_to(builder.van.global_position)
		if dist > 980.0:
			_fail("The van got away!")
			return
		if builder.van.global_position.x > def.get("length", 4000) - 500:
			builder.van.done = true
	_check_objectives()
	if hud and hud.has_method("refresh"):
		hud.refresh()


func toggle_pause() -> void:
	paused = not paused
	pause_ui.visible = paused
	get_tree().paused = paused
	pause_ui.process_mode = Node.PROCESS_MODE_ALWAYS


func can_restore(index: int) -> bool:
	var ordered := false
	for o in def.get("objectives", []):
		if o.get("type") == "restore" and o.get("ordered", false):
			ordered = true
	if not ordered:
		return true
	return index == restore_next


func notify_restore(index: int) -> void:
	if index == restore_next:
		restore_next += 1


func _check_objectives() -> void:
	var all := true
	var i := 0
	for o in def.get("objectives", []):
		var ok := _obj_ok(o)
		obj_done[i] = ok
		if not ok:
			all = false
		i += 1
	if all and def.get("objectives", []).size() > 0:
		_win()


func _obj_ok(o: Dictionary) -> bool:
	match str(o.get("type", "")):
		"reach":
			return hero.global_position.x >= float(o.get("x", 3000))
		"defeat":
			return _living_enemies() <= 0
		"rescue":
			return get_tree().get_nodes_in_group("rescued").size() >= int(o.get("count", 1))
		"defend":
			return defend_left <= 0.0 and _living_enemies() <= 2
		"chase":
			return builder.van != null and builder.van.done
		"survive":
			return survive_left <= 0.0
		"destroy":
			return int(hero.stats.get("smashes", 0)) >= int(o.get("count", 4))
		"restore":
			return get_tree().get_nodes_in_group("light_on").size() >= int(o.get("count", 3))
		"stealth":
			return hero.global_position.x > float(def.get("length", 3000)) * 0.42
		"boss":
			return get_tree().get_nodes_in_group("boss").is_empty() and elapsed > 1.5
		"skill":
			return int(hero.stats.get(str(o.get("stat", "")), 0)) >= int(o.get("count", 1))
		_:
			return true


func _living_enemies() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.is_in_group("dummy") or e.is_in_group("decoy"):
			continue
		n += 1
	return n


func _on_hp(hp: int, max_hp: int) -> void:
	if hp < max_hp:
		damage_taken += 1
	if hud:
		hud.refresh()


func _on_died() -> void:
	if done:
		return
	continues += 1
	var cost := 0 if "cheap_continue" in SaveManager.active.get("city_upgrades", []) else 5
	if SaveManager.active.get("spark", 0) < cost and cost > 0:
		_fail("Knocked out...")
		return
	SaveManager.add_spark(-cost)
	hero.hp = hero.max_hp
	hero.global_position = hero.spawn_pos
	hero.velocity = Vector2.ZERO
	hero.invuln = 1.2
	hero.hp_changed.emit(hero.hp, hero.max_hp)
	VFX.text_pop(self, hero.global_position, "CHECKPOINT", Color("F4C542"))


func _tut(id: String, text: String) -> void:
	if id in SaveManager.active.get("tutorials", []):
		return
	if tut and tut.has_method("show_tip"):
		tut.show_tip(text)
	var t: Array = SaveManager.active.get("tutorials", [])
	t.append(id)
	SaveManager.active["tutorials"] = t


func _comic(id: String) -> void:
	comic_over = (load("res://scripts/ui/comic_overlay.gd") as GDScript).new()
	Game.ui.add_child(comic_over)
	comic_over.show_comic(id)
	var shown: Array = SaveManager.active.get("comics_shown", [])
	shown.append(id)
	SaveManager.active["comics_shown"] = shown


func _rank() -> String:
	var par := float(def.get("par_time", 150))
	var score := 0
	if elapsed <= par * 0.7:
		score += 2
	elif elapsed <= par:
		score += 1
	if damage_taken <= 1:
		score += 2
	elif damage_taken <= 4:
		score += 1
	if continues == 0:
		score += 1
	if score >= 5:
		return "S"
	if score >= 4:
		return "A"
	if score >= 2:
		return "B"
	return "C"


func _dare_ok() -> bool:
	var d: Dictionary = def.get("dare", {})
	if d.is_empty():
		return false
	var st := str(d.get("stat", ""))
	match st:
		"no_hit":
			return damage_taken == 0
		"unseen":
			return hero.unseen
		"speed":
			return elapsed <= float(def.get("par_time", 99))
		"team_style":
			return hero.signatures >= 8
		_:
			return int(hero.stats.get(st, 0)) >= int(d.get("count", 1))


func _win() -> void:
	if done:
		return
	done = true
	Game.in_combat = false
	var rank := _rank()
	var star := _dare_ok()
	var rec := str(def.get("recommended", ""))
	var spark := int(def.get("spark_reward", 40))
	if hero_id == rec:
		spark += 25
	if rank == "S":
		spark += 20
	if star:
		spark += 15
	SaveManager.add_spark(spark)
	SaveManager.mark_cleared(def.id, rank, star, elapsed)
	if def.kind == "trial":
		var tr: Array = SaveManager.active.get("trials", [])
		if not def.id in tr:
			tr.append(def.id)
			SaveManager.active["trials"] = tr
	if def.kind == "challenge":
		var ch: Array = SaveManager.active.get("challenges", [])
		if not def.id in ch:
			ch.append(def.id)
			SaveManager.active["challenges"] = ch
	SaveManager.save_now()
	AudioDirector.play("win")
	var res := {"win": true, "rank": rank, "star": star, "spark": spark, "time": elapsed, "def": def, "hero": hero_id, "stats": hero.stats}
	if def.id == "s12":
		Game.show_credits(res)
	else:
		Game.show_results(res)


func _fail(why: String) -> void:
	if done:
		return
	done = true
	Game.in_combat = false
	AudioDirector.play("lose")
	Game.show_results({"win": false, "why": why, "def": def, "hero": hero_id, "time": elapsed, "rank": "F", "star": false, "spark": 0, "stats": hero.stats if hero else {}})


func quit_to_hub() -> void:
	get_tree().paused = false
	Game.show_hub()
