class_name EnemyController
extends CharacterBody2D

signal defeated

enum State { WANDER, PATROL, ALERT, CHASE, ATTACK }

const WANDER_COLOR := Color(0.686275, 0.403922, 0.482353, 1.0)
const PATROL_COLOR := Color(0.933333, 0.458824, 0.466667, 1.0)
const ALERT_COLOR := Color(1.0, 0.745098, 0.290196, 1.0)
const CHASE_COLOR := Color(1.0, 0.286275, 0.341176, 1.0)
const ATTACK_COLOR := Color(1.0, 0.141176, 0.141176, 1.0)
const HIT_FLASH_COLOR := Color(1.0, 0.968627, 0.737255, 1.0)
const DEFAULT_MOVE_SPEED := 42.0
const DEFAULT_MAX_HEALTH := 2
const DEFAULT_ATTACK_COOLDOWN := 0.8
const DEFAULT_SIGHT_RANGE := 176.0
const DEFAULT_ATTACK_RANGE := 20.0
const DEFAULT_PATROL_RADIUS := 112.0
const DEFAULT_CHASE_SPEED_MULTIPLIER := 1.22
const WANDER_SPEED_MULTIPLIER := 0.62
const PATROL_SPEED_MULTIPLIER := 0.82
const BODY_MARGIN := 8.0

var arena_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))
var target: CharacterBody2D
var world_controller: Node
var current_state: int = State.WANDER
var state_initialized: bool = false
var home_position: Vector2 = Vector2.ZERO
var movement_target: Vector2 = Vector2.ZERO
var last_seen_position: Vector2 = Vector2.ZERO
var patrol_points: Array = []
var patrol_index: int = 0
var navigation_path: PackedVector2Array = PackedVector2Array()
var navigation_index: int = 0
var move_speed: float = DEFAULT_MOVE_SPEED
var max_health: int = DEFAULT_MAX_HEALTH
var current_health: int = DEFAULT_MAX_HEALTH
var touch_damage: int = 1
var attack_cooldown_duration: float = DEFAULT_ATTACK_COOLDOWN
var attack_cooldown_remaining: float = 0.0
var sight_range: float = DEFAULT_SIGHT_RANGE
var attack_range: float = DEFAULT_ATTACK_RANGE
var patrol_radius: float = DEFAULT_PATROL_RADIUS
var chase_speed_multiplier: float = DEFAULT_CHASE_SPEED_MULTIPLIER
var hit_flash_remaining: float = 0.0
var state_timer: float = 0.0
var path_refresh_remaining: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
    add_to_group("enemies")
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

    if home_position == Vector2.ZERO:
        home_position = global_position
        last_seen_position = home_position

    if patrol_points.is_empty():
        _build_patrol_points()

    current_health = max_health
    _sync_size_with_health()

    if not state_initialized:
        _enter_state(State.WANDER)

func _physics_process(delta: float) -> void:
    attack_cooldown_remaining = max(attack_cooldown_remaining - delta, 0.0)
    hit_flash_remaining = max(hit_flash_remaining - delta, 0.0)
    state_timer = max(state_timer - delta, 0.0)
    path_refresh_remaining = max(path_refresh_remaining - delta, 0.0)

    if not is_instance_valid(target) or not target.visible:
        _process_without_target(delta)
        _update_visuals()
        return

    var distance_to_target: float = global_position.distance_to(target.global_position)
    var can_see_target: bool = _can_see_target(distance_to_target)

    if can_see_target:
        last_seen_position = target.global_position

    match current_state:
        State.WANDER:
            _process_wander(delta, can_see_target, distance_to_target)
        State.PATROL:
            _process_patrol(delta, can_see_target, distance_to_target)
        State.ALERT:
            _process_alert(can_see_target, distance_to_target)
        State.CHASE:
            _process_chase(delta, can_see_target, distance_to_target)
        State.ATTACK:
            _process_attack(can_see_target, distance_to_target)

    _update_visuals()

func setup(target_node: CharacterBody2D, rect: Rect2, config: Dictionary = {}, world_node: Node = null) -> void:
    target = target_node
    world_controller = world_node
    arena_rect = rect
    home_position = global_position
    last_seen_position = home_position
    move_speed = config.get("move_speed", DEFAULT_MOVE_SPEED)
    max_health = config.get("max_health", DEFAULT_MAX_HEALTH)
    current_health = max_health
    touch_damage = config.get("touch_damage", 1)
    attack_cooldown_duration = config.get("attack_cooldown", DEFAULT_ATTACK_COOLDOWN)
    sight_range = config.get("sight_range", DEFAULT_SIGHT_RANGE)
    attack_range = config.get("attack_range", DEFAULT_ATTACK_RANGE)
    patrol_radius = config.get("patrol_radius", DEFAULT_PATROL_RADIUS)
    chase_speed_multiplier = config.get("chase_speed_multiplier", DEFAULT_CHASE_SPEED_MULTIPLIER)
    patrol_points.clear()
    _build_patrol_points()

    if is_node_ready():
        _sync_size_with_health()
        _enter_state(State.WANDER)

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
        return

    if current_state != State.CHASE and current_state != State.ATTACK:
        _enter_state(State.ALERT)

func _process_without_target(delta: float) -> void:
    match current_state:
        State.WANDER:
            _move_to_point(movement_target, move_speed * WANDER_SPEED_MULTIPLIER, delta)
            if state_timer <= 0.0 or global_position.distance_to(movement_target) <= 8.0:
                _enter_state(State.PATROL)
        State.PATROL:
            _move_to_point(movement_target, move_speed * PATROL_SPEED_MULTIPLIER, delta)
            if global_position.distance_to(movement_target) <= 8.0:
                _advance_patrol_point()
        _:
            velocity = Vector2.ZERO

func _process_wander(delta: float, can_see_target: bool, distance_to_target: float) -> void:
    if can_see_target:
        if distance_to_target <= attack_range:
            _enter_state(State.ATTACK)
            return

        _enter_state(State.ALERT)
        return

    var reached_target: bool = _move_to_point(movement_target, move_speed * WANDER_SPEED_MULTIPLIER, delta)
    if reached_target or state_timer <= 0.0:
        _enter_state(State.PATROL)

func _process_patrol(delta: float, can_see_target: bool, distance_to_target: float) -> void:
    if can_see_target:
        if distance_to_target <= attack_range:
            _enter_state(State.ATTACK)
            return

        _enter_state(State.ALERT)
        return

    if patrol_points.is_empty():
        _build_patrol_points()

    var reached_target: bool = _move_to_point(movement_target, move_speed * PATROL_SPEED_MULTIPLIER, delta)
    if reached_target:
        _advance_patrol_point()

func _process_alert(can_see_target: bool, distance_to_target: float) -> void:
    velocity = Vector2.ZERO
    if can_see_target:
        sprite.rotation = (target.global_position - global_position).angle()

        if distance_to_target <= attack_range:
            _enter_state(State.ATTACK)
            return
    elif state_timer <= 0.0:
        _enter_state(State.PATROL)
        return

    if state_timer <= 0.0:
        _enter_state(State.CHASE)

func _process_chase(delta: float, can_see_target: bool, distance_to_target: float) -> void:
    if can_see_target:
        last_seen_position = target.global_position
        state_timer = 1.6
    elif state_timer <= 0.0:
        _enter_state(State.PATROL)
        return

    if distance_to_target <= attack_range and can_see_target:
        _enter_state(State.ATTACK)
        return

    var chase_destination: Vector2 = target.global_position if can_see_target else last_seen_position
    var reached_destination: bool = _move_to_point(chase_destination, move_speed * chase_speed_multiplier, delta)
    if reached_destination and not can_see_target and global_position.distance_to(last_seen_position) <= 12.0:
        _enter_state(State.PATROL)

func _process_attack(can_see_target: bool, distance_to_target: float) -> void:
    velocity = Vector2.ZERO

    if not can_see_target:
        _enter_state(State.ALERT)
        return

    sprite.rotation = (target.global_position - global_position).angle()

    if distance_to_target > attack_range + 10.0:
        _enter_state(State.CHASE)
        return

    if attack_cooldown_remaining <= 0.0 and target.has_method("take_hit"):
        target.take_hit(global_position, touch_damage)
        attack_cooldown_remaining = attack_cooldown_duration

func _move_to_point(destination: Vector2, speed: float, _delta: float) -> bool:
    if global_position.distance_to(destination) <= 8.0:
        velocity = Vector2.ZERO
        return true

    if path_refresh_remaining <= 0.0 or navigation_path.is_empty():
        _request_path_to(destination)

    var next_point: Vector2 = _get_next_path_point(destination)
    var direction: Vector2 = next_point - global_position
    if direction.length_squared() <= 0.5:
        velocity = Vector2.ZERO
        return true

    velocity = direction.normalized() * speed
    move_and_slide()
    _clamp_to_arena()

    if velocity.length_squared() > 0.01:
        sprite.rotation = velocity.angle()

    return global_position.distance_to(destination) <= 10.0

func _request_path_to(destination: Vector2) -> void:
    path_refresh_remaining = 0.35
    navigation_index = 0

    if world_controller != null and world_controller.has_method("request_path"):
        navigation_path = world_controller.request_path(global_position, destination)
    else:
        navigation_path = PackedVector2Array([destination])

    if not navigation_path.is_empty() and global_position.distance_to(navigation_path[0]) <= 8.0:
        navigation_index = 1

func _get_next_path_point(destination: Vector2) -> Vector2:
    if navigation_path.is_empty():
        return destination

    while navigation_index < navigation_path.size():
        var path_point: Vector2 = navigation_path[navigation_index]
        if global_position.distance_to(path_point) <= 8.0:
            navigation_index += 1
            continue

        return path_point

    return destination

func _build_patrol_points() -> void:
    patrol_points.clear()
    patrol_points.append(home_position)

    for _index in range(3):
        patrol_points.append(_pick_random_patrol_point())

    patrol_index = 0
    movement_target = patrol_points[0]

func _pick_random_patrol_point() -> Vector2:
    if world_controller != null and world_controller.has_method("find_walkable_point_near"):
        return world_controller.find_walkable_point_near(home_position, patrol_radius)

    for _attempt in range(12):
        var candidate := home_position + Vector2(
            randf_range(-patrol_radius, patrol_radius),
            randf_range(-patrol_radius, patrol_radius)
        )
        if arena_rect.has_point(candidate):
            return candidate

    return home_position

func _advance_patrol_point() -> void:
    if patrol_points.is_empty():
        _build_patrol_points()

    patrol_index = (patrol_index + 1) % patrol_points.size()
    movement_target = patrol_points[patrol_index]
    _request_path_to(movement_target)

func _enter_state(new_state: int) -> void:
    if state_initialized and current_state == new_state:
        return

    current_state = new_state
    state_initialized = true
    navigation_path = PackedVector2Array()
    navigation_index = 0
    path_refresh_remaining = 0.0

    match current_state:
        State.WANDER:
            state_timer = randf_range(0.8, 1.7)
            movement_target = _pick_random_patrol_point()
        State.PATROL:
            state_timer = 0.0
            if patrol_points.is_empty():
                _build_patrol_points()
            movement_target = patrol_points[patrol_index]
        State.ALERT:
            state_timer = 0.5
            velocity = Vector2.ZERO
        State.CHASE:
            state_timer = 1.8
        State.ATTACK:
            state_timer = 0.0
            velocity = Vector2.ZERO

func _can_see_target(distance_to_target: float) -> bool:
    if distance_to_target > sight_range:
        return false

    var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position)
    query.exclude = [get_rid()]
    query.collision_mask = 9

    var hit := get_world_2d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return false

    return hit.get("collider") == target

func _clamp_to_arena() -> void:
    global_position = global_position.clamp(
        arena_rect.position + Vector2.ONE * BODY_MARGIN,
        arena_rect.end - Vector2.ONE * BODY_MARGIN
    )

func _update_visuals() -> void:
    if hit_flash_remaining > 0.0:
        sprite.modulate = HIT_FLASH_COLOR
        return

    match current_state:
        State.WANDER:
            sprite.modulate = WANDER_COLOR
        State.PATROL:
            sprite.modulate = PATROL_COLOR
        State.ALERT:
            sprite.modulate = ALERT_COLOR
        State.CHASE:
            sprite.modulate = CHASE_COLOR
        State.ATTACK:
            sprite.modulate = ATTACK_COLOR

func _sync_size_with_health() -> void:
    var visual_scale: float = 1.0 + float(max_health - 1) * 0.12
    sprite.scale = Vector2.ONE * visual_scale
