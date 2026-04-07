class_name EnemyMeleeAttackComponent
extends "res://scripts/actors/attacks/enemy_attack_component.gd"

const ATTACK_CONTACT_MARGIN := 6.0

func perform_attack(enemy) -> void:
    if enemy == null:
        return

    enemy.apply_attack_contact_hit(ATTACK_CONTACT_MARGIN)
