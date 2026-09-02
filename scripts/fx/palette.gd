class_name Palette
extends RefCounted

static func district(id: String) -> Dictionary:
	match id:
		"docks":
			return {
				"sky_top": Color("1A3A58"),
				"sky_bot": Color("F0A36B"),
				"far": Color("2C536B"),
				"mid": Color("3E6B7A"),
				"ground": Color("3A322C"),
				"ground2": Color("5A4A3A"),
				"build": Color("C47A4A"),
				"build2": Color("8C5A3A"),
				"accent": Color("E8D48A"),
				"fog": Color(0.15, 0.35, 0.4, 0.25),
				"water": Color("1C6B8A")
			}
		"grid":
			return {
				"sky_top": Color("070B14"),
				"sky_bot": Color("1A2340"),
				"far": Color("141C33"),
				"mid": Color("1C2A4D"),
				"ground": Color("12151F"),
				"ground2": Color("2A3148"),
				"build": Color("243056"),
				"build2": Color("3A5080"),
				"accent": Color("6CF0E0"),
				"fog": Color(0.05, 0.1, 0.2, 0.4),
				"water": Color("102030")
			}
		_:
			return {
				"sky_top": Color("0B1B33"),
				"sky_bot": Color("3A1A4A"),
				"far": Color("1A2A55"),
				"mid": Color("243A6B"),
				"ground": Color("1A1A28"),
				"ground2": Color("3A3A50"),
				"build": Color("2A3A70"),
				"build2": Color("4A2A68"),
				"accent": Color("FF4DA6"),
				"fog": Color(0.2, 0.1, 0.3, 0.2),
				"water": Color("102040")
			}


static func hero(id: String, costume: String = "classic") -> Dictionary:
	var base := {}
	match id:
		"titan":
			base = {"body": Color("E89B2D"), "trim": Color("6B3A12"), "skin": Color("F3C7A0"), "accent": Color("FFEE88"), "outline": Color("1A1208")}
		"forge":
			base = {"body": Color("3B7CFF"), "trim": Color("D08A3A"), "skin": Color("E8C4A0"), "accent": Color("9AD4FF"), "outline": Color("081018")}
		_:
			base = {"body": Color("2EE6C7"), "trim": Color("E23B9A"), "skin": Color("F0C8A8"), "accent": Color("B8FFE8"), "outline": Color("081820")}
	match costume:
		"night_market":
			base.body = Color("145A66")
			base.trim = Color("C9F06C")
		"neon_rain":
			base.body = Color("7A5CFF")
			base.trim = Color("FF66CC")
		"dock_gold":
			base.body = Color("C9A227")
			base.trim = Color("3A2A10")
		"quarry":
			base.body = Color("8A6A4A")
			base.trim = Color("E8D0A0")
		"copper_bright":
			base.body = Color("2A5AE0")
			base.trim = Color("FFB070")
		"midnight_lab":
			base.body = Color("14243A")
			base.trim = Color("6CF0E0")
		"ng_pulse":
			base.body = Color("F4C542")
			base.trim = Color("FFFFFF")
	return base


static func enemy(kind: String, elite: bool = false) -> Dictionary:
	var c := {"body": Color("6A7A8A"), "trim": Color("2EE6C7"), "outline": Color("101018"), "eye": Color("FFEE88")}
	match kind:
		"drainling":
			c.body = Color("3A8A8A")
			c.trim = Color("7EF0E0")
		"scraper":
			c.body = Color("6A5348")
			c.trim = Color("C45A3A")
		"drone":
			c.body = Color("4A5A70")
			c.trim = Color("7AB0FF")
		"shieldbot":
			c.body = Color("5A6A80")
			c.trim = Color("88D0FF")
		"grabber":
			c.body = Color("5A3A5A")
			c.trim = Color("E08AD0")
		"turret":
			c.body = Color("3A3A48")
			c.trim = Color("F0A040")
		"bomber":
			c.body = Color("5A4A3A")
			c.trim = Color("F07040")
		"leaper":
			c.body = Color("2A6A7A")
			c.trim = Color("A0F0E0")
		"elite_pulse":
			c.body = Color("2A2A60")
			c.trim = Color("F4C542")
			elite = true
		"seeker":
			c.body = Color("1A2438")
			c.trim = Color("FF4DA6")
		"riptide":
			c.body = Color("1A6A8A")
			c.trim = Color("7EE0FF")
		"gridlock":
			c.body = Color("3A3A48")
			c.trim = Color("F0A040")
		"brownout":
			c.body = Color("2A2048")
			c.trim = Color("C090FF")
		"drain":
			c.body = Color("0A2030")
			c.trim = Color("6CF0E0")
		"overload":
			c.body = Color("201018")
			c.trim = Color("FF4466")
	if elite:
		c.trim = Color("F4C542")
		c.eye = Color("FFFFFF")
	return c
