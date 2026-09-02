extends Control

func _ready() -> void:
	UIKit.full_rect(self)
	var bg := TextureRect.new()
	bg.texture = Art.tex("title_keyart")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	UIKit.full_rect(bg)
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.08, 0.42)
	shade.position = Vector2(0, 0)
	shade.size = Vector2(820, 1080)
	add_child(shade)
	var fade := ColorRect.new()
	fade.color = Color(0.02, 0.03, 0.07, 0.28)
	fade.position = Vector2(0, 820)
	fade.size = Vector2(1920, 260)
	add_child(fade)
	UIKit.label(self, "HARBOR PULSE", Vector2(80, 70), 78, UIKit.GOLD, true)
	UIKit.label(self, "Three kids. One loud city. Save snack time.", Vector2(86, 168), 26, UIKit.TEAL)
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
		var b := UIKit.button(self, it[0], Rect2(86, 250 + i * 82, 400, 68))
		b.pressed.connect(it[1])
		if i == 0:
			first = b
		i += 1
	UIKit.label(self, "Xbox: A confirm   B back     Keyboard: Enter / Esc", Vector2(86, 980), 20, Color(1, 1, 1, 0.7))
	if first:
		first.grab_focus()


func _process(_delta: float) -> void:
	if Input.is_action_pressed("gadget") and Input.is_action_pressed("lockon") and Input.is_action_just_pressed("signature"):
		if SaveManager.slot_index < 0:
			SaveManager.use_slot(0, true)
		SaveManager.unlock_all_debug()
		VFX.text_pop(self, Vector2(960, 200), "PARENT UNLOCK", Color("F4C542"))
		AudioDirector.play("win")
