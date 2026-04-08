extends Control

const LOBBY_SCENE_PATH := "res://scenes/lobby.tscn"
const AGREEMENT_URL := "https://www.baidu.com"
const UITextsScript = preload("res://scripts/ui/ui_texts.gd")

@onready var subtitle_label: Label = $SafeArea/ContentPanel/ContentMargin/Content/LeftSection/LeftColumn/SubtitleLabel
@onready var agreement_checkbox: CheckBox = $SafeArea/ContentPanel/ContentMargin/Content/RightSection/RightColumn/AgreementCenter/AgreementRow/AgreementCheckBox
@onready var agreement_prefix_label: Label = $SafeArea/ContentPanel/ContentMargin/Content/RightSection/RightColumn/AgreementCenter/AgreementRow/AgreementPrefixLabel
@onready var service_button: LinkButton = $SafeArea/ContentPanel/ContentMargin/Content/RightSection/RightColumn/AgreementCenter/AgreementRow/ServiceLinkButton
@onready var agreement_connector_label: Label = $SafeArea/ContentPanel/ContentMargin/Content/RightSection/RightColumn/AgreementCenter/AgreementRow/AgreementConnectorLabel
@onready var privacy_button: LinkButton = $SafeArea/ContentPanel/ContentMargin/Content/RightSection/RightColumn/AgreementCenter/AgreementRow/PrivacyLinkButton
@onready var start_button: Button = $SafeArea/ContentPanel/ContentMargin/Content/LeftSection/LeftColumn/StartButton
@onready var about_button: Button = $SafeArea/ContentPanel/ContentMargin/Content/LeftSection/LeftColumn/AboutButton
@onready var notice_title_label: Label = $SafeArea/ContentPanel/ContentMargin/Content/RightSection/RightColumn/NoticeTitleLabel
@onready var notice_label: Label = $SafeArea/ContentPanel/ContentMargin/Content/RightSection/RightColumn/NoticeLabel
@onready var agreement_overlay: Control = $AgreementOverlay
@onready var agreement_title_label: Label = $AgreementOverlay/AgreementDialog/AgreementMargin/AgreementContent/AgreementTitle
@onready var agreement_prompt_label: Label = $AgreementOverlay/AgreementDialog/AgreementMargin/AgreementContent/AgreementPrompt
@onready var agreement_yes_button: Button = $AgreementOverlay/AgreementDialog/AgreementMargin/AgreementContent/AgreementButtons/AgreementYesButton
@onready var agreement_no_button: Button = $AgreementOverlay/AgreementDialog/AgreementMargin/AgreementContent/AgreementButtons/AgreementNoButton
@onready var about_overlay: Control = $AboutOverlay
@onready var about_title_label: Label = $AboutOverlay/AboutDialog/AboutMargin/AboutContent/AboutTitle
@onready var about_body_label: Label = $AboutOverlay/AboutDialog/AboutMargin/AboutContent/AboutBody
@onready var about_close_button: Button = $AboutOverlay/AboutDialog/AboutMargin/AboutContent/AboutCloseButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var tree := get_tree()
	if tree != null:
		tree.paused = false

	_apply_static_texts()

	start_button.pressed.connect(_on_start_button_pressed)
	about_button.pressed.connect(_on_about_button_pressed)
	service_button.pressed.connect(_open_agreement_link)
	privacy_button.pressed.connect(_open_agreement_link)
	agreement_yes_button.pressed.connect(_on_agreement_yes_button_pressed)
	agreement_no_button.pressed.connect(_on_agreement_no_button_pressed)
	about_close_button.pressed.connect(_on_about_close_button_pressed)

	_set_overlay_visible(agreement_overlay, false)
	_set_overlay_visible(about_overlay, false)


func _apply_static_texts() -> void:
	subtitle_label.text = UITextsScript.MAIN_MENU_SUBTITLE
	start_button.text = UITextsScript.MAIN_MENU_START
	about_button.text = UITextsScript.MAIN_MENU_ABOUT
	notice_title_label.text = UITextsScript.MAIN_MENU_NOTICE_TITLE
	notice_label.text = UITextsScript.main_menu_notice_text()
	agreement_prefix_label.text = UITextsScript.MAIN_MENU_AGREEMENT_PREFIX
	agreement_connector_label.text = UITextsScript.MAIN_MENU_AGREEMENT_CONNECTOR
	service_button.text = UITextsScript.MAIN_MENU_SERVICE_AGREEMENT
	privacy_button.text = UITextsScript.MAIN_MENU_PRIVACY_AGREEMENT
	agreement_title_label.text = UITextsScript.MAIN_MENU_AGREEMENT_TITLE
	agreement_prompt_label.text = UITextsScript.MAIN_MENU_AGREEMENT_PROMPT
	agreement_yes_button.text = UITextsScript.MAIN_MENU_CONFIRM_YES
	agreement_no_button.text = UITextsScript.MAIN_MENU_CONFIRM_NO
	about_title_label.text = UITextsScript.MAIN_MENU_ABOUT
	about_body_label.text = UITextsScript.main_menu_about_body()
	about_close_button.text = UITextsScript.CLOSE


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
