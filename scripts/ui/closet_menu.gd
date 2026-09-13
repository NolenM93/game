extends Control

func _ready() -> void:
	UIKit.full_rect(self)
	UIKit.art_bg(self, "bg_hub", 0.58)
	UIKit.label(self, "COSTUME CLOSET", Vector2(80, 40), 48, UIKit.GOLD)
	var x := 80.0
	for hero in ["sling", "titan", "forge"]:
		UIKit.label(self, hero.capitalize(), Vector2(x, 120), 28, UIKit.TEAL)
		var y := 170.0
		for c in Catalog.costumes()[hero]:
			var owned := c in SaveManager.active.get("costumes_owned", {}).get(hero, [])
			var eq := str(SaveManager.active.get("costumes_eq", {}).get(hero, "classic")) == c
			var t := c.replace("_", " ")
			if eq:
				t = "▶ " + t
			if not owned:
				t += "  (locked)"
			var b := UIKit.button(self, t, Rect2(x, y, 500, 56))
			b.disabled = not owned
			var hid := hero
			var cid := c
			b.pressed.connect(func():
				var eqd: Dictionary = SaveManager.active.get("costumes_eq", {})
				eqd[hid] = cid
				SaveManager.active["costumes_eq"] = eqd
				SaveManager.save_now()
				AudioDirector.play("confirm")
				Game.show_closet()
			)
			y += 66
		x += 560
	var back := UIKit.button(self, "Back", Rect2(80, 980, 240, 56))
	back.pressed.connect(func(): Game.show_hub())
	back.grab_focus()
