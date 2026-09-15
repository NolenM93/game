class_name HollowPower
extends Area3D

const FX = preload("res://scripts/hollow/hollow_fx.gd")

var kind := "maxammo"
var world: Node
var life := 28.0
var vis: Node3D
var grabbed := false

const DEFS := {
	"maxammo": {"name": "MAX AMMO", "color": Color("3D8CFF"), "icon": "📦"},
	"instakill": {"name": "INSTA-KILL", "color": Color("E24B4B"), "icon": "💀"},
	"double": {"name": "DOUBLE POINTS", "color": Color("FFE27A"), "icon": "x2"},
	"nuke": {"name": "NUKE", "color": Color("FF8A3A"), "icon": "☢"},
	"carpenter": {"name": "CARPENTER", "color": Color("C4A05A"), "icon": "🔨"},
}


func setup(p_kind: String) -> void:
	kind = p_kind


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 1.15
	cs.shape = sh
	cs.position.y = 0.6
	add_child(cs)
	body_entered.connect(_grab)
	_mesh()


func _mesh() -> void:
	var def: Dictionary = DEFS.get(kind, DEFS["maxammo"])
	var col: Color = def["color"]
	vis = Node3D.new()
	add_child(vis)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.55, 0.55, 0.55)
	mi.mesh = box
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 1.6
	mi.material_override = m
	vis.add_child(mi)
	var tag := Label3D.new()
	tag.text = str(def["icon"])
	tag.font_size = 64
	tag.outline_size = 8
	tag.position.y = 0.9
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	if Art.font_emoji:
		tag.font = Art.font_emoji
	vis.add_child(tag)
	var glow := OmniLight3D.new()
	glow.light_color = col
	glow.light_energy = 2.4
	glow.omni_range = 5.0
	glow.position.y = 0.4
	add_child(glow)


func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if vis:
		vis.rotate_y(delta * 1.6)
		vis.position.y = 0.55 + sin(Time.get_ticks_msec() * 0.005) * 0.12


func _grab(body: Node3D) -> void:
	if grabbed or not body.is_in_group("hunter"):
		return
	grabbed = true
	if world and world.has_method("apply_powerup"):
		world.apply_powerup(kind, global_position)
	queue_free()
