extends Node

signal changed

var music_vol: float = 0.8
var sfx_vol: float = 0.9
var shake: float = 1.0
var aim_assist: float = 0.8
var reduced_flash: bool = false
var large_hud: bool = false
var invert_fly: bool = false
var fullscreen: bool = false
var difficulty: String = "story"

func _ready() -> void:
	load_settings()
	apply()


func apply() -> void:
	_bus_vol("Music", music_vol)
	_bus_vol("SFX", sfx_vol)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	changed.emit()


func _bus_vol(bus: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))
	if linear <= 0.01:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)


func i_frames_mult() -> float:
	match difficulty:
		"story":
			return 1.6
		"super":
			return 0.7
		_:
			return 1.0


func damage_in_mult() -> float:
	match difficulty:
		"story":
			return 0.7
		"super":
			return 1.35
		_:
			return 1.0


func enemy_hp_mult() -> float:
	var m := 1.0
	match difficulty:
		"story":
			m = 0.8
		"super":
			m = 1.35
	if SaveManager.active.get("ng_plus", false):
		m *= 1.35
	return m


func assist() -> float:
	return clampf(aim_assist, 0.0, 1.0)


func load_settings() -> void:
	var p := ConfigFile.new()
	if p.load("user://settings.cfg") != OK:
		return
	music_vol = float(p.get_value("a", "music", music_vol))
	sfx_vol = float(p.get_value("a", "sfx", sfx_vol))
	shake = float(p.get_value("a", "shake", shake))
	aim_assist = float(p.get_value("a", "assist", aim_assist))
	reduced_flash = bool(p.get_value("a", "flash", reduced_flash))
	large_hud = bool(p.get_value("a", "hud", large_hud))
	invert_fly = bool(p.get_value("a", "invert", invert_fly))
	fullscreen = bool(p.get_value("a", "full", fullscreen))
	difficulty = str(p.get_value("a", "diff", difficulty))


func save_settings() -> void:
	var p := ConfigFile.new()
	p.set_value("a", "music", music_vol)
	p.set_value("a", "sfx", sfx_vol)
	p.set_value("a", "shake", shake)
	p.set_value("a", "assist", aim_assist)
	p.set_value("a", "flash", reduced_flash)
	p.set_value("a", "hud", large_hud)
	p.set_value("a", "invert", invert_fly)
	p.set_value("a", "full", fullscreen)
	p.set_value("a", "diff", difficulty)
	p.save("user://settings.cfg")
