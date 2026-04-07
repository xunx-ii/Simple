class_name HUDStateBuilder
extends RefCounted

const DEFAULT_WEAPON_NAME := "\u5F92\u624B"
const DEFAULT_SUMMARY_TEXT := "\u80CC\u5305 0/8"

static func build_state(
	player: Node,
	merchant_npc: Node,
	ui_controller: Node,
	wave_director,
	game_over: bool
) -> Dictionary:
	var gold := 0
	var inventory_summary_text := ""
	var inventory_items: Array[Dictionary] = []
	var interaction_text := ""

	if is_instance_valid(player):
		gold = int(_call_or_default(player, "get_gold", 0))
		var inventory_snapshot: Dictionary = _get_inventory_snapshot(player)
		inventory_summary_text = str(inventory_snapshot.get("summary_text", DEFAULT_SUMMARY_TEXT))
		inventory_items = _duplicate_item_entries(inventory_snapshot.get("items", []))

	if is_instance_valid(merchant_npc) and merchant_npc.has_method("get_interaction_prompt"):
		interaction_text = str(merchant_npc.call("get_interaction_prompt"))

	if ui_controller != null and ui_controller.has_method("is_shop_open") and ui_controller.is_shop_open():
		interaction_text = ""

	return {
		"health": int(player.get("current_health")) if is_instance_valid(player) else 0,
		"score": int(wave_director.get("score")) if wave_director != null else 0,
		"gold": gold,
		"wave": int(wave_director.get("current_wave")) if wave_director != null else 0,
		"dash_ready": bool(_call_or_default(player, "is_dash_ready", false)),
		"dash_cooldown": float(_call_or_default(player, "get_dash_cooldown_remaining", 0.0)),
		"dash_ratio": float(_call_or_default(player, "get_dash_ratio", 0.0)),
		"weapon_name": str(_call_or_default(player, "get_weapon_name", DEFAULT_WEAPON_NAME)),
		"inventory_summary_text": inventory_summary_text,
		"inventory_items": inventory_items,
		"interaction_text": interaction_text,
		"banner_text": str(wave_director.get("banner_text")) if wave_director != null else "",
		"game_over": game_over
	}

static func _get_inventory_snapshot(player: Node) -> Dictionary:
	if player == null or not player.has_method("get_inventory_snapshot"):
		return {}

	var snapshot_variant: Variant = player.call("get_inventory_snapshot")
	if snapshot_variant is Dictionary:
		return snapshot_variant

	return {}

static func _duplicate_item_entries(items_variant: Variant) -> Array[Dictionary]:
	var item_entries: Array[Dictionary] = []
	if items_variant is Array:
		for item_variant in items_variant:
			if item_variant is Dictionary:
				var item: Dictionary = item_variant
				item_entries.append(item.duplicate(true))

	return item_entries

static func _call_or_default(target: Node, method_name: String, default_value: Variant) -> Variant:
	if target == null or not target.has_method(method_name):
		return default_value

	return target.call(method_name)
