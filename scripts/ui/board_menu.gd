extends Control

var kind := "story"


func setup(p_kind: String) -> void:
	kind = p_kind
	for c in get_children():
		c.queue_free()
	UIKit.full_rect(self)
	UIKit.art_bg(self, "bg_midtown", 0.62)
	var titles := {"story": "STORY", "side": "SIDE JOBS", "trial": "TRIALS", "challenge": "CHALLENGES", "secret": "SECRET"}
	UIKit.label(self, titles.get(kind, "BOARD"), Vector2(72, 36), 48, UIKit.GOLD, true)
	UIKit.label(self, "A select     B back     Gold hero = bonus Spark", Vector2(72, 96), 20, Color(1, 1, 1, 0.6))
	var tabs := [["story", "Story"], ["side", "Side"], ["trial", "Trials"], ["challenge", "Challenges"]]
	var tx := 72.0
	for t in tabs:
		var tb := UIKit.button(self, t[1], Rect2(tx, 130, 200, 48))
		if t[0] == kind:
			tb.modulate = Color(1.15, 1.05, 0.8)
		var kid: String = t[0]
		tb.pressed.connect(func(): Game.show_board(kid))
		tx += 214.0
	var back := UIKit.button(self, "Back to HQ", Rect2(1520, 36, 320, 52))
	back.pressed.connect(func(): Game.show_hub())
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
		var label := str(m.title)
		if not unlocked:
			label = "Locked"
		elif cleared:
			label = "%s   [%s]%s" % [m.title, rank if rank != "" else "C", "  ★" if star else ""]
		var b := UIKit.button(self, label, Rect2(72 + col * 620, 210 + row * 88, 580, 72))
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
		var ob := UIKit.button(self, "OVERLOAD   secret boss", Rect2(72, 980, 580, 60))
		ob.pressed.connect(func(): _pick("x_overload"))
	if first:
		first.grab_focus()
	else:
		back.grab_focus()


func _pick(id: String) -> void:
	AudioDirector.play("confirm")
	Game.show_hero_select(Catalog.get_mission(id))
