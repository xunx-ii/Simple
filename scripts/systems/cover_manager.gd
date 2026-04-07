class_name CoverManager
extends RefCounted

const COVER_CLUSTER_COUNT := 18
const COVER_CLUSTER_MIN_CELLS := 6
const COVER_CLUSTER_MAX_CELLS := 18
const COVER_CLUSTER_ATTEMPTS := 48
const COVER_EDGE_MARGIN_CELLS := 3
const COVER_PLAYER_SAFE_RADIUS := 120.0
const COVER_DIRECTIONS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var world_rect: Rect2 = Rect2()
var tile_size: int = 16
var cover_color: Color = Color(0.494118, 0.529412, 0.568627, 1.0)
var player: Node2D = null
var covers_root: Node2D = null
var cover_scene: PackedScene = null
var active_cover_rects: Array = []

func setup(covers_node: Node2D, cover_scene_resource: PackedScene, world_bounds: Rect2, tile_world_size: int, tint: Color, player_node: Node2D) -> void:
    covers_root = covers_node
    cover_scene = cover_scene_resource
    world_rect = world_bounds
    tile_size = tile_world_size
    cover_color = tint
    player = player_node

func spawn_covers(on_cover_destroyed: Callable) -> void:
    active_cover_rects.clear()

    if covers_root == null or cover_scene == null:
        return

    for existing_cover in covers_root.get_children():
        existing_cover.queue_free()

    var occupied_cells := {}

    for _cluster_index in range(COVER_CLUSTER_COUNT):
        var cluster_cells := _generate_cover_cluster(occupied_cells)
        if cluster_cells.is_empty():
            continue

        for cell_variant in cluster_cells:
            var cell: Vector2i = cell_variant
            occupied_cells[cell] = true
            _spawn_cover_tile(cell, on_cover_destroyed)

func handle_cover_destroyed(cell: Vector2i) -> bool:
    var world_cover_rect := cell_to_world_rect(cell)
    var remove_index := -1

    for index in range(active_cover_rects.size()):
        var cover_rect: Rect2 = active_cover_rects[index]
        if cover_rect.position.is_equal_approx(world_cover_rect.position) and cover_rect.size.is_equal_approx(world_cover_rect.size):
            remove_index = index
            break

    if remove_index < 0:
        return false

    active_cover_rects.remove_at(remove_index)
    return true

func find_walkable_point_near(origin: Vector2, radius: float) -> Vector2:
    for _attempt in range(24):
        var candidate := origin + Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
        candidate = clamp_point_to_world(candidate)
        if is_point_walkable(candidate):
            return candidate

    return clamp_point_to_world(origin)

func is_point_walkable(point: Vector2) -> bool:
    if not world_rect.has_point(point):
        return false

    for cover_rect in active_cover_rects:
        if cover_rect.has_point(point):
            return false

    return true

func cell_to_world_center(cell: Vector2i) -> Vector2:
    return (Vector2(cell) + Vector2.ONE * 0.5) * tile_size

func cell_to_world_rect(cell: Vector2i) -> Rect2:
    return Rect2(Vector2(cell) * tile_size, Vector2.ONE * tile_size)

func get_world_cell_size() -> Vector2i:
    return Vector2i(int(world_rect.size.x / tile_size), int(world_rect.size.y / tile_size))

func clamp_point_to_world(point: Vector2) -> Vector2:
    return point.clamp(world_rect.position + Vector2.ONE * 8.0, world_rect.end - Vector2.ONE * 8.0)

func _spawn_cover_tile(cell: Vector2i, on_cover_destroyed: Callable) -> void:
    var cover = cover_scene.instantiate()
    cover.global_position = cell_to_world_center(cell)
    covers_root.add_child(cover)
    cover.configure(tile_size, cover_color, cell)
    if on_cover_destroyed.is_valid():
        cover.destroyed.connect(on_cover_destroyed)
    active_cover_rects.append(cell_to_world_rect(cell))

func _generate_cover_cluster(occupied_cells: Dictionary) -> Array:
    for _attempt in range(COVER_CLUSTER_ATTEMPTS):
        var origin := _pick_cover_origin_cell(occupied_cells)
        if origin == Vector2i(-1, -1):
            break

        var target_size := randi_range(COVER_CLUSTER_MIN_CELLS, COVER_CLUSTER_MAX_CELLS)
        var cluster_cells: Array = [origin]
        var local_cells := {origin: true}
        var frontier: Array = [origin]

        while cluster_cells.size() < target_size and not frontier.is_empty():
            var frontier_index := randi_range(0, frontier.size() - 1)
            var base_cell: Vector2i = frontier[frontier_index]
            var directions := COVER_DIRECTIONS.duplicate()
            directions.shuffle()

            var expanded := false
            for direction_variant in directions:
                var direction: Vector2i = direction_variant
                var candidate := base_cell + direction
                if not _can_use_cover_cell(candidate, occupied_cells, local_cells):
                    continue

                cluster_cells.append(candidate)
                local_cells[candidate] = true
                frontier.append(candidate)
                expanded = true
                break

            if not expanded:
                frontier.remove_at(frontier_index)

        if cluster_cells.size() >= COVER_CLUSTER_MIN_CELLS:
            return cluster_cells

    return []

func _pick_cover_origin_cell(occupied_cells: Dictionary) -> Vector2i:
    var world_cells := get_world_cell_size()
    var min_x := COVER_EDGE_MARGIN_CELLS
    var max_x := world_cells.x - COVER_EDGE_MARGIN_CELLS - 1
    var min_y := COVER_EDGE_MARGIN_CELLS
    var max_y := world_cells.y - COVER_EDGE_MARGIN_CELLS - 1

    for _attempt in range(72):
        var candidate := Vector2i(randi_range(min_x, max_x), randi_range(min_y, max_y))
        if _can_use_cover_cell(candidate, occupied_cells):
            return candidate

    return Vector2i(-1, -1)

func _can_use_cover_cell(cell: Vector2i, occupied_cells: Dictionary, local_cells: Dictionary = {}) -> bool:
    var world_cells := get_world_cell_size()
    if cell.x < COVER_EDGE_MARGIN_CELLS or cell.x >= world_cells.x - COVER_EDGE_MARGIN_CELLS:
        return false

    if cell.y < COVER_EDGE_MARGIN_CELLS or cell.y >= world_cells.y - COVER_EDGE_MARGIN_CELLS:
        return false

    if occupied_cells.has(cell) or local_cells.has(cell):
        return false

    if is_instance_valid(player) and cell_to_world_center(cell).distance_to(player.global_position) < COVER_PLAYER_SAFE_RADIUS:
        return false

    for direction_variant in COVER_DIRECTIONS:
        var direction: Vector2i = direction_variant
        var neighbor := cell + direction
        if occupied_cells.has(neighbor) and not local_cells.has(neighbor):
            return false

    return true
