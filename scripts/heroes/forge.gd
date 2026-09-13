class_name Forge
extends HeroBase

var hovering := false
var dash_cd := 0.0
var charge := 0.0
var charging_bolt := false
var decoy: Node2D


func _ready() -> void:
	hero_key = "forge"
	display_name = "Forge"
	move_speed = 360.0
	jump_velocity = -720.0
	max_fuel = 6.5 if has_up("overclock") else 5.0
	fuel = max_fuel
	costume = str(SaveManager.active.get("costumes_eq", {}).get("forge", "classic"))
	super._ready()
	tutorial.emit("forge", "Hold A to hover (fuel). Y charges a bolt. B dashes. LB shield.")


func _kit_physics(delta: float) -> void:
	dash_cd = maxf(0.0, dash_cd - delta)
	hovering = false
	var jump_hold := Input.is_action_pressed("jump")
	if Input.is_action_just_pressed("jump"):
		if Game.in_hub:
			pass
		elif not try_jump() and fuel > 0.2:
			hovering = true
	if jump_hold and not is_on_floor() and fuel > 0.0 and not Game.in_hub:
		hovering = true
	if hovering:
		fuel = maxf(0.0, fuel - delta * (0.7 if has_up("overclock") else 0.95))
		var fly := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
		if Settings.invert_fly:
			fly.y *= -1.0
		velocity.x = move_toward(velocity.x, fly.x * 380.0, 2600.0 * delta)
		var target_y := fly.y * 280.0
		if abs(fly.y) < 0.15:
			target_y = -40.0
		velocity.y = move_toward(velocity.y, target_y, 2200.0 * delta)
		if abs(fly.x) > 0.2:
			facing = 1 if fly.x > 0.0 else -1
		if fuel <= 0.0:
			hovering = false
	else:
		velocity.y += gravity * delta
		apply_move(delta, move_speed)
		try_jump()
		if is_on_floor():
			fuel = minf(max_fuel, fuel + delta * 2.4)
	if Input.is_action_just_pressed("attack") and attack_cd <= 0.0:
		_bolt(false)
	if Input.is_action_pressed("signature"):
		charging_bolt = true
		charge = minf(1.0, charge + delta * 1.4)
	if charging_bolt and not Input.is_action_pressed("signature"):
		charging_bolt = false
		_bolt(charge > 0.35)
		charge = 0.0
		signatures += 1
		bump_stat("signatures")
	if Input.is_action_just_pressed("mobility") and dash_cd <= 0.0:
		_dash()
	if Input.is_action_just_pressed("gadget"):
		if has_up("bounce_bomb"):
			_bomb()
		elif has_up("decoy_drone"):
			_decoy()
		else:
			_shield()


func _bolt(charged: bool) -> void:
	attack_cd = 0.16 if has_up("overclock") else 0.22
	var dir := aim
	if dir.length() < 0.1:
		dir = Vector2(facing, 0)
	var dmg := 3 if charged else 1
	var spd := 980.0 if charged else 820.0
	if has_up("overclock"):
		spd += 120.0
	spawn_proj(dir, spd, dmg, {"color": Color("9AD4FF") if not charged else Color("F4C542"), "kind": "bolt", "life": 1.8})
	bump_stat("bolts")
	AudioDirector.play("bolt", 0.9 if charged else 1.1)
	actor.pulse(0.9)


func _dash() -> void:
	dash_cd = 0.45
	var dir := aim
	if dir.length() < 0.2:
		dir = Vector2(facing, 0)
	velocity = dir.normalized() * 880.0
	invuln = maxf(invuln, 0.18)
	bump_stat("dashes")
	AudioDirector.play("whoosh", 1.3)
	VFX.burst(get_parent(), global_position, Color("3B7CFF"), 8, 160.0)
	if has_up("afterburner"):
		spawn_hit(Vector2(70, 40), Vector2(-facing * 20, 0), 2, 200, 0.2, {"kind": "trail", "ttl": 0.18, "color": Color("FFB070AA")})


func _shield() -> void:
	shield = 1.6 if has_up("capacitor") else 0.9
	AudioDirector.play("shield")
	VFX.ring(get_parent(), global_position, Color("88D0FF"), 90.0)
	tutorial.emit("shield", "Shield pulse! Hits bounce off for a moment.")


func _bomb() -> void:
	var p := spawn_proj(aim + Vector2(0, -0.2), 520.0, 3, {"color": Color("F07040"), "kind": "bomb", "life": 2.4, "bounces": 3})
	p.bounces = 3
	AudioDirector.play("charge")
	bump_stat("bombs")


func _decoy() -> void:
	if decoy and is_instance_valid(decoy):
		decoy.queue_free()
	decoy = Node2D.new()
	decoy.add_to_group("decoy")
	decoy.add_to_group("enemy")
	var a := CartoonActor.new()
	a.configure("forge", Palette.hero("forge", costume))
	a.modulate = Color(1, 1, 1, 0.65)
	decoy.add_child(a)
	get_parent().add_child(decoy)
	decoy.global_position = global_position + Vector2(facing * 40, 0)
	AudioDirector.play("ui")
	get_tree().create_timer(6.0).timeout.connect(func():
		if is_instance_valid(decoy):
			decoy.queue_free()
	)
