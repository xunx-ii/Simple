class_name BulletController
extends Node2D

const DEFAULT_RANGE := 320.0
const DEFAULT_DAMAGE := 1
const DEFAULT_WIDTH := 1.5
const DEFAULT_FLASH_DURATION := 0.06
const DEFAULT_COLLISION_MASK := 10
const DEFAULT_COLOR := Color(1.0, 0.894118, 0.345098, 0.95)
const DEFAULT_VISUAL_SPEED := 7200.0

var direction: Vector2 = Vector2.RIGHT
var max_range: float = DEFAULT_RANGE
var damage: int = DEFAULT_DAMAGE
var flash_duration: float = DEFAULT_FLASH_DURATION
var remaining_flash_time: float = DEFAULT_FLASH_DURATION
var visual_speed: float = DEFAULT_VISUAL_SPEED
var travel_duration: float = 0.01
var travel_elapsed: float = 0.0
var beam_target_local: Vector2 = Vector2.ZERO
var collision_mask_bits: int = DEFAULT_COLLISION_MASK
var beam_color: Color = DEFAULT_COLOR
var impact_color: Color = DEFAULT_COLOR
var beam_width: float = DEFAULT_WIDTH
var can_hit_player: bool = false
var can_hit_enemies: bool = true
var can_hit_covers: bool = true

@onready var trail: Line2D = $Trail

func _ready() -> void:
    _apply_visuals()
    _fire_hitscan()

func _process(delta: float) -> void:
    if travel_elapsed < travel_duration:
        travel_elapsed = min(travel_elapsed + delta, travel_duration)
        var travel_ratio: float = travel_elapsed / travel_duration if travel_duration > 0.0 else 1.0
        trail.points = PackedVector2Array([Vector2.ZERO, beam_target_local * travel_ratio])

        if travel_elapsed < travel_duration:
            return

    remaining_flash_time = max(remaining_flash_time - delta, 0.0)
    if remaining_flash_time <= 0.0:
        queue_free()
        return

    var alpha_ratio: float = remaining_flash_time / flash_duration if flash_duration > 0.0 else 0.0
    var current_color := beam_color
    current_color.a *= alpha_ratio
    trail.default_color = current_color

func setup(move_direction: Vector2, _rect: Rect2, config: Dictionary = {}) -> void:
    direction = move_direction.normalized() if move_direction != Vector2.ZERO else Vector2.RIGHT
    max_range = config.get("range", DEFAULT_RANGE)
    damage = config.get("damage", DEFAULT_DAMAGE)
    flash_duration = config.get("flash_duration", DEFAULT_FLASH_DURATION)
    remaining_flash_time = flash_duration
    visual_speed = config.get("visual_speed", DEFAULT_VISUAL_SPEED)
    travel_duration = 0.01
    travel_elapsed = 0.0
    beam_target_local = Vector2.ZERO
    collision_mask_bits = config.get("collision_mask", DEFAULT_COLLISION_MASK)
    beam_color = config.get("color", DEFAULT_COLOR)
    impact_color = config.get("impact_color", beam_color)
    beam_width = config.get("width", DEFAULT_WIDTH)
    can_hit_player = config.get("can_hit_player", false)
    can_hit_enemies = config.get("can_hit_enemies", true)
    can_hit_covers = config.get("can_hit_covers", true)

    if is_node_ready():
        _apply_visuals()
        _fire_hitscan()

func _fire_hitscan() -> void:
    var hit_position: Vector2 = global_position + direction * max_range
    var query := PhysicsRayQueryParameters2D.create(global_position, hit_position)
    query.collision_mask = collision_mask_bits
    var hit := get_world_2d().direct_space_state.intersect_ray(query)

    if not hit.is_empty():
        hit_position = hit.get("position", hit_position)
        _spawn_hit_spark(hit_position, hit.get("normal", -direction))
        _apply_hit(hit.get("collider"))

    beam_target_local = hit_position - global_position
    travel_duration = max(beam_target_local.length() / max(visual_speed, 1.0), 0.01)
    trail.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])

func _apply_hit(collider_variant: Variant) -> void:
    var collider := collider_variant as Node
    if collider == null:
        return

    if can_hit_enemies and collider.is_in_group("enemies") and collider.has_method("take_damage"):
        collider.take_damage(damage, direction)
        return

    if can_hit_player and collider.is_in_group("player") and collider.has_method("take_hit"):
        collider.take_hit(global_position, damage)
        return

    if can_hit_covers and collider.is_in_group("covers") and collider.has_method("take_damage"):
        collider.take_damage(damage, direction)

func _apply_visuals() -> void:
    trail.width = beam_width
    trail.default_color = beam_color

func _spawn_hit_spark(hit_position: Vector2, hit_normal: Vector2) -> void:
    var world_controller := get_tree().get_first_node_in_group("world_controller")
    if world_controller == null or not world_controller.has_method("spawn_hit_spark"):
        return

    world_controller.spawn_hit_spark(hit_position, hit_normal, {"color": impact_color})
