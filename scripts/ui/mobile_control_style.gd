class_name MobileControlStyle
extends RefCounted

const BASE_FILL := Color(0.06, 0.08, 0.11, 0.58)
const ACTIVE_FILL := Color(0.08, 0.14, 0.18, 0.82)
const RING_COLOR := Color(0.62, 0.82, 0.95, 0.26)
const ACTIVE_RING_COLOR := Color(0.66, 0.9, 1.0, 0.92)
const INNER_GLOW_COLOR := Color(1.0, 1.0, 1.0, 0.05)
const ACTIVE_GLOW_COLOR := Color(0.36, 0.87, 1.0, 0.16)
const KNOB_COLOR := Color(0.36, 0.87, 1.0, 0.88)
const ICON_COLOR := Color(0.86, 0.97, 1.0, 0.94)
const ACTIVE_ICON_COLOR := Color(0.9, 1.0, 0.94, 1.0)
const DISABLED_OVERLAY := Color(0.01, 0.02, 0.03, 0.34)


static func draw_shell(canvas: CanvasItem, center: Vector2, radius: float, is_active: bool = false, is_disabled: bool = false) -> void:
	var safe_radius := maxf(radius, 4.0)
	var fill_color := ACTIVE_FILL if is_active else BASE_FILL
	var ring_color := ACTIVE_RING_COLOR if is_active else RING_COLOR
	var glow_color := ACTIVE_GLOW_COLOR if is_active else INNER_GLOW_COLOR

	canvas.draw_circle(center, safe_radius, fill_color)
	canvas.draw_circle(center, safe_radius * 0.58, glow_color)
	canvas.draw_arc(center, safe_radius, 0.0, TAU, 48, ring_color, maxf(safe_radius * 0.08, 2.0), true)

	if is_disabled:
		canvas.draw_circle(center, safe_radius, DISABLED_OVERLAY)


static func draw_knob(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	var safe_radius := maxf(radius, 2.0)
	canvas.draw_circle(center, safe_radius, KNOB_COLOR)
	canvas.draw_circle(center, safe_radius * 0.42, Color(1.0, 1.0, 1.0, 0.12))


static func draw_crosshair_icon(
	canvas: CanvasItem,
	center: Vector2,
	radius: float,
	is_active: bool = false,
	is_disabled: bool = false
) -> void:
	var icon_color := ACTIVE_ICON_COLOR if is_active else ICON_COLOR
	if is_disabled:
		icon_color = Color(icon_color.r, icon_color.g, icon_color.b, 0.54)

	var arm_length := radius * 0.42
	var gap := radius * 0.16
	var thickness := maxf(radius * 0.12, 2.0)

	canvas.draw_line(
		center + Vector2(0.0, -(gap + arm_length)),
		center + Vector2(0.0, -gap),
		icon_color,
		thickness
	)
	canvas.draw_line(
		center + Vector2(0.0, gap),
		center + Vector2(0.0, gap + arm_length),
		icon_color,
		thickness
	)
	canvas.draw_line(
		center + Vector2(-(gap + arm_length), 0.0),
		center + Vector2(-gap, 0.0),
		icon_color,
		thickness
	)
	canvas.draw_line(
		center + Vector2(gap, 0.0),
		center + Vector2(gap + arm_length, 0.0),
		icon_color,
		thickness
	)
	canvas.draw_circle(center, maxf(radius * 0.11, 2.0), icon_color)
