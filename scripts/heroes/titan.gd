class_name Titan
extends HeroBase

var charging := false
var charge_t := 0.0
var surging := false
var surge_t := 0.0
var pound := false
var grabbing: Node2D
var grab_t := 0.0
var base_scale := Vector2.ONE


func _ready() -> void:
	hero_key = "titan"
	display_name = "Titan"
	move_speed = 310.0
	jump_velocity = -700.0
	gravity = 2100.0
	max_hp = 10
	costume = str(SaveManager.active.get("costumes_eq", {}).get("titan", "classic"))
	super._ready()
	base_scale = actor.scale
	tutorial.emit("titan", "Y charges a shoulder. Air Y pounds. B Surges. LB throws cars and pests.")


func _kit_physics(delta: float) -> void:
	if grabbing and is_instance_valid(grabbing):
		grab_t -= delta
		grabbing.global_position = global_position + Vector2(facing * 48, -20)
		if grab_t <= 0.0 or Input.is_action_just_pressed("gadget") or Input.is_action_just_pressed("attack"):
			_throw()
		apply_move(delta, move_speed * 0.7)
		velocity.y += gravity * delta
		try_jump()
		return
	if surging:
		surge_t -= delta
		move_speed = 360.0
		armor = 0.2
		if actor:
			actor.squash = Vector2(1.25, 1.25)
		if surge_t <= 0.0:
			surging = false
			move_speed = 310.0
	else:
		if actor:
			actor.squash = Vector2.ONE
	velocity.y += gravity * delta
	if charging:
		charge_t += delta
		velocity.x = facing * (420.0 + mini(int(charge_t * 80.0), 180))
		if charge_t > 0.12 and int(charge_t * 10.0) % 2 == 0:
			spawn_hit(Vector2(50, 40), Vector2(facing * 30, 4), 2, 400, 0.2, {"kind": "charge", "ttl": 0.08, "sfx": "thud"})
		if not Input.is_action_pressed("signature") or charge_t > 0.9:
			charging = false
			attack_cd = 0.25
	else:
		apply_move(delta, move_speed, 1800.0)
		try_jump()
	if Input.is_action_just_pressed("signature"):
		signatures += 1
		bump_stat("signatures")
		if not is_on_floor():
			pound = true
			velocity.y = 1400.0
			tutorial.emit("pound", "Ground pound! The shockwave pops anything nearby.")
		else:
			charging = true
			charge_t = 0.0
			AudioDirector.play("whoom")
	if Input.is_action_just_pressed("attack") and attack_cd <= 0.0 and not charging:
		_combo()
	if Input.is_action_just_pressed("mobility") and not surging:
		surging = true
		surge_t = 3.2 if has_up("long_surge") else 2.0
		bump_stat("surges")
		AudioDirector.play("surge")
		VFX.ring(get_parent(), global_position, Color("E89B2D"), 120.0)
		Juice.punch(10.0)
		tutorial.emit("surge", "Surge! You're bigger, tougher, and the floor is a drum.")
	if Input.is_action_just_pressed("gadget"):
		_grab()
	if pound and is_on_floor():
		pound = false
		bump_stat("pounds")
		var w := 140.0 if has_up("wrecking") else 100.0
		spawn_hit(Vector2(w, 46), Vector2(0, 18), 3, 420, 0.35, {"kind": "pound", "sfx": "thud"})
		VFX.ring(get_parent(), global_position, Color("E89B2D"), 130.0)
		Juice.punch(16.0)
		Juice.hitstop(0.07)
		if has_up("quake_walk"):
			velocity.x = facing * 280.0
		if has_up("smash_armor"):
			armor = 0.6


func _combo() -> void:
	attack_cd = 0.28
	combo = (combo % 3) + 1
	combo_time = 0.55
	bump_stat("combos")
	var dmg := 2 + (1 if has_up("heavy_hands") else 0)
	match combo:
		1:
			spawn_hit(Vector2(54, 36), Vector2(facing * 32, 0), dmg, 300, 0.2, {"sfx": "thud"})
		2:
			spawn_hit(Vector2(58, 40), Vector2(facing * 34, 4), dmg, 340, 0.2, {"sfx": "thud"})
		3:
			spawn_hit(Vector2(72, 48), Vector2(facing * 38, 0), dmg + 1, 520, 0.35, {"sfx": "whoom", "kind": "finisher"})
			Juice.hitstop(0.05)
			bump_stat("smashes")


func _grab() -> void:
	var t := nearest_group("smashable", 90.0)
	if t == null:
		t = nearest_group("enemy", 90.0)
	if t == null:
		AudioDirector.play("blip", 0.5)
		return
	grabbing = t
	grab_t = 1.6
	AudioDirector.play("thud", 0.8)
	tutorial.emit("throw", "You grabbed it! Press LB or X to throw.")


func _throw() -> void:
	if grabbing == null:
		return
	bump_stat("throws")
	var dir := aim
	if dir.length() < 0.2:
		dir = Vector2(facing, -0.3)
	if grabbing.has_method("receive_hit"):
		grabbing.receive_hit({"dmg": 3, "knock": dir.normalized() * 780.0, "stun": 0.6, "kind": "throw"}, global_position, self)
	if grabbing.is_in_group("smashable") and grabbing.has_method("launch"):
		grabbing.launch(dir.normalized() * 900.0)
	VFX.burst(get_parent(), grabbing.global_position, Color("E89B2D"), 8, 180.0)
	grabbing = null
	AudioDirector.play("whoom")
