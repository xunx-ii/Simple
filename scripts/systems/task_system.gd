class_name TaskSystem
extends RefCounted

signal tasks_updated(task_chains: Array, total_gold: int)

const TaskChainRepositoryScript = preload("res://scripts/systems/tasks/task_chain_repository.gd")
const TaskChainServiceScript = preload("res://scripts/systems/tasks/task_chain_service.gd")
const MetaProgressionStateScript = preload("res://scripts/systems/meta_progression_state.gd")

var _task_chain_service


func _init() -> void:
	_task_chain_service = TaskChainServiceScript.new(TaskChainRepositoryScript.build_chains())


func get_player_name() -> String:
	return MetaProgressionStateScript.get_player_name()


func get_gold() -> int:
	return MetaProgressionStateScript.get_gold()


func get_task_chains() -> Array:
	return _task_chain_service.get_chain_snapshots()


func perform_task_action(task_id: String) -> Dictionary:
	var result: Dictionary = _task_chain_service.perform_primary_action(task_id)
	if not bool(result.get("changed", false)):
		return result

	var gold_delta := int(result.get("gold_delta", 0))
	if gold_delta > 0:
		MetaProgressionStateScript.add_gold(gold_delta)

	tasks_updated.emit(get_task_chains(), get_gold())
	return result
