extends Node2D

const InputSetup = preload("res://scripts/systems/input_setup.gd")
const EnemyScene := preload("res://scenes/actors/enemy.tscn")
const BulletScene := preload("res://scenes/actors/bullet.tscn")

const ARENA_SIZE := Vector2(320.0, 180.0)
const ARENA_RECT := Rect2(Vector2.ZERO, ARENA_SIZE)
const TILE_SIZE := 16
const MAX_SIMULTANEOUS_ENEMIES := 12
const WAVE_BANNER_TIME := 1.8

var score: int = 0
var game_over: bool = false
var current_wave: int = 0
var enemies_alive: int = 0
var enemies_remaining_to_spawn: int = 0
var banner_time_remaining: float = 0.0

@onready var player = $Player
@onready var enemies: Node2D = $Enemies
@onready var bullets: Node2D = $Bullets
@onready var spawn_timer: Timer = $SpawnTimer
@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var state_label: Label = $CanvasLayer/StateLabel
@onready var restart_label: Label = $CanvasLayer/RestartLabel
@onready var wave_label: Label = $CanvasLayer/WaveLabel
@onready var dash_label: Label = $CanvasLayer/DashLabel
@onready var banner_label: Label = $CanvasLayer/BannerLabel

func _ready() -> void:
    InputSetup.ensure_default_actions()

    player.configure_arena(ARENA_RECT)
    player.shoot_requested.connect(_on_player_shoot_requested)
    player.health_changed.connect(_on_player_health_changed)
    player.defeated.connect(_on_player_defeated)

    spawn_timer.timeout.connect(_on_spawn_timer_timeout)

    randomize()
    _start_next_wave()
    _update_ui()
    queue_redraw()

func _process(delta: float) -> void:
    if game_over and Input.is_action_just_pressed("restart"):
        get_tree().reload_current_scene()

    if banner_time_remaining > 0.0:
        banner_time_remaining = max(banner_time_remaining - delta, 0.0)
        if banner_time_remaining == 0.0 and not game_over:
            banner_label.text = ""

    _update_ui()

func _draw() -> void:
    draw_rect(ARENA_RECT, Color(0.06, 0.08, 0.11, 1.0), true)

    for x in range(0, int(ARENA_SIZE.x), TILE_SIZE):
        for y in range(0, int(ARENA_SIZE.y), TILE_SIZE):
            var tile_rect: Rect2 = Rect2(Vector2(x, y), Vector2.ONE * TILE_SIZE)
            var tile_x: int = int(x / float(TILE_SIZE))
            var tile_y: int = int(y / float(TILE_SIZE))
            var use_alt_color := (tile_x + tile_y) % 2 == 0
            var tile_color: Color = Color(0.12, 0.15, 0.18, 1.0) if use_alt_color else Color(0.10, 0.13, 0.16, 1.0)
            draw_rect(tile_rect, tile_color, true)

    for x in range(0, int(ARENA_SIZE.x) + 1, TILE_SIZE):
        draw_line(Vector2(x, 0.0), Vector2(x, ARENA_SIZE.y), Color(0.15, 0.19, 0.22, 0.55), 1.0)

    for y in range(0, int(ARENA_SIZE.y) + 1, TILE_SIZE):
        draw_line(Vector2(0.0, y), Vector2(ARENA_SIZE.x, y), Color(0.15, 0.19, 0.22, 0.55), 1.0)

    var center_glow_rect: Rect2 = Rect2(Vector2(104.0, 56.0), Vector2(112.0, 68.0))
    draw_rect(center_glow_rect, Color(0.16, 0.20, 0.24, 0.7), true)
    draw_rect(ARENA_RECT, Color(0.50, 0.55, 0.62, 1.0), false, 2.0)

    var dash_fill_width: float = 72.0 * float(player.get_dash_ratio())
    var dash_bar_origin: Vector2 = Vector2(240.0, 48.0)
    draw_rect(Rect2(dash_bar_origin, Vector2(72.0, 6.0)), Color(0.17, 0.20, 0.25, 1.0), true)
    draw_rect(Rect2(dash_bar_origin, Vector2(dash_fill_width, 6.0)), Color(0.35, 0.87, 1.0, 1.0), true)
    draw_rect(Rect2(dash_bar_origin, Vector2(72.0, 6.0)), Color(0.70, 0.78, 0.87, 1.0), false, 1.0)

func _on_spawn_timer_timeout() -> void:
    if game_over:
        return

    if enemies_remaining_to_spawn <= 0:
        return

    if enemies_alive >= MAX_SIMULTANEOUS_ENEMIES:
        return

    var enemy = EnemyScene.instantiate()
    enemy.global_position = _pick_spawn_position()
    enemy.setup(player, ARENA_RECT, _build_enemy_config())
    enemy.defeated.connect(_on_enemy_defeated)
    enemy.tree_exited.connect(_on_enemy_tree_exited)
    enemies.add_child(enemy)
    enemies_alive += 1
    enemies_remaining_to_spawn -= 1

func _on_player_shoot_requested(origin: Vector2, direction: Vector2) -> void:
    if game_over:
        return

    var bullet = BulletScene.instantiate()
    bullet.global_position = origin
    bullet.setup(direction, ARENA_RECT)
    bullets.add_child(bullet)

func _on_player_health_changed(_current_health: int) -> void:
    _update_ui()

func _on_player_defeated() -> void:
    game_over = true
    spawn_timer.stop()
    state_label.text = "Game Over"
    restart_label.visible = true
    banner_label.text = "GAME OVER"
    banner_time_remaining = 999.0

func _on_enemy_defeated() -> void:
    score += 1
    _update_ui()

func _on_enemy_tree_exited() -> void:
    enemies_alive = max(enemies_alive - 1, 0)

    if game_over:
        return

    if enemies_alive == 0 and enemies_remaining_to_spawn == 0:
        _on_wave_cleared()

func _update_ui() -> void:
    score_label.text = "HP: %d  SCORE: %d" % [player.current_health, score]
    wave_label.text = "WAVE %d" % current_wave
    dash_label.text = "DASH READY" if player.is_dash_ready() else "DASH %.1f" % player.get_dash_cooldown_remaining()

    if game_over:
        return

    state_label.text = "WASD Move  SHIFT Dash\nMouse Aim  LMB / Space Shoot"

func _pick_spawn_position() -> Vector2:
    var padding := 12.0
    var side := randi_range(0, 3)

    match side:
        0:
            return Vector2(randf_range(padding, ARENA_SIZE.x - padding), padding)
        1:
            return Vector2(ARENA_SIZE.x - padding, randf_range(padding, ARENA_SIZE.y - padding))
        2:
            return Vector2(randf_range(padding, ARENA_SIZE.x - padding), ARENA_SIZE.y - padding)
        _:
            return Vector2(padding, randf_range(padding, ARENA_SIZE.y - padding))

func _start_next_wave() -> void:
    current_wave += 1
    enemies_remaining_to_spawn = 3 + current_wave * 2
    enemies_alive = 0
    spawn_timer.wait_time = max(0.9 - float(current_wave - 1) * 0.08, 0.35)
    spawn_timer.start()
    _show_banner("WAVE %d" % current_wave)
    _update_ui()

func _on_wave_cleared() -> void:
    player.recover(1)
    spawn_timer.stop()
    _show_banner("WAVE %d CLEAR" % current_wave)
    await get_tree().create_timer(1.2).timeout

    if game_over:
        return

    _start_next_wave()

func _show_banner(text: String) -> void:
    banner_label.text = text
    banner_time_remaining = WAVE_BANNER_TIME

func _build_enemy_config() -> Dictionary:
    return {
        "move_speed": 38.0 + current_wave * 4.0,
        "max_health": 1 + floori(current_wave / 2.0),
        "touch_damage": 1,
        "contact_cooldown": max(0.75 - current_wave * 0.03, 0.4)
    }
