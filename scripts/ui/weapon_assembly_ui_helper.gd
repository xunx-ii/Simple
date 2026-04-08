class_name WeaponAssemblyUIHelper
extends RefCounted

const UIThemeHelperScript = preload("res://scripts/ui/ui_theme_helper.gd")


static func clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


static func create_slot_button(
	slot_size: Vector2,
	ui_font: Font,
	font_size: int,
	pressed_callable: Callable
) -> Button:
	var button := Button.new()
	button.custom_minimum_size = slot_size
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.clip_text = false
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if pressed_callable.is_valid():
		button.pressed.connect(pressed_callable)
	UIThemeHelperScript.apply_font(button, ui_font, font_size)
	return button


static func apply_slot_button_style(
	button: Button,
	active: bool,
	active_border_color: Color,
	inactive_border_color: Color
) -> void:
	var border_color := active_border_color if active else inactive_border_color
	var fill_color := Color(0.09, 0.1, 0.13, 0.98) if active else Color(0.06, 0.07, 0.1, 0.94)
	var style := UIThemeHelperScript.build_panel_style(fill_color, 7, border_color)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.modulate = Color(1.0, 0.98, 0.98, 1.0) if active else Color(0.94, 0.94, 0.94, 1.0)


static func create_stat_label(text: String, ui_font: Font, font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.modulate = Color(0.88, 0.93, 0.99, 0.78)
	label.custom_minimum_size = Vector2(150.0, 0.0)
	label.text = text
	UIThemeHelperScript.apply_font(label, ui_font, font_size)
	return label


static func create_empty_label(text: String, ui_font: Font, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIThemeHelperScript.apply_font(label, ui_font, font_size)
	return label


static func create_attachment_entry(
	entry: Dictionary,
	ui_font: Font,
	pressed_callable: Callable
) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override(
		"panel",
		UIThemeHelperScript.build_panel_style(Color(0.094, 0.11, 0.145, 0.96), 10, Color(0.22, 0.31, 0.39, 1.0))
	)

	var margin := MarginContainer.new()
	UIThemeHelperScript.set_margin(margin, 8, 8, 8, 8)
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 3)
	row.add_child(text_column)

	var name_label := Label.new()
	name_label.text = str(entry.get("display_name", "配件"))
	UIThemeHelperScript.apply_font(name_label, ui_font, 13)
	text_column.add_child(name_label)

	var meta_text := str(entry.get("meta_text", ""))
	if not meta_text.is_empty():
		var meta_label := Label.new()
		meta_label.text = meta_text
		meta_label.modulate = Color(0.73, 0.84, 0.94, 0.92)
		UIThemeHelperScript.apply_font(meta_label, ui_font, 10)
		text_column.add_child(meta_label)

	var description_text := str(entry.get("description", ""))
	if not description_text.is_empty():
		var description_label := Label.new()
		description_label.text = description_text
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.max_lines_visible = 2
		UIThemeHelperScript.apply_font(description_label, ui_font, 10)
		text_column.add_child(description_label)

	var action_button := Button.new()
	action_button.text = str(entry.get("action_text", "装配"))
	action_button.custom_minimum_size = Vector2(82.0, 38.0)
	action_button.disabled = not bool(entry.get("action_enabled", false))
	action_button.focus_mode = Control.FOCUS_NONE
	if pressed_callable.is_valid():
		action_button.pressed.connect(pressed_callable.bind(str(entry.get("id", ""))))
	UIThemeHelperScript.apply_font(action_button, ui_font, 12)
	row.add_child(action_button)

	return card
