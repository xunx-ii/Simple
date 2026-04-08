class_name TaskChainRepository
extends RefCounted

const TaskTextsScript = preload("res://scripts/systems/tasks/task_texts.gd")


static func build_chains() -> Array:
	return [
		{
			"id": "starter_chain",
			"title": TaskTextsScript.STARTER_CHAIN_TITLE,
			"description": TaskTextsScript.STARTER_CHAIN_DESCRIPTION,
			"tasks": [
				{
					"id": "read_briefing",
					"title": TaskTextsScript.TASK_READ_BRIEFING_TITLE,
					"description": TaskTextsScript.TASK_READ_BRIEFING_DESCRIPTION,
					"reward": 80,
					"target": 1,
					"prerequisite_task_ids": []
				},
				{
					"id": "claim_supplies",
					"title": TaskTextsScript.TASK_CLAIM_SUPPLIES_TITLE,
					"description": TaskTextsScript.TASK_CLAIM_SUPPLIES_DESCRIPTION,
					"reward": 120,
					"target": 2,
					"prerequisite_task_ids": ["read_briefing"]
				},
				{
					"id": "confirm_loadout",
					"title": TaskTextsScript.TASK_CONFIRM_LOADOUT_TITLE,
					"description": TaskTextsScript.TASK_CONFIRM_LOADOUT_DESCRIPTION,
					"reward": 180,
					"target": 2,
					"prerequisite_task_ids": ["claim_supplies"]
				}
			]
		},
		{
			"id": "deployment_chain",
			"title": TaskTextsScript.DEPLOYMENT_CHAIN_TITLE,
			"description": TaskTextsScript.DEPLOYMENT_CHAIN_DESCRIPTION,
			"tasks": [
				{
					"id": "contact_operator",
					"title": TaskTextsScript.TASK_CONTACT_OPERATOR_TITLE,
					"description": TaskTextsScript.TASK_CONTACT_OPERATOR_DESCRIPTION,
					"reward": 100,
					"target": 1,
					"prerequisite_task_ids": ["read_briefing"]
				},
				{
					"id": "inspect_route",
					"title": TaskTextsScript.TASK_INSPECT_ROUTE_TITLE,
					"description": TaskTextsScript.TASK_INSPECT_ROUTE_DESCRIPTION,
					"reward": 160,
					"target": 2,
					"prerequisite_task_ids": ["contact_operator", "confirm_loadout"]
				},
				{
					"id": "final_briefing",
					"title": TaskTextsScript.TASK_FINAL_BRIEFING_TITLE,
					"description": TaskTextsScript.TASK_FINAL_BRIEFING_DESCRIPTION,
					"reward": 220,
					"target": 1,
					"prerequisite_task_ids": ["inspect_route"]
				}
			]
		}
	]
