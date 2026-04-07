class_name EnemyController
extends "res://scripts/actors/enemy_base.gd"

const WANDER_COLOR := Color(0.686275, 0.403922, 0.482353, 1.0)
const PATROL_COLOR := Color(0.933333, 0.458824, 0.466667, 1.0)
const ALERT_COLOR := Color(1.0, 0.745098, 0.290196, 1.0)
const CHASE_COLOR := Color(1.0, 0.286275, 0.341176, 1.0)
const ATTACK_COLOR := Color(1.0, 0.141176, 0.141176, 1.0)

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
