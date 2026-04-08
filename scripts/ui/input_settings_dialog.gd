class_name InputSettingsDialog
extends Control

const MobileInputSettingsScript = preload("res://scripts/systems/mobile_input_settings.gd")
const VirtualJoystickScript = preload("res://scripts/ui/virtual_joystick.gd")
const CircularActionButtonScript = preload("res://scripts/ui/circular_action_button.gd")
const UIThemeHelperScript = preload("res://scripts/ui/ui_theme_helper.gd")
const UITextsScript = preload("res://scripts/ui/ui_texts.gd")
const UIFont = preload("res://assets/fonts/vonwaon.ttf")

const SECTION_JOYSTICK := "joystick"
const SECTION_AIM_BUTTON := "aim_button"
const ROW_PRIMARY_MARGIN := "primary_margin"
const ROW_BOTTOM_MARGIN := "margin_bottom"
const ROW_SIZE := "size"

var current_settings: Dictionary = {}
var is_syncing_controls: bool = false
var selected_section := SECTION_JOYSTICK
var slider_labels: Dictionary = {}
var slider_controls: Dictionary = {}
var value_labels: Dictionary = {}
var preview_selectors: Dictionary = {}
var preview_selection_frames: Dictionary = {}

var backdrop: ColorRect
var dialog_panel: PanelContainer
var preview_root: Control
var preview_joystick: Control
var preview_aim_button: Button
var controls_title_label: Label


func _ready() -> void:
	anchors_preset = PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_build_ui()
	current_settings = MobileInputSettingsScript.load_settings()
	_sync_controls_from_settings()
	resized.connect(_update_dialog_geometry)


func open_dialog() -> void:
	current_settings = MobileInputSettingsScript.load_settings()
	_sync_controls_from_settings()
	visible = true
	_update_dialog_geometry()


func close_dialog() -> void:
	visible = false


func is_dialog_open() -> bool:
	return visible


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		close_dialog()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	backdrop = ColorRect.new()
	backdrop.anchors_preset = PRESET_FULL_RECT
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.color = Color(0.0117647, 0.0156863, 0.027451, 0.84)
	backdrop.gui_input.connect(_on_backdrop_gui_input)
	add_child(backdrop)

	dialog_panel = PanelContainer.new()
	dialog_panel.anchor_left = 0.5
	dialog_panel.anchor_top = 0.5
	dialog_panel.anchor_right = 0.5
	dialog_panel.anchor_bottom = 0.5
	dialog_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog_panel.add_theme_stylebox_override(
		"panel",
		UIThemeHelperScript.build_panel_style(
			Color(0.0588235, 0.0705882, 0.0941176, 0.98),
			18,
			Color(0.396078, 0.501961, 0.592157, 1.0)
		)
	)
	add_child(dialog_panel)

	var margin := MarginContainer.new()
	UIThemeHelperScript.set_margin(margin, 14, 14, 14, 14)
	dialog_panel.add_child(margin)

	var root_layout := VBoxContainer.new()
	root_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_layout.add_theme_constant_override("separation", 10)
	margin.add_child(root_layout)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	root_layout.add_child(title_row)

	var title_label := Label.new()
	title_label.text = UITextsScript.INPUT_SETTINGS
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_dialog_font(title_label, 20)
	title_row.add_child(title_label)

	var close_button := Button.new()
	close_button.text = UITextsScript.CLOSE
	close_button.custom_minimum_size = Vector2(76.0, 34.0)
	close_button.pressed.connect(close_dialog)
	_apply_dialog_font(close_button, 13)
	title_row.add_child(close_button)

	var content_row := HBoxContainer.new()
	content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 14)
	root_layout.add_child(content_row)

	var preview_column := VBoxContainer.new()
	preview_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_column.add_theme_constant_override("separation", 8)
	content_row.add_child(preview_column)

	var preview_title := Label.new()
	preview_title.text = UITextsScript.INPUT_SETTINGS_PREVIEW_TITLE
	_apply_dialog_font(preview_title, 15)
	preview_column.add_child(preview_title)

	var preview_frame := PanelContainer.new()
	preview_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_frame.add_theme_stylebox_override(
		"panel",
		UIThemeHelperScript.build_panel_style(Color(0.043, 0.054, 0.074, 1.0), 14, Color(0.23, 0.34, 0.42, 1.0))
	)
	preview_column.add_child(preview_frame)

	var preview_margin := MarginContainer.new()
	preview_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UIThemeHelperScript.set_margin(preview_margin, 8, 8, 8, 8)
	preview_frame.add_child(preview_margin)

	var aspect := AspectRatioContainer.new()
	aspect.ratio = MobileInputSettingsScript.REFERENCE_VIEWPORT_SIZE.x / MobileInputSettingsScript.REFERENCE_VIEWPORT_SIZE.y
	aspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aspect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_margin.add_child(aspect)

	preview_root = Control.new()
	preview_root.clip_contents = true
	preview_root.custom_minimum_size = Vector2(340.0, 157.0)
	preview_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	aspect.add_child(preview_root)
	preview_root.resized.connect(_update_preview_layout)

	_build_preview_scene(preview_root)

	var controls_panel := PanelContainer.new()
	controls_panel.custom_minimum_size = Vector2(244.0, 0.0)
	controls_panel.size_flags_horizontal = Control.SIZE_FILL
	controls_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls_panel.add_theme_stylebox_override(
		"panel",
		UIThemeHelperScript.build_panel_style(Color(0.066, 0.08, 0.11, 0.98), 14, Color(0.24, 0.34, 0.42, 0.92))
	)
	content_row.add_child(controls_panel)

	var controls_margin := MarginContainer.new()
	UIThemeHelperScript.set_margin(controls_margin, 12, 12, 12, 12)
	controls_panel.add_child(controls_margin)

	var controls_layout := VBoxContainer.new()
	controls_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls_layout.add_theme_constant_override("separation", 10)
	controls_margin.add_child(controls_layout)

	controls_title_label = _build_section_title("")
	controls_layout.add_child(controls_title_label)
	controls_layout.add_child(_create_slider_row(ROW_PRIMARY_MARGIN))
	controls_layout.add_child(_create_slider_row(ROW_BOTTOM_MARGIN))
	controls_layout.add_child(_create_slider_row(ROW_SIZE))

	var controls_spacer := Control.new()
	controls_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls_layout.add_child(controls_spacer)

	var footer_row := HBoxContainer.new()
	footer_row.add_theme_constant_override("separation", 8)
	root_layout.add_child(footer_row)

	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_row.add_child(footer_spacer)

	var reset_button := Button.new()
	reset_button.text = UITextsScript.RESET_DEFAULT
	reset_button.custom_minimum_size = Vector2(96.0, 34.0)
	reset_button.pressed.connect(_on_reset_button_pressed)
	_apply_dialog_font(reset_button, 13)
	footer_row.add_child(reset_button)

	var done_button := Button.new()
	done_button.text = UITextsScript.DONE
	done_button.custom_minimum_size = Vector2(84.0, 34.0)
	done_button.pressed.connect(close_dialog)
	_apply_dialog_font(done_button, 13)
	footer_row.add_child(done_button)

	_update_dialog_geometry()


func _build_preview_scene(root: Control) -> void:
	var background := ColorRect.new()
	background.anchors_preset = PRESET_FULL_RECT
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.color = Color(0.05, 0.06, 0.08, 1.0)
	root.add_child(background)

	for district_index in range(4):
		var district := ColorRect.new()
		district.anchor_left = 0.25 * district_index
		district.anchor_top = 0.0
		district.anchor_right = 0.25 * (district_index + 1)
		district.anchor_bottom = 1.0
		district.color = [
			Color(0.09, 0.11, 0.14, 0.76),
			Color(0.11, 0.10, 0.14, 0.76),
			Color(0.09, 0.12, 0.11, 0.76),
			Color(0.12, 0.10, 0.10, 0.76)
		][district_index]
		root.add_child(district)

	var vertical_strip := ColorRect.new()
	vertical_strip.anchor_left = 0.47
	vertical_strip.anchor_top = 0.0
	vertical_strip.anchor_right = 0.53
	vertical_strip.anchor_bottom = 1.0
	vertical_strip.color = Color(0.15, 0.17, 0.20, 0.48)
	root.add_child(vertical_strip)

	var horizontal_strip := ColorRect.new()
	horizontal_strip.anchor_left = 0.0
	horizontal_strip.anchor_top = 0.465
	horizontal_strip.anchor_right = 1.0
	horizontal_strip.anchor_bottom = 0.535
	horizontal_strip.color = Color(0.15, 0.17, 0.20, 0.44)
	root.add_child(horizontal_strip)

	var player_marker := PanelContainer.new()
	player_marker.anchor_left = 0.5
	player_marker.anchor_top = 0.5
	player_marker.anchor_right = 0.5
	player_marker.anchor_bottom = 0.5
	player_marker.offset_left = -10.0
	player_marker.offset_top = -10.0
	player_marker.offset_right = 10.0
	player_marker.offset_bottom = 10.0
	player_marker.add_theme_stylebox_override(
		"panel",
		UIThemeHelperScript.build_panel_style(
			Color(0.36, 0.87, 1.0, 1.0),
			10,
			Color(0.82, 0.97, 1.0, 0.92)
		)
	)
	root.add_child(player_marker)

	_build_preview_crosshair(root)

	preview_joystick = VirtualJoystickScript.new()
	root.add_child(preview_joystick)
	preview_joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if preview_joystick.has_method("set_controls_enabled"):
		preview_joystick.set_controls_enabled(false)
	if preview_joystick.has_method("reset_input"):
		preview_joystick.reset_input()

	preview_aim_button = CircularActionButtonScript.new()
	root.add_child(preview_aim_button)
	preview_aim_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_aim_button.disabled = false

	_create_preview_selector(SECTION_JOYSTICK)
	_create_preview_selector(SECTION_AIM_BUTTON)
	_create_preview_selection_frame(SECTION_JOYSTICK)
	_create_preview_selection_frame(SECTION_AIM_BUTTON)


func _build_preview_crosshair(root: Control) -> void:
	var crosshair_root := Control.new()
	crosshair_root.anchor_left = 0.5
	crosshair_root.anchor_top = 0.5
	crosshair_root.anchor_right = 0.5
	crosshair_root.anchor_bottom = 0.5
	crosshair_root.offset_left = 84.0
	crosshair_root.offset_top = -26.0
	crosshair_root.offset_right = 108.0
	crosshair_root.offset_bottom = -2.0
	crosshair_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(crosshair_root)

	_add_crosshair_segment(crosshair_root, Vector2(10.0, 11.0), Vector2(7.0, 2.0))
	_add_crosshair_segment(crosshair_root, Vector2(28.0, 11.0), Vector2(7.0, 2.0))
	_add_crosshair_segment(crosshair_root, Vector2(21.0, 0.0), Vector2(2.0, 7.0))
	_add_crosshair_segment(crosshair_root, Vector2(21.0, 18.0), Vector2(2.0, 7.0))

	var center_dot := PanelContainer.new()
	center_dot.offset_left = 18.0
	center_dot.offset_top = 8.0
	center_dot.offset_right = 26.0
	center_dot.offset_bottom = 16.0
	center_dot.add_theme_stylebox_override(
		"panel",
		UIThemeHelperScript.build_panel_style(
			Color(0.86, 0.97, 1.0, 0.94),
			4,
			Color(0.86, 0.97, 1.0, 0.94)
		)
	)
	crosshair_root.add_child(center_dot)


func _add_crosshair_segment(parent: Control, offset: Vector2, segment_size: Vector2) -> void:
	var segment := ColorRect.new()
	segment.offset_left = offset.x
	segment.offset_top = offset.y
	segment.offset_right = offset.x + segment_size.x
	segment.offset_bottom = offset.y + segment_size.y
	segment.color = Color(0.86, 0.97, 1.0, 0.94)
	parent.add_child(segment)


func _create_preview_selector(section_name: String) -> void:
	var selector := Control.new()
	selector.mouse_filter = Control.MOUSE_FILTER_STOP
	selector.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	selector.gui_input.connect(_on_preview_selector_gui_input.bind(section_name))
	preview_root.add_child(selector)
	preview_selectors[section_name] = selector


func _create_preview_selection_frame(section_name: String) -> void:
	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _build_selection_frame_style())
	preview_root.add_child(frame)
	preview_selection_frames[section_name] = frame


func _build_selection_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.454902, 0.827451, 1.0, 0.96)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	return style


func _create_slider_row(row_id: String) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var label := Label.new()
	_apply_dialog_font(label, 12)
	row.add_child(label)

	var controls_row := HBoxContainer.new()
	controls_row.add_theme_constant_override("separation", 8)
	row.add_child(controls_row)

	var slider := HSlider.new()
	slider.step = 1.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_slider_value_changed.bind(row_id))
	controls_row.add_child(slider)

	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(48.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_apply_dialog_font(value_label, 11)
	controls_row.add_child(value_label)

	slider_labels[row_id] = label
	slider_controls[row_id] = slider
	value_labels[row_id] = value_label
	return row


func _build_section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.modulate = Color(0.89, 0.96, 1.0, 1.0)
	_apply_dialog_font(label, 15)
	return label


func _get_section_config(section_name: String) -> Dictionary:
	if section_name == SECTION_AIM_BUTTON:
		return {
			"title": UITextsScript.INPUT_SETTINGS_AIM_BUTTON_SECTION,
			"fields": [
				{
					"row_id": ROW_PRIMARY_MARGIN,
					"key": "margin_right",
					"label": UITextsScript.INPUT_SETTINGS_RIGHT_MARGIN,
					"min": 8.0,
					"max": 280.0,
					"step": 1.0
				},
				{
					"row_id": ROW_BOTTOM_MARGIN,
					"key": "margin_bottom",
					"label": UITextsScript.INPUT_SETTINGS_BOTTOM_MARGIN,
					"min": 8.0,
					"max": 180.0,
					"step": 1.0
				},
				{
					"row_id": ROW_SIZE,
					"key": "size",
					"label": UITextsScript.INPUT_SETTINGS_SIZE,
					"min": MobileInputSettingsScript.MIN_AIM_BUTTON_SIZE,
					"max": MobileInputSettingsScript.MAX_AIM_BUTTON_SIZE,
					"step": 1.0
				}
			]
		}

	return {
		"title": UITextsScript.INPUT_SETTINGS_JOYSTICK_SECTION,
		"fields": [
			{
				"row_id": ROW_PRIMARY_MARGIN,
				"key": "margin_left",
				"label": UITextsScript.INPUT_SETTINGS_LEFT_MARGIN,
				"min": 8.0,
				"max": 280.0,
				"step": 1.0
			},
			{
				"row_id": ROW_BOTTOM_MARGIN,
				"key": "margin_bottom",
				"label": UITextsScript.INPUT_SETTINGS_BOTTOM_MARGIN,
				"min": 8.0,
				"max": 180.0,
				"step": 1.0
			},
			{
				"row_id": ROW_SIZE,
				"key": "size",
				"label": UITextsScript.INPUT_SETTINGS_SIZE,
				"min": MobileInputSettingsScript.MIN_JOYSTICK_SIZE,
				"max": MobileInputSettingsScript.MAX_JOYSTICK_SIZE,
				"step": 1.0
			}
		]
	}


func _get_field_config(section_name: String, row_id: String) -> Dictionary:
	var config: Dictionary = _get_section_config(section_name)
	for field_variant in config.get("fields", []):
		var field: Dictionary = field_variant
		if str(field.get("row_id", "")) == row_id:
			return field
	return {}


func _on_slider_value_changed(value: float, row_id: String) -> void:
	if is_syncing_controls:
		return

	var field_config := _get_field_config(selected_section, row_id)
	if field_config.is_empty():
		return

	current_settings[selected_section][field_config["key"]] = value
	current_settings = MobileInputSettingsScript.sanitize_settings(current_settings)
	MobileInputSettingsScript.save_settings(current_settings)
	_sync_controls_from_settings()


func _on_reset_button_pressed() -> void:
	current_settings = MobileInputSettingsScript.get_default_settings()
	MobileInputSettingsScript.save_settings(current_settings)
	_sync_controls_from_settings()


func _on_preview_selector_gui_input(event: InputEvent, section_name: String) -> void:
	var is_mouse_press: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var is_touch_press: bool = event is InputEventScreenTouch and event.pressed
	if not is_mouse_press and not is_touch_press:
		return

	_select_section(section_name)
	accept_event()


func _select_section(section_name: String) -> void:
	if section_name not in [SECTION_JOYSTICK, SECTION_AIM_BUTTON]:
		return

	selected_section = section_name
	_refresh_selected_section_controls()
	_update_preview_selection_frames()


func _refresh_selected_section_controls() -> void:
	if controls_title_label == null:
		return

	is_syncing_controls = true
	var config: Dictionary = _get_section_config(selected_section)
	controls_title_label.text = str(config.get("title", ""))

	for field_variant in config.get("fields", []):
		var field: Dictionary = field_variant
		var row_id := str(field.get("row_id", ""))
		var label: Label = slider_labels.get(row_id)
		var slider: HSlider = slider_controls.get(row_id)
		var value_label: Label = value_labels.get(row_id)
		if label == null or slider == null or value_label == null:
			continue

		label.text = str(field.get("label", ""))
		slider.min_value = float(field.get("min", 0.0))
		slider.max_value = float(field.get("max", 0.0))
		slider.step = float(field.get("step", 1.0))

		var section: Dictionary = current_settings.get(selected_section, {})
		var value := float(section.get(str(field.get("key", "")), slider.value))
		slider.value = value
		value_label.text = str(int(round(value)))

	is_syncing_controls = false


func _sync_controls_from_settings() -> void:
	current_settings = MobileInputSettingsScript.sanitize_settings(current_settings)
	_refresh_selected_section_controls()
	_update_preview_layout()


func _update_preview_layout() -> void:
	if preview_root == null or preview_joystick == null or preview_aim_button == null:
		return

	MobileInputSettingsScript.apply_to_controls(preview_root, preview_joystick, preview_aim_button, current_settings)
	_match_overlay_to_control(preview_selectors.get(SECTION_JOYSTICK), preview_joystick)
	_match_overlay_to_control(preview_selectors.get(SECTION_AIM_BUTTON), preview_aim_button)
	_update_preview_selection_frames()
	preview_root.queue_redraw()


func _match_overlay_to_control(overlay: Control, source: Control, padding: float = 0.0) -> void:
	if overlay == null or source == null:
		return

	overlay.anchor_left = source.anchor_left
	overlay.anchor_top = source.anchor_top
	overlay.anchor_right = source.anchor_right
	overlay.anchor_bottom = source.anchor_bottom
	overlay.offset_left = source.offset_left - padding
	overlay.offset_top = source.offset_top - padding
	overlay.offset_right = source.offset_right + padding
	overlay.offset_bottom = source.offset_bottom + padding


func _update_preview_selection_frames() -> void:
	var joystick_frame: Control = preview_selection_frames.get(SECTION_JOYSTICK)
	var aim_button_frame: Control = preview_selection_frames.get(SECTION_AIM_BUTTON)

	if joystick_frame != null:
		_match_overlay_to_control(joystick_frame, preview_joystick, 6.0)
		joystick_frame.visible = selected_section == SECTION_JOYSTICK

	if aim_button_frame != null:
		_match_overlay_to_control(aim_button_frame, preview_aim_button, 6.0)
		aim_button_frame.visible = selected_section == SECTION_AIM_BUTTON


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		close_dialog()
		accept_event()


func _update_dialog_geometry() -> void:
	if dialog_panel == null:
		return

	var viewport_size := get_viewport_rect().size
	var width := minf(viewport_size.x - 24.0, 860.0)
	var height := minf(viewport_size.y - 24.0, 390.0)
	dialog_panel.offset_left = -width * 0.5
	dialog_panel.offset_top = -height * 0.5
	dialog_panel.offset_right = width * 0.5
	dialog_panel.offset_bottom = height * 0.5
	_update_preview_layout()


func _apply_dialog_font(control: Control, font_size: int) -> void:
	UIThemeHelperScript.apply_font(control, UIFont, font_size)
