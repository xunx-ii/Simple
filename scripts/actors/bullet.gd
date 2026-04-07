class_name BulletController
extends Node2D

const DEFAULT_RANGE := 320.0
const DEFAULT_DAMAGE := 1
const DEFAULT_WIDTH := 1.5
const DEFAULT_FLASH_DURATION := 0.06
const DEFAULT_COLLISION_MASK := 10
const DEFAULT_COLOR := Color(1.0, 0.894118, 0.345098, 0.95)
const DEFAULT_VISUAL_SPEED := 7200.0
const DEFAULT_IMPACT_RADIUS := 10.0

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
var use_target_area_damage: bool = false
var impact_radius: float = DEFAULT_IMPACT_RADIUS
var target_position: Vector2 = Vector2.ZERO

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
    use_target_area_damage = config.get("use_target_area_damage", false)
    impact_radius = config.get("impact_radius", DEFAULT_IMPACT_RADIUS)
    target_position = config.get("target_position", global_position + direction * max_range)

    if is_node_ready():
        _apply_visuals()
        _fire_hitscan()

func _fire_hitscan() -> void:
    if use_target_area_damage:
        _fire_target_area_damage()
        return

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

func _fire_target_area_damage() -> void:
    var clamped_target: Vector2 = _get_clamped_target_position()
    var path_result: Dictionary = _apply_path_damage_to_target(clamped_target)
    var impact_position: Vector2 = path_result.get("impact_position", clamped_target)
    var impact_normal: Vector2 = path_result.get("impact_normal", (impact_position - global_position).normalized())
    var hit_instance_ids: Dictionary = path_result.get("hit_instance_ids", {})
    var blocked: bool = bool(path_result.get("blocked", false))

    if not blocked:
        var area_collider: Node = _find_target_area_collider(impact_position, hit_instance_ids)
        if area_collider != null:
            _apply_hit(area_collider)

    _spawn_hit_spark(impact_position, impact_normal)
    beam_target_local = impact_position - global_position
    travel_duration = max(beam_target_local.length() / max(visual_speed, 1.0), 0.01)
    trail.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])

func _get_clamped_target_position() -> Vector2:
    var target_vector: Vector2 = target_position - global_position
    if target_vector.length_squared() <= 1.0:
        return global_position + direction * max_range

    if target_vector.length() <= max_range:
        return target_position

    return global_position + target_vector.normalized() * max_range

func _apply_path_damage_to_target(target_world_position: Vector2) -> Dictionary:
    var path_direction: Vector2 = (target_world_position - global_position).normalized()
    if path_direction == Vector2.ZERO:
        path_direction = direction

    var ray_start: Vector2 = global_position
    var excluded_colliders: Array = []
    var hit_instance_ids: Dictionary = {}
    var impact_position: Vector2 = target_world_position
    var impact_normal: Vector2 = (impact_position - global_position).normalized()
    var blocked: bool = false

    for _index in range(12):
        var query := PhysicsRayQueryParameters2D.create(ray_start, target_world_position)
        query.collision_mask = collision_mask_bits
        query.exclude = excluded_colliders
        query.collide_with_bodies = true
        query.collide_with_areas = false

        var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
        if hit.is_empty():
            break

        var collider: Node = hit.get("collider") as Node
        var hit_position: Vector2 = hit.get("position", target_world_position)
        if collider == null:
            ray_start = hit_position + path_direction * 0.5
            continue

        excluded_colliders.append(collider)

        if can_hit_enemies and collider.is_in_group("enemies") and collider.has_method("take_damage"):
            var instance_id: int = collider.get_instance_id()
            if not hit_instance_ids.has(instance_id):
                _apply_hit(collider)
                hit_instance_ids[instance_id] = true

            ray_start = hit_position + path_direction * 0.5
            continue

        if _can_hit_collider(collider):
            _apply_hit(collider)
            impact_position = hit_position
            impact_normal = hit.get("normal", -path_direction)
            blocked = true
            break

        ray_start = hit_position + path_direction * 0.5

    return {
        "impact_position": impact_position,
        "impact_normal": impact_normal,
        "blocked": blocked,
        "hit_instance_ids": hit_instance_ids
    }

func _find_target_area_collider(impact_position: Vector2, ignored_instance_ids: Dictionary = {}) -> Node:
    var impact_shape := CircleShape2D.new()
    impact_shape.radius = impact_radius

    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = impact_shape
    query.transform = Transform2D(0.0, impact_position)
    query.collision_mask = collision_mask_bits
    query.collide_with_bodies = true
    query.collide_with_areas = false

    var results: Array = get_world_2d().direct_space_state.intersect_shape(query)
    var best_collider: Node = null
    var best_distance: float = INF

    for result_variant in results:
        if typeof(result_variant) != TYPE_DICTIONARY:
            continue

        var result: Dictionary = result_variant
        var collider: Node = result.get("collider") as Node
        if not _can_hit_collider(collider):
            continue
        if ignored_instance_ids.has(collider.get_instance_id()):
            continue

        var sample_position: Vector2 = impact_position
        var collider_node := collider as Node2D
        if collider_node != null:
            sample_position = collider_node.global_position

        var distance_to_impact: float = sample_position.distance_squared_to(impact_position)
        if distance_to_impact >= best_distance:
            continue

        best_distance = distance_to_impact
        best_collider = collider

    return best_collider

func _can_hit_collider(collider: Node) -> bool:
    if collider == null:
        return false

    if can_hit_enemies and collider.is_in_group("enemies") and collider.has_method("take_damage"):
        return true

    if can_hit_player and collider.is_in_group("player") and collider.has_method("take_hit"):
        return true

    if can_hit_covers and collider.is_in_group("covers") and collider.has_method("take_damage"):
        return true

    return false

func _apply_hit(collider_variant: Variant) -> void:
    var collider := collider_variant as Node
    if not _can_hit_collider(collider):
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
