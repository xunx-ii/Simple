extends Control

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const TaskSystemScript = preload("res://scripts/systems/task_system.gd")
const TaskPanelRendererScript = preload("res://scripts/ui/task_panel_renderer.gd")
const InputSettingsDialogScript = preload("res://scripts/ui/input_settings_dialog.gd")
const LevelSelectionDialogScript = preload("res://scripts/ui/level_selection_dialog.gd")
const LevelProgressStateScript = preload("res://scripts/systems/levels/level_progress_state.gd")
const UITextsScript = preload("res://scripts/ui/ui_texts.gd")

var task_system
var input_settings_dialog: Control
var level_selection_dialog: Control
var level_select_button: Button

@onready var player_title_label: Label = $SafeArea/MainLayout/TopPanel/TopMargin/TopBar/PlayerSection/PlayerColumn/PlayerTitleLabel
@onready var player_name_label: Label = $SafeArea/MainLayout/TopPanel/TopMargin/TopBar/PlayerSection/PlayerColumn/PlayerValueLabel
@onready var gold_title_label: Label = $SafeArea/MainLayout/TopPanel/TopMargin/TopBar/GoldSection/GoldColumn/GoldTitleLabel
@onready var gold_label: Label = $SafeArea/MainLayout/TopPanel/TopMargin/TopBar/GoldSection/GoldColumn/GoldValueLabel
@onready var bottom_bar: HBoxContainer = $SafeArea/MainLayout/BottomBar
@onready var task_toggle_button: Button = $SafeArea/MainLayout/BottomBar/TaskToggleButton
@onready var task_panel: PanelContainer = $TaskPanel
@onready var task_title_label: Label = $TaskPanel/TaskMargin/TaskContent/TaskHeader/TaskTitle
@onready var task_items_container: VBoxContainer = $TaskPanel/TaskMargin/TaskContent/TaskScroll/TaskItems
@onready var task_close_button: Button = $TaskPanel/TaskMargin/TaskContent/TaskHeader/TaskCloseButton
@onready var settings_button: Button = $SafeArea/MainLayout/TopPanel/TopMargin/TopBar/SettingsSection/SettingsButton
@onready var settings_overlay: Control = $SettingsOverlay
@onready var settings_title_label: Label = $SettingsOverlay/SettingsDialog/SettingsMargin/SettingsContent/SettingsTitle
@onready var settings_body_label: Label = $SettingsOverlay/SettingsDialog/SettingsMargin/SettingsContent/SettingsBody
@onready var input_settings_button: Button = $SettingsOverlay/SettingsDialog/SettingsMargin/SettingsContent/InputSettingsButton
@onready var settings_close_button: Button = $SettingsOverlay/SettingsDialog/SettingsMargin/SettingsContent/SettingsCloseButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	task_system = TaskSystemScript.new()
	task_system.tasks_updated.connect(_on_tasks_updated)
	input_settings_dialog = InputSettingsDialogScript.new()
	add_child(input_settings_dialog)
	level_selection_dialog = LevelSelectionDialogScript.new()
	add_child(level_selection_dialog)
	if level_selection_dialog.has_signal("challenge_requested"):
		level_selection_dialog.challenge_requested.connect(_on_level_challenge_requested)

	_setup_bottom_buttons()

	settings_button.pressed.connect(_on_settings_button_pressed)
	input_settings_button.pressed.connect(_on_input_settings_button_pressed)
	settings_close_button.pressed.connect(_on_settings_close_button_pressed)
	task_toggle_button.pressed.connect(_on_task_toggle_button_pressed)
	task_close_button.pressed.connect(_close_task_panel)

	_apply_static_texts()
	settings_overlay.visible = false
	task_panel.visible = false
	_apply_task_state(task_system.get_player_name(), task_system.get_gold(), task_system.get_task_chains())


func _apply_static_texts() -> void:
	player_title_label.text = UITextsScript.LOBBY_PLAYER_TITLE
	gold_title_label.text = UITextsScript.LOBBY_GOLD_TITLE
	settings_button.text = UITextsScript.SETTINGS
	if level_select_button != null:
		level_select_button.text = UITextsScript.LEVEL_SELECT
	task_title_label.text = UITextsScript.TASK_PANEL_TITLE
	task_close_button.text = UITextsScript.CLOSE
	settings_title_label.text = UITextsScript.SETTINGS
	settings_body_label.text = UITextsScript.LOBBY_SETTINGS_BODY
	input_settings_button.text = UITextsScript.INPUT_SETTINGS
	settings_close_button.text = UITextsScript.CLOSE


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if level_selection_dialog != null and level_selection_dialog.has_method("is_dialog_open") and level_selection_dialog.is_dialog_open():
		level_selection_dialog.close_dialog()
		get_viewport().set_input_as_handled()
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


func _on_level_select_button_pressed() -> void:
	if level_selection_dialog != null and level_selection_dialog.has_method("open_dialog"):
		level_selection_dialog.open_dialog()


func _on_level_challenge_requested(level_id: String) -> void:
	if not LevelProgressStateScript.start_challenge(level_id):
		return

	if level_selection_dialog != null and level_selection_dialog.has_method("close_dialog"):
		level_selection_dialog.close_dialog()

	var tree := get_tree()
	if tree == null:
		return

	var change_result := tree.change_scene_to_file(MAIN_SCENE_PATH)
	if change_result != OK:
		push_error("Unable to load scene: %s" % MAIN_SCENE_PATH)


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

	task_toggle_button.text = UITextsScript.task_toggle_button_text(task_panel.visible, ready_count, pending_count)


func _setup_bottom_buttons() -> void:
	if bottom_bar == null:
		return

	var button_column := VBoxContainer.new()
	button_column.name = "BottomButtonColumn"
	button_column.add_theme_constant_override("separation", 10)
	button_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bottom_bar.remove_child(task_toggle_button)
	bottom_bar.add_child(button_column)
	button_column.add_child(_create_level_select_button())
	button_column.add_child(task_toggle_button)


func _create_level_select_button() -> Button:
	level_select_button = Button.new()
	level_select_button.custom_minimum_size = task_toggle_button.custom_minimum_size
	level_select_button.text = UITextsScript.LEVEL_SELECT
	level_select_button.pressed.connect(_on_level_select_button_pressed)

	var font := task_toggle_button.get_theme_font("font")
	if font != null:
		level_select_button.add_theme_font_override("font", font)
	level_select_button.add_theme_font_size_override(
		"font_size",
		task_toggle_button.get_theme_font_size("font_size")
	)

	return level_select_button
