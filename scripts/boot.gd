extends Node

const Hollow = preload("res://scripts/hollow/hollow_world.gd")


func _ready() -> void:
	add_child(Hollow.new())
