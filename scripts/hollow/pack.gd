class_name HollowPack
extends RefCounted

signal changed

const DEFS := {
	"gun_shotgun": {"id": "gun_shotgun", "name": "Squeaky Twelve", "kind": "gun", "gun": 0, "mag": 8, "max_stack": 1, "color": Color("3A2A1C"), "mark": "SG", "icon": "💥", "desc": "Wide blast. Knocks a crowd back."},
	"gun_nailer": {"id": "gun_nailer", "name": "Tomb Nailer", "kind": "gun", "gun": 1, "mag": 14, "max_stack": 1, "color": Color("4A5058"), "mark": "TN", "icon": "🔩", "desc": "Fast iron nails. Staggers whatever it hits."},
	"gun_gloop": {"id": "gun_gloop", "name": "Gloop-O-Matic", "kind": "gun", "gun": 2, "mag": 6, "max_stack": 1, "color": Color("6AA84A"), "mark": "GO", "icon": "🫧", "desc": "Sticky candy slime. Slows a whole shuffle."},
	"gun_rocket": {"id": "gun_rocket", "name": "Bottle Rocket", "kind": "gun", "gun": 3, "mag": 3, "max_stack": 1, "color": Color("C45A20"), "mark": "BR", "icon": "🚀", "desc": "Arcing firework. Boom on impact."},
	"gun_stake": {"id": "gun_stake", "name": "Grave Stake", "kind": "gun", "gun": 4, "mag": 5, "max_stack": 1, "color": Color("5A3A28"), "mark": "GS", "icon": "🗡️", "desc": "Heavy iron stake. Huge hit, long pause."},
	"gun_hex": {"id": "gun_hex", "name": "Hex Lantern", "kind": "gun", "gun": 5, "mag": 4, "max_stack": 1, "color": Color("B070D0"), "mark": "HX", "icon": "🏮", "desc": "Thrown lantern. Burns everything nearby."},
	"gun_frost": {"id": "gun_frost", "name": "Rime Nail", "kind": "gun", "gun": 6, "mag": 10, "max_stack": 1, "color": Color("7EC8E8"), "mark": "RN", "icon": "❄️", "desc": "Ice tack. Freezes feet to the dirt."},
	"bat": {"id": "bat", "name": "Porch Bat", "kind": "melee", "max_stack": 1, "color": Color("C48A4A"), "mark": "BAT", "icon": "🦇", "desc": "A swing that pops heads if you get close."},
	"ammo": {"id": "ammo", "name": "Candy Caps", "kind": "ammo", "max_stack": 64, "color": Color("FFE27A"), "mark": "CAP", "icon": "🍬", "desc": "Reload candy for every gun."},
	"candy": {"id": "candy", "name": "Candy", "kind": "candy", "max_stack": 64, "color": Color("FF8A3A"), "mark": "YUM", "icon": "🍭", "desc": "Spent to build fences and traps."},
	"heart": {"id": "heart", "name": "Pumpkin Tart", "kind": "heal", "max_stack": 8, "color": Color("E56BA0"), "mark": "HP", "icon": "🥧", "desc": "Eat to mend a hunter heart."},
	"oil": {"id": "oil", "name": "Lantern Oil", "kind": "oil", "max_stack": 8, "color": Color("FFB347"), "mark": "OIL", "icon": "🛢️", "desc": "Pour into the keep to restore flame."},
}

var bag: Array = []
var bar: Array = []
var cursor: Dictionary = {}
var selected := 0


func _init() -> void:
	bag.resize(27)
	bar.resize(9)
	for i in 27:
		bag[i] = {}
	for i in 9:
		bar[i] = {}
	bar[0] = make("gun_shotgun")
	bar[1] = make("bat")
	add(make("ammo", 20))


static func make(id: String, count: int = 1) -> Dictionary:
	if not DEFS.has(id):
		return {}
	var d: Dictionary = DEFS[id].duplicate(true)
	d["count"] = count
	if str(d.get("kind", "")) == "gun":
		d["ammo"] = int(d.get("mag", 8))
	return d


static func blank(it: Dictionary) -> bool:
	return it.is_empty() or str(it.get("id", "")) == ""


static func icon(it: Dictionary) -> String:
	var ic := str(it.get("icon", ""))
	if ic != "":
		return ic
	var id := str(it.get("id", ""))
	if DEFS.has(id):
		return str(DEFS[id].get("icon", "•"))
	return "•"


func equipped() -> Dictionary:
	if selected < 0 or selected >= bar.size():
		return {}
	return bar[selected]


func add(it: Dictionary) -> bool:
	if blank(it):
		return true
	it = it.duplicate(true)
	if int(it.get("max_stack", 1)) > 1:
		for arr in [bar, bag]:
			for i in arr.size():
				if _same(arr[i], it):
					var room := int(arr[i].get("max_stack", 64)) - int(arr[i].get("count", 1))
					if room <= 0:
						continue
					var n := mini(room, int(it.get("count", 1)))
					arr[i]["count"] = int(arr[i]["count"]) + n
					it["count"] = int(it["count"]) - n
					if int(it["count"]) <= 0:
						changed.emit()
						return true
	for arr in [bar, bag]:
		for i in arr.size():
			if blank(arr[i]):
				arr[i] = it
				changed.emit()
				return true
	return false


func take(id: String, n: int) -> int:
	var left := n
	for arr in [bar, bag]:
		for i in arr.size():
			if str(arr[i].get("id", "")) != id:
				continue
			var c := int(arr[i].get("count", 1))
			var use := mini(c, left)
			arr[i]["count"] = c - use
			left -= use
			if int(arr[i]["count"]) <= 0:
				arr[i] = {}
			if left <= 0:
				changed.emit()
				return n
	if left < n:
		changed.emit()
	return n - left


func click(where: String, index: int, right: bool = false) -> void:
	var arr: Array = bar if where == "bar" else bag
	if index < 0 or index >= arr.size():
		return
	var slot: Dictionary = arr[index]
	if right:
		if blank(cursor):
			if blank(slot):
				return
			var c := int(slot.get("count", 1))
			if c <= 1 or int(slot.get("max_stack", 1)) <= 1:
				cursor = slot
				arr[index] = {}
			else:
				var half := (c + 1) / 2
				cursor = slot.duplicate(true)
				cursor["count"] = half
				arr[index]["count"] = c - half
		elif blank(slot):
			var one := cursor.duplicate(true)
			one["count"] = 1
			arr[index] = one
			cursor["count"] = int(cursor.get("count", 1)) - 1
			if int(cursor["count"]) <= 0:
				cursor = {}
		elif _same(slot, cursor) and int(slot.get("count", 1)) < int(slot.get("max_stack", 1)):
			arr[index]["count"] = int(slot["count"]) + 1
			cursor["count"] = int(cursor.get("count", 1)) - 1
			if int(cursor["count"]) <= 0:
				cursor = {}
		changed.emit()
		return
	if blank(cursor):
		cursor = slot
		arr[index] = {}
	elif blank(slot):
		arr[index] = cursor
		cursor = {}
	elif _same(slot, cursor):
		var maxs := int(slot.get("max_stack", 1))
		var room := maxs - int(slot.get("count", 1))
		var n := mini(room, int(cursor.get("count", 1)))
		arr[index]["count"] = int(slot["count"]) + n
		cursor["count"] = int(cursor["count"]) - n
		if int(cursor["count"]) <= 0:
			cursor = {}
	else:
		arr[index] = cursor
		cursor = slot
	changed.emit()


func drop_cursor_or_selected() -> Dictionary:
	var it: Dictionary
	if not blank(cursor):
		it = cursor
		cursor = {}
	else:
		it = bar[selected]
		bar[selected] = {}
	changed.emit()
	return it.duplicate(true) if not blank(it) else {}


func _same(a: Dictionary, b: Dictionary) -> bool:
	if blank(a) or blank(b):
		return false
	if str(a.get("id", "")) != str(b.get("id", "")):
		return false
	if str(a.get("kind", "")) == "gun":
		return false
	return int(a.get("max_stack", 1)) > 1
