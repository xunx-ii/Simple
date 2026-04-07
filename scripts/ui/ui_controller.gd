class_name UIController
extends CanvasLayer

signal restart_requested
signal quit_requested

const DASH_READY_TEXT := "DASH READY"
const ACTIVE_STATE_TEMPLATE := "WASD Move  SHIFT Dash\nMouse Aim  RMB Aim  LMB Shoot\n%s  ENEMY NAV AGENT"
const GAME_OVER_TEXT := "Game Over"

var game_over: bool = false
var player: Node2D = null

@onready var fog_overlay: ColorRect = $FogOverlay
@onready var score_label: Label = $ScoreLabel
@onready var state_label: Label = $StateLabel
@onready var restart_label: Label = $RestartLabel
@onready var wave_label: Label = $WaveLabel
@onready var dash_label: Label = $DashLabel
@onready var dash_bar_fill: ColorRect = $DashBarFill
@onready var banner_label: Label = $BannerLabel
@onready var pause_overlay: Control = $PauseOverlay
@onready var continue_button: Button = $PauseOverlay/PausePanel/PauseButtons/ContinueButton
@onready var quit_button: Button = $PauseOverlay/PausePanel/PauseButtons/QuitButton
@onready var damage_indicators: Node2D = $DamageIndicators
@onready var crosshair: Node2D = $Crosshair

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configure_process_modes()
	continue_button.text = "继续游戏"
	quit_button.text = "退出游戏"
	continue_button.pressed.connect(_on_continue_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	set_pause_menu_visible(false)

func _process(_delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("restart"):
			restart_requested.emit()
		return

	if Input.is_action_just_pressed("ui_cancel"):
		set_pause_menu_visible(not pause_overlay.visible)

func setup(player_node: Node2D) -> void:
	player = player_node

	if fog_overlay != null and fog_overlay.has_method("setup"):
		fog_overlay.setup(player)

	if damage_indicators != null and damage_indicators.has_method("setup"):
		damage_indicators.setup(player)

	if crosshair != null and crosshair.has_method("setup"):
		crosshair.setup(player)

func apply_hud(state: Dictionary) -> void:
	var next_game_over: bool = state.get("game_over", false)
	if next_game_over and not game_over:
		set_pause_menu_visible(false)

	game_over = next_game_over
	score_label.text = "HP: %d  SCORE: %d" % [state.get("health", 0), state.get("score", 0)]
	wave_label.text = "WAVE %d" % state.get("wave", 0)
	banner_label.text = str(state.get("banner_text", ""))

	var dash_ready: bool = state.get("dash_ready", false)
	var dash_ratio: float = state.get("dash_ratio", 0.0)
	dash_label.text = DASH_READY_TEXT if dash_ready else "DASH %.1f" % state.get("dash_cooldown", 0.0)
	dash_bar_fill.size.x = 72.0 * dash_ratio
	dash_bar_fill.color = Color(0.35, 0.87, 1.0, 1.0) if dash_ready else Color(0.31, 0.67, 0.96, 1.0)

	restart_label.visible = game_over
	if game_over:
		state_label.text = GAME_OVER_TEXT
		return

	state_label.text = ACTIVE_STATE_TEMPLATE % state.get("weapon_name", "UNARMED")

func set_pause_menu_visible(menu_open: bool) -> void:
	pause_overlay.visible = menu_open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if menu_open else Input.MOUSE_MODE_CONFINED_HIDDEN
	var tree := get_tree()
	if tree != null:
		tree.paused = menu_open

func close_pause_menu() -> void:
	set_pause_menu_visible(false)

func _configure_process_modes() -> void:
	fog_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	damage_indicators.process_mode = Node.PROCESS_MODE_ALWAYS
	crosshair.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	continue_button.process_mode = Node.PROCESS_MODE_ALWAYS
	quit_button.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_continue_button_pressed() -> void:
	set_pause_menu_visible(false)

func _on_quit_button_pressed() -> void:
	quit_requested.emit()
