class_name TaskPanelRenderer
extends RefCounted

const TaskTextsScript = preload("res://scripts/systems/tasks/task_texts.gd")
const UIThemeHelperScript = preload("res://scripts/ui/ui_theme_helper.gd")


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
	card.add_theme_stylebox_override("panel", UIThemeHelperScript.build_panel_style(Color(0.094, 0.11, 0.145, 0.96)))

	var margin := MarginContainer.new()
	UIThemeHelperScript.set_margin(margin, 14, 14, 14, 14)
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	content.add_child(header)

	var title := Label.new()
	title.text = str(chain.get("title", TaskTextsScript.DEFAULT_CHAIN_TITLE))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UIThemeHelperScript.apply_font(title, ui_font, 16)
	header.add_child(title)

	var summary := Label.new()
	summary.text = str(chain.get("summary_text", ""))
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UIThemeHelperScript.apply_font(summary, ui_font, 13)
	header.add_child(summary)

	var description := Label.new()
	description.text = str(chain.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIThemeHelperScript.apply_font(description, ui_font, 13)
	content.add_child(description)

	for task_variant in chain.get("tasks", []):
		if not (task_variant is Dictionary):
			continue

		content.add_child(_build_task_row(task_variant, ui_font, action_callback))

	return card


static func _build_task_row(task: Dictionary, ui_font: Font, action_callback: Callable) -> Control:
	var row := PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_stylebox_override("panel", UIThemeHelperScript.build_panel_style(Color(0.119, 0.135, 0.172, 0.98), 10))

	var margin := MarginContainer.new()
	UIThemeHelperScript.set_margin(margin, 12, 12, 12, 12)
	row.add_child(margin)

	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 6)
	layout.add_child(details)

	var title := Label.new()
	title.text = "%s  [%s]" % [str(task.get("title", TaskTextsScript.DEFAULT_TASK_TITLE)), str(task.get("status_text", ""))]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIThemeHelperScript.apply_font(title, ui_font, 14)
	details.add_child(title)

	var description := Label.new()
	description.text = str(task.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIThemeHelperScript.apply_font(description, ui_font, 12)
	details.add_child(description)

	var meta := HBoxContainer.new()
	meta.add_theme_constant_override("separation", 12)
	details.add_child(meta)

	var progress := Label.new()
	progress.text = str(task.get("progress_text", ""))
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIThemeHelperScript.apply_font(progress, ui_font, 12)
	meta.add_child(progress)

	var reward := Label.new()
	reward.text = TaskTextsScript.reward_text(int(task.get("reward", 0)))
	UIThemeHelperScript.apply_font(reward, ui_font, 12)
	meta.add_child(reward)

	var action_button := Button.new()
	action_button.custom_minimum_size = Vector2(104, 38)
	action_button.text = str(task.get("action_label", ""))
	action_button.disabled = not bool(task.get("action_enabled", false))
	if bool(task.get("action_enabled", false)) and action_callback.is_valid():
		action_button.pressed.connect(action_callback.bind(str(task.get("id", ""))))
	UIThemeHelperScript.apply_font(action_button, ui_font, 13)
	layout.add_child(action_button)

	return row


static func _clear_container(container: VBoxContainer) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
