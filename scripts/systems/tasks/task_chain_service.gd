class_name TaskChainService
extends RefCounted

const STATUS_LOCKED := "locked"
const STATUS_AVAILABLE := "available"
const STATUS_ACCEPTED := "accepted"
const STATUS_READY_TO_COMPLETE := "ready_to_complete"
const STATUS_COMPLETED := "completed"

var _chains: Array = []
var _tasks_by_id: Dictionary = {}


func _init(chain_definitions: Array = []) -> void:
	_initialize_chains(chain_definitions)


func get_chain_snapshots() -> Array:
	var chain_snapshots: Array = []

	for chain in _chains:
		var task_snapshots: Array = []
		var completed_count := 0
		var total_count: int = chain.get("tasks", []).size()

		for task in chain.get("tasks", []):
			var task_snapshot := _build_task_snapshot(task)
			task_snapshots.append(task_snapshot)
			if str(task_snapshot.get("status", "")) == STATUS_COMPLETED:
				completed_count += 1

		chain_snapshots.append(
			{
				"id": str(chain.get("id", "")),
				"title": str(chain.get("title", "任务链")),
				"description": str(chain.get("description", "")),
				"summary_text": "%d/%d 已完成" % [completed_count, total_count],
				"tasks": task_snapshots
			}
		)

	return chain_snapshots


func perform_primary_action(task_id: String) -> Dictionary:
	var task: Dictionary = _tasks_by_id.get(task_id, {})
	if task.is_empty():
		return {"changed": false}

	var status: String = str(task.get("status", STATUS_LOCKED))
	match status:
		STATUS_AVAILABLE:
			task["accepted"] = true
			_refresh_task_states()
			return {"changed": true, "action": "accepted", "gold_delta": 0}
		STATUS_ACCEPTED:
			var target: int = int(task.get("target", 1))
			var next_progress: int = min(target, int(task.get("progress", 0)) + 1)
			task["progress"] = next_progress
			_refresh_task_states()
			return {"changed": true, "action": "advanced", "gold_delta": 0}
		STATUS_READY_TO_COMPLETE:
			task["completed"] = true
			task["accepted"] = false
			_refresh_task_states()
			return {
				"changed": true,
				"action": "completed",
				"gold_delta": int(task.get("reward", 0))
			}
		_:
			return {"changed": false}


func _initialize_chains(chain_definitions: Array) -> void:
	_chains.clear()
	_tasks_by_id.clear()

	for chain_definition in chain_definitions:
		if not (chain_definition is Dictionary):
			continue

		var chain_copy: Dictionary = chain_definition.duplicate(true)
		var prepared_tasks: Array = []

		for task_definition in chain_copy.get("tasks", []):
			if not (task_definition is Dictionary):
				continue

			var task_copy: Dictionary = task_definition.duplicate(true)
			task_copy["progress"] = 0
			task_copy["accepted"] = false
			task_copy["completed"] = false
			task_copy["status"] = STATUS_LOCKED
			prepared_tasks.append(task_copy)
			_tasks_by_id[str(task_copy.get("id", ""))] = task_copy

		chain_copy["tasks"] = prepared_tasks
		_chains.append(chain_copy)

	_refresh_task_states()


func _refresh_task_states() -> void:
	for task in _tasks_by_id.values():
		if bool(task.get("completed", false)):
			task["status"] = STATUS_COMPLETED
			continue

		if bool(task.get("accepted", false)):
			var target: int = int(task.get("target", 1))
			task["status"] = (
				STATUS_READY_TO_COMPLETE
				if int(task.get("progress", 0)) >= target
				else STATUS_ACCEPTED
			)
			continue

		task["status"] = STATUS_AVAILABLE if _is_task_unlocked(task) else STATUS_LOCKED


func _is_task_unlocked(task: Dictionary) -> bool:
	for prerequisite_id_variant in task.get("prerequisite_task_ids", []):
		var prerequisite_id := str(prerequisite_id_variant)
		var prerequisite_task: Dictionary = _tasks_by_id.get(prerequisite_id, {})
		if prerequisite_task.is_empty():
			return false

		if not bool(prerequisite_task.get("completed", false)):
			return false

	return true


func _build_task_snapshot(task: Dictionary) -> Dictionary:
	var status: String = str(task.get("status", STATUS_LOCKED))
	var progress: int = int(task.get("progress", 0))
	var target: int = int(task.get("target", 1))

	return {
		"id": str(task.get("id", "")),
		"title": str(task.get("title", "任务")),
		"description": str(task.get("description", "")),
		"reward": int(task.get("reward", 0)),
		"status": status,
		"status_text": _get_status_text(status),
		"progress_text": "进度 %d/%d" % [progress, target],
		"action_label": _get_action_label(status),
		"action_enabled": _is_action_enabled(status)
	}


func _get_status_text(status: String) -> String:
	match status:
		STATUS_LOCKED:
			return "未解锁"
		STATUS_AVAILABLE:
			return "可接受"
		STATUS_ACCEPTED:
			return "进行中"
		STATUS_READY_TO_COMPLETE:
			return "可提交"
		STATUS_COMPLETED:
			return "已完成"
		_:
			return "未知"


func _get_action_label(status: String) -> String:
	match status:
		STATUS_LOCKED:
			return "未解锁"
		STATUS_AVAILABLE:
			return "接受任务"
		STATUS_ACCEPTED:
			return "推进任务"
		STATUS_READY_TO_COMPLETE:
			return "完成任务"
		STATUS_COMPLETED:
			return "已完成"
		_:
			return "不可用"


func _is_action_enabled(status: String) -> bool:
	return status in [STATUS_AVAILABLE, STATUS_ACCEPTED, STATUS_READY_TO_COMPLETE]
