extends Control

const LOBBY_SCENE_PATH := "res://scenes/lobby.tscn"
const AGREEMENT_URL := "https://www.baidu.com"

@onready var agreement_checkbox: CheckBox = $SafeArea/ContentCenter/ContentPanel/ContentMargin/Content/RightColumn/AgreementCenter/AgreementRow/AgreementCheckBox
@onready var service_button: LinkButton = $SafeArea/ContentCenter/ContentPanel/ContentMargin/Content/RightColumn/AgreementCenter/AgreementRow/ServiceLinkButton
@onready var privacy_button: LinkButton = $SafeArea/ContentCenter/ContentPanel/ContentMargin/Content/RightColumn/AgreementCenter/AgreementRow/PrivacyLinkButton
@onready var start_button: Button = $SafeArea/ContentCenter/ContentPanel/ContentMargin/Content/LeftColumn/StartButton
@onready var about_button: Button = $SafeArea/ContentCenter/ContentPanel/ContentMargin/Content/LeftColumn/AboutButton
@onready var notice_label: Label = $SafeArea/ContentCenter/ContentPanel/ContentMargin/Content/RightColumn/NoticeLabel
@onready var agreement_overlay: Control = $AgreementOverlay
@onready var agreement_prompt_label: Label = $AgreementOverlay/AgreementDialog/AgreementMargin/AgreementContent/AgreementPrompt
@onready var agreement_yes_button: Button = $AgreementOverlay/AgreementDialog/AgreementMargin/AgreementContent/AgreementButtons/AgreementYesButton
@onready var agreement_no_button: Button = $AgreementOverlay/AgreementDialog/AgreementMargin/AgreementContent/AgreementButtons/AgreementNoButton
@onready var about_overlay: Control = $AboutOverlay
@onready var about_body_label: Label = $AboutOverlay/AboutDialog/AboutMargin/AboutContent/AboutBody
@onready var about_close_button: Button = $AboutOverlay/AboutDialog/AboutMargin/AboutContent/AboutCloseButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var tree := get_tree()
	if tree != null:
		tree.paused = false

	notice_label.text = (
		"抵制不良游戏，拒绝盗版游戏。\n"
		+ "注意自我保护，谨防受骗上当。\n"
		+ "适度游戏益脑，沉迷游戏伤身。\n"
		+ "合理安排时间，享受健康生活。"
	)
	agreement_prompt_label.text = "是否同意服务和隐私协议？"
	about_body_label.text = (
		"《Simple》当前提供主菜单与大厅界面原型，\n"
		+ "后续可以继续接入战斗、商店和角色成长流程。"
	)

	start_button.pressed.connect(_on_start_button_pressed)
	about_button.pressed.connect(_on_about_button_pressed)
	service_button.pressed.connect(_open_agreement_link)
	privacy_button.pressed.connect(_open_agreement_link)
	agreement_yes_button.pressed.connect(_on_agreement_yes_button_pressed)
	agreement_no_button.pressed.connect(_on_agreement_no_button_pressed)
	about_close_button.pressed.connect(_on_about_close_button_pressed)

	_set_overlay_visible(agreement_overlay, false)
	_set_overlay_visible(about_overlay, false)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if agreement_overlay.visible:
		_set_overlay_visible(agreement_overlay, false)
		get_viewport().set_input_as_handled()
		return

	if about_overlay.visible:
		_set_overlay_visible(about_overlay, false)
		get_viewport().set_input_as_handled()


func _on_start_button_pressed() -> void:
	if agreement_checkbox.button_pressed:
		_enter_lobby()
		return

	_set_overlay_visible(agreement_overlay, true)


func _on_about_button_pressed() -> void:
	_set_overlay_visible(agreement_overlay, false)
	_set_overlay_visible(about_overlay, true)


func _on_agreement_yes_button_pressed() -> void:
	agreement_checkbox.button_pressed = true
	_set_overlay_visible(agreement_overlay, false)
	_enter_lobby()


func _on_agreement_no_button_pressed() -> void:
	_set_overlay_visible(agreement_overlay, false)


func _on_about_close_button_pressed() -> void:
	_set_overlay_visible(about_overlay, false)


func _open_agreement_link() -> void:
	OS.shell_open(AGREEMENT_URL)


func _set_overlay_visible(overlay: Control, should_show: bool) -> void:
	overlay.visible = should_show


func _enter_lobby() -> void:
	var tree := get_tree()
	if tree == null:
		return

	var change_result := tree.change_scene_to_file(LOBBY_SCENE_PATH)
	if change_result != OK:
		push_error("Unable to load scene: %s" % LOBBY_SCENE_PATH)
