class_name MerchantNPC
extends Node2D

signal shop_requested

const IDLE_BODY_COLOR := Color(0.396078, 0.568627, 0.466667, 1.0)
const ACTIVE_BODY_COLOR := Color(0.52549, 0.756863, 0.611765, 1.0)
const HEAD_COLOR := Color(0.937255, 0.858824, 0.701961, 1.0)
const SHOP_TITLE := "商人"
const SHOP_ITEMS := [
	{
		"id": "supply_kit",
		"display_name": "补给包",
		"price": 4,
		"sell_value": 1,
		"description": "基础补给。"
	},
	{
		"id": "lucky_charm",
		"display_name": "幸运符",
		"price": 8,
		"sell_value": 3,
		"description": "更值钱的小饰品。"
	}
]

var player: Node2D = null
var player_in_range: bool = false

@onready var body_sprite: Sprite2D = $BodySprite2D
@onready var head_sprite: Sprite2D = $HeadSprite2D
@onready var interaction_area: Area2D = $InteractionArea

func _ready() -> void:
	body_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	head_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	_update_visuals()

func setup(player_node: Node2D) -> void:
	player = player_node
	_update_visuals()

func _process(_delta: float) -> void:
	if get_tree().paused:
		return

	if not player_in_range or not is_instance_valid(player) or not player.visible:
		return

	if Input.is_action_just_pressed("interact"):
		shop_requested.emit()

func get_interaction_prompt() -> String:
	if not player_in_range or not is_instance_valid(player) or not player.visible:
		return ""

	return "E 交易"

func build_shop_state(player_node: Node) -> Dictionary:
	var current_gold: int = 0
	var pending_sale_gold: int = 0
	var bag_summary: String = "背包 0/0"
	var inventory_items: Array[Dictionary] = []
	if player_node != null:
		if player_node.has_method("get_gold"):
			current_gold = int(player_node.call("get_gold"))
		if player_node.has_method("get_pending_sale_gold"):
			pending_sale_gold = int(player_node.call("get_pending_sale_gold"))
		if player_node.has_method("get_inventory_snapshot"):
			var snapshot_variant: Variant = player_node.call("get_inventory_snapshot")
			if snapshot_variant is Dictionary:
				var snapshot: Dictionary = snapshot_variant
				bag_summary = str(snapshot.get("summary_text", bag_summary))
				var inventory_items_variant: Variant = snapshot.get("items", [])
				if inventory_items_variant is Array:
					for item_variant in inventory_items_variant:
						if item_variant is Dictionary:
							var item: Dictionary = item_variant
							inventory_items.append(item.duplicate(true))

	var item_entries: Array[Dictionary] = []
	for offer_variant in SHOP_ITEMS:
		var offer: Dictionary = offer_variant
		var price: int = int(offer.get("price", 0))
		item_entries.append(
			{
				"id": str(offer.get("id", "")),
				"display_name": str(offer.get("display_name", "物品")),
				"price": price,
				"description": str(offer.get("description", "")),
				"can_afford": current_gold >= price,
				"button_text": "%s  %d金币" % [offer.get("display_name", "物品"), price]
			}
		)

	return {
		"title": SHOP_TITLE,
		"gold": current_gold,
		"bag_summary": bag_summary,
		"sell_value": pending_sale_gold,
		"can_sell": pending_sale_gold > 0,
		"sell_button_text": "Sell Loot  +%dG" % pending_sale_gold if pending_sale_gold > 0 else "Sell Loot  Empty",
		"items": item_entries,
		"inventory_items": inventory_items
	}

func get_shop_offer(item_id: String) -> Dictionary:
	for offer_variant in SHOP_ITEMS:
		var offer: Dictionary = offer_variant
		if str(offer.get("id", "")) != item_id:
			continue

		return {
			"display_name": str(offer.get("display_name", "物品")),
			"price": int(offer.get("price", 0)),
			"item_data": {
				"id": str(offer.get("id", "")),
				"display_name": str(offer.get("display_name", "物品")),
				"quantity": 1,
				"sell_value": int(offer.get("sell_value", 0))
			}
		}

	return {}

func _on_body_entered(body: Node) -> void:
	if player != null and body != player:
		return

	if player == null and not body.is_in_group("player"):
		return

	player = body as Node2D
	player_in_range = true
	_update_visuals()

func _on_body_exited(body: Node) -> void:
	if player != null and body != player:
		return

	if player == null and not body.is_in_group("player"):
		return

	player_in_range = false
	_update_visuals()

func _update_visuals() -> void:
	var body_color: Color = ACTIVE_BODY_COLOR if player_in_range else IDLE_BODY_COLOR
	body_sprite.modulate = body_color
	head_sprite.modulate = HEAD_COLOR
