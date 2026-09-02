extends Control

var runner: MissionRunner


func setup(r: MissionRunner) -> void:
	runner = r
	UIKit.full_rect(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIKit.dimmer(self)
	UIKit.panel(self, Rect2(660, 220, 600, 640))
	UIKit.label(self, "PAUSED", Vector2(840, 260), 48, UIKit.GOLD)
	var b1 := UIKit.button(self, "Resume  (Start / B)", Rect2(740, 360, 440, 64))
	var b2 := UIKit.button(self, "Retry checkpoint", Rect2(740, 440, 440, 64))
	var b3 := UIKit.button(self, "Options", Rect2(740, 520, 440, 64))
	var b4 := UIKit.button(self, "Quit to Harbor HQ", Rect2(740, 600, 440, 64))
	b1.pressed.connect(func(): runner.toggle_pause())
	b2.pressed.connect(func():
		if runner.hero:
			runner.hero.hp = runner.hero.max_hp
			runner.hero.global_position = runner.hero.spawn_pos
			runner.hero.hp_changed.emit(runner.hero.hp, runner.hero.max_hp)
		runner.toggle_pause()
	)
	b3.pressed.connect(func(): Game.open_options(self))
	b4.pressed.connect(func(): runner.quit_to_hub())
	b1.grab_focus()
