class_name EnemyController
extends "res://scripts/actors/enemy_base.gd"

const WANDER_COLOR := Color(0.686275, 0.403922, 0.482353, 1.0)
const PATROL_COLOR := Color(0.933333, 0.458824, 0.466667, 1.0)
const ALERT_COLOR := Color(1.0, 0.745098, 0.290196, 1.0)
const CHASE_COLOR := Color(1.0, 0.286275, 0.341176, 1.0)
const ATTACK_COLOR := Color(1.0, 0.141176, 0.141176, 1.0)

func _perform_attack() -> void:
    if world_controller == null or not world_controller.has_method("spawn_bullet"):
        return

    var shot_direction: Vector2 = (target.global_position - global_position).normalized()
    if shot_direction == Vector2.ZERO:
        shot_direction = facing_direction

    world_controller.spawn_bullet(
        global_position + shot_direction * 12.0,
        shot_direction,
        {
            "range": attack_range,
            "damage": touch_damage,
            "collision_mask": 9,
            "color": Color(1.0, 0.8, 0.45, 0.95),
            "width": 2.0,
            "flash_duration": 0.05,
            "visual_speed": 7600.0,
            "can_hit_player": true,
            "can_hit_enemies": false,
            "can_hit_covers": true
        }
    )

func _get_state_color(state: int) -> Color:
    match state:
        State.WANDER:
            return WANDER_COLOR
        State.PATROL:
            return PATROL_COLOR
        State.ALERT:
            return ALERT_COLOR
        State.CHASE:
            return CHASE_COLOR
        State.ATTACK:
            return ATTACK_COLOR
        _:
            return Color.WHITE
