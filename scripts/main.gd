extends Node2D

const InputSetup = preload("res://scripts/systems/input_setup.gd")
const WaveDirectorScript = preload("res://scripts/systems/wave_director.gd")
const CoverManagerScript = preload("res://scripts/systems/cover_manager.gd")
const RangedEnemyScene := preload("res://scenes/actors/enemy.tscn")
const MeleeEnemyScene := preload("res://scenes/actors/enemy_melee.tscn")
const BulletScene := preload("res://scenes/actors/bullet.tscn")
const CoverScene := preload("res://scenes/actors/cover.tscn")
const HitSparkScene := preload("res://scenes/effects/hit_spark.tscn")

const WORLD_SIZE := Vector2(1280.0, 720.0)
const WORLD_RECT := Rect2(Vector2.ZERO, WORLD_SIZE)
const TILE_SIZE := 16
const MIN_SPAWN_DISTANCE := 112.0
const SPAWN_VIEW_MARGIN := 48.0
const NAVIGATION_MARGIN := 4.0
const COVER_COLOR := Color(0.494118, 0.529412, 0.568627, 1.0)

var cover_manager
var wave_director
var navigation_rebuild_queued: bool = false
var game_over: bool = false
var is_shutting_down: bool = false

@onready var player = $Player
@onready var covers: Node2D = $Covers
@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D
@onready var enemies: Node2D = $Enemies
@onready var bullets: Node2D = $Bullets
@onready var hit_effects: Node2D = $HitEffects
@onready var spawn_timer: Timer = $SpawnTimer
@onready var ui_controller = $CanvasLayer

func _ready() -> void:
	add_to_group("world_controller")
	InputSetup.ensure_default_actions()
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	randomize()

	wave_director = WaveDirectorScript.new()
	cover_manager = CoverManagerScript.new()
	cover_manager.setup(covers, CoverScene, WORLD_RECT, TILE_SIZE, COVER_COLOR, player)
	cover_manager.spawn_covers(Callable(self, "_on_cover_destroyed"))
	_rebuild_navigation_region()
	_configure_process_modes()
	_setup_ui()
	_setup_player()

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	_start_next_wave()
	_update_ui()
	queue_redraw()

func _process(delta: float) -> void:
	if get_tree().paused:
		return

	wave_director.update_banner(delta, game_over)
	_update_enemy_visibility()
	_update_ui()

func _exit_tree() -> void:
	is_shutting_down = true
	if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

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

func _setup_ui() -> void:
	ui_controller.restart_requested.connect(_on_restart_requested)
	ui_controller.quit_requested.connect(_on_quit_requested)

func _setup_player() -> void:
	player.configure_arena(WORLD_RECT)
	ui_controller.setup(player)

	player.shoot_requested.connect(_on_player_shoot_requested)
	player.health_changed.connect(_on_player_health_changed)
	player.defeated.connect(_on_player_defeated)

func _on_spawn_timer_timeout() -> void:
	if not wave_director.should_spawn_enemy(game_over):
		return

	var spawn_melee_enemy: bool = wave_director.pick_enemy_type_is_melee()
	var enemy_scene = MeleeEnemyScene if spawn_melee_enemy else RangedEnemyScene
	var enemy = enemy_scene.instantiate()
	enemy.global_position = _pick_spawn_position()
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.tree_exited.connect(_on_enemy_tree_exited)
	enemies.add_child(enemy)
	enemy.setup(player, WORLD_RECT, wave_director.build_enemy_config(spawn_melee_enemy), self)
	enemy.visible = player.is_point_in_vision(enemy.global_position)
	wave_director.register_enemy_spawned()

func _on_player_shoot_requested(projectiles: Array) -> void:
	if game_over:
		return

	for projectile_data_variant in projectiles:
		if typeof(projectile_data_variant) != TYPE_DICTIONARY:
			continue

		var projectile_data: Dictionary = projectile_data_variant
		if projectile_data.is_empty():
			continue

		spawn_bullet(
			projectile_data.get("origin", player.global_position),
			projectile_data.get("direction", Vector2.RIGHT),
			projectile_data.get("config", {})
		)

func _on_player_health_changed(_current_health: int) -> void:
	_update_ui()

func _on_player_defeated() -> void:
	ui_controller.close_pause_menu()
	game_over = true
	spawn_timer.stop()
	_show_banner("GAME OVER", 999.0)
	_update_ui()

func _on_enemy_defeated() -> void:
	wave_director.register_enemy_defeated()
	_update_ui()

func _on_enemy_tree_exited() -> void:
	if is_shutting_down or not is_inside_tree():
		return

	if wave_director.register_enemy_exited(game_over):
		_on_wave_cleared()

func _on_cover_destroyed(cell: Vector2i) -> void:
	if cover_manager.handle_cover_destroyed(cell):
		_queue_navigation_rebuild()

func _update_ui() -> void:
	ui_controller.apply_hud(
		{
			"health": player.current_health,
			"score": wave_director.score,
			"wave": wave_director.current_wave,
			"dash_ready": player.is_dash_ready(),
			"dash_cooldown": player.get_dash_cooldown_remaining(),
			"dash_ratio": player.get_dash_ratio(),
			"weapon_name": player.get_weapon_name(),
			"banner_text": wave_director.banner_text,
			"game_over": game_over
		}
	)

func _start_next_wave() -> void:
	wave_director.start_next_wave(spawn_timer)
	_update_ui()

func _on_wave_cleared() -> void:
	if is_shutting_down or not is_inside_tree():
		return

	if not wave_director.begin_wave_clear(player, spawn_timer):
		return

	_update_ui()
	var tree := get_tree()
	if tree == null:
		wave_director.cancel_wave_clear()
		return

	await tree.create_timer(1.2, false).timeout

	if is_shutting_down or not is_inside_tree() or game_over:
		wave_director.cancel_wave_clear()
		return

	_start_next_wave()

func _show_banner(text: String, duration: float = WaveDirectorScript.DEFAULT_BANNER_TIME) -> void:
	wave_director.set_banner(text, duration)
	_update_ui()

func _on_restart_requested() -> void:
	var tree := get_tree()
	if tree != null:
		tree.reload_current_scene()

func _on_quit_requested() -> void:
	is_shutting_down = true
	var tree := get_tree()
	if tree != null:
		tree.quit()

func _configure_process_modes() -> void:
	var pausable_nodes: Array[Node] = [
		player,
		covers,
		navigation_region,
		enemies,
		bullets,
		hit_effects,
		spawn_timer
	]

	for node in pausable_nodes:
		node.process_mode = Node.PROCESS_MODE_PAUSABLE

func _update_enemy_visibility() -> void:
	if not is_instance_valid(player):
		return

	for enemy_node in enemies.get_children():
		var enemy := enemy_node as Node2D
		if enemy == null:
			continue

		enemy.visible = player.visible and player.is_point_in_vision(enemy.global_position)

func spawn_bullet(origin: Vector2, direction: Vector2, config: Dictionary = {}) -> void:
	var bullet = BulletScene.instantiate()
	bullet.global_position = origin
	bullet.setup(direction, WORLD_RECT, config)
	bullets.add_child(bullet)

func spawn_hit_spark(impact_position: Vector2, normal: Vector2, config: Dictionary = {}) -> void:
	var hit_spark = HitSparkScene.instantiate()
	hit_spark.global_position = impact_position
	hit_effects.add_child(hit_spark)

	if hit_spark.has_method("setup"):
		hit_spark.setup(normal, config)

func find_walkable_point_near(origin: Vector2, radius: float) -> Vector2:
	return cover_manager.find_walkable_point_near(origin, radius)

func _pick_spawn_position() -> Vector2:
	var view_half_size := get_viewport_rect().size * 0.5
	var horizontal_span := view_half_size.x + SPAWN_VIEW_MARGIN
	var vertical_span := view_half_size.y + SPAWN_VIEW_MARGIN

	for _attempt in range(40):
		var side := randi_range(0, 3)
		var candidate: Vector2 = player.global_position

		match side:
			0:
				candidate += Vector2(randf_range(-horizontal_span, horizontal_span), -vertical_span)
			1:
				candidate += Vector2(horizontal_span, randf_range(-vertical_span, vertical_span))
			2:
				candidate += Vector2(randf_range(-horizontal_span, horizontal_span), vertical_span)
			_:
				candidate += Vector2(-horizontal_span, randf_range(-vertical_span, vertical_span))

		candidate = _clamp_point_to_world(candidate)

		if candidate.distance_to(player.global_position) < MIN_SPAWN_DISTANCE:
			continue

		if _is_point_walkable(candidate):
			return candidate

	return find_walkable_point_near(player.global_position, horizontal_span + 64.0)

func _rebuild_navigation_region() -> void:
	var navigation_polygon := NavigationPolygon.new()
	navigation_polygon.agent_radius = NAVIGATION_MARGIN
	navigation_polygon.sample_partition_type = NavigationPolygon.SAMPLE_PARTITION_TRIANGULATE
	navigation_polygon.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	navigation_polygon.parsed_collision_mask = 8
	navigation_polygon.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	navigation_polygon.add_outline(_build_outline_from_rect(WORLD_RECT))
	var source_geometry := NavigationMeshSourceGeometryData2D.new()
	NavigationServer2D.parse_source_geometry_data(navigation_polygon, source_geometry, self)
	NavigationServer2D.bake_from_source_geometry_data(navigation_polygon, source_geometry)
	navigation_region.navigation_polygon = navigation_polygon

func _queue_navigation_rebuild() -> void:
	if navigation_rebuild_queued:
		return

	navigation_rebuild_queued = true
	call_deferred("_rebuild_navigation_region_deferred")

func _rebuild_navigation_region_deferred() -> void:
	await get_tree().physics_frame

	if not is_inside_tree():
		return

	navigation_rebuild_queued = false
	_rebuild_navigation_region()

func _build_outline_from_rect(rect: Rect2) -> PackedVector2Array:
	var top_left := rect.position
	var top_right := Vector2(rect.end.x, rect.position.y)
	var bottom_right := rect.end
	var bottom_left := Vector2(rect.position.x, rect.end.y)

	return PackedVector2Array([top_left, bottom_left, bottom_right, top_right])

func _is_point_walkable(point: Vector2) -> bool:
	return cover_manager.is_point_walkable(point)

func _clamp_point_to_world(point: Vector2) -> Vector2:
	return cover_manager.clamp_point_to_world(point)
