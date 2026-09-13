class_name HeroBase
extends CharacterBody2D

signal died
signal hp_changed(hp: int, max_hp: int)
signal tutorial(id: String, text: String)

var hero_key := "sling"
var display_name := "Hero"
var move_speed := 380.0
var jump_velocity := -760.0
var gravity := 1950.0
var max_hp := 8
var hp := 8
var facing := 1
var invuln := 0.0
var coyote := 0.0
var jump_buf := 0.0
var combo := 0
var combo_time := 0.0
var aim := Vector2.RIGHT
var locked: Node2D
var stats: Dictionary = {}
var can_control := true
var costume := "classic"
var actor: CartoonActor
var cam: HeroCamera
var was_floor := false
var attack_cd := 0.0
var shield := 0.0
var armor := 0.0
var stun := 0.0
var fuel := 0.0
var max_fuel := 0.0
var dare_air := 0.0
var signatures := 0
var unseen := true
var spawn_pos := Vector2.ZERO
var one_heart := false


func _ready() -> void:
	add_to_group("hero")
	collision_layer = 2
	collision_mask = 1
	actor = CartoonActor.new()
	var colors: Dictionary = Palette.hero(hero_key, costume)
	actor.configure(hero_key, colors)
	add_child(actor)
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(actor.display_h * 0.18, actor.display_h * 0.40)
	cs.shape = r
	cs.position = Vector2(0, actor.foot - r.size.y * 0.5)
	add_child(cs)
	cam = HeroCamera.new()
	cam.hero = self
	add_child(cam)
	hp = max_hp
	spawn_pos = global_position
	_apply_difficulty()
	z_index = 10
	floor_snap_length = 8.0
	safe_margin = 0.2
	if not Game.in_hub:
		var lamp := PointLight2D.new()
		lamp.texture = Art.soft_light()
		lamp.energy = 0.28
		lamp.color = Color(1.0, 0.93, 0.82)
		lamp.texture_scale = 1.6
		add_child(lamp)
		tutorial.emit("move", "Left stick move  •  A jump  •  X attack")


func _apply_difficulty() -> void:
	if Game.challenge_mods.get("one_heart", false) or one_heart:
		max_hp = 1
		hp = 1
	hp_changed.emit(hp, max_hp)


func has_up(id: String) -> bool:
	return SaveManager.has_upgrade(hero_key, id)


func bump_stat(id: String, n: int = 1) -> void:
	stats[id] = int(stats.get(id, 0)) + n


func _physics_process(delta: float) -> void:
	if stun > 0.0:
		stun -= delta
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		velocity.y += gravity * delta
		move_and_slide()
		return
	if not can_control:
		velocity.y += gravity * delta
		move_and_slide()
		return
	invuln = maxf(0.0, invuln - delta)
	attack_cd = maxf(0.0, attack_cd - delta)
	combo_time = maxf(0.0, combo_time - delta)
	if combo_time <= 0.0:
		combo = 0
	shield = maxf(0.0, shield - delta)
	armor = maxf(0.0, armor - delta)
	if is_on_floor():
		coyote = 0.12
		if not was_floor:
			cam.land()
			AudioDirector.play("land", 0.9)
			if actor:
				actor.pulse(1.12)
			VFX.dust(get_parent(), global_position + Vector2(0, actor.foot if actor else 20))
			if has_up("smash_armor"):
				armor = maxf(armor, 0.25)
		dare_air = 0.0
	else:
		coyote = maxf(0.0, coyote - delta)
		dare_air += delta
		if dare_air >= 1.0:
			bump_stat("no_ground")
			dare_air = 0.0
	was_floor = is_on_floor()
	if Game.in_hub:
		jump_buf = 0.0
	elif Input.is_action_just_pressed("jump"):
		if Game.consume_hub_interact():
			jump_buf = 0.0
		else:
			jump_buf = 0.12
	else:
		jump_buf = maxf(0.0, jump_buf - delta)
	_update_aim()
	if not Game.in_hub and Input.is_action_just_pressed("lockon"):
		_cycle_lock()
		tutorial.emit("lockon", "RB cycles a target. Yellow ring = lock-on.")
	_kit_physics(delta)
	if not Game.in_hub and not is_on_floor() and velocity.y < 0.0 and not Input.is_action_pressed("jump"):
		if not (self is Forge and (self as Forge).hovering):
			velocity.y += gravity * 1.55 * delta
	move_and_slide()
	_kit_after(delta)
	if actor:
		actor.facing = facing
	if global_position.y > 1600.0:
		receive_hit({"dmg": 1, "knock": Vector2(0, -200)}, global_position, null)
		global_position = spawn_pos
		velocity = Vector2.ZERO


func _update_aim() -> void:
	var stick := Vector2(Input.get_axis("aim_left", "aim_right"), Input.get_axis("aim_up", "aim_down"))
	if Settings.invert_fly and hero_key == "forge":
		stick.y *= -1.0
	var mv := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	if stick.length() > 0.25:
		aim = stick.normalized()
	elif locked and is_instance_valid(locked):
		aim = (locked.global_position - global_position).normalized()
	elif mv.length() > 0.2:
		aim = mv.normalized()
		if abs(mv.x) > 0.2:
			facing = 1 if mv.x > 0.0 else -1
	else:
		aim = Vector2(facing, -0.15).normalized()
	if locked and is_instance_valid(locked):
		var assist := Settings.assist()
		if assist > 0.0:
			var to_t := (locked.global_position - global_position).normalized()
			aim = aim.lerp(to_t, assist * 0.65).normalized()
	if abs(aim.x) > 0.2:
		facing = 1 if aim.x > 0.0 else -1


func _cycle_lock() -> void:
	var foes := get_tree().get_nodes_in_group("enemy")
	var decoys := get_tree().get_nodes_in_group("decoy")
	foes.append_array(decoys)
	var alive: Array = []
	for f in foes:
		if f is Node2D and global_position.distance_to(f.global_position) < 780.0:
			alive.append(f)
	if alive.is_empty():
		locked = null
		return
	alive.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	if locked == null or not locked in alive:
		locked = alive[0]
		return
	var i := alive.find(locked)
	locked = alive[(i + 1) % alive.size()]


func _kit_physics(_delta: float) -> void:
	pass


func _kit_after(_delta: float) -> void:
	pass


func try_jump() -> bool:
	if Game.in_hub or Game.consume_hub_interact():
		jump_buf = 0.0
		return false
	if jump_buf > 0.0 and coyote > 0.0:
		velocity.y = jump_velocity
		coyote = 0.0
		jump_buf = 0.0
		AudioDirector.play("jump")
		if actor:
			actor.pulse(0.85)
		return true
	return false


func apply_move(delta: float, speed: float, accel: float = 3200.0) -> void:
	var x := Input.get_axis("move_left", "move_right")
	var target := x * speed
	velocity.x = move_toward(velocity.x, target, accel * delta)
	if abs(x) > 0.15:
		facing = 1 if x > 0.0 else -1


func spawn_hit(size: Vector2, offset: Vector2, dmg: int, knock: float, stun_t: float = 0.2, extra: Dictionary = {}) -> void:
	var k := Art.combat_scale(hero_key)
	var h := Hitbox.new()
	var data := {"dmg": dmg, "knock": Vector2(facing * knock, -180), "stun": stun_t, "color": extra.get("color", Color("FFFFFFAA")), "kind": extra.get("kind", "melee")}
	data.merge(extra)
	h.setup(self, data, size * k, extra.get("ttl", 0.12))
	add_child(h)
	h.position = offset * k
	Juice.punch(5.5)
	Juice.hitstop(0.02)
	if actor:
		actor.pulse(0.86)
	VFX.slash(get_parent(), global_position + offset * k, facing, extra.get("color", Color("F3E6D0")))
	AudioDirector.play(extra.get("sfx", "hit"))
	bump_stat("hits")


func spawn_proj(dir: Vector2, speed: float, dmg: int, extra: Dictionary = {}) -> Projectile:
	var p := Projectile.new()
	p.source = self
	p.team = "hero"
	p.vel = dir.normalized() * speed
	p.life = extra.get("life", 1.6)
	p.bounces = extra.get("bounces", 0)
	p.trail_color = extra.get("color", Color("9AD4FF"))
	p.data = {"dmg": dmg, "knock": dir.normalized() * 240.0 + Vector2(0, -80), "stun": 0.12, "kind": extra.get("kind", "bolt")}
	get_parent().add_child(p)
	p.global_position = global_position + dir.normalized() * 28.0 * Art.combat_scale(hero_key) + Vector2(0, -10)
	return p


func receive_hit(data: Dictionary, from_pos: Vector2, _src: Node) -> void:
	if invuln > 0.0 or shield > 0.0:
		if shield > 0.0:
			AudioDirector.play("shield")
			VFX.ring(get_parent(), global_position, Color("88D0FF"), 70.0)
		return
	if armor > 0.0:
		data = data.duplicate()
		data["dmg"] = max(1, int(data.get("dmg", 1)) - 1)
	var dmg := int(round(float(data.get("dmg", 1)) * Settings.damage_in_mult()))
	hp -= dmg
	invuln = 0.7 * Settings.i_frames_mult()
	var dir := (global_position - from_pos).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2(-facing, -0.3)
	velocity = dir * 420.0 + Vector2(0, -200)
	if actor:
		actor.hurt_flash = 0.35
		actor.pulse(1.3)
	AudioDirector.play("hurt")
	Juice.punch(12.0)
	Juice.hitstop(0.05)
	VFX.stars(get_parent(), global_position)
	bump_stat("times_hit")
	unseen = false
	hp_changed.emit(hp, max_hp)
	if Game.challenge_mods.get("no_damage_fail", false):
		hp = 0
	if hp <= 0:
		died.emit()


func heal(n: int = 2) -> void:
	hp = mini(max_hp, hp + n)
	hp_changed.emit(hp, max_hp)
	VFX.text_pop(get_parent(), global_position, "+HP", Color("2EE6C7"))


func nearest_group(group: String, radius: float) -> Node2D:
	var best: Node2D = null
	var bd := radius
	for n in get_tree().get_nodes_in_group(group):
		if n is Node2D:
			var d := global_position.distance_to(n.global_position)
			if d < bd:
				bd = d
				best = n
	return best
