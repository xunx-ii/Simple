class_name EnemyController
extends CharacterBody2D

signal defeated

const ENEMY_COLOR := Color(1.0, 0.411765, 0.45098, 1.0)
const HIT_FLASH_COLOR := Color(1.0, 0.894118, 0.345098, 1.0)
const CONTACT_DISTANCE := 12.0
const DEFAULT_MOVE_SPEED := 42.0
const DEFAULT_CONTACT_COOLDOWN := 0.8
const DEFAULT_MAX_HEALTH := 2
const BODY_MARGIN := 8.0

var arena_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(320.0, 180.0))
var target: CharacterBody2D
var move_speed: float = DEFAULT_MOVE_SPEED
var max_health: int = DEFAULT_MAX_HEALTH
var touch_damage: int = 1
var current_health: int = DEFAULT_MAX_HEALTH
var contact_cooldown_remaining: float = 0.0
var hit_flash_remaining: float = 0.0
var contact_cooldown_duration: float = DEFAULT_CONTACT_COOLDOWN

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
    add_to_group("enemies")
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    current_health = max_health
    _sync_size_with_health()

func _physics_process(delta: float) -> void:
    contact_cooldown_remaining = max(contact_cooldown_remaining - delta, 0.0)
    hit_flash_remaining = max(hit_flash_remaining - delta, 0.0)

    if not is_instance_valid(target) or not target.visible:
        velocity = Vector2.ZERO
        _update_visuals()
        return

    var to_target := target.global_position - global_position
    var distance_to_target := to_target.length()

    if distance_to_target > 1.0:
        velocity = to_target.normalized() * move_speed
    else:
        velocity = Vector2.ZERO

    move_and_slide()
    _clamp_to_arena()

    if distance_to_target <= CONTACT_DISTANCE and contact_cooldown_remaining <= 0.0:
        if target.has_method("take_hit"):
            target.take_hit(global_position, touch_damage)
        contact_cooldown_remaining = contact_cooldown_duration

    _update_visuals()

func setup(target_node: CharacterBody2D, rect: Rect2, config: Dictionary = {}) -> void:
    target = target_node
    arena_rect = rect
    move_speed = config.get("move_speed", DEFAULT_MOVE_SPEED)
    max_health = config.get("max_health", DEFAULT_MAX_HEALTH)
    touch_damage = config.get("touch_damage", 1)
    contact_cooldown_duration = config.get("contact_cooldown", DEFAULT_CONTACT_COOLDOWN)
    current_health = max_health
    if is_node_ready():
        _sync_size_with_health()

func take_damage(amount: int, from_direction: Vector2) -> void:
    if amount <= 0:
        return

    current_health = max(current_health - amount, 0)
    hit_flash_remaining = 0.12

    if from_direction != Vector2.ZERO:
        global_position += from_direction.normalized() * 6.0
        _clamp_to_arena()

    if current_health == 0:
        defeated.emit()
        queue_free()

func _clamp_to_arena() -> void:
    global_position = global_position.clamp(
        arena_rect.position + Vector2.ONE * BODY_MARGIN,
        arena_rect.end - Vector2.ONE * BODY_MARGIN
    )

func _update_visuals() -> void:
    if hit_flash_remaining > 0.0:
        sprite.modulate = HIT_FLASH_COLOR
        return

    sprite.modulate = ENEMY_COLOR

func _sync_size_with_health() -> void:
    var visual_scale := 1.0 + float(max_health - 1) * 0.16
    sprite.scale = Vector2.ONE * visual_scale
