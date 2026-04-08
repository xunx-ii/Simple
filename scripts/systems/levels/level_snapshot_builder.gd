class_name LevelSnapshotBuilder
extends RefCounted


static func build_snapshots(levels: Array, completed_level_ids: Dictionary) -> Array:
	var snapshots: Array = []
	for level_variant in levels:
		var level: Dictionary = level_variant
		snapshots.append(build_snapshot(level, completed_level_ids))
	return snapshots


static func build_snapshot(level: Dictionary, completed_level_ids: Dictionary) -> Dictionary:
	var level_id := str(level.get("id", ""))
	return {
		"id": level_id,
		"short_title": str(level.get("short_title", "")),
		"title": str(level.get("title", "")),
		"description": str(level.get("description", "")),
		"boss": bool(level.get("boss", false)),
		"required_wave_count": int(level.get("required_wave_count", 1)),
		"position": level.get("position", Vector2.ZERO),
		"prerequisite_ids": level.get("prerequisite_ids", PackedStringArray()),
		"completed": completed_level_ids.has(level_id),
		"unlocked": is_level_unlocked(level, completed_level_ids)
	}


static func is_level_unlocked(level: Dictionary, completed_level_ids: Dictionary) -> bool:
	var prerequisite_ids: PackedStringArray = level.get("prerequisite_ids", PackedStringArray())
	if prerequisite_ids.is_empty():
		return true

	for prerequisite_id in prerequisite_ids:
		if not completed_level_ids.has(str(prerequisite_id)):
			return false

	return true


static func get_first_unlocked_level_id(levels: Array, completed_level_ids: Dictionary) -> String:
	for level_variant in levels:
		var level: Dictionary = level_variant
		if is_level_unlocked(level, completed_level_ids):
			return str(level.get("id", ""))
	return get_default_level_id(levels)


static func get_default_level_id(levels: Array) -> String:
	if levels.is_empty():
		return ""
	return str(Dictionary(levels[0]).get("id", ""))
