class_name ArenaFx
extends RefCounted


static func burst(host: Node3D, pos: Vector3, color: Color, count: int = 12, speed: float = 2.2) -> void:
	if host == null or not is_instance_valid(host):
		return
	for i in count:
		var mi := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.1
		mesh.height = 0.2
		mi.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.material_override = mat
		host.add_child(mi)
		mi.global_position = pos
		var dir := Vector3(randf_range(-1.0, 1.0), randf_range(0.15, 1.0), randf_range(-1.0, 1.0)).normalized()
		var tw := host.create_tween()
		tw.tween_property(mi, "global_position", pos + dir * randf_range(speed * 0.5, speed), 0.38)
		tw.parallel().tween_property(mi, "scale", Vector3.ZERO, 0.38)
		tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.38)
		tw.tween_callback(mi.queue_free)


static func splash(host: Node3D, pos: Vector3) -> void:
	burst(host, pos + Vector3(0, 0.4, 0), Color("8FD4FF"), 16, 2.8)
	burst(host, pos + Vector3(0, 0.2, 0), Color("FFE27A"), 6, 1.6)


static func punch_flash(host: Node3D, pos: Vector3) -> void:
	if host == null:
		return
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.35
	mesh.height = 0.7
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 1, 1, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	host.add_child(mi)
	mi.global_position = pos
	var tw := host.create_tween()
	tw.tween_property(mi, "scale", Vector3(2.4, 2.4, 2.4), 0.12)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.12)
	tw.tween_callback(mi.queue_free)
