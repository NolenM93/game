extends Control

var tip: Label
var tleft := 0.0


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip = UIKit.label(self, "", Vector2(240, 880), 24, Color("F3E6D0"))
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.size = Vector2(1440, 60)
	modulate.a = 0.0


func show_tip(text: String) -> void:
	tip.text = text
	tleft = 3.6
	modulate.a = 1.0


func _process(delta: float) -> void:
	if tleft > 0.0:
		tleft -= delta
		if tleft < 0.7:
			modulate.a = tleft / 0.7
	else:
		modulate.a = 0.0
