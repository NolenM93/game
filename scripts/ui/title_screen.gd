extends Control

func _ready() -> void:
	UIKit.full_rect(self)
	UIKit.art_bg(self, "title_keyart", 0.22)
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.04, 0.03, 0.55)
	shade.position = Vector2(0, 0)
	shade.size = Vector2(720, 1080)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	UIKit.label(self, "HARBOR PULSE", Vector2(72, 64), 72, UIKit.GOLD, true)
	UIKit.label(self, "Three kids. One loud city. Save snack time.", Vector2(76, 150), 24, UIKit.TEAL)
	var items := [
		["New Game", func(): Game.show_slots(true)],
		["Continue", func(): Game.show_slots(false)],
		["Sandbox Gym", func(): Game.show_sandbox()],
		["Options", func(): Game.open_options(self)],
		["Credits", func(): Game.show_credits({})],
		["Quit", func(): get_tree().quit()]
	]
	var i := 0
	var first: Button
	for it in items:
		var b := UIKit.button(self, it[0], Rect2(76, 230 + i * 86, 420, 70))
		b.pressed.connect(it[1])
		if i == 0:
			first = b
		i += 1
	UIKit.label(self, "Xbox  A confirm   B back        Keyboard  Enter / Esc", Vector2(76, 990), 18, Color(1, 1, 1, 0.55))
	if first:
		first.grab_focus()


func _process(_delta: float) -> void:
	if Input.is_action_pressed("gadget") and Input.is_action_pressed("lockon") and Input.is_action_just_pressed("signature"):
		if SaveManager.slot_index < 0:
			SaveManager.use_slot(0, true)
		SaveManager.unlock_all_debug()
		VFX.text_pop(self, Vector2(960, 200), "PARENT UNLOCK", Color("E8C45A"))
		AudioDirector.play("win")
