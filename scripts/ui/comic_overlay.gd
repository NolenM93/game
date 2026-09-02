extends Control

var pages: Array = []
var idx := 0
var art: ColorRect
var caption: Label
var title_l: Label


func _ready() -> void:
	UIKit.full_rect(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	UIKit.dimmer(self)
	UIKit.panel(self, Rect2(360, 140, 1200, 800), Color("0B1B33F0"))
	title_l = UIKit.label(self, "COMIC", Vector2(420, 180), 40, UIKit.GOLD)
	art = ColorRect.new()
	art.position = Vector2(430, 250)
	art.size = Vector2(1060, 420)
	art.color = Color("1A3358")
	add_child(art)
	caption = UIKit.label(self, "", Vector2(430, 700), 30, UIKit.PAPER)
	caption.size = Vector2(1060, 120)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIKit.label(self, "A / Enter  next page", Vector2(430, 860), 22, Color(1, 1, 1, 0.7))


func show_comic(id: String) -> void:
	var c: Dictionary = Catalog.story_comics().get(id, {})
	title_l.text = str(c.get("title", "Story"))
	pages = c.get("pages", [{"caption": "Harbor City holds its breath.", "art": "midtown"}])
	idx = 0
	_show()


func _show() -> void:
	if idx >= pages.size():
		queue_free()
		return
	var p: Dictionary = pages[idx]
	caption.text = str(p.get("caption", ""))
	match str(p.get("art", "midtown")):
		"docks":
			art.color = Color("1A3A58")
		"grid":
			art.color = Color("070B14")
		"sling":
			art.color = Color("0A3A38")
		"titan":
			art.color = Color("4A3010")
		"forge":
			art.color = Color("102048")
		_:
			art.color = Color("1A3358")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") or event.is_action_pressed("attack"):
		idx += 1
		AudioDirector.play("ui")
		_show()
		get_viewport().set_input_as_handled()
