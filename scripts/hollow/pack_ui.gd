class_name HollowPackUi
extends CanvasLayer

const PackData = preload("res://scripts/hollow/pack.gd")

var hunter: Node
var open := false
var dim: ColorRect
var bag_wrap: Control
var title: Label
var hint: Label
var bar_row: HBoxContainer
var bag_grid: GridContainer
var ghost: Panel
var ghost_mark: Label
var ghost_count: Label
var bar_btns: Array[Button] = []
var bag_btns: Array[Button] = []


func setup(h: Node) -> void:
	hunter = h
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	if hunter.pack:
		hunter.pack.changed.connect(refresh)
	refresh()


func _build() -> void:
	dim = ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.06, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.visible = false
	add_child(dim)
	bag_wrap = Control.new()
	bag_wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bag_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bag_wrap.visible = false
	add_child(bag_wrap)
	title = Label.new()
	title.text = "PACK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left = -200
	title.offset_right = 200
	title.offset_top = -250
	title.offset_bottom = -200
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("FFB347"))
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08, 0.95))
	title.add_theme_constant_override("outline_size", 8)
	if Art.font_title:
		title.add_theme_font_override("font", Art.font_title)
	bag_wrap.add_child(title)
	hint = Label.new()
	hint.text = "Click move    Right-click split    Esc / E close    Q drop"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(Control.PRESET_CENTER)
	hint.offset_left = -420
	hint.offset_right = 420
	hint.offset_top = 168
	hint.offset_bottom = 210
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color("D4E0C8"))
	bag_wrap.add_child(hint)
	bag_grid = GridContainer.new()
	bag_grid.columns = 9
	bag_grid.add_theme_constant_override("h_separation", 6)
	bag_grid.add_theme_constant_override("v_separation", 6)
	bag_grid.set_anchors_preset(Control.PRESET_CENTER)
	bag_grid.offset_left = -330
	bag_grid.offset_right = 330
	bag_grid.offset_top = -186
	bag_grid.offset_bottom = 18
	bag_wrap.add_child(bag_grid)
	for i in 27:
		var b := _slot_btn("bag", i)
		bag_grid.add_child(b)
		bag_btns.append(b)
	bar_row = HBoxContainer.new()
	bar_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bar_row.add_theme_constant_override("separation", 6)
	bar_row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar_row.offset_left = -330
	bar_row.offset_right = 330
	bar_row.offset_top = -92
	bar_row.offset_bottom = -28
	bar_row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(bar_row)
	for i in 9:
		var b := _slot_btn("bar", i)
		bar_row.add_child(b)
		bar_btns.append(b)
	ghost = Panel.new()
	ghost.size = Vector2(64, 64)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.z_index = 20
	ghost.visible = false
	add_child(ghost)
	ghost_mark = Label.new()
	ghost_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ghost_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ghost_mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ghost_mark.add_theme_font_size_override("font_size", 16)
	ghost.add_child(ghost_mark)
	ghost_count = Label.new()
	ghost_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ghost_count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	ghost_count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ghost_count.add_theme_font_size_override("font_size", 14)
	ghost.add_child(ghost_count)


func _slot_btn(where: String, index: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(64, 64)
	b.toggle_mode = false
	b.focus_mode = Control.FOCUS_NONE
	b.set_meta("where", where)
	b.set_meta("index", index)
	b.gui_input.connect(_on_slot.bind(b))
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.text = ""
	var icon := Label.new()
	icon.name = "Icon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_bottom = -8
	icon.add_theme_font_size_override("font_size", 30)
	if Art.font_emoji:
		icon.add_theme_font_override("font", Art.font_emoji)
	b.add_child(icon)
	var qty := Label.new()
	qty.name = "Qty"
	qty.mouse_filter = Control.MOUSE_FILTER_IGNORE
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	qty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	qty.offset_right = -6
	qty.offset_bottom = -4
	qty.add_theme_font_size_override("font_size", 14)
	qty.add_theme_color_override("font_color", Color("FFF6D8"))
	b.add_child(qty)
	return b


func _on_slot(event: InputEvent, b: Button) -> void:
	if hunter == null or hunter.pack == null:
		return
	if event is InputEventMouseButton and event.pressed:
		if not open:
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			hunter.pack.click(str(b.get_meta("where")), int(b.get_meta("index")), false)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			hunter.pack.click(str(b.get_meta("where")), int(b.get_meta("index")), true)
			get_viewport().set_input_as_handled()


func toggle() -> void:
	set_open(not open)


func set_open(v: bool) -> void:
	if open == v:
		return
	open = v
	dim.visible = v
	bag_wrap.visible = v
	if get_tree():
		get_tree().paused = v
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioDirector.play("ui", 1.05 if v else 0.85)
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle()
		get_viewport().set_input_as_handled()
		return
	if open and (event.is_action_pressed("pause") or event.is_action_pressed("ui_back")):
		set_open(false)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var i: int = int(event.physical_keycode) - KEY_1
		if i >= 0 and i <= 8:
			if hunter and hunter.build_on:
				return
			if hunter and hunter.pack:
				hunter.pack.selected = i
				hunter.pack.changed.emit()
				get_viewport().set_input_as_handled()
	if open and event.is_action_pressed("drop_item") and hunter and hunter.has_method("drop_held"):
		hunter.drop_held()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if hunter == null or hunter.pack == null:
		return
	var it: Dictionary = hunter.pack.cursor
	ghost.visible = open and not PackData.blank(it)
	if ghost.visible:
		ghost.global_position = get_viewport().get_mouse_position() + Vector2(12, 12)
		_paint_panel(ghost, ghost_mark, ghost_count, it, false)


func refresh() -> void:
	if hunter == null or hunter.pack == null:
		return
	for i in bar_btns.size():
		_paint_btn(bar_btns[i], hunter.pack.bar[i], i == hunter.pack.selected)
	for i in bag_btns.size():
		_paint_btn(bag_btns[i], hunter.pack.bag[i], false)


func _paint_btn(b: Button, it: Dictionary, on: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("1A1612")
	sb.border_color = Color("FFB347") if on else Color("3A3228")
	sb.set_border_width_all(3 if on else 2)
	sb.set_corner_radius_all(8)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.text = ""
	var icon: Label = b.get_node_or_null("Icon")
	var qty: Label = b.get_node_or_null("Qty")
	if PackData.blank(it):
		b.tooltip_text = ""
		if icon:
			icon.text = ""
		if qty:
			qty.text = ""
		return
	b.tooltip_text = str(it.get("name", ""))
	if icon:
		icon.text = PackData.icon(it)
		icon.add_theme_color_override("font_color", Color.WHITE)
	if qty:
		if str(it.get("kind", "")) == "gun":
			qty.text = str(int(it.get("ammo", 0)))
		elif int(it.get("count", 1)) > 1:
			qty.text = str(int(it.get("count", 1)))
		else:
			qty.text = ""


func _paint_panel(p: Panel, mark: Label, count: Label, it: Dictionary, on: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("1A1612")
	sb.border_color = Color("FFB347") if on else Color("5A4A38")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	p.add_theme_stylebox_override("panel", sb)
	mark.text = PackData.icon(it)
	if Art.font_emoji:
		mark.add_theme_font_override("font", Art.font_emoji)
	mark.add_theme_font_size_override("font_size", 26)
	mark.add_theme_color_override("font_color", Color.WHITE)
	if str(it.get("kind", "")) == "gun":
		count.text = str(int(it.get("ammo", 0)))
	elif int(it.get("count", 1)) > 1:
		count.text = str(int(it.get("count", 1)))
	else:
		count.text = ""
