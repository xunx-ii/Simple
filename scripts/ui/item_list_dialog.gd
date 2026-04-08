class_name ItemListDialog
extends Control

signal item_action_requested(dialog_id: String, item_id: String)

const UIThemeHelperScript = preload("res://scripts/ui/ui_theme_helper.gd")
const UIFont = preload("res://assets/fonts/vonwaon.ttf")

const DEFAULT_EMPTY_TEXT := "暂无内容"

var current_dialog_id := ""
var current_state: Dictionary = {}

var backdrop: ColorRect
var dialog_panel: PanelContainer
var title_label: Label
var summary_label: Label
var status_label: Label
var items_container: VBoxContainer


func _ready() -> void:
	anchors_preset = PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_build_ui()
	resized.connect(_update_dialog_geometry)


func open_dialog(state: Dictionary) -> void:
	visible = true
	set_dialog_state(state)


func set_dialog_state(state: Dictionary) -> void:
	current_state = state.duplicate(true)
	current_dialog_id = str(current_state.get("dialog_id", ""))
	_apply_state()
	if visible:
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

	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_font(title_label, 20)
	title_row.add_child(title_label)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(76.0, 34.0)
	close_button.pressed.connect(close_dialog)
	_apply_font(close_button, 13)
	title_row.add_child(close_button)

	summary_label = Label.new()
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.modulate = Color(0.86, 0.93, 1.0, 0.96)
	_apply_font(summary_label, 13)
	root_layout.add_child(summary_label)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.modulate = Color(0.56, 0.88, 1.0, 0.98)
	_apply_font(status_label, 12)
	root_layout.add_child(status_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_layout.add_child(scroll)

	items_container = VBoxContainer.new()
	items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	items_container.add_theme_constant_override("separation", 10)
	scroll.add_child(items_container)


func _apply_state() -> void:
	if title_label == null:
		return

	title_label.text = str(current_state.get("title", ""))
	summary_label.text = str(current_state.get("summary_text", ""))
	summary_label.visible = not summary_label.text.is_empty()
	status_label.text = str(current_state.get("status_text", ""))
	status_label.visible = not status_label.text.is_empty()

	var empty_text := str(current_state.get("empty_text", DEFAULT_EMPTY_TEXT))
	_rebuild_items(current_state.get("items", []), empty_text)


func _rebuild_items(items_variant: Variant, empty_text: String) -> void:
	for child in items_container.get_children():
		items_container.remove_child(child)
		child.queue_free()

	if not (items_variant is Array):
		var empty_label := Label.new()
		empty_label.text = empty_text
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_font(empty_label, 13)
		items_container.add_child(empty_label)
		return

	var items: Array = items_variant
	if items.is_empty():
		var empty_label := Label.new()
		empty_label.text = empty_text
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_font(empty_label, 13)
		items_container.add_child(empty_label)
		return

	for item_variant in items:
		if not (item_variant is Dictionary):
			continue

		items_container.add_child(_build_item_card(item_variant))


func _build_item_card(item: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override(
		"panel",
		UIThemeHelperScript.build_panel_style(Color(0.094, 0.11, 0.145, 0.96), 12)
	)

	var margin := MarginContainer.new()
	UIThemeHelperScript.set_margin(margin, 12, 12, 12, 12)
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 4)
	row.add_child(details)

	var name_label := Label.new()
	name_label.text = str(item.get("display_name", "物资"))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(name_label, 15)
	details.add_child(name_label)

	var meta_text := str(item.get("meta_text", ""))
	if not meta_text.is_empty():
		var meta_label := Label.new()
		meta_label.text = meta_text
		meta_label.modulate = Color(0.73, 0.84, 0.94, 0.92)
		_apply_font(meta_label, 12)
		details.add_child(meta_label)

	var description_text := str(item.get("description", ""))
	if not description_text.is_empty():
		var description_label := Label.new()
		description_label.text = description_text
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_apply_font(description_label, 12)
		details.add_child(description_label)

	var action_text := str(item.get("action_text", ""))
	if action_text.is_empty():
		return card

	var action_button := Button.new()
	action_button.text = action_text
	action_button.custom_minimum_size = Vector2(98.0, 38.0)
	action_button.disabled = not bool(item.get("action_enabled", false))
	action_button.process_mode = Node.PROCESS_MODE_ALWAYS
	action_button.pressed.connect(_on_action_button_pressed.bind(str(item.get("id", ""))))
	_apply_font(action_button, 13)
	row.add_child(action_button)

	return card


func _on_action_button_pressed(item_id: String) -> void:
	if item_id.is_empty():
		return

	item_action_requested.emit(current_dialog_id, item_id)


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		close_dialog()
		accept_event()


func _update_dialog_geometry() -> void:
	if dialog_panel == null:
		return

	var viewport_size := get_viewport_rect().size
	var width := minf(viewport_size.x - 24.0, 720.0)
	var height := minf(viewport_size.y - 24.0, 400.0)
	dialog_panel.offset_left = -width * 0.5
	dialog_panel.offset_top = -height * 0.5
	dialog_panel.offset_right = width * 0.5
	dialog_panel.offset_bottom = height * 0.5


func _apply_font(control: Control, font_size: int) -> void:
	UIThemeHelperScript.apply_font(control, UIFont, font_size)
