extends StaticBody3D

const FX = preload("res://scripts/hollow/hollow_fx.gd")

signal ruined
signal hurt(hp: int, max_hp: int)

var hp := 100
var max_hp := 100
var bite_cd := 0.0
var vis: Node3D
var lamp: OmniLight3D
var tag: Label3D
var dead := false


func _ready() -> void:
	add_to_group("keep")
	collision_layer = 32
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.6, 2.4, 2.6)
	cs.shape = box
	cs.position.y = 1.2
	add_child(cs)
	vis = Node3D.new()
	add_child(vis)
	_box(Vector3(0, 1.05, 0), Vector3(2.5, 2.1, 2.5), Color("4A4E55"))
	_box(Vector3(0, 2.2, 0), Vector3(2.8, 0.25, 2.8), Color("3A3E44"))
	_box(Vector3(0, 1.0, 1.28), Vector3(0.7, 1.4, 0.12), Color("2A241C"))
	_box(Vector3(0, 2.55, 0), Vector3(0.22, 0.7, 0.22), Color("3A2414"))
	var ball := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.42
	sm.height = 0.84
	ball.mesh = sm
	ball.position = Vector3(0, 3.15, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("FFB347")
	mat.emission_enabled = true
	mat.emission = Color("FF8A3A")
	mat.emission_energy_multiplier = 3.4
	mat.roughness = 0.2
	ball.material_override = mat
	vis.add_child(ball)
	lamp = OmniLight3D.new()
	lamp.position = Vector3(0, 3.2, 0)
	lamp.light_color = Color("FFB36A")
	lamp.light_energy = 7.5
	lamp.omni_range = 16.0
	lamp.shadow_enabled = true
	add_child(lamp)
	tag = Label3D.new()
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.font_size = 42
	tag.outline_size = 12
	tag.position.y = 3.9
	add_child(tag)
	var zone := Area3D.new()
	zone.monitoring = true
	zone.collision_mask = 4
	zone.collision_layer = 0
	var zcs := CollisionShape3D.new()
	var zbox := BoxShape3D.new()
	zbox.size = Vector3(3.4, 2.2, 3.4)
	zcs.shape = zbox
	zcs.position.y = 1.0
	zone.add_child(zcs)
	add_child(zone)
	zone.body_entered.connect(func(n):
		if n.is_in_group("zed") and n.has_method("start_chew"):
			n.start_chew(self)
	)
	_refresh()


func chew(dmg: int) -> void:
	if dead:
		return
	hp = maxi(0, hp - dmg)
	lamp.light_energy = 4.0
	FX.spark(get_parent(), global_position + Vector3(0, 2.4, 0))
	AudioDirector.play("hurt", 0.7)
	hurt.emit(hp, max_hp)
	_refresh()
	if hp <= 0:
		dead = true
		FX.boom(get_parent(), global_position + Vector3(0, 1.5, 0))
		AudioDirector.play("lose")
		ruined.emit()


func _process(delta: float) -> void:
	if lamp:
		lamp.light_energy = move_toward(lamp.light_energy, 7.5 * (0.45 + 0.55 * float(hp) / float(max_hp)), delta * 6.0)
		lamp.omni_range = 12.0 + 6.0 * float(hp) / float(max_hp)


func _refresh() -> void:
	if tag:
		tag.text = "LANTERN  %d" % hp
		tag.modulate = Color("FFB347") if hp > 30 else Color("E24B4B")


func _box(pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.82
	mi.material_override = m
	vis.add_child(mi)
