class_name HollowGunArt
extends RefCounted

## Shared high-detail weapon meshes for the hunter's hands and world pickups.


static func attach(host: Node3D, id: String, sc: float = 1.0) -> void:
	var n := Node3D.new()
	n.scale = Vector3.ONE * sc
	host.add_child(n)
	match id:
		"gun_shotgun":
			_trench(n)
		"gun_nailer":
			_tommy(n)
		"gun_gloop":
			_garand(n)
		"gun_rocket":
			_bazooka(n)
		"gun_stake":
			_kar98(n)
		"gun_hex":
			_ray(n)
		"gun_frost":
			_mp40(n)
		"bat":
			_bat(n)
		"ammo":
			_ammo(n)
		"candy":
			_candy(n)
		"heart":
			_tart(n)
		"oil":
			_oil(n)
		_:
			_box(n, Vector3(0, 0.08, 0.2), Vector3(0.2, 0.2, 0.35), _paint(Color("FFE27A")))


static func _trench(n: Node3D) -> void:
	var wood := _wood(Color("6A4228"))
	var steel := _steel(Color("2A2E32"))
	var dark := _wood(Color("3A2418"))
	_box(n, Vector3(0, 0.02, 0.02), Vector3(0.09, 0.12, 0.38), dark)
	_box(n, Vector3(0, 0.06, 0.32), Vector3(0.08, 0.1, 0.28), wood)
	_box(n, Vector3(0, 0.08, 0.58), Vector3(0.07, 0.08, 0.42), steel)
	_cyl(n, Vector3(0.0, 0.1, 0.92), 0.028, 0.55, steel, Vector3(90, 0, 0))
	_cyl(n, Vector3(0.0, 0.055, 0.88), 0.022, 0.42, steel, Vector3(90, 0, 0))
	_box(n, Vector3(0, 0.02, 0.62), Vector3(0.09, 0.07, 0.22), wood)
	_box(n, Vector3(0, -0.04, 0.38), Vector3(0.04, 0.1, 0.08), steel)
	_box(n, Vector3(0, 0.14, 0.48), Vector3(0.05, 0.04, 0.16), steel)
	_box(n, Vector3(0, 0.16, 1.12), Vector3(0.03, 0.04, 0.06), steel)


static func _tommy(n: Node3D) -> void:
	var wood := _wood(Color("7A4A28"))
	var steel := _steel(Color("3A3E42"))
	var drum := _steel(Color("4A5056"))
	_box(n, Vector3(0, 0.04, -0.02), Vector3(0.08, 0.1, 0.32), wood)
	_box(n, Vector3(0, 0.07, 0.28), Vector3(0.07, 0.09, 0.38), steel)
	_cyl(n, Vector3(0.0, 0.09, 0.68), 0.02, 0.55, steel, Vector3(90, 0, 0))
	_box(n, Vector3(0, 0.12, 0.92), Vector3(0.045, 0.04, 0.12), steel)
	_cyl(n, Vector3(0.0, -0.08, 0.3), 0.14, 0.08, drum, Vector3(90, 0, 0))
	_cyl(n, Vector3(0.0, -0.08, 0.3), 0.04, 0.1, steel, Vector3(90, 0, 0))
	_box(n, Vector3(0, -0.02, 0.52), Vector3(0.04, 0.14, 0.04), wood)
	_box(n, Vector3(0, -0.06, 0.18), Vector3(0.035, 0.1, 0.07), steel)
	_box(n, Vector3(0, 0.14, 0.22), Vector3(0.06, 0.05, 0.08), steel)


static func _garand(n: Node3D) -> void:
	var wood := _wood(Color("8A5A32"))
	var steel := _steel(Color("2C3034"))
	_box(n, Vector3(0, 0.03, 0.08), Vector3(0.08, 0.1, 0.42), wood)
	_box(n, Vector3(0, 0.05, 0.5), Vector3(0.075, 0.09, 0.55), wood)
	_box(n, Vector3(0, 0.09, 0.42), Vector3(0.06, 0.06, 0.28), steel)
	_cyl(n, Vector3(0.0, 0.11, 0.95), 0.018, 0.7, steel, Vector3(90, 0, 0))
	_cyl(n, Vector3(0.0, 0.07, 0.82), 0.012, 0.4, steel, Vector3(90, 0, 0))
	_box(n, Vector3(0, 0.16, 0.38), Vector3(0.04, 0.05, 0.1), steel)
	_box(n, Vector3(0, 0.155, 1.22), Vector3(0.025, 0.04, 0.05), steel)
	_box(n, Vector3(0, -0.04, 0.22), Vector3(0.035, 0.09, 0.07), steel)
	_box(n, Vector3(0, 0.0, -0.12), Vector3(0.07, 0.12, 0.16), wood)


static func _bazooka(n: Node3D) -> void:
	var olive := _paint(Color("4A5A38"))
	var steel := _steel(Color("3A3A3C"))
	var wood := _wood(Color("5A3A24"))
	_cyl(n, Vector3(0.0, 0.1, 0.55), 0.085, 1.15, olive, Vector3(90, 0, 0))
	_cyl(n, Vector3(0.0, 0.1, 1.12), 0.1, 0.08, steel, Vector3(90, 0, 0))
	_cyl(n, Vector3(0.0, 0.1, -0.02), 0.1, 0.08, steel, Vector3(90, 0, 0))
	_box(n, Vector3(0, -0.04, 0.22), Vector3(0.12, 0.08, 0.28), wood)
	_box(n, Vector3(0.12, 0.16, 0.35), Vector3(0.02, 0.08, 0.02), steel)
	_box(n, Vector3(0.12, 0.2, 0.35), Vector3(0.08, 0.015, 0.08), steel)
	_box(n, Vector3(0, 0.2, 0.95), Vector3(0.06, 0.04, 0.08), steel)
	_cyl(n, Vector3(0.0, 0.1, 0.55), 0.04, 1.05, _steel(Color("1A1C1E")), Vector3(90, 0, 0))


static func _kar98(n: Node3D) -> void:
	var wood := _wood(Color("7A4E2C"))
	var steel := _steel(Color("2A2C30"))
	_box(n, Vector3(0, 0.02, 0.05), Vector3(0.075, 0.1, 0.4), wood)
	_box(n, Vector3(0, 0.04, 0.52), Vector3(0.07, 0.08, 0.7), wood)
	_cyl(n, Vector3(0.0, 0.1, 1.05), 0.016, 0.85, steel, Vector3(90, 0, 0))
	_box(n, Vector3(0.06, 0.1, 0.38), Vector3(0.05, 0.03, 0.14), steel)
	_box(n, Vector3(0.1, 0.1, 0.32), Vector3(0.04, 0.03, 0.04), steel)
	_box(n, Vector3(0, 0.16, 0.42), Vector3(0.035, 0.05, 0.08), steel)
	_box(n, Vector3(0, 0.155, 1.4), Vector3(0.022, 0.04, 0.05), steel)
	_box(n, Vector3(0, -0.04, 0.2), Vector3(0.03, 0.08, 0.06), steel)
	_box(n, Vector3(0, 0.0, -0.18), Vector3(0.065, 0.11, 0.14), wood)


static func _ray(n: Node3D) -> void:
	var purp := _glow(Color("7A32C8"), 1.4)
	var orange := _glow(Color("FF6A22"), 2.2)
	var dark := _steel(Color("2A1830"))
	_box(n, Vector3(0, 0.06, 0.12), Vector3(0.12, 0.12, 0.28), dark)
	_box(n, Vector3(0, 0.08, 0.38), Vector3(0.16, 0.14, 0.32), purp)
	_cyl(n, Vector3(0.0, 0.1, 0.68), 0.09, 0.22, purp, Vector3(90, 0, 0))
	_cyl(n, Vector3(0.0, 0.1, 0.82), 0.14, 0.06, orange, Vector3(90, 0, 0))
	_cyl(n, Vector3(0.0, 0.1, 0.9), 0.1, 0.05, purp, Vector3(90, 0, 0))
	_cyl(n, Vector3(0.0, 0.1, 0.98), 0.07, 0.08, orange, Vector3(90, 0, 0))
	_box(n, Vector3(0.11, 0.14, 0.32), Vector3(0.04, 0.1, 0.18), orange)
	_box(n, Vector3(-0.11, 0.14, 0.32), Vector3(0.04, 0.1, 0.18), orange)
	_box(n, Vector3(0, -0.04, 0.1), Vector3(0.05, 0.12, 0.1), dark)
	_box(n, Vector3(0, 0.0, -0.08), Vector3(0.1, 0.1, 0.12), purp)
	_sph(n, Vector3(0.0, 0.12, 0.4), 0.06, orange)


static func _mp40(n: Node3D) -> void:
	var steel := _steel(Color("4A4E52"))
	var dark := _steel(Color("2A2C2E"))
	_box(n, Vector3(0, 0.05, 0.08), Vector3(0.06, 0.07, 0.28), steel)
	_box(n, Vector3(0, 0.07, 0.32), Vector3(0.055, 0.07, 0.28), steel)
	_cyl(n, Vector3(0.0, 0.08, 0.62), 0.018, 0.42, dark, Vector3(90, 0, 0))
	_cyl(n, Vector3(0.0, 0.08, 0.62), 0.028, 0.28, steel, Vector3(90, 0, 0))
	_box(n, Vector3(0, -0.08, 0.28), Vector3(0.03, 0.18, 0.05), steel)
	_box(n, Vector3(0, -0.02, 0.16), Vector3(0.03, 0.08, 0.06), dark)
	_box(n, Vector3(0, 0.02, -0.14), Vector3(0.05, 0.04, 0.22), steel)
	_box(n, Vector3(0, 0.13, 0.22), Vector3(0.04, 0.04, 0.07), dark)


static func _bat(n: Node3D) -> void:
	var wood := _wood(Color("C48A4A"))
	var wrap := _paint(Color("3A2A1C"))
	_cyl(n, Vector3(0, 0.04, 0.48), 0.045, 1.05, wood, Vector3(90, 0, 0))
	_cyl(n, Vector3(0, 0.04, 0.95), 0.07, 0.18, wood, Vector3(90, 0, 0))
	_cyl(n, Vector3(0, 0.04, 0.06), 0.04, 0.16, wrap, Vector3(90, 0, 0))
	_box(n, Vector3(0, 0.04, -0.04), Vector3(0.07, 0.07, 0.08), wrap)


static func _ammo(n: Node3D) -> void:
	var wood := _wood(Color("6A4A28"))
	var brass := _steel(Color("C4A05A"))
	_box(n, Vector3(0, 0.1, 0), Vector3(0.32, 0.2, 0.22), wood)
	_box(n, Vector3(0, 0.21, 0), Vector3(0.34, 0.04, 0.24), _wood(Color("3A2418")))
	_cyl(n, Vector3(-0.07, 0.26, 0.0), 0.025, 0.08, brass)
	_cyl(n, Vector3(0.0, 0.26, 0.04), 0.025, 0.08, brass)
	_cyl(n, Vector3(0.07, 0.26, -0.03), 0.025, 0.08, brass)


static func _candy(n: Node3D) -> void:
	_sph(n, Vector3(0, 0.14, 0), 0.12, _glow(Color("FF8A3A"), 0.6))
	_box(n, Vector3(0, 0.14, 0), Vector3(0.38, 0.04, 0.1), _paint(Color("FFE27A")))
	_box(n, Vector3(0.16, 0.14, 0), Vector3(0.08, 0.015, 0.12), _paint(Color("C43A32")))
	_box(n, Vector3(-0.16, 0.14, 0), Vector3(0.08, 0.015, 0.12), _paint(Color("C43A32")))


static func _tart(n: Node3D) -> void:
	_cyl(n, Vector3(0, 0.08, 0), 0.14, 0.06, _paint(Color("C48A4A")))
	_cyl(n, Vector3(0, 0.12, 0), 0.12, 0.05, _paint(Color("E07020")))
	_sph(n, Vector3(-0.04, 0.16, 0.03), 0.045, _glow(Color("E56BA0"), 0.5))
	_sph(n, Vector3(0.04, 0.16, 0.03), 0.045, _glow(Color("E56BA0"), 0.5))


static func _oil(n: Node3D) -> void:
	_cyl(n, Vector3(0, 0.16, 0), 0.08, 0.28, _paint(Color("C45A20")))
	_cyl(n, Vector3(0, 0.16, 0), 0.06, 0.22, _glow(Color("FFB347"), 0.7))
	_cyl(n, Vector3(0, 0.32, 0), 0.04, 0.08, _paint(Color("3A2418")))
	_sph(n, Vector3(0, 0.38, 0), 0.035, _glow(Color("FFE27A"), 0.8))


static func _box(host: Node3D, pos: Vector3, size: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3.ONE
	mi.mesh = b
	mi.position = pos
	mi.scale = size
	mi.material_override = mat
	host.add_child(mi)


static func _cyl(host: Node3D, pos: Vector3, radius: float, height: float, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = 12
	mi.mesh = c
	mi.position = pos
	mi.rotation_degrees = rot
	mi.material_override = mat
	host.add_child(mi)


static func _sph(host: Node3D, pos: Vector3, radius: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 12
	s.rings = 8
	mi.mesh = s
	mi.position = pos
	mi.material_override = mat
	host.add_child(mi)


static func _steel(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.72
	m.roughness = 0.32
	m.rim_enabled = true
	m.rim = 0.22
	return m


static func _wood(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.78
	m.metallic = 0.0
	return m


static func _paint(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.55
	return m


static func _glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.28
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m
