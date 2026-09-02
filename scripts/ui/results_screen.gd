extends Control

var res: Dictionary = {}


func setup(p: Dictionary) -> void:
	res = p
	UIKit.full_rect(self)
	UIKit.dimmer(self)
	UIKit.panel(self, Rect2(460, 120, 1000, 840))
	var win := bool(p.get("win", false))
	UIKit.label(self, "MISSION CLEAR" if win else "MISSION FAILED", Vector2(560, 160), 48, UIKit.GOLD if win else Color("FF8A8A"))
	UIKit.label(self, str(p.get("def", {}).get("title", "")), Vector2(560, 230), 32, UIKit.PAPER)
	if win:
		UIKit.label(self, "Rank  %s" % str(p.get("rank", "C")), Vector2(560, 310), 64, Color("2EE6C7"))
		UIKit.label(self, "Spark +%d" % int(p.get("spark", 0)), Vector2(560, 390), 32, UIKit.GOLD)
		UIKit.label(self, "Time  %.1fs" % float(p.get("time", 0)), Vector2(560, 440), 28, UIKit.PAPER)
		if p.get("star", false):
			UIKit.label(self, "★ Dare complete!", Vector2(560, 490), 30, UIKit.GOLD)
	else:
		UIKit.label(self, str(p.get("why", "Knocked out")), Vector2(560, 320), 32, UIKit.PAPER)
	var b1 := UIKit.button(self, "Harbor HQ", Rect2(560, 640, 360, 64))
	var b2 := UIKit.button(self, "Play again", Rect2(560, 720, 360, 64))
	b1.pressed.connect(func(): Game.show_hub())
	b2.pressed.connect(func(): Game.start_mission(p.get("def", {}), str(p.get("hero", "sling"))))
	b1.grab_focus()
	if win and str(p.get("def", {}).get("id", "")) == "s12":
		UIKit.label(self, "The city breathes. Credits incoming...", Vector2(560, 540), 24, Color("2EE6C7"))
