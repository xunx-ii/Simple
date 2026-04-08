extends Control

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const TaskSystemScript = preload("res://scripts/systems/task_system.gd")
const TaskPanelRendererScript = preload("res://scripts/ui/task_panel_renderer.gd")
const InputSettingsDialogScript = preload("res://scripts/ui/input_settings_dialog.gd")
const LevelSelectionDialogScript = preload("res://scripts/ui/level_selection_dialog.gd")
const ItemListDialogScript = preload("res://scripts/ui/item_list_dialog.gd")
const MetaProgressionStateScript = preload("res://scripts/systems/meta_progression_state.gd")
const LevelProgressStateScript = preload("res://scripts/systems/levels/level_progress_state.gd")
const UITextsScript = preload("res://scripts/ui/ui_texts.gd")

const DIALOG_WAREHOUSE := "warehouse"
const DIALOG_SHOP := "shop"

var task_system
var input_settings_dialog: Control
var level_selection_dialog: Control
var warehouse_dialog: Control
var shop_dialog: Control
var level_select_button: Button
var warehouse_button: Button
var shop_button: Button
var last_shop_status_text := ""

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
	LevelProgressStateScript.clear_active_challenge()
	task_system = TaskSystemScript.new()
	task_system.tasks_updated.connect(_on_tasks_updated)

	input_settings_dialog = InputSettingsDialogScript.new()
	add_child(input_settings_dialog)

	level_selection_dialog = LevelSelectionDialogScript.new()
	add_child(level_selection_dialog)
	if level_selection_dialog.has_signal("challenge_requested"):
		level_selection_dialog.challenge_requested.connect(_on_level_challenge_requested)

	warehouse_dialog = ItemListDialogScript.new()
	add_child(warehouse_dialog)
	if warehouse_dialog.has_signal("item_action_requested"):
		warehouse_dialog.item_action_requested.connect(_on_item_dialog_action_requested)

	shop_dialog = ItemListDialogScript.new()
	add_child(shop_dialog)
	if shop_dialog.has_signal("item_action_requested"):
		shop_dialog.item_action_requested.connect(_on_item_dialog_action_requested)

	_setup_bottom_buttons()

	settings_button.pressed.connect(_on_settings_button_pressed)
	input_settings_button.pressed.connect(_on_input_settings_button_pressed)
	settings_close_button.pressed.connect(_on_settings_close_button_pressed)
	task_toggle_button.pressed.connect(_on_task_toggle_button_pressed)
	task_close_button.pressed.connect(_close_task_panel)

	_apply_static_texts()
	settings_overlay.visible = false
	task_panel.visible = false
	_refresh_lobby_state()


func _apply_static_texts() -> void:
	player_title_label.text = UITextsScript.LOBBY_PLAYER_TITLE
	gold_title_label.text = UITextsScript.LOBBY_GOLD_TITLE
	settings_button.text = UITextsScript.SETTINGS
	if level_select_button != null:
		level_select_button.text = UITextsScript.LEVEL_SELECT
	if warehouse_button != null:
		warehouse_button.text = UITextsScript.WAREHOUSE
	if shop_button != null:
		shop_button.text = UITextsScript.SHOP
	task_title_label.text = UITextsScript.TASK_PANEL_TITLE
	task_close_button.text = UITextsScript.CLOSE
	settings_title_label.text = UITextsScript.SETTINGS
	settings_body_label.text = UITextsScript.LOBBY_SETTINGS_BODY
	input_settings_button.text = UITextsScript.INPUT_SETTINGS
	settings_close_button.text = UITextsScript.CLOSE


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if _is_dialog_open(shop_dialog):
		shop_dialog.close_dialog()
		get_viewport().set_input_as_handled()
		return

	if _is_dialog_open(warehouse_dialog):
		warehouse_dialog.close_dialog()
		get_viewport().set_input_as_handled()
		return

	if _is_dialog_open(level_selection_dialog):
		level_selection_dialog.close_dialog()
		get_viewport().set_input_as_handled()
		return

	if _is_dialog_open(input_settings_dialog):
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
	_close_item_dialogs()
	settings_overlay.visible = true


func _on_settings_close_button_pressed() -> void:
	if _is_dialog_open(input_settings_dialog):
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
	_close_item_dialogs()
	if level_selection_dialog != null and level_selection_dialog.has_method("open_dialog"):
		level_selection_dialog.open_dialog()


func _on_warehouse_button_pressed() -> void:
	if _is_dialog_open(warehouse_dialog):
		warehouse_dialog.close_dialog()
		return

	if _is_dialog_open(shop_dialog):
		shop_dialog.close_dialog()

	warehouse_dialog.open_dialog(_build_warehouse_dialog_state())


func _on_shop_button_pressed() -> void:
	if _is_dialog_open(shop_dialog):
		shop_dialog.close_dialog()
		return

	if _is_dialog_open(warehouse_dialog):
		warehouse_dialog.close_dialog()

	last_shop_status_text = ""
	shop_dialog.open_dialog(_build_shop_dialog_state())


func _on_level_challenge_requested(level_id: String) -> void:
	if not LevelProgressStateScript.start_challenge(level_id):
		return

	if _is_dialog_open(level_selection_dialog):
		level_selection_dialog.close_dialog()

	var tree := get_tree()
	if tree == null:
		return

	var change_result := tree.change_scene_to_file(MAIN_SCENE_PATH)
	if change_result != OK:
		push_error("Unable to load scene: %s" % MAIN_SCENE_PATH)


func _on_tasks_updated(task_chains: Array, total_gold: int) -> void:
	_apply_task_state(task_system.get_player_name(), total_gold, task_chains)
	_refresh_item_dialog_states()


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


func _on_item_dialog_action_requested(dialog_id: String, item_id: String) -> void:
	if dialog_id != DIALOG_SHOP:
		return

	var purchase_result := MetaProgressionStateScript.buy_shop_item(item_id)
	last_shop_status_text = _build_shop_status_text(purchase_result)
	_refresh_lobby_state()


func _refresh_lobby_state() -> void:
	_apply_task_state(
		task_system.get_player_name(),
		MetaProgressionStateScript.get_gold(),
		task_system.get_task_chains()
	)
	_refresh_item_dialog_states()


func _refresh_item_dialog_states() -> void:
	if _is_dialog_open(warehouse_dialog):
		warehouse_dialog.set_dialog_state(_build_warehouse_dialog_state())

	if _is_dialog_open(shop_dialog):
		shop_dialog.set_dialog_state(_build_shop_dialog_state())


func _build_warehouse_dialog_state() -> Dictionary:
	var snapshot: Dictionary = MetaProgressionStateScript.get_warehouse_snapshot()
	var items: Array[Dictionary] = []

	for item_variant in snapshot.get("items", []):
		if not (item_variant is Dictionary):
			continue

		var item: Dictionary = item_variant
		items.append(
			{
				"id": str(item.get("id", "")),
				"display_name": str(item.get("display_name", "物资")),
				"meta_text": "x%d  估值 %d 金币"
					% [int(item.get("quantity", 0)), int(item.get("total_value", 0))]
			}
		)

	return {
		"dialog_id": DIALOG_WAREHOUSE,
		"title": UITextsScript.WAREHOUSE,
		"summary_text": UITextsScript.warehouse_summary_text(
			int(snapshot.get("used_slots", 0)),
			int(snapshot.get("capacity", 0)),
			int(snapshot.get("total_quantity", 0)),
			int(snapshot.get("total_sale_value", 0))
		),
		"empty_text": UITextsScript.WAREHOUSE_EMPTY,
		"items": items
	}


func _build_shop_dialog_state() -> Dictionary:
	var items: Array[Dictionary] = []

	for item_variant in MetaProgressionStateScript.get_shop_entries():
		if not (item_variant is Dictionary):
			continue

		var item: Dictionary = item_variant
		items.append(
			{
				"id": str(item.get("id", "")),
				"display_name": str(item.get("display_name", "物资")),
				"meta_text": "售价 %d 金币  入库估值 %d 金币"
					% [int(item.get("price", 0)), int(item.get("sell_value", 0))],
				"description": str(item.get("description", "")),
				"action_text": UITextsScript.BUY,
				"action_enabled": bool(item.get("can_afford", false))
			}
		)

	return {
		"dialog_id": DIALOG_SHOP,
		"title": UITextsScript.SHOP,
		"summary_text": UITextsScript.shop_summary_text(MetaProgressionStateScript.get_gold()),
		"status_text": last_shop_status_text,
		"empty_text": UITextsScript.SHOP_EMPTY,
		"items": items
	}


func _build_shop_status_text(purchase_result: Dictionary) -> String:
	var reason := str(purchase_result.get("reason", ""))
	match reason:
		"PURCHASED":
			return UITextsScript.shop_purchase_text(
				str(purchase_result.get("display_name", "物资")),
				int(purchase_result.get("price", 0))
			)
		"NOT_ENOUGH_GOLD":
			return UITextsScript.SHOP_NOT_ENOUGH_GOLD
		"WAREHOUSE_FULL":
			return UITextsScript.SHOP_WAREHOUSE_FULL
		_:
			return UITextsScript.SHOP_OUT_OF_STOCK


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

	level_select_button = _create_bottom_button(UITextsScript.LEVEL_SELECT, Callable(self, "_on_level_select_button_pressed"))
	warehouse_button = _create_bottom_button(UITextsScript.WAREHOUSE, Callable(self, "_on_warehouse_button_pressed"))
	shop_button = _create_bottom_button(UITextsScript.SHOP, Callable(self, "_on_shop_button_pressed"))

	button_column.add_child(level_select_button)
	button_column.add_child(warehouse_button)
	button_column.add_child(shop_button)
	button_column.add_child(task_toggle_button)


func _create_bottom_button(button_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.custom_minimum_size = task_toggle_button.custom_minimum_size
	button.text = button_text
	if callback.is_valid():
		button.pressed.connect(callback)

	_clone_button_theme(button)
	return button


func _clone_button_theme(target_button: Button) -> void:
	var font := task_toggle_button.get_theme_font("font")
	if font != null:
		target_button.add_theme_font_override("font", font)
	target_button.add_theme_font_size_override(
		"font_size",
		task_toggle_button.get_theme_font_size("font_size")
	)


func _close_item_dialogs() -> void:
	if _is_dialog_open(warehouse_dialog):
		warehouse_dialog.close_dialog()
	if _is_dialog_open(shop_dialog):
		shop_dialog.close_dialog()


func _is_dialog_open(dialog: Control) -> bool:
	return (
		dialog != null
		and dialog.has_method("is_dialog_open")
		and dialog.is_dialog_open()
	)
