class_name HollowStation
extends Area3D

const PackData = preload("res://scripts/hollow/pack.gd")
const FX = preload("res://scripts/hollow/hollow_fx.gd")

var kind := "wall" # wall, perk, debris, power
var id := ""
var cost := 500
var title := ""
var near := false
var world: Node
var used := false
var barrier: Node3D
var tag: Label3D
var lamp: OmniLight3D


func setup(p_kind: String, p_id: String, p_cost: int, p_title: String) -> void:
	kind = p_kind
	id = p_id
	cost = p_cost
	title = p_title


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 2.2 if kind != "debris" else 3.2
	cs.shape = sh
	cs.position.y = 1.0
	add_child(cs)
	body_entered.connect(func(n):
		if n.is_in_group("hunter"):
			near = true
	)
	body_exited.connect(func(n):
		if n.is_in_group("hunter"):
			near = false
	)
	tag = Label3D.new()
	tag.font_size = 28
	tag.outline_size = 6
	tag.position = Vector3(0, 2.15, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color("FFE27A")
	if Art.font_emoji:
		tag.font = Art.font_emoji
	add_child(tag)
	_refresh_tag()


func prompt() -> String:
	if not near or used:
		return ""
	if kind == "power":
		return "E  turn on the power"
	if kind == "debris":
		return "E  clear debris  ·  %d 🪙" % cost
	if kind == "perk":
		return "E  drink %s  ·  %d 🪙" % [title, cost]
	return "E  buy %s  ·  %d 🪙" % [title, cost]


func try_use() -> bool:
	if not near or used:
		return near
	if world == null:
		return near
	if kind == "power":
		if bool(world.get("power_on")):
			return true
		world.power_on = true
		used = true
		if world.has_method("_on_power"):
			world._on_power()
		AudioDirector.play("win", 0.9)
		_refresh_tag()
		return true
	if kind == "perk" and not bool(world.get("power_on")):
		if world.has_method("_show"):
			world._show("NEED POWER")
		AudioDirector.play("ui", 0.5)
		return true
	var hunter: Node = _hunter()
	if kind == "perk" and hunter and hunter.has_method("has_perk") and hunter.has_perk(id):
		if world.has_method("_show"):
			world._show("ALREADY HAVE  %s" % title)
		return true
	if kind == "wall" and hunter and _owns_gun(hunter, id):
		var ammo_cost := maxi(40, int(cost / 2))
		if not world.has_method("spend_coins") or not world.spend_coins(ammo_cost):
			if world.has_method("_show"):
				world._show("NEED  %d  COINS" % ammo_cost)
			AudioDirector.play("ui", 0.55)
			return true
		_fill_gun(hunter, id)
		if world.has_method("_show"):
			world._show("AMMO  ·  %s" % title)
		AudioDirector.play("pickup", 1.05)
		return true
	if not world.has_method("spend_coins") or not world.spend_coins(cost):
		if world.has_method("_show"):
			world._show("NEED  %d  COINS" % cost)
		AudioDirector.play("ui", 0.55)
		return true
	if kind == "debris":
		used = true
		if barrier:
			barrier.queue_free()
			barrier = null
		if world.has_method("_open_town"):
			world._open_town()
		FX.ring(get_parent(), global_position, Color(0.9, 0.7, 0.3, 0.8), 3.0, 0.4)
		AudioDirector.play("build", 0.7)
		_refresh_tag()
		return true
	if kind == "perk" and hunter and hunter.has_method("give_perk"):
		hunter.give_perk(id)
		if world.has_method("_show"):
			world._show(title)
		AudioDirector.play("win", 1.05)
		FX.ring(get_parent(), global_position, Color(1.0, 0.4, 0.7, 0.8), 2.2, 0.4)
		return true
	if kind == "wall" and hunter and hunter.has_method("take_loot"):
		var it: Dictionary = PackData.make(id, 1)
		if hunter.take_loot(it):
			if world.has_method("_show"):
				world._show("WALL BUY  ·  %s" % title)
		else:
			if world.has_method("_spawn_loot"):
				world._spawn_loot(global_position + Vector3(0, 0.3, 0.8), id)
		AudioDirector.play("confirm", 1.0)
		FX.ring(get_parent(), global_position, Color(0.4, 0.8, 1.0, 0.7), 1.8, 0.3)
		return true
	return true


func _refresh_tag() -> void:
	if tag == null:
		return
	if used and kind == "debris":
		tag.text = ""
		return
	if used and kind == "power":
		tag.text = "⚡ POWER ON"
		tag.modulate = Color("7CFF7A")
		return
	if kind == "power":
		tag.text = "⚡ POWER"
		return
	tag.text = "%s\n%d 🪙" % [title, cost]


func _hunter() -> Node:
	if get_tree() == null:
		return null
	for n in get_tree().get_nodes_in_group("hunter"):
		return n
	return null


func _owns_gun(hunter: Node, gun_id: String) -> bool:
	if hunter.pack == null:
		return false
	for arr in [hunter.pack.bar, hunter.pack.bag]:
		for it in arr:
			if str(it.get("id", "")) == gun_id:
				return true
	return false


func _fill_gun(hunter: Node, gun_id: String) -> void:
	if hunter.pack == null:
		return
	for arr in [hunter.pack.bar, hunter.pack.bag]:
		for it in arr:
			if str(it.get("id", "")) == gun_id:
				it["ammo"] = int(it.get("mag", 8))
	hunter.pack.add(PackData.make("ammo", 16))
	hunter.pack.changed.emit()
