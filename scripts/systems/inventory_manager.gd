class_name InventoryManager
extends RefCounted

const DEFAULT_CAPACITY := 8

var max_slots: int = DEFAULT_CAPACITY
var items: Dictionary = {}

func setup(capacity: int = DEFAULT_CAPACITY) -> void:
	max_slots = maxi(capacity, 1)

func clear() -> void:
	items.clear()

func add_item(item_data: Dictionary) -> bool:
	var item_id: String = str(item_data.get("id", "")).strip_edges()
	if item_id.is_empty():
		return false

	var quantity: int = maxi(int(item_data.get("quantity", 1)), 1)
	var sell_value: int = maxi(int(item_data.get("sell_value", 1)), 0)
	if items.has(item_id):
		var existing_item: Dictionary = items.get(item_id, {})
		existing_item["quantity"] = int(existing_item.get("quantity", 0)) + quantity
		existing_item["sell_value"] = maxi(int(existing_item.get("sell_value", 0)), sell_value)
		items[item_id] = existing_item
		return true

	if get_used_slots() >= max_slots:
		return false

	items[item_id] = {
		"id": item_id,
		"display_name": str(item_data.get("display_name", item_id.to_upper())),
		"quantity": quantity,
		"sell_value": sell_value
	}
	return true

func get_used_slots() -> int:
	return items.size()

func has_items() -> bool:
	return not items.is_empty()

func get_total_quantity() -> int:
	var total := 0
	for item_variant in items.values():
		var item: Dictionary = item_variant
		total += int(item.get("quantity", 0))
	return total

func get_total_sale_value() -> int:
	var total := 0
	for item_variant in items.values():
		var item: Dictionary = item_variant
		total += int(item.get("quantity", 0)) * int(item.get("sell_value", 0))
	return total

func build_summary_text() -> String:
	return "背包 %d/%d" % [get_used_slots(), max_slots]

func build_panel_text() -> String:
	if items.is_empty():
		return "空"

	var lines: Array[String] = []
	for item in _get_sorted_items():
		lines.append(
			"%s  x%d  %dG"
			% [
				item.get("display_name", "物品"),
				item.get("quantity", 0),
				item.get("sell_value", 0)
			]
		)

	return "\n".join(lines)

func build_item_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for item in _get_sorted_items():
		var quantity: int = int(item.get("quantity", 0))
		var sell_value: int = int(item.get("sell_value", 0))
		entries.append(
			{
				"id": str(item.get("id", "")),
				"display_name": str(item.get("display_name", "物品")),
				"quantity": quantity,
				"sell_value": sell_value,
				"total_value": quantity * sell_value
			}
		)

	return entries

func sell_item(item_id: String, quantity: int = 1) -> Dictionary:
	var normalized_id := item_id.strip_edges()
	if normalized_id.is_empty() or not items.has(normalized_id):
		return {
			"success": false,
			"reason": "NOT_FOUND",
			"item_id": normalized_id,
			"quantity_sold": 0,
			"gold_earned": 0
		}

	var item: Dictionary = items.get(normalized_id, {})
	var available_quantity: int = int(item.get("quantity", 0))
	var quantity_to_sell: int = mini(maxi(quantity, 1), available_quantity)
	var sell_value: int = maxi(int(item.get("sell_value", 0)), 0)
	var remaining_quantity: int = maxi(available_quantity - quantity_to_sell, 0)
	var gold_earned: int = quantity_to_sell * sell_value

	if remaining_quantity > 0:
		item["quantity"] = remaining_quantity
		items[normalized_id] = item
	else:
		items.erase(normalized_id)

	return {
		"success": true,
		"reason": "SOLD",
		"item_id": normalized_id,
		"display_name": str(item.get("display_name", normalized_id)),
		"quantity_sold": quantity_to_sell,
		"gold_earned": gold_earned,
		"remaining_quantity": remaining_quantity
	}

func remove_item(item_id: String, quantity: int = 1) -> Dictionary:
	var normalized_id := item_id.strip_edges()
	if normalized_id.is_empty() or not items.has(normalized_id):
		return {
			"success": false,
			"reason": "NOT_FOUND",
			"item_id": normalized_id,
			"quantity_removed": 0
		}

	var item: Dictionary = items.get(normalized_id, {})
	var available_quantity: int = int(item.get("quantity", 0))
	var quantity_to_remove: int = mini(maxi(quantity, 1), available_quantity)
	var remaining_quantity: int = maxi(available_quantity - quantity_to_remove, 0)

	if remaining_quantity > 0:
		item["quantity"] = remaining_quantity
		items[normalized_id] = item
	else:
		items.erase(normalized_id)

	return {
		"success": true,
		"reason": "REMOVED",
		"item_id": normalized_id,
		"display_name": str(item.get("display_name", normalized_id)),
		"quantity_removed": quantity_to_remove,
		"remaining_quantity": remaining_quantity,
		"item_data": {
			"id": normalized_id,
			"display_name": str(item.get("display_name", normalized_id)),
			"quantity": quantity_to_remove,
			"sell_value": int(item.get("sell_value", 0))
		}
	}

func sell_all_items() -> Dictionary:
	var items_sold := 0
	var gold_earned := 0

	for item_variant in items.values():
		var item: Dictionary = item_variant
		var quantity: int = int(item.get("quantity", 0))
		items_sold += quantity
		gold_earned += quantity * int(item.get("sell_value", 0))

	items.clear()
	return {
		"items_sold": items_sold,
		"gold_earned": gold_earned
	}

func build_snapshot() -> Dictionary:
	return {
		"capacity": max_slots,
		"used_slots": get_used_slots(),
		"total_quantity": get_total_quantity(),
		"total_sale_value": get_total_sale_value(),
		"summary_text": build_summary_text(),
		"panel_text": build_panel_text(),
		"items": build_item_entries()
	}

func _get_sorted_items() -> Array[Dictionary]:
	var sorted_ids: Array = items.keys()
	sorted_ids.sort()

	var sorted_items: Array[Dictionary] = []
	for item_id_variant in sorted_ids:
		var item_id: String = str(item_id_variant)
		var item: Dictionary = items.get(item_id, {})
		sorted_items.append(item)

	return sorted_items
