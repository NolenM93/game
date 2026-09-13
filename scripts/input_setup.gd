class_name InputSetup
extends RefCounted

static var _done := false


static func ensure() -> void:
	if _done:
		_strip_key("weap_next", KEY_E)
		_strip_key("weap_prev", KEY_Q)
		_strip_mouse("weap_next", MOUSE_BUTTON_WHEEL_DOWN)
		_strip_mouse("weap_prev", MOUSE_BUTTON_WHEEL_UP)
		_bind("inventory", [KEY_E, KEY_I], [JOY_BUTTON_BACK])
		_bind("drop_item", [KEY_Q], [])
		return
	_done = true
	_bind("move_left", [KEY_A, KEY_LEFT], [], [Vector2(JOY_AXIS_LEFT_X, -1.0)])
	_bind("move_right", [KEY_D, KEY_RIGHT], [], [Vector2(JOY_AXIS_LEFT_X, 1.0)])
	_bind("move_up", [KEY_W, KEY_UP], [], [Vector2(JOY_AXIS_LEFT_Y, -1.0)])
	_bind("move_down", [KEY_S, KEY_DOWN], [], [Vector2(JOY_AXIS_LEFT_Y, 1.0)])
	_bind("aim_left", [], [], [Vector2(JOY_AXIS_RIGHT_X, -1.0)])
	_bind("aim_right", [], [], [Vector2(JOY_AXIS_RIGHT_X, 1.0)])
	_bind("aim_up", [], [], [Vector2(JOY_AXIS_RIGHT_Y, -1.0)])
	_bind("aim_down", [], [], [Vector2(JOY_AXIS_RIGHT_Y, 1.0)])
	_bind("jump", [KEY_SPACE], [JOY_BUTTON_A])
	_bind("shoot", [KEY_CTRL], [], [Vector2(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_bind("aim_zoom", [KEY_SHIFT], [], [Vector2(JOY_AXIS_TRIGGER_LEFT, 1.0)])
	_bind("reload", [KEY_R], [JOY_BUTTON_X])
	_bind("melee", [KEY_V], [JOY_BUTTON_B])
	_bind("build_mode", [KEY_TAB, KEY_C], [JOY_BUTTON_Y])
	_bind("weap_next", [], [JOY_BUTTON_RIGHT_SHOULDER])
	_bind("weap_prev", [], [JOY_BUTTON_LEFT_SHOULDER])
	_bind("inventory", [KEY_E, KEY_I], [JOY_BUTTON_BACK])
	_bind("drop_item", [KEY_Q], [])
	_bind("pause", [KEY_ESCAPE], [JOY_BUTTON_START])
	_bind("attack", [KEY_J, KEY_Z], [JOY_BUTTON_X])
	_bind("signature", [KEY_K], [JOY_BUTTON_Y])
	_bind("mobility", [KEY_L], [JOY_BUTTON_B])
	_bind("gadget", [], [])
	_bind("lockon", [], [])
	_bind("interact", [KEY_F], [JOY_BUTTON_A])
	_bind("ui_confirm", [KEY_ENTER], [JOY_BUTTON_A])
	_bind("ui_back", [KEY_ESCAPE, KEY_BACKSPACE], [JOY_BUTTON_B])
	_add_ui(KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT)
	_mouse("shoot", MOUSE_BUTTON_LEFT)
	_mouse("aim_zoom", MOUSE_BUTTON_RIGHT)
	_strip_key("weap_next", KEY_E)
	_strip_key("weap_prev", KEY_Q)
	_strip_mouse("weap_next", MOUSE_BUTTON_WHEEL_DOWN)
	_strip_mouse("weap_prev", MOUSE_BUTTON_WHEEL_UP)


static func _mouse(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.3)
	var e := InputEventMouseButton.new()
	e.button_index = button
	InputMap.action_add_event(action, e)


static func _bind(action: String, keys: Array, buttons: Array, axes: Array = []) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.28)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	for b in buttons:
		var j := InputEventJoypadButton.new()
		j.button_index = b
		InputMap.action_add_event(action, j)
	for a in axes:
		var m := InputEventJoypadMotion.new()
		m.axis = int(a.x)
		m.axis_value = a.y
		InputMap.action_add_event(action, m)


static func _add_ui(up: int, down: int, left: int, right: int) -> void:
	_ensure_ui("ui_up", up, JOY_BUTTON_DPAD_UP)
	_ensure_ui("ui_down", down, JOY_BUTTON_DPAD_DOWN)
	_ensure_ui("ui_left", left, JOY_BUTTON_DPAD_LEFT)
	_ensure_ui("ui_right", right, JOY_BUTTON_DPAD_RIGHT)
	_ensure_ui("ui_accept", KEY_ENTER, JOY_BUTTON_A)
	_ensure_ui("ui_cancel", KEY_ESCAPE, JOY_BUTTON_B)


static func _strip_key(action: String, key: int) -> void:
	if not InputMap.has_action(action):
		return
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and (e as InputEventKey).physical_keycode == key:
			InputMap.action_erase_event(action, e)


static func _strip_mouse(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		return
	for e in InputMap.action_get_events(action):
		if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == button:
			InputMap.action_erase_event(action, e)


static func _ensure_ui(action: String, key: int, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var e := InputEventKey.new()
	e.physical_keycode = key
	InputMap.action_add_event(action, e)
	var j := InputEventJoypadButton.new()
	j.button_index = button
	InputMap.action_add_event(action, j)
	if action == "ui_left":
		var m := InputEventJoypadMotion.new()
		m.axis = JOY_AXIS_LEFT_X
		m.axis_value = -1.0
		InputMap.action_add_event(action, m)
	elif action == "ui_right":
		var m2 := InputEventJoypadMotion.new()
		m2.axis = JOY_AXIS_LEFT_X
		m2.axis_value = 1.0
		InputMap.action_add_event(action, m2)
	elif action == "ui_up":
		var m3 := InputEventJoypadMotion.new()
		m3.axis = JOY_AXIS_LEFT_Y
		m3.axis_value = -1.0
		InputMap.action_add_event(action, m3)
	elif action == "ui_down":
		var m4 := InputEventJoypadMotion.new()
		m4.axis = JOY_AXIS_LEFT_Y
		m4.axis_value = 1.0
		InputMap.action_add_event(action, m4)
