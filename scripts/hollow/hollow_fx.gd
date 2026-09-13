class_name HollowFx
extends RefCounted


static func burst(host: Node3D, pos: Vector3, color: Color, count: int = 14, speed: float = 2.4) -> void:
	if host == null or not is_instance_valid(host):
		return
	for i in count:
		var mi := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.09
		mesh.height = 0.18
		mi.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.material_override = mat
		host.add_child(mi)
		mi.global_position = pos
		var dir := Vector3(randf_range(-1.0, 1.0), randf_range(0.2, 1.15), randf_range(-1.0, 1.0)).normalized()
		var tw := host.create_tween()
		tw.tween_property(mi, "global_position", pos + dir * randf_range(speed * 0.45, speed), 0.4)
		tw.parallel().tween_property(mi, "scale", Vector3.ZERO, 0.4)
		tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.4)
		tw.tween_callback(mi.queue_free)


static func spark(host: Node3D, pos: Vector3) -> void:
	burst(host, pos, Color("D4FF8A"), 7, 1.4)


static func goo(host: Node3D, pos: Vector3) -> void:
	burst(host, pos, Color("7DCF58"), 16, 2.2)
	burst(host, pos, Color("C9A0FF"), 6, 1.3)


static func boom(host: Node3D, pos: Vector3) -> void:
	burst(host, pos, Color("FFB347"), 20, 3.2)
	burst(host, pos, Color("FFE27A"), 10, 2.0)


static func wood(host: Node3D, pos: Vector3) -> void:
	burst(host, pos, Color("C48A4A"), 12, 1.8)


static func tracer(host: Node3D, a: Vector3, b: Vector3, color: Color = Color("FFE6A0")) -> void:
	if host == null:
		return
	var len := a.distance_to(b)
	if len < 0.05:
		return
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.035, 0.035, len)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(color.r, color.g, color.b, 0.85)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	host.add_child(mi)
	mi.global_position = (a + b) * 0.5
	mi.look_at(b, Vector3.UP)
	var tw := host.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.08)
	tw.tween_callback(mi.queue_free)


static func float_text(host: Node3D, pos: Vector3, text: String, color: Color) -> void:
	if host == null:
		return
	var l := Label3D.new()
	l.text = text
	l.font_size = 48
	l.outline_size = 10
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	if Art.font_emoji:
		l.font = Art.font_emoji
	host.add_child(l)
	l.global_position = pos + Vector3(0, 1.2, 0)
	var tw := host.create_tween()
	tw.tween_property(l, "global_position", l.global_position + Vector3(0, 1.1, 0), 0.55)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.55)
	tw.tween_callback(l.queue_free)


static func fling_bit(host: Node3D, xform: Transform3D, color: Color, radius: float, dir: Vector3) -> void:
	if host == null:
		return
	var rb := RigidBody3D.new()
	rb.collision_layer = 0
	rb.collision_mask = 1
	rb.mass = 0.35
	host.add_child(rb)
	rb.global_transform = xform
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = radius
	cs.shape = sph
	rb.add_child(cs)
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	mi.material_override = mat
	rb.add_child(mi)
	rb.apply_impulse(dir * randf_range(3.5, 6.5) + Vector3.UP * randf_range(2.5, 4.5))
	rb.apply_torque_impulse(Vector3(randf_range(-2, 2), randf_range(-2, 2), randf_range(-2, 2)))
	var tw := host.create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(mi, "scale", Vector3.ZERO, 0.25)
	tw.tween_callback(rb.queue_free)
