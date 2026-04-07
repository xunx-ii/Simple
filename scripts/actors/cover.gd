class_name CoverObject
extends StaticBody2D

signal destroyed(cell: Vector2i)

const HIT_FLASH_COLOR := Color(1.0, 0.96, 0.72, 1.0)
const COLLISION_INSET := 4.0

var tile_size: int = 16
var cell: Vector2i = Vector2i.ZERO
var base_color: Color = Color(0.494118, 0.529412, 0.568627, 1.0)
var max_health: int = 1
var current_health: int = 1
var hit_flash_remaining: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
    add_to_group("covers")
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _apply_shape()
    _update_visuals()

func _process(delta: float) -> void:
    if hit_flash_remaining <= 0.0:
        return

    hit_flash_remaining = max(hit_flash_remaining - delta, 0.0)
    if hit_flash_remaining == 0.0:
        _update_visuals()

func configure(tile_world_size: int, tint: Color, cell_value: Vector2i) -> void:
    tile_size = tile_world_size
    base_color = tint
    cell = cell_value
    max_health = 1
    current_health = 1

    if is_node_ready():
        _apply_shape()
        _update_visuals()

func take_damage(amount: int, _from_direction: Vector2 = Vector2.ZERO) -> void:
    if amount <= 0:
        return

    current_health = max(current_health - amount, 0)
    hit_flash_remaining = 0.08
    sprite.modulate = HIT_FLASH_COLOR

    if current_health == 0:
        destroyed.emit(cell)
        queue_free()
        return

    _update_visuals()

func _apply_shape() -> void:
    var pixel_size := Vector2.ONE * float(tile_size)
    var rectangle_shape := collision_shape.shape as RectangleShape2D
    if rectangle_shape != null:
        rectangle_shape.size = Vector2(
            max(pixel_size.x - COLLISION_INSET, 4.0),
            max(pixel_size.y - COLLISION_INSET, 4.0)
        )

    sprite.scale = Vector2.ONE

func _update_visuals() -> void:
    if hit_flash_remaining > 0.0:
        sprite.modulate = HIT_FLASH_COLOR
        return

    var health_ratio: float = float(current_health) / float(max_health)
    var damaged_color := Color(0.286275, 0.231373, 0.215686, 1.0)
    sprite.modulate = damaged_color.lerp(base_color, health_ratio)
