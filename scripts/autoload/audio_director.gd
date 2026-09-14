extends Node

var _sfx: Dictionary = {}
var _music: Dictionary = {}
var _music_recipes: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx3d: Array[AudioStreamPlayer3D] = []
var _music_player: AudioStreamPlayer
var _combat_player: AudioStreamPlayer
var current_bed := ""
var combat_blend := 0.0
var _last_play: Dictionary = {}
var _lp_prev := 0.0
var _lp_t := -1.0


func _ready() -> void:
	_ensure_buses()
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)
	_combat_player = AudioStreamPlayer.new()
	_combat_player.bus = "Music"
	_combat_player.volume_db = -40
	add_child(_combat_player)
	for i in 16:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	for i in 14:
		var p := AudioStreamPlayer3D.new()
		p.bus = "SFX"
		p.unit_size = 13.0
		p.max_db = 2.0
		p.max_distance = 90.0
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(p)
		_sfx3d.append(p)
	_build_library()


func _process(delta: float) -> void:
	var target := 1.0 if Game.in_combat else 0.0
	combat_blend = move_toward(combat_blend, target, delta * 1.1)
	_combat_player.volume_db = linear_to_db(clampf(combat_blend * Settings.music_vol * 0.5, 0.0001, 1.0))


func play(id: String, pitch: float = 1.0) -> void:
	if not _sfx.has(id):
		id = "blip"
	if _throttled(id):
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = _sfx[id]
			p.pitch_scale = pitch
			p.play()
			return
	_sfx_players[0].stream = _sfx[id]
	_sfx_players[0].pitch_scale = pitch
	_sfx_players[0].play()


## Positional one-shot heard from the camera.
func play_at(id: String, pos: Vector3, pitch: float = 1.0) -> void:
	if not _sfx.has(id):
		id = "blip"
	if _throttled(id):
		return
	var best: AudioStreamPlayer3D = null
	for p in _sfx3d:
		if not p.playing:
			best = p
			break
	if best == null:
		best = _sfx3d[0]
	best.global_position = pos
	best.stream = _sfx[id]
	best.pitch_scale = pitch
	best.play()


func _throttled(id: String) -> bool:
	# The same sample a few ms apart only adds mud.
	var now := Time.get_ticks_msec()
	var last: int = int(_last_play.get(id, -1000))
	if now - last < 18:
		return true
	_last_play[id] = now
	return false


func _song_for(id: String) -> AudioStreamWAV:
	if _music.has(id):
		return _music[id]
	if _music_recipes.has(id):
		var s: AudioStreamWAV = (_music_recipes[id] as Callable).call()
		_music[id] = s
		return s
	return null


func play_music(id: String) -> void:
	if current_bed == id:
		return
	current_bed = id
	var bed := _song_for(id)
	if bed == null:
		bed = _song_for("hub")
		if bed == null:
			return
	_music_player.stream = bed
	_music_player.play()
	var layer := _song_for(id + "_combat")
	if layer == null and id != "hollow":
		layer = _song_for("combat")
	if layer:
		_combat_player.stream = layer
		_combat_player.play()
	else:
		_combat_player.stop()


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
	# UI / generic
	_sfx["blip"] = _tone(880, 0.08, 0.3, "square")
	_sfx["ui"] = _perc(0.06, 0.22, func(t: float) -> float:
		return _wave(_sweep(t, 760.0, 640.0, 0.06), "square") * exp(-t * 40.0)
	)
	_sfx["confirm"] = _perc(0.16, 0.26, func(t: float) -> float:
		var n := 660.0 if t < 0.07 else 990.0
		var lt := t if t < 0.07 else t - 0.07
		return sin(t * n * TAU) * exp(-lt * 22.0)
	)
	_sfx["pickup"] = _arpeggio([784, 988, 1175], 0.07)
	_sfx["win"] = _arpeggio([523, 659, 784, 1046], 0.12)
	_sfx["lose"] = _arpeggio([392, 330, 262], 0.16)
	_sfx["alarm"] = _perc(0.42, 0.24, func(t: float) -> float:
		var f := 740.0 if fmod(t, 0.16) < 0.08 else 620.0
		return _wave(t * f, "square") * 0.7
	)
	_sfx["boss"] = _arpeggio([110, 146, 110, 164], 0.1)
	_sfx["charge"] = _perc(0.38, 0.26, func(t: float) -> float:
		return _wave(_sweep(t, 110.0, 540.0, 0.38), "saw") * (0.3 + 0.7 * t / 0.38)
	)
	# hunter
	_sfx["shotgun"] = _perc(0.32, 0.62, func(t: float) -> float:
		var n := _noise_lp(t, 1400.0) * exp(-t * 15.0)
		var thump := sin(_sweep(t, 150.0, 48.0, 0.3) * TAU) * exp(-t * 11.0)
		var click := _wave(t * 2400.0, "square") * exp(-t * 180.0) * 0.5
		return n * 0.8 + thump * 0.9 + click
	)
	_sfx["shoot"] = _perc(0.1, 0.42, func(t: float) -> float:
		var body := _wave(_sweep(t, 980.0, 280.0, 0.1), "square") * exp(-t * 38.0)
		var n := _noise_lp(t, 3000.0) * exp(-t * 70.0)
		return body * 0.7 + n * 0.6
	)
	_sfx["gloop"] = _perc(0.2, 0.36, func(t: float) -> float:
		var f := _sweep(t, 320.0, 110.0, 0.2)
		return sin(f * TAU + sin(t * 60.0) * 0.6) * exp(-t * 11.0)
	)
	_sfx["whoom"] = _perc(0.38, 0.46, func(t: float) -> float:
		var n := _noise_lp(t, 650.0) * exp(-t * 7.0)
		var s := _wave(_sweep(t, 210.0, 70.0, 0.38), "saw") * exp(-t * 9.0)
		return n * 0.8 + s * 0.5
	)
	_sfx["reload"] = _perc(0.24, 0.3, func(t: float) -> float:
		var lt := t if t < 0.12 else t - 0.12
		var f := 520.0 if t < 0.12 else 420.0
		return (_noise_lp(t, 2500.0) * 0.6 + _wave(lt * f, "square") * 0.5) * exp(-lt * 60.0)
	)
	_sfx["whoosh"] = _perc(0.2, 0.26, func(t: float) -> float:
		return _noise_lp(t, 1100.0) * sin(PI * clampf(t / 0.2, 0.0, 1.0))
	)
	_sfx["step"] = _perc(0.07, 0.13, func(t: float) -> float:
		return _noise_lp(t, 420.0) * exp(-t * 55.0)
	)
	_sfx["jump"] = _perc(0.14, 0.24, func(t: float) -> float:
		return sin(_sweep(t, 330.0, 620.0, 0.14) * TAU) * exp(-t * 14.0)
	)
	_sfx["land"] = _perc(0.1, 0.3, func(t: float) -> float:
		return sin(_sweep(t, 120.0, 60.0, 0.1) * TAU) * exp(-t * 26.0)
	)
	_sfx["hurt"] = _perc(0.28, 0.42, func(t: float) -> float:
		return _wave(_sweep(t, 270.0, 120.0, 0.28), "square") * exp(-t * 9.0)
	)
	# world / zeds
	_sfx["hit"] = _perc(0.08, 0.36, func(t: float) -> float:
		return _wave(_sweep(t, 300.0, 180.0, 0.08), "square") * exp(-t * 32.0)
	)
	_sfx["hit2"] = _perc(0.09, 0.36, func(t: float) -> float:
		var s := _wave(_sweep(t, 420.0, 220.0, 0.09), "square") * exp(-t * 30.0)
		return s * 0.7 + _noise_lp(t, 2200.0) * exp(-t * 90.0) * 0.5
	)
	_sfx["limb"] = _perc(0.18, 0.36, func(t: float) -> float:
		var s := _wave(_sweep(t, 460.0, 170.0, 0.18), "square") * exp(-t * 13.0)
		return s * 0.6 + _noise_lp(t, 1600.0) * exp(-t * 28.0) * 0.5
	)
	_sfx["splat"] = _perc(0.26, 0.46, func(t: float) -> float:
		var n := _noise_lp(t, 760.0) * exp(-t * 11.0)
		var s := sin(_sweep(t, 190.0, 65.0, 0.26) * TAU) * exp(-t * 12.0)
		return n * 0.7 + s * 0.6
	)
	_sfx["thud"] = _perc(0.22, 0.5, func(t: float) -> float:
		return sin(_sweep(t, 105.0, 42.0, 0.22) * TAU) * exp(-t * 13.0)
	)
	_sfx["groan"] = _perc(0.62, 0.3, func(t: float) -> float:
		var f := _sweep(t, 84.0, 56.0, 0.62)
		var ph := f + sin(t * 5.5 * TAU) * 0.012 * t
		var env := minf(t / 0.12, 1.0) * exp(-(maxf(t - 0.2, 0.0)) * 4.5)
		return (_wave(ph, "tri") * 0.7 + _wave(ph, "saw") * 0.3) * env
	)
	_sfx["chew"] = _perc(0.13, 0.3, func(t: float) -> float:
		return (_noise_lp(t, 900.0) * 0.7 + _wave(t * 160.0, "square") * 0.3) * exp(-t * 28.0)
	)
	_sfx["spark"] = _perc(0.06, 0.24, func(t: float) -> float:
		return sin(t * 1200.0 * TAU) * exp(-t * 50.0)
	)
	_sfx["bolt"] = _tone(640, 0.09, 0.3, "saw")
	_sfx["wire"] = _perc(0.07, 0.2, func(t: float) -> float:
		return _wave(_sweep(t, 1500.0, 900.0, 0.07), "square") * exp(-t * 45.0)
	)
	_sfx["build"] = _perc(0.16, 0.42, func(t: float) -> float:
		var knock := sin(_sweep(t, 270.0, 170.0, 0.16) * TAU) * exp(-t * 24.0)
		return knock * 0.8 + _noise_lp(t, 1400.0) * exp(-t * 80.0) * 0.5
	)
	_sfx["explode"] = _perc(0.75, 0.62, func(t: float) -> float:
		var n := _noise_lp(t, 520.0) * exp(-t * 5.0)
		var sub := sin(_sweep(t, 95.0, 28.0, 0.75) * TAU) * exp(-t * 4.0)
		return n * 0.8 + sub * 0.8
	)
	_sfx["shield"] = _tone(500, 0.14, 0.3, "sine")
	_sfx["surge"] = _tone(70, 0.3, 0.5, "saw")
	_sfx["yip"] = _tone(640, 0.08, 0.22, "sine")
	# Music is rendered on first request so boot stays quick.
	_music_recipes["title"] = func() -> AudioStreamWAV: return _song([262, 330, 392, 330, 349, 392, 523, 392], 0.28, 0.18)
	_music_recipes["hub"] = func() -> AudioStreamWAV: return _song([196, 247, 294, 247, 220, 262, 330, 294], 0.32, 0.16)
	_music_recipes["midtown"] = func() -> AudioStreamWAV: return _song([220, 277, 330, 277, 246, 330, 440, 330], 0.26, 0.17)
	_music_recipes["docks"] = func() -> AudioStreamWAV: return _song([174, 220, 261, 220, 196, 246, 329, 261], 0.3, 0.16)
	_music_recipes["grid"] = func() -> AudioStreamWAV: return _song([155, 196, 233, 196, 185, 233, 311, 233], 0.24, 0.18)
	_music_recipes["combat"] = func() -> AudioStreamWAV: return _song([130, 164, 196, 164, 146, 196, 261, 196], 0.16, 0.2)
	_music_recipes["boss"] = func() -> AudioStreamWAV: return _song([98, 123, 146, 116, 98, 130, 164, 110], 0.18, 0.22)
	_music_recipes["credits"] = func() -> AudioStreamWAV: return _song([261, 329, 392, 523, 392, 329, 349, 440], 0.34, 0.15)
	_music_recipes["day"] = func() -> AudioStreamWAV: return _song([262, 294, 330, 392, 330, 294, 247, 262], 0.48, 0.11)
	_music_recipes["arena"] = func() -> AudioStreamWAV: return _song([262, 330, 392, 330, 349, 392, 523, 392], 0.22, 0.16)
	_music_recipes["hollow"] = func() -> AudioStreamWAV: return _hollow_bed()
	_music_recipes["hollow_combat"] = func() -> AudioStreamWAV: return _hollow_pulse()


## Spooky music-box lead in A minor over a slow bass drone.
func _hollow_bed() -> AudioStreamWAV:
	var lead := [440, 0, 523, 440, 0, 415, 0, 0, 349, 0, 440, 349, 0, 330, 0, 0,
		440, 0, 523, 659, 0, 622, 0, 0, 587, 0, 523, 494, 0, 440, 0, 0]
	var bass := [110, 110, 110, 110, 110, 110, 110, 110, 87, 87, 87, 87, 82, 82, 82, 82,
		110, 110, 110, 110, 104, 104, 104, 104, 98, 98, 98, 98, 82, 82, 82, 82]
	var step := 0.3
	var dur := step * lead.size()
	var s := _render(dur, 0.16, func(t: float) -> float:
		var idx := int(t / step) % lead.size()
		var local := fmod(t, step)
		var out := 0.0
		var f := float(lead[idx])
		if f > 0.0:
			var env := exp(-local * 6.5) * minf(local / 0.01, 1.0)
			out += (sin(t * f * TAU) * 0.6 + sin(t * f * 2.0 * TAU) * 0.18 + sin(t * f * 3.0 * TAU) * 0.06) * env
		var b := float(bass[idx])
		var bl := fmod(t, step * 4.0)
		var benv := minf(bl / 0.25, 1.0) * (1.0 - 0.35 * bl / (step * 4.0))
		out += (sin(t * b * TAU) * 0.55 + _wave(t * b, "tri") * 0.25) * benv * 0.7
		out += sin(t * b * 0.5 * TAU) * 0.18 * benv
		return out
	)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_end = s.data.size() / 2
	return s


## Combat layer: a heartbeat under a nervous plucked ostinato.
func _hollow_pulse() -> AudioStreamWAV:
	var notes := [220, 220, 262, 220, 233, 220, 196, 220]
	var step := 0.15
	var beat := 0.6
	var dur := step * notes.size() * 4
	var s := _render(dur, 0.2, func(t: float) -> float:
		var idx := int(t / step) % notes.size()
		var local := fmod(t, step)
		var f := float(notes[idx])
		var pluck := _wave(t * f, "square") * exp(-local * 22.0) * 0.28
		var bl := fmod(t, beat)
		var hb := 0.0
		if bl < 0.12:
			hb = sin(_sweep(bl, 90.0, 40.0, 0.12) * TAU) * exp(-bl * 22.0)
		elif bl > 0.18 and bl < 0.3:
			var b2 := bl - 0.18
			hb = sin(_sweep(b2, 80.0, 36.0, 0.12) * TAU) * exp(-b2 * 22.0) * 0.8
		return pluck + hb * 0.9
	)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_end = s.data.size() / 2
	return s


# --- synthesis helpers -------------------------------------------------------

func _wave(ph: float, wave: String) -> float:
	var p := fmod(ph, 1.0)
	if p < 0.0:
		p += 1.0
	match wave:
		"square":
			return 1.0 if p < 0.5 else -1.0
		"saw":
			return p * 2.0 - 1.0
		"tri":
			return 1.0 - 4.0 * absf(p - 0.5)
		_:
			return sin(p * TAU)


## Phase (in cycles) of an exponential frequency sweep f0 -> f1 over dur seconds.
func _sweep(t: float, f0: float, f1: float, dur: float) -> float:
	if absf(f1 - f0) < 0.01 or dur <= 0.0:
		return f0 * t
	var k := log(f1 / f0) / dur
	return f0 * (exp(k * t) - 1.0) / k


## One-pole lowpassed white noise. Stateful; rendering is sequential so that is fine.
func _noise_lp(t: float, cutoff: float) -> float:
	if t < _lp_t:
		_lp_prev = 0.0
	_lp_t = t
	var n := randf() * 2.0 - 1.0
	_lp_prev = _lp_prev + (n - _lp_prev) * clampf(cutoff / 8000.0, 0.03, 1.0)
	return _lp_prev


func _perc(dur: float, vol: float, fn: Callable) -> AudioStreamWAV:
	_lp_prev = 0.0
	_lp_t = -1.0
	return _render(dur, vol, fn)


func _tone(freq: float, dur: float, vol: float, wave: String) -> AudioStreamWAV:
	return _render(dur, vol, func(t: float) -> float:
		return _wave(t * freq, wave) * exp(-t * 6.0)
	)


func _arpeggio(notes: Array, step: float) -> AudioStreamWAV:
	var dur := step * notes.size()
	return _render(dur, 0.28, func(t: float) -> float:
		var idx := clampi(int(t / step), 0, notes.size() - 1)
		var local := t - idx * step
		var f := float(notes[idx])
		return (sin(t * f * TAU) * 0.8 + sin(t * f * 2.0 * TAU) * 0.2) * exp(-local * 9.0)
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
		var fade := 0.004
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
