extends Control

var new_game := true

func setup(p_new: bool) -> void:
	new_game = p_new
	UIKit.full_rect(self)
	var bg := ColorRect.new()
	bg.color = Color("070B14")
	UIKit.full_rect(bg)
	add_child(bg)
	UIKit.label(self, "NEW GAME" if new_game else "CONTINUE", Vector2(140, 80), 56, UIKit.GOLD)
	for i in 3:
		var has := SaveManager.has_slot(i)
		var data := SaveManager.load_slot(i)
		var title := "Empty slot"
		var sub := "Start a new Harbor story"
		if has:
			title = "Slot %d  •  Spark %d" % [i + 1, int(data.get("spark", 0))]
			sub = "Cleared %d  •  %s" % [data.get("cleared", []).size(), "NG+" if data.get("ng_plus") else "Story"]
			if data.get("drain_beaten"):
				sub += "  •  Drain down"
		var panel := UIKit.panel(self, Rect2(140, 200 + i * 200, 1100, 170))
		UIKit.label(panel, title, Vector2(30, 24), 32, UIKit.PAPER)
		UIKit.label(panel, sub, Vector2(30, 80), 24, UIKit.TEAL)
		var b := UIKit.button(panel, "Select" if (has or new_game) else "Empty", Rect2(780, 50, 280, 70))
		var idx := i
		b.pressed.connect(func(): _pick(idx, has))
		if has and not new_game:
			var d := UIKit.button(panel, "Erase", Rect2(780, 50, 0, 0))
			d.position = Vector2(780, 50)
			d.size = Vector2(0, 0)
		if i == 0:
			b.grab_focus()
	var ng := UIKit.button(self, "New Game+ (needs a beaten save)", Rect2(140, 840, 520, 64))
	ng.pressed.connect(_ng)
	var back := UIKit.button(self, "Back", Rect2(700, 840, 220, 64))
	back.pressed.connect(func(): Game.show_title())


func _pick(i: int, has: bool) -> void:
	AudioDirector.play("confirm")
	if new_game:
		SaveManager.use_slot(i, true, false)
		Game.show_hub()
	else:
		if not has:
			SaveManager.use_slot(i, true, false)
		else:
			SaveManager.use_slot(i, false)
		Game.show_hub()


func _ng() -> void:
	for i in 3:
		var d := SaveManager.load_slot(i)
		if d.get("drain_beaten", false):
			SaveManager.use_slot(i, true, true)
			Game.show_hub()
			return
	AudioDirector.play("lose")
