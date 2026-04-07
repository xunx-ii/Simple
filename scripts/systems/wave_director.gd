class_name WaveDirector
extends RefCounted

const MAX_SIMULTANEOUS_ENEMIES := 12
const DEFAULT_BANNER_TIME := 1.8
const MELEE_SPAWN_RATIO := 0.8

var score: int = 0
var current_wave: int = 0
var enemies_alive: int = 0
var enemies_remaining_to_spawn: int = 0
var banner_time_remaining: float = 0.0
var banner_text: String = ""
var wave_clear_in_progress: bool = false

func should_spawn_enemy(game_over: bool) -> bool:
    if game_over:
        return false

    if enemies_remaining_to_spawn <= 0:
        return false

    return enemies_alive < MAX_SIMULTANEOUS_ENEMIES

func pick_enemy_type_is_melee() -> bool:
    return randf() < MELEE_SPAWN_RATIO

func register_enemy_spawned() -> void:
    enemies_alive += 1
    enemies_remaining_to_spawn = max(enemies_remaining_to_spawn - 1, 0)

func register_enemy_defeated() -> void:
    score += 1

func register_enemy_exited(game_over: bool) -> bool:
    enemies_alive = max(enemies_alive - 1, 0)

    if game_over:
        return false

    return enemies_alive == 0 and enemies_remaining_to_spawn == 0 and not wave_clear_in_progress

func start_next_wave(spawn_timer: Timer) -> void:
    wave_clear_in_progress = false
    current_wave += 1
    enemies_remaining_to_spawn = 4 + current_wave * 2
    enemies_alive = 0
    spawn_timer.wait_time = max(1.0 - float(current_wave - 1) * 0.08, 0.4)
    spawn_timer.start()
    set_banner("WAVE %d" % current_wave)

func begin_wave_clear(player_node: Node, spawn_timer: Timer) -> bool:
    if wave_clear_in_progress:
        return false

    wave_clear_in_progress = true

    if player_node != null and player_node.has_method("recover"):
        player_node.recover(1)

    if spawn_timer != null:
        spawn_timer.stop()

    set_banner("WAVE %d CLEAR" % current_wave)
    return true

func cancel_wave_clear() -> void:
    wave_clear_in_progress = false

func set_banner(text: String, duration: float = DEFAULT_BANNER_TIME) -> void:
    banner_text = text
    banner_time_remaining = duration

func update_banner(delta: float, game_over: bool) -> String:
    if banner_time_remaining > 0.0:
        banner_time_remaining = max(banner_time_remaining - delta, 0.0)
        if banner_time_remaining == 0.0 and not game_over:
            banner_text = ""

    return banner_text

func build_enemy_config(is_melee_enemy: bool) -> Dictionary:
    if is_melee_enemy:
        return {
            "move_speed": 43.0 + current_wave * 3.0,
            "max_health": max(2, 1 + floori(current_wave / 3.0)),
            "touch_damage": 1,
            "attack_cooldown": max(0.72 - current_wave * 0.025, 0.32),
            "sight_range": 232.0 + current_wave * 8.0,
            "attack_range": 22.0,
            "patrol_radius": 168.0 + current_wave * 10.0,
            "chase_speed_multiplier": 1.42 + current_wave * 0.02
        }

    return {
        "move_speed": 31.0 + current_wave * 2.2,
        "max_health": max(2, 1 + floori(current_wave / 2.0)),
        "touch_damage": 1,
        "attack_cooldown": max(1.15 - current_wave * 0.04, 0.6),
        "sight_range": 224.0 + current_wave * 8.0,
        "attack_range": 96.0 + current_wave * 3.0,
        "patrol_radius": 148.0 + current_wave * 8.0,
        "chase_speed_multiplier": 1.16 + current_wave * 0.015
    }
