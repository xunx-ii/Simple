class_name VirtualJoystick
extends Control

signal move_vector_changed(move_vector: Vector2)

const BASE_RADIUS := 54.0
const KNOB_RADIUS := 24.0
const DEADZONE_RATIO := 0.16
const BASE_COLOR := Color(0.06, 0.08, 0.11, 0.58)
const KNOB_COLOR := Color(0.36, 0.87, 1.0, 0.88)
const RING_COLOR := Color(0.62, 0.82, 0.95, 0.26)

var touch_index: int = -1
var is_mouse_dragging: bool = false
var knob_offset: Vector2 = Vector2.ZERO
var controls_enabled: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
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


func reset_input() -> void:
	touch_index = -1
	is_mouse_dragging = false
	knob_offset = Vector2.ZERO
	move_vector_changed.emit(Vector2.ZERO)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, BASE_RADIUS, BASE_COLOR)
	draw_arc(center, BASE_RADIUS, 0.0, TAU, 48, RING_COLOR, 3.0, true)
	draw_circle(center + knob_offset, KNOB_RADIUS, KNOB_COLOR)


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
	knob_offset = raw_offset.limit_length(BASE_RADIUS)

	var normalized := Vector2.ZERO if BASE_RADIUS <= 0.0 else knob_offset / BASE_RADIUS
	if normalized.length() < DEADZONE_RATIO:
		normalized = Vector2.ZERO

	move_vector_changed.emit(normalized)
	queue_redraw()


func _get_local_input_position(event_position: Vector2) -> Vector2:
	if event_position.x >= 0.0 and event_position.y >= 0.0 and event_position.x <= size.x and event_position.y <= size.y:
		return event_position

	return event_position - get_global_rect().position
