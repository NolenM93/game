class_name Sling
extends HeroBase

var tethered := false
var anchors: Array[Vector2] = []
var lengths: Array[float] = []
var ribbon: Line2D
var clinging := false
var wall_dir := 0
var slam := false
var extra_jump := false


func _ready() -> void:
	hero_key = "sling"
	display_name = "Sling"
	move_speed = 410.0
	jump_velocity = -780.0
	costume = str(SaveManager.active.get("costumes_eq", {}).get("sling", "classic"))
	super._ready()
	ribbon = Line2D.new()
	ribbon.width = 5.0
	ribbon.default_color = Color("E23B9A")
	ribbon.z_index = 8
	add_child(ribbon)
	tutorial.emit("sling", "Y tethers a swing point. Hold A to climb the ribbon. B wall-leaps or slams.")


func _kit_physics(delta: float) -> void:
	if not tethered:
		velocity.y += gravity * delta
		apply_move(delta, move_speed)
		try_jump()
		_wall_cling(delta)
	else:
		velocity.y += gravity * 0.85 * delta
		var x := Input.get_axis("move_left", "move_right")
		velocity.x += x * 520.0 * delta
		if Input.is_action_pressed("jump"):
			for i in lengths.size():
				lengths[i] = maxf(70.0, lengths[i] - 380.0 * delta)
		if Input.is_action_just_pressed("jump") and has_up("aerial_acrobat") and not extra_jump:
			velocity += Vector2(facing * 80, -420)
			extra_jump = true
			AudioDirector.play("jump", 1.2)
		if Input.is_action_just_pressed("mobility") and has_up("zip_dash"):
			_release_tether(aim * 920.0 + Vector2(0, -80))
			invuln = maxf(invuln, 0.15)
			bump_stat("dashes")
			VFX.burst(get_parent(), global_position, Color("2EE6C7"), 10, 200.0)
	if Input.is_action_just_pressed("signature"):
		if tethered:
			_release_tether(velocity + Vector2(facing * 120, -220))
		else:
			_try_tether()
		signatures += 1
		bump_stat("signatures")
	if Input.is_action_just_pressed("attack") and attack_cd <= 0.0:
		_combo()
	if Input.is_action_just_pressed("gadget"):
		_yank()
	if Input.is_action_just_pressed("mobility") and not tethered:
		if clinging:
			velocity = Vector2(-wall_dir * 460.0, -700.0)
			clinging = false
			AudioDirector.play("whoosh")
		elif not is_on_floor():
			slam = true
			velocity.y = 1200.0
			velocity.x *= 0.4
			tutorial.emit("slam", "Air B slams down and pops a ribbon shock.")


func _kit_after(_delta: float) -> void:
	if tethered:
		_constrain()
		extra_jump = extra_jump
	else:
		extra_jump = false
		ribbon.points = PackedVector2Array()
	if slam and is_on_floor():
		slam = false
		spawn_hit(Vector2(90, 40), Vector2(0, 20), 2, 320, 0.4, {"kind": "slam", "color": Color("E23B9AAA"), "sfx": "whoosh"})
		VFX.ring(get_parent(), global_position, Color("E23B9A"), 100.0)
		Juice.punch(14.0)
	_draw_ribbon()


func _try_tether() -> void:
	var pts := _swing_candidates()
	if pts.is_empty():
		AudioDirector.play("blip", 0.6)
		return
	tethered = true
	anchors.clear()
	lengths.clear()
	anchors.append(pts[0])
	lengths.append(global_position.distance_to(pts[0]))
	if has_up("double_tether") and pts.size() > 1:
		anchors.append(pts[1])
		lengths.append(global_position.distance_to(pts[1]))
	bump_stat("swings")
	AudioDirector.play("whoosh")
	actor.pulse(0.8)
	tutorial.emit("swing", "You're swinging! Steer with the stick. Y again to leap off.")


func _swing_candidates() -> Array[Vector2]:
	var found: Array[Vector2] = []
	var assist := 120.0 + 180.0 * Settings.assist()
	for n in get_tree().get_nodes_in_group("swing_point"):
		if n is Node2D:
			var to: Vector2 = n.global_position - global_position
			if to.length() > 780.0 or to.length() < 40.0:
				continue
			var dot := aim.dot(to.normalized())
			if dot > 0.15 or to.length() < assist:
				found.append(n.global_position)
	found.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		var da: float = abs(aim.angle_to(a - global_position)) + global_position.distance_to(a) * 0.001
		var db: float = abs(aim.angle_to(b - global_position)) + global_position.distance_to(b) * 0.001
		return da < db
	)
	return found


func _constrain() -> void:
	for i in anchors.size():
		var to := global_position - anchors[i]
		var dist := to.length()
		var L: float = lengths[i]
		if dist > L and dist > 1.0:
			var n := to / dist
			global_position = anchors[i] + n * L
			var radial := velocity.dot(n)
			if radial > 0.0:
				velocity -= n * radial
			velocity += n.orthogonal() * 10.0 * facing


func _release_tether(boost: Vector2) -> void:
	tethered = false
	anchors.clear()
	lengths.clear()
	velocity += boost
	AudioDirector.play("jump", 0.8)


func _draw_ribbon() -> void:
	var pts := PackedVector2Array()
	if tethered:
		for a in anchors:
			pts.append(to_local(a))
			pts.append(Vector2.ZERO)
	ribbon.points = pts


func _wall_cling(delta: float) -> void:
	clinging = false
	if is_on_floor() or tethered:
		return
	if is_on_wall():
		var n := get_wall_normal()
		var into := Input.get_axis("move_left", "move_right")
		if (n.x < -0.4 and into > 0.2) or (n.x > 0.4 and into < -0.2):
			clinging = true
			wall_dir = -1 if n.x > 0.0 else 1
			velocity.y = minf(velocity.y, 70.0)
			velocity.y -= 20.0 * delta


func _combo() -> void:
	attack_cd = 0.18
	combo = (combo % 3) + 1
	combo_time = 0.5
	bump_stat("combos")
	var dmg := 1 + (1 if has_up("ribbon_edge") else 0)
	match combo:
		1:
			spawn_hit(Vector2(46, 30), Vector2(facing * 28, -6), dmg, 220, 0.12, {"sfx": "hit"})
		2:
			spawn_hit(Vector2(50, 34), Vector2(facing * 32, 0), dmg, 260, 0.12, {"sfx": "hit2"})
		3:
			spawn_hit(Vector2(64, 40), Vector2(facing * 36, -8), dmg + 1, 380, 0.25, {"sfx": "whoosh", "kind": "finisher"})
			Juice.hitstop(0.04)


func _yank() -> void:
	var foe := nearest_group("enemy", 260.0)
	if foe == null:
		foe = nearest_group("smashable", 220.0)
	if foe == null:
		AudioDirector.play("blip", 0.5)
		return
	bump_stat("yanks")
	AudioDirector.play("whoosh", 1.1)
	var stun_t := 1.1 if has_up("long_stun") else 0.65
	if foe.has_method("receive_hit"):
		foe.receive_hit({"dmg": 1, "knock": (global_position - foe.global_position).normalized() * 480.0, "stun": stun_t, "kind": "yank"}, global_position, self)
	VFX.burst(get_parent(), foe.global_position, Color("E23B9A"), 8, 160.0)
	tutorial.emit("yank", "LB yanks a nearby foe and stuns them. Smash them next!")
