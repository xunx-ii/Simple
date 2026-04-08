extends Node2D

const InputSetup = preload("res://scripts/systems/input_setup.gd")
const LevelProgressStateScript = preload("res://scripts/systems/levels/level_progress_state.gd")
const WaveDirectorScript = preload("res://scripts/systems/wave_director.gd")
const CoverManagerScript = preload("res://scripts/systems/cover_manager.gd")
const ShopServiceScript = preload("res://scripts/systems/shop_service.gd")
const HUDStateBuilderScript = preload("res://scripts/systems/hud_state_builder.gd")
const EnemySpawnServiceScript = preload("res://scripts/systems/enemy_spawn_service.gd")
const RangedEnemyScene := preload("res://scenes/actors/enemy.tscn")
const MeleeEnemyScene := preload("res://scenes/actors/enemy_melee.tscn")
const BulletScene := preload("res://scenes/actors/bullet.tscn")
const CoverScene := preload("res://scenes/actors/cover.tscn")
const HitSparkScene := preload("res://scenes/effects/hit_spark.tscn")
const LootPickupScene := preload("res://scenes/actors/loot_pickup.tscn")

const WORLD_SIZE := Vector2(1280.0, 720.0)
const WORLD_RECT := Rect2(Vector2.ZERO, WORLD_SIZE)
const TILE_SIZE := 16
const MIN_SPAWN_DISTANCE := 112.0
const SPAWN_VIEW_MARGIN := 48.0
const NAVIGATION_MARGIN := 4.0
const LOBBY_SCENE_PATH := "res://scenes/lobby.tscn"
const COVER_COLOR := Color(0.494118, 0.529412, 0.568627, 1.0)
const GAME_OVER_BANNER_TEXT := "\u6E38\u620F\u7ED3\u675F"
const LEVEL_COMPLETED_BANNER_TEXT := "关卡通关"

var cover_manager
var wave_director
var shop_service
var enemy_spawn_service
var navigation_rebuild_queued: bool = false
var game_over: bool = false
var is_shutting_down: bool = false
var level_completed: bool = false
var active_level: Dictionary = {}

@onready var player = $Player
@onready var covers: Node2D = $Covers
@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D
@onready var enemies: Node2D = $Enemies
@onready var merchant_npc: Node2D = $MerchantNPC
@onready var loot_drops: Node2D = $LootDrops
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
	shop_service = ShopServiceScript.new()
	enemy_spawn_service = EnemySpawnServiceScript.new()

	cover_manager.setup(covers, CoverScene, WORLD_RECT, TILE_SIZE, COVER_COLOR, player)
	cover_manager.spawn_covers(Callable(self, "_on_cover_destroyed"))
	_rebuild_navigation_region()
	_configure_process_modes()
	_setup_ui()
	_setup_player()
	_setup_merchant()
	_setup_services()
	active_level = LevelProgressStateScript.get_active_level_definition()

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
			var tile_rect := Rect2(Vector2(x, y), Vector2.ONE * TILE_SIZE)
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
	if ui_controller.has_signal("shop_purchase_requested"):
		ui_controller.shop_purchase_requested.connect(_on_shop_purchase_requested)
	if ui_controller.has_signal("shop_sell_requested"):
		ui_controller.shop_sell_requested.connect(_on_shop_sell_requested)
	if ui_controller.has_signal("shop_closed"):
		ui_controller.shop_closed.connect(_on_shop_closed)

func _setup_player() -> void:
	player.configure_arena(WORLD_RECT)
	ui_controller.setup(player)

	player.shoot_requested.connect(_on_player_shoot_requested)
	player.health_changed.connect(_on_player_health_changed)
	player.inventory_changed.connect(_on_player_inventory_changed)
	player.currency_changed.connect(_on_player_currency_changed)
	player.defeated.connect(_on_player_defeated)

func _setup_merchant() -> void:
	if merchant_npc == null:
		return

	if merchant_npc.has_method("setup"):
		merchant_npc.setup(player)

	if merchant_npc.has_signal("shop_requested"):
		merchant_npc.shop_requested.connect(_on_merchant_shop_requested)

func _setup_services() -> void:
	if shop_service != null and shop_service.has_method("setup"):
		shop_service.setup(merchant_npc, player, ui_controller)

	if enemy_spawn_service != null and enemy_spawn_service.has_method("setup"):
		enemy_spawn_service.setup(
			{
				"player": player,
				"enemies_container": enemies,
				"wave_director": wave_director,
				"world_rect": WORLD_RECT,
				"ranged_enemy_scene": RangedEnemyScene,
				"melee_enemy_scene": MeleeEnemyScene,
				"world_controller": self,
				"enemy_defeated_callback": Callable(self, "_on_enemy_defeated"),
				"enemy_tree_exited_callback": Callable(self, "_on_enemy_tree_exited"),
				"is_walkable_callable": Callable(self, "_is_point_walkable"),
				"clamp_point_callable": Callable(self, "_clamp_point_to_world"),
				"find_walkable_point_callable": Callable(self, "find_walkable_point_near"),
				"min_spawn_distance": MIN_SPAWN_DISTANCE,
				"spawn_view_margin": SPAWN_VIEW_MARGIN
			}
		)

func _on_spawn_timer_timeout() -> void:
	if enemy_spawn_service == null:
		return

	enemy_spawn_service.spawn_next_enemy(game_over)

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

func _on_player_inventory_changed(_inventory_snapshot: Dictionary) -> void:
	_refresh_shop_ui()
	_update_ui()

func _on_player_currency_changed(_current_gold: int) -> void:
	_refresh_shop_ui()
	_update_ui()

func _on_merchant_shop_requested() -> void:
	if game_over or shop_service == null:
		return

	if shop_service.open_shop():
		_update_ui()

func _on_shop_purchase_requested(item_id: String) -> void:
	if shop_service == null:
		return

	_handle_shop_feedback(shop_service.buy_item(item_id))

func _on_shop_sell_requested(item_id: String) -> void:
	if shop_service == null:
		return

	_handle_shop_feedback(shop_service.sell_item(item_id))

func _on_shop_closed() -> void:
	_update_ui()

func _on_player_defeated() -> void:
	ui_controller.close_pause_menu()
	if ui_controller.has_method("close_shop_menu"):
		ui_controller.close_shop_menu()

	game_over = true
	spawn_timer.stop()
	_show_banner(GAME_OVER_BANNER_TEXT, 999.0)
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
	ui_controller.apply_hud(_build_hud_state())

func _refresh_shop_ui() -> void:
	if shop_service == null:
		return

	shop_service.refresh_open_shop()

func _handle_shop_feedback(feedback: Dictionary) -> void:
	if feedback.is_empty():
		return

	var banner_text: String = str(feedback.get("banner_text", ""))
	if not banner_text.is_empty():
		_show_banner(
			banner_text,
			float(feedback.get("banner_duration", WaveDirectorScript.DEFAULT_BANNER_TIME))
		)
	elif bool(feedback.get("refresh_ui", false)):
		_update_ui()

func _start_next_wave() -> void:
	wave_director.start_next_wave(spawn_timer)
	_update_ui()

func _on_wave_cleared() -> void:
	if is_shutting_down or not is_inside_tree():
		return

	if _is_level_target_reached():
		await _complete_level_and_return_to_lobby()
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


func _is_level_target_reached() -> bool:
	if level_completed or active_level.is_empty() or wave_director == null:
		return false

	var required_wave_count := int(active_level.get("required_wave_count", 0))
	if required_wave_count <= 0:
		return false

	return int(wave_director.get("current_wave")) >= required_wave_count


func _complete_level_and_return_to_lobby() -> void:
	if level_completed:
		return

	level_completed = true
	spawn_timer.stop()
	LevelProgressStateScript.complete_active_level()
	_show_banner(LEVEL_COMPLETED_BANNER_TEXT, 1.8)
	_update_ui()

	var tree := get_tree()
	if tree == null:
		return

	await tree.create_timer(1.2, false).timeout

	if is_shutting_down or not is_inside_tree():
		return

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	tree.change_scene_to_file(LOBBY_SCENE_PATH)

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
		merchant_npc,
		loot_drops,
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

func spawn_loot_drop(origin: Vector2, drop_data: Dictionary = {}) -> void:
	var loot_pickup = LootPickupScene.instantiate()
	loot_pickup.global_position = _clamp_point_to_world(origin)
	loot_drops.add_child(loot_pickup)

	if loot_pickup.has_method("setup"):
		loot_pickup.setup(drop_data)

func find_walkable_point_near(origin: Vector2, radius: float) -> Vector2:
	return cover_manager.find_walkable_point_near(origin, radius)

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
	var bottom_left := Vector2(rect.position.x, rect.end.y)
	var bottom_right := rect.end
	var top_right := Vector2(rect.end.x, rect.position.y)

	return PackedVector2Array([top_left, bottom_left, bottom_right, top_right])

func _build_hud_state() -> Dictionary:
	return HUDStateBuilderScript.build_state(player, merchant_npc, ui_controller, wave_director, game_over)

func _is_point_walkable(point: Vector2) -> bool:
	return cover_manager.is_point_walkable(point)

func _clamp_point_to_world(point: Vector2) -> Vector2:
	return cover_manager.clamp_point_to_world(point)
