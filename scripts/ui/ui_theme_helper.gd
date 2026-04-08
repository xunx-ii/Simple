class_name UIThemeHelper
extends RefCounted


static func build_panel_style(
	background_color: Color,
	corner_radius: int = 12,
	border_color: Color = Color(0.258824, 0.337255, 0.415686, 0.88)
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	return style


static func apply_font(control: Control, ui_font: Font, font_size: int) -> void:
	if ui_font != null:
		control.add_theme_font_override("font", ui_font)
	control.add_theme_font_size_override("font_size", font_size)


static func set_margin(container: MarginContainer, left: int, top: int, right: int, bottom: int) -> void:
	container.add_theme_constant_override("margin_left", left)
	container.add_theme_constant_override("margin_top", top)
	container.add_theme_constant_override("margin_right", right)
	container.add_theme_constant_override("margin_bottom", bottom)
