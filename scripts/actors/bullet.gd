class_name BulletController
extends Area2D

const BULLET_COLOR := Color(1.0, 0.894118, 0.345098, 1.0)
const MOVE_SPEED := 220.0
const MAX_LIFETIME := 1.6

var arena_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(320.0, 180.0))
var direction: Vector2 = Vector2.RIGHT
var lifetime_remaining: float = MAX_LIFETIME

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    sprite.modulate = BULLET_COLOR
    body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
    global_position += direction * MOVE_SPEED * delta
    lifetime_remaining -= delta

    if lifetime_remaining <= 0.0 or not arena_rect.has_point(global_position):
        queue_free()

func setup(move_direction: Vector2, rect: Rect2) -> void:
    direction = move_direction.normalized()
    arena_rect = rect

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("enemies") and body.has_method("take_damage"):
        body.take_damage(1, direction)
        queue_free()
        return

    if body.is_in_group("covers") and body.has_method("take_damage"):
        body.take_damage(1, direction)
        queue_free()
        return
