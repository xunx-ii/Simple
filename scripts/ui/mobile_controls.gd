class_name MobileControls
extends Control

const MobileInputSettingsScript = preload("res://scripts/systems/mobile_input_settings.gd")

signal move_vector_changed(move_vector: Vector2)
signal shoot_requested(screen_position: Vector2)
signal aim_mode_toggled(is_enabled: bool)

var controls_enabled: bool = true
var current_layout_settings: Dictionary = {}

@onready var left_joystick: Control = $LeftJoystick
@onready var aim_button: Button = $AimButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_joystick.move_vector_changed.connect(_on_left_joystick_move_vector_changed)
	aim_button.toggle_mode = true
	aim_button.toggled.connect(_on_aim_button_toggled)

	var viewport := get_viewport()
	if viewport != null:
		viewport.size_changed.connect(_apply_saved_layout)

	resized.connect(_apply_saved_layout)
	_apply_saved_layout()
	_update_aim_button_text()


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled:
		return

	if event is InputEventScreenTouch and event.pressed:
		if _is_touch_over_controls(event.position):
			return

		shoot_requested.emit(event.position)
		get_viewport().set_input_as_handled()


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	visible = enabled
	aim_button.disabled = not enabled

	if left_joystick != null and left_joystick.has_method("set_controls_enabled"):
		left_joystick.set_controls_enabled(enabled)

	if not enabled and aim_button.button_pressed:
		aim_button.set_pressed_no_signal(false)
		aim_mode_toggled.emit(false)

	_update_aim_button_text()


func apply_saved_layout() -> void:
	_apply_saved_layout()


func _on_left_joystick_move_vector_changed(move_vector: Vector2) -> void:
	move_vector_changed.emit(move_vector)


func _on_aim_button_toggled(is_enabled: bool) -> void:
	_update_aim_button_text()
	aim_mode_toggled.emit(is_enabled)


func _update_aim_button_text() -> void:
	aim_button.text = ""
	aim_button.tooltip_text = "\u89e3\u9664\u7784\u51c6" if aim_button.button_pressed else "\u8fdb\u5165\u7784\u51c6"


func _is_touch_over_controls(screen_position: Vector2) -> bool:
	return (
		left_joystick.get_global_rect().has_point(screen_position)
		or aim_button.get_global_rect().has_point(screen_position)
	)


func _apply_saved_layout() -> void:
	current_layout_settings = MobileInputSettingsScript.load_settings()
	MobileInputSettingsScript.apply_to_controls(self, left_joystick, aim_button, current_layout_settings)
