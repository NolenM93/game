extends Node

var _sfx: Dictionary = {}
var _music: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _combat_player: AudioStreamPlayer
var current_bed := ""
var combat_blend := 0.0


func _ready() -> void:
	_ensure_buses()
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)
	_combat_player = AudioStreamPlayer.new()
	_combat_player.bus = "Music"
	_combat_player.volume_db = -40
	add_child(_combat_player)
	for i in 10:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	_build_library()
	play_music("title")


func _process(delta: float) -> void:
	var target := 1.0 if Game.in_combat else 0.0
	combat_blend = move_toward(combat_blend, target, delta * 1.6)
	_combat_player.volume_db = linear_to_db(clampf(combat_blend * Settings.music_vol * 0.45, 0.0001, 1.0))


func play(id: String, pitch: float = 1.0) -> void:
	if not _sfx.has(id):
		id = "blip"
	for p in _sfx_players:
		if not p.playing:
			p.stream = _sfx[id]
			p.pitch_scale = pitch
			p.play()
			return
	_sfx_players[0].stream = _sfx[id]
	_sfx_players[0].play()


func play_music(id: String) -> void:
	if current_bed == id:
		return
	current_bed = id
	if not _music.has(id):
		id = "hub"
	_music_player.stream = _music[id]
	_music_player.play()
	if _music.has(id + "_combat"):
		_combat_player.stream = _music[id + "_combat"]
		_combat_player.play()
	elif _music.has("combat"):
		_combat_player.stream = _music["combat"]
		_combat_player.play()


func _ensure_buses() -> void:
	if AudioServer.get_bus_index("Music") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	if AudioServer.get_bus_index("SFX") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")


func _build_library() -> void:
	_sfx["blip"] = _tone(880, 0.08, 0.3, "square")
	_sfx["whoosh"] = _noise(0.18, 0.25, 900)
	_sfx["thud"] = _tone(90, 0.16, 0.5, "sine")
	_sfx["whoom"] = _tone(140, 0.28, 0.45, "square")
	_sfx["hit"] = _tone(220, 0.07, 0.4, "square")
	_sfx["hit2"] = _tone(330, 0.06, 0.35, "square")
	_sfx["spark"] = _tone(1200, 0.05, 0.25, "sine")
	_sfx["bolt"] = _tone(640, 0.09, 0.3, "saw")
	_sfx["charge"] = _tone(180, 0.2, 0.25, "saw")
	_sfx["jump"] = _tone(420, 0.1, 0.25, "sine")
	_sfx["land"] = _tone(110, 0.08, 0.3, "sine")
	_sfx["pickup"] = _tone(980, 0.12, 0.3, "sine")
	_sfx["hurt"] = _tone(160, 0.2, 0.4, "square")
	_sfx["win"] = _arpeggio([523, 659, 784, 1046], 0.12)
	_sfx["lose"] = _arpeggio([392, 330, 262], 0.16)
	_sfx["ui"] = _tone(700, 0.05, 0.2, "square")
	_sfx["confirm"] = _tone(880, 0.09, 0.25, "square")
	_sfx["shield"] = _tone(500, 0.14, 0.3, "sine")
	_sfx["surge"] = _tone(70, 0.3, 0.5, "saw")
	_sfx["alarm"] = _tone(740, 0.15, 0.25, "square")
	_sfx["boss"] = _arpeggio([110, 146, 110, 164], 0.1)
	_music["title"] = _song([262, 330, 392, 330, 349, 392, 523, 392], 0.28, 0.18)
	_music["hub"] = _song([196, 247, 294, 247, 220, 262, 330, 294], 0.32, 0.16)
	_music["midtown"] = _song([220, 277, 330, 277, 246, 330, 440, 330], 0.26, 0.17)
	_music["docks"] = _song([174, 220, 261, 220, 196, 246, 329, 261], 0.3, 0.16)
	_music["grid"] = _song([155, 196, 233, 196, 185, 233, 311, 233], 0.24, 0.18)
	_music["combat"] = _song([130, 164, 196, 164, 146, 196, 261, 196], 0.16, 0.2)
	_music["boss"] = _song([98, 123, 146, 116, 98, 130, 164, 110], 0.18, 0.22)
	_music["credits"] = _song([261, 329, 392, 523, 392, 329, 349, 440], 0.34, 0.15)


func _tone(freq: float, dur: float, vol: float, wave: String) -> AudioStreamWAV:
	return _render(dur, vol, func(t: float) -> float:
		var ph := t * freq
		match wave:
			"square":
				return 1.0 if fmod(ph, 1.0) < 0.5 else -1.0
			"saw":
				return fmod(ph, 1.0) * 2.0 - 1.0
			_:
				return sin(ph * TAU)
	)


func _noise(dur: float, vol: float, cutoff: float) -> AudioStreamWAV:
	var prev := 0.0
	return _render(dur, vol, func(_t: float) -> float:
		var n := randf() * 2.0 - 1.0
		prev = prev + (n - prev) * clampf(cutoff / 8000.0, 0.05, 1.0)
		return prev
	)


func _arpeggio(notes: Array, step: float) -> AudioStreamWAV:
	var dur := step * notes.size()
	return _render(dur, 0.28, func(t: float) -> float:
		var idx := clampi(int(t / step), 0, notes.size() - 1)
		return sin(t * float(notes[idx]) * TAU) 
	)


func _song(notes: Array, step: float, vol: float) -> AudioStreamWAV:
	var loops := 4
	var dur := step * notes.size() * loops
	var s := _render(dur, vol, func(t: float) -> float:
		var total := notes.size()
		var idx := int(fmod(t / step, float(total)))
		var freq := float(notes[idx])
		var local := fmod(t, step)
		var env := 1.0
		if local < 0.02:
			env = local / 0.02
		var tail := step - local
		if tail < 0.05:
			env *= tail / 0.05
		var bass := sin(t * freq * 0.5 * TAU) * 0.35
		return (sin(t * freq * TAU) * 0.7 + bass) * env
	)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_end = s.data.size() / 2
	return s


func _render(dur: float, vol: float, fn: Callable) -> AudioStreamWAV:
	var sr := 22050
	var n := int(sr * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(sr)
		var env := 1.0
		var fade := 0.01
		if t < fade:
			env = t / fade
		if t > dur - fade:
			env = maxf(0.0, (dur - t) / fade)
		var v := int(clampf(fn.call(t) * env * vol, -1.0, 1.0) * 32000.0)
		data[i * 2] = v & 255
		data[i * 2 + 1] = (v >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sr
	stream.stereo = false
	stream.data = data
	return stream
