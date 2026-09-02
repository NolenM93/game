extends Control

var tip: Label
var tleft := 0.0


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip = UIKit.label(self, "", Vector2(360, 140), 28, Color("F4EFE2"))
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.size = Vector2(1200, 80)
	modulate.a = 0.0


func show_tip(text: String) -> void:
	tip.text = text
	tleft = 4.2
	modulate.a = 1.0


func _process(delta: float) -> void:
	if tleft > 0.0:
		tleft -= delta
		if tleft < 0.8:
			modulate.a = tleft / 0.8
	else:
		modulate.a = 0.0
