class_name EnemyRangedAttackComponent
extends "res://scripts/actors/attacks/enemy_attack_component.gd"

const MUZZLE_OFFSET := 12.0
const BULLET_COLOR := Color(1.0, 0.8, 0.45, 0.95)
const BULLET_WIDTH := 2.0
const BULLET_FLASH_DURATION := 0.05
const BULLET_VISUAL_SPEED := 7600.0

func perform_attack(enemy) -> void:
    if enemy == null or not is_instance_valid(enemy.target):
        return

    var world_controller = enemy.world_controller
    if world_controller == null or not world_controller.has_method("spawn_bullet"):
        return

    var shot_direction: Vector2 = (enemy.target.global_position - enemy.global_position).normalized()
    if shot_direction == Vector2.ZERO:
        shot_direction = enemy.facing_direction

    world_controller.spawn_bullet(
        enemy.global_position + shot_direction * MUZZLE_OFFSET,
        shot_direction,
        {
            "range": enemy.attack_range,
            "damage": enemy.touch_damage,
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
