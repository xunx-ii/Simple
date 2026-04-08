class_name TaskSystem
extends RefCounted

signal tasks_updated(tasks: Array, total_gold: int)

var _player_name := "测试玩家"
var _gold := 1200
var _tasks: Array[Dictionary] = [
	{
		"id": "daily_signin",
		"title": "完成每日签到",
		"description": "进入大厅后完成今日签到，领取基础补给。",
		"reward": 100,
		"completed": false
	},
	{
		"id": "briefing_review",
		"title": "查看作战简报",
		"description": "打开任务面板，阅读当前战区的作战安排。",
		"reward": 150,
		"completed": false
	},
	{
		"id": "prepare_loadout",
		"title": "整理出战配置",
		"description": "检查武器、补给与金币储备，为下一场战斗做准备。",
		"reward": 200,
		"completed": false
	}
]


func get_player_name() -> String:
	return _player_name


func get_gold() -> int:
	return _gold


func get_tasks() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for task in _tasks:
		snapshot.append(task.duplicate(true))
	return snapshot


func complete_task(task_id: String) -> void:
	for task in _tasks:
		if str(task.get("id", "")) != task_id:
			continue

		if bool(task.get("completed", false)):
			return

		task["completed"] = true
		_gold += int(task.get("reward", 0))
		tasks_updated.emit(get_tasks(), _gold)
		return
