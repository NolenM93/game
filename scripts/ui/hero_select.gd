extends Control

var mission: Dictionary = {}


func setup(m: Dictionary) -> void:
	mission = m
	UIKit.full_rect(self)
	var bg := ColorRect.new()
	bg.color = Color("070B14")
	UIKit.full_rect(bg)
	add_child(bg)
	UIKit.label(self, m.title, Vector2(80, 50), 48, UIKit.GOLD)
	UIKit.label(self, str(m.get("blurb", "")), Vector2(80, 120), 26, UIKit.PAPER)
	UIKit.label(self, "Recommended: %s  (bonus Spark)" % str(m.get("recommended", "any")).capitalize(), Vector2(80, 180), 24, UIKit.TEAL)
	var heroes := ["sling", "titan", "forge"]
	var lock := str(m.get("hero_lock", ""))
	var x := 80.0
	var first: Button
	for h in heroes:
		if lock != "" and h != lock:
			continue
		if not SaveManager.is_hero_unlocked(h):
			var locked := UIKit.button(self, h.capitalize() + " (locked)", Rect2(x, 280, 360, 420))
			locked.disabled = true
			x += 400
			continue
		var b := UIKit.button(self, h.capitalize(), Rect2(x, 280, 360, 420))
		var hid := h
		b.pressed.connect(func():
			SaveManager.active["last_hero"] = hid
			Game.start_mission(mission, hid)
		)
		if first == null:
			first = b
		x += 400
	var back := UIKit.button(self, "Back", Rect2(80, 760, 240, 56))
	back.pressed.connect(func(): Game.show_hub())
	if first:
		first.grab_focus()
