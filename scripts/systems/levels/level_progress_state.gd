class_name LevelProgressState
extends RefCounted

const SAVE_PATH := "user://level_progress.cfg"
const LevelRepositoryScript = preload("res://scripts/systems/levels/level_repository.gd")
const LevelSnapshotBuilderScript = preload("res://scripts/systems/levels/level_snapshot_builder.gd")

static var _loaded := false
static var _completed_level_ids: Dictionary = {}
static var _selected_level_id := ""
static var _active_challenge_level_id := ""


static func get_level_snapshots() -> Array:
	_ensure_loaded()
	return LevelSnapshotBuilderScript.build_snapshots(LevelRepositoryScript.get_levels(), _completed_level_ids)


static func get_level_definition(level_id: String) -> Dictionary:
	_ensure_loaded()
	return LevelRepositoryScript.get_level(level_id)


static func get_selected_level_id() -> String:
	_ensure_loaded()
	return _selected_level_id


static func get_active_challenge_level_definition() -> Dictionary:
	_ensure_loaded()
	return get_level_definition(_active_challenge_level_id)


static func clear_active_challenge() -> void:
	_active_challenge_level_id = ""


static func select_level(level_id: String) -> bool:
	_ensure_loaded()
	var level := LevelRepositoryScript.get_level(level_id)
	if level.is_empty():
		return false

	_selected_level_id = level_id
	_save_state()
	return true


static func start_challenge(level_id: String) -> bool:
	_ensure_loaded()
	var level := LevelRepositoryScript.get_level(level_id)
	if level.is_empty():
		return false
	if not LevelSnapshotBuilderScript.is_level_unlocked(level, _completed_level_ids):
		return false

	_selected_level_id = level_id
	_active_challenge_level_id = level_id
	_save_state()
	return true


static func complete_active_level() -> void:
	_ensure_loaded()
	if _active_challenge_level_id.is_empty():
		return

	_completed_level_ids[_active_challenge_level_id] = true
	_selected_level_id = _active_challenge_level_id
	_active_challenge_level_id = ""
	_save_state()


static func get_first_unlocked_level_id() -> String:
	_ensure_loaded()
	return LevelSnapshotBuilderScript.get_first_unlocked_level_id(
		LevelRepositoryScript.get_levels(),
		_completed_level_ids
	)


static func _ensure_loaded() -> void:
	if _loaded:
		return

	_loaded = true
	_selected_level_id = LevelSnapshotBuilderScript.get_default_level_id(LevelRepositoryScript.get_levels())
	_completed_level_ids.clear()
	_active_challenge_level_id = ""

	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		_selected_level_id = get_first_unlocked_level_id()
		return

	_selected_level_id = str(config.get_value("progress", "selected_level_id", _selected_level_id))
	for level_id_variant in config.get_value("progress", "completed_level_ids", PackedStringArray()):
		_completed_level_ids[str(level_id_variant)] = true

	if LevelRepositoryScript.get_level(_selected_level_id).is_empty():
		_selected_level_id = get_first_unlocked_level_id()


static func _save_state() -> void:
	var config := ConfigFile.new()
	var completed_ids := PackedStringArray()
	for level_id in _completed_level_ids.keys():
		completed_ids.append(str(level_id))

	config.set_value("progress", "selected_level_id", _selected_level_id)
	config.set_value("progress", "completed_level_ids", completed_ids)
	config.save(SAVE_PATH)
