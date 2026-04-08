class_name TaskChainRepository
extends RefCounted


static func build_chains() -> Array:
	return [
		{
			"id": "starter_chain",
			"title": "新手引导",
			"description": "熟悉大厅的基础功能，完成战斗前的准备。",
			"tasks": [
				{
					"id": "read_briefing",
					"title": "阅读作战告示",
					"description": "查看大厅中的基础说明，了解当前区域的战斗规则。",
					"reward": 80,
					"target": 1,
					"prerequisite_task_ids": []
				},
				{
					"id": "claim_supplies",
					"title": "领取基础补给",
					"description": "整理补给箱，确保出发前的基础资源已经准备妥当。",
					"reward": 120,
					"target": 2,
					"prerequisite_task_ids": ["read_briefing"]
				},
				{
					"id": "confirm_loadout",
					"title": "确认出战配置",
					"description": "检查武器、弹药和金币储备，为正式出击做好确认。",
					"reward": 180,
					"target": 2,
					"prerequisite_task_ids": ["claim_supplies"]
				}
			]
		},
		{
			"id": "deployment_chain",
			"title": "部署准备",
			"description": "完成联络、路线确认与最终简报，推进完整任务链。",
			"tasks": [
				{
					"id": "contact_operator",
					"title": "联络前线联络员",
					"description": "建立通讯，确认大厅到战区之间的调度链路畅通。",
					"reward": 100,
					"target": 1,
					"prerequisite_task_ids": ["read_briefing"]
				},
				{
					"id": "inspect_route",
					"title": "确认部署路线",
					"description": "核对路线图和关键补给点，准备下一步作战推进。",
					"reward": 160,
					"target": 2,
					"prerequisite_task_ids": ["contact_operator", "confirm_loadout"]
				},
				{
					"id": "final_briefing",
					"title": "完成最终简报",
					"description": "完成所有准备工作后，提交最终简报，结束整条任务链。",
					"reward": 220,
					"target": 1,
					"prerequisite_task_ids": ["inspect_route"]
				}
			]
		}
	]
