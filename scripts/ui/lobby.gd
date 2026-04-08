extends Control

@onready var player_name_label: Label = $TopPanel/TopMargin/TopBar/PlayerNameLabel
@onready var gold_label: Label = $TopPanel/TopMargin/TopBar/GoldLabel
@onready var task_list_label: Label = $TaskPanel/TaskMargin/TaskContent/TaskList
@onready var settings_button: Button = $TopPanel/TopMargin/TopBar/SettingsButton
@onready var settings_overlay: Control = $SettingsOverlay
@onready var settings_close_button: Button = $SettingsOverlay/SettingsDialog/SettingsMargin/SettingsContent/SettingsCloseButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player_name_label.text = "玩家名字：测试玩家"
	gold_label.text = "金币：9999"
	task_list_label.text = "1. 查看角色信息\n2. 整理今日任务\n3. 准备进入战斗"

	settings_button.pressed.connect(_on_settings_button_pressed)
	settings_close_button.pressed.connect(_on_settings_close_button_pressed)
	settings_overlay.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if settings_overlay.visible and event.is_action_pressed("ui_cancel"):
		settings_overlay.visible = false
		get_viewport().set_input_as_handled()


func _on_settings_button_pressed() -> void:
	settings_overlay.visible = true


func _on_settings_close_button_pressed() -> void:
	settings_overlay.visible = false
