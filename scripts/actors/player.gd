class_name PlayerController
extends CharacterBody2D

signal shoot_requested(origin: Vector2, direction: Vector2)
signal health_changed(current_health: int)
signal defeated

const PLAYER_COLOR := Color(0.360784, 0.870588, 1.0, 1.0)
const HIT_FLASH_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const MOVE_SPEED := 88.0
const SHOOT_COOLDOWN := 0.18
const HIT_INVULNERABILITY := 0.6
const DASH_SPEED := 200.0
const DASH_DURATION := 0.12
const DASH_COOLDOWN := 1.0
const MAX_HEALTH := 5
const BODY_MARGIN := 8.0

var arena_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(320.0, 180.0))
var aim_direction: Vector2 = Vector2.RIGHT
var current_health: int = MAX_HEALTH
var shoot_cooldown_remaining: float = 0.0
var hit_invulnerability_remaining: float = 0.0
var dash_time_remaining: float = 0.0
var dash_cooldown_remaining: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT
var is_dead: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
    add_to_group("player")
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    health_changed.emit(current_health)

func _physics_process(delta: float) -> void:
    if is_dead:
        velocity = Vector2.ZERO
        return

    shoot_cooldown_remaining = max(shoot_cooldown_remaining - delta, 0.0)
    hit_invulnerability_remaining = max(hit_invulnerability_remaining - delta, 0.0)
    dash_time_remaining = max(dash_time_remaining - delta, 0.0)
    dash_cooldown_remaining = max(dash_cooldown_remaining - delta, 0.0)

    var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    _update_aim_direction()

    if Input.is_action_just_pressed("dash") and dash_cooldown_remaining <= 0.0:
        _start_dash(input_vector)

    if dash_time_remaining > 0.0:
        velocity = dash_direction * DASH_SPEED
    else:
        velocity = input_vector * MOVE_SPEED

    move_and_slide()

    _clamp_to_arena()
    _update_visuals()

    if Input.is_action_pressed("shoot") and shoot_cooldown_remaining <= 0.0:
        shoot_cooldown_remaining = SHOOT_COOLDOWN
        shoot_requested.emit(global_position + aim_direction * 10.0, aim_direction)

func configure_arena(rect: Rect2) -> void:
    arena_rect = rect
    _clamp_to_arena()

    camera.limit_left = int(rect.position.x)
    camera.limit_top = int(rect.position.y)
    camera.limit_right = int(rect.end.x)
    camera.limit_bottom = int(rect.end.y)
    camera.reset_smoothing()

func take_hit(source_position: Vector2, damage: int = 1) -> void:
    if is_dead or hit_invulnerability_remaining > 0.0 or dash_time_remaining > 0.0:
        return

    current_health = max(current_health - max(damage, 1), 0)
    hit_invulnerability_remaining = HIT_INVULNERABILITY

    var push_direction := (global_position - source_position).normalized()
    if push_direction == Vector2.ZERO:
        push_direction = Vector2.UP

    global_position += push_direction * 8.0
    _clamp_to_arena()
    health_changed.emit(current_health)

    if current_health == 0:
        is_dead = true
        collision_layer = 0
        collision_mask = 0
        visible = false
        defeated.emit()

func _update_aim_direction() -> void:
    var mouse_direction := get_global_mouse_position() - global_position

    if mouse_direction.length_squared() > 1.0:
        aim_direction = mouse_direction.normalized()
    elif velocity.length_squared() > 0.01:
        aim_direction = velocity.normalized()

func _clamp_to_arena() -> void:
    global_position = global_position.clamp(
        arena_rect.position + Vector2.ONE * BODY_MARGIN,
        arena_rect.end - Vector2.ONE * BODY_MARGIN
    )

func _update_visuals() -> void:
    if hit_invulnerability_remaining > 0.0 and int(hit_invulnerability_remaining * 20.0) % 2 == 0:
        sprite.modulate = HIT_FLASH_COLOR
        sprite.scale = Vector2.ONE
        return

    sprite.scale = Vector2.ONE * (1.18 if dash_time_remaining > 0.0 else 1.0)
    sprite.modulate = PLAYER_COLOR
    sprite.rotation = aim_direction.angle()

func recover(amount: int) -> void:
    if amount <= 0 or is_dead:
        return

    current_health = min(current_health + amount, MAX_HEALTH)
    health_changed.emit(current_health)

func is_dash_ready() -> bool:
    return dash_cooldown_remaining <= 0.0

func get_dash_ratio() -> float:
    return clampf(1.0 - dash_cooldown_remaining / DASH_COOLDOWN, 0.0, 1.0)

func get_dash_cooldown_remaining() -> float:
    return dash_cooldown_remaining

func _start_dash(input_vector: Vector2) -> void:
    dash_direction = input_vector if input_vector.length_squared() > 0.0 else aim_direction
    if dash_direction == Vector2.ZERO:
        dash_direction = Vector2.RIGHT

    dash_direction = dash_direction.normalized()
    dash_time_remaining = DASH_DURATION
    dash_cooldown_remaining = DASH_COOLDOWN
