class_name WeaponAssemblyPanel
extends PanelContainer

signal assembly_changed(status_text: String)

const MetaProgressionStateScript = preload("res://scripts/systems/meta_progression_state.gd")
const UIThemeHelperScript = preload("res://scripts/ui/ui_theme_helper.gd")
const UITextsScript = preload("res://scripts/ui/ui_texts.gd")
const UIFont = preload("res://assets/fonts/vonwaon.ttf")

const SLOT_BUTTON_SIZE := Vector2(118.0, 42.0)
const LINE_COLOR := Color(0.8, 0.22, 0.22, 0.9)
const FRAME_BORDER_COLOR := Color(0.88, 0.28, 0.28, 0.94)

var selected_slot_id := ""
var overlay_open := false
var slot_buttons: Dictionary = {}
var current_snapshot: Dictionary = {}

var header_label: Label
var header_meta_label: Label
var schematic_root: Control
var weapon_frame: PanelContainer
var weapon_name_label: Label
var weapon_description_label: Label
var stat_overlay: VBoxContainer
var stat_items: VBoxContainer
var attachment_overlay: PanelContainer
var attachment_title_label: Label
var attachment_scroll: ScrollContainer
var attachment_items: VBoxContainer


func _ready() -> void:
	anchors_preset = PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override(
		"panel",
		UIThemeHelperScript.build_panel_style(
			Color(0.0588235, 0.0705882, 0.0941176, 0.98),
			18,
			Color(0.396078, 0.501961, 0.592157, 1.0)
		)
	)
	_build_ui()
	_refresh_panel()
	resized.connect(_on_layout_changed)


func refresh_panel() -> void:
	_refresh_panel()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UIThemeHelperScript.set_margin(margin, 8, 8, 8, 8)
	add_child(margin)

	var root_layout := VBoxContainer.new()
	root_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_layout.add_theme_constant_override("separation", 8)
	margin.add_child(root_layout)

	var header_row := HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_theme_constant_override("separation", 12)
	root_layout.add_child(header_row)

	header_label = Label.new()
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_label.text = UITextsScript.WEAPON_ASSEMBLY_TITLE
	_apply_font(header_label, 16)
	header_row.add_child(header_label)

	header_meta_label = Label.new()
	header_meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_meta_label.modulate = Color(0.84, 0.9, 0.96, 0.9)
	_apply_font(header_meta_label, 11)
	header_row.add_child(header_meta_label)

	schematic_root = Control.new()
	schematic_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	schematic_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_layout.add_child(schematic_root)
	schematic_root.resized.connect(_on_layout_changed)

	weapon_frame = PanelContainer.new()
	weapon_frame.add_theme_stylebox_override(
		"panel",
		UIThemeHelperScript.build_panel_style(Color(0.035, 0.043, 0.062, 0.98), 10, FRAME_BORDER_COLOR)
	)
	schematic_root.add_child(weapon_frame)

	var weapon_margin := MarginContainer.new()
	UIThemeHelperScript.set_margin(weapon_margin, 18, 18, 18, 18)
	weapon_frame.add_child(weapon_margin)

	var weapon_layout := VBoxContainer.new()
	weapon_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	weapon_layout.alignment = BoxContainer.ALIGNMENT_CENTER
	weapon_layout.add_theme_constant_override("separation", 10)
	weapon_margin.add_child(weapon_layout)

	weapon_name_label = Label.new()
	weapon_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(weapon_name_label, 20)
	weapon_layout.add_child(weapon_name_label)

	weapon_description_label = Label.new()
	weapon_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	weapon_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	weapon_description_label.max_lines_visible = 3
	_apply_font(weapon_description_label, 11)
	weapon_layout.add_child(weapon_description_label)

	stat_overlay = VBoxContainer.new()
	stat_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stat_overlay.add_theme_constant_override("separation", 3)
	schematic_root.add_child(stat_overlay)
	stat_items = stat_overlay

	attachment_overlay = PanelContainer.new()
	attachment_overlay.visible = false
	attachment_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	attachment_overlay.add_theme_stylebox_override(
		"panel",
		UIThemeHelperScript.build_panel_style(Color(0.05, 0.06, 0.085, 0.98), 14, Color(0.25, 0.37, 0.47, 1.0))
	)
	schematic_root.add_child(attachment_overlay)

	var attachment_margin := MarginContainer.new()
	UIThemeHelperScript.set_margin(attachment_margin, 12, 12, 12, 12)
	attachment_overlay.add_child(attachment_margin)

	var attachment_layout := VBoxContainer.new()
	attachment_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attachment_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	attachment_layout.add_theme_constant_override("separation", 8)
	attachment_margin.add_child(attachment_layout)

	attachment_title_label = Label.new()
	attachment_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attachment_title_label.modulate = Color(0.88, 0.92, 0.98, 0.96)
	_apply_font(attachment_title_label, 12)
	attachment_layout.add_child(attachment_title_label)

	attachment_scroll = ScrollContainer.new()
	attachment_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attachment_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	attachment_layout.add_child(attachment_scroll)

	attachment_items = VBoxContainer.new()
	attachment_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attachment_items.add_theme_constant_override("separation", 6)
	attachment_scroll.add_child(attachment_items)

	for slot_id in ["optic", "muzzle", "magazine", "stock"]:
		var button := Button.new()
		button.custom_minimum_size = SLOT_BUTTON_SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.flat = true
		button.clip_text = false
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_slot_button_pressed.bind(slot_id))
		_apply_font(button, 13)
		schematic_root.add_child(button)
		slot_buttons[slot_id] = button


func _refresh_panel() -> void:
	current_snapshot = MetaProgressionStateScript.get_weapon_assembly_snapshot()
	var slots: Array = current_snapshot.get("slots", [])
	if slots.is_empty():
		return

	if selected_slot_id.is_empty() or not _slot_exists(selected_slot_id, slots):
		selected_slot_id = str(slots[0].get("id", ""))

	weapon_name_label.text = str(current_snapshot.get("weapon_name", "Weapon"))
	weapon_description_label.text = str(current_snapshot.get("weapon_description", ""))
	_update_header_meta()
	_refresh_slot_buttons(slots)
	_refresh_stats()
	_refresh_attachment_overlay()
	_update_schematic_layout()
	queue_redraw()


func _update_header_meta() -> void:
	var attachment_total := int(current_snapshot.get("warehouse_attachment_total", 0))
	if not overlay_open:
		header_meta_label.text = "x%d" % attachment_total
		return

	var slot_definition := _get_selected_slot_definition()
	var slot_name := str(slot_definition.get("display_name", ""))
	header_meta_label.text = "%s  x%d" % [slot_name, attachment_total] if not slot_name.is_empty() else "x%d" % attachment_total


func _refresh_slot_buttons(slots: Array) -> void:
	for slot_variant in slots:
		if not (slot_variant is Dictionary):
			continue

		var slot: Dictionary = slot_variant
		var slot_id := str(slot.get("id", ""))
		var button: Button = slot_buttons.get(slot_id)
		if button == null:
			continue

		button.text = "%s\n%s" % [
			str(slot.get("display_name", "Slot")),
			str(slot.get("equipped_name", "点击装配"))
		]
		button.tooltip_text = str(slot.get("description", ""))

		var active := overlay_open and slot_id == selected_slot_id
		var border_color := FRAME_BORDER_COLOR if active else Color(0.6, 0.2, 0.2, 0.72)
		var fill_color := Color(0.09, 0.1, 0.13, 0.98) if active else Color(0.06, 0.07, 0.1, 0.94)
		var style := UIThemeHelperScript.build_panel_style(fill_color, 7, border_color)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		button.modulate = Color(1.0, 0.98, 0.98, 1.0) if active else Color(0.94, 0.94, 0.94, 1.0)


func _refresh_stats() -> void:
	for child in stat_items.get_children():
		stat_items.remove_child(child)
		child.queue_free()

	for stat_variant in current_snapshot.get("stats", []):
		if not (stat_variant is Dictionary):
			continue

		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.modulate = Color(0.88, 0.93, 0.99, 0.78)
		label.text = _format_stat_text(stat_variant)
		label.custom_minimum_size = Vector2(150.0, 0.0)
		_apply_font(label, 10)
		stat_items.add_child(label)

	stat_overlay.visible = stat_items.get_child_count() > 0


func _format_stat_text(stat_variant: Dictionary) -> String:
	var stat: Dictionary = stat_variant
	var stat_name := str(stat.get("label", "属性"))
	var base_value := int(stat.get("base", 0))
	var modifier := int(stat.get("modifier", 0))
	var current_value := int(stat.get("current", base_value + modifier))
	return "%s: %d(%s) %d" % [stat_name, base_value, _signed_number(modifier), current_value]


func _signed_number(value: int) -> String:
	return "+%d" % value if value >= 0 else str(value)


func _refresh_attachment_overlay() -> void:
	attachment_overlay.visible = overlay_open
	if not overlay_open:
		return

	for child in attachment_items.get_children():
		attachment_items.remove_child(child)
		child.queue_free()

	var slot_definition := _get_selected_slot_definition()
	attachment_title_label.text = "%s / %s" % [
		UITextsScript.WEAPON_ATTACHMENT_LIST_TITLE,
		str(slot_definition.get("display_name", "Slot"))
	]

	var entries := MetaProgressionStateScript.get_weapon_attachment_entries(selected_slot_id)
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = UITextsScript.WEAPON_ATTACHMENT_EMPTY
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_apply_font(empty_label, 11)
		attachment_items.add_child(empty_label)
		return

	for entry_variant in entries:
		if not (entry_variant is Dictionary):
			continue

		attachment_items.add_child(_build_attachment_entry(entry_variant))


func _build_attachment_entry(entry: Dictionary) -> Control:
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
	_apply_font(name_label, 13)
	text_column.add_child(name_label)

	var meta_text := str(entry.get("meta_text", ""))
	if not meta_text.is_empty():
		var meta_label := Label.new()
		meta_label.text = meta_text
		meta_label.modulate = Color(0.73, 0.84, 0.94, 0.92)
		_apply_font(meta_label, 10)
		text_column.add_child(meta_label)

	var description_text := str(entry.get("description", ""))
	if not description_text.is_empty():
		var description_label := Label.new()
		description_label.text = description_text
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.max_lines_visible = 2
		_apply_font(description_label, 10)
		text_column.add_child(description_label)

	var action_button := Button.new()
	action_button.text = str(entry.get("action_text", "装配"))
	action_button.custom_minimum_size = Vector2(82.0, 38.0)
	action_button.disabled = not bool(entry.get("action_enabled", false))
	action_button.focus_mode = Control.FOCUS_NONE
	action_button.pressed.connect(_on_attachment_action_pressed.bind(str(entry.get("id", ""))))
	_apply_font(action_button, 12)
	row.add_child(action_button)

	return card


func _on_slot_button_pressed(slot_id: String) -> void:
	if overlay_open and selected_slot_id == slot_id:
		overlay_open = false
	else:
		selected_slot_id = slot_id
		overlay_open = true

	_update_header_meta()
	_refresh_slot_buttons(current_snapshot.get("slots", []))
	_refresh_attachment_overlay()
	_update_schematic_layout()
	queue_redraw()


func _on_attachment_action_pressed(attachment_id: String) -> void:
	var result := MetaProgressionStateScript.equip_weapon_attachment(selected_slot_id, attachment_id)
	if not bool(result.get("success", false)):
		assembly_changed.emit(UITextsScript.WEAPON_ATTACHMENT_EQUIP_FAILED)
		return

	var slot_name := str(_get_selected_slot_definition().get("display_name", "配件"))
	var attachment_name := str(result.get("display_name", ""))
	var status_text := UITextsScript.weapon_attachment_changed_text(slot_name, attachment_name)
	if str(result.get("reason", "")) == "UNEQUIPPED":
		status_text = UITextsScript.weapon_attachment_removed_text(slot_name, attachment_name)

	overlay_open = false
	_refresh_panel()
	assembly_changed.emit(status_text)


func _get_selected_slot_definition() -> Dictionary:
	for slot_variant in current_snapshot.get("slots", []):
		if not (slot_variant is Dictionary):
			continue

		var slot: Dictionary = slot_variant
		if str(slot.get("id", "")) == selected_slot_id:
			return slot

	return {}


func _slot_exists(slot_id: String, slots: Array) -> bool:
	for slot_variant in slots:
		if slot_variant is Dictionary and str(slot_variant.get("id", "")) == slot_id:
			return true

	return false


func _on_layout_changed() -> void:
	_update_schematic_layout()
	queue_redraw()


func _update_schematic_layout() -> void:
	if schematic_root == null or weapon_frame == null:
		return

	var root_size := schematic_root.size
	if root_size.x <= 0.0 or root_size.y <= 0.0:
		return

	var frame_margin_x := SLOT_BUTTON_SIZE.x * 0.78
	var frame_margin_y := SLOT_BUTTON_SIZE.y * 0.78
	var weapon_size := Vector2(
		clampf(root_size.x - frame_margin_x * 2.0, 320.0, root_size.x - 24.0),
		clampf(root_size.y - frame_margin_y * 2.0, 172.0, root_size.y - 18.0)
	)
	var frame_position := Vector2(
		(root_size.x - weapon_size.x) * 0.5,
		(root_size.y - weapon_size.y) * 0.5
	)
	weapon_frame.position = frame_position
	weapon_frame.size = weapon_size

	var weapon_rect := Rect2(weapon_frame.position, weapon_frame.size)
	_position_slot_button(
		"optic",
		Vector2(weapon_rect.get_center().x - SLOT_BUTTON_SIZE.x * 0.5, weapon_rect.position.y - SLOT_BUTTON_SIZE.y * 0.46),
		root_size
	)
	_position_slot_button(
		"muzzle",
		Vector2(weapon_rect.end.x - SLOT_BUTTON_SIZE.x * 0.18, weapon_rect.position.y + weapon_rect.size.y * 0.28),
		root_size
	)
	_position_slot_button(
		"magazine",
		Vector2(weapon_rect.position.x - SLOT_BUTTON_SIZE.x * 0.82, weapon_rect.position.y + weapon_rect.size.y * 0.58),
		root_size
	)
	_position_slot_button(
		"stock",
		Vector2(weapon_rect.get_center().x - SLOT_BUTTON_SIZE.x * 0.5, weapon_rect.end.y - SLOT_BUTTON_SIZE.y * 0.14),
		root_size
	)

	var stat_size := stat_overlay.get_combined_minimum_size()
	stat_overlay.position = Vector2(12.0, root_size.y - stat_size.y - 10.0)
	stat_overlay.size = stat_size

	var overlay_size := Vector2(
		clampf(root_size.x * 0.48, 320.0, root_size.x - 24.0),
		clampf(root_size.y * 0.52, 168.0, root_size.y - 20.0)
	)
	attachment_overlay.position = Vector2(root_size.x - overlay_size.x - 10.0, root_size.y - overlay_size.y - 10.0)
	attachment_overlay.size = overlay_size


func _draw() -> void:
	if weapon_frame == null:
		return

	var panel_origin := get_global_rect().position
	var weapon_center := weapon_frame.get_global_rect().get_center() - panel_origin
	for slot_id in slot_buttons.keys():
		var button: Button = slot_buttons.get(slot_id)
		if button == null:
			continue

		var button_center := button.get_global_rect().get_center() - panel_origin
		draw_line(weapon_center, button_center, LINE_COLOR, 1.4, true)
		draw_circle(button_center, 3.0, LINE_COLOR)


func _apply_font(control: Control, font_size: int) -> void:
	UIThemeHelperScript.apply_font(control, UIFont, font_size)


func _position_slot_button(slot_id: String, target_position: Vector2, root_size: Vector2) -> void:
	var button: Button = slot_buttons.get(slot_id)
	if button == null:
		return

	button.size = SLOT_BUTTON_SIZE
	button.position = Vector2(
		clampf(target_position.x, 0.0, maxf(root_size.x - SLOT_BUTTON_SIZE.x, 0.0)),
		clampf(target_position.y, 0.0, maxf(root_size.y - SLOT_BUTTON_SIZE.y, 0.0))
	)
