class_name EnemyAttackComponent
extends Node

func perform_attack(_enemy) -> void:
    pass

func can_attack_without_sight(_enemy) -> bool:
    return false

func get_attack_release_margin(_enemy) -> float:
    return 10.0
