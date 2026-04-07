class_name EnemyMeleeAttackComponent
extends "res://scripts/actors/attacks/enemy_attack_component.gd"

const ATTACK_CONTACT_MARGIN := 6.0

func perform_attack(enemy) -> void:
    if enemy == null or not is_instance_valid(enemy.target):
        return

    if enemy.global_position.distance_to(enemy.target.global_position) > enemy.attack_range + ATTACK_CONTACT_MARGIN:
        return

    if enemy.target.has_method("take_hit"):
        enemy.target.call("take_hit", enemy.global_position, enemy.touch_damage)
