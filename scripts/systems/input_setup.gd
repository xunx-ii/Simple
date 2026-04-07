extends RefCounted

static func ensure_default_actions() -> void:
    _ensure_key_action("move_left", [KEY_A, KEY_LEFT])
    _ensure_key_action("move_right", [KEY_D, KEY_RIGHT])
    _ensure_key_action("move_up", [KEY_W, KEY_UP])
    _ensure_key_action("move_down", [KEY_S, KEY_DOWN])
    _ensure_key_action("shoot", [KEY_SPACE])
    _ensure_key_action("dash", [KEY_SHIFT, KEY_X])
    _ensure_key_action("restart", [KEY_R, KEY_ENTER, KEY_KP_ENTER])
    _ensure_mouse_button_action("shoot", MOUSE_BUTTON_LEFT)

static func _ensure_key_action(action_name: StringName, keycodes: Array) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)

    for keycode in keycodes:
        var event := InputEventKey.new()
        event.physical_keycode = keycode

        if not InputMap.action_has_event(action_name, event):
            InputMap.action_add_event(action_name, event)

static func _ensure_mouse_button_action(action_name: StringName, button_index: MouseButton) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)

    var event := InputEventMouseButton.new()
    event.button_index = button_index

    if not InputMap.action_has_event(action_name, event):
        InputMap.action_add_event(action_name, event)
