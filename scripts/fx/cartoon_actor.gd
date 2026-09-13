class_name CartoonActor
extends Node2D

var kind: String = "sling"
var bob := 0.0
var squash := Vector2.ONE
var hurt_flash := 0.0
var trail_color := Color.WHITE
var facing := 1
var sprite: Sprite2D
var shadow: Sprite2D
var idle_tex: Texture2D
var run_tex: Texture2D
var pose := "idle"
var display_h := 118.0
var foot := 30.0
var base_scale := 1.0


func configure(p_kind: String, colors: Dictionary) -> void:
	kind = p_kind
	trail_color = colors.get("accent", Color.WHITE)
	for c in get_children():
		c.queue_free()
	display_h = Art.display_height(p_kind)
	foot = display_h * 0.14
	idle_tex = Art.tex(Art.actor_id(p_kind, "idle"))
	run_tex = Art.tex(Art.actor_id(p_kind, "run"))
	if run_tex == null:
		run_tex = idle_tex
	_shadow()
	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.centered = true
	sprite.texture = idle_tex
	_fit_sprite()
	add_child(sprite)
	if sprite.texture == null:
		_blob_fallback(colors)
	if colors.has("trim") and p_kind in ["sling", "titan", "forge"]:
		var trim: Color = colors.trim
		if trim != Color("E23B9A") and trim != Color("6B3A12") and trim != Color("D08A3A"):
			sprite.modulate = Color(0.92, 0.95, 1.08)


func _shadow() -> void:
	shadow = Sprite2D.new()
	shadow.texture = Art.soft_light()
	shadow.modulate = Color(0.02, 0.03, 0.05, 0.5)
	shadow.scale = Vector2(0.62, 0.14)
	shadow.position = Vector2(0, foot + 8)
	shadow.z_index = -1
	add_child(shadow)


func _process(delta: float) -> void:
	bob += delta * (7.0 if pose == "run" else 2.4)
	var air := false
	var vx := 0.0
	var p := get_parent()
	if p is CharacterBody2D:
		air = not p.is_on_floor()
		vx = p.velocity.x
	var y := 0.0
	if not air:
		y = sin(bob) * (2.4 if pose == "run" else 0.7)
	var lean := clampf(vx / 900.0, -0.12, 0.12)
	rotation = lerp_angle(rotation, lean, 0.18)
	scale = Vector2(facing * squash.x * base_scale, squash.y * base_scale)
	position.y = lerp(position.y, y, 0.25)
	if hurt_flash > 0.0:
		hurt_flash -= delta
		modulate = Color(1.35, 0.72, 0.72)
	else:
		modulate = Color.WHITE
	_update_pose()


func _update_pose() -> void:
	if sprite == null or idle_tex == null:
		return
	var moving := false
	var p := get_parent()
	if p is CharacterBody2D:
		moving = abs(p.velocity.x) > 55.0 or abs(p.velocity.y) > 160.0
		if p is Forge and p.hovering:
			moving = true
		if p is Sling and p.tethered:
			moving = true
	var want := "run" if moving and run_tex else "idle"
	if want == pose:
		return
	pose = want
	sprite.texture = run_tex if want == "run" else idle_tex
	_fit_sprite()


func _fit_sprite() -> void:
	if sprite == null or sprite.texture == null:
		return
	var th := float(sprite.texture.get_height())
	if th > 1.0:
		sprite.scale = Vector2.ONE * (display_h / th)
	sprite.position = Vector2(0, foot - display_h * 0.5)


func pulse(k: float = 1.25) -> void:
	squash = Vector2(k, 2.0 - k)
	var tw := create_tween()
	tw.tween_property(self, "squash", Vector2.ONE, 0.12)


func _blob_fallback(colors: Dictionary) -> void:
	var body: Color = colors.get("body", Color.WHITE)
	var poly := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		pts.append(Vector2(cos(a) * 16.0, sin(a) * 22.0))
	poly.polygon = pts
	poly.color = body
	poly.position = Vector2(0, -8)
	add_child(poly)
