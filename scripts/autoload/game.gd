extends Node

var world: Node2D
var ui: CanvasLayer
var in_combat := false
var in_hub := false
var hub_interact_armed := false
var challenge_mods: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputSetup.ensure()
