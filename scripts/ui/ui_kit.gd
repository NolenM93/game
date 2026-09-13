class_name UIKit
extends RefCounted

const NAVY := Color("10141C")
const GOLD := Color("E8C45A")
const TEAL := Color("7DCFC4")
const PAPER := Color("F3E6D0")
const INK := Color("1A140E")


static func full_rect(node: Control) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.mouse_filter = Control.MOUSE_FILTER_STOP


static func _font(title: bool) -> Font:
	var f: Font = Art.font_title if title else Art.font_body
	if f == null:
		return ThemeDB.fallback_font
	return f


static func _sb(bg: Color, border: Color, radius: int = 10, bw: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	sb.border_width_left = bw
	sb.border_width_top = bw
	sb.border_width_right = bw
	sb.border_width_bottom = bw
	sb.border_color = border
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 6)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


static func panel(parent: Control, rect: Rect2, color: Color = Color(0.09, 0.08, 0.07, 0.92)) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	p.add_theme_stylebox_override("panel", _sb(color, Color(0.91, 0.77, 0.35, 0.55), 14, 2))
	parent.add_child(p)
	return p


static func label(parent: Node, text: String, pos: Vector2, size: int = 28, color: Color = PAPER, title: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", _font(title or size >= 40))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 3)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.03, 0.9))
	l.add_theme_constant_override("outline_size", 5 if size >= 40 else 3)
	parent.add_child(l)
	return l


static func button(parent: Node, text: String, rect: Rect2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	var n := _sb(Color(0.12, 0.1, 0.09, 0.94), Color(0.55, 0.42, 0.22, 0.7), 12, 2)
	var h := _sb(Color(0.22, 0.17, 0.1, 0.96), GOLD, 12, 3)
	h.border_width_left = 8
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.add_theme_stylebox_override("focus", h)
	var dis := n.duplicate()
	dis.bg_color = Color(0.08, 0.08, 0.08, 0.7)
	dis.border_color = Color(0.3, 0.3, 0.3, 0.4)
	b.add_theme_stylebox_override("disabled", dis)
	b.add_theme_font_override("font", _font(false))
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_color_override("font_color", PAPER)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_focus_color", GOLD)
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.32))
	b.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.02, 0.9))
	b.add_theme_constant_override("outline_size", 4)
	b.clip_text = false
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(b)
	return b


static func dimmer(parent: Control) -> ColorRect:
	var c := ColorRect.new()
	full_rect(c)
	c.color = Color(0.02, 0.02, 0.03, 0.72)
	parent.add_child(c)
	return c


static func art_bg(parent: Control, tex_id: String, dark: float = 0.45) -> TextureRect:
	var bg := TextureRect.new()
	bg.texture = Art.tex(tex_id)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	full_rect(bg)
	parent.add_child(bg)
	if dark > 0.0:
		var d := ColorRect.new()
		full_rect(d)
		d.color = Color(0.04, 0.03, 0.03, dark)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(d)
	return bg
