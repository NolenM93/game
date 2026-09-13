extends CharacterBody3D

const FX = preload("res://scripts/hollow/hollow_fx.gd")
const Shot = preload("res://scripts/hollow/shot.gd")
const Pack = preload("res://scripts/hollow/pack.gd")
const PackUi = preload("res://scripts/hollow/pack_ui.gd")
const Loot = preload("res://scripts/hollow/loot.gd")

signal hp_changed(hp: int, max_hp: int)
signal loadout_changed

var world: Node
var cam_yaw := 0.0
var cam_zoom := 1.0
var pad_aiming := false
var last_aim := Vector3.ZERO
var aim_dot: Panel
var aim_ring: Panel
var aim_ui: CanvasLayer
var vis: Node3D
var camera: Camera3D
var gun_vis: Node3D
var hand: Node3D
var lamp: SpotLight3D
var gun_kick := 0.0
var hp := 6
var max_hp := 6
var i_frames := 0.0
var gun := 0
var build_on := false
var build_i := 0
var ammo := [8, 14, 6, 3]
var mag := [8, 14, 6, 3]
var fire_cd := 0.0
var reload_t := 0.0
var melee_cd := 0.0
var spawn := Vector3.ZERO
var ghost: MeshInstance3D
var names_gun := ["Squeaky Twelve", "Tomb Nailer", "Gloop-O-Matic", "Bottle Rocket"]
var names_build := ["Picket Fence", "Barbed Wire", "Jack Bomb", "Peckcrow", "Spike Crate"]
var icons_build := ["🪵", "⛓️", "🎃", "🐦", "🌵"]
var build_ids := ["fence", "wire", "jack", "turret", "spikes"]
var build_cost := [12, 16, 22, 40, 14]
var pack
var pack_ui
var last_held := ""
var leg_l: Node3D
var leg_r: Node3D
var arm_l: Node3D
var walk_t := 0.0


func _ready() -> void:
	add_to_group("hunter")
	collision_layer = 2
	collision_mask = 1 | 16
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(52.0)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.34
	cap.height = 1.55
	cs.shape = cap
	cs.position.y = 0.82
	add_child(cs)
	_look()
	_cam()
	pack = Pack.new()
	pack.changed.connect(_on_pack)
	pack_ui = PackUi.new()
	add_child(pack_ui)
	pack_ui.setup(self)
	spawn = global_position
	last_aim = global_position + Vector3(0, 0.9, 6.0)
	_play_mouse()
	hp_changed.emit(hp, max_hp)
	loadout_changed.emit()


func _look() -> void:
	vis = Node3D.new()
	add_child(vis)
	var coat := _mat(Color("3A3226"), 0.72)
	var lining := _mat(Color("5A2018"), 0.7)
	var pants := _mat(Color("1C1E1A"), 0.78)
	var skin := _mat(Color("C4A07A"), 0.55)
	var ink := _mat(Color("121214"), 0.5, 0.25)
	var strap := _mat(Color("1A140E"), 0.8)
	var rust := _mat(Color("6A3A22"), 0.55, 0.2)
	var boot := _mat(Color("141210"), 0.7)
	var lens := _mat(Color("FF8A3A"), 0.18, 0.35)
	lens.emission_enabled = true
	lens.emission = Color("FF6A1A")
	lens.emission_energy_multiplier = 2.6
	var glow := _mat(Color("FFB347"), 0.35)
	glow.emission_enabled = true
	glow.emission = Color("FF8A3A")
	glow.emission_energy_multiplier = 2.6
	_mesh(vis, BoxMesh.new(), Vector3(0, 0.86, 0.02), Vector3(0.42, 0.16, 0.28), pants)
	_mesh(vis, BoxMesh.new(), Vector3(0, 0.94, 0.03), Vector3(0.46, 0.07, 0.32), strap)
	_mesh(vis, BoxMesh.new(), Vector3(0.0, 0.94, 0.2), Vector3(0.1, 0.1, 0.08), rust)
	leg_l = Node3D.new()
	leg_l.position = Vector3(-0.13, 0.84, 0.02)
	vis.add_child(leg_l)
	_mesh(leg_l, CapsuleMesh.new(), Vector3(0, -0.2, 0.02), Vector3(0.18, 0.36, 0.2), pants)
	_mesh(leg_l, CapsuleMesh.new(), Vector3(0, -0.48, 0.04), Vector3(0.16, 0.3, 0.18), pants)
	_mesh(leg_l, BoxMesh.new(), Vector3(0, -0.7, 0.08), Vector3(0.2, 0.14, 0.34), boot)
	_mesh(leg_l, BoxMesh.new(), Vector3(0, -0.64, 0.22), Vector3(0.18, 0.06, 0.08), rust)
	leg_r = Node3D.new()
	leg_r.position = Vector3(0.13, 0.84, 0.02)
	vis.add_child(leg_r)
	_mesh(leg_r, CapsuleMesh.new(), Vector3(0, -0.2, 0.02), Vector3(0.18, 0.36, 0.2), pants)
	_mesh(leg_r, CapsuleMesh.new(), Vector3(0, -0.48, 0.04), Vector3(0.16, 0.3, 0.18), pants)
	_mesh(leg_r, BoxMesh.new(), Vector3(0, -0.7, 0.08), Vector3(0.2, 0.14, 0.34), boot)
	_mesh(leg_r, BoxMesh.new(), Vector3(0, -0.64, 0.22), Vector3(0.18, 0.06, 0.08), rust)
	_mesh(vis, BoxMesh.new(), Vector3(0, 1.18, 0.02), Vector3(0.4, 0.48, 0.26), _mat(Color("2A241C"), 0.75))
	_mesh(vis, BoxMesh.new(), Vector3(0, 1.16, -0.08), Vector3(0.5, 0.7, 0.16), coat)
	_mesh(vis, BoxMesh.new(), Vector3(-0.22, 0.78, 0.04), Vector3(0.16, 0.72, 0.28), coat)
	_mesh(vis, BoxMesh.new(), Vector3(0.22, 0.78, 0.04), Vector3(0.16, 0.72, 0.28), coat)
	_mesh(vis, BoxMesh.new(), Vector3(-0.18, 1.38, 0.12), Vector3(0.18, 0.12, 0.22), lining)
	_mesh(vis, BoxMesh.new(), Vector3(0.18, 1.38, 0.12), Vector3(0.18, 0.12, 0.22), lining)
	_mesh(vis, BoxMesh.new(), Vector3(0, 1.08, 0.16), Vector3(0.08, 0.28, 0.04), rust)
	_mesh(vis, BoxMesh.new(), Vector3(-0.18, 0.7, 0.16), Vector3(0.16, 0.16, 0.1), strap)
	_mesh(vis, BoxMesh.new(), Vector3(0.2, 0.7, 0.16), Vector3(0.14, 0.12, 0.1), strap)
	_mesh(vis, BoxMesh.new(), Vector3(0, 1.22, -0.28), Vector3(0.42, 0.48, 0.22), rust)
	_mesh(vis, CapsuleMesh.new(), Vector3(0, 1.46, -0.3), Vector3(0.4, 0.16, 0.18), _mat(Color("3A4630"), 0.85))
	_mesh(vis, BoxMesh.new(), Vector3(-0.16, 1.22, 0.02), Vector3(0.06, 0.06, 0.52), strap)
	_mesh(vis, BoxMesh.new(), Vector3(0.16, 1.22, 0.02), Vector3(0.06, 0.06, 0.52), strap)
	arm_l = Node3D.new()
	arm_l.position = Vector3(-0.3, 1.32, 0.04)
	vis.add_child(arm_l)
	_mesh(arm_l, SphereMesh.new(), Vector3(0, 0, 0), Vector3(0.16, 0.16, 0.16), coat)
	_mesh(arm_l, CapsuleMesh.new(), Vector3(-0.08, -0.18, 0.06), Vector3(0.16, 0.34, 0.16), coat)
	_mesh(arm_l, CapsuleMesh.new(), Vector3(-0.1, -0.4, 0.14), Vector3(0.14, 0.28, 0.14), coat)
	_mesh(arm_l, SphereMesh.new(), Vector3(-0.1, -0.54, 0.2), Vector3(0.13, 0.13, 0.14), ink)
	_mesh(vis, SphereMesh.new(), Vector3(0.3, 1.32, 0.04), Vector3(0.16, 0.16, 0.16), coat)
	_mesh(vis, CapsuleMesh.new(), Vector3(0.36, 1.16, 0.08), Vector3(0.16, 0.28, 0.16), coat)
	_mesh(vis, CapsuleMesh.new(), Vector3(0, 1.42, 0.03), Vector3(0.14, 0.12, 0.14), skin)
	_mesh(vis, SphereMesh.new(), Vector3(0, 1.58, 0.05), Vector3(0.38, 0.4, 0.38), skin)
	_mesh(vis, SphereMesh.new(), Vector3(0, 1.66, -0.04), Vector3(0.44, 0.28, 0.44), coat)
	_mesh(vis, BoxMesh.new(), Vector3(0, 1.54, -0.16), Vector3(0.4, 0.28, 0.18), coat)
	_mesh(vis, BoxMesh.new(), Vector3(0, 1.46, 0.08), Vector3(0.4, 0.06, 0.34), lining)
	_mesh(vis, BoxMesh.new(), Vector3(0, 1.56, 0.18), Vector3(0.34, 0.22, 0.16), ink)
	_mesh(vis, BoxMesh.new(), Vector3(0, 1.46, 0.26), Vector3(0.18, 0.14, 0.16), ink)
	_mesh(vis, SphereMesh.new(), Vector3(-0.09, 1.58, 0.26), Vector3(0.15, 0.12, 0.08), lens)
	_mesh(vis, SphereMesh.new(), Vector3(0.09, 1.58, 0.26), Vector3(0.15, 0.12, 0.08), lens)
	_mesh(vis, CylinderMesh.new(), Vector3(0.2, 1.48, 0.18), Vector3(0.1, 0.16, 0.1), rust, Vector3(0, 0, 70))
	_mesh(vis, BoxMesh.new(), Vector3(-0.16, 1.56, 0.02), Vector3(0.05, 0.05, 0.28), strap)
	_mesh(vis, BoxMesh.new(), Vector3(0.16, 1.56, 0.02), Vector3(0.05, 0.05, 0.28), strap)
	_mesh(vis, CylinderMesh.new(), Vector3(-0.28, 0.9, 0.16), Vector3(0.1, 0.06, 0.1), rust)
	_mesh(vis, SphereMesh.new(), Vector3(-0.28, 0.8, 0.16), Vector3(0.14, 0.14, 0.14), glow)
	hand = Node3D.new()
	hand.position = Vector3(0.42, 0.98, 0.32)
	vis.add_child(hand)
	_mesh(hand, CapsuleMesh.new(), Vector3(0.02, 0.04, -0.14), Vector3(0.15, 0.32, 0.15), coat)
	_mesh(hand, SphereMesh.new(), Vector3(0.02, 0.0, 0.1), Vector3(0.13, 0.13, 0.15), ink)
	gun_vis = Node3D.new()
	gun_vis.position = Vector3(0.02, 0.04, 0.18)
	hand.add_child(gun_vis)
	_rebuild_gun()
	lamp = SpotLight3D.new()
	lamp.position = Vector3(0.08, 1.5, 0.22)
	lamp.spot_range = 22.0
	lamp.spot_angle = 32.0
	lamp.light_energy = 2.1
	lamp.light_color = Color("FFE6B0")
	lamp.shadow_enabled = true
	lamp.rotation_degrees = Vector3(-6, 0, 0)
	vis.add_child(lamp)
	vis.rotation.y = 0.0


func _play_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _cam() -> void:
	camera = Camera3D.new()
	camera.fov = 46.0
	camera.near = 0.25
	camera.far = 900.0
	camera.current = true
	add_child(camera)
	_place_cam()
	ghost = MeshInstance3D.new()
	var gb := BoxMesh.new()
	gb.size = Vector3(1.6, 1.2, 0.4)
	ghost.mesh = gb
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.4, 1, 0.5, 0.35)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost.material_override = gm
	ghost.visible = false
	add_child(ghost)
	_aim_ui()


func _aim_ui() -> void:
	aim_ui = CanvasLayer.new()
	aim_ui.layer = 45
	aim_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(aim_ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aim_ui.add_child(root)
	aim_ring = _aim_mark(root, 18, Color(0.08, 0.06, 0.04, 0.15), Color("FFB347"))
	aim_dot = _aim_mark(root, 7, Color("FFB347"), Color("1A140E"))


func _aim_mark(root: Control, px: int, fill: Color, edge: Color) -> Panel:
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_anchors_preset(Control.PRESET_TOP_LEFT)
	p.size = Vector2(px, px)
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = edge
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(int(px * 0.5))
	p.add_theme_stylebox_override("panel", sb)
	root.add_child(p)
	return p


func _place_cam() -> void:
	if camera == null:
		return
	var z := cam_zoom
	if Input.is_action_pressed("aim_zoom"):
		z *= 0.82
	camera.position = Vector3(0.0, 22.0 * z, 16.8 * z)
	if camera.is_inside_tree():
		camera.look_at(global_position + Vector3(0, 0.75, 0), Vector3.UP)
		camera.fov = 46.0


func _rebuild_gun() -> void:
	if gun_vis == null:
		return
	for c in gun_vis.get_children():
		c.queue_free()
	var id := "gun_shotgun"
	if pack:
		id = str(pack.equipped().get("id", ""))
	match id:
		"gun_shotgun":
			_mesh(gun_vis, BoxMesh.new(), Vector3(0, 0.02, 0.38), Vector3(0.09, 0.12, 0.78), _mat(Color("3A2A1C")))
			_mesh(gun_vis, BoxMesh.new(), Vector3(0, -0.06, 0.02), Vector3(0.08, 0.2, 0.16), _mat(Color("1A140E")))
			_mesh(gun_vis, BoxMesh.new(), Vector3(0, 0.08, 0.18), Vector3(0.07, 0.08, 0.22), _mat(Color("5A4630")))
		"gun_nailer":
			_mesh(gun_vis, BoxMesh.new(), Vector3(0, 0.04, 0.5), Vector3(0.06, 0.06, 1.05), _mat(Color("4A5058")))
			_mesh(gun_vis, BoxMesh.new(), Vector3(0, -0.05, 0.02), Vector3(0.08, 0.18, 0.16), _mat(Color("1A140E")))
			_mesh(gun_vis, BoxMesh.new(), Vector3(0, 0.1, 0.22), Vector3(0.05, 0.08, 0.16), _mat(Color("2A2E34")))
		"gun_gloop":
			_mesh(gun_vis, SphereMesh.new(), Vector3(0, 0.06, 0.22), Vector3(0.28, 0.28, 0.4), _mat(Color("6AA84A")))
			_mesh(gun_vis, BoxMesh.new(), Vector3(0, 0.06, 0.52), Vector3(0.1, 0.1, 0.4), _mat(Color("3A4630")))
			_mesh(gun_vis, BoxMesh.new(), Vector3(0, -0.06, 0.0), Vector3(0.08, 0.16, 0.16), _mat(Color("1A140E")))
		"gun_rocket":
			_mesh(gun_vis, BoxMesh.new(), Vector3(0, 0.06, 0.42), Vector3(0.14, 0.14, 0.7), _mat(Color("C45A20")))
			_mesh(gun_vis, SphereMesh.new(), Vector3(0, 0.06, 0.08), Vector3(0.2, 0.2, 0.2), _mat(Color("FFB347")))
			_mesh(gun_vis, BoxMesh.new(), Vector3(0, -0.06, -0.02), Vector3(0.08, 0.16, 0.14), _mat(Color("1A140E")))
		"bat":
			_mesh(gun_vis, BoxMesh.new(), Vector3(0, 0.02, 0.42), Vector3(0.1, 0.1, 0.9), _mat(Color("C48A4A")))
			_mesh(gun_vis, BoxMesh.new(), Vector3(0, 0.02, 0.02), Vector3(0.14, 0.14, 0.18), _mat(Color("3A2A1C")))


func _unhandled_input(event: InputEvent) -> void:
	if pack_ui and pack_ui.open:
		return
	if event is InputEventMouseMotion:
		pad_aiming = false
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam_zoom = clampf(cam_zoom - 0.09, 0.7, 1.58)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam_zoom = clampf(cam_zoom + 0.09, 0.7, 1.58)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo:
		var i: int = int(event.physical_keycode) - KEY_1
		if i >= 0 and i <= 8:
			if build_on:
				_slot(clampi(i, 0, 4))
			elif pack:
				pack.selected = i
				pack.changed.emit()


func _slot(i: int) -> void:
	if build_on:
		build_i = clampi(i, 0, 4)
	else:
		gun = clampi(i, 0, 3)
		_rebuild_gun()
	loadout_changed.emit()
	AudioDirector.play("ui", 1.1)


func _physics_process(delta: float) -> void:
	i_frames = maxf(0.0, i_frames - delta)
	fire_cd = maxf(0.0, fire_cd - delta)
	reload_t = maxf(0.0, reload_t - delta)
	melee_cd = maxf(0.0, melee_cd - delta)
	if vis:
		vis.visible = i_frames <= 0.0 or fmod(i_frames, 0.1) > 0.05
	_update_pad_aim()
	_face_aim(delta)
	_walk_pose(delta)
	gun_kick = move_toward(gun_kick, 0.0, delta * 8.0)
	if hand:
		var aim := _aim_world()
		var dy := aim.y - hand.global_position.y
		var dxz := Vector2(aim.x - hand.global_position.x, aim.z - hand.global_position.z).length()
		hand.rotation.x = lerp_angle(hand.rotation.x, -atan2(dy, maxf(dxz, 0.15)) - deg_to_rad(18.0) * gun_kick, 0.35)
	_update_aim_dot()
	if lamp and world and world.has_method("lantern_frac"):
		var f: float = world.lantern_frac()
		lamp.light_energy = 2.1 if f > 0.3 else 1.1 + sin(Time.get_ticks_msec() * 0.02) * 0.7

	if Input.is_action_just_pressed("build_mode"):
		build_on = not build_on
		ghost.visible = build_on
		AudioDirector.play("confirm", 0.9)
		loadout_changed.emit()
	if Input.is_action_just_pressed("weap_next"):
		if build_on:
			_slot((build_i + 1) % 5)
		elif pack:
			pack.selected = (pack.selected + 1) % 9
			pack.changed.emit()
	if Input.is_action_just_pressed("weap_prev"):
		if build_on:
			_slot((build_i + 4) % 5)
		elif pack:
			pack.selected = (pack.selected + 8) % 9
			pack.changed.emit()
	if Input.is_action_just_pressed("reload"):
		_reload()
	if Input.is_action_just_pressed("drop_item"):
		drop_held()

	if not is_on_floor():
		velocity.y -= 24.0 * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = 8.2
		AudioDirector.play("jump", 0.95)

	if build_on:
		_update_ghost()
		if Input.is_action_just_pressed("shoot"):
			_place()
	else:
		ghost.visible = false
		if Input.is_action_pressed("shoot") and fire_cd <= 0.0 and reload_t <= 0.0:
			_fire()
		if Input.is_action_just_pressed("melee") and melee_cd <= 0.0:
			_melee()

	if not build_on and _gun_ammo() <= 0 and reload_t <= 0.0 and _holding_gun():
		_reload()

	var input := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	if input.length() > 1.0:
		input = input.normalized()
	var forward := _flat(-camera.global_transform.basis.z)
	var right := _flat(camera.global_transform.basis.x)
	var wish := right * input.x + forward * (-input.y)
	var spd := 7.4
	if wish.length() > 0.1:
		wish = wish.normalized()
		velocity.x = wish.x * spd
		velocity.z = wish.z * spd
	else:
		velocity.x = move_toward(velocity.x, 0.0, 28.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 28.0 * delta)
	move_and_slide()
	_place_cam()
	if global_position.y < -16.0:
		global_position = spawn
		velocity = Vector3.ZERO


func _on_pack() -> void:
	var it: Dictionary = pack.equipped() if pack else {}
	if str(it.get("kind", "")) == "gun":
		gun = int(it.get("gun", 0))
	var id := str(it.get("id", ""))
	if id != last_held:
		last_held = id
		_rebuild_gun()
	loadout_changed.emit()
	if pack_ui:
		pack_ui.refresh()


func _holding_gun() -> bool:
	return pack and str(pack.equipped().get("kind", "")) == "gun"


func _gun_ammo() -> int:
	if not _holding_gun():
		return 0
	return int(pack.equipped().get("ammo", 0))


func _held_name() -> String:
	if pack == null or Pack.blank(pack.equipped()):
		return "Empty"
	var it: Dictionary = pack.equipped()
	return "%s  %s" % [Pack.icon(it), str(it.get("name", "Item"))]


func take_loot(it: Dictionary) -> bool:
	if pack == null:
		return false
	if str(it.get("kind", "")) == "candy":
		if world:
			world.add_candy(int(it.get("count", 1)), global_position + Vector3(0, 1.2, 0))
		AudioDirector.play("confirm", 1.2)
		return true
	if pack.add(it):
		FX.float_text(get_parent(), global_position + Vector3(0, 1.4, 0), Pack.icon(it), Color("FFE27A"))
		AudioDirector.play("confirm", 1.15)
		return true
	FX.float_text(get_parent(), global_position + Vector3(0, 1.4, 0), "PACK FULL", Color("E24B4B"))
	return false


func drop_held() -> void:
	if pack == null:
		return
	var it: Dictionary = pack.drop_cursor_or_selected()
	if Pack.blank(it):
		return
	var loot = Loot.new()
	loot.setup(it)
	get_parent().add_child(loot)
	loot.global_position = global_position + facing() * 1.5 + Vector3(0, 0.55, 0)
	AudioDirector.play("ui", 0.7)


func _fire() -> void:
	if pack_ui and pack_ui.open:
		return
	var it: Dictionary = pack.equipped() if pack else {}
	if str(it.get("kind", "")) == "melee":
		if melee_cd <= 0.0:
			_melee()
		return
	if str(it.get("kind", "")) != "gun":
		return
	gun = int(it.get("gun", 0))
	if int(it.get("ammo", 0)) <= 0:
		_reload()
		return
	it["ammo"] = int(it["ammo"]) - 1
	if pack:
		pack.changed.emit()
	gun_kick = 1.0
	match gun:
		0:
			fire_cd = 0.68
			AudioDirector.play("shotgun", 1.0)
			for i in 7:
				_hitscan(0.09, 2, 5.5, Color("FFE6A0"))
		1:
			fire_cd = 0.15
			AudioDirector.play("shoot", 1.25)
			_hitscan(0.025, 4, 7.5, Color("D4FF8A"))
		2:
			fire_cd = 0.48
			AudioDirector.play("whoosh", 1.2)
			_lob("gloop", 18.0, 3)
		3:
			fire_cd = 0.82
			AudioDirector.play("whoom", 1.15)
			_lob("rocket", 22.0, 8)
	loadout_changed.emit()


func _muzzle() -> Vector3:
	if hand and vis:
		return hand.global_position + vis.global_transform.basis.z * 0.95
	return camera.global_position + (-camera.global_transform.basis.z * 0.8)


func _hitscan(spread: float, dmg: int, knock: float, color: Color) -> void:
	var dir := _shot_dir()
	var right := dir.cross(Vector3.UP)
	if right.length() < 0.05:
		right = dir.cross(Vector3.RIGHT)
	right = right.normalized()
	var up := right.cross(dir)
	dir = (dir + right * randf_range(-spread, spread) + up * randf_range(-spread, spread)).normalized()
	var from := _muzzle()
	var to := from + dir * 72.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1 | 4
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var end := to
	if hit:
		end = hit.position
		var n: Object = hit.get("collider")
		if n is Node and (n as Node).has_method("receive_shot"):
			(n as Node).receive_shot(hit.position, dir, dmg, knock, _held_name())
		FX.spark(get_parent(), end)
	FX.tracer(get_parent(), _muzzle(), end, color)


func _lob(kind: String, spd: float, dmg: int) -> void:
	var s = Shot.new()
	s.kind = kind
	s.dmg = dmg
	s.host = get_parent()
	s.vel = _shot_dir() * spd
	if kind == "rocket":
		s.vel += Vector3.UP * 2.4
	get_parent().add_child(s)
	s.global_position = _muzzle()


func _melee() -> void:
	melee_cd = 0.42
	AudioDirector.play("whoosh", 0.85)
	var origin := global_position + Vector3(0, 0.8, 0) + facing() * 1.1
	FX.burst(get_parent(), origin, Color("C0C6CC"), 6, 1.0)
	var sh := SphereShape3D.new()
	sh.radius = 1.35
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = sh
	q.transform = Transform3D(Basis(), origin)
	q.collision_mask = 4
	var hits := get_world_3d().direct_space_state.intersect_shape(q, 10)
	for h in hits:
		var n: Object = h.get("collider")
		if n is Node and (n as Node).has_method("receive_shot"):
			(n as Node).receive_shot(origin, facing(), 5, 9.0, "bat")
			FX.float_text(get_parent(), origin, "BONK!", Color("FFF6D8"))


func _reload() -> void:
	if reload_t > 0.0 or not _holding_gun():
		return
	var it: Dictionary = pack.equipped()
	var cap := int(it.get("mag", 8))
	if int(it.get("ammo", 0)) >= cap:
		return
	if pack.take("ammo", 1) <= 0:
		AudioDirector.play("ui", 0.55)
		return
	reload_t = 1.15
	it["ammo"] = cap
	AudioDirector.play("reload")
	pack.changed.emit()


func _update_ghost() -> void:
	if world == null or not world.has_method("snap_build"):
		return
	var p: Vector3 = world.snap_build(_aim_point())
	ghost.global_position = p + Vector3(0, 0.7, 0)
	ghost.visible = true
	var ok: bool = world.can_build(p, build_cost[build_i])
	var m: StandardMaterial3D = ghost.material_override
	m.albedo_color = Color(0.35, 1.0, 0.45, 0.4) if ok else Color(1.0, 0.25, 0.25, 0.4)


func _place() -> void:
	if world and world.has_method("try_build"):
		world.try_build(build_ids[build_i], _aim_point(), build_cost[build_i])


func _aim_point() -> Vector3:
	if pad_aiming:
		return Vector3(last_aim.x, 0.82, last_aim.z)
	return _cursor_ground()


func _flat(v: Vector3) -> Vector3:
	v.y = 0.0
	return v.normalized() if v.length() > 0.05 else Vector3.FORWARD


func _cursor_ground() -> Vector3:
	var hit := _cursor_hit(1 | 16 | 32)
	if not hit.is_empty():
		return hit.position
	return _cursor_plane()


func _aim_world() -> Vector3:
	if pad_aiming:
		return last_aim
	var hit := _cursor_hit(1 | 4 | 16 | 32)
	if not hit.is_empty():
		return hit.position
	return _cursor_plane()


func _cursor_hit(mask: int) -> Dictionary:
	if camera == null:
		return {}
	var from: Vector3
	var to: Vector3
	if pad_aiming:
		from = camera.global_position
		var d := last_aim - from
		if d.length() < 0.1:
			return {}
		to = from + d.normalized() * 420.0
	else:
		var mouse := get_viewport().get_mouse_position()
		from = camera.project_ray_origin(mouse)
		to = from + camera.project_ray_normal(mouse) * 420.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = mask
	q.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(q)


func _cursor_plane() -> Vector3:
	if camera == null:
		return global_position + Vector3(0, 0.9, 4.0)
	var mouse := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse)
	var dir := camera.project_ray_normal(mouse)
	if absf(dir.y) < 0.02:
		return global_position + facing() * 6.0 + Vector3(0, 0.9, 0)
	var t := (0.82 - from.y) / dir.y
	if t < 0.0:
		return global_position + facing() * 6.0 + Vector3(0, 0.9, 0)
	return from + dir * t


func _shot_dir() -> Vector3:
	var from := _muzzle()
	var world_pt := _aim_world()
	var dest := world_pt
	if world_pt.y < global_position.y + 0.55:
		dest.y = from.y
	var d := dest - from
	if d.length() < 0.25:
		return facing()
	return d.normalized()


func _update_pad_aim() -> void:
	var look := Vector2(Input.get_axis("aim_left", "aim_right"), Input.get_axis("aim_up", "aim_down"))
	if look.length() < 0.22:
		return
	pad_aiming = true
	var dir := _flat(camera.global_transform.basis.x) * look.x + _flat(-camera.global_transform.basis.z) * (-look.y)
	if dir.length() < 0.1:
		return
	last_aim = global_position + dir.normalized() * 14.0 + Vector3(0, 0.95, 0)


func _face_aim(delta: float) -> void:
	if vis == null:
		return
	var aim := _aim_world()
	var dx := aim.x - global_position.x
	var dz := aim.z - global_position.z
	if Vector2(dx, dz).length() < 0.4:
		return
	vis.rotation.y = lerp_angle(vis.rotation.y, atan2(dx, dz), 1.0 - pow(0.0005, delta))
	cam_yaw = vis.rotation.y


func facing() -> Vector3:
	if vis:
		var f := vis.global_transform.basis.z
		f.y = 0.0
		if f.length() > 0.05:
			return f.normalized()
	return Vector3.FORWARD


func receive_hit(source: Node3D, dmg: int, knock: float) -> void:
	if i_frames > 0.0:
		return
	hp = maxi(0, hp - dmg)
	i_frames = 0.95
	var away := global_position - source.global_position
	away.y = 0.0
	if away.length() > 0.05:
		velocity = away.normalized() * knock
	velocity.y = 4.0
	AudioDirector.play("hurt", 1.0)
	if hp <= 0:
		hp = max_hp
		i_frames = 1.8
		global_position = spawn
		velocity = Vector3.ZERO
		if world and world.has_method("player_down"):
			world.player_down()
	hp_changed.emit(hp, max_hp)


func _update_aim_dot() -> void:
	if aim_dot == null or aim_ring == null or camera == null:
		return
	var show := true
	if pack_ui and pack_ui.open:
		show = false
	if build_on:
		show = false
	aim_dot.visible = show
	aim_ring.visible = show
	if not show:
		return
	var mp := get_viewport().get_mouse_position()
	if pad_aiming:
		mp = camera.unproject_position(_aim_world())
	aim_dot.position = mp - aim_dot.size * 0.5
	aim_ring.position = mp - aim_ring.size * 0.5
	var hit := _cursor_hit(1 | 4 | 16 | 32)
	var fill := Color("FFB347")
	var edge := Color("1A140E")
	if hit:
		var n: Object = hit.get("collider")
		if n is Node and (n as Node).is_in_group("zed"):
			fill = Color("E24B4B")
			edge = Color("FFF6D8")
		elif n is Node and (n as Node).is_in_group("hunter"):
			fill = Color("FFE27A")
	_paint_aim(aim_dot, 7, fill, edge)
	_paint_aim(aim_ring, 18, Color(fill.r, fill.g, fill.b, 0.12), fill)


func _paint_aim(p: Panel, px: int, fill: Color, edge: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = edge
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(int(px * 0.5))
	p.add_theme_stylebox_override("panel", sb)


func _walk_pose(delta: float) -> void:
	var spd := Vector2(velocity.x, velocity.z).length()
	if spd > 0.7 and is_on_floor():
		walk_t += delta * clampf(spd * 1.7, 4.0, 11.0)
	else:
		walk_t = move_toward(walk_t, 0.0, delta * 6.0)
	var swing := sin(walk_t) * (0.55 if spd > 0.7 else 0.0)
	if vis:
		vis.position.y = absf(sin(walk_t)) * (0.045 if spd > 0.7 else 0.0)
	if leg_l:
		leg_l.rotation.x = swing
	if leg_r:
		leg_r.rotation.x = -swing
	if arm_l:
		arm_l.rotation.x = -swing * 0.7


func _mat(c: Color, rough: float = 0.62, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	m.rim_enabled = true
	m.rim = 0.28
	return m


func _mesh(parent: Node3D, mesh: PrimitiveMesh, pos: Vector3, sc: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	if mesh is SphereMesh:
		(mesh as SphereMesh).radius = 0.5
		(mesh as SphereMesh).height = 1.0
	elif mesh is CapsuleMesh:
		(mesh as CapsuleMesh).radius = 0.5
		(mesh as CapsuleMesh).height = 1.4
	elif mesh is BoxMesh:
		(mesh as BoxMesh).size = Vector3.ONE
	elif mesh is CylinderMesh:
		(mesh as CylinderMesh).top_radius = 0.5
		(mesh as CylinderMesh).bottom_radius = 0.5
		(mesh as CylinderMesh).height = 1.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.scale = sc
	mi.rotation_degrees = rot
	mi.material_override = mat
	parent.add_child(mi)
	return mi
