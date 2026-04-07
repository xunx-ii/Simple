extends Node2D

const InputSetup = preload("res://scripts/systems/input_setup.gd")
const EnemyScene := preload("res://scenes/actors/enemy.tscn")
const BulletScene := preload("res://scenes/actors/bullet.tscn")
const CoverScene := preload("res://scenes/actors/cover.tscn")

const WORLD_SIZE := Vector2(1280.0, 720.0)
const WORLD_RECT := Rect2(Vector2.ZERO, WORLD_SIZE)
const TILE_SIZE := 16
const MAX_SIMULTANEOUS_ENEMIES := 12
const MIN_SPAWN_DISTANCE := 240.0
const WAVE_BANNER_TIME := 1.8
const COVER_LAYOUT := [
	{"pos": Vector2i(8, 6), "size": Vector2i(8, 2), "health": 5, "tint": Color(0.478431, 0.572549, 0.423529, 1.0)},
	{"pos": Vector2i(6, 10), "size": Vector2i(2, 8), "health": 5, "tint": Color(0.478431, 0.572549, 0.423529, 1.0)},
	{"pos": Vector2i(14, 14), "size": Vector2i(6, 2), "health": 4, "tint": Color(0.478431, 0.572549, 0.423529, 1.0)},
	{"pos": Vector2i(24, 7), "size": Vector2i(10, 2), "health": 6, "tint": Color(0.65098, 0.552941, 0.380392, 1.0)},
	{"pos": Vector2i(28, 11), "size": Vector2i(2, 7), "health": 5, "tint": Color(0.65098, 0.552941, 0.380392, 1.0)},
	{"pos": Vector2i(22, 20), "size": Vector2i(8, 2), "health": 5, "tint": Color(0.65098, 0.552941, 0.380392, 1.0)},
	{"pos": Vector2i(40, 10), "size": Vector2i(2, 10), "health": 6, "tint": Color(0.564706, 0.494118, 0.658824, 1.0)},
	{"pos": Vector2i(46, 8), "size": Vector2i(9, 2), "health": 6, "tint": Color(0.564706, 0.494118, 0.658824, 1.0)},
	{"pos": Vector2i(52, 14), "size": Vector2i(2, 8), "health": 5, "tint": Color(0.564706, 0.494118, 0.658824, 1.0)},
	{"pos": Vector2i(44, 24), "size": Vector2i(10, 2), "health": 6, "tint": Color(0.564706, 0.494118, 0.658824, 1.0)},
	{"pos": Vector2i(12, 28), "size": Vector2i(12, 2), "health": 7, "tint": Color(0.427451, 0.603922, 0.647059, 1.0)},
	{"pos": Vector2i(18, 30), "size": Vector2i(2, 8), "health": 5, "tint": Color(0.427451, 0.603922, 0.647059, 1.0)},
	{"pos": Vector2i(30, 32), "size": Vector2i(16, 2), "health": 8, "tint": Color(0.427451, 0.603922, 0.647059, 1.0)},
	{"pos": Vector2i(48, 30), "size": Vector2i(2, 8), "health": 5, "tint": Color(0.427451, 0.603922, 0.647059, 1.0)},
	{"pos": Vector2i(60, 22), "size": Vector2i(10, 2), "health": 6, "tint": Color(0.74902, 0.447059, 0.4, 1.0)},
	{"pos": Vector2i(64, 26), "size": Vector2i(2, 10), "health": 6, "tint": Color(0.74902, 0.447059, 0.4, 1.0)},
	{"pos": Vector2i(8, 36), "size": Vector2i(10, 2), "health": 6, "tint": Color(0.74902, 0.447059, 0.4, 1.0)},
	{"pos": Vector2i(58, 38), "size": Vector2i(12, 2), "health": 7, "tint": Color(0.74902, 0.447059, 0.4, 1.0)}
]

var navigation_grid: AStarGrid2D = AStarGrid2D.new()
var score: int = 0
var game_over: bool = false
var current_wave: int = 0
var enemies_alive: int = 0
var enemies_remaining_to_spawn: int = 0
var banner_time_remaining: float = 0.0

@onready var player = $Player
@onready var covers: Node2D = $Covers
@onready var enemies: Node2D = $Enemies
@onready var bullets: Node2D = $Bullets
@onready var spawn_timer: Timer = $SpawnTimer
@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var state_label: Label = $CanvasLayer/StateLabel
@onready var restart_label: Label = $CanvasLayer/RestartLabel
@onready var wave_label: Label = $CanvasLayer/WaveLabel
@onready var dash_label: Label = $CanvasLayer/DashLabel
@onready var dash_bar_fill: ColorRect = $CanvasLayer/DashBarFill
@onready var banner_label: Label = $CanvasLayer/BannerLabel

func _ready() -> void:
	InputSetup.ensure_default_actions()
	randomize()
	_setup_navigation_grid()
	_spawn_covers()

	player.configure_arena(WORLD_RECT)
	player.shoot_requested.connect(_on_player_shoot_requested)
	player.health_changed.connect(_on_player_health_changed)
	player.defeated.connect(_on_player_defeated)

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	_start_next_wave()
	_update_ui()
	queue_redraw()

func _process(delta: float) -> void:
	if game_over and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

	if banner_time_remaining > 0.0:
		banner_time_remaining = max(banner_time_remaining - delta, 0.0)
		if banner_time_remaining == 0.0 and not game_over:
			banner_label.text = ""

	_update_ui()

func _draw() -> void:
	draw_rect(WORLD_RECT, Color(0.05, 0.06, 0.08, 1.0), true)

	var district_size := Vector2(320.0, 240.0)
	var district_palette := [
		Color(0.09, 0.11, 0.14, 1.0),
		Color(0.11, 0.10, 0.14, 1.0),
		Color(0.09, 0.12, 0.11, 1.0),
		Color(0.12, 0.10, 0.10, 1.0)
	]

	for district_x in range(0, 4):
		for district_y in range(0, 3):
			var district_index: int = (district_x + district_y) % district_palette.size()
			var district_rect := Rect2(Vector2(district_x, district_y) * district_size, district_size)
			draw_rect(district_rect, district_palette[district_index], true)

	draw_rect(Rect2(Vector2(600.0, 0.0), Vector2(80.0, WORLD_SIZE.y)), Color(0.15, 0.17, 0.20, 0.55), true)
	draw_rect(Rect2(Vector2(0.0, 336.0), Vector2(WORLD_SIZE.x, 48.0)), Color(0.15, 0.17, 0.20, 0.55), true)
	draw_rect(Rect2(Vector2(104.0, 96.0), Vector2(192.0, 96.0)), Color(0.13, 0.18, 0.20, 0.4), true)
	draw_rect(Rect2(Vector2(912.0, 480.0), Vector2(208.0, 112.0)), Color(0.20, 0.14, 0.14, 0.35), true)

	for x in range(0, int(WORLD_SIZE.x), TILE_SIZE):
		for y in range(0, int(WORLD_SIZE.y), TILE_SIZE):
			var tile_rect: Rect2 = Rect2(Vector2(x, y), Vector2.ONE * TILE_SIZE)
			var tile_x: int = int(x / float(TILE_SIZE))
			var tile_y: int = int(y / float(TILE_SIZE))
			var use_alt_color: bool = (tile_x + tile_y) % 2 == 0
			var tile_color: Color = Color(0.11, 0.13, 0.16, 0.32) if use_alt_color else Color(0.08, 0.10, 0.13, 0.32)
			draw_rect(tile_rect, tile_color, true)

	for x in range(0, int(WORLD_SIZE.x) + 1, TILE_SIZE):
		draw_line(Vector2(x, 0.0), Vector2(x, WORLD_SIZE.y), Color(0.17, 0.19, 0.22, 0.28), 1.0)

	for y in range(0, int(WORLD_SIZE.y) + 1, TILE_SIZE):
		draw_line(Vector2(0.0, y), Vector2(WORLD_SIZE.x, y), Color(0.17, 0.19, 0.22, 0.28), 1.0)

	draw_rect(WORLD_RECT, Color(0.58, 0.62, 0.68, 1.0), false, 3.0)

func _on_spawn_timer_timeout() -> void:
	if game_over:
		return

	if enemies_remaining_to_spawn <= 0:
		return

	if enemies_alive >= MAX_SIMULTANEOUS_ENEMIES:
		return

	var enemy = EnemyScene.instantiate()
	enemy.global_position = _pick_spawn_position()
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.tree_exited.connect(_on_enemy_tree_exited)
	enemies.add_child(enemy)
	enemy.setup(player, WORLD_RECT, _build_enemy_config(), self)
	enemies_alive += 1
	enemies_remaining_to_spawn -= 1

func _on_player_shoot_requested(origin: Vector2, direction: Vector2) -> void:
	if game_over:
		return

	var bullet = BulletScene.instantiate()
	bullet.global_position = origin
	bullet.setup(direction, WORLD_RECT)
	bullets.add_child(bullet)

func _on_player_health_changed(_current_health: int) -> void:
	_update_ui()

func _on_player_defeated() -> void:
	game_over = true
	spawn_timer.stop()
	state_label.text = "Game Over"
	restart_label.visible = true
	banner_label.text = "GAME OVER"
	banner_time_remaining = 999.0

func _on_enemy_defeated() -> void:
	score += 1
	_update_ui()

func _on_enemy_tree_exited() -> void:
	enemies_alive = max(enemies_alive - 1, 0)

	if game_over:
		return

	if enemies_alive == 0 and enemies_remaining_to_spawn == 0:
		_on_wave_cleared()

func _on_cover_destroyed(cell_rect: Rect2i) -> void:
	_mark_cell_rect(cell_rect, false)

func _update_ui() -> void:
	score_label.text = "HP: %d  SCORE: %d" % [player.current_health, score]
	wave_label.text = "WAVE %d" % current_wave
	dash_label.text = "DASH READY" if player.is_dash_ready() else "DASH %.1f" % player.get_dash_cooldown_remaining()

	var dash_ratio: float = player.get_dash_ratio()
	dash_bar_fill.size.x = 72.0 * dash_ratio
	dash_bar_fill.color = Color(0.35, 0.87, 1.0, 1.0) if player.is_dash_ready() else Color(0.31, 0.67, 0.96, 1.0)

	if game_over:
		return

	restart_label.visible = false
	state_label.text = "WASD Move  SHIFT Dash\nMouse Aim  LMB Shoot\nShoot cover to open routes"

func _start_next_wave() -> void:
	current_wave += 1
	enemies_remaining_to_spawn = 4 + current_wave * 2
	enemies_alive = 0
	spawn_timer.wait_time = max(1.0 - float(current_wave - 1) * 0.08, 0.4)
	spawn_timer.start()
	_show_banner("WAVE %d" % current_wave)
	_update_ui()

func _on_wave_cleared() -> void:
	player.recover(1)
	spawn_timer.stop()
	_show_banner("WAVE %d CLEAR" % current_wave)
	await get_tree().create_timer(1.2).timeout

	if game_over:
		return

	_start_next_wave()

func _show_banner(text: String) -> void:
	banner_label.text = text
	banner_time_remaining = WAVE_BANNER_TIME

func _build_enemy_config() -> Dictionary:
	return {
		"move_speed": 34.0 + current_wave * 3.0,
		"max_health": 1 + floori(current_wave / 2.0),
		"touch_damage": 1,
		"attack_cooldown": max(1.0 - current_wave * 0.04, 0.55),
		"sight_range": 176.0 + current_wave * 6.0,
		"attack_range": 20.0 + min(current_wave, 4),
		"patrol_radius": 112.0 + current_wave * 6.0,
		"chase_speed_multiplier": 1.18 + current_wave * 0.015
	}

func _setup_navigation_grid() -> void:
	navigation_grid.region = Rect2i(Vector2i.ZERO, Vector2i(int(WORLD_SIZE.x / TILE_SIZE), int(WORLD_SIZE.y / TILE_SIZE)))
	navigation_grid.cell_size = Vector2.ONE * TILE_SIZE
	navigation_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	navigation_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	navigation_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation_grid.update()

func _spawn_covers() -> void:
	for cover_config in COVER_LAYOUT:
		var cell_rect := Rect2i(cover_config["pos"], cover_config["size"])
		var cover = CoverScene.instantiate()
		cover.global_position = _cell_rect_to_world_center(cell_rect)
		covers.add_child(cover)
		cover.configure(TILE_SIZE, cover_config["size"], cover_config["health"], cover_config["tint"], cell_rect)
		cover.destroyed.connect(_on_cover_destroyed)
		_mark_cell_rect(cell_rect, true)

func _mark_cell_rect(cell_rect: Rect2i, solid: bool) -> void:
	for x in range(cell_rect.position.x, cell_rect.end.x):
		for y in range(cell_rect.position.y, cell_rect.end.y):
			var cell := Vector2i(x, y)
			if navigation_grid.region.has_point(cell):
				navigation_grid.set_point_solid(cell, solid)

func request_path(from_position: Vector2, to_position: Vector2) -> PackedVector2Array:
	var start_cell: Vector2i = _nearest_walkable_cell(_world_to_cell(from_position))
	var end_cell: Vector2i = _nearest_walkable_cell(_world_to_cell(to_position))

	if start_cell == Vector2i(-1, -1) or end_cell == Vector2i(-1, -1):
		return PackedVector2Array([_clamp_point_to_world(to_position)])

	var path: PackedVector2Array = navigation_grid.get_point_path(start_cell, end_cell)
	if path.is_empty():
		return PackedVector2Array([_cell_to_world(end_cell)])

	return path

func find_walkable_point_near(origin: Vector2, radius: float) -> Vector2:
	for _attempt in range(20):
		var candidate := origin + Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
		candidate = _clamp_point_to_world(candidate)
		if _is_cell_walkable(_world_to_cell(candidate)):
			return candidate

	var fallback_cell: Vector2i = _nearest_walkable_cell(_world_to_cell(origin))
	if fallback_cell == Vector2i(-1, -1):
		return WORLD_RECT.get_center()

	return _cell_to_world(fallback_cell)

func _pick_spawn_position() -> Vector2:
	var margin := 24.0

	for _attempt in range(32):
		var side := randi_range(0, 3)
		var candidate: Vector2 = WORLD_RECT.get_center()

		match side:
			0:
				candidate = Vector2(randf_range(margin, WORLD_SIZE.x - margin), margin)
			1:
				candidate = Vector2(WORLD_SIZE.x - margin, randf_range(margin, WORLD_SIZE.y - margin))
			2:
				candidate = Vector2(randf_range(margin, WORLD_SIZE.x - margin), WORLD_SIZE.y - margin)
			_:
				candidate = Vector2(margin, randf_range(margin, WORLD_SIZE.y - margin))

		if candidate.distance_to(player.global_position) < MIN_SPAWN_DISTANCE:
			continue

		if _is_cell_walkable(_world_to_cell(candidate)):
			return candidate

	return find_walkable_point_near(WORLD_RECT.get_center(), 240.0)

func _world_to_cell(point: Vector2) -> Vector2i:
	var clamped_position: Vector2 = _clamp_point_to_world(point)
	var cell_x: int = clampi(int(floor(clamped_position.x / TILE_SIZE)), 0, navigation_grid.region.size.x - 1)
	var cell_y: int = clampi(int(floor(clamped_position.y / TILE_SIZE)), 0, navigation_grid.region.size.y - 1)
	return Vector2i(cell_x, cell_y)

func _cell_to_world(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2.ONE * 0.5) * TILE_SIZE

func _cell_rect_to_world_center(cell_rect: Rect2i) -> Vector2:
	return (Vector2(cell_rect.position) + Vector2(cell_rect.size) * 0.5) * TILE_SIZE

func _nearest_walkable_cell(origin_cell: Vector2i) -> Vector2i:
	if _is_cell_walkable(origin_cell):
		return origin_cell

	for radius in range(1, 8):
		for offset_x in range(-radius, radius + 1):
			for offset_y in range(-radius, radius + 1):
				var candidate := origin_cell + Vector2i(offset_x, offset_y)
				if _is_cell_walkable(candidate):
					return candidate

	return Vector2i(-1, -1)

func _is_cell_walkable(cell: Vector2i) -> bool:
	if not navigation_grid.region.has_point(cell):
		return false

	return not navigation_grid.is_point_solid(cell)

func _clamp_point_to_world(point: Vector2) -> Vector2:
	return point.clamp(WORLD_RECT.position + Vector2.ONE * 8.0, WORLD_RECT.end - Vector2.ONE * 8.0)
