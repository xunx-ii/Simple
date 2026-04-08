class_name LevelSelectionDialog
extends Control

signal challenge_requested(level_id: String)

const LevelProgressStateScript = preload("res://scripts/systems/levels/level_progress_state.gd")
const UIThemeHelperScript = preload("res://scripts/ui/ui_theme_helper.gd")
const UITextsScript = preload("res://scripts/ui/ui_texts.gd")
const UIFont = preload("res://assets/fonts/vonwaon.ttf")

const MARKER_SIZE := 24.0
const MARKER_CONTAINER_SIZE := Vector2(84.0, 54.0)
const DETAIL_POPUP_SIZE := Vector2(248.0, 176.0)
const LINE_COLOR := Color(0.321569, 0.419608, 0.505882, 0.82)
const COMPLETED_COLOR := Color(0.345098, 0.933333, 0.584314, 1.0)
const AVAILABLE_COLOR := Color(0.96, 0.98, 1.0, 1.0)
const BOSS_COLOR := Color(1.0, 0.34902, 0.34902, 1.0)
const LOCKED_COLOR := Color(0.4, 0.454902, 0.52549, 0.92)
const SELECTED_RING_COLOR := Color(0.447059, 0.827451, 1.0, 0.98)

var level_snapshots: Array = []
var selected_level_id := ""
var level_widgets: Dictionary = {}
var connector_lines: Array = []

var backdrop: ColorRect
var dialog_panel: PanelContainer
var tree_root: Control
var detail_popup: PanelContainer
var detail_title_label: Label
var detail_status_label: Label
var detail_description_scroll: ScrollContainer
var detail_description_label: Label
var detail_challenge_button: Button
var detail_close_button: Button


func _ready() -> void:
	anchors_preset = PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_build_ui()


func open_dialog() -> void:
	visible = true
	_refresh_level_data()
	_update_dialog_geometry()


func close_dialog() -> void:
	_clear_selected_level()
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
	backdrop.color = Color(0.0117647, 0.0156863, 0.027451, 0.84)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
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
	title_label.text = UITextsScript.LEVEL_SELECTION_TITLE
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(title_label, 20)
	title_row.add_child(title_label)

	var close_button := Button.new()
	close_button.text = UITextsScript.CLOSE
	close_button.custom_minimum_size = Vector2(76.0, 34.0)
	close_button.pressed.connect(close_dialog)
	_apply_font(close_button, 13)
	title_row.add_child(close_button)

	var tree_frame := PanelContainer.new()
	tree_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree_frame.add_theme_stylebox_override(
		"panel",
		UIThemeHelperScript.build_panel_style(Color(0.043, 0.054, 0.074, 1.0), 14, Color(0.23, 0.34, 0.42, 1.0))
	)
	root_layout.add_child(tree_frame)

	var tree_margin := MarginContainer.new()
	UIThemeHelperScript.set_margin(tree_margin, 14, 14, 14, 14)
	tree_frame.add_child(tree_margin)

	tree_root = Control.new()
	tree_root.clip_contents = true
	tree_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree_margin.add_child(tree_root)
	tree_root.resized.connect(_update_tree_layout)

	_build_level_nodes()
	_build_detail_popup()


func _build_level_nodes() -> void:
	level_snapshots = LevelProgressStateScript.get_level_snapshots()

	for snapshot_variant in level_snapshots:
		var snapshot: Dictionary = snapshot_variant
		var level_id := str(snapshot.get("id", ""))

		var container := Control.new()
		container.custom_minimum_size = MARKER_CONTAINER_SIZE
		container.size = MARKER_CONTAINER_SIZE
		tree_root.add_child(container)

		var button := Button.new()
		button.flat = false
		button.focus_mode = Control.FOCUS_NONE
		button.text = ""
		button.custom_minimum_size = Vector2.ONE * MARKER_SIZE
		button.size = Vector2.ONE * MARKER_SIZE
		button.position = Vector2((MARKER_CONTAINER_SIZE.x - MARKER_SIZE) * 0.5, 0.0)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_level_marker_pressed.bind(level_id))
		container.add_child(button)

		var label := Label.new()
		label.size = Vector2(MARKER_CONTAINER_SIZE.x, 20.0)
		label.position = Vector2(0.0, 28.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_apply_font(label, 12)
		container.add_child(label)

		level_widgets[level_id] = {
			"container": container,
			"button": button,
			"label": label
		}

	for snapshot_variant in level_snapshots:
		var snapshot: Dictionary = snapshot_variant
		var level_id := str(snapshot.get("id", ""))
		for prerequisite_id in snapshot.get("prerequisite_ids", PackedStringArray()):
			var line := Line2D.new()
			line.width = 2.0
			line.default_color = LINE_COLOR
			line.antialiased = true
			tree_root.add_child(line)
			tree_root.move_child(line, 0)
			connector_lines.append(
				{
					"from": str(prerequisite_id),
					"to": level_id,
					"line": line
				}
			)


func _build_detail_popup() -> void:
	detail_popup = PanelContainer.new()
	detail_popup.visible = false
	detail_popup.custom_minimum_size = DETAIL_POPUP_SIZE
	detail_popup.add_theme_stylebox_override(
		"panel",
		UIThemeHelperScript.build_panel_style(
			Color(0.066, 0.08, 0.11, 0.98),
			14,
			Color(0.396078, 0.501961, 0.592157, 0.98)
		)
	)
	tree_root.add_child(detail_popup)

	var detail_margin := MarginContainer.new()
	UIThemeHelperScript.set_margin(detail_margin, 12, 12, 12, 12)
	detail_popup.add_child(detail_margin)

	var detail_layout := VBoxContainer.new()
	detail_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_layout.add_theme_constant_override("separation", 8)
	detail_margin.add_child(detail_layout)

	var detail_header := HBoxContainer.new()
	detail_header.add_theme_constant_override("separation", 8)
	detail_layout.add_child(detail_header)

	detail_title_label = Label.new()
	detail_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(detail_title_label, 16)
	detail_header.add_child(detail_title_label)

	detail_close_button = Button.new()
	detail_close_button.text = UITextsScript.CLOSE
	detail_close_button.custom_minimum_size = Vector2(64.0, 28.0)
	detail_close_button.pressed.connect(_on_detail_close_button_pressed)
	_apply_font(detail_close_button, 12)
	detail_header.add_child(detail_close_button)

	detail_status_label = Label.new()
	_apply_font(detail_status_label, 12)
	detail_layout.add_child(detail_status_label)

	detail_description_scroll = ScrollContainer.new()
	detail_description_scroll.custom_minimum_size = Vector2(0.0, 56.0)
	detail_description_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_description_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_description_scroll.resized.connect(_update_detail_description_width)
	detail_layout.add_child(detail_description_scroll)

	detail_description_label = Label.new()
	detail_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_description_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_apply_font(detail_description_label, 12)
	detail_description_scroll.add_child(detail_description_label)

	detail_challenge_button = Button.new()
	detail_challenge_button.custom_minimum_size = Vector2(0.0, 38.0)
	detail_challenge_button.text = UITextsScript.LEVEL_CHALLENGE_BUTTON
	detail_challenge_button.pressed.connect(_on_challenge_button_pressed)
	_apply_font(detail_challenge_button, 14)
	detail_layout.add_child(detail_challenge_button)


func _refresh_level_data() -> void:
	level_snapshots = LevelProgressStateScript.get_level_snapshots()
	selected_level_id = ""

	_refresh_level_widgets()
	_update_tree_layout()
	_update_detail_popup()


func _refresh_level_widgets() -> void:
	for snapshot_variant in level_snapshots:
		var snapshot: Dictionary = snapshot_variant
		var level_id := str(snapshot.get("id", ""))
		var widget: Dictionary = level_widgets.get(level_id, {})
		if widget.is_empty():
			continue

		var label: Label = widget.get("label")
		var button: Button = widget.get("button")
		if label == null or button == null:
			continue

		label.text = str(snapshot.get("short_title", ""))
		label.modulate = Color(0.84, 0.9, 0.96, 0.96) if bool(snapshot.get("unlocked", false)) else Color(0.58, 0.64, 0.72, 0.9)
		_apply_marker_style(button, snapshot, level_id == selected_level_id)


func _apply_marker_style(button: Button, snapshot: Dictionary, is_selected: bool) -> void:
	var base_color := _get_marker_color(snapshot)
	var border_color := SELECTED_RING_COLOR if is_selected else base_color.darkened(0.18)
	var border_width := 3 if is_selected else 2

	for state_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = base_color
		style.border_color = border_color
		style.border_width_left = border_width
		style.border_width_top = border_width
		style.border_width_right = border_width
		style.border_width_bottom = border_width
		style.corner_radius_top_left = 32
		style.corner_radius_top_right = 32
		style.corner_radius_bottom_right = 32
		style.corner_radius_bottom_left = 32
		button.add_theme_stylebox_override(state_name, style)


func _get_marker_color(snapshot: Dictionary) -> Color:
	if bool(snapshot.get("completed", false)):
		return COMPLETED_COLOR
	if bool(snapshot.get("boss", false)):
		return BOSS_COLOR
	if bool(snapshot.get("unlocked", false)):
		return AVAILABLE_COLOR
	return LOCKED_COLOR


func _update_tree_layout() -> void:
	if tree_root == null:
		return

	var tree_size := tree_root.size
	for snapshot_variant in level_snapshots:
		var snapshot: Dictionary = snapshot_variant
		var widget: Dictionary = level_widgets.get(str(snapshot.get("id", "")), {})
		var container: Control = widget.get("container")
		if container == null:
			continue

		var normalized_position: Vector2 = snapshot.get("position", Vector2.ZERO)
		var marker_position := Vector2(
			tree_size.x * normalized_position.x,
			tree_size.y * normalized_position.y
		)
		container.position = marker_position - Vector2(MARKER_CONTAINER_SIZE.x * 0.5, MARKER_SIZE * 0.5)
		container.size = MARKER_CONTAINER_SIZE

	for connector_variant in connector_lines:
		var connector: Dictionary = connector_variant
		var line: Line2D = connector.get("line")
		if line == null:
			continue

		var from_center := _get_marker_center(str(connector.get("from", "")))
		var to_center := _get_marker_center(str(connector.get("to", "")))
		var mid_x := lerpf(from_center.x, to_center.x, 0.5)
		line.points = PackedVector2Array(
			[
				from_center,
				Vector2(mid_x, from_center.y),
				Vector2(mid_x, to_center.y),
				to_center
			]
		)

	_update_detail_popup_position()


func _get_marker_center(level_id: String) -> Vector2:
	var widget: Dictionary = level_widgets.get(level_id, {})
	var container: Control = widget.get("container")
	if container == null:
		return Vector2.ZERO

	return container.position + Vector2(MARKER_CONTAINER_SIZE.x * 0.5, MARKER_SIZE * 0.5)


func _on_level_marker_pressed(level_id: String) -> void:
	LevelProgressStateScript.select_level(level_id)
	selected_level_id = level_id
	_refresh_level_widgets()
	_update_detail_popup()


func _update_detail_popup() -> void:
	var snapshot := _get_snapshot_by_id(selected_level_id)
	if snapshot.is_empty():
		detail_popup.visible = false
		return

	detail_popup.visible = true
	detail_title_label.text = str(snapshot.get("title", ""))
	detail_description_label.text = str(snapshot.get("description", ""))

	if bool(snapshot.get("completed", false)):
		detail_status_label.text = UITextsScript.LEVEL_STATUS_COMPLETED
		detail_status_label.modulate = COMPLETED_COLOR
	elif bool(snapshot.get("unlocked", false)):
		if bool(snapshot.get("boss", false)):
			detail_status_label.text = UITextsScript.LEVEL_STATUS_BOSS
			detail_status_label.modulate = BOSS_COLOR
		else:
			detail_status_label.text = UITextsScript.LEVEL_STATUS_AVAILABLE
			detail_status_label.modulate = AVAILABLE_COLOR
	else:
		detail_status_label.text = UITextsScript.LEVEL_STATUS_LOCKED
		detail_status_label.modulate = LOCKED_COLOR.lightened(0.35)

	detail_challenge_button.disabled = not bool(snapshot.get("unlocked", false))
	detail_challenge_button.visible = true
	detail_popup.size = DETAIL_POPUP_SIZE
	_update_detail_description_width()
	_update_detail_popup_position()
	call_deferred("_update_detail_description_width")
	call_deferred("_update_detail_popup_position")


func _update_detail_popup_position() -> void:
	if detail_popup == null or not detail_popup.visible:
		return

	var anchor_point := _get_marker_center(selected_level_id) + Vector2(22.0, -8.0)
	var popup_position := anchor_point
	var max_x := maxf(tree_root.size.x - DETAIL_POPUP_SIZE.x, 0.0)
	var max_y := maxf(tree_root.size.y - DETAIL_POPUP_SIZE.y, 0.0)

	if popup_position.x + DETAIL_POPUP_SIZE.x > tree_root.size.x:
		popup_position.x = _get_marker_center(selected_level_id).x - DETAIL_POPUP_SIZE.x - 22.0

	popup_position.x = clampf(popup_position.x, 0.0, max_x)
	popup_position.y = clampf(popup_position.y, 0.0, max_y)

	detail_popup.position = popup_position
	detail_popup.size = DETAIL_POPUP_SIZE


func _update_detail_description_width() -> void:
	if detail_description_scroll == null or detail_description_label == null:
		return

	var available_width := maxf(detail_description_scroll.size.x, DETAIL_POPUP_SIZE.x - 24.0)
	detail_description_label.custom_minimum_size.x = available_width
	detail_description_label.size.x = available_width


func _get_snapshot_by_id(level_id: String) -> Dictionary:
	for snapshot_variant in level_snapshots:
		var snapshot: Dictionary = snapshot_variant
		if str(snapshot.get("id", "")) == level_id:
			return snapshot
	return {}


func _on_challenge_button_pressed() -> void:
	var snapshot := _get_snapshot_by_id(selected_level_id)
	if snapshot.is_empty():
		return
	if not bool(snapshot.get("unlocked", false)):
		return

	challenge_requested.emit(selected_level_id)


func _on_detail_close_button_pressed() -> void:
	_clear_selected_level()
	_refresh_level_widgets()


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		close_dialog()
		accept_event()


func _update_dialog_geometry() -> void:
	if dialog_panel == null:
		return

	var viewport_size := get_viewport_rect().size
	var width := minf(viewport_size.x - 24.0, 860.0)
	var height := minf(viewport_size.y - 24.0, 404.0)
	dialog_panel.offset_left = -width * 0.5
	dialog_panel.offset_top = -height * 0.5
	dialog_panel.offset_right = width * 0.5
	dialog_panel.offset_bottom = height * 0.5
	_update_tree_layout()


func _clear_selected_level() -> void:
	selected_level_id = ""
	if detail_popup != null:
		detail_popup.visible = false


func _apply_font(control: Control, font_size: int) -> void:
	UIThemeHelperScript.apply_font(control, UIFont, font_size)
