class_name WeaponAssemblyState
extends RefCounted

const DEFAULT_WEAPON_NAME := "M4A1 平台"
const DEFAULT_WEAPON_DESCRIPTION := "标准突击步枪，可通过仓库配件快速调整战斗风格。"

const SLOT_ORDER := ["optic", "muzzle", "magazine", "stock"]
const SLOT_DEFINITIONS := {
	"optic": {
		"id": "optic",
		"display_name": "瞄具",
		"anchor": Vector2(0.31, 0.15)
	},
	"muzzle": {
		"id": "muzzle",
		"display_name": "枪口",
		"anchor": Vector2(0.86, 0.18)
	},
	"magazine": {
		"id": "magazine",
		"display_name": "弹匣",
		"anchor": Vector2(0.09, 0.52)
	},
	"stock": {
		"id": "stock",
		"display_name": "枪托",
		"anchor": Vector2(0.46, 0.84)
	}
}

const BASE_STATS := [
	{
		"id": "recoil",
		"label": "后坐力",
		"base": 5
	},
	{
		"id": "stability",
		"label": "稳定性",
		"base": 5
	},
	{
		"id": "range",
		"label": "射程",
		"base": 5
	},
	{
		"id": "handling",
		"label": "操控性",
		"base": 5
	}
]

const ATTACHMENT_LIBRARY := {
	"red_dot": {
		"id": "red_dot",
		"display_name": "红点瞄具",
		"slot_id": "optic",
		"description": "轻量化近距离瞄具，提高稳定性与操控。",
		"sell_value": 90,
		"modifiers": {
			"stability": 1,
			"handling": 1
		}
	},
	"holo_sight": {
		"id": "holo_sight",
		"display_name": "全息瞄具",
		"slot_id": "optic",
		"description": "中距离识别更清晰，兼顾射程与稳定性。",
		"sell_value": 110,
		"modifiers": {
			"stability": 1,
			"range": 1
		}
	},
	"compensator": {
		"id": "compensator",
		"display_name": "补偿器",
		"slot_id": "muzzle",
		"description": "有效压低枪口上跳，显著降低后坐力。",
		"sell_value": 105,
		"modifiers": {
			"recoil": -1,
			"stability": 1
		}
	},
	"suppressor": {
		"id": "suppressor",
		"display_name": "消音器",
		"slot_id": "muzzle",
		"description": "降低枪声暴露，提高射程，但稍微拖累操控。",
		"sell_value": 120,
		"modifiers": {
			"range": 1,
			"handling": -1
		}
	},
	"extended_mag": {
		"id": "extended_mag",
		"display_name": "扩容弹匣",
		"slot_id": "magazine",
		"description": "延长持续火力，牺牲一部分枪械灵活性。",
		"sell_value": 130,
		"modifiers": {
			"range": 1,
			"handling": -1
		}
	},
	"quick_mag": {
		"id": "quick_mag",
		"display_name": "快拔弹匣",
		"slot_id": "magazine",
		"description": "更顺手的换弹组件，提升整体操控表现。",
		"sell_value": 125,
		"modifiers": {
			"handling": 1,
			"stability": 1
		}
	},
	"light_stock": {
		"id": "light_stock",
		"display_name": "轻型枪托",
		"slot_id": "stock",
		"description": "压缩重量，提升转向和抬枪速度。",
		"sell_value": 100,
		"modifiers": {
			"handling": 1,
			"recoil": 1
		}
	},
	"precision_stock": {
		"id": "precision_stock",
		"display_name": "稳定枪托",
		"slot_id": "stock",
		"description": "强化肩托支撑，提升稳定性与中远距离控制。",
		"sell_value": 118,
		"modifiers": {
			"recoil": -1,
			"stability": 1
		}
	}
}


static func get_starter_attachment_items() -> Array[Dictionary]:
	return [
		build_attachment_item("red_dot"),
		build_attachment_item("holo_sight"),
		build_attachment_item("compensator"),
		build_attachment_item("quick_mag"),
		build_attachment_item("precision_stock")
	]


static func sanitize_equipped_attachments(equipped_variant: Variant) -> Dictionary:
	var equipped: Dictionary = {}
	if not (equipped_variant is Dictionary):
		return equipped

	for slot_id in SLOT_ORDER:
		var attachment_id := str(equipped_variant.get(slot_id, ""))
		if is_attachment_valid_for_slot(slot_id, attachment_id):
			equipped[slot_id] = attachment_id

	return equipped


static func build_snapshot(warehouse_snapshot: Dictionary, equipped_variant: Variant) -> Dictionary:
	var equipped := sanitize_equipped_attachments(equipped_variant)
	var slots: Array[Dictionary] = []
	for slot_id in SLOT_ORDER:
		var slot_definition: Dictionary = SLOT_DEFINITIONS.get(slot_id, {})
		var equipped_id := str(equipped.get(slot_id, ""))
		var equipped_attachment: Dictionary = get_attachment_definition(equipped_id)
		slots.append(
			{
				"id": slot_id,
				"display_name": str(slot_definition.get("display_name", "配件")),
				"anchor": slot_definition.get("anchor", Vector2.ZERO),
				"equipped_id": equipped_id,
				"equipped_name": (
					str(equipped_attachment.get("display_name", "点击装配"))
					if not equipped_id.is_empty()
					else "点击装配"
				),
				"description": (
					str(equipped_attachment.get("description", "从仓库选择适配配件。"))
					if not equipped_id.is_empty()
					else "从仓库选择适配配件。"
				)
			}
		)

	return {
		"weapon_name": DEFAULT_WEAPON_NAME,
		"weapon_description": DEFAULT_WEAPON_DESCRIPTION,
		"slots": slots,
		"stats": _build_stat_entries(equipped),
		"warehouse_attachment_total": _count_warehouse_attachments(warehouse_snapshot)
	}


static func build_available_attachment_entries(slot_id: String, warehouse_snapshot: Dictionary, equipped_variant: Variant) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var equipped := sanitize_equipped_attachments(equipped_variant)
	var current_attachment_id := str(equipped.get(slot_id, ""))
	if not current_attachment_id.is_empty():
		var current_attachment := get_attachment_definition(current_attachment_id)
		entries.append(
			{
				"id": "__unequip__",
				"display_name": "卸下当前配件",
				"meta_text": str(current_attachment.get("display_name", "")),
				"description": "将已装配的部件退回仓库。",
				"action_text": "卸下",
				"action_enabled": true
			}
		)

	var items_variant: Variant = warehouse_snapshot.get("items", [])
	if not (items_variant is Array):
		return entries

	for item_variant in items_variant:
		if not (item_variant is Dictionary):
			continue

		var item: Dictionary = item_variant
		var attachment_id := str(item.get("id", ""))
		if not is_attachment_valid_for_slot(slot_id, attachment_id):
			continue

		var quantity := int(item.get("quantity", 0))
		if quantity <= 0:
			continue

		var attachment_definition := get_attachment_definition(attachment_id)
		entries.append(
			{
				"id": attachment_id,
				"display_name": str(attachment_definition.get("display_name", "配件")),
				"meta_text": "仓库 x%d  %s" % [quantity, build_modifier_summary(attachment_id)],
				"description": str(attachment_definition.get("description", "")),
				"action_text": "装配",
				"action_enabled": true
			}
		)

	return entries


static func get_slot_definition(slot_id: String) -> Dictionary:
	return SLOT_DEFINITIONS.get(slot_id, {}).duplicate(true)


static func get_attachment_definition(attachment_id: String) -> Dictionary:
	return ATTACHMENT_LIBRARY.get(attachment_id, {}).duplicate(true)


static func is_attachment_valid_for_slot(slot_id: String, attachment_id: String) -> bool:
	if slot_id.is_empty() or attachment_id.is_empty():
		return false

	var definition: Dictionary = ATTACHMENT_LIBRARY.get(attachment_id, {})
	return not definition.is_empty() and str(definition.get("slot_id", "")) == slot_id


static func build_attachment_item(attachment_id: String) -> Dictionary:
	var definition := get_attachment_definition(attachment_id)
	if definition.is_empty():
		return {}

	return {
		"id": str(definition.get("id", "")),
		"display_name": str(definition.get("display_name", "配件")),
		"quantity": 1,
		"sell_value": int(definition.get("sell_value", 0))
	}


static func build_modifier_summary(attachment_id: String) -> String:
	var definition := get_attachment_definition(attachment_id)
	if definition.is_empty():
		return "无属性调整"

	var modifiers: Dictionary = definition.get("modifiers", {})
	if modifiers.is_empty():
		return "无属性调整"

	var parts: Array[String] = []
	for stat_variant in BASE_STATS:
		var stat: Dictionary = stat_variant
		var stat_id := str(stat.get("id", ""))
		var modifier := int(modifiers.get(stat_id, 0))
		if modifier == 0:
			continue

		parts.append("%s %s%d" % [stat.get("label", stat_id), "+" if modifier > 0 else "", modifier])

	return " / ".join(parts) if not parts.is_empty() else "无属性调整"


static func _build_stat_entries(equipped: Dictionary) -> Array[Dictionary]:
	var total_modifiers: Dictionary = {}
	for slot_id in SLOT_ORDER:
		var attachment_id := str(equipped.get(slot_id, ""))
		var definition := get_attachment_definition(attachment_id)
		if definition.is_empty():
			continue

		var modifiers: Dictionary = definition.get("modifiers", {})
		for modifier_key_variant in modifiers.keys():
			var modifier_key := str(modifier_key_variant)
			total_modifiers[modifier_key] = int(total_modifiers.get(modifier_key, 0)) + int(modifiers.get(modifier_key, 0))

	var stat_entries: Array[Dictionary] = []
	for stat_variant in BASE_STATS:
		var stat: Dictionary = stat_variant
		var stat_id := str(stat.get("id", ""))
		var base_value := int(stat.get("base", 0))
		var modifier := int(total_modifiers.get(stat_id, 0))
		stat_entries.append(
			{
				"id": stat_id,
				"label": str(stat.get("label", stat_id)),
				"base": base_value,
				"modifier": modifier,
				"current": base_value + modifier,
				"display_text": "%s：%d (%s%d)  当前 %d"
					% [
						stat.get("label", stat_id),
						base_value,
						"+" if modifier >= 0 else "",
						modifier,
						base_value + modifier
					]
			}
		)

	return stat_entries


static func _count_warehouse_attachments(warehouse_snapshot: Dictionary) -> int:
	var total := 0
	var items_variant: Variant = warehouse_snapshot.get("items", [])
	if not (items_variant is Array):
		return total

	for item_variant in items_variant:
		if not (item_variant is Dictionary):
			continue

		var item: Dictionary = item_variant
		if ATTACHMENT_LIBRARY.has(str(item.get("id", ""))):
			total += int(item.get("quantity", 0))

	return total
