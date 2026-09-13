extends Control

var mission: Dictionary = {}


func setup(m: Dictionary) -> void:
	mission = m
	UIKit.full_rect(self)
	UIKit.art_bg(self, Art.district_bg(str(m.get("district", "midtown"))), 0.58)
	UIKit.label(self, str(m.title), Vector2(72, 40), 48, UIKit.GOLD, true)
	UIKit.label(self, str(m.get("blurb", "")), Vector2(72, 108), 24, UIKit.PAPER)
	UIKit.label(self, "Recommended: %s     (bonus Spark)" % str(m.get("recommended", "any")).capitalize(), Vector2(72, 160), 22, UIKit.TEAL)
	var heroes := ["sling", "titan", "forge"]
	var lock := str(m.get("hero_lock", ""))
	var x := 72.0
	var first: Button
	for h in heroes:
		if lock != "" and h != lock:
			continue
		var card := UIKit.panel(self, Rect2(x, 230, 400, 520))
		var spr := TextureRect.new()
		spr.texture = Art.tex("hero_%s_idle" % h)
		spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		spr.position = Vector2(40, 30)
		spr.size = Vector2(320, 340)
		card.add_child(spr)
		var unlocked := SaveManager.is_hero_unlocked(h)
		var b := UIKit.button(card, h.capitalize() if unlocked else "Locked", Rect2(40, 400, 320, 70))
		b.disabled = not unlocked
		if unlocked:
			var hid := h
			b.pressed.connect(func():
				SaveManager.active["last_hero"] = hid
				Game.start_mission(mission, hid)
			)
			if first == null:
				first = b
		x += 440.0
	var back := UIKit.button(self, "Back", Rect2(72, 780, 240, 56))
	back.pressed.connect(func(): Game.show_board(str(m.get("kind", "story"))))
	if first:
		first.grab_focus()
