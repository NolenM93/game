extends Control

func _ready() -> void:
	UIKit.full_rect(self)
	UIKit.art_bg(self, "bg_hub", 0.55)
	UIKit.label(self, "UPGRADE BENCH", Vector2(80, 40), 48, UIKit.GOLD)
	UIKit.label(self, "Spark %d" % int(SaveManager.active.get("spark", 0)), Vector2(1500, 50), 32, UIKit.GOLD)
	var y := 120.0
	for hero in ["sling", "titan", "forge"]:
		UIKit.label(self, hero.capitalize(), Vector2(80, y), 32, UIKit.TEAL)
		y += 44
		for u in Catalog.upgrades()[hero]:
			var owned := SaveManager.has_upgrade(hero, u.id)
			var t := u.name + "  •  " + u.desc
			if owned:
				t = "✓  " + t
			else:
				t = "%s  (%d Spark)" % [t, int(u.cost)]
			var b := UIKit.button(self, t, Rect2(80, y, 1760, 52))
			b.disabled = owned or not SaveManager.is_hero_unlocked(hero)
			var hid := hero
			var uid: String = u.id
			var cost: int = u.cost
			b.pressed.connect(func(): _buy_hero(hid, uid, cost))
			y += 58
		y += 8
	UIKit.label(self, "City upgrades", Vector2(80, y), 32, UIKit.TEAL)
	y += 44
	for u in Catalog.city_upgrades():
		var owned := u.id in SaveManager.active.get("city_upgrades", [])
		var t := u.name + "  •  " + u.desc
		t = ("✓  " + t) if owned else ("%s  (%d Spark)" % [t, int(u.cost)])
		var b2 := UIKit.button(self, t, Rect2(80, y, 1760, 52))
		b2.disabled = owned
		var cid: String = u.id
		var cc: int = u.cost
		b2.pressed.connect(func(): _buy_city(cid, cc))
		y += 58
	var back := UIKit.button(self, "Back", Rect2(80, 1000, 240, 52))
	back.pressed.connect(func(): Game.show_hub())
	back.grab_focus()


func _buy_hero(hero: String, id: String, cost: int) -> void:
	if int(SaveManager.active.get("spark", 0)) < cost:
		AudioDirector.play("lose")
		return
	SaveManager.add_spark(-cost)
	SaveManager.grant_upgrade(hero, id)
	SaveManager.save_now()
	AudioDirector.play("confirm")
	Game.show_upgrades()


func _buy_city(id: String, cost: int) -> void:
	if int(SaveManager.active.get("spark", 0)) < cost:
		AudioDirector.play("lose")
		return
	SaveManager.add_spark(-cost)
	var a: Array = SaveManager.active.get("city_upgrades", [])
	a.append(id)
	SaveManager.active["city_upgrades"] = a
	SaveManager.save_now()
	AudioDirector.play("confirm")
	Game.show_upgrades()
