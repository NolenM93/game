class_name LevelBuilder
extends Node2D

var def: Dictionary = {}
var rng := RandomNumberGenerator.new()
var pal: Dictionary = {}
var length := 4000.0
var ground_y := 920.0
var van: ChaseVan


func build(p_def: Dictionary) -> void:
	def = p_def
	length = float(def.get("length", 4000))
	pal = Palette.district(str(def.get("district", "midtown")))
	rng.seed = hash(str(def.get("id", "x")))
	_sky()
	_parallax()
	_weather()
	match str(def.get("layout", "roofs")):
		"docks":
			_docks()
		"grid":
			_grid()
		"arena":
			_arena()
		"chase":
			_roofs()
			_chase()
		"gym_swing":
			_gym_swing()
		"gym_smash":
			_gym_smash()
		"gym_fly":
			_gym_fly()
		_:
			_roofs()
	_waves()
	_objectives_props()
	_collectibles()
	WorldProps.checkpoint(self, Vector2(180, ground_y - 80))
	WorldProps.checkpoint(self, Vector2(length * 0.45, ground_y - 80))
	WorldProps.checkpoint(self, Vector2(length * 0.75, ground_y - 80))


func spawn_point() -> Vector2:
	return Vector2(160, ground_y - 80)


func _sky() -> void:
	var sky := ColorRect.new()
	sky.size = Vector2(length + 2400, 2200)
	sky.position = Vector2(-600, -900)
	sky.color = pal.sky_top
	sky.z_index = -90
	add_child(sky)
	Art.backdrop(self, Art.district_bg(str(def.get("district", "midtown"))), length, -160.0, Vector2(0.16, 0.5))
	var veil := ColorRect.new()
	veil.size = Vector2(length + 2400, 2200)
	veil.position = Vector2(-600, -900)
	veil.color = Color(pal.fog.r, pal.fog.g, pal.fog.b, 0.06)
	veil.z_index = -20
	add_child(veil)


func _parallax() -> void:
	# Painted city lives in Art.backdrop. Keep a few mid-ground silhouettes for depth.
	var mid := Art.tex("prop_building")
	if mid == null:
		return
	for i in 6:
		var s := Sprite2D.new()
		s.texture = mid
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		s.modulate = Color(0.22, 0.24, 0.32, 0.4)
		s.centered = false
		var sc := (420.0 + rng.randf() * 180.0) / float(mid.get_height())
		s.scale = Vector2(sc, sc)
		s.position = Vector2(300 + i * 620, ground_y - mid.get_height() * sc + 40)
		s.z_index = -35
		s.flip_h = i % 2 == 0
		add_child(s)


func _ground(x: float, w: float) -> void:
	WorldProps.static_rect(self, Rect2(x, ground_y, w, 240), pal.ground, [], Art.ground_tex(str(def.get("district", "midtown"))), true, 56.0)


func _building(x: float, w: float, h: float) -> void:
	WorldProps.building(self, Rect2(x, ground_y - h, w, h), rng.randf() > 0.5)
	if "swing" in def.get("features", []) or str(def.get("layout", "")) in ["roofs", "chase", "gym_swing"]:
		WorldProps.swing_point(self, Vector2(x + w * 0.5, ground_y - h - 26))


func _weather() -> void:
	var w := str(def.get("weather", ""))
	if w == "rain" or w == "storm":
		var p := CPUParticles2D.new()
		p.amount = 200
		p.lifetime = 0.9
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(length * 0.5, 10)
		p.direction = Vector2(-0.2, 1)
		p.gravity = Vector2(-80, 900)
		p.initial_velocity_min = 400
		p.initial_velocity_max = 700
		p.color = Color(0.7, 0.8, 1, 0.45)
		p.position = Vector2(length * 0.5, -200)
		p.z_index = 50
		add_child(p)
	if w == "blackout":
		modulate = Color(0.55, 0.6, 0.85)


func _roofs() -> void:
	_ground(0, length + 400)
	var x := 280.0
	while x < length - 200:
		var w := 160.0 + rng.randi_range(0, 140)
		var h := 160.0 + rng.randi_range(0, 300)
		_building(x, w, h)
		if rng.randf() > 0.55:
			WorldProps.static_rect(self, Rect2(x + w + 20, ground_y - 140 - rng.randi_range(0, 80), 90, 18), pal.mid)
		x += w + 70 + rng.randi_range(0, 90)
	if "smash" in def.get("features", []):
		for i in 6:
			WorldProps.smashable(self, Vector2(500 + i * 400, ground_y - 30), pal.build2)


func _docks() -> void:
	_ground(0, length + 400)
	var water := ColorRect.new()
	water.size = Vector2(length + 800, 160)
	water.position = Vector2(-200, ground_y + 40)
	water.color = pal.water
	water.z_index = -5
	add_child(water)
	var x := 240.0
	while x < length - 180:
		var w := 140.0 + rng.randi_range(0, 80)
		WorldProps.static_rect(self, Rect2(x, ground_y - 18, w, 18), pal.accent)
		if rng.randf() > 0.4:
			WorldProps.static_rect(self, Rect2(x + 20, ground_y - 220, 24, 220), pal.build2)
			WorldProps.swing_point(self, Vector2(x + 32, ground_y - 240))
		x += 260
	for i in 10:
		WorldProps.smashable(self, Vector2(420 + i * 280, ground_y - 30))
	if "wet" in def.get("features", []):
		pass


func _grid() -> void:
	_ground(0, length + 400)
	var x := 200.0
	var i := 0
	while x < length - 160:
		var h := 120.0 + (i % 4) * 70.0
		WorldProps.building(self, Rect2(x, ground_y - h, 180, h), i % 2 == 0)
		WorldProps.static_rect(self, Rect2(x + 40, ground_y - h - 90, 100, 16), pal.accent)
		if "swing" in def.get("features", []) or i % 2 == 0:
			WorldProps.swing_point(self, Vector2(x + 90, ground_y - h - 110))
		if "fuel" in def.get("features", []) or str(def.get("recommended", "")) == "forge":
			if i % 2 == 1:
				WorldProps.fuel_pad(self, Vector2(x + 90, ground_y - h - 100))
		if "wires" in def.get("features", []) and i % 3 == 0:
			var wire := Sprite2D.new()
			wire.texture = Art.soft_light()
			wire.modulate = Color("6CF0E088")
			wire.scale = Vector2(0.06, 0.45)
			wire.position = Vector2(x + 20, ground_y - 80)
			add_child(wire)
		x += 240
		i += 1
	if "smash" in def.get("features", []):
		for n in 5:
			WorldProps.smashable(self, Vector2(700 + n * 500, ground_y - 30), pal.build2)


func _arena() -> void:
	length = maxf(length, 2200)
	_ground(0, length)
	WorldProps.static_rect(self, Rect2(40, 200, 48, 800), pal.build2)
	WorldProps.static_rect(self, Rect2(length - 80, 200, 48, 800), pal.build2)
	WorldProps.static_rect(self, Rect2(400, ground_y - 160, 160, 24), pal.mid)
	WorldProps.static_rect(self, Rect2(900, ground_y - 240, 160, 24), pal.mid)
	WorldProps.swing_point(self, Vector2(480, ground_y - 190))
	WorldProps.swing_point(self, Vector2(980, ground_y - 270))
	WorldProps.fuel_pad(self, Vector2(700, ground_y - 20))
	for i in 4:
		WorldProps.smashable(self, Vector2(500 + i * 180, ground_y - 30))


func _chase() -> void:
	van = ChaseVan.new()
	add_child(van)
	van.global_position = Vector2(700, ground_y - 40)
	van.speed = 240.0


func _gym_swing() -> void:
	_ground(0, length)
	for i in 9:
		var h := 180 + (i % 3) * 90
		WorldProps.static_rect(self, Rect2(220 + i * 240, ground_y - h, 40, h), pal.build)
		WorldProps.swing_point(self, Vector2(240 + i * 240, ground_y - h - 24))


func _gym_smash() -> void:
	_ground(0, length)
	for i in 14:
		WorldProps.smashable(self, Vector2(300 + i * 140, ground_y - 30))
	WorldProps.static_rect(self, Rect2(800, ground_y - 120, 200, 24), pal.mid)


func _gym_fly() -> void:
	_ground(0, length)
	for i in 8:
		WorldProps.static_rect(self, Rect2(280 + i * 280, ground_y - 200 - (i % 3) * 80, 90, 18), pal.accent)
		WorldProps.fuel_pad(self, Vector2(320 + i * 280, ground_y - 220 - (i % 3) * 80))


func _waves() -> void:
	for w in def.get("waves", []):
		var at := float(w.get("at", 800))
		var elite := bool(w.get("elite", false))
		for pair in w.get("e", []):
			var k := str(pair[0])
			var n := int(pair[1])
			for i in n:
				var e := Enemy.new()
				e.configure(k, elite)
				add_child(e)
				e.global_position = Vector2(at + i * 46, ground_y - 50)


func _objectives_props() -> void:
	var lights := 0
	var destroys := 0
	var rescues := 0
	for o in def.get("objectives", []):
		match str(o.get("type", "")):
			"restore":
				lights = int(o.get("count", 3))
			"destroy":
				destroys = int(o.get("count", 4))
			"rescue":
				rescues = int(o.get("count", 1))
			"defend":
				WorldProps.generator(self, Vector2(minf(900, length * 0.35), ground_y - 50))
			"boss":
				var b := Boss.new()
				var bk := str(def.get("boss", "riptide"))
				b.configure(bk)
				add_child(b)
				b.global_position = Vector2(length * 0.62, ground_y - 80)
	for i in lights:
		WorldProps.restore_light(self, Vector2(600 + i * (length - 1000) / max(1, lights), ground_y - 70), i)
	for i in destroys:
		WorldProps.smashable(self, Vector2(480 + i * 320, ground_y - 30), Color("2A5080"))
		# pylons tagged
		var pylon := WorldProps.smashable(self, Vector2(500 + i * 340, ground_y - 30), Color("6CF0E0"))
		pylon.add_to_group("pylon")
	for i in rescues:
		var c := Civilian.new()
		add_child(c)
		c.global_position = Vector2(700 + i * 420, ground_y - 40)
		for o in def.get("objectives", []):
			if o.get("escort", false):
				c.follow = false


func _collectibles() -> void:
	var i := 0
	for id in def.get("tokens", []):
		if id in SaveManager.active.get("tokens", []):
			continue
		WorldProps.pickup(self, Vector2(800 + i * 500, ground_y - 180), "token", id)
		i += 1
	var j := 0
	var placed: Array = []
	for id in def.get("comics", []):
		if id in SaveManager.active.get("comics", []):
			continue
		WorldProps.pickup(self, Vector2(1100 + j * 420, ground_y - 260), "comic", id)
		placed.append(id)
		j += 1
	var extras: Array = []
	for id in Catalog.comics().keys():
		if id in SaveManager.active.get("comics", []) or id in placed or id in def.get("comics", []):
			continue
		extras.append(id)
	for k in mini(2, extras.size()):
		WorldProps.pickup(self, Vector2(1500 + k * 600, ground_y - 320), "comic", extras[k])
