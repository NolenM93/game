extends Node

var _cache: Array = []


func _ready() -> void:
	_cache = _build()


func all_missions() -> Array:
	return _cache


func get_mission(id: String) -> Dictionary:
	for m in _cache:
		if m.id == id:
			return m
	return {}


func story_ids() -> PackedStringArray:
	return PackedStringArray(["s01", "s02", "s03", "s04", "s05", "s06", "s07", "s08", "s09", "s10", "s11", "s12"])


func side_ids() -> PackedStringArray:
	return PackedStringArray(["m_patrol_roofs", "m_patrol_docks", "m_patrol_grid", "m_rescue_streak", "m_wrecking", "m_gallery", "m_race", "m_restore", "m_night", "m_scrap"])


func trial_ids() -> PackedStringArray:
	return PackedStringArray(["t_sling_1", "t_sling_2", "t_sling_3", "t_titan_1", "t_titan_2", "t_titan_3", "t_forge_1", "t_forge_2", "t_forge_3"])


func challenge_ids() -> PackedStringArray:
	return PackedStringArray(["c_nodmg", "c_onehp", "c_time", "c_sling", "c_titan", "c_forge"])


func upgrades() -> Dictionary:
	return {
		"sling": [
			{"id": "ribbon_edge", "name": "Ribbon Edge", "cost": 40, "desc": "Combos hit harder."},
			{"id": "zip_dash", "name": "Zip Dash", "cost": 55, "desc": "Air dash after a swing."},
			{"id": "double_tether", "name": "Double Tether", "cost": 70, "desc": "Two swing lines at once."},
			{"id": "long_stun", "name": "Long Stun", "cost": 80, "desc": "Yank keeps foes still longer."},
			{"id": "aerial_acrobat", "name": "Aerial Acrobat", "cost": 95, "desc": "Bonus jump after swinging."}
		],
		"titan": [
			{"id": "heavy_hands", "name": "Heavy Hands", "cost": 40, "desc": "Bigger punch numbers."},
			{"id": "quake_walk", "name": "Quake Walk", "cost": 55, "desc": "Ground pound while moving."},
			{"id": "long_surge", "name": "Long Surge", "cost": 70, "desc": "Surge lasts longer."},
			{"id": "smash_armor", "name": "Smash Armor", "cost": 80, "desc": "Armor right after a smash."},
			{"id": "wrecking", "name": "Wrecking Crew", "cost": 95, "desc": "Wider shockwaves and throws."}
		],
		"forge": [
			{"id": "overclock", "name": "Overclock", "cost": 40, "desc": "More fuel, snappier bolts."},
			{"id": "bounce_bomb", "name": "Bounce Bomb", "cost": 55, "desc": "Gadget lobs a bouncy bomb."},
			{"id": "decoy_drone", "name": "Decoy Drone", "cost": 70, "desc": "A dummy drone draws fire."},
			{"id": "capacitor", "name": "Capacitor", "cost": 80, "desc": "Shield pulse lasts longer."},
			{"id": "afterburner", "name": "Afterburner", "cost": 95, "desc": "Dash leaves a hot trail."}
		]
	}


func city_upgrades() -> Array:
	return [
		{"id": "civ_glow", "name": "Neighbor Glow", "cost": 60, "desc": "Civilians sparkle on the map."},
		{"id": "cheap_continue", "name": "Safety Net", "cost": 80, "desc": "Checkpoint retries do not cost Spark."},
		{"id": "spark_magnet", "name": "Spark Magnet", "cost": 70, "desc": "Pickups fly to you."}
	]


func costumes() -> Dictionary:
	return {
		"sling": ["classic", "night_market", "neon_rain", "ng_pulse"],
		"titan": ["classic", "dock_gold", "quarry", "ng_pulse"],
		"forge": ["classic", "copper_bright", "midnight_lab", "ng_pulse"]
	}


func comics() -> Dictionary:
	var d := {}
	var lines := [
		"Harbor City blinks. The streetlights hiccup.",
		"Mira at the comic shop tapes a flashlight to the register.",
		"Sling ties a ribbon to the fire escape and grins.",
		"Titan lifts a dumpster like it owes him lunch.",
		"Forge solders a jet from a scooter and two kettles.",
		"The Drain drinks a billboard until it goes grey.",
		"Riptide laughs like a foghorn in a bathtub.",
		"Gridlock parks vans where vans should never park.",
		"Brownout turns the block into a hide-and-seek board.",
		"Coach says: punch the dummy, not the donuts.",
		"A ferry full of snacks needs an escort. Obviously.",
		"Spark the HQ bot beeps a pep talk.",
		"Someone left a Harbor Token in a crane.",
		"The rooftops feel like a jungle gym for heroes.",
		"Night Market noodles taste like victory.",
		"A drone drops a comic and flees, embarrassed.",
		"Quake puddles on the docks. Titan stomps them dry.",
		"Forge labels every lever: DO NOT, MAYBE, YES.",
		"The team high-fives. It is slightly out of sync.",
		"Civilians cheer with paper lightning bolts.",
		"A secret switch in the substation hums 'try me'.",
		"New Game+ is just the city with extra sass.",
		"Overload waits behind a gold stamp.",
		"Sling's ribbon writes a smiley in the sky.",
		"Titan names a boulder 'Steve'.",
		"Forge's helmet fogs up when he is proud.",
		"The Drain never learned to share batteries.",
		"Harbor Pulse: three kids, one loud city.",
		"Credits roll, then the board lights up again.",
		"Save the lights. Save snack time. Save Harbor."
	]
	for i in 30:
		d["p%02d" % (i + 1)] = {"title": "Panel %d" % (i + 1), "text": lines[i]}
	return d


func story_comics() -> Dictionary:
	return {
		"c01": {"title": "Lights Out", "pages": [
			{"caption": "Harbor City hiccups. Every neon sign goes shy.", "art": "midtown"},
			{"caption": "A kid with teal ribbons looks up. 'Okay. My turn.'", "art": "sling"}
		]},
		"c02": {"title": "Heavy Help", "pages": [
			{"caption": "The docks roar. Crates learn to fly.", "art": "docks"},
			{"caption": "Titan cracks a smile. 'I got the heavy stuff.'", "art": "titan"}
		]},
		"c03": {"title": "Scrap Genius", "pages": [
			{"caption": "A homemade jet coughs, then sings.", "art": "grid"},
			{"caption": "Forge flips a visor down. 'I brought extra batteries.'", "art": "forge"}
		]},
		"c04": {"title": "Citywide Pulse", "pages": [
			{"caption": "Vans, waves, and blackout tag. The city asks for everyone.", "art": "midtown"}
		]},
		"c05": {"title": "The Drain", "pages": [
			{"caption": "Under the substation, something drinks the glow.", "art": "grid"},
			{"caption": "Three heroes. One overload. Flip the switch.", "art": "drain"}
		]},
		"c06": {"title": "Pulse On", "pages": [
			{"caption": "Harbor lights slam back like a high-five.", "art": "midtown"},
			{"caption": "Snack time is saved. For now.", "art": "hub"}
		]}
	}


func is_unlocked(id: String) -> bool:
	if SaveManager.active.get("debug_unlock", false):
		return true
	var m := get_mission(id)
	if m.is_empty():
		return false
	var cleared: Array = SaveManager.active.get("cleared", [])
	if m.kind == "secret":
		return SaveManager.overload_ready()
	if m.kind == "challenge":
		return SaveManager.active.get("drain_beaten", false)
	if m.kind == "trial":
		var rec := str(m.get("recommended", "sling"))
		return SaveManager.is_hero_unlocked(rec)
	if m.kind == "side":
		var ch := int(m.get("chapter", 1))
		return _chapter_opened(ch, cleared)
	var req = m.get("requires", [])
	if typeof(req) == TYPE_DICTIONARY:
		var n := 0
		for x in req.get("of", []):
			if x in cleared:
				n += 1
		return n >= int(req.get("any", 1))
	for r in req:
		if not r in cleared:
			return false
	return true


func _chapter_opened(ch: int, cleared: Array) -> bool:
	match ch:
		1:
			return true
		2:
			return "s02" in cleared
		3:
			return "s05" in cleared
		4:
			return "s08" in cleared
		_:
			return SaveManager.active.get("drain_beaten", false)


func _build() -> Array:
	var a: Array = []
	a.append_array(_story())
	a.append_array(_side())
	a.append_array(_trials())
	a.append_array(_challenges())
	a.append({"id": "x_overload", "title": "Overload", "blurb": "A secret pulse that never learned manners.", "chapter": 6, "district": "grid", "kind": "secret", "recommended": "sling", "weather": "storm", "length": 2400, "layout": "arena", "requires": [], "boss": "overload", "par_time": 180.0, "spark_reward": 250, "objectives": [{"type": "boss", "text": "Shut down Overload"}], "dare": {"stat": "no_hit", "count": 1, "text": "Don't get hit"}, "tokens": [], "comics": ["p23"], "features": ["arena"], "comic_start": ""})
	return a


func _m(id: String, title: String, blurb: String, ch: int, dist: String, kind: String, rec: String, weather: String, length: int, layout: String, requires, objs: Array, extras: Dictionary) -> Dictionary:
	var d := {
		"id": id, "title": title, "blurb": blurb, "chapter": ch, "district": dist, "kind": kind,
		"recommended": rec, "weather": weather, "length": length, "layout": layout, "requires": requires,
		"objectives": objs, "dare": extras.get("dare", {}), "par_time": extras.get("par_time", 150.0),
		"spark_reward": extras.get("spark_reward", 40), "boss": extras.get("boss", ""),
		"tokens": extras.get("tokens", []), "comics": extras.get("comics", []),
		"features": extras.get("features", []), "comic_start": extras.get("comic_start", ""),
		"waves": extras.get("waves", []), "hero_lock": extras.get("hero_lock", ""),
		"modifiers": extras.get("modifiers", {})
	}
	return d


func _story() -> Array:
	return [
		_m("s01", "Neon Blackout", "The rooftops go dark. Swing the long way home.", 1, "midtown", "story", "sling", "rain", 4200, "roofs", [], [
			{"type": "reach", "x": 3600, "text": "Reach the dark tower"},
			{"type": "rescue", "count": 2, "text": "Help two neighbors"}
		], {"dare": {"stat": "swings", "count": 8, "text": "Swing 8 times"}, "par_time": 140.0, "spark_reward": 50, "tokens": ["t01"], "comics": ["p01", "p02"], "features": ["swing", "rain"], "comic_start": "c01", "waves": [{"at": 900, "e": [["drainling", 2]]}, {"at": 1800, "e": [["scraper", 1], ["drone", 1]]}, {"at": 2800, "e": [["drainling", 2], ["seeker", 1]]}]}),
		_m("s02", "Alley Ambush", "Drainlings throw a surprise party. Ruin it.", 1, "midtown", "story", "sling", "night", 3800, "roofs", ["s01"], [
			{"type": "defeat", "text": "Clear the ambush"},
			{"type": "rescue", "count": 1, "text": "Free Mira's delivery kid"}
		], {"dare": {"stat": "combos", "count": 6, "text": "Land 6 combos"}, "par_time": 120.0, "spark_reward": 55, "tokens": ["t02"], "comics": ["p03"], "features": ["swing"], "waves": [{"at": 600, "e": [["scraper", 2]]}, {"at": 1400, "e": [["drainling", 3], ["drone", 1]]}, {"at": 2400, "e": [["shieldbot", 1], ["scraper", 2]], "elite": true}]}),
		_m("s03", "Crate Crush", "The docks stacked a puzzle. Titan-shaped answers.", 2, "docks", "story", "titan", "dusk", 4000, "docks", ["s02"], [
			{"type": "destroy", "count": 6, "text": "Smash Drain pylons"},
			{"type": "reach", "x": 3400, "text": "Reach the tall crane"}
		], {"dare": {"stat": "smashes", "count": 5, "text": "Smash 5 wrecks"}, "par_time": 130.0, "spark_reward": 60, "tokens": ["t03"], "comics": ["p04", "p11"], "features": ["smash", "wet"], "comic_start": "c02", "waves": [{"at": 800, "e": [["leaper", 2]]}, {"at": 1700, "e": [["scraper", 2], ["bomber", 1]]}, {"at": 2600, "e": [["leaper", 2], ["turret", 1]]}]}),
		_m("s04", "Ferry Run", "A ferry full of snacks. Escort it. Obviously.", 2, "docks", "story", "titan", "wind", 3600, "docks", ["s03"], [
			{"type": "rescue", "count": 1, "escort": true, "text": "Escort the ferry captain"},
			{"type": "defend", "waves": 3, "text": "Keep the ferry safe"}
		], {"dare": {"stat": "throws", "count": 3, "text": "Throw 3 foes"}, "par_time": 150.0, "spark_reward": 65, "tokens": ["t04"], "comics": ["p05"], "features": ["smash", "wet"], "waves": [{"at": 500, "e": [["drone", 2]]}, {"at": 1200, "e": [["leaper", 2], ["scraper", 1]]}, {"at": 2200, "e": [["bomber", 2], ["shieldbot", 1]]}]}),
		_m("s05", "Riptide", "A lieutenant with sea-legs and no indoor voice.", 2, "docks", "story", "titan", "storm", 2800, "arena", ["s04"], [
			{"type": "survive", "time": 12.0, "text": "Ride out the first wave"},
			{"type": "boss", "text": "Beat Riptide"}
		], {"dare": {"stat": "pounds", "count": 4, "text": "Ground pound 4 times"}, "par_time": 160.0, "spark_reward": 90, "boss": "riptide", "tokens": ["t05"], "comics": ["p07"], "features": ["arena", "wet"], "waves": [{"at": 200, "e": [["leaper", 2]]}]}),
		_m("s06", "Spark Maze", "Cranes, fuel pads, and a path only jets love.", 3, "grid", "story", "forge", "night", 4400, "grid", ["s05"], [
			{"type": "reach", "x": 3800, "text": "Thread the crane maze"},
			{"type": "restore", "count": 3, "text": "Turn three lights on"}
		], {"dare": {"stat": "air_kills", "count": 4, "text": "Beat 4 foes in the air"}, "par_time": 150.0, "spark_reward": 70, "tokens": ["t06"], "comics": ["p06", "p08"], "features": ["fuel", "lifts"], "comic_start": "c03", "waves": [{"at": 700, "e": [["drone", 2]]}, {"at": 1600, "e": [["turret", 1], ["drone", 1]]}, {"at": 2700, "e": [["seeker", 1], ["drone", 2]]}]}),
		_m("s07", "Live Wire", "A generator throws a tantrum. Defend it.", 3, "grid", "story", "forge", "storm", 3200, "grid", ["s06"], [
			{"type": "defend", "waves": 4, "text": "Defend the generator"},
			{"type": "destroy", "count": 4, "text": "Break the Drain taps"}
		], {"dare": {"stat": "bolts", "count": 12, "text": "Land 12 bolts"}, "par_time": 140.0, "spark_reward": 75, "tokens": ["t07"], "comics": ["p18"], "features": ["fuel", "wires"], "waves": [{"at": 400, "e": [["drainling", 3]]}, {"at": 900, "e": [["drone", 2], ["bomber", 1]]}, {"at": 1500, "e": [["elite_pulse", 1]], "elite": true}, {"at": 2100, "e": [["turret", 2], ["scraper", 2]]}]}),
		_m("s08", "Circuit Break", "Lights in order. Elites out of order.", 3, "grid", "story", "forge", "night", 4000, "grid", ["s07"], [
			{"type": "restore", "count": 4, "ordered": true, "text": "Restore lights in order"},
			{"type": "defeat", "text": "Drop the elite patrol"}
		], {"dare": {"stat": "no_ground", "count": 8, "text": "Stay airborne 8 seconds"}, "par_time": 155.0, "spark_reward": 80, "tokens": ["t08"], "comics": ["p09"], "features": ["fuel", "lifts", "wires"], "waves": [{"at": 800, "e": [["shieldbot", 1], ["drone", 2]]}, {"at": 1900, "e": [["elite_pulse", 1], ["seeker", 1]], "elite": true}]}),
		_m("s09", "Pulse Chase", "A Drain van tries to leave with the city's glow.", 4, "midtown", "story", "sling", "dusk", 4800, "chase", ["s08"], [
			{"type": "chase", "text": "Stay on the van"},
			{"type": "defeat", "text": "Stop the escort drones"}
		], {"dare": {"stat": "swings", "count": 10, "text": "Swing 10 times"}, "par_time": 130.0, "spark_reward": 80, "tokens": ["t09"], "comics": ["p10"], "features": ["swing", "chase"], "comic_start": "c04", "waves": [{"at": 600, "e": [["drone", 2]]}, {"at": 1800, "e": [["drone", 2], ["scraper", 1]]}, {"at": 3000, "e": [["bomber", 1], ["drone", 2]]}]}),
		_m("s10", "Gridlock", "Turret vans. Traffic cones with opinions.", 4, "midtown", "story", "titan", "night", 3000, "arena", ["s08"], [
			{"type": "defend", "waves": 2, "text": "Clear the plaza turrets"},
			{"type": "boss", "text": "Beat Gridlock"}
		], {"dare": {"stat": "smashes", "count": 4, "text": "Smash 4 barriers"}, "par_time": 170.0, "spark_reward": 100, "boss": "gridlock", "tokens": ["t10"], "comics": ["p08"], "features": ["arena", "smash"], "waves": [{"at": 300, "e": [["turret", 2], ["scraper", 2]]}]}),
		_m("s11", "Brownout", "Hide-and-seek in a stolen night.", 4, "grid", "story", "sling", "blackout", 3600, "grid", ["s08"], [
			{"type": "stealth", "text": "Slip the search cones"},
			{"type": "boss", "text": "Beat Brownout"}
		], {"dare": {"stat": "unseen", "count": 1, "text": "Reach Brownout unseen"}, "par_time": 180.0, "spark_reward": 100, "boss": "brownout", "tokens": ["t11"], "comics": ["p09"], "features": ["stealth", "blackout"], "waves": [{"at": 700, "e": [["seeker", 2]]}, {"at": 1800, "e": [["seeker", 2], ["drainling", 2]]}]}),
		_m("s12", "The Drain", "Flip the city's big switch.", 5, "grid", "story", "forge", "storm", 4200, "grid", {"any": 2, "of": ["s09", "s10", "s11"]}, [
			{"type": "reach", "x": 2600, "text": "Enter the substation"},
			{"type": "restore", "count": 3, "text": "Prime the overload pads"},
			{"type": "boss", "text": "Stop The Drain"}
		], {"dare": {"stat": "team_style", "count": 1, "text": "Use a signature 8 times"}, "par_time": 210.0, "spark_reward": 160, "boss": "drain", "tokens": ["t12"], "comics": ["p21", "p27"], "features": ["fuel", "smash", "swing", "wires"], "comic_start": "c05", "waves": [{"at": 500, "e": [["drone", 2]]}, {"at": 1400, "e": [["elite_pulse", 1], ["shieldbot", 1]]}, {"at": 2200, "e": [["seeker", 1], ["bomber", 1], ["turret", 1]]}]})
	]


func _side() -> Array:
	return [
		_m("m_patrol_roofs", "Night Patrol", "A quiet loop of the neon jungle gym.", 1, "midtown", "side", "sling", "night", 3400, "roofs", [], [{"type": "defeat", "text": "Clear rooftop pests"}, {"type": "reach", "x": 3000, "text": "Finish the loop"}], {"dare": {"stat": "swings", "count": 12, "text": "Swing 12 times"}, "spark_reward": 35, "tokens": ["t13"], "comics": ["p14"], "features": ["swing"], "par_time": 100.0, "waves": [{"at": 700, "e": [["drainling", 2]]}, {"at": 1600, "e": [["drone", 2]]}, {"at": 2400, "e": [["scraper", 2]]}]}),
		_m("m_patrol_docks", "Pier Patrol", "Walk the wet boards. Stomp the loud ones.", 2, "docks", "side", "titan", "dusk", 3400, "docks", [], [{"type": "destroy", "count": 5, "text": "Smash leftover pylons"}, {"type": "defeat", "text": "Shove scrapers home"}], {"dare": {"stat": "pounds", "count": 3, "text": "Pound 3 times"}, "spark_reward": 40, "tokens": [], "comics": ["p17"], "features": ["smash", "wet"], "par_time": 110.0, "waves": [{"at": 800, "e": [["leaper", 2]]}, {"at": 1800, "e": [["scraper", 2], ["turret", 1]]}]}),
		_m("m_patrol_grid", "Grid Walk", "Check the hum. Unplug the rude machines.", 3, "grid", "side", "forge", "night", 3600, "grid", [], [{"type": "restore", "count": 3, "text": "Relight three blocks"}, {"type": "defeat", "text": "Clear drones"}], {"dare": {"stat": "bolts", "count": 10, "text": "Land 10 bolts"}, "spark_reward": 40, "comics": ["p16"], "features": ["fuel"], "par_time": 110.0, "waves": [{"at": 900, "e": [["drone", 3]]}, {"at": 2000, "e": [["turret", 2]]}]}),
		_m("m_rescue_streak", "Rescue Streak", "Five civilians. Zero excuses.", 1, "midtown", "side", "sling", "rain", 4000, "roofs", [], [{"type": "rescue", "count": 5, "text": "Help five neighbors"}, {"type": "reach", "x": 3600, "text": "Get them home"}], {"dare": {"stat": "no_hit", "count": 1, "text": "Don't get hit"}, "spark_reward": 50, "tokens": ["t14"], "comics": ["p20"], "features": ["swing"], "par_time": 130.0, "waves": [{"at": 600, "e": [["scraper", 1]]}, {"at": 1500, "e": [["grabber", 1], ["drone", 1]]}, {"at": 2500, "e": [["seeker", 1]]}]}),
		_m("m_wrecking", "Wrecking Yard", "If it rattles, it is a toy.", 2, "docks", "side", "titan", "dusk", 3000, "docks", [], [{"type": "destroy", "count": 10, "text": "Wreck everything"}, {"type": "survive", "time": 20.0, "text": "Enjoy the mess"}], {"dare": {"stat": "smashes", "count": 10, "text": "Smash 10 wrecks"}, "spark_reward": 45, "comics": ["p25"], "features": ["smash"], "par_time": 90.0, "waves": [{"at": 400, "e": [["scraper", 2]]}, {"at": 1200, "e": [["shieldbot", 1], ["leaper", 1]]}]}),
		_m("m_gallery", "Drone Gallery", "Target practice with manners.", 3, "grid", "side", "forge", "night", 2800, "grid", [], [{"type": "defeat", "text": "Pop the gallery drones"}, {"type": "survive", "time": 15.0, "text": "Hold the range"}], {"dare": {"stat": "air_kills", "count": 6, "text": "6 air KOs"}, "spark_reward": 45, "comics": ["p16"], "features": ["fuel"], "par_time": 80.0, "waves": [{"at": 300, "e": [["drone", 3]]}, {"at": 900, "e": [["drone", 3]]}, {"at": 1500, "e": [["drone", 4]]}]}),
		_m("m_race", "Ribbon Race", "Rooftop time trial. Swing or eat billboard.", 1, "midtown", "side", "sling", "dusk", 5000, "roofs", [], [{"type": "reach", "x": 4600, "text": "Beat the gate"}, {"type": "survive", "time": 5.0, "text": "Keep moving"}], {"dare": {"stat": "swings", "count": 15, "text": "Swing 15 times"}, "spark_reward": 55, "par_time": 70.0, "features": ["swing", "race"], "waves": [{"at": 2000, "e": [["drone", 1]]}]}),
		_m("m_restore", "Restore the Block", "Someone unplugged a whole street.", 3, "grid", "side", "forge", "blackout", 3600, "grid", [], [{"type": "restore", "count": 5, "ordered": true, "text": "Lights in order"}, {"type": "defeat", "text": "Shoo the seekers"}], {"dare": {"stat": "unseen", "count": 1, "text": "Stay unseen until the last light"}, "spark_reward": 50, "tokens": ["t15"], "comics": ["p13"], "features": ["stealth", "fuel"], "par_time": 120.0, "waves": [{"at": 800, "e": [["seeker", 2]]}, {"at": 2000, "e": [["seeker", 2], ["turret", 1]]}]}),
		_m("m_night", "Night Watch", "HQ asked for one more lap after dark.", 4, "midtown", "side", "sling", "night", 3800, "roofs", [], [{"type": "stealth", "text": "Slip past seekers"}, {"type": "rescue", "count": 2, "text": "Walk two neighbors home"}], {"dare": {"stat": "unseen", "count": 1, "text": "Nobody spots you"}, "spark_reward": 50, "comics": ["p15"], "features": ["stealth", "swing"], "par_time": 125.0, "waves": [{"at": 700, "e": [["seeker", 2]]}, {"at": 1900, "e": [["seeker", 1], ["scraper", 1]]}]}),
		_m("m_scrap", "Scrap Heap", "Forge left a mess. Titan is welcome.", 2, "docks", "side", "titan", "wind", 3200, "docks", [], [{"type": "destroy", "count": 8, "text": "Sort the heap"}, {"type": "defend", "waves": 2, "text": "Don't let drones nest"}], {"dare": {"stat": "throws", "count": 4, "text": "Throw 4 times"}, "spark_reward": 45, "comics": ["p18"], "features": ["smash"], "par_time": 100.0, "waves": [{"at": 600, "e": [["bomber", 2]]}, {"at": 1600, "e": [["drone", 2], ["grabber", 1]]}]})
	]


func _trials() -> Array:
	return [
		_m("t_sling_1", "Trial: Pendulum", "Swing like you mean it.", 1, "midtown", "trial", "sling", "clear", 2600, "gym_swing", [], [{"type": "skill", "stat": "swings", "count": 12, "text": "Swing 12 times"}, {"type": "reach", "x": 2300, "text": "Finish the course"}], {"hero_lock": "sling", "spark_reward": 40, "par_time": 80.0, "features": ["swing"], "dare": {"stat": "swings", "count": 16, "text": "Swing 16 times"}}),
		_m("t_sling_2", "Trial: Yank", "Pull the rude ones closer.", 1, "midtown", "trial", "sling", "clear", 2200, "gym_swing", [], [{"type": "skill", "stat": "yanks", "count": 6, "text": "Yank 6 foes"}, {"type": "defeat", "text": "Clear the dummies"}], {"hero_lock": "sling", "spark_reward": 45, "par_time": 90.0, "features": ["swing"], "waves": [{"at": 400, "e": [["scraper", 3]]}, {"at": 1100, "e": [["scraper", 3]]}], "dare": {"stat": "yanks", "count": 8, "text": "Yank 8"}}),
		_m("t_sling_3", "Trial: Ribbon Storm", "Combo until the ribbon sings.", 1, "midtown", "trial", "sling", "clear", 2000, "arena", [], [{"type": "skill", "stat": "combos", "count": 10, "text": "10 combos"}, {"type": "defeat", "text": "Win the gym fight"}], {"hero_lock": "sling", "spark_reward": 50, "par_time": 90.0, "waves": [{"at": 200, "e": [["drainling", 4]]}, {"at": 200, "e": [["drone", 2]]}], "dare": {"stat": "combos", "count": 14, "text": "14 combos"}}),
		_m("t_titan_1", "Trial: Pound", "The floor is a drum.", 2, "docks", "trial", "titan", "clear", 2200, "gym_smash", [], [{"type": "skill", "stat": "pounds", "count": 6, "text": "Ground pound 6 times"}, {"type": "destroy", "count": 6, "text": "Open the yard"}], {"hero_lock": "titan", "spark_reward": 40, "par_time": 80.0, "features": ["smash"], "dare": {"stat": "pounds", "count": 8, "text": "Pound 8"}}),
		_m("t_titan_2", "Trial: Surge", "Grow, stomp, grin.", 2, "docks", "trial", "titan", "clear", 2000, "gym_smash", [], [{"type": "skill", "stat": "surges", "count": 3, "text": "Surge 3 times"}, {"type": "defeat", "text": "Bowl them over"}], {"hero_lock": "titan", "spark_reward": 45, "par_time": 90.0, "features": ["smash"], "waves": [{"at": 300, "e": [["scraper", 3]]}, {"at": 900, "e": [["shieldbot", 2]]}], "dare": {"stat": "surges", "count": 4, "text": "Surge 4"}}),
		_m("t_titan_3", "Trial: Throw", "Everything is a ball if you believe.", 2, "docks", "trial", "titan", "clear", 2200, "gym_smash", [], [{"type": "skill", "stat": "throws", "count": 5, "text": "Throw 5 times"}, {"type": "destroy", "count": 4, "text": "Clean the heap"}], {"hero_lock": "titan", "spark_reward": 50, "par_time": 90.0, "features": ["smash"], "waves": [{"at": 400, "e": [["scraper", 4]]}], "dare": {"stat": "throws", "count": 7, "text": "Throw 7"}}),
		_m("t_forge_1", "Trial: Fuel", "Fly the rings. Don't sip the last drop.", 3, "grid", "trial", "forge", "clear", 2800, "gym_fly", [], [{"type": "reach", "x": 2500, "text": "Finish the flyway"}, {"type": "skill", "stat": "fuel_pickups", "count": 3, "text": "Grab 3 fuel pads"}], {"hero_lock": "forge", "spark_reward": 40, "par_time": 85.0, "features": ["fuel"], "dare": {"stat": "no_ground", "count": 10, "text": "Air 10 seconds"}}),
		_m("t_forge_2", "Trial: Aim", "Bolts with travel time. Lead the shot.", 3, "grid", "trial", "forge", "clear", 2200, "gym_fly", [], [{"type": "skill", "stat": "bolts", "count": 16, "text": "Land 16 bolts"}, {"type": "defeat", "text": "Clear the range"}], {"hero_lock": "forge", "spark_reward": 45, "par_time": 90.0, "features": ["fuel"], "waves": [{"at": 400, "e": [["drone", 4]]}, {"at": 1100, "e": [["drone", 4]]}], "dare": {"stat": "bolts", "count": 20, "text": "20 bolts"}}),
		_m("t_forge_3", "Trial: Dash", "Blink through the sparks.", 3, "grid", "trial", "forge", "clear", 2400, "gym_fly", [], [{"type": "skill", "stat": "dashes", "count": 8, "text": "Dash 8 times"}, {"type": "reach", "x": 2100, "text": "End gate"}], {"hero_lock": "forge", "spark_reward": 50, "par_time": 80.0, "features": ["fuel"], "dare": {"stat": "dashes", "count": 12, "text": "Dash 12"}})
	]


func _challenges() -> Array:
	return [
		_m("c_nodmg", "Challenge: Untouchable", "Story rooftops. Zero hits.", 5, "midtown", "challenge", "sling", "night", 3600, "roofs", [], [{"type": "reach", "x": 3200, "text": "Finish clean"}, {"type": "defeat", "text": "Clear them anyway"}], {"modifiers": {"no_damage_fail": true}, "spark_reward": 80, "par_time": 110.0, "features": ["swing"], "waves": [{"at": 700, "e": [["scraper", 2]]}, {"at": 1600, "e": [["drone", 2]]}, {"at": 2400, "e": [["seeker", 1]]}], "dare": {"stat": "no_hit", "count": 1, "text": "Don't get hit"}}),
		_m("c_onehp", "Challenge: One Heart", "You get one. Make it count.", 5, "docks", "challenge", "titan", "storm", 3200, "docks", [], [{"type": "defeat", "text": "Win with a whisper of HP"}, {"type": "reach", "x": 2800, "text": "Walk out"}], {"modifiers": {"one_heart": true}, "spark_reward": 80, "par_time": 120.0, "features": ["smash"], "waves": [{"at": 600, "e": [["leaper", 2]]}, {"at": 1500, "e": [["bomber", 1], ["scraper", 2]]}], "dare": {"stat": "no_hit", "count": 1, "text": "Still don't get hit"}}),
		_m("c_time", "Challenge: Time Attack", "A fast plaza. The clock is the boss.", 5, "midtown", "challenge", "forge", "dusk", 3000, "roofs", [], [{"type": "defeat", "text": "Clear fast"}, {"type": "reach", "x": 2600, "text": "Punch the clock"}], {"modifiers": {"time_limit": 75.0}, "spark_reward": 80, "par_time": 60.0, "features": ["swing", "fuel"], "waves": [{"at": 400, "e": [["drainling", 3]]}, {"at": 1200, "e": [["drone", 2], ["scraper", 1]]}], "dare": {"stat": "speed", "count": 1, "text": "Beat par"}}),
		_m("c_sling", "Challenge: Ribbon Only", "Sling's course. No backups.", 5, "midtown", "challenge", "sling", "rain", 3800, "roofs", [], [{"type": "reach", "x": 3400, "text": "Ribbon to the end"}, {"type": "rescue", "count": 2, "text": "Save two"}], {"hero_lock": "sling", "spark_reward": 70, "par_time": 100.0, "features": ["swing"], "waves": [{"at": 900, "e": [["scraper", 2]]}, {"at": 2000, "e": [["drone", 2]]}], "dare": {"stat": "swings", "count": 12, "text": "Swing 12"}}),
		_m("c_titan", "Challenge: Stone Only", "Titan's wrecking exam.", 5, "docks", "challenge", "titan", "dusk", 3400, "docks", [], [{"type": "destroy", "count": 8, "text": "Wreck the exam"}, {"type": "defeat", "text": "Bowl the class"}], {"hero_lock": "titan", "spark_reward": 70, "par_time": 110.0, "features": ["smash"], "waves": [{"at": 700, "e": [["scraper", 3]]}, {"at": 1800, "e": [["shieldbot", 2]]}], "dare": {"stat": "smashes", "count": 8, "text": "Smash 8"}}),
		_m("c_forge", "Challenge: Jet Only", "Forge's fly-and-fry.", 5, "grid", "challenge", "forge", "night", 3600, "grid", [], [{"type": "restore", "count": 3, "text": "Lights"}, {"type": "defeat", "text": "Drones down"}], {"hero_lock": "forge", "spark_reward": 70, "par_time": 110.0, "features": ["fuel"], "waves": [{"at": 800, "e": [["drone", 3]]}, {"at": 1900, "e": [["turret", 2], ["drone", 2]]}], "dare": {"stat": "bolts", "count": 14, "text": "14 bolts"}})
	]
