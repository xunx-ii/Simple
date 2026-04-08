class_name CircularActionButton
extends Button

var is_hovered: bool = false


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	text = ""
	clip_text = false
	toggled.connect(_on_button_visual_state_changed)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var radius := maxf(minf(size.x, size.y) * 0.5 - 4.0, 12.0)
	var center := size * 0.5
	var is_active := button_pressed or is_hovered

	MobileControlStyle.draw_shell(self, center, radius, is_active, disabled)
	MobileControlStyle.draw_crosshair_icon(self, center, radius * 0.9, button_pressed, disabled)

	if button_pressed:
		draw_arc(
			center,
			radius * 0.72,
			-PI * 0.22,
			PI * 0.22,
			24,
			Color(0.9, 1.0, 0.94, 0.96),
			maxf(radius * 0.08, 2.0),
			true
		)


func _on_button_visual_state_changed(_is_pressed: bool) -> void:
	queue_redraw()


func _on_mouse_entered() -> void:
	is_hovered = true
	queue_redraw()


func _on_mouse_exited() -> void:
	is_hovered = false
	queue_redraw()
