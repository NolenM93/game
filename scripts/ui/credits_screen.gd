extends Control

var lines := [
	"HARBOR PULSE",
	"",
	"A superhero game for a kid who deserves a real one.",
	"",
	"HEROES",
	"Sling — ribbons, rooftops, pendulum swagger",
	"Titan — stone armor, dumpsters, kind thunder",
	"Forge — scrap jets, travel-time bolts, extra batteries",
	"",
	"VILLAINS",
	"Riptide  •  Gridlock  •  Brownout  •  The Drain  •  Overload",
	"",
	"HARBOR CITY",
	"Mira keeps the comic shop flashlight-taped and hopeful.",
	"Coach yells encouragement at a dummy named Steve.",
	"Spark the HQ bot beeps a pep talk on request.",
	"",
	"No spiders. No borrowed billionaires. No green rage.",
	"Just three friends plugging the city back in.",
	"",
	"Thanks for playing.",
	"Press A to return to Harbor HQ — the board is still lit."
]
var scroll := 0.0


func setup(_res: Dictionary = {}) -> void:
	UIKit.full_rect(self)
	var bg := ColorRect.new()
	bg.color = Color("070B14")
	UIKit.full_rect(bg)
	add_child(bg)
	AudioDirector.play_music("credits")
	if SaveManager.overload_ready():
		lines.append("")
		lines.append("Post-credits: a gold stamp appears on the side board.")
		lines.append("OVERLOAD is waiting.")


func _process(delta: float) -> void:
	scroll += delta * 42.0
	queue_redraw()
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump") or scroll > 1400.0:
		if SaveManager.slot_index >= 0:
			Game.show_hub()
		else:
			Game.show_title()


func _draw() -> void:
	var y := 900.0 - scroll
	for s in lines:
		draw_string(ThemeDB.fallback_font, Vector2(200, y), s, HORIZONTAL_ALIGNMENT_LEFT, 1520.0, 36, Color("F4EFE2"))
		y += 48.0
