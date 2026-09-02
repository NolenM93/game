extends Node

signal slot_changed

const SLOT_COUNT := 3
const SAVE_VERSION := 1

var active: Dictionary = {}
var slot_index: int = -1


func _ready() -> void:
	active = blank()


func blank() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"name": "Hero",
		"spark": 40,
		"difficulty": "story",
		"last_hero": "sling",
		"unlocked_heroes": ["sling"],
		"upgrades": {"sling": [], "titan": [], "forge": []},
		"city_upgrades": [],
		"costumes_owned": {"sling": ["classic"], "titan": ["classic"], "forge": ["classic"]},
		"costumes_eq": {"sling": "classic", "titan": "classic", "forge": "classic"},
		"cleared": [],
		"ranks": {},
		"stars": {},
		"comics": [],
		"tokens": [],
		"trials": [],
		"challenges": [],
		"tutorials": [],
		"comics_shown": [],
		"ng_plus": false,
		"drain_beaten": false,
		"overload_beaten": false,
		"playtime": 0.0,
		"continues": 0,
		"best_time": {},
		"created": Time.get_datetime_string_from_system()
	}


func path_for(i: int) -> String:
	return "user://slot_%d.json" % i


func has_slot(i: int) -> bool:
	return FileAccess.file_exists(path_for(i))


func load_slot(i: int) -> Dictionary:
	if not has_slot(i):
		return {}
	var f := FileAccess.open(path_for(i), FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return _migrate(data)


func save_slot(i: int, data: Dictionary) -> void:
	var f := FileAccess.open(path_for(i), FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))


func delete_slot(i: int) -> void:
	var p := path_for(i)
	if FileAccess.file_exists(p):
		DirAccess.remove_absolute(p)


func use_slot(i: int, new_game: bool, ng_plus: bool = false) -> void:
	slot_index = i
	if new_game:
		active = blank()
		if ng_plus:
			var old := load_slot(i)
			active["ng_plus"] = true
			active["spark"] = int(old.get("spark", 0)) + 200
			active["unlocked_heroes"] = ["sling", "titan", "forge"]
			active["upgrades"] = old.get("upgrades", active["upgrades"])
			active["city_upgrades"] = old.get("city_upgrades", [])
			active["costumes_owned"] = old.get("costumes_owned", active["costumes_owned"])
			_grant_costume("sling", "ng_pulse")
			_grant_costume("titan", "ng_pulse")
			_grant_costume("forge", "ng_pulse")
			active["comics"] = old.get("comics", [])
			active["tokens"] = old.get("tokens", [])
		save_now()
	else:
		active = load_slot(i)
		if active.is_empty():
			active = blank()
	Settings.difficulty = str(active.get("difficulty", "story"))
	slot_changed.emit()


func save_now() -> void:
	if slot_index < 0:
		return
	active["difficulty"] = Settings.difficulty
	save_slot(slot_index, active)


func is_hero_unlocked(id: String) -> bool:
	return id in active.get("unlocked_heroes", [])


func unlock_hero(id: String) -> void:
	var u: Array = active.get("unlocked_heroes", [])
	if not id in u:
		u.append(id)
		active["unlocked_heroes"] = u


func has_upgrade(hero: String, id: String) -> bool:
	return id in active.get("upgrades", {}).get(hero, [])


func grant_upgrade(hero: String, id: String) -> void:
	var tree: Dictionary = active.get("upgrades", {"sling": [], "titan": [], "forge": []})
	var arr: Array = tree.get(hero, [])
	if not id in arr:
		arr.append(id)
		tree[hero] = arr
		active["upgrades"] = tree


func _grant_costume(hero: String, id: String) -> void:
	var owned: Dictionary = active.get("costumes_owned", {})
	var arr: Array = owned.get(hero, [])
	if not id in arr:
		arr.append(id)
		owned[hero] = arr
		active["costumes_owned"] = owned


func grant_costume(hero: String, id: String) -> void:
	_grant_costume(hero, id)


func mark_cleared(id: String, rank: String, starred: bool, time_sec: float) -> void:
	var c: Array = active.get("cleared", [])
	if not id in c:
		c.append(id)
	active["cleared"] = c
	var ranks: Dictionary = active.get("ranks", {})
	var prev := str(ranks.get(id, ""))
	if _rank_value(rank) >= _rank_value(prev):
		ranks[id] = rank
	active["ranks"] = ranks
	if starred:
		var stars: Dictionary = active.get("stars", {})
		stars[id] = true
		active["stars"] = stars
	var best: Dictionary = active.get("best_time", {})
	if not best.has(id) or time_sec < float(best[id]):
		best[id] = time_sec
		active["best_time"] = best
	_story_unlocks(id)


func _story_unlocks(id: String) -> void:
	if id in ["s01", "s02"]:
		unlock_hero("titan")
		grant_costume("sling", "night_market")
	if id in ["s05", "s06"]:
		unlock_hero("forge")
		grant_costume("titan", "dock_gold")
	if id == "s08":
		grant_costume("forge", "copper_bright")
	if id == "s12":
		active["drain_beaten"] = true
		grant_costume("sling", "neon_rain")
		grant_costume("titan", "quarry")
		grant_costume("forge", "midnight_lab")
	if id == "x_overload":
		active["overload_beaten"] = true
	if id.begins_with("t_sling"):
		grant_costume("sling", "night_market")
	if id.begins_with("t_titan"):
		grant_costume("titan", "dock_gold")
	if id.begins_with("t_forge"):
		grant_costume("forge", "copper_bright")


func add_spark(n: int) -> void:
	active["spark"] = int(active.get("spark", 0)) + n


func collect_comic(id: String) -> void:
	var a: Array = active.get("comics", [])
	if not id in a:
		a.append(id)
		active["comics"] = a


func collect_token(id: String) -> void:
	var a: Array = active.get("tokens", [])
	if not id in a:
		a.append(id)
		active["tokens"] = a


func story_s_count() -> int:
	var n := 0
	for id in Catalog.story_ids():
		if str(active.get("ranks", {}).get(id, "")) == "S":
			n += 1
	return n


func overload_ready() -> bool:
	if active.get("drain_beaten", false) == false:
		return false
	var tokens: Array = active.get("tokens", [])
	return tokens.size() >= 15 or story_s_count() >= 12


func _rank_value(r: String) -> int:
	match r:
		"S":
			return 4
		"A":
			return 3
		"B":
			return 2
		"C":
			return 1
		_:
			return 0


func _migrate(data: Dictionary) -> Dictionary:
	var b := blank()
	b.merge(data, true)
	return b


func unlock_all_debug() -> void:
	active["unlocked_heroes"] = ["sling", "titan", "forge"]
	active["drain_beaten"] = true
	active["spark"] = 9999
	var all_ids: Array = []
	for m in Catalog.all_missions():
		all_ids.append(m.id)
		# don't auto-clear; just unlock
	active["debug_unlock"] = true
	for id in Catalog.story_ids():
		if not id in active["cleared"]:
			active["cleared"].append(id)
	save_now()
