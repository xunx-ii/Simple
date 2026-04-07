class_name EnemyRangedAttackComponent
extends "res://scripts/actors/attacks/enemy_attack_component.gd"

const MUZZLE_OFFSET := 12.0
const BULLET_COLOR := Color(1.0, 0.8, 0.45, 0.95)
const BULLET_WIDTH := 2.0
const BULLET_FLASH_DURATION := 0.05
const BULLET_VISUAL_SPEED := 7600.0

func perform_attack(enemy) -> void:
    if enemy == null or not enemy.has_attack_target():
        return

    enemy.fire_attack_bullet(
        MUZZLE_OFFSET,
        {
            "range": enemy.get_attack_range_value(),
            "damage": enemy.get_attack_damage_value(),
            "collision_mask": 9,
            "color": BULLET_COLOR,
            "width": BULLET_WIDTH,
            "flash_duration": BULLET_FLASH_DURATION,
            "visual_speed": BULLET_VISUAL_SPEED,
            "can_hit_player": true,
            "can_hit_enemies": false,
            "can_hit_covers": true
        }
    )
