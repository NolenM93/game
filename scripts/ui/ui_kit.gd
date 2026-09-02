class_name UIKit
extends RefCounted

const NAVY := Color("0B1B33")
const GOLD := Color("F4C542")
const TEAL := Color("2EE6C7")
const PAPER := Color("F4EFE2")
const INK := Color("142033")


static func full_rect(node: Control) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.mouse_filter = Control.MOUSE_FILTER_STOP


static func _font(title: bool) -> Font:
	var f: Font = Art.font_title if title else Art.font_body
	if f == null:
		return ThemeDB.fallback_font
	return f


static func panel(parent: Control, rect: Rect2, color: Color = Color("0B1B33E6")) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 22
	sb.corner_radius_top_right = 22
	sb.corner_radius_bottom_left = 22
	sb.corner_radius_bottom_right = 22
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(0.96, 0.77, 0.26, 0.45)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 16
	sb.shadow_offset = Vector2(0, 8)
	p.add_theme_stylebox_override("panel", sb)
	parent.add_child(p)
	return p


static func label(parent: Node, text: String, pos: Vector2, size: int = 28, color: Color = PAPER, title: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", _font(title or size >= 40))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 3)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.08, 0.85))
	l.add_theme_constant_override("outline_size", 4 if size >= 40 else 3)
	parent.add_child(l)
	return l


static func button(parent: Node, text: String, rect: Rect2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.08, 0.14, 0.24, 0.88)
	n.corner_radius_top_left = 16
	n.corner_radius_top_right = 16
	n.corner_radius_bottom_left = 16
	n.corner_radius_bottom_right = 16
	n.border_width_left = 1
	n.border_width_top = 1
	n.border_width_right = 1
	n.border_width_bottom = 1
	n.border_color = Color(0.18, 0.9, 0.78, 0.55)
	n.shadow_color = Color(0, 0, 0, 0.35)
	n.shadow_size = 8
	n.content_margin_left = 18
	n.content_margin_right = 18
	var h := n.duplicate()
	h.bg_color = Color(0.14, 0.24, 0.38, 0.95)
	h.border_color = GOLD
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("focus", h)
	b.add_theme_font_override("font", _font(false))
	b.add_theme_font_size_override("font_size", 28)
	b.add_theme_color_override("font_color", PAPER)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_focus_color", GOLD)
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))
	b.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.08, 0.9))
	b.add_theme_constant_override("outline_size", 4)
	b.clip_text = false
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(b)
	return b


static func dimmer(parent: Control) -> ColorRect:
	var c := ColorRect.new()
	full_rect(c)
	c.color = Color(0.02, 0.03, 0.06, 0.62)
	parent.add_child(c)
	return c
