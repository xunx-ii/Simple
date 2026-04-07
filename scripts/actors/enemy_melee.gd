class_name EnemyMeleeController
extends "res://scripts/actors/enemy_base.gd"

const WANDER_COLOR := Color(0.454902, 0.545098, 0.466667, 1.0)
const PATROL_COLOR := Color(0.623529, 0.729412, 0.513725, 1.0)
const ALERT_COLOR := Color(0.92549, 0.760784, 0.290196, 1.0)
const CHASE_COLOR := Color(0.996078, 0.45098, 0.211765, 1.0)
const ATTACK_COLOR := Color(1.0, 0.25098, 0.172549, 1.0)

func _on_target_spotted() -> void:
    target_locked = true

func _get_detected_state(distance_to_target: float) -> int:
    return State.ATTACK if distance_to_target <= attack_range else State.CHASE

func _get_alert_followup_state(_target_visible: bool, can_engage_target: bool) -> int:
    return State.CHASE if can_engage_target else State.PATROL

func _get_attack_lost_target_state() -> int:
    return State.CHASE if target_locked else State.PATROL

func _get_damage_reaction_state() -> int:
    return State.CHASE if target_locked else State.ALERT

func _get_chase_destination(_target_visible: bool, _can_engage_target: bool) -> Vector2:
    return target.global_position if is_instance_valid(target) else last_seen_position

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
