class_name MobileInputSettings
extends RefCounted

const CONFIG_PATH := "user://mobile_input_settings.cfg"
const REFERENCE_VIEWPORT_SIZE := Vector2(932.0, 430.0)
const MIN_MARGIN := 8.0
const MIN_JOYSTICK_SIZE := 112.0
const MAX_JOYSTICK_SIZE := 240.0
const MIN_AIM_BUTTON_SIZE := 88.0
const MAX_AIM_BUTTON_SIZE := 220.0


static func get_default_settings() -> Dictionary:
	return {
		"joystick": {
			"margin_left": 18.0,
			"margin_bottom": 18.0,
			"size": 172.0
		},
		"aim_button": {
			"margin_right": 24.0,
			"margin_bottom": 24.0,
			"size": 112.0
		}
	}


static func load_settings() -> Dictionary:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return get_default_settings()

	return sanitize_settings(
		{
			"joystick": {
				"margin_left": config.get_value("joystick", "margin_left", 18.0),
				"margin_bottom": config.get_value("joystick", "margin_bottom", 18.0),
				"size": config.get_value("joystick", "size", 172.0)
			},
			"aim_button": {
				"margin_right": config.get_value("aim_button", "margin_right", 24.0),
				"margin_bottom": config.get_value("aim_button", "margin_bottom", 24.0),
				"size": config.get_value("aim_button", "size", 112.0)
			}
		}
	)


static func save_settings(settings: Dictionary) -> int:
	var sanitized := sanitize_settings(settings)
	var config := ConfigFile.new()

	for section_name in sanitized.keys():
		var section: Dictionary = sanitized.get(section_name, {})
		for key in section.keys():
			config.set_value(section_name, key, section.get(key))

	return config.save(CONFIG_PATH)


static func sanitize_settings(settings_variant: Variant) -> Dictionary:
	var sanitized := get_default_settings()
	if settings_variant is Dictionary:
		var settings: Dictionary = settings_variant
		var joystick_settings: Dictionary = settings.get("joystick", {})
		var aim_button_settings: Dictionary = settings.get("aim_button", {})

		sanitized["joystick"]["margin_left"] = _as_float(
			joystick_settings.get("margin_left", sanitized["joystick"]["margin_left"])
		)
		sanitized["joystick"]["margin_bottom"] = _as_float(
			joystick_settings.get("margin_bottom", sanitized["joystick"]["margin_bottom"])
		)
		sanitized["joystick"]["size"] = _as_float(
			joystick_settings.get("size", sanitized["joystick"]["size"])
		)

		sanitized["aim_button"]["margin_right"] = _as_float(
			aim_button_settings.get("margin_right", sanitized["aim_button"]["margin_right"])
		)
		sanitized["aim_button"]["margin_bottom"] = _as_float(
			aim_button_settings.get("margin_bottom", sanitized["aim_button"]["margin_bottom"])
		)
		sanitized["aim_button"]["size"] = _as_float(
			aim_button_settings.get("size", sanitized["aim_button"]["size"])
		)

	var joystick_size := clampf(float(sanitized["joystick"]["size"]), MIN_JOYSTICK_SIZE, MAX_JOYSTICK_SIZE)
	var aim_button_size := clampf(float(sanitized["aim_button"]["size"]), MIN_AIM_BUTTON_SIZE, MAX_AIM_BUTTON_SIZE)
	sanitized["joystick"]["size"] = joystick_size
	sanitized["aim_button"]["size"] = aim_button_size

	sanitized["joystick"]["margin_left"] = clampf(
		float(sanitized["joystick"]["margin_left"]),
		MIN_MARGIN,
		maxf(REFERENCE_VIEWPORT_SIZE.x - joystick_size - MIN_MARGIN, MIN_MARGIN)
	)
	sanitized["joystick"]["margin_bottom"] = clampf(
		float(sanitized["joystick"]["margin_bottom"]),
		MIN_MARGIN,
		maxf(REFERENCE_VIEWPORT_SIZE.y - joystick_size - MIN_MARGIN, MIN_MARGIN)
	)
	sanitized["aim_button"]["margin_right"] = clampf(
		float(sanitized["aim_button"]["margin_right"]),
		MIN_MARGIN,
		maxf(REFERENCE_VIEWPORT_SIZE.x - aim_button_size - MIN_MARGIN, MIN_MARGIN)
	)
	sanitized["aim_button"]["margin_bottom"] = clampf(
		float(sanitized["aim_button"]["margin_bottom"]),
		MIN_MARGIN,
		maxf(REFERENCE_VIEWPORT_SIZE.y - aim_button_size - MIN_MARGIN, MIN_MARGIN)
	)

	return sanitized


static func apply_to_controls(
	container: Control,
	joystick: Control,
	aim_button: Control,
	settings_variant: Variant
) -> Dictionary:
	var sanitized := sanitize_settings(settings_variant)
	var container_size := container.size
	if container_size.x <= 0.0 or container_size.y <= 0.0:
		container_size = REFERENCE_VIEWPORT_SIZE

	var scale := minf(
		container_size.x / maxf(REFERENCE_VIEWPORT_SIZE.x, 1.0),
		container_size.y / maxf(REFERENCE_VIEWPORT_SIZE.y, 1.0)
	)
	scale = maxf(scale, 0.001)

	var joystick_settings: Dictionary = sanitized["joystick"]
	var joystick_size := float(joystick_settings["size"]) * scale
	var joystick_margin_left := float(joystick_settings["margin_left"]) * scale
	var joystick_margin_bottom := float(joystick_settings["margin_bottom"]) * scale

	joystick.custom_minimum_size = Vector2.ONE * joystick_size
	joystick.anchor_left = 0.0
	joystick.anchor_top = 1.0
	joystick.anchor_right = 0.0
	joystick.anchor_bottom = 1.0
	joystick.offset_left = joystick_margin_left
	joystick.offset_top = -(joystick_margin_bottom + joystick_size)
	joystick.offset_right = joystick_margin_left + joystick_size
	joystick.offset_bottom = -joystick_margin_bottom

	var aim_button_settings: Dictionary = sanitized["aim_button"]
	var aim_button_size := float(aim_button_settings["size"]) * scale
	var aim_button_margin_right := float(aim_button_settings["margin_right"]) * scale
	var aim_button_margin_bottom := float(aim_button_settings["margin_bottom"]) * scale

	aim_button.custom_minimum_size = Vector2.ONE * aim_button_size
	aim_button.anchor_left = 1.0
	aim_button.anchor_top = 1.0
	aim_button.anchor_right = 1.0
	aim_button.anchor_bottom = 1.0
	aim_button.offset_left = -(aim_button_margin_right + aim_button_size)
	aim_button.offset_top = -(aim_button_margin_bottom + aim_button_size)
	aim_button.offset_right = -aim_button_margin_right
	aim_button.offset_bottom = -aim_button_margin_bottom

	return sanitized


static func _as_float(value: Variant) -> float:
	if value is float or value is int:
		return float(value)

	return 0.0
