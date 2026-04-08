class_name WeaponAssemblyPanel
extends PanelContainer

signal assembly_changed(status_text: String)

const MetaProgressionStateScript = preload("res://scripts/systems/meta_progression_state.gd")
const UIThemeHelperScript = preload("res://scripts/ui/ui_theme_helper.gd")
const UITextsScript = preload("res://scripts/ui/ui_texts.gd")
const UIFont = preload("res://assets/fonts/vonwaon.ttf")

const SLOT_BUTTON_SIZE := Vector2(108.0, 40.0)
const LINE_COLOR := Color(0.8, 0.22, 0.22, 0.92)
const FRAME_BORDER_COLOR := Color(0.88, 0.28, 0.28, 0.94)

var selected_slot_id := "optic"
var slot_buttons: Dictionary = {}
var current_snapshot: Dictionary = {}

var header_label: Label
var header_meta_label: Label
var subtitle_label: Label
var status_label: Label
var content_row: HBoxContainer
var schematic_root: Control
var detail_column: VBoxContainer
var weapon_frame: PanelContainer
var weapon_name_label: Label
var weapon_description_label: Label
var stat_scroll: ScrollContainer
var stat_items: VBoxContainer
var attachment_title_button: Button
var attachment_hint_label: Label
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
	header_meta_label.custom_minimum_size = Vector2(160.0, 0.0)
	header_meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_meta_label.modulate = Color(0.84, 0.9, 0.96, 0.9)
	_apply_font(header_meta_label, 11)
	header_row.add_child(header_meta_label)

	# Keep legacy labels detached so old logic can write into them without
	# bringing the removed prompt area back into the visible layout.
	subtitle_label = Label.new()
	status_label = Label.new()
	status_label.visible = false
	var legacy_state_holder := Control.new()
	legacy_state_holder.visible = false
	add_child(legacy_state_holder)
	legacy_state_holder.add_child(subtitle_label)
	legacy_state_holder.add_child(status_label)

	content_row = HBoxContainer.new()
	content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", 10)
	root_layout.add_child(content_row)

	schematic_root = Control.new()
	schematic_root.custom_minimum_size = Vector2(0.0, 176.0)
	schematic_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	schematic_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	schematic_root.size_flags_stretch_ratio = 1.0
	content_row.add_child(schematic_root)
	schematic_root.resized.connect(_on_layout_changed)

	weapon_frame = PanelContainer.new()
	weapon_frame.size = Vector2(0.0, 0.0)
	weapon_frame.add_theme_stylebox_override(
		"panel",
		UIThemeHelperScript.build_panel_style(Color(0.035, 0.043, 0.062, 1.0), 8, FRAME_BORDER_COLOR)
	)
	schematic_root.add_child(weapon_frame)

	var weapon_margin := MarginContainer.new()
	UIThemeHelperScript.set_margin(weapon_margin, 14, 14, 14, 14)
	weapon_frame.add_child(weapon_margin)

	var weapon_layout := VBoxContainer.new()
	weapon_layout.add_theme_constant_override("separation", 8)
	weapon_margin.add_child(weapon_layout)

	weapon_name_label = Label.new()
	weapon_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_apply_font(weapon_name_label, 16)
	weapon_layout.add_child(weapon_name_label)

	weapon_description_label = Label.new()
	weapon_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	weapon_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	weapon_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_font(weapon_description_label, 10)
	weapon_layout.add_child(weapon_description_label)

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

	detail_column = VBoxContainer.new()
	detail_column.custom_minimum_size = Vector2(332.0, 0.0)
	detail_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_column.size_flags_stretch_ratio = 1.18
	detail_column.add_theme_constant_override("separation", 8)
	content_row.add_child(detail_column)

	var stat_panel := PanelContainer.new()
	stat_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stat_panel.size_flags_stretch_ratio = 0.78
	stat_panel.add_theme_stylebox_override(
		"panel",
		UIThemeHelperScript.build_panel_style(Color(0.043, 0.054, 0.074, 1.0), 14, Color(0.23, 0.34, 0.42, 1.0))
	)
	detail_column.add_child(stat_panel)

	var stat_margin := MarginContainer.new()
	UIThemeHelperScript.set_margin(stat_margin, 10, 10, 10, 10)
	stat_panel.add_child(stat_margin)

	var stat_layout := VBoxContainer.new()
	stat_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stat_layout.add_theme_constant_override("separation", 8)
	stat_margin.add_child(stat_layout)

	var stat_title := Button.new()
	stat_title.text = UITextsScript.WEAPON_STATS_TITLE
	stat_title.disabled = true
	stat_title.focus_mode = Control.FOCUS_NONE
	stat_title.custom_minimum_size = Vector2(0.0, 28.0)
	_apply_font(stat_title, 12)
	stat_layout.add_child(stat_title)

	stat_scroll = ScrollContainer.new()
	stat_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stat_layout.add_child(stat_scroll)

	stat_items = VBoxContainer.new()
	stat_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_items.add_theme_constant_override("separation", 8)
	stat_scroll.add_child(stat_items)

	var attachment_panel := PanelContainer.new()
	attachment_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attachment_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	attachment_panel.size_flags_stretch_ratio = 1.22
	attachment_panel.add_theme_stylebox_override(
		"panel",
		UIThemeHelperScript.build_panel_style(Color(0.043, 0.054, 0.074, 1.0), 14, Color(0.23, 0.34, 0.42, 1.0))
	)
	detail_column.add_child(attachment_panel)

	var attachment_margin := MarginContainer.new()
	UIThemeHelperScript.set_margin(attachment_margin, 10, 10, 10, 10)
	attachment_panel.add_child(attachment_margin)

	var attachment_layout := VBoxContainer.new()
	attachment_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attachment_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	attachment_layout.add_theme_constant_override("separation", 8)
	attachment_margin.add_child(attachment_layout)

	attachment_title_button = Button.new()
	attachment_title_button.disabled = true
	attachment_title_button.focus_mode = Control.FOCUS_NONE
	attachment_title_button.custom_minimum_size = Vector2(0.0, 28.0)
	_apply_font(attachment_title_button, 12)
	attachment_layout.add_child(attachment_title_button)

	attachment_hint_label = Label.new()
	attachment_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	attachment_hint_label.max_lines_visible = 1
	attachment_hint_label.modulate = Color(0.83, 0.89, 0.96, 0.9)
	_apply_font(attachment_hint_label, 10)
	attachment_layout.add_child(attachment_hint_label)

	attachment_scroll = ScrollContainer.new()
	attachment_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attachment_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	attachment_layout.add_child(attachment_scroll)

	attachment_items = VBoxContainer.new()
	attachment_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attachment_items.add_theme_constant_override("separation", 6)
	attachment_scroll.add_child(attachment_items)


func _refresh_panel_legacy() -> void:
	current_snapshot = MetaProgressionStateScript.get_weapon_assembly_snapshot()
	var slots: Array = current_snapshot.get("slots", [])
	if slots.is_empty():
		return

	if not _slot_exists(selected_slot_id, slots):
		selected_slot_id = str(slots[0].get("id", ""))

	weapon_name_label.text = str(current_snapshot.get("weapon_name", "武器"))
	weapon_description_label.text = str(current_snapshot.get("weapon_description", ""))
	subtitle_label.text = "%s  当前仓库可用配件 %d 件" % [
		UITextsScript.WEAPON_ASSEMBLY_SUBTITLE,
		int(current_snapshot.get("warehouse_attachment_total", 0))
	]
	if status_label.text.is_empty():
		status_label.text = UITextsScript.WEAPON_ATTACHMENT_LIST_HINT

	_refresh_slot_buttons(slots)
	_refresh_stats()
	_refresh_attachment_list()
	_update_schematic_layout()
	queue_redraw()


func _refresh_panel() -> void:
	current_snapshot = MetaProgressionStateScript.get_weapon_assembly_snapshot()
	var slots: Array = current_snapshot.get("slots", [])
	if slots.is_empty():
		return

	if not _slot_exists(selected_slot_id, slots):
		selected_slot_id = str(slots[0].get("id", ""))

	weapon_name_label.text = str(current_snapshot.get("weapon_name", "Weapon"))
	weapon_description_label.text = str(current_snapshot.get("weapon_description", ""))
	subtitle_label.text = "%s (x%d)" % [
		UITextsScript.WEAPON_ASSEMBLY_SUBTITLE,
		int(current_snapshot.get("warehouse_attachment_total", 0))
	]
	var selected_slot := _get_selected_slot_definition()
	var selected_slot_name := str(selected_slot.get("display_name", ""))
	var attachment_total := int(current_snapshot.get("warehouse_attachment_total", 0))
	header_meta_label.text = "%s  x%d" % [selected_slot_name, attachment_total] if not selected_slot_name.is_empty() else "x%d" % attachment_total
	status_label.visible = not status_label.text.is_empty()

	_refresh_slot_buttons(slots)
	_refresh_stats()
	_refresh_attachment_list()
	_update_schematic_layout()
	queue_redraw()


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
			str(slot.get("display_name", "配件")),
			str(slot.get("equipped_name", "点击装配"))
		]
		button.tooltip_text = str(slot.get("description", ""))
		button.modulate = Color(1.0, 0.98, 0.98, 1.0) if slot_id == selected_slot_id else Color(0.94, 0.94, 0.94, 1.0)
		button.add_theme_stylebox_override(
			"normal",
			UIThemeHelperScript.build_panel_style(
				Color(0.08, 0.09, 0.12, 1.0),
				6,
				FRAME_BORDER_COLOR if slot_id == selected_slot_id else Color(0.62, 0.2, 0.2, 0.9)
			)
		)


func _refresh_stats() -> void:
	for child in stat_items.get_children():
		stat_items.remove_child(child)
		child.queue_free()

	for stat_variant in current_snapshot.get("stats", []):
		if not (stat_variant is Dictionary):
			continue

		var stat: Dictionary = stat_variant
		var row_button := Button.new()
		row_button.focus_mode = Control.FOCUS_NONE
		row_button.flat = false
		row_button.text = str(stat.get("display_text", ""))
		row_button.custom_minimum_size = Vector2(0.0, 30.0)
		row_button.tooltip_text = str(stat.get("label", ""))
		_apply_font(row_button, 11)
		stat_items.add_child(row_button)


func _refresh_attachment_list_legacy() -> void:
	for child in attachment_items.get_children():
		attachment_items.remove_child(child)
		child.queue_free()

	var slot_definition := _get_selected_slot_definition()
	attachment_title_button.text = "%s：%s" % [
		UITextsScript.WEAPON_ATTACHMENT_LIST_TITLE,
		str(slot_definition.get("display_name", "配件"))
	]
	attachment_hint_label.text = str(slot_definition.get("description", UITextsScript.WEAPON_ATTACHMENT_LIST_HINT))

	var entries := MetaProgressionStateScript.get_weapon_attachment_entries(selected_slot_id)
	if entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = UITextsScript.WEAPON_ATTACHMENT_EMPTY
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_apply_font(empty_label, 12)
		attachment_items.add_child(empty_label)
		return

	for entry_variant in entries:
		if not (entry_variant is Dictionary):
			continue

		attachment_items.add_child(_build_attachment_entry(entry_variant))


func _refresh_attachment_list() -> void:
	for child in attachment_items.get_children():
		attachment_items.remove_child(child)
		child.queue_free()

	var slot_definition := _get_selected_slot_definition()
	attachment_title_button.text = "%s / %s" % [
		UITextsScript.WEAPON_ATTACHMENT_LIST_TITLE,
		str(slot_definition.get("display_name", "Slot"))
	]
	attachment_hint_label.text = str(
		slot_definition.get("description", UITextsScript.WEAPON_ATTACHMENT_LIST_HINT)
	)

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
		UIThemeHelperScript.build_panel_style(Color(0.094, 0.11, 0.145, 0.96), 10)
	)

	var margin := MarginContainer.new()
	UIThemeHelperScript.set_margin(margin, 8, 8, 8, 8)
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
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

	var description_label := Label.new()
	description_label.text = str(entry.get("description", ""))
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_font(description_label, 10)
	text_column.add_child(description_label)

	var action_button := Button.new()
	action_button.text = str(entry.get("action_text", "装配"))
	action_button.custom_minimum_size = Vector2(76.0, 34.0)
	action_button.disabled = not bool(entry.get("action_enabled", false))
	action_button.focus_mode = Control.FOCUS_NONE
	action_button.pressed.connect(_on_attachment_action_pressed.bind(str(entry.get("id", ""))))
	_apply_font(action_button, 12)
	row.add_child(action_button)

	return card


func _on_slot_button_pressed(slot_id: String) -> void:
	selected_slot_id = slot_id
	status_label.text = ""
	status_label.visible = false
	_refresh_slot_buttons(current_snapshot.get("slots", []))
	_refresh_attachment_list()
	queue_redraw()


func _on_attachment_action_pressed(attachment_id: String) -> void:
	var result := MetaProgressionStateScript.equip_weapon_attachment(selected_slot_id, attachment_id)
	if not bool(result.get("success", false)):
		status_label.text = UITextsScript.WEAPON_ATTACHMENT_EQUIP_FAILED
		status_label.visible = true
		assembly_changed.emit(UITextsScript.WEAPON_ATTACHMENT_EQUIP_FAILED)
		return

	var status_text := UITextsScript.weapon_attachment_changed_text(
		str(_get_selected_slot_definition().get("display_name", "配件")),
		str(result.get("display_name", ""))
	)
	if str(result.get("reason", "")) == "UNEQUIPPED":
		status_text = UITextsScript.weapon_attachment_removed_text(
			str(_get_selected_slot_definition().get("display_name", "配件")),
			str(result.get("display_name", ""))
		)

	_refresh_panel()
	status_label.text = status_text
	status_label.visible = true
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

	var weapon_size := Vector2(
		clampf(root_size.x * 0.62, 208.0, maxf(root_size.x - 108.0, 208.0)),
		clampf(root_size.y * 0.5, 100.0, maxf(minf(root_size.y - 74.0, 144.0), 100.0))
	)
	weapon_frame.position = Vector2(
		(root_size.x - weapon_size.x) * 0.5,
		clampf((root_size.y - weapon_size.y) * 0.5, 38.0, maxf(root_size.y - weapon_size.y - 38.0, 38.0))
	)
	weapon_frame.size = weapon_size

	var weapon_rect := Rect2(weapon_frame.position, weapon_frame.size)
	_position_slot_button("optic", Vector2(weapon_rect.get_center().x - SLOT_BUTTON_SIZE.x * 0.5, weapon_rect.position.y - 52.0), root_size)
	_position_slot_button("muzzle", Vector2(weapon_rect.end.x - SLOT_BUTTON_SIZE.x * 0.32, weapon_rect.position.y - 8.0), root_size)
	_position_slot_button("magazine", Vector2(weapon_rect.position.x - SLOT_BUTTON_SIZE.x + 18.0, weapon_rect.get_center().y - SLOT_BUTTON_SIZE.y * 0.5), root_size)
	_position_slot_button("stock", Vector2(weapon_rect.get_center().x - SLOT_BUTTON_SIZE.x * 0.5, weapon_rect.end.y + 10.0), root_size)


func _draw() -> void:
	if weapon_frame == null:
		return

	var panel_origin: Vector2 = get_global_rect().position
	var weapon_center: Vector2 = weapon_frame.get_global_rect().get_center() - panel_origin
	for slot_id in slot_buttons.keys():
		var button: Button = slot_buttons.get(slot_id)
		if button == null:
			continue

		var button_center: Vector2 = button.get_global_rect().get_center() - panel_origin
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
