class_name LootPickup
extends Area2D

const FLOAT_DISTANCE := 2.5
const FLOAT_SPEED := 3.5
const BASE_TINT := Color(1.0, 0.803922, 0.313725, 1.0)

var item_data: Dictionary = {
	"id": "scrap",
	"display_name": "废料",
	"quantity": 1
}
var float_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("loot_pickups")
	body_entered.connect(_on_body_entered)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_visuals()

func _process(delta: float) -> void:
	float_time += delta
	sprite.position.y = sin(float_time * TAU * FLOAT_SPEED * 0.25) * FLOAT_DISTANCE
	sprite.rotation = sin(float_time * 2.2) * 0.08

func setup(drop_data: Dictionary = {}) -> void:
	item_data = {
		"id": str(drop_data.get("id", "scrap")),
		"display_name": str(drop_data.get("display_name", "废料")),
		"quantity": max(int(drop_data.get("quantity", 1)), 1),
		"tint": drop_data.get("tint", BASE_TINT)
	}

	if is_node_ready():
		_apply_visuals()

func _apply_visuals() -> void:
	if sprite == null:
		return

	sprite.modulate = item_data.get("tint", BASE_TINT)

func _on_body_entered(body: Node) -> void:
	if body == null or not body.has_method("add_inventory_item"):
		return

	if body.call("add_inventory_item", item_data):
		queue_free()
