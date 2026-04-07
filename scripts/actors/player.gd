class_name PlayerController
extends CharacterBody2D

const MachineGunWeaponScript = preload("res://scripts/weapons/machine_gun.gd")

signal shoot_requested(projectiles: Array)
signal health_changed(current_health: int)
signal hidden_hit_received(source_position: Vector2)
signal defeated

const PLAYER_COLOR := Color(0.360784, 0.870588, 1.0, 1.0)
const HIT_FLASH_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const MOVE_SPEED := 88.0
const AIM_MOVE_SPEED_MULTIPLIER := 0.58
const HIT_INVULNERABILITY := 0.6
const DASH_SPEED := 200.0
const DASH_DURATION := 0.12
const DASH_COOLDOWN := 1.0
const MAX_HEALTH := 100
const BODY_MARGIN := 8.0
const FIRE_KICK_RECOVERY := 20.0
const CAMERA_SHAKE_DECAY := 26.0
const MAX_CAMERA_SHAKE := 6.0
const MAX_SPRITE_KICK := 5.0
const VISION_CONE_DEGREES := 120.0
const CAMERA_WORLD_VIEW_RATIO := 0.5

var arena_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(320.0, 180.0))
var aim_direction: Vector2 = Vector2.RIGHT
var current_health: int = MAX_HEALTH
var hit_invulnerability_remaining: float = 0.0
var dash_time_remaining: float = 0.0
var dash_cooldown_remaining: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT
var is_aiming: bool = false
var is_dead: bool = false
var current_weapon
var sprite_kick_offset: Vector2 = Vector2.ZERO
var camera_shake_strength: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
    add_to_group("player")
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    current_weapon = MachineGunWeaponScript.new()
    var viewport := get_viewport()
    if viewport != null:
        viewport.size_changed.connect(_on_viewport_size_changed)
    _update_camera_view()
    health_changed.emit(current_health)

func _physics_process(delta: float) -> void:
    if is_dead:
        velocity = Vector2.ZERO
        _update_fire_feedback(delta)
        return

    hit_invulnerability_remaining = max(hit_invulnerability_remaining - delta, 0.0)
    dash_time_remaining = max(dash_time_remaining - delta, 0.0)
    dash_cooldown_remaining = max(dash_cooldown_remaining - delta, 0.0)

    var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var shoot_pressed: bool = Input.is_action_pressed("shoot")
    is_aiming = Input.is_action_pressed("aim") and not is_dead
    _update_aim_direction()
    _update_weapon(delta, shoot_pressed)

    if Input.is_action_just_pressed("dash") and dash_cooldown_remaining <= 0.0:
        _start_dash(input_vector)

    if dash_time_remaining > 0.0:
        velocity = dash_direction * DASH_SPEED
    else:
        var move_speed := MOVE_SPEED * (AIM_MOVE_SPEED_MULTIPLIER if is_aiming else 1.0)
        velocity = input_vector * move_speed

    move_and_slide()

    _clamp_to_arena()
    _update_fire_feedback(delta)
    _update_visuals()

func configure_arena(rect: Rect2) -> void:
    arena_rect = rect
    _clamp_to_arena()
    _update_camera_view()

func take_hit(source_position: Vector2, damage: int = 1) -> void:
    if is_dead or hit_invulnerability_remaining > 0.0 or dash_time_remaining > 0.0:
        return

    if not is_point_in_vision(source_position):
        hidden_hit_received.emit(source_position)

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
    sprite.position = sprite_kick_offset

    if hit_invulnerability_remaining > 0.0 and int(hit_invulnerability_remaining * 20.0) % 2 == 0:
        sprite.modulate = HIT_FLASH_COLOR
        sprite.scale = Vector2.ONE * (1.18 if dash_time_remaining > 0.0 else 1.0)
        return

    sprite.scale = Vector2.ONE * (1.18 if dash_time_remaining > 0.0 else 1.0)
    sprite.modulate = PLAYER_COLOR
    sprite.rotation = aim_direction.angle() + sprite_kick_offset.x * 0.015

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

func get_weapon_name() -> String:
    if current_weapon == null:
        return "UNARMED"

    return current_weapon.weapon_name

func get_crosshair_outer_scale() -> float:
    if current_weapon == null or not current_weapon.has_method("get_crosshair_outer_scale"):
        return 1.0

    return current_weapon.get_crosshair_outer_scale()

func is_in_aim_mode() -> bool:
    return is_aiming

func get_view_direction() -> Vector2:
    return aim_direction if aim_direction != Vector2.ZERO else Vector2.RIGHT

func get_vision_cone_degrees() -> float:
    return VISION_CONE_DEGREES

func get_camera_visible_world_size() -> Vector2:
    var viewport_size := get_viewport_rect().size
    var safe_zoom := Vector2(
        max(camera.zoom.x, 0.001),
        max(camera.zoom.y, 0.001)
    )
    return Vector2(
        viewport_size.x / safe_zoom.x,
        viewport_size.y / safe_zoom.y
    )

func is_point_in_vision(world_point: Vector2) -> bool:
    var to_point := world_point - global_position
    if to_point.length_squared() <= 1.0:
        return true

    var half_angle_cos: float = cos(deg_to_rad(VISION_CONE_DEGREES * 0.5))
    return get_view_direction().dot(to_point.normalized()) >= half_angle_cos

func _start_dash(input_vector: Vector2) -> void:
    dash_direction = input_vector if input_vector.length_squared() > 0.0 else aim_direction
    if dash_direction == Vector2.ZERO:
        dash_direction = Vector2.RIGHT

    dash_direction = dash_direction.normalized()
    dash_time_remaining = DASH_DURATION
    dash_cooldown_remaining = DASH_COOLDOWN

func _update_weapon(delta: float, shoot_pressed: bool) -> void:
    if current_weapon == null:
        return

    current_weapon.update(delta, shoot_pressed, is_aiming)

    if not shoot_pressed:
        return

    var fire_result: Dictionary = current_weapon.try_fire(global_position, aim_direction)
    if fire_result.is_empty():
        return

    _apply_fire_feedback(fire_result)
    shoot_requested.emit(fire_result.get("projectiles", []))

func _apply_fire_feedback(fire_result: Dictionary) -> void:
    var kickback: float = fire_result.get("player_kick", 0.0)
    var fire_direction: Vector2 = aim_direction if aim_direction != Vector2.ZERO else Vector2.RIGHT
    var side_direction := Vector2(-fire_direction.y, fire_direction.x) * randf_range(-0.4, 0.4)
    sprite_kick_offset += (-fire_direction * kickback) + side_direction
    sprite_kick_offset = sprite_kick_offset.limit_length(MAX_SPRITE_KICK)
    camera_shake_strength = min(camera_shake_strength + fire_result.get("camera_shake", 0.0), MAX_CAMERA_SHAKE)

func _update_fire_feedback(delta: float) -> void:
    sprite_kick_offset = sprite_kick_offset.lerp(Vector2.ZERO, clampf(delta * FIRE_KICK_RECOVERY, 0.0, 1.0))
    camera_shake_strength = max(camera_shake_strength - CAMERA_SHAKE_DECAY * delta, 0.0)

    if camera_shake_strength <= 0.0:
        camera.offset = Vector2.ZERO
        return

    camera.offset = Vector2(
        randf_range(-camera_shake_strength, camera_shake_strength),
        randf_range(-camera_shake_strength, camera_shake_strength)
    )

func _on_viewport_size_changed() -> void:
    _update_camera_view()

func _update_camera_view() -> void:
    if camera == null:
        return

    var viewport_size := get_viewport_rect().size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        return

    var zoom_factor := minf(
        viewport_size.x / max(arena_rect.size.x, 1.0),
        viewport_size.y / max(arena_rect.size.y, 1.0)
    )
    zoom_factor = maxf(zoom_factor, 0.001)
    zoom_factor /= CAMERA_WORLD_VIEW_RATIO

    camera.zoom = Vector2.ONE * zoom_factor
    camera.limit_left = int(arena_rect.position.x)
    camera.limit_top = int(arena_rect.position.y)
    camera.limit_right = int(arena_rect.end.x)
    camera.limit_bottom = int(arena_rect.end.y)
    camera.offset = Vector2.ZERO
    camera.reset_smoothing()
