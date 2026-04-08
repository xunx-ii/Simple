class_name LevelProgressState
extends RefCounted

const SAVE_PATH := "user://level_progress.cfg"
const LevelRepositoryScript = preload("res://scripts/systems/levels/level_repository.gd")

static var _loaded := false
static var _completed_level_ids: Dictionary = {}
static var _active_level_id := ""


static func get_level_snapshots() -> Array:
	_ensure_loaded()

	var snapshots: Array = []
	for level_variant in LevelRepositoryScript.get_levels():
		var level: Dictionary = level_variant
		var level_id := str(level.get("id", ""))
		snapshots.append(
			{
				"id": level_id,
				"short_title": str(level.get("short_title", "")),
				"title": str(level.get("title", "")),
				"description": str(level.get("description", "")),
				"boss": bool(level.get("boss", false)),
				"required_wave_count": int(level.get("required_wave_count", 1)),
				"position": level.get("position", Vector2.ZERO),
				"prerequisite_ids": level.get("prerequisite_ids", PackedStringArray()),
				"completed": _completed_level_ids.has(level_id),
				"unlocked": _is_level_unlocked(level)
			}
		)

	return snapshots


static func get_level_definition(level_id: String) -> Dictionary:
	_ensure_loaded()
	return LevelRepositoryScript.get_level(level_id)


static func get_active_level_definition() -> Dictionary:
	_ensure_loaded()
	return get_level_definition(_active_level_id)


static func start_challenge(level_id: String) -> bool:
	_ensure_loaded()
	var level := LevelRepositoryScript.get_level(level_id)
	if level.is_empty():
		return false
	if not _is_level_unlocked(level):
		return false

	_active_level_id = level_id
	_save_state()
	return true


static func complete_active_level() -> void:
	_ensure_loaded()
	if _active_level_id.is_empty():
		return

	_completed_level_ids[_active_level_id] = true
	_save_state()


static func get_first_unlocked_level_id() -> String:
	_ensure_loaded()
	for snapshot_variant in get_level_snapshots():
		var snapshot: Dictionary = snapshot_variant
		if bool(snapshot.get("unlocked", false)):
			return str(snapshot.get("id", ""))
	return _get_default_level_id()


static func _ensure_loaded() -> void:
	if _loaded:
		return

	_loaded = true
	_active_level_id = _get_default_level_id()
	_completed_level_ids.clear()

	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return

	_active_level_id = str(config.get_value("progress", "active_level_id", _active_level_id))
	for level_id_variant in config.get_value("progress", "completed_level_ids", PackedStringArray()):
		_completed_level_ids[str(level_id_variant)] = true

	if LevelRepositoryScript.get_level(_active_level_id).is_empty():
		_active_level_id = _get_default_level_id()


static func _save_state() -> void:
	var config := ConfigFile.new()
	var completed_ids := PackedStringArray()
	for level_id in _completed_level_ids.keys():
		completed_ids.append(str(level_id))

	config.set_value("progress", "active_level_id", _active_level_id)
	config.set_value("progress", "completed_level_ids", completed_ids)
	config.save(SAVE_PATH)


static func _get_default_level_id() -> String:
	var levels := LevelRepositoryScript.get_levels()
	if levels.is_empty():
		return ""
	return str(Dictionary(levels[0]).get("id", ""))


static func _is_level_unlocked(level: Dictionary) -> bool:
	var prerequisite_ids: PackedStringArray = level.get("prerequisite_ids", PackedStringArray())
	if prerequisite_ids.is_empty():
		return true

	for prerequisite_id in prerequisite_ids:
		if not _completed_level_ids.has(str(prerequisite_id)):
			return false

	return true
