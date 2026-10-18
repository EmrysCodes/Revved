extends Node
## Shared display preference used by the pause/settings menu. Physics stays in SI units.

signal units_changed
signal car_style_changed
signal performance_changed

enum Units { US, METRIC }

const SETTINGS_PATH: String = "user://settings.cfg"
const METERS_PER_MILE: float = 1609.344
const METERS_PER_FOOT: float = 0.3048

var unit_system: Units = Units.US
var settings_path: String = SETTINGS_PATH
var car_body: int = 0
var car_wheels: int = 0
var car_paint: int = 0
var car_vinyl: int = 0
var car_vinyl_color: int = 0
var engine_level: int = 0
var brakes_level: int = 0
var tires_level: int = 0


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		var saved_units: Variant = config.get_value("display", "units", Units.US)
		if saved_units is int and saved_units in [Units.US, Units.METRIC]:
			unit_system = saved_units
		car_body = _load_choice(config, "body", 3)
		car_wheels = _load_choice(config, "wheels", 4)
		car_paint = _load_choice(config, "paint", 6)
		car_vinyl = _load_choice(config, "vinyl", 3)
		car_vinyl_color = _load_choice(config, "vinyl_color", 3)
		engine_level = _load_choice(config, "engine", 4)
		brakes_level = _load_choice(config, "brakes", 4)
		tires_level = _load_choice(config, "tires", 4)


func set_unit_system(value: int, persist: bool = true) -> Error:
	if value not in [Units.US, Units.METRIC]:
		return ERR_INVALID_PARAMETER
	unit_system = value as Units
	units_changed.emit()
	if not persist:
		return OK
	return _save_preferences()


func set_car_style(body: int, wheels: int, paint: int, persist: bool = true) -> Error:
	if body < 0 or body >= 3 or wheels < 0 or wheels >= 4 or paint < 0 or paint >= 6:
		return ERR_INVALID_PARAMETER
	car_body = body
	car_wheels = wheels
	car_paint = paint
	car_style_changed.emit()
	return _save_preferences() if persist else OK


func _load_choice(config: ConfigFile, key: String, count: int) -> int:
	var value: Variant = config.get_value("car", key, 0)
	return value if value is int and value >= 0 and value < count else 0


func set_performance(engine: int, brakes: int, tires: int, persist: bool = true) -> Error:
	if engine < 0 or engine > 3 or brakes < 0 or brakes > 3 or tires < 0 or tires > 3:
		return ERR_INVALID_PARAMETER
	engine_level = engine
	brakes_level = brakes
	tires_level = tires
	performance_changed.emit()
	return _save_preferences() if persist else OK


func performance_multipliers() -> Dictionary:
	return {"top_speed": 1.0 + engine_level * 0.06, "acceleration": 1.0 + engine_level * 0.15, "braking": 1.0 + brakes_level * 0.2, "grip": 1.0 + tires_level * 0.1}


func set_vinyl(style: int, color: int, persist: bool = true) -> Error:
	if style < 0 or style > 2 or color < 0 or color > 2:
		return ERR_INVALID_PARAMETER
	car_vinyl = style
	car_vinyl_color = color
	car_style_changed.emit()
	return _save_preferences() if persist else OK


func _save_preferences() -> Error:
	var config := ConfigFile.new()
	config.load(settings_path)
	config.set_value("display", "units", unit_system)
	config.set_value("car", "body", car_body)
	config.set_value("car", "wheels", car_wheels)
	config.set_value("car", "paint", car_paint)
	config.set_value("car", "vinyl", car_vinyl)
	config.set_value("car", "vinyl_color", car_vinyl_color)
	config.set_value("car", "engine", engine_level)
	config.set_value("car", "brakes", brakes_level)
	config.set_value("car", "tires", tires_level)
	return config.save(settings_path)


func format_speed(meters_per_second: float) -> String:
	var factor: float = 3600.0 / METERS_PER_MILE if unit_system == Units.US else 3.6
	var suffix: String = "MPH" if unit_system == Units.US else "km/h"
	return "%03d %s" % [roundi(absf(meters_per_second) * factor), suffix]


func format_distance(meters: float, short_distance: bool = false) -> String:
	var distance: float = maxf(meters, 0.0)
	if unit_system == Units.US:
		return "%.0f ft" % (distance / METERS_PER_FOOT) if short_distance else "%.2f mi" % (distance / METERS_PER_MILE)
	return "%.0f m" % distance if short_distance else "%.2f km" % (distance / 1000.0)
