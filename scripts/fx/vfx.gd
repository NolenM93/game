class_name VFX
extends RefCounted

static func burst(host: Node, pos: Vector2, color: Color, count: int = 10, speed: float = 260.0) -> void:
	if host == null:
		return
	for i in count:
		var r := ColorRect.new()
		r.size = Vector2(8, 8)
		r.color = color
		r.z_index = 40
		host.add_child(r)
		r.global_position = pos
		var dir := Vector2.RIGHT.rotated(randf() * TAU)
		var tw := host.get_tree().create_tween()
		tw.tween_property(r, "global_position", pos + dir * speed * randf_range(0.3, 1.0), 0.35)
		tw.parallel().tween_property(r, "modulate:a", 0.0, 0.35)
		tw.tween_callback(r.queue_free)


static func ring(host: Node, pos: Vector2, color: Color, radius: float = 80.0) -> void:
	if host == null:
		return
	var p := Polygon2D.new()
	p.color = Color(color.r, color.g, color.b, 0.35)
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(Vector2(cos(a), sin(a)) * 12.0)
	p.polygon = pts
	p.z_index = 30
	host.add_child(p)
	p.global_position = pos
	var tw := host.get_tree().create_tween()
	tw.tween_property(p, "scale", Vector2.ONE * (radius / 12.0), 0.28)
	tw.parallel().tween_property(p, "modulate:a", 0.0, 0.28)
	tw.tween_callback(p.queue_free)


static func stars(host: Node, pos: Vector2) -> void:
	burst(host, pos, Color("FFEE88"), 7, 180.0)


static func text_pop(host: Node, pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	if host == null:
		return
	var l := Label.new()
	l.text = text
	l.z_index = 80
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", 28)
	host.add_child(l)
	l.global_position = pos
	var tw := host.get_tree().create_tween()
	tw.tween_property(l, "global_position", pos + Vector2(0, -48), 0.5)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)
