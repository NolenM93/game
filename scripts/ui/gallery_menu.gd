extends Control

func _ready() -> void:
	UIKit.full_rect(self)
	UIKit.art_bg(self, "bg_hub", 0.6)
	UIKit.label(self, "COMIC GALLERY", Vector2(80, 30), 48, UIKit.GOLD)
	UIKit.label(self, "%d / 30 panels   •   %d / 15 tokens" % [SaveManager.active.get("comics", []).size(), SaveManager.active.get("tokens", []).size()], Vector2(80, 90), 24, UIKit.TEAL)
	var comics: Dictionary = Catalog.comics()
	var i := 0
	for id in comics.keys():
		var owned := id in SaveManager.active.get("comics", [])
		var p := UIKit.panel(self, Rect2(60 + (i % 6) * 300, 140 + int(i / 6) * 150, 280, 130), Color("1A3358AA") if owned else Color("101018AA"))
		var title := str(comics[id].title) if owned else "???"
		UIKit.label(p, title, Vector2(12, 10), 18, UIKit.GOLD)
		if owned:
			var l := UIKit.label(p, str(comics[id].text), Vector2(12, 40), 16, UIKit.PAPER)
			l.size = Vector2(250, 80)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		i += 1
	var back := UIKit.button(self, "Back", Rect2(80, 1000, 240, 52))
	back.pressed.connect(func(): Game.show_hub())
	back.grab_focus()
