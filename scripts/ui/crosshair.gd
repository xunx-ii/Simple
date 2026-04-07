class_name CrosshairUI
extends Node2D

const CENTER_TEXTURE_PATH := "res://assets/textures/image/crosshair_center.png"
const DEFAULT_OUTER_SCALE := 1.0
const AIM_TINT := Color(0.82, 1.0, 0.88, 1.0)
const DEFAULT_TINT := Color(1.0, 1.0, 1.0, 1.0)
const OUTER_ARM_LENGTH := 4.0
const OUTER_ARM_THICKNESS := 2.0
const OUTER_BASE_GAP := 6.0

var player: Node = null
var current_outer_scale: float = DEFAULT_OUTER_SCALE
var current_tint: Color = DEFAULT_TINT

@onready var center: Sprite2D = $Center
@onready var outer: Sprite2D = $Outer

func _ready() -> void:
    center.texture = _load_texture(CENTER_TEXTURE_PATH)
    center.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    outer.visible = false
    z_index = 50

func setup(player_node: Node) -> void:
    player = player_node

func _process(_delta: float) -> void:
    if not is_instance_valid(player):
        visible = false
        return

    visible = player.visible
    global_position = get_viewport().get_mouse_position()

    var outer_scale := DEFAULT_OUTER_SCALE
    if player.has_method("get_crosshair_outer_scale"):
        outer_scale = player.get_crosshair_outer_scale()

    var tint := AIM_TINT if player.has_method("is_in_aim_mode") and player.is_in_aim_mode() else DEFAULT_TINT
    current_outer_scale = outer_scale
    current_tint = tint
    center.modulate = tint
    queue_redraw()

func _draw() -> void:
    var gap := OUTER_BASE_GAP * current_outer_scale
    var arm_size := Vector2(OUTER_ARM_THICKNESS, OUTER_ARM_LENGTH)
    var horizontal_size := Vector2(OUTER_ARM_LENGTH, OUTER_ARM_THICKNESS)

    draw_rect(Rect2(Vector2(-OUTER_ARM_THICKNESS * 0.5, -(gap + OUTER_ARM_LENGTH)), arm_size), current_tint)
    draw_rect(Rect2(Vector2(-OUTER_ARM_THICKNESS * 0.5, gap), arm_size), current_tint)
    draw_rect(Rect2(Vector2(-(gap + OUTER_ARM_LENGTH), -OUTER_ARM_THICKNESS * 0.5), horizontal_size), current_tint)
    draw_rect(Rect2(Vector2(gap, -OUTER_ARM_THICKNESS * 0.5), horizontal_size), current_tint)

func _load_texture(resource_path: String) -> Texture2D:
    return load(resource_path) as Texture2D
