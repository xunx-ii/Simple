extends Control

const TaskSystemScript = preload("res://scripts/systems/task_system.gd")

var task_system

@onready var player_name_label: Label = $SafeArea/MainLayout/TopPanel/TopMargin/TopBar/PlayerColumn/PlayerValueLabel
@onready var gold_label: Label = $SafeArea/MainLayout/TopPanel/TopMargin/TopBar/GoldColumn/GoldValueLabel
@onready var task_toggle_button: Button = $SafeArea/MainLayout/BottomBar/TaskToggleButton
@onready var task_panel: PanelContainer = $TaskPanel
@onready var task_items_container: VBoxContainer = $TaskPanel/TaskMargin/TaskContent/TaskScroll/TaskItems
@onready var task_close_button: Button = $TaskPanel/TaskMargin/TaskContent/TaskHeader/TaskCloseButton
@onready var settings_button: Button = $SafeArea/MainLayout/TopPanel/TopMargin/TopBar/SettingsButton
@onready var settings_overlay: Control = $SettingsOverlay
@onready var settings_close_button: Button = $SettingsOverlay/SettingsDialog/SettingsMargin/SettingsContent/SettingsCloseButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	task_system = TaskSystemScript.new()
	task_system.tasks_updated.connect(_on_tasks_updated)

	settings_button.pressed.connect(_on_settings_button_pressed)
	settings_close_button.pressed.connect(_on_settings_close_button_pressed)
	task_toggle_button.pressed.connect(_on_task_toggle_button_pressed)
	task_close_button.pressed.connect(_close_task_panel)

	settings_overlay.visible = false
	task_panel.visible = false
	_apply_task_state(task_system.get_player_name(), task_system.get_gold(), task_system.get_tasks())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_overlay.visible:
			settings_overlay.visible = false
			get_viewport().set_input_as_handled()
			return

		if task_panel.visible:
			_close_task_panel()
			get_viewport().set_input_as_handled()


func _on_settings_button_pressed() -> void:
	settings_overlay.visible = true


func _on_settings_close_button_pressed() -> void:
	settings_overlay.visible = false


func _on_task_toggle_button_pressed() -> void:
	task_panel.visible = not task_panel.visible
	_refresh_task_button_text()


func _close_task_panel() -> void:
	task_panel.visible = false
	_refresh_task_button_text()


func _on_tasks_updated(tasks: Array, total_gold: int) -> void:
	_apply_task_state(task_system.get_player_name(), total_gold, tasks)


func _apply_task_state(player_name: String, total_gold: int, tasks: Array) -> void:
	player_name_label.text = player_name
	gold_label.text = str(total_gold)
	_rebuild_task_list(tasks)
	_refresh_task_button_text()


func _rebuild_task_list(tasks: Array) -> void:
	for child in task_items_container.get_children():
		task_items_container.remove_child(child)
		child.queue_free()

	for task_variant in tasks:
		if not (task_variant is Dictionary):
			continue

		var task: Dictionary = task_variant
		var row := PanelContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		task_items_container.add_child(row)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_right", 14)
		margin.add_theme_constant_override("margin_bottom", 12)
		row.add_child(margin)

		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 10)
		margin.add_child(content)

		var title := Label.new()
		title.text = "%s  [%s]" % [
			str(task.get("title", "任务")),
			"已完成" if bool(task.get("completed", false)) else "进行中"
		]
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_apply_text_style(title, 15)
		content.add_child(title)

		var description := Label.new()
		description.text = str(task.get("description", ""))
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_apply_text_style(description, 13)
		content.add_child(description)

		var footer := HBoxContainer.new()
		footer.add_theme_constant_override("separation", 10)
		content.add_child(footer)

		var reward := Label.new()
		reward.text = "奖励金币：%d" % int(task.get("reward", 0))
		reward.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_text_style(reward, 13)
		footer.add_child(reward)

		var action_button := Button.new()
		action_button.custom_minimum_size = Vector2(96, 34)
		action_button.text = "已领取" if bool(task.get("completed", false)) else "完成任务"
		action_button.disabled = bool(task.get("completed", false))
		action_button.pressed.connect(_on_complete_task_button_pressed.bind(str(task.get("id", ""))))
		_apply_text_style(action_button, 13)
		footer.add_child(action_button)


func _on_complete_task_button_pressed(task_id: String) -> void:
	task_system.complete_task(task_id)


func _apply_text_style(control: Control, font_size: int) -> void:
	var ui_font: Font = player_name_label.get_theme_font("font")
	if ui_font != null:
		control.add_theme_font_override("font", ui_font)
	control.add_theme_font_size_override("font_size", font_size)


func _refresh_task_button_text() -> void:
	task_toggle_button.text = "收起任务" if task_panel.visible else "任务列表"
