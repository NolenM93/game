class_name Boss
extends Enemy

var phase := 1
var phase_t := 0.0
var special_cd := 2.0
var title_shown := false


func configure(p_kind: String, p_elite: bool = false) -> void:
	super.configure(p_kind, true)
	add_to_group("boss")
	match kind:
		"riptide":
			max_hp = int(28 * Settings.enemy_hp_mult())
			speed = 160
		"gridlock":
			max_hp = int(32 * Settings.enemy_hp_mult())
			speed = 70
		"brownout":
			max_hp = int(30 * Settings.enemy_hp_mult())
			speed = 150
		"drain":
			max_hp = int(40 * Settings.enemy_hp_mult())
			speed = 90
			flying = true
		"overload":
			max_hp = int(48 * Settings.enemy_hp_mult())
			speed = 120
			flying = true
	hp = max_hp
	if actor:
		actor.base_scale = 1.08
	AudioDirector.play("boss")
	AudioDirector.play_music("boss")


func _physics_process(delta: float) -> void:
	if not title_shown:
		title_shown = true
		VFX.text_pop(get_parent(), global_position + Vector2(0, -80), kind.to_upper(), Color("F4C542"))
	phase_t += delta
	special_cd -= delta
	if hp < max_hp * 0.45:
		phase = 2
	super._physics_process(delta)


func _ai(delta: float, hero: Node2D, to: Vector2) -> void:
	Game.in_combat = true
	match kind:
		"riptide":
			_riptide(hero, to)
		"gridlock":
			_gridlock(hero, to)
		"brownout":
			_brownout(hero, to)
		"drain":
			_drain(hero, to)
		"overload":
			_drain(hero, to)
			if special_cd <= 0.0:
				_shoot(Vector2(-facing, 0.2).normalized(), 2, Color("FF4466"), 500.0)
				special_cd = 0.8
		_:
			_chase(to, 1.0)


func _riptide(hero: Node2D, to: Vector2) -> void:
	if is_on_floor() and special_cd <= 0.0:
		_telegraph()
		velocity = Vector2(facing * 200, -720)
		special_cd = 2.2
	else:
		_chase(to, 1.0)
	if is_on_floor() and attack_cd <= 0.0 and to.length() < 160:
		_wave()
	if to.length() < 120:
		_melee(2, 360)


func _wave() -> void:
	attack_cd = 1.4
	var h := Hitbox.new()
	var k := Art.combat_scale(kind)
	h.setup(self, {"dmg": 2, "knock": Vector2(facing * 500, -120), "stun": 0.3, "color": Color("7EE0FFAA")}, Vector2(220, 28) * k, 0.35)
	add_child(h)
	h.position = Vector2(facing * 80, 22) * k
	AudioDirector.play("whoom")
	VFX.ring(get_parent(), global_position + Vector2(facing * 40, 20), Color("7EE0FF"), 140.0)


func _gridlock(hero: Node2D, to: Vector2) -> void:
	velocity.x = 0
	if special_cd <= 0.0:
		_telegraph()
		_shoot(to.normalized(), 2, Color("F0A040"), 380.0)
		_shoot(to.normalized().rotated(0.2), 1, Color("F0A040"), 360.0)
		_shoot(to.normalized().rotated(-0.2), 1, Color("F0A040"), 360.0)
		special_cd = 1.6 if phase == 1 else 1.1
		if phase == 2 and randf() > 0.5:
			_spawn_minion("turret")
	if to.length() < 140:
		_melee(3, 400)


func _brownout(hero: Node2D, to: Vector2) -> void:
	if not Settings.reduced_flash and phase == 2:
		modulate.a = 0.55 + 0.45 * abs(sin(phase_t * 3.0))
	_chase(to, 1.15)
	if special_cd <= 0.0:
		_telegraph()
		velocity = to.normalized() * 520.0
		special_cd = 1.8
		_spawn_minion("seeker")
	if to.length() < 110:
		_melee(2, 300)


func _drain(hero: Node2D, to: Vector2) -> void:
	_hover(hero.global_position + Vector2(0, -140), 0.016)
	if special_cd <= 0.0:
		_telegraph()
		_siphon(hero)
		special_cd = 2.4 if kind != "overload" else 1.6
		if phase == 2:
			_spawn_minion("drone")


func _siphon(hero: Node2D) -> void:
	var h := Hitbox.new()
	h.setup(self, {"dmg": 2, "knock": Vector2(0, 40), "stun": 0.4, "color": Color("6CF0E0AA"), "kind": "siphon"}, Vector2(40, 220), 0.6)
	add_child(h)
	h.position = to_local(hero.global_position) * Vector2(0.2, 0.5) + Vector2(0, 40)
	AudioDirector.play("whoom", 0.6)
	VFX.burst(get_parent(), global_position, Color("6CF0E0"), 12, 120.0)


func _spawn_minion(k: String) -> void:
	var e := Enemy.new()
	e.configure(k, false)
	get_parent().add_child(e)
	e.global_position = global_position + Vector2(facing * 80, -20)


func _ko() -> void:
	VFX.ring(get_parent(), global_position, Color("F4C542"), 220.0)
	VFX.stars(get_parent(), global_position)
	AudioDirector.play("win")
	Juice.hitstop(0.12)
	Juice.punch(22.0)
	queue_free()
