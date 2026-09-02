class_name WorldProps
extends RefCounted

static func static_rect(parent: Node, rect: Rect2, color: Color, groups: Array = [], tex_id: String = "", draw: bool = true) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.collision_layer = 1
	b.collision_mask = 0
	b.position = rect.position + rect.size * 0.5
	var cs := CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = rect.size
	cs.shape = s
	b.add_child(cs)
	if draw:
		var shadow := ColorRect.new()
		shadow.size = Vector2(rect.size.x, 22)
		shadow.position = Vector2(-rect.size.x * 0.5, rect.size.y * 0.5 - 8)
		shadow.color = Color(0, 0, 0, 0.35)
		shadow.z_index = -2
		b.add_child(shadow)
		var vis_tex := Art.tex(tex_id) if tex_id != "" else null
		if vis_tex:
			var spr := Sprite2D.new()
			spr.texture = vis_tex
			spr.centered = true
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			spr.region_enabled = true
			spr.region_rect = Rect2(0, 0, maxf(rect.size.x, 8), maxf(rect.size.y, 8))
			spr.modulate = Color(color.r, color.g, color.b, 1.0).lerp(Color.WHITE, 0.35)
			b.add_child(spr)
		else:
			var vis := ColorRect.new()
			vis.size = rect.size
			vis.position = -rect.size * 0.5
			vis.color = color
			b.add_child(vis)
		var edge := ColorRect.new()
		edge.size = Vector2(rect.size.x, 10)
		edge.position = Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5)
		edge.color = Color(1, 0.92, 0.75, 0.28)
		b.add_child(edge)
	for g in groups:
		b.add_to_group(str(g))
	parent.add_child(b)
	return b


static func building(parent: Node, rect: Rect2, flip: bool = false) -> StaticBody2D:
	var b := static_rect(parent, rect, Color("2A2A38"), [])
	var t := Art.tex("prop_building")
	if t:
		var spr := Sprite2D.new()
		spr.texture = t
		spr.centered = true
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		spr.flip_h = flip
		spr.scale = Vector2(rect.size.x / float(t.get_width()), rect.size.y / float(t.get_height()))
		b.add_child(spr)
	return b


static func swing_point(parent: Node, pos: Vector2) -> Area2D:
	var a := Area2D.new()
	a.add_to_group("swing_point")
	a.collision_layer = 64
	a.collision_mask = 0
	a.position = pos
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 18.0
	cs.shape = c
	a.add_child(cs)
	var vis := Art.sprite("prop_swing", 42.0)
	if vis.texture:
		a.add_child(vis)
	else:
		var box := ColorRect.new()
		box.size = Vector2(16, 16)
		box.position = Vector2(-8, -8)
		box.color = Color("E23B9A")
		a.add_child(box)
	var glow := Sprite2D.new()
	glow.texture = Art.soft_light()
	glow.modulate = Color("E23B9A88")
	glow.scale = Vector2(0.28, 0.28)
	a.add_child(glow)
	parent.add_child(a)
	return a


static func smashable(parent: Node, pos: Vector2, color: Color = Color("8C5A3A")) -> SmashProp:
	var s := SmashProp.new()
	s.position = pos
	parent.add_child(s)
	s.build(color)
	return s


static func fuel_pad(parent: Node, pos: Vector2) -> Area2D:
	var a := Area2D.new()
	a.add_to_group("fuel_pad")
	a.collision_layer = 32
	a.collision_mask = 2
	a.position = pos
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(48, 16)
	cs.shape = r
	a.add_child(cs)
	var vis := ColorRect.new()
	vis.size = Vector2(56, 18)
	vis.position = Vector2(-28, -9)
	vis.color = Color(0.15, 0.45, 1.0, 0.55)
	a.add_child(vis)
	var glow := Sprite2D.new()
	glow.texture = Art.soft_light()
	glow.modulate = Color("3B7CFF99")
	glow.scale = Vector2(0.32, 0.14)
	a.add_child(glow)
	a.body_entered.connect(func(b):
		if b is Forge:
			b.fuel = b.max_fuel
			b.bump_stat("fuel_pickups")
			AudioDirector.play("spark")
			VFX.text_pop(parent, a.global_position, "FUEL", Color("9AD4FF"))
	)
	parent.add_child(a)
	return a


static func pickup(parent: Node, pos: Vector2, kind: String, pid: String) -> Area2D:
	var a := Area2D.new()
	a.add_to_group("pickup")
	a.collision_layer = 32
	a.collision_mask = 2
	a.position = pos
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 14.0
	cs.shape = c
	a.add_child(cs)
	var pid_tex := "pickup_token" if kind == "token" else "pickup_token"
	var spr := Art.sprite(pid_tex, 36.0 if kind == "token" else 32.0)
	if kind != "token":
		spr.modulate = Color("C9A0FF")
	if spr.texture:
		a.add_child(spr)
	else:
		var vis := ColorRect.new()
		vis.size = Vector2(18, 18)
		vis.position = Vector2(-9, -9)
		vis.color = Color("F4C542") if kind == "token" else Color("C090FF")
		a.add_child(vis)
	a.body_entered.connect(func(b):
		if b is HeroBase:
			if kind == "token":
				SaveManager.collect_token(pid)
				VFX.text_pop(parent, a.global_position, "TOKEN", Color("F4C542"))
			else:
				SaveManager.collect_comic(pid)
				VFX.text_pop(parent, a.global_position, "COMIC", Color("C090FF"))
			AudioDirector.play("pickup")
			a.queue_free()
	)
	parent.add_child(a)
	return a


static func restore_light(parent: Node, pos: Vector2, idx: int) -> RestoreLight:
	var l := RestoreLight.new()
	l.index = idx
	l.position = pos
	parent.add_child(l)
	l.build()
	return l


static func checkpoint(parent: Node, pos: Vector2) -> Area2D:
	var a := Area2D.new()
	a.add_to_group("checkpoint")
	a.collision_layer = 128
	a.collision_mask = 2
	a.position = pos
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(40, 90)
	cs.shape = r
	a.add_child(cs)
	var vis := ColorRect.new()
	vis.size = Vector2(12, 80)
	vis.position = Vector2(-6, -40)
	vis.color = Color("F4C542")
	a.add_child(vis)
	a.body_entered.connect(func(b):
		if b is HeroBase:
			b.spawn_pos = a.global_position
			vis.color = Color("2EE6C7")
			AudioDirector.play("ui")
	)
	parent.add_child(a)
	return a


static func generator(parent: Node, pos: Vector2) -> Area2D:
	var a := Area2D.new()
	a.add_to_group("generator")
	a.position = pos
	var vis := ColorRect.new()
	vis.size = Vector2(70, 90)
	vis.position = Vector2(-35, -45)
	vis.color = Color("6CF0E0")
	a.add_child(vis)
	parent.add_child(a)
	return a
