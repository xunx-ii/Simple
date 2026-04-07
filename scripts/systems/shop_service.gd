class_name ShopService
extends RefCounted

const ACTION_BANNER_DURATION := 1.1
const TEXT_OUT_OF_STOCK := "\u6682\u65E0\u5546\u54C1"
const TEXT_NOT_ENOUGH_GOLD := "\u91D1\u5E01\u4E0D\u8DB3"
const TEXT_BAG_FULL := "\u80CC\u5305\u5DF2\u6EE1"
const TEXT_CANNOT_BUY := "\u65E0\u6CD5\u8D2D\u4E70"
const TEXT_CANNOT_SELL := "\u65E0\u6CD5\u51FA\u552E"
const TEXT_ITEM_FALLBACK := "\u7269\u54C1"
const TEXT_BUY_TEMPLATE := "\u8D2D\u4E70 %s  -%d\u91D1\u5E01"
const TEXT_SELL_TEMPLATE := "\u5356\u51FA %s  +%d\u91D1\u5E01"

var merchant_npc: Node = null
var player: Node = null
var ui_controller: Node = null

func setup(merchant_node: Node, player_node: Node, ui_node: Node) -> void:
	merchant_npc = merchant_node
	player = player_node
	ui_controller = ui_node

func open_shop() -> bool:
	if merchant_npc == null or ui_controller == null:
		return false

	if not merchant_npc.has_method("build_shop_state") or not ui_controller.has_method("open_shop"):
		return false

	ui_controller.open_shop(merchant_npc.build_shop_state(player))
	return true

func refresh_open_shop() -> void:
	if ui_controller == null or not ui_controller.has_method("is_shop_open") or not ui_controller.is_shop_open():
		return

	if merchant_npc == null or not merchant_npc.has_method("build_shop_state"):
		return

	if ui_controller.has_method("apply_shop_state"):
		ui_controller.apply_shop_state(merchant_npc.build_shop_state(player))

func buy_item(item_id: String) -> Dictionary:
	if merchant_npc == null or not merchant_npc.has_method("get_shop_offer"):
		return {}

	var offer: Dictionary = merchant_npc.get_shop_offer(item_id)
	if offer.is_empty():
		refresh_open_shop()
		return _build_feedback(TEXT_OUT_OF_STOCK)

	if player == null or not player.has_method("buy_inventory_item"):
		return {}

	var purchase_result: Dictionary = player.buy_inventory_item(
		offer.get("item_data", {}),
		int(offer.get("price", 0))
	)
	refresh_open_shop()

	if bool(purchase_result.get("success", false)):
		return _build_feedback(
			TEXT_BUY_TEMPLATE % [
				str(offer.get("display_name", TEXT_ITEM_FALLBACK)),
				int(offer.get("price", 0))
			]
		)

	var reason: String = str(purchase_result.get("reason", "FAILED"))
	match reason:
		"NOT_ENOUGH_GOLD":
			return _build_feedback(TEXT_NOT_ENOUGH_GOLD)
		"BAG_FULL":
			return _build_feedback(TEXT_BAG_FULL)
		_:
			return _build_feedback(TEXT_CANNOT_BUY)

func sell_item(item_id: String) -> Dictionary:
	if player == null or not player.has_method("sell_inventory_item"):
		return {}

	var sale_result: Dictionary = player.sell_inventory_item(item_id)
	refresh_open_shop()

	var items_sold: int = int(sale_result.get("quantity_sold", 0))
	var gold_earned: int = int(sale_result.get("gold_earned", 0))
	if items_sold <= 0 or gold_earned <= 0:
		return _build_feedback(TEXT_CANNOT_SELL)

	return _build_feedback(
		TEXT_SELL_TEMPLATE % [
			str(sale_result.get("display_name", TEXT_ITEM_FALLBACK)),
			gold_earned
		]
	)

func _build_feedback(banner_text: String) -> Dictionary:
	return {
		"banner_text": banner_text,
		"banner_duration": ACTION_BANNER_DURATION,
		"refresh_ui": true
	}
