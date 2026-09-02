class_name Enemy
extends CharacterBody2D

var kind := "drainling"
var elite := false
var max_hp := 3
var hp := 3
var facing := -1
var stun := 0.0
var tell := 0.0
var attack_cd := 0.0
var actor: CartoonActor
var speed := 140.0
var spotted := false
var gravity := 1900.0
var flying := false
var cone: Polygon2D
var home := Vector2.ZERO
var shot_cd := 0.0


func configure(p_kind: String, p_elite: bool = false) -> void:
	kind = p_kind
	elite = p_elite or p_kind == "elite_pulse"
	add_to_group("enemy")
	collision_layer = 4
	collision_mask = 1
	actor = CartoonActor.new()
	actor.configure(kind, Palette.enemy(kind, elite))
	if elite:
		actor.base_scale = 1.22
	add_child(actor)
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(actor.display_h * 0.22, actor.display_h * 0.42)
	cs.shape = r
	cs.position = Vector2(0, actor.foot - r.size.y * 0.5)
	add_child(cs)
	_stats()
	hp = max_hp
	z_index = 8
	if kind == "seeker":
		cone = Polygon2D.new()
		cone.color = Color(1, 0.3, 0.5, 0.18)
		cone.polygon = PackedVector2Array([Vector2(0, 0), Vector2(240, -70), Vector2(240, 70)])
		add_child(cone)


func _stats() -> void:
	var m: float = Settings.enemy_hp_mult()
	match kind:
		"drainling":
			max_hp = int(2 * m); speed = 170; 
		"scraper":
			max_hp = int(4 * m); speed = 130
		"drone":
			max_hp = int(3 * m); speed = 160; flying = true
		"shieldbot":
			max_hp = int(6 * m); speed = 90
		"grabber":
			max_hp = int(5 * m); speed = 85
		"turret":
			max_hp = int(5 * m); speed = 0; flying = true
		"bomber":
			max_hp = int(4 * m); speed = 110; flying = true
		"leaper":
			max_hp = int(3 * m); speed = 150
		"elite_pulse":
			max_hp = int(10 * m); speed = 100; elite = true
		"seeker":
			max_hp = int(4 * m); speed = 140
		_:
			max_hp = int(3 * m)


func _physics_process(delta: float) -> void:
	if home == Vector2.ZERO:
		home = global_position
	if stun > 0.0:
		stun -= delta
		if not flying:
			velocity.y += gravity * delta
		move_and_slide()
		return
	attack_cd = maxf(0.0, attack_cd - delta)
	shot_cd = maxf(0.0, shot_cd - delta)
	var hero := _hero()
	if not flying:
		velocity.y += gravity * delta
	if hero:
		var to := hero.global_position - global_position
		facing = 1 if to.x > 0.0 else -1
		if actor:
			actor.facing = facing
		_ai(delta, hero, to)
	move_and_slide()
	if global_position.y > 1700.0:
		_ko()


func _ai(delta: float, hero: Node2D, to: Vector2) -> void:
	Game.in_combat = true
	match kind:
		"drainling":
			_chase(to, 1.0)
			if to.length() < 46 and attack_cd <= 0.0:
				_melee(1, 200)
		"scraper":
			_chase(to, 0.9)
			if to.length() < 52 and attack_cd <= 0.0:
				_telegraph()
				_melee(2, 260)
		"drone":
			_hover(hero.global_position + Vector2(0, -80), delta)
			if shot_cd <= 0.0 and to.length() < 560:
				_shoot(to.normalized(), 1)
		"shieldbot":
			_chase(to, 0.6)
			if to.length() < 58 and attack_cd <= 0.0:
				_melee(2, 200)
		"grabber":
			_chase(to, 0.55)
			if to.length() < 50 and attack_cd <= 0.0:
				_telegraph()
				_melee(1, 80, 0.8)
		"turret":
			velocity = Vector2.ZERO
			if shot_cd <= 0.0:
				_shoot(to.normalized(), 1)
				shot_cd = 1.3
		"bomber":
			_hover(hero.global_position + Vector2(0, -120), delta)
			if shot_cd <= 0.0:
				_shoot(Vector2(facing * 0.4, 1).normalized(), 2, Color("F07040"), 420.0)
				shot_cd = 1.8
		"leaper":
			if is_on_floor() and to.length() < 260 and attack_cd <= 0.0:
				velocity = Vector2(facing * 280, -640)
				attack_cd = 1.2
			else:
				_chase(to, 0.8)
			if to.length() < 50:
				_melee(2, 300)
		"elite_pulse":
			_chase(to, 0.7)
			if to.length() < 70 and attack_cd <= 0.0:
				_telegraph()
				_melee(3, 400, 0.4)
				VFX.ring(get_parent(), global_position, Color("F4C542"), 90.0)
		"seeker":
			if cone:
				cone.scale.x = facing
				cone.color = Color(1, 0.3, 0.5, 0.28 if spotted else 0.16)
			if not spotted:
				_patrol(delta)
				if _sees(hero):
					spotted = true
					if hero is HeroBase:
						hero.unseen = false
					AudioDirector.play("alarm")
					VFX.text_pop(get_parent(), global_position + Vector2(0, -40), "SPOTTED", Color("FF4DA6"))
			else:
				_chase(to, 1.1)
				if to.length() < 48:
					_melee(2, 240)
		_:
			_chase(to, 0.8)


func _patrol(delta: float) -> void:
	if abs(global_position.x - home.x) > 160.0:
		facing = -1 if global_position.x > home.x else 1
	velocity.x = facing * 70.0


func _sees(hero: Node2D) -> bool:
	var to := hero.global_position - global_position
	if to.length() > 250.0:
		return false
	if sign(to.x) != facing and to.length() > 70.0:
		return false
	return abs(to.angle_to(Vector2(facing, 0))) < 0.7


func _chase(to: Vector2, mult: float) -> void:
	if flying:
		return
	velocity.x = sign(to.x) * speed * mult


func _hover(target: Vector2, delta: float) -> void:
	var d := target - global_position
	velocity = velocity.lerp(d.normalized() * speed, delta * 3.0)
	if d.length() < 30.0:
		velocity *= 0.9


func _telegraph() -> void:
	if Settings.reduced_flash:
		return
	tell = 0.2
	if actor:
		actor.modulate = Color(1.3, 1.1, 0.6)


func _melee(dmg: int, knock: float, stun_t: float = 0.15) -> void:
	attack_cd = 0.8
	var h := Hitbox.new()
	var k := Art.combat_scale(kind)
	h.setup(self, {"dmg": dmg, "knock": Vector2(facing * knock, -160), "stun": stun_t, "color": Color("FFAA66AA")}, Vector2(40, 30) * k, 0.12)
	add_child(h)
	h.position = Vector2(facing * 24, 0) * k
	AudioDirector.play("hit", 0.7)
	if actor:
		actor.modulate = Color.WHITE
		actor.pulse(1.15)


func _shoot(dir: Vector2, dmg: int, color: Color = Color("7EF0E0"), spd: float = 420.0) -> void:
	shot_cd = 1.1
	var p := Projectile.new()
	p.source = self
	p.team = "enemy"
	p.vel = dir * spd
	p.trail_color = color
	p.data = {"dmg": dmg, "knock": dir * 200.0, "stun": 0.1}
	get_parent().add_child(p)
	p.global_position = global_position + dir * 20.0 * Art.combat_scale(kind)
	AudioDirector.play("spark", 0.8)


func receive_hit(data: Dictionary, from_pos: Vector2, src: Node) -> void:
	if kind == "shieldbot" and src is Node2D:
		var from_front: bool = signf(global_position.x - from_pos.x) == float(facing)
		if from_front and str(data.get("kind", "")) != "pound" and str(data.get("kind", "")) != "slam":
			AudioDirector.play("shield", 0.7)
			VFX.text_pop(get_parent(), global_position, "CLANG", Color("88D0FF"))
			return
	hp -= int(data.get("dmg", 1))
	stun = maxf(stun, float(data.get("stun", 0.15)))
	var kn: Vector2 = data.get("knock", Vector2.ZERO) as Vector2
	velocity += kn
	if actor:
		actor.hurt_flash = 0.2
		actor.pulse(1.2)
	VFX.burst(get_parent(), global_position, Palette.enemy(kind, elite).trim, 6, 140.0)
	Juice.punch(6.0)
	if src is HeroBase and not is_on_floor() or (src is HeroBase and src.hero_key == "forge" and src.fuel >= 0):
		if src is HeroBase and not src.is_on_floor():
			src.bump_stat("air_kills")
	if hp <= 0:
		_ko()


func _ko() -> void:
	VFX.stars(get_parent(), global_position)
	VFX.text_pop(get_parent(), global_position, "POW", Color("FFEE88"))
	AudioDirector.play("hit2", 0.8)
	queue_free()


func _hero() -> Node2D:
	var decoys := get_tree().get_nodes_in_group("decoy")
	if decoys.size() > 0 and decoys[0] is Node2D:
		return decoys[0]
	var hs := get_tree().get_nodes_in_group("hero")
	if hs.size() > 0:
		return hs[0]
	return null
