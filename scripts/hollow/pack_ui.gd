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
var focus_where := "bar"
var focus_index := 0
var nav_cd := 0.0
var name_lbl: Label
var heart_lbl: Label
var xp_bg: ColorRect
var xp_fill: ColorRect
var xp_lvl: Label
var candy_lbl: Label
var last_held := ""
var name_t := 0.0


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
	title.text = "Inventory"
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
	hint.text = "Click to move    Right-click split    Esc close    Q drop"
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
	bar_row.offset_top = -78
	bar_row.offset_bottom = -14
	bar_row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(bar_row)
	for i in 9:
		var b := _slot_btn("bar", i)
		bar_row.add_child(b)
		bar_btns.append(b)
	heart_lbl = Label.new()
	heart_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heart_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	heart_lbl.offset_left = -320
	heart_lbl.offset_right = 320
	heart_lbl.offset_top = -148
	heart_lbl.offset_bottom = -118
	heart_lbl.add_theme_font_size_override("font_size", 22)
	heart_lbl.add_theme_color_override("font_color", Color("E24B4B"))
	heart_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.04, 0.95))
	heart_lbl.add_theme_constant_override("outline_size", 6)
	heart_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(heart_lbl)
	xp_bg = ColorRect.new()
	xp_bg.color = Color(0.08, 0.08, 0.1, 0.85)
	xp_bg.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	xp_bg.offset_left = -182
	xp_bg.offset_right = 182
	xp_bg.offset_top = -116
	xp_bg.offset_bottom = -106
	xp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(xp_bg)
	xp_fill = ColorRect.new()
	xp_fill.color = Color("7CFF4A")
	xp_fill.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	xp_fill.offset_left = -182
	xp_fill.offset_right = 182
	xp_fill.offset_top = -116
	xp_fill.offset_bottom = -106
	xp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(xp_fill)
	xp_lvl = Label.new()
	xp_lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_lvl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	xp_lvl.offset_left = -80
	xp_lvl.offset_right = 80
	xp_lvl.offset_top = -122
	xp_lvl.offset_bottom = -100
	xp_lvl.add_theme_font_size_override("font_size", 14)
	xp_lvl.add_theme_color_override("font_color", Color("3A2A14"))
	xp_lvl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(xp_lvl)
	candy_lbl = Label.new()
	candy_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	candy_lbl.offset_left = -330
	candy_lbl.offset_right = -190
	candy_lbl.offset_top = -120
	candy_lbl.offset_bottom = -96
	candy_lbl.add_theme_font_size_override("font_size", 16)
	candy_lbl.add_theme_color_override("font_color", Color("FFB347"))
	candy_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08, 0.9))
	candy_lbl.add_theme_constant_override("outline_size", 5)
	candy_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(candy_lbl)
	name_lbl = Label.new()
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	name_lbl.offset_left = -280
	name_lbl.offset_right = 280
	name_lbl.offset_top = -176
	name_lbl.offset_bottom = -150
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", Color("FFF6D8"))
	name_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08, 0.95))
	name_lbl.add_theme_constant_override("outline_size", 7)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.modulate.a = 0.0
	add_child(name_lbl)
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
	if where == "bar":
		var num := Label.new()
		num.name = "Num"
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		num.text = str(index + 1)
		num.position = Vector2(4, 2)
		num.add_theme_font_size_override("font_size", 12)
		num.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		b.add_child(num)
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
	if hunter and hunter.has_method("_sync_mouse"):
		hunter._sync_mouse()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioDirector.play("ui", 1.05 if v else 0.85)
	if v:
		focus_where = "bar"
		focus_index = hunter.pack.selected if hunter and hunter.pack else 0
		nav_cd = 0.2
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if hunter and hunter.world and hunter.world.has_method("try_interact") and hunter.world.try_interact():
			get_viewport().set_input_as_handled()
			return
		toggle()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		if open:
			set_open(false)
			get_viewport().set_input_as_handled()
			return
		if hunter and hunter.world and bool(hunter.world.get("over")):
			return
		var tree := get_tree()
		tree.paused = not tree.paused
		if tree.paused and hunter and hunter.world and hunter.world.has_method("_show"):
			hunter.world._show("PAUSED")
		get_viewport().set_input_as_handled()
		return
	if open and event.is_action_pressed("ui_back"):
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
		return
	if open and event.is_action_pressed("ui_accept"):
		_activate(false)
		get_viewport().set_input_as_handled()
		return
	if open and event.is_action_pressed("reload"):
		_activate(true)
		get_viewport().set_input_as_handled()
		return


func _process(delta: float) -> void:
	if hunter == null or hunter.pack == null:
		return
	if open:
		nav_cd = maxf(0.0, nav_cd - delta)
		var dx := 0
		var dy := 0
		if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("bar_left"):
			dx = -1
		elif Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("bar_right"):
			dx = 1
		if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("zoom_in"):
			dy = -1
		elif Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("zoom_out"):
			dy = 1
		if dx == 0 and dy == 0 and nav_cd <= 0.0:
			var stick := Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
			if absf(stick.x) > 0.55:
				dx = 1 if stick.x > 0.0 else -1
			if absf(stick.y) > 0.55:
				dy = 1 if stick.y > 0.0 else -1
		if dx != 0 or dy != 0:
			_move_focus(dx, dy)
			nav_cd = 0.16
			refresh()
	if name_lbl and name_t > 0.0:
		name_t -= delta
		name_lbl.modulate.a = clampf(name_t, 0.0, 1.0)
	var it: Dictionary = hunter.pack.cursor
	ghost.visible = open and not PackData.blank(it)
	if ghost.visible:
		var gp := get_viewport().get_mouse_position() + Vector2(12, 12)
		var fb := _focus_btn()
		if InputSetup.pad_connected() and fb:
			gp = fb.global_position + fb.size * 0.5 - ghost.size * 0.5
		ghost.global_position = gp
		_paint_panel(ghost, ghost_mark, ghost_count, it, false)


func refresh() -> void:
	if hunter == null or hunter.pack == null:
		return
	for i in bar_btns.size():
		_paint_btn(bar_btns[i], hunter.pack.bar[i], i == hunter.pack.selected, open and focus_where == "bar" and i == focus_index)
	for i in bag_btns.size():
		_paint_btn(bag_btns[i], hunter.pack.bag[i], false, open and focus_where == "bag" and i == focus_index)
	var held: Dictionary = hunter.pack.equipped()
	var nm := str(held.get("name", ""))
	if nm != "" and nm != last_held:
		last_held = nm
		name_lbl.text = nm
		name_t = 2.4
		name_lbl.modulate.a = 1.0
	refresh_hud()


func refresh_hud() -> void:
	if hunter == null:
		return
	if heart_lbl:
		var s := ""
		for i in hunter.max_hp:
			s += "❤" if i < hunter.hp else "♡"
		heart_lbl.text = s
	if candy_lbl and hunter.world:
		candy_lbl.text = "🍬 %d" % int(hunter.world.get("candy"))
	if xp_fill and hunter.world and hunter.world.has_method("lantern_frac"):
		var f: float = hunter.world.lantern_frac()
		xp_fill.offset_right = xp_fill.offset_left + 364.0 * clampf(f, 0.0, 1.0)
		xp_fill.color = Color("7CFF4A") if f > 0.35 else Color("E24B4B")
	if xp_lvl and hunter.world:
		xp_lvl.text = str(maxi(int(hunter.world.get("wave")), 0))


func _paint_btn(b: Button, it: Dictionary, on: bool, focused: bool = false) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.22, 0.22, 0.22, 0.92)
	if focused:
		sb.border_color = Color("FFF6D8")
		sb.set_border_width_all(3)
	elif on:
		sb.border_color = Color("FFFFFF")
		sb.set_border_width_all(3)
	else:
		sb.border_color = Color(0.08, 0.08, 0.08, 1.0)
		sb.set_border_width_all(3)
	sb.set_corner_radius_all(2)
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
	b.tooltip_text = "%s\n%s" % [str(it.get("name", "")), str(it.get("desc", ""))]
	if icon:
		icon.text = PackData.icon(it)
		icon.add_theme_color_override("font_color", Color.WHITE)
	if on and not focused:
		sb.border_color = Color("FFFFFF")
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


func _focus_btn() -> Button:
	if focus_where == "bar":
		if focus_index >= 0 and focus_index < bar_btns.size():
			return bar_btns[focus_index]
	elif focus_index >= 0 and focus_index < bag_btns.size():
		return bag_btns[focus_index]
	return null


func _activate(split: bool) -> void:
	if hunter == null or hunter.pack == null:
		return
	hunter.pack.click(focus_where, focus_index, split)
	if focus_where == "bar":
		hunter.pack.selected = focus_index
		hunter.pack.changed.emit()
	refresh()


func _move_focus(dx: int, dy: int) -> void:
	if dx == 0 and dy == 0:
		return
	if focus_where == "bar":
		if dy > 0:
			focus_where = "bag"
			focus_index = clampi(focus_index, 0, 8)
		else:
			focus_index = (focus_index + dx + 9) % 9
			hunter.pack.selected = focus_index
			hunter.pack.changed.emit()
		return
	var col := focus_index % 9
	var row := int(focus_index / 9)
	col = (col + dx + 9) % 9
	row += dy
	if row < 0:
		focus_where = "bar"
		focus_index = col
		hunter.pack.selected = focus_index
		hunter.pack.changed.emit()
		return
	if row > 2:
		row = 2
	focus_index = row * 9 + col
	AudioDirector.play("ui", 1.15)

