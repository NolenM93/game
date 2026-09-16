class_name HollowTown
extends Node3D

const Station = preload("res://scripts/hollow/station.gd")

var world: Node
var asphalt: StandardMaterial3D
var walk: StandardMaterial3D
var brick: StandardMaterial3D
var wood: StandardMaterial3D
var plaster: StandardMaterial3D
var rust: StandardMaterial3D
var metal: StandardMaterial3D
var tile: StandardMaterial3D
var stations: Array = []
var town_lamps: Array[OmniLight3D] = []
var power_glow: Array[OmniLight3D] = []


func setup(p_world: Node) -> void:
	world = p_world
	asphalt = _noise([Color("1C1C20"), Color("2A2A30"), Color("3A3A42")], 0.08, 0.03, 19)
	walk = _noise([Color("4A4842"), Color("5C5A52"), Color("6A6860")], 0.1, 0.04, 5)
	brick = _noise([Color("5A2E28"), Color("6E3A32"), Color("8A4A3C")], 0.06, 0.022, 9)
	wood = _noise([Color("3A2418"), Color("5A3A24"), Color("6E4A2C")], 0.11, 0.04, 14)
	plaster = _noise([Color("C8B8A0"), Color("D4C6B0"), Color("B8A888")], 0.04, 0.02, 21)
	rust = _noise([Color("4A2818"), Color("6A3A22"), Color("3A2014")], 0.12, 0.05, 8)
	metal = _noise([Color("3A3E44"), Color("4A5058"), Color("2A2E32")], 0.09, 0.04, 3)
	tile = _noise([Color("6A5A4A"), Color("8A7A68"), Color("5A4A3C")], 0.16, 0.06, 17)
	_roads()
	_intersection()
	_shops()
	_props()
	_stations()


func _roads() -> void:
	var gy := 0.72
	_box(Vector3(34.0, gy + 0.015, 0.0), Vector3(52.0, 0.04, 6.4), Color("2A2A30"), false, asphalt)
	_box(Vector3(48.0, gy + 0.015, 0.0), Vector3(6.4, 0.04, 52.0), Color("2A2A30"), false, asphalt)
	_box(Vector3(34.0, gy + 0.02, 4.05), Vector3(52.0, 0.05, 1.5), Color("5C5A52"), false, walk)
	_box(Vector3(34.0, gy + 0.02, -4.05), Vector3(52.0, 0.05, 1.5), Color("5C5A52"), false, walk)
	_box(Vector3(48.0, gy + 0.02, 0.0), Vector3(1.5, 0.05, 52.0), Color("5C5A52"), false, walk)
	for i in 7:
		_box(Vector3(48.0, gy + 0.04, -2.4 + i * 0.8), Vector3(2.6, 0.02, 0.32), Color("D8D0C0"), false)
	for i in 7:
		_box(Vector3(45.6 + i * 0.8, gy + 0.04, 0.0), Vector3(0.32, 0.02, 2.6), Color("D8D0C0"), false)
	for i in 12:
		_box(Vector3(12.0 + i * 4.0, gy + 0.04, 0.0), Vector3(1.6, 0.015, 0.12), Color("C4B060"), false)


func _intersection() -> void:
	var gy := 0.72
	_cyl(Vector3(51.8, gy + 1.5, 4.2), 0.07, 3.0, Color("3A3A40"))
	_box(Vector3(51.8, gy + 3.05, 4.2), Vector3(1.9, 0.5, 0.1), Color("2A6A3A"), false)
	_sign(Vector3(51.8, gy + 3.05, 4.36), "HOLLOW ST", 40)
	_cyl(Vector3(44.2, gy + 1.5, -4.2), 0.07, 3.0, Color("3A3A40"))
	_box(Vector3(44.2, gy + 3.1, -4.2), Vector3(0.14, 1.0, 0.78), Color("C43A32"), false)
	_sign(Vector3(44.2, gy + 3.1, -3.7), "STOP", 26)
	_box(Vector3(48.0, gy + 0.55, 0.0), Vector3(1.6, 1.1, 1.6), Color("3A3E38"), true, metal)
	_box(Vector3(48.0, gy + 1.25, 0.0), Vector3(0.85, 0.35, 0.55), Color("C4A05A"), false, metal)
	_box(Vector3(47.55, gy + 0.85, 0.55), Vector3(0.12, 0.7, 0.18), Color("2A2A2C"), false)
	_box(Vector3(48.45, gy + 0.85, 0.55), Vector3(0.12, 0.7, 0.18), Color("2A2A2C"), false)
	var bolt := Label3D.new()
	bolt.text = "⚡"
	bolt.font_size = 52
	bolt.position = Vector3(48.0, gy + 2.15, 0.0)
	bolt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	if Art.font_emoji:
		bolt.font = Art.font_emoji
	add_child(bolt)


func _shops() -> void:
	_building(Vector3(38.4, 0, -13.4), 0.0, "store")
	_building(Vector3(57.6, 0, -13.4), 0.0, "apoth")
	_building(Vector3(38.4, 0, 13.4), PI, "diner")
	_building(Vector3(57.6, 0, 13.4), PI, "sheriff")
	if world:
		for p in [Vector3(38.4, 0, -13.4), Vector3(57.6, 0, -13.4), Vector3(38.4, 0, 13.4), Vector3(57.6, 0, 13.4)]:
			world.hill_pads.append(p)


func _building(pad: Vector3, yaw: float, style: String) -> void:
	var gy := 0.72
	var n := Node3D.new()
	n.position = Vector3(pad.x, gy, pad.z)
	n.rotation.y = yaw
	add_child(n)
	var hull: Color
	var trim: Color
	var title := ""
	var sub := ""
	match style:
		"store":
			hull = Color("4A3428")
			trim = Color("2A1C14")
			title = "GENERAL"
			sub = "STORE"
		"apoth":
			hull = Color("C8C0B0")
			trim = Color("5A3A4A")
			title = "APOTHECARY"
			sub = "& TONICS"
		"diner":
			hull = Color("C45A38")
			trim = Color("FFF6D8")
			title = "HOLLOW"
			sub = "DINER"
		_:
			hull = Color("3A4A38")
			trim = Color("C4A05A")
			title = "SHERIFF"
			sub = "NO. 12"
	var hull_m: Material = brick if style == "store" or style == "sheriff" else _mat(hull)
	if style == "diner":
		hull_m = _noise([Color("A84828"), Color("C45A38"), Color("8A3020")], 0.07, 0.03, 12)
	if style == "apoth":
		hull_m = plaster
	_shell(n, hull_m, trim, title, sub)
	_stairs(n)
	_upper_floors(n, style)
	_fire_escape(n)
	match style:
		"store":
			_fit_store(n)
		"apoth":
			_fit_apoth(n)
		"diner":
			_fit_diner(n)
		_:
			_fit_sheriff(n)
	_glow_inside(n)


func _shell(n: Node3D, hull: Material, trim: Color, title: String, sub: String) -> void:
	# Stencil shop: separate wall / floor boxes. No CSG combiner — its trimesh
	# was filling the stairwell. West well stays a real hole on every storey.
	_wall_front(n, hull, 5.52)
	_wall_front(n, hull, -5.52)
	_box(Vector3(-5.72, 5.5, 0), Vector3(0.4, 11.0, 11.04), Color("4A3428"), true, hull, n)
	_east_wall(n, hull)
	_floors(n)
	var pane := _lit(Color("FFB070", 0.38), 0.85)
	var night := _lit(Color("7EC8E8", 0.26), 0.4)
	var cuts: Array = [
		[Vector3(-3.45, 1.95, 5.72), Vector3(1.25, 1.4, 0.06), false],
		[Vector3(3.45, 1.95, 5.72), Vector3(1.25, 1.4, 0.06), false],
		[Vector3(-3.45, 5.35, 5.72), Vector3(1.25, 1.35, 0.06), false],
		[Vector3(0.0, 5.35, 5.72), Vector3(1.25, 1.35, 0.06), false],
		[Vector3(3.45, 5.35, 5.72), Vector3(1.25, 1.35, 0.06), false],
		[Vector3(-3.45, 8.45, 5.72), Vector3(1.2, 1.2, 0.06), false],
		[Vector3(3.45, 8.45, 5.72), Vector3(1.2, 1.2, 0.06), false],
		[Vector3(-2.5, 5.35, -5.72), Vector3(1.2, 1.35, 0.06), false],
		[Vector3(2.5, 5.35, -5.72), Vector3(1.2, 1.35, 0.06), false],
		[Vector3(-2.5, 8.45, -5.72), Vector3(1.15, 1.2, 0.06), false],
		[Vector3(-5.94, 1.95, -2.15), Vector3(0.06, 1.4, 1.2), true],
		[Vector3(-5.94, 5.35, 1.55), Vector3(0.06, 1.35, 1.2), true],
		[Vector3(-5.94, 8.45, -1.4), Vector3(0.06, 1.2, 1.15), true],
		[Vector3(5.94, 1.95, 1.35), Vector3(0.06, 1.4, 1.2), true],
		[Vector3(5.94, 5.35, -2.05), Vector3(0.06, 1.35, 1.2), true],
		[Vector3(5.94, 8.45, -1.8), Vector3(0.06, 1.2, 1.15), true],
	]
	for i in cuts.size():
		var cut: Array = cuts[i]
		_window(n, cut[0], pane if (cut[0] as Vector3).y < 3.5 else night, cut[2] as bool)
	_board(n, Vector3(-5.94, 1.95, 2.45), true)
	_board(n, Vector3(5.94, 5.35, 2.25), true)
	_box(Vector3(0, 11.35, 5.52), Vector3(12.2, 1.85, 0.38), Color("2A1C14"), true, hull, n)
	_box(Vector3(0, 12.35, 5.52), Vector3(12.6, 0.22, 0.5), trim, false, null, n)
	_box(Vector3(-5.7, 11.9, 5.52), Vector3(0.28, 1.1, 0.48), trim, false, null, n)
	_box(Vector3(5.7, 11.9, 5.52), Vector3(0.28, 1.1, 0.48), trim, false, null, n)
	_box(Vector3(0, 11.18, -0.2), Vector3(12.6, 0.2, 11.6), Color("2A2420"), true, rust, n)
	_box(Vector3(0, 11.32, -0.4), Vector3(10.6, 0.14, 9.6), Color("3A2A22"), false, rust, n)
	_box(Vector3(-4.15, 12.15, -3.5), Vector3(1.15, 1.7, 0.95), Color("4A3A32"), true, brick, n)
	_box(Vector3(-4.15, 13.1, -3.5), Vector3(1.35, 0.18, 1.15), Color("2A1C14"), false, null, n)
	_cyl(Vector3(-4.15, 13.35, -3.5), 0.12, 0.4, Color("1A140E"), n)
	_box(Vector3(0, 3.38, 5.95), Vector3(4.6, 0.12, 1.55), trim, false, null, n)
	_cyl(Vector3(-1.75, 1.66, 6.45), 0.09, 3.3, Color("2A1C14"), n)
	_cyl(Vector3(1.75, 1.66, 6.45), 0.09, 3.3, Color("2A1C14"), n)
	_box(Vector3(0, 3.58, 5.68), Vector3(5.0, 0.58, 0.16), trim, false, null, n)
	var sign := Label3D.new()
	sign.text = "%s\n%s" % [title, sub]
	sign.font_size = 34
	sign.outline_size = 6
	sign.position = Vector3(0, 3.58, 5.82)
	sign.modulate = Color("FFE27A")
	if Art.font_title:
		sign.font = Art.font_title
	n.add_child(sign)
	_box(Vector3(-1.02, 1.2, 5.52), Vector3(0.12, 2.4, 0.22), Color("2A1C14"), false, wood, n)
	_box(Vector3(1.02, 1.2, 5.52), Vector3(0.12, 2.4, 0.22), Color("2A1C14"), false, wood, n)
	_box(Vector3(0, 2.42, 5.52), Vector3(2.16, 0.12, 0.22), Color("2A1C14"), false, wood, n)
	_box(Vector3(0, 0.06, 5.75), Vector3(2.2, 0.1, 1.1), Color("3A2A22"), true, wood, n)
	_box(Vector3(0, 0.06, -5.75), Vector3(2.2, 0.1, 1.1), Color("3A2A22"), true, wood, n)


func _window(n: Node3D, pos: Vector3, mat: Material, side: bool = false) -> void:
	var size := Vector3(0.04, 1.28, 1.08) if side else Vector3(1.08, 1.28, 0.04)
	_box(pos, size, Color("FFB070", 0.35), false, mat, n)
	var frame := Color("2A1C14")
	if side:
		_box(pos + Vector3(0, 0.72, 0), Vector3(0.12, 0.08, 1.24), frame, false, wood, n)
		_box(pos + Vector3(0, -0.72, 0), Vector3(0.12, 0.08, 1.24), frame, false, wood, n)
		_box(pos, Vector3(0.1, 1.42, 0.06), frame, false, wood, n)
	else:
		_box(pos + Vector3(0, 0.72, 0), Vector3(1.24, 0.08, 0.12), frame, false, wood, n)
		_box(pos + Vector3(0, -0.72, 0), Vector3(1.24, 0.08, 0.12), frame, false, wood, n)
		_box(pos, Vector3(0.06, 1.42, 0.1), frame, false, wood, n)


func _board(n: Node3D, pos: Vector3, side: bool = false) -> void:
	var size := Vector3(0.12, 1.45, 1.25) if side else Vector3(1.25, 1.45, 0.12)
	_box(pos, size, Color("4A3424"), false, wood, n)
	for i in 3:
		var o := (i - 1) * 0.32
		if side:
			_box(pos + Vector3(0.02, o, 0), Vector3(0.14, 0.1, 1.32), Color("3A2418"), false, null, n)
		else:
			_box(pos + Vector3(0, o, 0.02), Vector3(1.32, 0.1, 0.14), Color("3A2418"), false, null, n)


func _wall_front(n: Node3D, hull: Material, z: float) -> void:
	# Split around a 1.9 x 2.28 door so the hunter capsule fits cleanly.
	_box(Vector3(-3.35, 5.5, z), Vector3(4.74, 11.0, 0.4), Color("4A3428"), true, hull, n)
	_box(Vector3(3.35, 5.5, z), Vector3(4.74, 11.0, 0.4), Color("4A3428"), true, hull, n)
	_box(Vector3(0.0, 6.64, z), Vector3(2.0, 8.72, 0.4), Color("4A3428"), true, hull, n)


func _east_wall(n: Node3D, hull: Material) -> void:
	# Fire-escape doors at 2nd and attic. Hunter needs 1.35 wide, 2.1 tall.
	_box(Vector3(5.72, 5.5, -2.06), Vector3(0.4, 11.0, 6.92), Color("4A3428"), true, hull, n)
	_box(Vector3(5.72, 5.5, 4.21), Vector3(0.4, 11.0, 2.62), Color("4A3428"), true, hull, n)
	_box(Vector3(5.72, 1.68, 2.15), Vector3(0.4, 3.36, 1.5), Color("4A3428"), true, hull, n)
	_box(Vector3(5.72, 6.48, 2.15), Vector3(0.4, 1.28, 1.5), Color("4A3428"), true, hull, n)
	_box(Vector3(5.72, 10.02, 2.15), Vector3(0.4, 1.96, 1.5), Color("4A3428"), true, hull, n)


func _floors(n: Node3D) -> void:
	# Ground is solid. Upper floors stop at x = -3.0 so the west well is empty.
	_box(Vector3(0.0, 0.06, 0.0), Vector3(11.04, 0.12, 10.64), Color("4A3428"), true, wood, n)
	_box(Vector3(1.26, 3.52, 0.0), Vector3(8.52, 0.14, 10.64), Color("4A3428"), true, wood, n)
	_box(Vector3(1.26, 7.04, 0.0), Vector3(8.52, 0.14, 10.64), Color("4A3428"), true, wood, n)
	# Landings inside the well, flush with each floor.
	_box(Vector3(-4.08, 3.52, 1.65), Vector3(2.48, 0.14, 2.0), Color("5A3A24"), true, wood, n)
	_box(Vector3(-4.08, 7.04, -4.05), Vector3(2.48, 0.14, 2.2), Color("5A3A24"), true, wood, n)


func _stairs(n: Node3D) -> void:
	# Open west well. Closed-riser flights + a walk-ramp under them. No solid
	# well-wall — that slab was the brown plane you walked through.
	var sx := -4.15
	var w := 2.18
	_stair_flight(n, sx, 0.12, -4.48, 12, 0.283, 0.44, 1.0, w, wood, false)
	_stair_flight(n, sx, 3.52, 1.42, 12, 0.293, 0.44, -1.0, w, wood, false)
	_well_rail(n, -3.04, 3.52, -5.05, 0.4)
	_well_rail(n, -3.04, 7.04, -2.8, 1.5)


func _upper_floors(n: Node3D, style: String) -> void:
	# 2nd floor: hall, bedroom, closet you can duck into.
	_box(Vector3(-1.55, 5.18, -1.55), Vector3(0.16, 3.05, 7.5), Color("C8B8A0"), true, plaster, n)
	_box(Vector3(-1.55, 5.18, 4.45), Vector3(0.16, 3.05, 1.7), Color("C8B8A0"), true, plaster, n)
	_box(Vector3(-1.55, 6.6, 2.6), Vector3(0.16, 0.28, 2.0), Color("C8B8A0"), true, plaster, n)
	_box(Vector3(2.15, 5.18, -1.55), Vector3(6.7, 3.05, 0.16), Color("C8B8A0"), true, plaster, n)
	_box(Vector3(3.55, 5.18, 3.55), Vector3(3.9, 3.05, 0.14), Color("C8B8A0"), true, plaster, n)
	_box(Vector3(1.65, 5.18, 4.45), Vector3(0.14, 3.05, 1.7), Color("C8B8A0"), true, plaster, n)
	_box(Vector3(1.65, 6.55, 3.15), Vector3(0.14, 0.3, 0.9), Color("C8B8A0"), true, plaster, n)
	_crate(n, Vector3(4.15, 3.7, 4.35))
	_crate(n, Vector3(3.35, 3.7, 4.55))
	_crate(n, Vector3(4.35, 3.7, 3.85))
	_table(n, Vector3(3.15, 3.7, -3.55), 1.5, 0.85)
	if style == "diner" or style == "store":
		_bed(n, Vector3(3.7, 3.7, -3.85))
	else:
		_desk(n, Vector3(3.5, 3.7, -3.75))
	_crate(n, Vector3(4.7, 3.7, -0.35))
	_box(Vector3(1.4, 8.55, -0.4), Vector3(0.14, 2.7, 8.8), Color("C8B8A0"), true, plaster, n)
	_box(Vector3(1.4, 9.75, 4.4), Vector3(0.14, 0.3, 1.4), Color("C8B8A0"), true, plaster, n)
	_bed(n, Vector3(3.5, 7.18, -3.6))
	_crate(n, Vector3(4.2, 7.18, 3.4))
	_crate(n, Vector3(3.4, 7.18, 3.9))
	_crate(n, Vector3(4.5, 7.18, 2.7))
	_table(n, Vector3(3.2, 7.18, 0.2), 1.3, 0.7)
	_barrel(n, Vector3(3.5, 7.18, -3.6))
	_barrel(n, Vector3(4.2, 7.18, -4.0))
	_loot(n, Vector3(3.6, 7.95, -3.4), "ammo")
	_loot(n, Vector3(4.1, 7.7, 3.3), "candy")


func _fire_escape(n: Node3D) -> void:
	# Compact Z-switchback on the east wall, door (z=2.15) to the front corner.
	var x := 6.62
	var w := 1.32
	_box(Vector3(x, 0.08, 2.15), Vector3(w, 0.12, 1.7), Color("4A3A32"), true, rust, n)
	_stair_flight(n, x, 0.08, 2.88, 10, 0.344, 0.26, 1.0, w, rust, true)
	_box(Vector3(x, 3.52, 5.42), Vector3(w, 0.12, 1.35), Color("4A3A32"), true, rust, n)
	_box(Vector3(x, 3.52, 3.72), Vector3(w, 0.12, 3.6), Color("4A3A32"), true, rust, n)
	_stair_flight(n, x, 3.52, 5.18, 10, 0.352, 0.30, -1.0, w, rust, true)
	_box(Vector3(x, 7.04, 2.15), Vector3(w, 0.12, 1.8), Color("4A3A32"), true, rust, n)
	_stair_flight(n, x, 7.04, 2.88, 10, 0.414, 0.26, 1.0, w, rust, true)
	_box(Vector3(x, 11.18, 5.42), Vector3(w, 0.12, 1.35), Color("4A3A32"), true, rust, n)
	_well_rail(n, x + 0.64, 3.52, 1.9, 5.9, true)
	_well_rail(n, x + 0.64, 7.04, 1.4, 3.0, true)
	_box(Vector3(x + 0.64, 5.7, 2.15), Vector3(0.05, 11.2, 0.05), Color("3A2A22"), false, rust, n)
	_box(Vector3(x - 0.64, 5.7, 2.15), Vector3(0.05, 11.2, 0.05), Color("3A2A22"), false, rust, n)


func _stair_flight(n: Node3D, x: float, y0: float, z0: float, steps: int, rise: float, run: float, dir: float, width: float, mat: Material, rusty: bool) -> void:
	var y1 := y0 + float(steps) * rise
	var z1 := z0 + float(steps) * run * dir
	_col_ramp(n, x, y0, z0, y1, z1, width)
	var col := Color("4A3A32") if rusty else Color("5A3A24")
	for i in steps:
		var y_top := y0 + float(i + 1) * rise
		var z_mid := z0 + (float(i) + 0.5) * run * dir
		_box(Vector3(x, y_top - 0.04, z_mid), Vector3(width, 0.08, run + 0.05), col, false, mat, n)
		var z_r := z0 + float(i) * run * dir
		_box(Vector3(x, y0 + float(i) * rise + rise * 0.5, z_r), Vector3(width, rise, 0.05), col, false, mat, n)
	var hx := width * 0.5 - 0.03
	_stringer(n, x - hx, y0, z0, y1, z1, mat, col)
	_stringer(n, x + hx, y0, z0, y1, z1, mat, col)


func _stringer(n: Node3D, x: float, y0: float, z0: float, y1: float, z1: float, mat: Material, col: Color) -> void:
	var za := minf(z0, z1)
	var zb := maxf(z0, z1)
	var ya := y0 if z0 <= z1 else y1
	var yb := y1 if z0 <= z1 else y0
	var dz := zb - za
	var dy := yb - ya
	var length := sqrt(dz * dz + dy * dy)
	var ang := -atan2(dy, dz)
	_box(Vector3(x, (ya + yb) * 0.5, (za + zb) * 0.5), Vector3(0.07, 0.22, length), col, false, mat, n, 0.0, ang)


func _col_ramp(n: Node3D, x: float, y0: float, z0: float, y1: float, z1: float, width: float) -> void:
	var za := minf(z0, z1)
	var zb := maxf(z0, z1)
	var ya := y0 if z0 <= z1 else y1
	var yb := y1 if z0 <= z1 else y0
	var dz := zb - za
	var dy := yb - ya
	var length := sqrt(dz * dz + dy * dy)
	var ang := -atan2(dy, dz)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector3(x, (ya + yb) * 0.5 - 0.06 * cos(ang), (za + zb) * 0.5)
	body.rotation.x = ang
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, 0.16, length)
	cs.shape = box
	body.add_child(cs)
	n.add_child(body)


func _well_rail(n: Node3D, x: float, y: float, z0: float, z1: float, rusty: bool = false) -> void:
	var za := minf(z0, z1)
	var zb := maxf(z0, z1)
	var h := 0.9
	var col := Color("3A2A22") if rusty else Color("3A2A1C")
	var mat: Material = rust if rusty else wood
	var z := za
	while z <= zb + 0.01:
		_box(Vector3(x, y + h * 0.5, z), Vector3(0.045, h, 0.045), col, false, mat, n)
		z += 0.55
	_box(Vector3(x, y + h, (za + zb) * 0.5), Vector3(0.045, 0.05, zb - za + 0.1), col, false, mat, n)



func _fit_store(n: Node3D) -> void:
	# Shop floor: long counters and aisles of shelves to duck behind.
	_counter(n, Vector3(0.5, 0.0, 3.2), 5.4)
	_shelf(n, Vector3(-1.7, 0.0, 0.6), 0.0)
	_shelf(n, Vector3(-1.7, 0.0, -0.8), 0.0)
	_shelf(n, Vector3(3.6, 0.0, 0.6), PI)
	_shelf(n, Vector3(3.6, 0.0, -0.8), PI)
	_partition(n, -1.15)
	_crate(n, Vector3(-1.5, 0.08, -3.4))
	_crate(n, Vector3(-0.8, 0.08, -3.8))
	_crate(n, Vector3(3.4, 0.08, -3.2))
	_barrel(n, Vector3(4.2, 0.08, 3.4))
	_barrel(n, Vector3(4.35, 0.08, 2.55))
	_box(Vector3(1.6, 1.22, 3.15), Vector3(0.55, 0.28, 0.42), Color("2A2A30"), false, metal, n)
	_table(n, Vector3(2.2, 0.08, -3.8), 1.6, 1.0)
	_loot(n, Vector3(0.4, 0.95, 3.0), "ammo")
	_loot(n, Vector3(-1.7, 1.2, 0.6), "candy")
	_loot(n, Vector3(3.2, 3.9, -3.6), "heart")


func _fit_apoth(n: Node3D) -> void:
	_counter(n, Vector3(1.2, 0.0, 2.8), 5.2)
	_shelf(n, Vector3(-1.7, 0.0, 1.4), 0.0)
	_shelf(n, Vector3(-1.7, 0.0, -0.2), 0.0)
	_shelf(n, Vector3(3.9, 0.0, 0.4), PI)
	_partition(n, -1.3)
	_desk(n, Vector3(-1.4, 0.08, -3.6))
	_crate(n, Vector3(3.6, 0.08, -3.6))
	for i in 12:
		_sph(Vector3(-1.6, 1.15 + (i % 3) * 0.35, 1.25 - int(i / 3) * 0.28), 0.07, Color("7EC8E8") if i % 2 == 0 else Color("E56BA0"), n)
	_cyl(Vector3(3.6, 0.55, -3.2), 0.42, 0.7, Color("3A2A22"), n, true)
	_cyl(Vector3(3.6, 0.95, -3.2), 0.48, 0.12, Color("2A1C14"), n, false)
	_loot(n, Vector3(1.0, 0.95, 2.6), "oil")
	_loot(n, Vector3(-1.4, 0.9, -3.4), "heart")
	_loot(n, Vector3(3.8, 3.9, 3.4), "ammo")


func _fit_diner(n: Node3D) -> void:
	_counter(n, Vector3(0.6, 0.0, 1.6), 5.2)
	for i in 4:
		_stool(n, Vector3(-1.6 + i * 1.15, 0.08, 2.35))
	_booth(n, Vector3(3.5, 0.08, 3.4))
	_booth(n, Vector3(3.5, 0.08, 1.3))
	_partition(n, -1.0)
	_box(Vector3(-1.2, 0.85, -3.2), Vector3(1.6, 1.6, 1.1), Color("4A5058"), true, metal, n)
	_box(Vector3(0.4, 0.7, -3.4), Vector3(1.6, 1.3, 0.9), Color("3A3A40"), true, metal, n)
	_box(Vector3(2.6, 0.55, -3.5), Vector3(1.4, 1.0, 1.4), Color("6A3A22"), true, rust, n)
	_cyl(Vector3(-1.4, 1.75, -2.85), 0.18, 0.35, Color("C45A38"), n, false)
	_box(Vector3(0.6, 1.15, -3.35), Vector3(1.1, 0.7, 0.55), Color("7EC8E8", 0.35), true, _lit(Color("7EC8E8", 0.28), 0.35), n)
	_crate(n, Vector3(4.2, 0.08, -2.8))
	_loot(n, Vector3(-0.4, 0.95, 1.4), "candy")
	_loot(n, Vector3(3.5, 0.7, 3.4), "ammo")
	_loot(n, Vector3(3.4, 3.9, -3.6), "oil")


func _fit_sheriff(n: Node3D) -> void:
	_desk(n, Vector3(-1.4, 0.08, 2.6))
	_desk(n, Vector3(1.6, 0.08, 2.2))
	_partition(n, -0.9)
	# Jail cell in the back-right — keep the west stairwell clear.
	_box(Vector3(4.55, 1.5, -3.35), Vector3(1.4, 3.0, 0.12), Color("3A3E44"), true, metal, n)
	_box(Vector3(2.85, 1.5, -4.4), Vector3(0.12, 3.0, 2.2), Color("3A3E44"), true, metal, n)
	for i in 4:
		_cyl(Vector3(3.2 + i * 0.22, 1.5, -3.32), 0.035, 2.8, Color("4A5058"), n, false)
	_bed(n, Vector3(3.7, 0.08, -4.45))
	_crate(n, Vector3(3.8, 0.08, -2.4))
	_crate(n, Vector3(3.2, 0.08, 0.6))
	_box(Vector3(4.4, 1.2, 0.4), Vector3(0.16, 2.2, 1.8), Color("3A2A1C"), true, wood, n)
	var poster := Label3D.new()
	poster.text = "WANTED"
	poster.font_size = 28
	poster.position = Vector3(4.32, 1.85, 0.4)
	poster.rotation.y = -PI * 0.5
	poster.modulate = Color("C43A32")
	if Art.font_title:
		poster.font = Art.font_title
	n.add_child(poster)
	_loot(n, Vector3(-1.4, 0.85, 2.5), "ammo")
	_loot(n, Vector3(3.6, 0.55, -4.3), "heart")
	_loot(n, Vector3(3.6, 3.9, 3.5), "ammo")


func _partition(n: Node3D, z: float) -> void:
	# Back-room wall. Stops east of the well (x > -2.7).
	_box(Vector3(-1.75, 1.6, z), Vector3(1.8, 3.2, 0.16), Color("C8B8A0"), true, plaster, n)
	_box(Vector3(3.6, 1.6, z), Vector3(4.6, 3.2, 0.16), Color("C8B8A0"), true, plaster, n)
	_box(Vector3(0.35, 2.95, z), Vector3(2.5, 0.5, 0.16), Color("C8B8A0"), true, plaster, n)


func _counter(n: Node3D, pos: Vector3, wide: float) -> void:
	_box(pos + Vector3(0, 0.55, 0), Vector3(wide, 1.05, 0.7), Color("5A3A24"), true, wood, n)
	_box(pos + Vector3(0, 1.1, 0), Vector3(wide + 0.1, 0.08, 0.82), Color("3A2418"), true, wood, n)


func _shelf(n: Node3D, pos: Vector3, yaw: float) -> void:
	var h := Node3D.new()
	h.position = pos
	h.rotation.y = yaw
	n.add_child(h)
	_box(Vector3(0, 1.15, 0), Vector3(0.4, 2.3, 2.4), Color("4A3220"), true, wood, h)
	for i in 4:
		_box(Vector3(0.12, 0.35 + i * 0.52, 0), Vector3(0.5, 0.06, 2.3), Color("6A4A2C"), true, wood, h)


func _table(n: Node3D, pos: Vector3, w: float, d: float) -> void:
	_box(pos + Vector3(0, 0.72, 0), Vector3(w, 0.08, d), Color("5A3A24"), true, wood, n)
	_box(pos + Vector3(-w * 0.4, 0.35, -d * 0.35), Vector3(0.08, 0.7, 0.08), Color("3A2418"), true, null, n)
	_box(pos + Vector3(w * 0.4, 0.35, -d * 0.35), Vector3(0.08, 0.7, 0.08), Color("3A2418"), true, null, n)
	_box(pos + Vector3(-w * 0.4, 0.35, d * 0.35), Vector3(0.08, 0.7, 0.08), Color("3A2418"), true, null, n)
	_box(pos + Vector3(w * 0.4, 0.35, d * 0.35), Vector3(0.08, 0.7, 0.08), Color("3A2418"), true, null, n)


func _desk(n: Node3D, pos: Vector3) -> void:
	_box(pos + Vector3(0, 0.7, 0), Vector3(1.7, 0.1, 0.85), Color("4A3220"), true, wood, n)
	_box(pos + Vector3(-0.7, 0.35, 0), Vector3(0.3, 0.7, 0.8), Color("3A2418"), true, wood, n)
	_box(pos + Vector3(0.7, 0.35, 0), Vector3(0.3, 0.7, 0.8), Color("3A2418"), true, wood, n)
	_box(pos + Vector3(0.2, 0.82, 0.1), Vector3(0.35, 0.08, 0.28), Color("1A140E"), false, null, n)


func _bed(n: Node3D, pos: Vector3) -> void:
	_box(pos + Vector3(0, 0.28, 0), Vector3(1.1, 0.35, 2.0), Color("3A2A22"), true, wood, n)
	_box(pos + Vector3(0, 0.52, 0), Vector3(1.05, 0.16, 1.9), Color("6A4A5A"), true, null, n)
	_box(pos + Vector3(0, 0.62, -0.7), Vector3(0.7, 0.18, 0.4), Color("D4C6B0"), false, plaster, n)


func _booth(n: Node3D, pos: Vector3) -> void:
	_box(pos + Vector3(0, 0.42, 0), Vector3(1.5, 0.12, 1.1), Color("C45A38"), true, null, n)
	_box(pos + Vector3(0, 0.7, -0.55), Vector3(1.5, 0.7, 0.16), Color("6A2A20"), true, null, n)
	_box(pos + Vector3(-0.7, 0.7, 0), Vector3(0.16, 0.7, 1.1), Color("6A2A20"), true, null, n)


func _stool(n: Node3D, pos: Vector3) -> void:
	_cyl(pos + Vector3(0, 0.45, 0), 0.16, 0.9, Color("3A2A1C"), n, true)
	_cyl(pos + Vector3(0, 0.92, 0), 0.2, 0.08, Color("C45A38"), n, false)


func _crate(n: Node3D, pos: Vector3) -> void:
	_box(pos + Vector3(0, 0.38, 0), Vector3(0.78, 0.76, 0.78), Color("6A4A28"), true, wood, n)
	_box(pos + Vector3(0, 0.38, 0), Vector3(0.82, 0.06, 0.82), Color("3A2418"), false, null, n)


func _barrel(n: Node3D, pos: Vector3) -> void:
	_cyl(pos + Vector3(0, 0.52, 0), 0.38, 1.04, Color("6A3A22"), n, true)
	_cyl(pos + Vector3(0, 0.52, 0), 0.4, 0.08, Color("3A2418"), n, false)
	_cyl(pos + Vector3(0, 1.02, 0), 0.36, 0.08, Color("3A2418"), n, false)


func _glow_inside(n: Node3D) -> void:
	_omni(n, Vector3(0, 2.8, 1.4), Color("FFB070"), 0.5, 9.0)
	_omni(n, Vector3(2.4, 5.55, -2.4), Color("E8D2A0"), 0.38, 7.5)
	_omni(n, Vector3(-2.2, 5.55, 2.6), Color("FFB070"), 0.32, 6.5)
	_omni(n, Vector3(2.2, 8.7, 0.4), Color("E8D2A0"), 0.28, 6.0)


func _omni(n: Node3D, pos: Vector3, color: Color, energy: float, rng: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = pos
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.omni_range = rng
	lamp.shadow_enabled = false
	n.add_child(lamp)
	town_lamps.append(lamp)
	power_glow.append(lamp)


func _loot(n: Node3D, local: Vector3, id: String) -> void:
	if world == null or not world.has_method("_spawn_loot"):
		return
	world._spawn_loot(n.to_global(local), id)


func _props() -> void:
	var gy := 0.72
	_wreck(Vector3(31.5, gy, 6.6), 0.35, Color("3A4A38"), 0)
	_wreck(Vector3(62.2, gy, -6.5), 2.6, Color("5A2A28"), 1)
	_wreck(Vector3(24.0, gy, -6.7), -0.4, Color("2A3A4A"), 2)
	_wreck(Vector3(70.4, gy, 6.2), 1.1, Color("4A4A2A"), 3)
	_wreck(Vector3(14.5, gy, 6.4), 0.15, Color("4A3028"), 0)
	_wreck(Vector3(43.0, gy, -8.8), 1.85, Color("3A3A40"), 1)
	_wreck(Vector3(52.4, gy, 8.6), -0.7, Color("5A4030"), 2)
	_wreck(Vector3(33.8, gy, -8.4), 2.4, Color("2A3238"), 3)
	_dumpster(Vector3(32.2, gy, -8.2), 0.2)
	_dumpster(Vector3(63.8, gy, 8.4), 3.0)
	_dumpster(Vector3(45.2, gy, 18.6), 0.0)
	_wreck(Vector3(52.4, gy, 8.6), -0.7, Color("5A4030"), 2)
	_wreck(Vector3(33.8, gy, -8.4), 2.4, Color("2A3238"), 3)
	_dumpster(Vector3(32.2, gy, -8.2), 0.2)
	_dumpster(Vector3(63.8, gy, 8.4), 3.0)
	_dumpster(Vector3(45.2, gy, 18.6), 0.0)
	for x in [16.0, 26.0, 36.0, 66.0]:
		_lamp(Vector3(x, 0, 5.0))
		_lamp(Vector3(x, 0, -5.0))
	_lamp(Vector3(48.0, 0, 16.5))
	_lamp(Vector3(48.0, 0, -16.5))
	_hydrant(Vector3(29.5, gy, 4.7))
	_hydrant(Vector3(52.8, gy, -4.7))
	_can(Vector3(35.6, gy, 5.3))
	_can(Vector3(54.2, gy, -5.4))
	_can(Vector3(41.2, gy, 5.2))
	_mail(Vector3(20.4, gy, 4.8))
	_mail(Vector3(64.0, gy, -4.9))


func _wreck(pos: Vector3, yaw: float, color: Color, kind: int) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = yaw
	if kind == 2:
		n.rotation.z = 0.22
	add_child(n)
	var dark: Color = color.darkened(0.25)
	# Body + cabin.
	_box(Vector3(0.1, 0.52, 0), Vector3(3.9, 0.72, 1.7), color, true, rust if kind != 1 else null, n)
	_box(Vector3(-0.15, 1.12, 0), Vector3(2.15, 0.62, 1.62), dark, true, null, n)
	# Hood popped or crumpled.
	if kind == 0 or kind == 3:
		_box(Vector3(1.55, 0.95, 0), Vector3(1.15, 0.08, 1.5), color, false, rust, n, 0.55)
	else:
		_box(Vector3(1.5, 0.78, 0), Vector3(1.2, 0.16, 1.5), dark, true, rust, n)
	# Trunk / bed.
	if kind == 1:
		_box(Vector3(-1.55, 0.7, 0), Vector3(1.5, 0.45, 1.55), Color("3A2A22"), true, rust, n)
		_crate(n, Vector3(-1.5, 0.85, 0.15))
		_crate(n, Vector3(-1.7, 0.85, -0.35))
	else:
		_box(Vector3(-1.55, 0.72, 0), Vector3(1.15, 0.14, 1.5), dark, true, null, n)
	# Glass.
	var glass := _lit(Color("7EC8E8", 0.25), 0.15)
	_box(Vector3(0.7, 1.18, 0), Vector3(0.06, 0.42, 1.35), Color("7EC8E8", 0.22), false, glass, n)
	if kind != 2:
		_box(Vector3(-0.95, 1.18, 0), Vector3(0.06, 0.38, 1.3), Color("7EC8E8", 0.18), false, glass, n)
	# Door hanging open.
	_box(Vector3(0.35, 0.85, 1.15), Vector3(1.1, 0.85, 0.08), color, true, null, n, 0.7)
	# Wheels — one missing, lying in the gutter.
	_wheel(n, Vector3(-1.2, 0.32, 0.88))
	_wheel(n, Vector3(1.15, 0.32, 0.88))
	_wheel(n, Vector3(-1.2, 0.32, -0.88))
	if kind != 0:
		_wheel(n, Vector3(1.15, 0.32, -0.88))
	else:
		_wheel(n, Vector3(1.7, 0.18, -1.45), 1.2)
	# Bumper torn off.
	_box(Vector3(2.3, 0.28, 0.4), Vector3(0.16, 0.22, 1.3), Color("4A4A4A"), true, metal, n, 0.4)
	# Lights.
	_sph(Vector3(1.95, 0.62, 0.55), 0.12, Color("FFE27A") if kind != 3 else Color("2A2A2C"), n)
	_sph(Vector3(1.95, 0.62, -0.55), 0.12, Color("2A1A1A"), n)
	_sph(Vector3(-1.95, 0.62, 0.55), 0.1, Color("C43A32"), n)
	_sph(Vector3(-1.95, 0.62, -0.55), 0.1, Color("C43A32"), n)
	# Interior seats + wheel.
	_box(Vector3(0.15, 0.72, 0.35), Vector3(0.5, 0.28, 0.5), Color("2A1C18"), false, null, n)
	_box(Vector3(0.15, 0.72, -0.35), Vector3(0.5, 0.28, 0.5), Color("2A1C18"), false, null, n)
	_cyl(Vector3(0.75, 0.95, 0.2), 0.16, 0.05, Color("1A1A1C"), n)
	# Mirrors, antenna, exhaust.
	_box(Vector3(0.5, 1.15, 0.92), Vector3(0.18, 0.1, 0.22), Color("3A3A40"), false, metal, n)
	_cyl(Vector3(-0.4, 1.55, -0.2), 0.02, 0.7, Color("2A2A2C"), n)
	_cyl(Vector3(-1.9, 0.28, 0.45), 0.05, 0.35, Color("3A3A40"), n)
	# Rust holes, shattered glass on the curb, grille.
	_box(Vector3(-0.4, 0.7, 0.82), Vector3(0.55, 0.22, 0.08), Color("2A1810"), false, rust, n)
	_box(Vector3(0.9, 0.48, -0.2), Vector3(0.35, 0.12, 0.4), Color("3A2014"), false, rust, n)
	_box(Vector3(1.1, 0.08, 1.35), Vector3(0.55, 0.04, 0.4), Color("7EC8E8", 0.35), false, _lit(Color("7EC8E8", 0.2), 0.12), n)
	_box(Vector3(2.05, 0.42, 0), Vector3(0.08, 0.28, 1.35), Color("2A2A2C"), false, metal, n)
	# Gutter junk.
	_box(Vector3(2.1, 0.08, -1.1), Vector3(0.45, 0.08, 0.35), Color("5A5A60"), false, metal, n)
	_cyl(Vector3(-0.6, 0.08, -1.35), 0.16, 0.05, Color("3A3A40"), n)


func _wheel(n: Node3D, pos: Vector3, tilt: float = 0.0) -> void:
	var w := Node3D.new()
	w.position = pos
	w.rotation_degrees = Vector3(90.0, 0.0, tilt * 40.0)
	n.add_child(w)
	_cyl(Vector3.ZERO, 0.32, 0.22, Color("1A1A1C"), w, true)
	_cyl(Vector3.ZERO, 0.14, 0.24, Color("4A4A50"), w, false)


func _hydrant(pos: Vector3) -> void:
	_cyl(pos + Vector3(0, 0.45, 0), 0.16, 0.9, Color("C43A32"), self, true)
	_box(pos + Vector3(0, 0.85, 0), Vector3(0.45, 0.12, 0.18), Color("A83028"), false)
	_cyl(pos + Vector3(0, 0.98, 0), 0.12, 0.16, Color("C43A32"))


func _can(pos: Vector3) -> void:
	_cyl(pos + Vector3(0, 0.42, 0), 0.22, 0.85, Color("3A4638"), self, true)
	_cyl(pos + Vector3(0.05, 0.88, 0.05), 0.2, 0.08, Color("2A2A2C"))


func _dumpster(pos: Vector3, yaw: float) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = yaw
	add_child(n)
	_box(Vector3(0, 0.7, 0), Vector3(1.7, 1.35, 0.95), Color("3A4638"), true, metal, n)
	_box(Vector3(-0.15, 1.42, 0.05), Vector3(1.35, 0.08, 0.92), Color("2A2A2C"), true, rust, n, 0.45)
	_box(Vector3(0.85, 0.85, 0.52), Vector3(0.08, 0.55, 0.08), Color("2A2A2C"), false, metal, n)
	_cyl(Vector3(-0.7, 0.16, 0.4), 0.14, 0.18, Color("1A1A1C"), n, true)
	_cyl(Vector3(0.7, 0.16, 0.4), 0.14, 0.18, Color("1A1A1C"), n, true)
	_cyl(Vector3(-0.7, 0.16, -0.4), 0.14, 0.18, Color("1A1A1C"), n, true)
	_cyl(Vector3(0.7, 0.16, -0.4), 0.14, 0.18, Color("1A1A1C"), n, true)


func _mail(pos: Vector3) -> void:
	_box(pos + Vector3(0, 0.7, 0), Vector3(0.35, 0.55, 0.22), Color("3A5A8A"), true)
	_cyl(pos + Vector3(0, 0.32, 0), 0.05, 0.64, Color("3A3A40"), self, true)


func _lamp(xz: Vector3) -> void:
	var gy := 0.72
	_cyl(Vector3(xz.x, gy + 2.4, xz.z), 0.08, 4.8, Color("2A2A30"))
	_box(Vector3(xz.x, gy + 4.85, xz.z), Vector3(0.85, 0.14, 0.85), Color("3A3A40"), false, metal)
	_cyl(Vector3(xz.x, gy + 4.55, xz.z), 0.22, 0.28, Color("E8D2A0"))
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(xz.x, gy + 4.5, xz.z)
	lamp.light_color = Color("E8D2A0")
	lamp.light_energy = 0.45
	lamp.omni_range = 11.0
	add_child(lamp)
	town_lamps.append(lamp)
	power_glow.append(lamp)
	if world:
		world.lamp_posts.append(lamp)


func _stations() -> void:
	var gy := 0.72
	var debris := Node3D.new()
	debris.position = Vector3(21.5, gy, 0.0)
	add_child(debris)
	for i in 6:
		_box(Vector3(randf_range(-0.4, 0.4), 0.4 + i * 0.38, randf_range(-2.4, 2.4)), Vector3(0.22, 0.9, 1.8), Color("5A3A22"), true, wood, debris)
	_box(Vector3(0, 1.5, 0), Vector3(0.8, 3.0, 6.4), Color("3A2A1C"), true, wood, debris)
	var gate = _station("debris", "road", 150, "Clear the road", Vector3(21.5, gy, 0.0))
	gate.barrier = debris
	_station("wall", "gun_nailer", 100, "Tommy Gun", Vector3(38.4, gy, -7.6))
	_station("wall", "gun_gloop", 150, "M1 Garand", Vector3(38.4, gy, 7.6))
	_station("wall", "gun_frost", 250, "MP40", Vector3(57.6, gy, -7.6))
	_station("wall", "gun_rocket", 350, "Bazooka", Vector3(57.6, gy, 7.6))
	_station("perk", "jug", 500, "Pumpkin Punch", Vector3(31.4, gy, -13.4))
	_station("perk", "speed", 600, "Sugar Rush", Vector3(64.6, gy, -13.4))
	_station("perk", "double", 400, "Double Tap", Vector3(31.4, gy, 13.4))
	_station("perk", "revive", 100, "Quick Revive", Vector3(64.6, gy, 13.4))
	_station("power", "power", 0, "Power", Vector3(48.0, gy, 1.7))


func _station(kind: String, id: String, cost: int, title: String, pos: Vector3):
	var s = Station.new()
	s.setup(kind, id, cost, title)
	s.world = world
	s.position = pos
	add_child(s)
	stations.append(s)
	return s


func set_power(on: bool) -> void:
	for l in power_glow:
		if is_instance_valid(l):
			l.light_energy = (2.8 if on else 0.4)
			l.omni_range = 15.0 if on else 8.0


func _sign(pos: Vector3, text: String, size: int) -> void:
	var sign := Label3D.new()
	sign.text = text
	sign.font_size = size
	sign.outline_size = 6
	sign.position = pos
	sign.modulate = Color("FFF6D8")
	if Art.font_title:
		sign.font = Art.font_title
	add_child(sign)


func _box(pos: Vector3, size: Vector3, color: Color, coll: bool, mat: Material = null, host: Node = null, rot_y: float = 0.0, rot_x: float = 0.0) -> void:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.rotation.y = rot_y
	b.rotation.x = rot_x
	b.material = mat if mat else _mat(color)
	b.use_collision = coll
	(host if host else self).add_child(b)


func _cyl(pos: Vector3, radius: float, height: float, color: Color, host: Node = null, coll: bool = false) -> void:
	var c := CSGCylinder3D.new()
	c.radius = radius
	c.height = height
	c.sides = 12
	c.position = pos
	c.material = _mat(color)
	c.use_collision = coll
	(host if host else self).add_child(c)


func _sph(pos: Vector3, radius: float, color: Color, host: Node = null) -> void:
	var s := CSGSphere3D.new()
	s.radius = radius
	s.radial_segments = 10
	s.rings = 6
	s.position = pos
	s.material = _mat(color)
	s.use_collision = false
	(host if host else self).add_child(s)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.84
	if c.a < 0.99:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _lit(c: Color, energy: float) -> StandardMaterial3D:
	var m := _mat(c)
	m.emission_enabled = true
	m.emission = Color(c.r, c.g, c.b)
	m.emission_energy_multiplier = energy
	return m


func _noise(ramp: Array, uv_scale: float, freq: float, seed_v: int) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = seed_v
	noise.frequency = freq
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.noise = noise
	var grad := Gradient.new()
	grad.set_color(0, ramp[0])
	grad.set_color(1, ramp[ramp.size() - 1])
	for i in range(1, ramp.size() - 1):
		grad.add_point(float(i) / float(ramp.size() - 1), ramp[i])
	tex.color_ramp = grad
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	m.roughness = 0.92
	return m
