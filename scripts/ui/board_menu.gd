extends Control

var kind := "story"
var pending: Dictionary = {}


func setup(p_kind: String) -> void:
	kind = p_kind
	UIKit.full_rect(self)
	var bg := ColorRect.new()
	bg.color = Color("0B1B33")
	UIKit.full_rect(bg)
	add_child(bg)
	var titles := {"story": "STORY BOARD", "side": "SIDE BOARD", "trial": "HERO TRIALS", "challenge": "CHALLENGE BOARD", "secret": "SECRET"}
	UIKit.label(self, titles.get(kind, "BOARD"), Vector2(80, 40), 52, UIKit.GOLD)
	UIKit.label(self, "A select   B back   Gold = recommended hero bonus", Vector2(80, 100), 22, Color(1, 1, 1, 0.65))
	var ids: PackedStringArray
	match kind:
		"side":
			ids = Catalog.side_ids()
		"trial":
			ids = Catalog.trial_ids()
		"challenge":
			ids = Catalog.challenge_ids()
		_:
			ids = Catalog.story_ids()
	var col := 0
	var row := 0
	var first: Button
	for id in ids:
		var m := Catalog.get_mission(id)
		var unlocked := Catalog.is_unlocked(id)
		var cleared := id in SaveManager.active.get("cleared", [])
		var rank := str(SaveManager.active.get("ranks", {}).get(id, ""))
		var star := bool(SaveManager.active.get("stars", {}).get(id, false))
		var label := m.title
		if not unlocked:
			label = "???"
		elif cleared:
			label = "%s  [%s]%s" % [m.title, rank if rank != "" else "C", " ★" if star else ""]
		var b := UIKit.button(self, label, Rect2(80 + col * 620, 150 + row * 90, 580, 72))
		b.disabled = not unlocked
		if unlocked:
			var mid := id
			b.pressed.connect(func(): _pick(mid))
			if first == null:
				first = b
		col += 1
		if col > 1:
			col = 0
			row += 1
	if kind == "side" and Catalog.is_unlocked("x_overload"):
		var ob := UIKit.button(self, "OVERLOAD  (secret boss)", Rect2(80, 960, 580, 64))
		ob.pressed.connect(func(): _pick("x_overload"))
	var back := UIKit.button(self, "Back to HQ", Rect2(1500, 40, 320, 56))
	back.pressed.connect(func(): Game.show_hub())
	if first:
		first.grab_focus()
	else:
		back.grab_focus()


func _pick(id: String) -> void:
	AudioDirector.play("confirm")
	Game.show_hero_select(Catalog.get_mission(id))
