class_name LevelRepository
extends RefCounted


static func get_levels() -> Array:
	return [
		{
			"id": "stage_1",
			"short_title": "1-1",
			"title": "1-1 废墟入口",
			"description": "清理城区外围的游荡敌群，打通进入战区的第一条安全路线。",
			"boss": false,
			"required_wave_count": 2,
			"position": Vector2(0.14, 0.52),
			"prerequisite_ids": PackedStringArray()
		},
		{
			"id": "stage_2",
			"short_title": "1-2",
			"title": "1-2 东区补给线",
			"description": "稳住东侧补给通道，确保补给车队可以继续推进。",
			"boss": false,
			"required_wave_count": 3,
			"position": Vector2(0.36, 0.30),
			"prerequisite_ids": PackedStringArray(["stage_1"])
		},
		{
			"id": "stage_3",
			"short_title": "1-3",
			"title": "1-3 西区监控站",
			"description": "夺回监控站视野，重新建立对西区的火力预警。",
			"boss": false,
			"required_wave_count": 3,
			"position": Vector2(0.36, 0.74),
			"prerequisite_ids": PackedStringArray(["stage_1"])
		},
		{
			"id": "stage_4",
			"short_title": "1-4",
			"title": "1-4 中央集散地",
			"description": "在中央集散地会合友军，完成对核心区域的最终包围。",
			"boss": false,
			"required_wave_count": 4,
			"position": Vector2(0.61, 0.52),
			"prerequisite_ids": PackedStringArray(["stage_2", "stage_3"])
		},
		{
			"id": "boss_1",
			"short_title": "BOSS",
			"title": "BOSS 核心巢穴",
			"description": "突入敌方巢穴核心，击溃首领，完成本章节收尾战斗。",
			"boss": true,
			"required_wave_count": 5,
			"position": Vector2(0.84, 0.52),
			"prerequisite_ids": PackedStringArray(["stage_4"])
		}
	]


static func get_level(level_id: String) -> Dictionary:
	for level_variant in get_levels():
		var level: Dictionary = level_variant
		if str(level.get("id", "")) == level_id:
			return level.duplicate(true)
	return {}
