class_name MetaProgressionState
extends RefCounted

const SAVE_PATH := "user://meta_progression.cfg"
const InventoryManagerScript = preload("res://scripts/systems/inventory_manager.gd")

const DEFAULT_PLAYER_NAME := "测试玩家"
const DEFAULT_GOLD := 1200
const WAREHOUSE_CAPACITY := 48
const SHOP_ITEMS := [
	{
		"id": "supply_kit",
		"display_name": "补给包",
		"price": 120,
		"sell_value": 40,
		"description": "基础补给物资，适合先囤进仓库。"
	},
	{
		"id": "repair_parts",
		"display_name": "维修零件",
		"price": 180,
		"sell_value": 65,
		"description": "常用零件，可作为战后库存储备。"
	},
	{
		"id": "lucky_charm",
		"display_name": "幸运符",
		"price": 260,
		"sell_value": 90,
		"description": "稀有挂件，价值更高，适合长期收藏。"
	}
]

static var _loaded := false
static var _player_name := DEFAULT_PLAYER_NAME
static var _gold := DEFAULT_GOLD
static var _warehouse_inventory = null


static func get_player_name() -> String:
	_ensure_loaded()
	return _player_name


static func get_gold() -> int:
	_ensure_loaded()
	return _gold


static func add_gold(amount: int) -> void:
	_ensure_loaded()
	if amount <= 0:
		return

	_gold += amount
	_save_state()


static func get_warehouse_snapshot() -> Dictionary:
	_ensure_loaded()
	return _warehouse_inventory.build_snapshot()


static func get_shop_entries() -> Array[Dictionary]:
	_ensure_loaded()

	var entries: Array[Dictionary] = []
	for offer_variant in SHOP_ITEMS:
		var offer: Dictionary = offer_variant
		var price := int(offer.get("price", 0))
		entries.append(
			{
				"id": str(offer.get("id", "")),
				"display_name": str(offer.get("display_name", "物资")),
				"price": price,
				"sell_value": int(offer.get("sell_value", 0)),
				"description": str(offer.get("description", "")),
				"can_afford": _gold >= price
			}
		)

	return entries


static func buy_shop_item(item_id: String) -> Dictionary:
	_ensure_loaded()

	var offer := _get_shop_offer(item_id)
	if offer.is_empty():
		return {
			"success": false,
			"reason": "OUT_OF_STOCK",
			"item_id": item_id
		}

	var price := int(offer.get("price", 0))
	if _gold < price:
		return {
			"success": false,
			"reason": "NOT_ENOUGH_GOLD",
			"item_id": item_id,
			"display_name": str(offer.get("display_name", "物资")),
			"price": price,
			"gold_total": _gold
		}

	var item_data := {
		"id": str(offer.get("id", "")),
		"display_name": str(offer.get("display_name", "物资")),
		"quantity": 1,
		"sell_value": int(offer.get("sell_value", 0))
	}
	if not _warehouse_inventory.add_item(item_data):
		return {
			"success": false,
			"reason": "WAREHOUSE_FULL",
			"item_id": item_id,
			"display_name": str(offer.get("display_name", "物资")),
			"price": price,
			"gold_total": _gold
		}

	_gold -= price
	_save_state()
	return {
		"success": true,
		"reason": "PURCHASED",
		"item_id": item_id,
		"display_name": str(offer.get("display_name", "物资")),
		"price": price,
		"gold_total": _gold
	}


static func deposit_inventory_snapshot(inventory_snapshot: Dictionary) -> Dictionary:
	_ensure_loaded()

	var items_variant: Variant = inventory_snapshot.get("items", [])
	if not (items_variant is Array):
		return {
			"stored_item_types": 0,
			"stored_quantity": 0
		}

	var stored_item_types := 0
	var stored_quantity := 0
	for item_variant in items_variant:
		if not (item_variant is Dictionary):
			continue

		var item: Dictionary = item_variant
		if not _warehouse_inventory.add_item(item):
			continue

		stored_item_types += 1
		stored_quantity += int(item.get("quantity", 0))

	if stored_item_types > 0:
		_save_state()

	return {
		"stored_item_types": stored_item_types,
		"stored_quantity": stored_quantity
	}


static func _ensure_loaded() -> void:
	if _loaded:
		return

	_loaded = true
	_player_name = DEFAULT_PLAYER_NAME
	_gold = DEFAULT_GOLD
	_warehouse_inventory = InventoryManagerScript.new()
	_warehouse_inventory.setup(WAREHOUSE_CAPACITY)

	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return

	_player_name = str(config.get_value("player", "name", DEFAULT_PLAYER_NAME))
	_gold = maxi(int(config.get_value("player", "gold", DEFAULT_GOLD)), 0)

	var warehouse_items_variant: Variant = config.get_value("warehouse", "items", [])
	if warehouse_items_variant is Array:
		for item_variant in warehouse_items_variant:
			if item_variant is Dictionary:
				_warehouse_inventory.add_item(item_variant)


static func _save_state() -> void:
	if _warehouse_inventory == null:
		return

	var config := ConfigFile.new()
	config.set_value("player", "name", _player_name)
	config.set_value("player", "gold", _gold)
	config.set_value("warehouse", "items", _warehouse_inventory.build_item_entries())
	config.save(SAVE_PATH)


static func _get_shop_offer(item_id: String) -> Dictionary:
	var normalized_id := item_id.strip_edges()
	if normalized_id.is_empty():
		return {}

	for offer_variant in SHOP_ITEMS:
		var offer: Dictionary = offer_variant
		if str(offer.get("id", "")) == normalized_id:
			return offer.duplicate(true)

	return {}
