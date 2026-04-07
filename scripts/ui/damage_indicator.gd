class_name DamageIndicatorUI
extends Node2D

const INDICATOR_LIFETIME := 0.55
const INDICATOR_RADIUS := 34.0
const INDICATOR_LENGTH := 15.0
const INDICATOR_WIDTH := 3.0
const INDICATOR_COLOR := Color(1.0, 0.180392, 0.180392, 1.0)
const MAX_INDICATORS := 6

var player: Node2D
var indicators: Array[Dictionary] = []

func _ready() -> void:
	z_index = 15
	visible = false

func setup(player_node: Node2D) -> void:
	var hidden_hit_callable := Callable(self, "_on_hidden_hit_received")
	if is_instance_valid(player) and player.is_connected("hidden_hit_received", hidden_hit_callable):
		player.disconnect("hidden_hit_received", hidden_hit_callable)

	player = player_node
	if is_instance_valid(player):
		player.connect("hidden_hit_received", hidden_hit_callable)

func _process(delta: float) -> void:
	if indicators.is_empty():
		visible = false
		return

	visible = true
	for index in range(indicators.size() - 1, -1, -1):
		var indicator := indicators[index]
		indicator["time_left"] = max(float(indicator.get("time_left", 0.0)) - delta, 0.0)
		if indicator["time_left"] <= 0.0:
			indicators.remove_at(index)
			continue

		indicators[index] = indicator

	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(player):
		return

	var player_screen_position := player.get_global_transform_with_canvas().origin
	for indicator in indicators:
		var direction: Vector2 = indicator.get("direction", Vector2.ZERO)
		if direction == Vector2.ZERO:
			continue

		var lifetime: float = indicator.get("lifetime", INDICATOR_LIFETIME)
		var alpha: float = clampf(float(indicator.get("time_left", 0.0)) / lifetime, 0.0, 1.0)
		var anchor := player_screen_position + direction * INDICATOR_RADIUS
		var tangent := Vector2(-direction.y, direction.x)
		var half_length := tangent * INDICATOR_LENGTH * 0.5
		var glow_color := INDICATOR_COLOR
		glow_color.a = alpha * 0.28
		var bar_color := INDICATOR_COLOR
		bar_color.a = alpha

		draw_line(anchor - half_length * 1.35, anchor + half_length * 1.35, glow_color, INDICATOR_WIDTH + 4.0, true)
		draw_line(anchor - half_length, anchor + half_length, bar_color, INDICATOR_WIDTH, true)

func _on_hidden_hit_received(source_position: Vector2) -> void:
	if not is_instance_valid(player):
		return

	var direction := source_position - player.global_position
	if direction == Vector2.ZERO:
		return

	indicators.append(
		{
			"direction": direction.normalized(),
			"time_left": INDICATOR_LIFETIME,
			"lifetime": INDICATOR_LIFETIME
		}
	)

	while indicators.size() > MAX_INDICATORS:
		indicators.remove_at(0)

	queue_redraw()
