extends Control

var runner: MissionRunner
var obj_label: Label
var hp_box: HBoxContainer
var fuel_bar: ProgressBar
var name_label: Label
var time_label: Label
var spark_label: Label
var dare_label: Label
var hint: Label
var hint_t := 7.0


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label = UIKit.label(self, "", Vector2(48, 28), 22, UIKit.PAPER)
	hp_box = HBoxContainer.new()
	hp_box.position = Vector2(48, 58)
	hp_box.add_theme_constant_override("separation", 6)
	add_child(hp_box)
	fuel_bar = ProgressBar.new()
	fuel_bar.position = Vector2(48, 92)
	fuel_bar.size = Vector2(220, 12)
	fuel_bar.show_percentage = false
	fuel_bar.max_value = 1
	var fb := StyleBoxFlat.new()
	fb.bg_color = Color(0.12, 0.2, 0.32, 0.85)
	fb.set_corner_radius_all(6)
	fuel_bar.add_theme_stylebox_override("background", fb)
	var ff := StyleBoxFlat.new()
	ff.bg_color = Color("3B7CFF")
	ff.set_corner_radius_all(6)
	fuel_bar.add_theme_stylebox_override("fill", ff)
	fuel_bar.visible = false
	add_child(fuel_bar)
	time_label = UIKit.label(self, "0:00", Vector2(900, 32), 30, UIKit.PAPER, true)
	spark_label = UIKit.label(self, "", Vector2(1580, 32), 24, UIKit.GOLD)
	obj_label = UIKit.label(self, "", Vector2(48, 990), 22, UIKit.TEAL)
	dare_label = UIKit.label(self, "", Vector2(48, 1028), 18, UIKit.GOLD)
	hint = UIKit.label(self, "A jump    X attack    Y signature    B mobility    LB gadget    RB lock-on    Start pause", Vector2(420, 28), 16, Color(1, 1, 1, 0.55))


func setup(r: MissionRunner) -> void:
	runner = r
	refresh()


func refresh() -> void:
	if runner == null or runner.hero == null:
		return
	var h := runner.hero
	name_label.text = h.display_name
	_hearts(h.hp, h.max_hp)
	if h.max_fuel > 0.0:
		fuel_bar.visible = true
		fuel_bar.max_value = h.max_fuel
		fuel_bar.value = h.fuel
	else:
		fuel_bar.visible = false
	var t := int(runner.elapsed)
	time_label.text = "%d:%02d" % [int(t / 60.0), t % 60]
	spark_label.text = "Spark %d" % int(SaveManager.active.get("spark", 0))
	var lines: PackedStringArray = PackedStringArray()
	var oi := 0
	for o in runner.def.get("objectives", []):
		var mark := "✓" if runner.obj_done.get(oi, false) else "•"
		lines.append("%s %s" % [mark, str(o.get("text", ""))])
		oi += 1
	obj_label.text = "     ".join(lines)
	var d: Dictionary = runner.def.get("dare", {})
	dare_label.text = "" if d.is_empty() else "Dare: %s" % str(d.get("text", ""))


func _process(delta: float) -> void:
	if hint_t > 0.0:
		hint_t -= delta
		hint.modulate.a = clampf(hint_t / 1.2, 0.0, 1.0)


func _hearts(hp: int, mx: int) -> void:
	while hp_box.get_child_count() < mx:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(18, 18)
		var sb_ignore := pip
		hp_box.add_child(sb_ignore)
	for i in hp_box.get_child_count():
		var pip: ColorRect = hp_box.get_child(i)
		pip.visible = i < mx
		pip.color = Color("E24B4B") if i < hp else Color(0.18, 0.12, 0.12, 0.85)
