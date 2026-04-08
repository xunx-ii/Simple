class_name TaskTexts
extends RefCounted

const DEFAULT_PLAYER_NAME := "测试玩家"
const DEFAULT_CHAIN_TITLE := "任务链"
const DEFAULT_TASK_TITLE := "任务"

const STARTER_CHAIN_TITLE := "新手引导"
const STARTER_CHAIN_DESCRIPTION := "熟悉大厅的基础功能，完成战斗前的准备。"
const TASK_READ_BRIEFING_TITLE := "阅读作战告示"
const TASK_READ_BRIEFING_DESCRIPTION := "查看大厅中的基础说明，了解当前区域的战斗规则。"
const TASK_CLAIM_SUPPLIES_TITLE := "领取基础补给"
const TASK_CLAIM_SUPPLIES_DESCRIPTION := "整理补给箱，确保出发前的基础资源已经准备妥当。"
const TASK_CONFIRM_LOADOUT_TITLE := "确认出战配置"
const TASK_CONFIRM_LOADOUT_DESCRIPTION := "检查武器、弹药和金币储备，为正式出击做好确认。"

const DEPLOYMENT_CHAIN_TITLE := "部署准备"
const DEPLOYMENT_CHAIN_DESCRIPTION := "完成联络、路线确认与最终简报，推进完整任务链。"
const TASK_CONTACT_OPERATOR_TITLE := "联络前线联络员"
const TASK_CONTACT_OPERATOR_DESCRIPTION := "建立通讯，确认大厅到战区之间的调度链路畅通。"
const TASK_INSPECT_ROUTE_TITLE := "确认部署路线"
const TASK_INSPECT_ROUTE_DESCRIPTION := "核对路线图和关键补给点，准备下一步作战推进。"
const TASK_FINAL_BRIEFING_TITLE := "完成最终简报"
const TASK_FINAL_BRIEFING_DESCRIPTION := "完成所有准备工作后，提交最终简报，结束整条任务链。"


static func chain_summary_text(completed_count: int, total_count: int) -> String:
	return "%d/%d 已完成" % [completed_count, total_count]


static func reward_text(reward: int) -> String:
	return "奖励 %d 金币" % reward


static func progress_text(progress: int, target: int) -> String:
	return "进度 %d/%d" % [progress, target]


static func status_text(status: String) -> String:
	match status:
		"locked":
			return "未解锁"
		"available":
			return "可接受"
		"accepted":
			return "进行中"
		"ready_to_complete":
			return "可提交"
		"completed":
			return "已完成"
		_:
			return "未知"


static func action_label(status: String) -> String:
	match status:
		"locked":
			return "未解锁"
		"available":
			return "接受任务"
		"accepted":
			return "推进任务"
		"ready_to_complete":
			return "完成任务"
		"completed":
			return "已完成"
		_:
			return "不可用"
