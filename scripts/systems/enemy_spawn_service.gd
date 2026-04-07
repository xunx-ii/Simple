class_name EnemySpawnService
extends RefCounted

var player: Node2D = null
var enemies_container: Node2D = null
var wave_director = null
var world_rect: Rect2 = Rect2()
var ranged_enemy_scene: PackedScene = null
var melee_enemy_scene: PackedScene = null
var world_controller: Node = null
var enemy_defeated_callback: Callable = Callable()
var enemy_tree_exited_callback: Callable = Callable()
var is_walkable_callable: Callable = Callable()
var clamp_point_callable: Callable = Callable()
var find_walkable_point_callable: Callable = Callable()
var min_spawn_distance: float = 112.0
var spawn_view_margin: float = 48.0

func setup(config: Dictionary) -> void:
	player = config.get("player") as Node2D
	enemies_container = config.get("enemies_container") as Node2D
	wave_director = config.get("wave_director")
	world_rect = config.get("world_rect", Rect2())
	ranged_enemy_scene = config.get("ranged_enemy_scene") as PackedScene
	melee_enemy_scene = config.get("melee_enemy_scene") as PackedScene
	world_controller = config.get("world_controller") as Node
	enemy_defeated_callback = config.get("enemy_defeated_callback", Callable())
	enemy_tree_exited_callback = config.get("enemy_tree_exited_callback", Callable())
	is_walkable_callable = config.get("is_walkable_callable", Callable())
	clamp_point_callable = config.get("clamp_point_callable", Callable())
	find_walkable_point_callable = config.get("find_walkable_point_callable", Callable())
	min_spawn_distance = float(config.get("min_spawn_distance", min_spawn_distance))
	spawn_view_margin = float(config.get("spawn_view_margin", spawn_view_margin))

func spawn_next_enemy(game_over: bool) -> bool:
	if wave_director == null or player == null or enemies_container == null:
		return false

	if not wave_director.should_spawn_enemy(game_over):
		return false

	var spawn_melee_enemy: bool = wave_director.pick_enemy_type_is_melee()
	var enemy_scene: PackedScene = melee_enemy_scene if spawn_melee_enemy else ranged_enemy_scene
	if enemy_scene == null:
		return false

	var enemy: Node = enemy_scene.instantiate()
	var enemy_body := enemy as Node2D
	if enemy_body == null:
		return false

	enemy_body.global_position = _pick_spawn_position()
	if enemy.has_signal("defeated") and enemy_defeated_callback.is_valid():
		enemy.connect("defeated", enemy_defeated_callback)
	if enemy_tree_exited_callback.is_valid():
		enemy.tree_exited.connect(enemy_tree_exited_callback)

	enemies_container.add_child(enemy)

	if enemy.has_method("setup"):
		enemy.call(
			"setup",
			player,
			world_rect,
			wave_director.build_enemy_config(spawn_melee_enemy),
			world_controller
		)

	if player.has_method("is_point_in_vision"):
		enemy_body.visible = player.is_point_in_vision(enemy_body.global_position)

	wave_director.register_enemy_spawned()
	return true

func _pick_spawn_position() -> Vector2:
	var visible_world_size := player.get_viewport_rect().size
	if player.has_method("get_camera_visible_world_size"):
		visible_world_size = player.get_camera_visible_world_size()

	var view_half_size: Vector2 = visible_world_size * 0.5
	var horizontal_span: float = view_half_size.x + spawn_view_margin
	var vertical_span: float = view_half_size.y + spawn_view_margin

	for _attempt in range(40):
		var side: int = randi_range(0, 3)
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

		candidate = _clamp_point(candidate)

		if candidate.distance_to(player.global_position) < min_spawn_distance:
			continue

		if _is_walkable(candidate):
			return candidate

	return _find_walkable_point_near(player.global_position, horizontal_span + 64.0)

func _is_walkable(point: Vector2) -> bool:
	if is_walkable_callable.is_valid():
		return bool(is_walkable_callable.call(point))

	return true

func _clamp_point(point: Vector2) -> Vector2:
	if clamp_point_callable.is_valid():
		return clamp_point_callable.call(point)

	return point.clamp(world_rect.position, world_rect.end)

func _find_walkable_point_near(origin: Vector2, radius: float) -> Vector2:
	if find_walkable_point_callable.is_valid():
		return find_walkable_point_callable.call(origin, radius)

	return _clamp_point(origin)
