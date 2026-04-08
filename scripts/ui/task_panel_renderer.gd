class_name TaskPanelRenderer
extends RefCounted


static func populate(
	container: VBoxContainer,
	task_chains: Array,
	ui_font: Font,
	action_callback: Callable
) -> void:
	_clear_container(container)

	for chain_variant in task_chains:
		if not (chain_variant is Dictionary):
			continue

		container.add_child(_build_chain_card(chain_variant, ui_font, action_callback))


static func _build_chain_card(chain: Dictionary, ui_font: Font, action_callback: Callable) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _build_panel_style(Color(0.094, 0.11, 0.145, 0.96)))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	content.add_child(header)

	var title := Label.new()
	title.text = str(chain.get("title", "任务链"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_text_style(title, ui_font, 16)
	header.add_child(title)

	var summary := Label.new()
	summary.text = str(chain.get("summary_text", ""))
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_apply_text_style(summary, ui_font, 13)
	header.add_child(summary)

	var description := Label.new()
	description.text = str(chain.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_text_style(description, ui_font, 13)
	content.add_child(description)

	for task_variant in chain.get("tasks", []):
		if not (task_variant is Dictionary):
			continue

		content.add_child(_build_task_row(task_variant, ui_font, action_callback))

	return card


static func _build_task_row(task: Dictionary, ui_font: Font, action_callback: Callable) -> Control:
	var row := PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", _build_panel_style(Color(0.119, 0.135, 0.172, 0.98), 10))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	row.add_child(margin)

	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 6)
	layout.add_child(details)

	var title := Label.new()
	title.text = "%s  [%s]" % [str(task.get("title", "任务")), str(task.get("status_text", ""))]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_text_style(title, ui_font, 14)
	details.add_child(title)

	var description := Label.new()
	description.text = str(task.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_text_style(description, ui_font, 12)
	details.add_child(description)

	var meta := HBoxContainer.new()
	meta.add_theme_constant_override("separation", 12)
	details.add_child(meta)

	var progress := Label.new()
	progress.text = str(task.get("progress_text", ""))
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_text_style(progress, ui_font, 12)
	meta.add_child(progress)

	var reward := Label.new()
	reward.text = "奖励 %d 金币" % int(task.get("reward", 0))
	_apply_text_style(reward, ui_font, 12)
	meta.add_child(reward)

	var action_button := Button.new()
	action_button.custom_minimum_size = Vector2(104, 38)
	action_button.text = str(task.get("action_label", ""))
	action_button.disabled = not bool(task.get("action_enabled", false))
	if bool(task.get("action_enabled", false)) and action_callback.is_valid():
		action_button.pressed.connect(action_callback.bind(str(task.get("id", ""))))
	_apply_text_style(action_button, ui_font, 13)
	layout.add_child(action_button)

	return row


static func _build_panel_style(
	background_color: Color,
	corner_radius: int = 12
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.258824, 0.337255, 0.415686, 0.88)
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	return style


static func _apply_text_style(control: Control, ui_font: Font, font_size: int) -> void:
	if ui_font != null:
		control.add_theme_font_override("font", ui_font)
	control.add_theme_font_size_override("font_size", font_size)


static func _clear_container(container: VBoxContainer) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
