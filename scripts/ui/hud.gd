extends Control

var runner: MissionRunner
var obj_label: Label
var hp_label: Label
var fuel_label: Label
var dare_label: Label
var time_label: Label
var spark_label: Label
var lock_label: Label


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := ColorRect.new()
	top.position = Vector2(24, 16)
	top.size = Vector2(1872, 78)
	top.color = Color(0.04, 0.07, 0.12, 0.55)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	hp_label = UIKit.label(self, "HP", Vector2(48, 28), 30 if not Settings.large_hud else 36, Color("FF8A8A"))
	fuel_label = UIKit.label(self, "", Vector2(48, 58), 20, Color("9AD4FF"))
	time_label = UIKit.label(self, "0:00", Vector2(900, 28), 28, Color("F4EFE2"), true)
	spark_label = UIKit.label(self, "Spark 0", Vector2(1580, 28), 24, Color("F4C542"))
	obj_label = UIKit.label(self, "", Vector2(40, 978), 24, Color("2EE6C7"))
	dare_label = UIKit.label(self, "", Vector2(40, 1020), 20, Color("F4C542"))
	lock_label = UIKit.label(self, "A jump   X attack   Y signature   B mobility   LB gadget   RB lock-on   Start pause", Vector2(420, 58), 16, Color(1, 1, 1, 0.72))


func setup(r: MissionRunner) -> void:
	runner = r
	refresh()


func refresh() -> void:
	if runner == null or runner.hero == null:
		return
	var h := runner.hero
	var hearts := ""
	for i in h.max_hp:
		hearts += "♥" if i < h.hp else "♡"
	hp_label.text = hearts
	if h.max_fuel > 0.0:
		fuel_label.text = "Fuel " + "█".repeat(int(h.fuel)) + "░".repeat(maxi(0, int(h.max_fuel - h.fuel)))
	else:
		fuel_label.text = h.display_name
	var t := int(runner.elapsed)
	time_label.text = "%d:%02d" % [int(t / 60.0), t % 60]
	spark_label.text = "Spark %d" % int(SaveManager.active.get("spark", 0))
	var lines: PackedStringArray = PackedStringArray()
	var oi := 0
	for o in runner.def.get("objectives", []):
		var mark := "✓" if runner.obj_done.get(oi, false) else "•"
		lines.append("%s %s" % [mark, str(o.get("text", ""))])
		oi += 1
	obj_label.text = "   ".join(lines)
	var d: Dictionary = runner.def.get("dare", {})
	if d.is_empty():
		dare_label.text = ""
	else:
		dare_label.text = "Dare: %s   (View)" % str(d.get("text", ""))
