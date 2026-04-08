class_name VirtualJoystick
extends Control

const MobileControlStyleScript = preload("res://scripts/ui/mobile_control_style.gd")

signal move_vector_changed(move_vector: Vector2)

const DEADZONE_RATIO := 0.16

var touch_index: int = -1
var is_mouse_dragging: bool = false
var knob_offset: Vector2 = Vector2.ZERO
var controls_enabled: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not controls_enabled:
		return

	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
		return

	if event is InputEventScreenDrag:
		_handle_screen_drag(event)
		return

	if event is InputEventMouseButton:
		_handle_mouse_button(event)
		return

	if event is InputEventMouseMotion:
		_handle_mouse_motion(event)


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not enabled:
		reset_input()
		return

	queue_redraw()


func reset_input() -> void:
	touch_index = -1
	is_mouse_dragging = false
	knob_offset = Vector2.ZERO
	move_vector_changed.emit(Vector2.ZERO)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var base_radius := _get_base_radius()
	MobileControlStyleScript.draw_shell(
		self,
		center,
		base_radius,
		touch_index >= 0 or is_mouse_dragging,
		not controls_enabled
	)
	MobileControlStyleScript.draw_knob(self, center + knob_offset, _get_knob_radius(base_radius))


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		touch_index = event.index
		_update_knob_from_screen_position(event.position)
		accept_event()
		return

	if event.index != touch_index:
		return

	reset_input()
	accept_event()


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index != touch_index:
		return

	_update_knob_from_screen_position(event.position)
	accept_event()


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		is_mouse_dragging = true
		_update_knob_from_screen_position(event.position)
		accept_event()
		return

	if not is_mouse_dragging:
		return

	reset_input()
	accept_event()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not is_mouse_dragging:
		return

	_update_knob_from_screen_position(event.position)
	accept_event()


func _update_knob_from_screen_position(screen_position: Vector2) -> void:
	var center := size * 0.5
	var local_position := _get_local_input_position(screen_position)
	var raw_offset := local_position - center
	var base_radius := _get_base_radius()
	knob_offset = raw_offset.limit_length(base_radius)

	var normalized := Vector2.ZERO if base_radius <= 0.0 else knob_offset / base_radius
	if normalized.length() < DEADZONE_RATIO:
		normalized = Vector2.ZERO

	move_vector_changed.emit(normalized)
	queue_redraw()


func _get_local_input_position(event_position: Vector2) -> Vector2:
	if event_position.x >= 0.0 and event_position.y >= 0.0 and event_position.x <= size.x and event_position.y <= size.y:
		return event_position

	return event_position - get_global_rect().position


func _get_base_radius() -> float:
	return maxf(minf(size.x, size.y) * 0.32, 18.0)


func _get_knob_radius(base_radius: float) -> float:
	return maxf(base_radius * 0.44, 10.0)
