class_name WeaponBase
extends RefCounted

var weapon_name: String = "武器"
var muzzle_distance: float = 10.0
var fire_interval: float = 0.12
var cooldown_remaining: float = 0.0
var recoil_strength: float = 0.0
var recoil_per_shot: float = 0.35
var max_recoil_strength: float = 3.5
var recoil_recovery_rate: float = 6.0
var recoil_recovery_delay: float = 0.12
var recoil_recovery_delay_remaining: float = 0.0
var aim_recoil_multiplier: float = 0.65
var aim_spread_multiplier: float = 0.55
var aim_visual_spread_multiplier: float = 0.7
var aim_player_kick_multiplier: float = 0.72
var aim_camera_shake_multiplier: float = 0.7
var crosshair_base_scale: float = 1.0
var crosshair_max_scale: float = 1.65
var is_aiming: bool = false

func update(delta: float, _trigger_pressed: bool, aiming: bool = false) -> void:
    is_aiming = aiming
    cooldown_remaining = max(cooldown_remaining - delta, 0.0)

    if recoil_recovery_delay_remaining > 0.0:
        recoil_recovery_delay_remaining = max(recoil_recovery_delay_remaining - delta, 0.0)
    elif recoil_strength > 0.0:
        recoil_strength = max(recoil_strength - recoil_recovery_rate * delta, 0.0)

func try_fire(origin: Vector2, direction: Vector2, target_position: Variant = null) -> Dictionary:
    if cooldown_remaining > 0.0 or direction == Vector2.ZERO:
        return {}

    cooldown_remaining = fire_interval
    recoil_recovery_delay_remaining = recoil_recovery_delay
    recoil_strength = min(recoil_strength + recoil_per_shot * _get_recoil_multiplier(), max_recoil_strength)
    return _build_fire_result(origin, direction.normalized(), target_position)

func get_recoil_ratio() -> float:
    if max_recoil_strength <= 0.0:
        return 0.0

    return clampf(recoil_strength / max_recoil_strength, 0.0, 1.0)

func get_crosshair_outer_scale() -> float:
    var visual_multiplier := _get_visual_spread_multiplier()
    return lerpf(crosshair_base_scale * visual_multiplier, crosshair_max_scale * visual_multiplier, get_recoil_ratio())

func _build_fire_result(origin: Vector2, direction: Vector2, target_position: Variant = null) -> Dictionary:
    return {
        "projectiles": [_build_projectile(origin, direction, target_position)],
        "player_kick": _get_player_kick() * _get_player_kick_multiplier(),
        "camera_shake": _get_camera_shake() * _get_camera_shake_multiplier()
    }

func _build_projectile(origin: Vector2, direction: Vector2, target_position: Variant = null) -> Dictionary:
    var spread_angle_radians: float = deg_to_rad(_sample_spread_degrees() * _get_spread_multiplier())
    var bullet_config: Dictionary = _build_bullet_config()
    var projectile_range: float = float(bullet_config.get("range", 320.0))
    var base_direction: Vector2 = direction
    var raw_target_vector: Vector2 = Vector2.ZERO
    var has_target_position: bool = target_position is Vector2
    if has_target_position:
        raw_target_vector = (target_position as Vector2) - origin
        if raw_target_vector.length_squared() > 1.0:
            base_direction = raw_target_vector.normalized()

    var shot_direction: Vector2 = base_direction.rotated(spread_angle_radians).normalized()
    var projectile_origin: Vector2 = origin + shot_direction * muzzle_distance
    if has_target_position:
        var target_distance: float = minf(raw_target_vector.length(), projectile_range)
        bullet_config["target_position"] = origin + shot_direction * target_distance

    return {
        "origin": projectile_origin,
        "direction": shot_direction,
        "config": bullet_config
    }

func _sample_spread_degrees() -> float:
    return 0.0

func _build_bullet_config() -> Dictionary:
    return {}

func _get_player_kick() -> float:
    return 0.0

func _get_camera_shake() -> float:
    return 0.0

func _get_recoil_multiplier() -> float:
    return aim_recoil_multiplier if is_aiming else 1.0

func _get_spread_multiplier() -> float:
    return aim_spread_multiplier if is_aiming else 1.0

func _get_visual_spread_multiplier() -> float:
    return aim_visual_spread_multiplier if is_aiming else 1.0

func _get_player_kick_multiplier() -> float:
    return aim_player_kick_multiplier if is_aiming else 1.0

func _get_camera_shake_multiplier() -> float:
    return aim_camera_shake_multiplier if is_aiming else 1.0
