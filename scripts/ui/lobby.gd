extends Control

const TaskSystemScript = preload("res://scripts/systems/task_system.gd")
const TaskPanelRendererScript = preload("res://scripts/ui/task_panel_renderer.gd")
const InputSettingsDialogScript = preload("res://scripts/ui/input_settings_dialog.gd")

var task_system
var input_settings_dialog: Control

@onready var player_name_label: Label = $SafeArea/MainLayout/TopPanel/TopMargin/TopBar/PlayerSection/PlayerColumn/PlayerValueLabel
@onready var gold_label: Label = $SafeArea/MainLayout/TopPanel/TopMargin/TopBar/GoldSection/GoldColumn/GoldValueLabel
@onready var task_toggle_button: Button = $SafeArea/MainLayout/BottomBar/TaskToggleButton
@onready var task_panel: PanelContainer = $TaskPanel
@onready var task_items_container: VBoxContainer = $TaskPanel/TaskMargin/TaskContent/TaskScroll/TaskItems
@onready var task_close_button: Button = $TaskPanel/TaskMargin/TaskContent/TaskHeader/TaskCloseButton
@onready var settings_button: Button = $SafeArea/MainLayout/TopPanel/TopMargin/TopBar/SettingsSection/SettingsButton
@onready var settings_overlay: Control = $SettingsOverlay
@onready var input_settings_button: Button = $SettingsOverlay/SettingsDialog/SettingsMargin/SettingsContent/InputSettingsButton
@onready var settings_close_button: Button = $SettingsOverlay/SettingsDialog/SettingsMargin/SettingsContent/SettingsCloseButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	task_system = TaskSystemScript.new()
	task_system.tasks_updated.connect(_on_tasks_updated)
	input_settings_dialog = InputSettingsDialogScript.new()
	add_child(input_settings_dialog)

	settings_button.pressed.connect(_on_settings_button_pressed)
	input_settings_button.pressed.connect(_on_input_settings_button_pressed)
	settings_close_button.pressed.connect(_on_settings_close_button_pressed)
	task_toggle_button.pressed.connect(_on_task_toggle_button_pressed)
	task_close_button.pressed.connect(_close_task_panel)

	settings_overlay.visible = false
	task_panel.visible = false
	_apply_task_state(task_system.get_player_name(), task_system.get_gold(), task_system.get_task_chains())


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if input_settings_dialog != null and input_settings_dialog.has_method("is_dialog_open") and input_settings_dialog.is_dialog_open():
		input_settings_dialog.close_dialog()
		get_viewport().set_input_as_handled()
		return

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
	if input_settings_dialog != null and input_settings_dialog.has_method("close_dialog"):
		input_settings_dialog.close_dialog()
	settings_overlay.visible = false


func _on_task_toggle_button_pressed() -> void:
	task_panel.visible = not task_panel.visible
	_refresh_task_button_text(task_system.get_task_chains())


func _close_task_panel() -> void:
	task_panel.visible = false
	_refresh_task_button_text(task_system.get_task_chains())


func _on_input_settings_button_pressed() -> void:
	if input_settings_dialog != null and input_settings_dialog.has_method("open_dialog"):
		input_settings_dialog.open_dialog()


func _on_tasks_updated(task_chains: Array, total_gold: int) -> void:
	_apply_task_state(task_system.get_player_name(), total_gold, task_chains)


func _apply_task_state(player_name: String, total_gold: int, task_chains: Array) -> void:
	player_name_label.text = player_name
	gold_label.text = str(total_gold)
	TaskPanelRendererScript.populate(
		task_items_container,
		task_chains,
		_get_ui_font(),
		Callable(self, "_on_task_action_pressed")
	)
	_refresh_task_button_text(task_chains)


func _on_task_action_pressed(task_id: String) -> void:
	task_system.perform_task_action(task_id)


func _get_ui_font() -> Font:
	return player_name_label.get_theme_font("font")


func _refresh_task_button_text(task_chains: Array) -> void:
	var pending_count := 0
	var ready_count := 0

	for chain_variant in task_chains:
		if not (chain_variant is Dictionary):
			continue

		for task_variant in chain_variant.get("tasks", []):
			if not (task_variant is Dictionary):
				continue

			var status := str(task_variant.get("status", ""))
			if status == "ready_to_complete":
				ready_count += 1
			if status != "locked" and status != "completed":
				pending_count += 1

	var base_label := "鏀惰捣浠诲姟" if task_panel.visible else "浠诲姟鍒楄〃"
	if ready_count > 0:
		task_toggle_button.text = "%s (%d 鍙彁浜?" % [base_label, ready_count]
		return

	if pending_count > 0:
		task_toggle_button.text = "%s (%d)" % [base_label, pending_count]
		return

	task_toggle_button.text = base_label
