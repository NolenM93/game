class_name TrainingDummy
extends StaticBody2D

var hp_show := 0
var actor: CartoonActor


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("dummy")
	collision_layer = 4
	collision_mask = 0
	actor = CartoonActor.new()
	actor.configure("dummy", {})
	add_child(actor)
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(actor.display_h * 0.22, actor.display_h * 0.48)
	cs.shape = r
	cs.position = Vector2(0, actor.foot - r.size.y * 0.5)
	add_child(cs)


func receive_hit(data: Dictionary, _from: Vector2, _src: Node) -> void:
	hp_show += int(data.get("dmg", 1))
	if actor:
		actor.pulse(1.3)
		actor.hurt_flash = 0.15
	VFX.text_pop(get_parent(), global_position + Vector2(0, -40), str(data.get("kind", "hit")).to_upper(), Color("F4C542"))
	AudioDirector.play("thud", 1.1)
	Juice.punch(5.0)
