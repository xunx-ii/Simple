class_name MachineGunWeapon
extends "res://scripts/weapons/weapon_base.gd"

const BASE_SPREAD_DEGREES := 0.7
const MAX_SPREAD_DEGREES := 6.0
const BULLET_COLOR := Color(1.0, 0.960784, 0.717647, 0.95)
const IMPACT_COLOR := Color(1.0, 0.878431, 0.533333, 0.95)

func _init() -> void:
    weapon_name = "机枪"
    muzzle_distance = 10.0
    fire_interval = 0.08
    recoil_per_shot = 0.48
    max_recoil_strength = 4.4
    recoil_recovery_rate = 7.6
    recoil_recovery_delay = 0.13
    aim_recoil_multiplier = 0.55
    aim_spread_multiplier = 0.4
    aim_visual_spread_multiplier = 0.52
    aim_player_kick_multiplier = 0.62
    aim_camera_shake_multiplier = 0.58
    crosshair_base_scale = 1.0
    crosshair_max_scale = 1.85

func _sample_spread_degrees() -> float:
    var current_spread: float = lerpf(BASE_SPREAD_DEGREES, MAX_SPREAD_DEGREES, get_recoil_ratio())
    return randf_range(-current_spread, current_spread)

func _build_bullet_config() -> Dictionary:
    return {
        "range": 400.0,
        "damage": 1,
        "collision_mask": 10,
        "use_target_area_damage": true,
        "impact_radius": 12.0,
        "color": BULLET_COLOR,
        "impact_color": IMPACT_COLOR,
        "width": 1.25,
        "flash_duration": 0.045,
        "visual_speed": 8400.0,
        "can_hit_player": false,
        "can_hit_enemies": true,
        "can_hit_covers": true
    }

func _get_player_kick() -> float:
    return lerpf(1.1, 2.2, get_recoil_ratio())

func _get_camera_shake() -> float:
    return lerpf(0.8, 1.7, get_recoil_ratio())
