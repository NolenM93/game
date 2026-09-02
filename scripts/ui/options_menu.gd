extends Control

func setup(_host: Node = null) -> void:
	UIKit.full_rect(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIKit.dimmer(self)
	UIKit.panel(self, Rect2(420, 80, 1080, 920))
	UIKit.label(self, "OPTIONS", Vector2(460, 110), 48, UIKit.GOLD)
	_slider("Music", 200, Settings.music_vol, func(v):
		Settings.music_vol = v
		Settings.apply()
	)
	_slider("Sound", 280, Settings.sfx_vol, func(v):
		Settings.sfx_vol = v
		Settings.apply()
	)
	_slider("Shake", 360, Settings.shake, func(v): Settings.shake = v)
	_slider("Aim assist", 440, Settings.aim_assist, func(v): Settings.aim_assist = v)
	var diffs := ["story", "hero", "super"]
	UIKit.label(self, "Difficulty: %s  (left/right on buttons)" % Settings.difficulty, Vector2(460, 540), 26, UIKit.PAPER)
	var di := 0
	for d in diffs:
		var b := UIKit.button(self, d.capitalize(), Rect2(460 + di * 220, 590, 200, 56))
		var name := d
		b.pressed.connect(func():
			Settings.difficulty = name
			SaveManager.active["difficulty"] = name
			AudioDirector.play("ui")
			queue_redraw()
		)
		di += 1
	_toggle("Reduced flash", 680, Settings.reduced_flash, func(v): Settings.reduced_flash = v)
	_toggle("Large HUD", 750, Settings.large_hud, func(v): Settings.large_hud = v)
	_toggle("Invert fly aim", 820, Settings.invert_fly, func(v): Settings.invert_fly = v)
	_toggle("Fullscreen", 890, Settings.fullscreen, func(v):
		Settings.fullscreen = v
		Settings.apply()
	)
	var close := UIKit.button(self, "Save & Close", Rect2(460, 940, 300, 56))
	close.pressed.connect(func():
		Settings.save_settings()
		SaveManager.save_now()
		queue_free()
	)
	close.grab_focus()


func _slider(title: String, y: float, value: float, cb: Callable) -> void:
	UIKit.label(self, title, Vector2(460, y), 24, UIKit.PAPER)
	var s := HSlider.new()
	s.min_value = 0
	s.max_value = 1
	s.step = 0.05
	s.value = value
	s.position = Vector2(700, y + 8)
	s.size = Vector2(640, 24)
	s.value_changed.connect(func(v): cb.call(v))
	add_child(s)


func _toggle(title: String, y: float, on: bool, cb: Callable) -> void:
	var b := UIKit.button(self, title + (": ON" if on else ": OFF"), Rect2(460, y, 420, 52))
	b.pressed.connect(func():
		var nv := not on
		cb.call(nv)
		b.text = title + (": ON" if nv else ": OFF")
		on = nv
	)
