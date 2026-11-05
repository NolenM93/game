extends Node

const Hollow = preload("res://scripts/hollow/hollow_world.gd")


func _ready() -> void:
	if OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
	add_child(Hollow.new())
