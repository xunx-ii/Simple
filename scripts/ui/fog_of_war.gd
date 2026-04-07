class_name FogOfWarUI
extends ColorRect

const FogShader := preload("res://shaders/fog_of_war.gdshader")
const OVERLAY_COLOR := Color(0.015686, 0.019608, 0.031373, 0.86)
const INNER_RADIUS := 24.0
const EDGE_SOFTNESS := 28.0

var player: Node2D

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	z_index = -10

	var shader_material := ShaderMaterial.new()
	shader_material.shader = FogShader
	material = shader_material
	_update_shader()

func setup(player_node: Node2D) -> void:
	player = player_node
	_update_shader()

func _process(_delta: float) -> void:
	if not is_instance_valid(player) or not player.visible:
		visible = false
		return

	visible = true
	_update_shader()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_shader()

func _update_shader() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return

	var viewport_size := get_viewport_rect().size
	var player_screen_position := viewport_size * 0.5
	var view_direction := Vector2.RIGHT
	var cone_angle_degrees := 120.0

	if is_instance_valid(player):
		player_screen_position = player.get_global_transform_with_canvas().origin
		if player.has_method("get_view_direction"):
			view_direction = player.call("get_view_direction")
		if player.has_method("get_vision_cone_degrees"):
			cone_angle_degrees = player.call("get_vision_cone_degrees")

	if view_direction == Vector2.ZERO:
		view_direction = Vector2.RIGHT

	shader_material.set_shader_parameter("viewport_size", viewport_size)
	shader_material.set_shader_parameter("player_screen_pos", player_screen_position)
	shader_material.set_shader_parameter("view_direction", view_direction.normalized())
	shader_material.set_shader_parameter("cone_angle_radians", deg_to_rad(cone_angle_degrees))
	shader_material.set_shader_parameter("inner_radius", INNER_RADIUS)
	shader_material.set_shader_parameter("edge_softness", EDGE_SOFTNESS)
	shader_material.set_shader_parameter("overlay_color", OVERLAY_COLOR)
