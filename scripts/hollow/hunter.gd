extends CharacterBody3D

const FX = preload("res://scripts/hollow/hollow_fx.gd")
const Shot = preload("res://scripts/hollow/shot.gd")
const Pack = preload("res://scripts/hollow/pack.gd")
const PackUi = preload("res://scripts/hollow/pack_ui.gd")
const Loot = preload("res://scripts/hollow/loot.gd")
const Build = preload("res://scripts/hollow/buildable.gd")
const GunArt = preload("res://scripts/hollow/gun_art.gd")

signal hp_changed(hp: int, max_hp: int)
signal loadout_changed

const CAM_OFFSET := Vector3(0.0, 16.4, 12.0)
const GROUND_Y := 0.72
const ZOOM_MIN := 0.7
const ZOOM_MAX := 1.45
const TOP_FOV := 48.0
const FP_FOV := 75.0
const HAND_HIP := Vector3(0.42, 0.98, 0.32)
const HAND_FP := Vector3(0.34, 1.20, 0.52)
const BODY_LAYER := 2
const STEP_HEIGHT := 0.72
const WALK_SPEED := 6.9
const GRAVITY := 32.0
const JUMP_VEL := 9.15

var world: Node
var locked := false
var cam_yaw := 0.0
var cam_pitch := 0.18
var cam_zoom := 1.1
var cam_focus := Vector3.ZERO
var trauma := 0.0
var first_person := false
var fp_fov := FP_FOV
var pad_aiming := false
var pad_dir := Vector3(0, 0, 1)
var pad_mag := 0.0
var _shoot_held := false
# Aim solution, refreshed every physics tick.
var aim_target: Node3D = null
var aim_pos := Vector3.ZERO
var aim_ground := Vector3.ZERO
var aim_assisted := false
var last_aim := Vector3.ZERO
var aim_dot: Panel
var aim_ring: Panel
var aim_ui: CanvasLayer
var ring3d: MeshInstance3D
var lock_ring: MeshInstance3D
var vignette: ColorRect
var vig_mat: ShaderMaterial
var hurt_flash := 0.0
var vis: Node3D
var camera: Camera3D
var gun_vis: Node3D
var hand: Node3D
var lamp: SpotLight3D
var own_light: OmniLight3D
var flash_light: OmniLight3D
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
var ghost: Node3D
var ghost_mat: StandardMaterial3D
var ghost_kind := ""
var names_gun := ["Trench Gun", "Tommy Gun", "M1 Garand", "Bazooka", "Kar98k", "Ray Gun", "MP40"]
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
var stride := 0
var foot_ring: MeshInstance3D
var perks := {"jug": false, "speed": false, "double": false, "revive": false}


func _ready() -> void:
	InputSetup.ensure()
	set_process_input(true)
	add_to_group("hunter")
	collision_layer = 2
	collision_mask = 1 | 16 | 32
	floor_snap_length = 0.9
	floor_max_angle = deg_to_rad(62.0)
	safe_margin = 0.06
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
	aim_ground = global_position + Vector3(0, 0, -6.0)
	aim_pos = aim_ground + Vector3(0, 0.6, 0)
	last_aim = aim_pos
	if InputSetup.pad_connected():
		pad_aiming = true
	first_person = Settings.first_person
	_apply_view()
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
	hand.position = HAND_HIP
	vis.add_child(hand)
	_mesh(hand, CapsuleMesh.new(), Vector3(0.02, 0.04, -0.14), Vector3(0.15, 0.32, 0.15), coat)
	_mesh(hand, SphereMesh.new(), Vector3(0.02, 0.0, 0.1), Vector3(0.13, 0.13, 0.15), ink)
	gun_vis = Node3D.new()
	gun_vis.position = Vector3(0.02, 0.04, 0.18)
	hand.add_child(gun_vis)
	_rebuild_gun()
	flash_light = OmniLight3D.new()
	flash_light.position = Vector3(0.02, 0.08, 1.0)
	flash_light.light_color = Color("FFC46A")
	flash_light.light_energy = 0.0
	flash_light.omni_range = 7.0
	flash_light.shadow_enabled = false
	hand.add_child(flash_light)
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
	# Personal glow so the hunter always reads from the overhead camera.
	own_light = OmniLight3D.new()
	own_light.position = Vector3(0, 1.7, 0)
	own_light.light_color = Color("FFD9A0")
	own_light.light_energy = 1.25
	own_light.omni_range = 6.0
	own_light.shadow_enabled = false
	add_child(own_light)
	foot_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.46
	tm.outer_radius = 0.56
	tm.rings = 32
	tm.ring_segments = 8
	foot_ring.mesh = tm
	foot_ring.position = Vector3(0, 0.06, 0)
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(0.6, 0.92, 0.5, 0.5)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	foot_ring.material_override = rm
	foot_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(foot_ring)


func _play_mouse() -> void:
	_sync_mouse()


func _sync_mouse() -> void:
	if pack_ui and pack_ui.open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if world != null and bool(world.get("over")):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if first_person:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_sync_mouse()


func _cam() -> void:
	camera = Camera3D.new()
	camera.top_level = true
	camera.fov = 48.0
	camera.near = 0.3
	camera.far = 900.0
	camera.current = true
	add_child(camera)
	cam_focus = global_position + Vector3(0, 0.75, 0)
	camera.global_position = cam_focus + CAM_OFFSET
	camera.look_at(cam_focus, Vector3.UP)
	ghost = Node3D.new()
	ghost.top_level = true
	ghost.visible = false
	add_child(ghost)
	ghost_mat = StandardMaterial3D.new()
	ghost_mat.albedo_color = Color(0.4, 1, 0.5, 0.42)
	ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring3d = _ground_ring(0.34, 0.42, Color(1.0, 0.7, 0.28, 0.75))
	lock_ring = _ground_ring(0.5, 0.62, Color(0.92, 0.3, 0.3, 0.85))
	_aim_ui()


func _ground_ring(inner: float, outer: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.top_level = true
	var tm := TorusMesh.new()
	tm.inner_radius = inner
	tm.outer_radius = outer
	tm.rings = 36
	tm.ring_segments = 6
	mi.mesh = tm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = true
	m.render_priority = 2
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	add_child(mi)
	return mi


func _aim_ui() -> void:
	aim_ui = CanvasLayer.new()
	aim_ui.layer = 45
	aim_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(aim_ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aim_ui.add_child(root)
	vignette = ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(0.72, 0.05, 0.04, 1.0);
void fragment() {
	vec2 d = UV - vec2(0.5);
	d.x *= 1.35;
	float v = smoothstep(0.22, 0.78, length(d) * 1.35);
	COLOR = vec4(tint.rgb, v * amount);
}
"""
	vig_mat = ShaderMaterial.new()
	vig_mat.shader = sh
	vig_mat.set_shader_parameter("amount", 0.0)
	vignette.material = vig_mat
	root.add_child(vignette)
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


func shake(amount: float) -> void:
	trauma = minf(1.0, trauma + amount)


func _toggle_view() -> void:
	first_person = not first_person
	Settings.first_person = first_person
	Settings.save_settings()
	if first_person:
		cam_yaw = vis.rotation.y if vis else cam_yaw
		cam_pitch = 0.18
		fp_fov = FP_FOV
	else:
		cam_focus = global_position + Vector3(0, 0.75, 0)
	_apply_view()
	AudioDirector.play("confirm", 1.15 if first_person else 0.85)
	if world and world.has_method("_show"):
		world._show("FIRST PERSON" if first_person else "OVERHEAD")


func _apply_view() -> void:
	if camera:
		if first_person:
			camera.fov = fp_fov
			camera.near = 0.05
			camera.cull_mask = 0xFFFFF & ~BODY_LAYER
		else:
			camera.fov = TOP_FOV
			camera.near = 0.3
			camera.cull_mask = 0xFFFFF
	if hand:
		hand.position = HAND_FP if first_person else HAND_HIP
	if foot_ring:
		foot_ring.visible = not first_person
	if own_light:
		own_light.visible = not first_person
	_set_body_layer(BODY_LAYER if first_person else 1)
	_sync_mouse()


func _set_body_layer(layer: int) -> void:
	if vis == null:
		return
	_geom_layer(vis, layer, hand)


func _geom_layer(n: Node, layer: int, skip: Node) -> void:
	if n == skip:
		return
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).layers = layer
	for c in n.get_children():
		_geom_layer(c, layer, skip)


func _place_cam(delta: float) -> void:
	if camera == null:
		return
	if first_person:
		_place_cam_fp(delta)
		return
	var z := cam_zoom
	if Input.is_action_pressed("aim_zoom"):
		z *= 0.84
	var want := global_position + Vector3(0, 0.75, 0) + _cam_lead()
	cam_focus = cam_focus.lerp(want, 1.0 - pow(0.0001, delta))
	trauma = maxf(0.0, trauma - delta * 1.7)
	var sh := trauma * trauma * clampf(Settings.shake, 0.0, 1.5)
	var t := Time.get_ticks_msec() * 0.001
	var off := Vector3(sin(t * 41.0) * 0.55, sin(t * 53.0 + 1.3) * 0.4, cos(t * 47.0 + 0.7) * 0.35) * sh
	camera.global_position = cam_focus + CAM_OFFSET * z + off
	camera.look_at(cam_focus + off * 0.35, Vector3.UP)


func _place_cam_fp(delta: float) -> void:
	if pack_ui == null or not pack_ui.open:
		var look := Vector2(Input.get_axis("aim_left", "aim_right"), Input.get_axis("aim_up", "aim_down"))
		if look.length() >= 0.18:
			pad_aiming = true
			cam_yaw -= look.x * 2.5 * delta
			var inv := -1.0 if Settings.invert_fly else 1.0
			cam_pitch = clampf(cam_pitch + look.y * 2.1 * delta * inv, deg_to_rad(-68.0), deg_to_rad(72.0))
	if vis:
		vis.rotation.y = cam_yaw
	var want_fov := 54.0 if Input.is_action_pressed("aim_zoom") else fp_fov
	camera.fov = lerpf(camera.fov, want_fov, 1.0 - pow(0.0004, delta))
	trauma = maxf(0.0, trauma - delta * 1.7)
	var sh := trauma * trauma * clampf(Settings.shake, 0.0, 1.5)
	var t := Time.get_ticks_msec() * 0.001
	var bob := 0.0
	var spd := Vector2(velocity.x, velocity.z).length()
	if spd > 0.7 and is_on_floor():
		bob = sin(walk_t) * 0.035
	var eye := global_position + Vector3(0, 1.52 + bob, 0)
	var face := Vector3(sin(cam_yaw), 0.0, cos(cam_yaw))
	eye += face * 0.12
	var right := Vector3.UP.cross(face)
	if right.length() < 0.05:
		right = Vector3.RIGHT
	else:
		right = right.normalized()
	var look_dir := face.rotated(right, cam_pitch)
	var off := Vector3(sin(t * 41.0) * 0.08, sin(t * 53.0 + 1.3) * 0.07, cos(t * 47.0 + 0.7) * 0.06) * sh
	camera.global_position = eye + off
	if look_dir.length() > 0.05:
		camera.look_at(eye + look_dir, Vector3.UP)


func _cam_lead() -> Vector3:
	if camera == null or locked:
		return Vector3.ZERO
	var f := _flat(-camera.global_transform.basis.z)
	var r := _flat(camera.global_transform.basis.x)
	if pad_aiming:
		return pad_dir * (2.2 * pad_mag)
	var vp := get_viewport().get_visible_rect().size
	if vp.x < 1.0 or vp.y < 1.0:
		return Vector3.ZERO
	var m := get_viewport().get_mouse_position()
	var n := (m - vp * 0.5) / (vp * 0.5)
	n = n.limit_length(1.0)
	# Ease-in so small cursor motions near the hunter barely move the view, while pushing
	# the cursor toward a screen edge reveals ~2.6 m more in that direction.
	var k := n.length() * n.length()
	return (r * n.x + f * (-n.y)) * (2.6 * k / maxf(n.length(), 0.001))


func _rebuild_gun() -> void:
	if gun_vis == null:
		return
	for c in gun_vis.get_children():
		c.queue_free()
	var id := "gun_shotgun"
	if pack:
		id = str(pack.equipped().get("id", ""))
	if id == "":
		return
	GunArt.attach(gun_vis, id)


func _input(event: InputEvent) -> void:
	if pack_ui and pack_ui.open:
		return
	if event.is_echo():
		return
	var tap := false
	if event is InputEventKey and event.pressed:
		var k: int = event.keycode
		var p: int = event.physical_keycode
		if k == KEY_F or p == KEY_F or k == KEY_F5 or p == KEY_F5:
			tap = true
	if InputMap.has_action("camera_mode") and event.is_action_pressed("camera_mode"):
		tap = true
	if tap:
		_toggle_view()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if pack_ui and pack_ui.open:
		return
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event is InputEventJoypadMotion and absf(event.axis_value) < 0.28:
			pass
		else:
			pad_aiming = true
	if first_person and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pad_aiming = false
		var sens := 0.00205
		cam_yaw -= event.relative.x * sens
		var inv := -1.0 if Settings.invert_fly else 1.0
		cam_pitch = clampf(cam_pitch + event.relative.y * sens * inv, deg_to_rad(-68.0), deg_to_rad(72.0))
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and event.relative.length() > 3.5:
		pad_aiming = false
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if first_person:
				fp_fov = clampf(fp_fov - 4.0, 58.0, 92.0)
			else:
				cam_zoom = clampf(cam_zoom - 0.09, ZOOM_MIN, ZOOM_MAX)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if first_person:
				fp_fov = clampf(fp_fov + 4.0, 58.0, 92.0)
			else:
				cam_zoom = clampf(cam_zoom + 0.09, ZOOM_MIN, ZOOM_MAX)
			get_viewport().set_input_as_handled()
			return
		pad_aiming = false
	if locked:
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
	hurt_flash = maxf(0.0, hurt_flash - delta * 1.6)
	if vis:
		if first_person:
			vis.visible = true
		else:
			vis.visible = i_frames <= 0.0 or fmod(i_frames, 0.12) > 0.05
	_update_aim()
	_face_aim(delta)
	_walk_pose(delta)
	gun_kick = move_toward(gun_kick, 0.0, delta * 8.0)
	if flash_light:
		flash_light.light_energy = maxf(0.0, flash_light.light_energy - delta * 60.0)
	if hand:
		var dy := aim_pos.y - hand.global_position.y
		var dxz := Vector2(aim_pos.x - hand.global_position.x, aim_pos.z - hand.global_position.z).length()
		hand.rotation.x = lerp_angle(hand.rotation.x, -atan2(dy, maxf(dxz, 0.15)) - deg_to_rad(18.0) * gun_kick, 0.35)
	_update_aim_dot()
	_update_reticle()
	_update_vignette()
	if lamp and world and world.has_method("lantern_frac"):
		var f: float = world.lantern_frac()
		lamp.light_energy = 2.1 if f > 0.3 else 1.1 + sin(Time.get_ticks_msec() * 0.02) * 0.7

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if locked:
		velocity.x = 0.0
		velocity.z = 0.0
		ghost.visible = false
		move_and_slide()
		_place_cam(delta)
		return

	if Input.is_action_just_pressed("build_mode"):
		build_on = not build_on
		ghost.visible = build_on
		if world and world.has_method("show_build_zone"):
			world.show_build_zone(build_on)
		AudioDirector.play("confirm", 0.9)
		loadout_changed.emit()
	if Input.is_action_just_pressed("weap_next") or Input.is_action_just_pressed("bar_right"):
		if build_on:
			_slot((build_i + 1) % 5)
		elif pack:
			pack.selected = (pack.selected + 1) % 9
			pack.changed.emit()
	if Input.is_action_just_pressed("weap_prev") or Input.is_action_just_pressed("bar_left"):
		if build_on:
			_slot((build_i + 4) % 5)
		elif pack:
			pack.selected = (pack.selected + 8) % 9
			pack.changed.emit()
	if Input.is_action_pressed("zoom_in"):
		if first_person:
			fp_fov = move_toward(fp_fov, 58.0, delta * 28.0)
		else:
			cam_zoom = move_toward(cam_zoom, ZOOM_MIN, delta * 0.9)
	if Input.is_action_pressed("zoom_out"):
		if first_person:
			fp_fov = move_toward(fp_fov, 92.0, delta * 28.0)
		else:
			cam_zoom = move_toward(cam_zoom, ZOOM_MAX, delta * 0.9)
	if Input.is_action_just_pressed("reload"):
		_reload()
	if Input.is_action_just_pressed("drop_item"):
		drop_held()

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VEL
		AudioDirector.play("jump", 0.95)

	var shoot_now := Input.is_action_pressed("shoot")
	var shoot_tap := shoot_now and not _shoot_held
	_shoot_held = shoot_now
	if build_on:
		_update_ghost()
		if shoot_tap:
			_place()
	else:
		ghost.visible = false
		if shoot_now and fire_cd <= 0.0 and reload_t <= 0.0:
			_fire()
		if Input.is_action_just_pressed("melee") and melee_cd <= 0.0:
			_melee()

	if not build_on and _gun_ammo() <= 0 and reload_t <= 0.0 and _holding_gun():
		_reload()

	var input := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	if input.length() < 0.22:
		input = Vector2.ZERO
	elif input.length() > 1.0:
		input = input.normalized()
	var forward := _flat(-camera.global_transform.basis.z)
	var right := _flat(camera.global_transform.basis.x)
	var wish := right * input.x + forward * (-input.y)
	if wish.length() > 0.1:
		wish = wish.normalized()
		velocity.x = wish.x * WALK_SPEED
		velocity.z = wish.z * WALK_SPEED
		if is_on_floor():
			_step_up(wish)
			_stair_follow(wish)
	elif is_on_floor():
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()
	_footsteps()
	_place_cam(delta)
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
	var kind := str(it.get("kind", ""))
	if kind == "candy":
		if world:
			world.add_candy(int(it.get("count", 1)), global_position + Vector3(0, 1.2, 0))
		AudioDirector.play("pickup", 1.1)
		return true
	if pack.add(it):
		FX.float_text(get_parent(), global_position + Vector3(0, 1.4, 0), Pack.icon(it), Color("FFE27A"))
		AudioDirector.play("pickup", 1.0)
		return true
	if kind == "heal":
		heal(2 * int(it.get("count", 1)))
		AudioDirector.play("pickup", 1.2)
		return true
	if kind == "oil":
		if world and world.keep and world.keep.has_method("heal"):
			world.keep.heal(18 * int(it.get("count", 1)))
		AudioDirector.play("pickup", 0.85)
		return true
	FX.float_text(get_parent(), global_position + Vector3(0, 1.4, 0), "PACK FULL", Color("E24B4B"))
	return false


func heal(n: int) -> void:
	var before := hp
	hp = mini(max_hp, hp + n)
	if hp > before:
		FX.float_text(get_parent(), global_position + Vector3(0, 1.5, 0), "+%d ♥" % (hp - before), Color("E56BA0"), 36)
		hp_changed.emit(hp, max_hp)


func has_perk(id: String) -> bool:
	return bool(perks.get(id, false))


func give_perk(id: String) -> void:
	perks[id] = true
	if id == "jug":
		max_hp = 10
		hp = max_hp
		hp_changed.emit(hp, max_hp)
	if world and world.has_method("_refresh"):
		world._refresh()
	loadout_changed.emit()


func perk_line() -> String:
	var bits: PackedStringArray = []
	if has_perk("jug"):
		bits.append("Punch")
	if has_perk("speed"):
		bits.append("Rush")
	if has_perk("double"):
		bits.append("Tap")
	if has_perk("revive"):
		bits.append("Revive")
	return "  ".join(bits)


func fill_all_ammo() -> void:
	if pack == null:
		return
	for arr in [pack.bar, pack.bag]:
		for it in arr:
			if str(it.get("kind", "")) == "gun":
				it["ammo"] = int(it.get("mag", 8))
	pack.add(Pack.make("ammo", 24))
	pack.changed.emit()


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
	if str(it.get("kind", "")) == "heal" or str(it.get("kind", "")) == "oil":
		_use_item(it)
		return
	if str(it.get("kind", "")) != "gun":
		return
	gun = int(it.get("gun", 0))
	if int(it.get("ammo", 0)) <= 0:
		_reload()
		return
	it["ammo"] = int(it["ammo"]) - 1
	_snap_face()
	if pack:
		pack.changed.emit()
	gun_kick = 1.0
	match gun:
		0:
			fire_cd = 0.68
			AudioDirector.play("shotgun", randf_range(0.95, 1.05))
			for i in 7:
				_hitscan(0.075, 0.035, 2, 5.5, Color("FFE6A0"))
			shake(0.32)
			_muzzle_flash(1.0)
			InputSetup.rumble(0.25, 0.55, 0.12)
		1:
			fire_cd = 0.15
			AudioDirector.play("shoot", randf_range(1.15, 1.3))
			_hitscan(0.012, 0.008, 4, 7.5, Color("E8D0A0"), "nailer")
			shake(0.1)
			_muzzle_flash(0.5)
			InputSetup.rumble(0.1, 0.2, 0.06)
		2:
			fire_cd = 0.42
			AudioDirector.play("shoot", randf_range(0.85, 0.95))
			_hitscan(0.008, 0.005, 8, 9.0, Color("E8DCC0"))
			shake(0.16)
			_muzzle_flash(0.7)
			InputSetup.rumble(0.18, 0.28, 0.08)
		3:
			fire_cd = 0.82
			AudioDirector.play("whoom", 1.15)
			_lob("rocket", 22.0, 8)
			shake(0.3)
			_muzzle_flash(0.8)
			InputSetup.rumble(0.3, 0.5, 0.14)
		4:
			fire_cd = 0.95
			AudioDirector.play("shoot", randf_range(0.55, 0.65))
			_hitscan(0.004, 0.003, 14, 11.0, Color("E8DCC0"), "stake")
			shake(0.28)
			_muzzle_flash(0.7)
			InputSetup.rumble(0.2, 0.45, 0.1)
		5:
			fire_cd = 0.22
			AudioDirector.play("whoom", 1.35)
			var zed: Node = _hitscan(0.006, 0.004, 7, 8.0, Color("FF6A22"), "hex")
			if zed is Node3D:
				FX.flash(get_parent(), (zed as Node3D).global_position, Color("C040E8"), 6.0, 5.0, 0.18)
				FX.burst(get_parent(), (zed as Node3D).global_position + Vector3(0, 0.8, 0), Color("C040E8"), 8, 1.4)
			shake(0.12)
			_muzzle_flash(0.9)
			InputSetup.rumble(0.16, 0.25, 0.07)
		6:
			fire_cd = 0.11
			AudioDirector.play("shoot", randf_range(1.25, 1.4))
			_hitscan(0.018, 0.012, 4, 5.5, Color("D8C8A0"))
			shake(0.08)
			_muzzle_flash(0.4)
			InputSetup.rumble(0.08, 0.16, 0.05)
	if has_perk("double"):
		fire_cd *= 0.58
	loadout_changed.emit()


func _use_item(it: Dictionary) -> void:
	var kind := str(it.get("kind", ""))
	if kind == "heal":
		if hp >= max_hp:
			return
		heal(2)
	elif kind == "oil":
		if world == null or world.keep == null or not world.keep.has_method("heal"):
			return
		if int(world.keep.get("hp")) >= int(world.keep.get("max_hp")):
			return
		world.keep.heal(18)
	else:
		return
	fire_cd = 0.35
	it["count"] = int(it.get("count", 1)) - 1
	if int(it["count"]) <= 0 and pack:
		pack.bar[pack.selected] = {}
	if pack:
		pack.changed.emit()
	AudioDirector.play("confirm", 1.05)
	loadout_changed.emit()


func _muzzle_flash(amt: float) -> void:
	if flash_light:
		flash_light.light_energy = 5.5 * amt
	FX.burst(get_parent(), _muzzle(), Color("FFE6A0"), int(3 + 4 * amt), 0.9)


func _muzzle() -> Vector3:
	if hand and vis:
		return hand.global_position + vis.global_transform.basis.z * 0.95
	return camera.global_position + (-camera.global_transform.basis.z * 0.8)


func _hitscan(spread_h: float, spread_v: float, dmg: int, knock: float, color: Color, style: String = "") -> Node:
	var dir := _shot_dir()
	var right := dir.cross(Vector3.UP)
	if right.length() < 0.05:
		right = dir.cross(Vector3.RIGHT)
	right = right.normalized()
	var up := right.cross(dir)
	dir = (dir + right * randf_range(-spread_h, spread_h) + up * randf_range(-spread_v, spread_v)).normalized()
	var from := _muzzle()
	var to := from + dir * 72.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1 | 4
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var end := to
	var struck: Node = null
	if hit:
		end = hit.position
		var n: Object = hit.get("collider")
		if n is Node and (n as Node).has_method("receive_shot"):
			struck = n as Node
			struck.receive_shot(hit.position, dir, dmg, knock, style)
		else:
			FX.spark(get_parent(), end)
	FX.tracer(get_parent(), from, end, color)
	return struck


func _lob(kind: String, spd: float, dmg: int) -> void:
	var s = Shot.new()
	s.kind = kind
	s.dmg = dmg
	s.host = get_parent()
	var from := _muzzle()
	if kind == "rocket" or kind == "hex":
		var dest := aim_pos
		if aim_target == null:
			dest = aim_ground + Vector3(0, 0.25, 0)
		s.vel = _ballistic(from, dest, spd, 10.0 if kind == "hex" else 16.0)
	else:
		s.vel = _shot_dir() * spd
	get_parent().add_child(s)
	s.global_position = from


func _ballistic(from: Vector3, to: Vector3, spd: float, g: float) -> Vector3:
	var flat := Vector3(to.x - from.x, 0.0, to.z - from.z)
	var d := flat.length()
	var h := to.y - from.y
	var dir := flat.normalized() if d > 0.05 else facing()
	var v2 := spd * spd
	var disc := v2 * v2 - g * (g * d * d + 2.0 * h * v2)
	var ang := deg_to_rad(45.0)
	if disc >= 0.0 and d > 0.05:
		ang = atan2(v2 - sqrt(disc), g * d)
	return dir * cos(ang) * spd + Vector3.UP * sin(ang) * spd


func _melee() -> void:
	melee_cd = 0.42
	_snap_face()
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
	var landed := false
	for h in hits:
		var n: Object = h.get("collider")
		if n is Node and (n as Node).has_method("receive_shot"):
			(n as Node).receive_shot(origin, facing(), 5, 9.0, "bat")
			landed = true
	if landed:
		FX.float_text(get_parent(), origin, "BONK!", Color("FFF6D8"))
		shake(0.22)
		InputSetup.rumble(0.3, 0.4, 0.1)


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
	reload_t = 0.42 if has_perk("speed") else 1.15
	it["ammo"] = cap
	AudioDirector.play("reload")
	pack.changed.emit()


func _update_ghost() -> void:
	if world == null or not world.has_method("snap_build"):
		return
	var kind: String = build_ids[build_i]
	if ghost_kind != kind:
		_make_ghost(kind)
	var p: Vector3 = world.snap_build(_aim_point())
	ghost.global_position = p
	ghost.rotation.y = build_yaw()
	ghost.visible = true
	var ok: bool = world.can_build(p, build_cost[build_i])
	ghost_mat.albedo_color = Color(0.35, 1.0, 0.45, 0.42) if ok else Color(1.0, 0.25, 0.25, 0.42)


func _make_ghost(kind: String) -> void:
	ghost_kind = kind
	for c in ghost.get_children():
		c.queue_free()
	var b = Build.new()
	b.kind = kind
	b.ghost_mat = ghost_mat
	var v: Node3D = b.ghost_vis()
	b.free()
	ghost.add_child(v)


func build_yaw() -> float:
	if vis == null:
		return 0.0
	return snappedf(vis.rotation.y, PI / 4.0)


func _place() -> void:
	if world and world.has_method("try_build"):
		world.try_build(build_ids[build_i], _aim_point(), build_cost[build_i])


func _aim_point() -> Vector3:
	return aim_ground


func _step_up(dir: Vector3) -> void:
	if dir.length() < 0.05:
		return
	dir = dir.normalized()
	var probe := dir * 0.34
	if not test_move(global_transform, probe):
		return
	if test_move(global_transform, Vector3(0, STEP_HEIGHT, 0)):
		return
	var best := 0.0
	var low := 0.05
	var high := STEP_HEIGHT
	for i in 10:
		var mid := (low + high) * 0.5
		if test_move(global_transform, Vector3(0, mid, 0)):
			high = mid
			continue
		var raised := global_transform.translated(Vector3(0, mid, 0))
		if test_move(raised, probe):
			low = mid
			continue
		if test_move(raised.translated(probe), Vector3(0, -mid - 0.25, 0)):
			best = mid
			high = mid
		else:
			low = mid
	if best >= 0.05:
		global_position.y += best + 0.02
		velocity.y = 0.0


func _stair_follow(dir: Vector3) -> void:
	if dir.length() < 0.05:
		return
	var space := get_world_3d().direct_space_state
	var origin := global_position + dir.normalized() * 0.48 + Vector3(0, 0.95, 0)
	var q := PhysicsRayQueryParameters3D.create(origin, origin + Vector3(0, -1.4, 0))
	q.collision_mask = collision_mask
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return
	var dy: float = (hit.position as Vector3).y - global_position.y
	if dy > 0.04 and dy <= STEP_HEIGHT and not test_move(global_transform, Vector3(0, dy + 0.03, 0)):
		global_position.y += dy + 0.02
		velocity.y = 0.0


func _flat(v: Vector3) -> Vector3:
	v.y = 0.0
	return v.normalized() if v.length() > 0.05 else Vector3.FORWARD


func _update_aim() -> void:
	aim_target = null
	aim_assisted = false
	if camera == null:
		return
	var assist := clampf(Settings.aim_assist, 0.0, 1.0)
	if first_person:
		_update_aim_fp(assist)
		return
	if pad_aiming:
		var look := Vector2(Input.get_axis("aim_left", "aim_right"), Input.get_axis("aim_up", "aim_down"))
		pad_mag = minf(look.length(), 1.0)
		if look.length() >= 0.2:
			var d := _flat(camera.global_transform.basis.x) * look.x + _flat(-camera.global_transform.basis.z) * (-look.y)
			if d.length() > 0.1:
				pad_dir = d.normalized()
		var reach := 9.0
		aim_target = _cone_target(pad_dir, deg_to_rad(8.0 + 10.0 * assist), 28.0)
		if aim_target:
			aim_assisted = true
			reach = Vector2(aim_target.global_position.x - global_position.x, aim_target.global_position.z - global_position.z).length()
		var g := global_position + pad_dir * reach
		aim_ground = Vector3(g.x, _ground_at(g), g.z)
	else:
		var hit := _cursor_hit(1 | 4 | 16 | 32)
		var ground: Vector3
		if hit.is_empty():
			ground = _cursor_plane()
		else:
			ground = hit.position
			var n: Object = hit.get("collider")
			if n is Node3D and (n as Node).is_in_group("zed"):
				aim_target = n as Node3D
				ground = aim_target.global_position
		aim_ground = ground
		if aim_target == null and assist > 0.0:
			aim_target = _near_target(ground, 0.55 + 1.05 * assist)
			aim_assisted = aim_target != null
	if aim_target != null and aim_target.has_method("aim_center"):
		aim_pos = aim_target.call("aim_center")
	elif aim_target != null:
		aim_pos = aim_target.global_position + Vector3(0, 0.7, 0)
	else:
		aim_pos = aim_ground + Vector3(0, 0.62, 0)
	last_aim = aim_pos


func _update_aim_fp(assist: float) -> void:
	var vp := get_viewport().get_visible_rect().size
	var mid := vp * 0.5
	var from := camera.project_ray_origin(mid)
	var dir := camera.project_ray_normal(mid)
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 90.0)
	q.collision_mask = 1 | 4 | 16 | 32
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var ground: Vector3
	if hit.is_empty():
		ground = _look_plane(from, dir)
	else:
		ground = hit.position
		var n: Object = hit.get("collider")
		if n is Node3D and (n as Node).is_in_group("zed"):
			aim_target = n as Node3D
			ground = aim_target.global_position
	aim_ground = ground
	if aim_target == null and assist > 0.0:
		var face := _flat(-camera.global_transform.basis.z)
		aim_target = _cone_target(face, deg_to_rad(4.5 + 7.0 * assist), 28.0)
		aim_assisted = aim_target != null
		if aim_target:
			aim_ground = Vector3(aim_target.global_position.x, _ground_at(aim_target.global_position), aim_target.global_position.z)
	if aim_target != null and aim_target.has_method("aim_center"):
		aim_pos = aim_target.call("aim_center")
	elif aim_target != null:
		aim_pos = aim_target.global_position + Vector3(0, 0.7, 0)
	elif not hit.is_empty():
		aim_pos = hit.position
	else:
		aim_pos = from + dir * 14.0
	last_aim = aim_pos


func _look_plane(from: Vector3, dir: Vector3) -> Vector3:
	if absf(dir.y) < 0.02:
		return global_position + facing() * 8.0
	var t := (GROUND_Y - from.y) / dir.y
	if t < 0.0:
		return global_position + facing() * 8.0
	return from + dir * t


func _cone_target(dir: Vector3, cone: float, max_d: float) -> Node3D:
	var best: Node3D = null
	var best_score := INF
	for n in get_tree().get_nodes_in_group("zed"):
		if not (n is Node3D) or not is_instance_valid(n) or bool(n.get("dead")):
			continue
		var z := n as Node3D
		var to := z.global_position - global_position
		to.y = 0.0
		var d := to.length()
		if d < 0.6 or d > max_d:
			continue
		var ang := acos(clampf(dir.dot(to / d), -1.0, 1.0))
		if ang > cone:
			continue
		var score := ang + d * 0.012
		if score < best_score:
			best_score = score
			best = z
	return best


func _near_target(pt: Vector3, radius: float) -> Node3D:
	var best: Node3D = null
	var best_d := radius
	for n in get_tree().get_nodes_in_group("zed"):
		if not (n is Node3D) or not is_instance_valid(n) or bool(n.get("dead")):
			continue
		var z := n as Node3D
		var d := Vector2(z.global_position.x - pt.x, z.global_position.z - pt.z).length()
		var sc := 1.0
		if z.get("sc") != null:
			sc = float(z.get("sc"))
		d -= 0.25 * (sc - 1.0)
		if d < best_d and Vector2(z.global_position.x - global_position.x, z.global_position.z - global_position.z).length() < 34.0:
			best_d = d
			best = z
	return best


func _ground_at(p: Vector3) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, p.y + 30.0, p.z), Vector3(p.x, p.y - 12.0, p.z))
	q.collision_mask = 1 | 16 | 32
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit:
		return float(hit.position.y)
	return GROUND_Y


func _cursor_hit(mask: int) -> Dictionary:
	if camera == null:
		return {}
	var mouse := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse)
	var to := from + camera.project_ray_normal(mouse) * 420.0
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
		return global_position + facing() * 6.0 + Vector3(0, GROUND_Y, 0)
	var t := (GROUND_Y - from.y) / dir.y
	if t < 0.0:
		return global_position + facing() * 6.0
	return from + dir * t


func _shot_dir() -> Vector3:
	if first_person and camera:
		return camera.project_ray_normal(get_viewport().get_visible_rect().size * 0.5)
	var from := _muzzle()
	var d := aim_pos - from
	if d.length() < 0.25:
		return facing()
	return d.normalized()


func _face_aim(delta: float) -> void:
	if vis == null:
		return
	if first_person:
		vis.rotation.y = cam_yaw
		return
	var dx := aim_pos.x - global_position.x
	var dz := aim_pos.z - global_position.z
	if Vector2(dx, dz).length() < 0.4:
		return
	# Fast exponential turn with a floor on angular speed so big flicks finish in ~0.15 s.
	var want := atan2(dx, dz)
	var diff := angle_difference(vis.rotation.y, want)
	var step := maxf(absf(diff) * (1.0 - pow(0.00002, delta)), minf(absf(diff), 14.0 * delta))
	vis.rotation.y += signf(diff) * step
	cam_yaw = vis.rotation.y


func _snap_face() -> void:
	# Shots always leave the barrel in the direction they travel: align the body with the aim
	# the moment a trigger pull lands, so the visual never lags the hit.
	if vis == null:
		return
	if first_person:
		vis.rotation.y = cam_yaw
		return
	var dx := aim_pos.x - global_position.x
	var dz := aim_pos.z - global_position.z
	if Vector2(dx, dz).length() < 0.4:
		return
	vis.rotation.y = atan2(dx, dz)
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
	hurt_flash = 0.9
	var away := global_position - source.global_position
	away.y = 0.0
	if away.length() > 0.05:
		velocity = away.normalized() * knock
	velocity.y = 4.0
	AudioDirector.play("hurt", 1.0)
	InputSetup.rumble(0.45, 0.8, 0.22)
	shake(0.5)
	if hp <= 0:
		hp = max_hp
		i_frames = 1.8
		global_position = spawn
		velocity = Vector3.ZERO
		if world and world.has_method("player_down"):
			world.player_down()
	hp_changed.emit(hp, max_hp)


func _update_vignette() -> void:
	if vig_mat == null:
		return
	var low := 0.0
	if hp <= 2 and not locked:
		low = 0.22 + 0.12 * sin(Time.get_ticks_msec() * 0.006)
		if hp <= 1:
			low += 0.1
	vig_mat.set_shader_parameter("amount", clampf(maxf(hurt_flash, low), 0.0, 1.0))


func _update_reticle() -> void:
	if ring3d == null or lock_ring == null:
		return
	var show: bool = not locked and not (pack_ui != null and pack_ui.open)
	var target_ok := aim_target != null and is_instance_valid(aim_target)
	ring3d.visible = show and (build_on or not first_person)
	lock_ring.visible = show and target_ok and not build_on
	if ring3d.visible:
		ring3d.global_position = aim_ground + Vector3(0, 0.05, 0)
		var s := 0.8 + 0.25 * cam_zoom
		ring3d.scale = Vector3(s, 1.0, s)
	if lock_ring.visible:
		lock_ring.global_position = aim_target.global_position + Vector3(0, 0.06, 0)
		var p := 1.0 + 0.08 * sin(Time.get_ticks_msec() * 0.012)
		var sc := 1.0
		if aim_target.get("sc") != null:
			sc = float(aim_target.get("sc"))
		lock_ring.scale = Vector3(p * sc, 1.0, p * sc)


func _update_aim_dot() -> void:
	if aim_dot == null or aim_ring == null or camera == null:
		return
	var show := not locked
	if pack_ui and pack_ui.open:
		show = false
	if build_on and not first_person:
		show = false
	aim_dot.visible = show
	aim_ring.visible = show
	if not show:
		return
	var mp := get_viewport().get_visible_rect().size * 0.5
	if not first_person:
		mp = get_viewport().get_mouse_position()
		if pad_aiming:
			mp = camera.unproject_position(aim_pos)
	aim_dot.position = mp - aim_dot.size * 0.5
	aim_ring.position = mp - aim_ring.size * 0.5
	var fill := Color("FFB347")
	var edge := Color("1A140E")
	if aim_target != null and is_instance_valid(aim_target):
		fill = Color("E24B4B")
		edge = Color("FFF6D8")
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


func _footsteps() -> void:
	var spd := Vector2(velocity.x, velocity.z).length()
	if spd < 0.7 or not is_on_floor():
		return
	var s := int(floor(walk_t / PI))
	if s != stride:
		stride = s
		AudioDirector.play("step", randf_range(0.85, 1.12))


func _glow(c: Color, energy: float = 1.0) -> StandardMaterial3D:
	var m := _mat(c, 0.42, 0.15)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


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
