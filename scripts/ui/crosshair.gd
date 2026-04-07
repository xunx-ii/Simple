class_name CrosshairUI
extends Node2D

const CENTER_TEXTURE_PATH := "res://assets/textures/image/crosshair_center.png"
const OUTER_TEXTURE_PATH := "res://assets/textures/image/crosshair_outer_expand.png"
const DEFAULT_OUTER_SCALE := 1.0
const AIM_TINT := Color(0.82, 1.0, 0.88, 1.0)
const DEFAULT_TINT := Color(1.0, 1.0, 1.0, 1.0)

var player: Node = null

@onready var center: Sprite2D = $Center
@onready var outer: Sprite2D = $Outer

func _ready() -> void:
    center.texture = _load_texture(CENTER_TEXTURE_PATH)
    outer.texture = _load_texture(OUTER_TEXTURE_PATH)
    center.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    outer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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

    outer.scale = Vector2.ONE * outer_scale

    var tint := AIM_TINT if player.has_method("is_in_aim_mode") and player.is_in_aim_mode() else DEFAULT_TINT
    center.modulate = tint
    outer.modulate = tint

func _load_texture(resource_path: String) -> Texture2D:
    var image: Image = Image.load_from_file(ProjectSettings.globalize_path(resource_path))
    if image == null or image.is_empty():
        return null

    return ImageTexture.create_from_image(image)
