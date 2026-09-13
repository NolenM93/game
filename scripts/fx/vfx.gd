class_name VFX
extends RefCounted

static func _glow(host: Node, pos: Vector2, color: Color, sc: Vector2, life: float = 0.28) -> Sprite2D:
	if host == null:
		return null
	var s := Sprite2D.new()
	s.texture = Art.soft_light()
	s.modulate = color
	s.scale = sc
	s.z_index = 40
	host.add_child(s)
	s.global_position = pos
	var tw := host.get_tree().create_tween()
	tw.tween_property(s, "scale", sc * 1.7, life)
	tw.parallel().tween_property(s, "modulate:a", 0.0, life)
	tw.tween_callback(s.queue_free)
	return s


static func burst(host: Node, pos: Vector2, color: Color, count: int = 10, speed: float = 260.0) -> void:
	if host == null:
		return
	for i in count:
		var s := Sprite2D.new()
		s.texture = Art.soft_light()
		s.modulate = Color(color.r, color.g, color.b, 0.85)
		s.scale = Vector2(0.08, 0.08)
		s.z_index = 40
		host.add_child(s)
		s.global_position = pos
		var dir := Vector2.RIGHT.rotated(randf() * TAU)
		var tw := host.get_tree().create_tween()
		tw.tween_property(s, "global_position", pos + dir * speed * randf_range(0.25, 1.0), 0.32)
		tw.parallel().tween_property(s, "modulate:a", 0.0, 0.32)
		tw.parallel().tween_property(s, "scale", Vector2(0.02, 0.02), 0.32)
		tw.tween_callback(s.queue_free)


static func ring(host: Node, pos: Vector2, color: Color, radius: float = 80.0) -> void:
	_glow(host, pos, Color(color.r, color.g, color.b, 0.55), Vector2(radius / 180.0, radius / 280.0), 0.3)


static func slash(host: Node, pos: Vector2, facing: int, color: Color) -> void:
	if host == null:
		return
	var s := Sprite2D.new()
	s.texture = Art.soft_light()
	s.modulate = Color(color.r, color.g, color.b, 0.7)
	s.scale = Vector2(0.55 * facing, 0.16)
	s.rotation = deg_to_rad(-18.0 * facing)
	s.z_index = 35
	host.add_child(s)
	s.global_position = pos
	var tw := host.get_tree().create_tween()
	tw.tween_property(s, "scale", Vector2(0.9 * facing, 0.08), 0.12)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.14)
	tw.tween_callback(s.queue_free)


static func dust(host: Node, pos: Vector2) -> void:
	if host == null:
		return
	for i in 5:
		_glow(host, pos + Vector2(randf_range(-18, 18), randf_range(-4, 6)), Color(0.85, 0.78, 0.62, 0.35), Vector2(0.14, 0.05), 0.22)


static func stars(host: Node, pos: Vector2) -> void:
	burst(host, pos, Color("FFEE88"), 7, 180.0)


static func text_pop(host: Node, pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	if host == null:
		return
	var l := Label.new()
	l.text = text
	l.z_index = 80
	l.add_theme_font_override("font", Art.font_title if Art.font_title else ThemeDB.fallback_font)
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.03, 0.9))
	l.add_theme_constant_override("outline_size", 4)
	host.add_child(l)
	l.global_position = pos + Vector2(-40, -20)
	var tw := host.get_tree().create_tween()
	tw.tween_property(l, "global_position", pos + Vector2(-40, -64), 0.45)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.45)
	tw.tween_callback(l.queue_free)
