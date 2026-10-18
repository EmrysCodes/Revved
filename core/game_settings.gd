extends Node
## Shared display preference used by the pause/settings menu. Physics stays in SI units.

signal units_changed
signal car_style_changed
signal performance_changed

enum Units { US, METRIC }

const SETTINGS_PATH: String = "user://settings.cfg"
const METERS_PER_MILE: float = 1609.344
const METERS_PER_FOOT: float = 0.3048
const BRAND_NAMES := [["Vector / balanced", "Forge / launch", "Zenith / speed"], ["Vector / balanced", "Anchor / bite", "Modula / control"], ["Vector / balanced", "Apex / grip", "Stride / response"]]
const BRAND_DETAILS := [["Balanced acceleration and speed.", "Stronger launch; less top-speed gain.", "More top speed; smaller acceleration gain."], ["Balanced stopping and control.", "Stronger braking; slightly less road grip.", "Gentler braking; slightly more road grip."], ["Balanced grip and response.", "More grip; slightly less acceleration.", "Less grip gain; slightly more acceleration."]]

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
var engine_brand: int = 0
var brakes_brand: int = 0
var tires_brand: int = 0
var front_bumper: int = 0
var rear_bumper: int = 0
var side_skirts: int = 0
var car_spoiler: int = 0
var spoiler_finish: int = 0


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
		engine_brand = _load_choice(config, "engine_brand", 3)
		brakes_brand = _load_choice(config, "brakes_brand", 3)
		tires_brand = _load_choice(config, "tires_brand", 3)
		front_bumper = _load_choice(config, "front_bumper", 3, car_body)
		rear_bumper = _load_choice(config, "rear_bumper", 3, car_body)
		side_skirts = _load_choice(config, "side_skirts", 3, car_body)
		car_spoiler = _load_choice(config, "spoiler", 3)
		spoiler_finish = _load_choice(config, "spoiler_finish", 2)


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
	# Changing the kit applies its matching parts; paint/wheel edits preserve custom parts.
	if car_body != body:
		front_bumper = body
		rear_bumper = body
		side_skirts = body
	car_body = body
	car_wheels = wheels
	car_paint = paint
	car_style_changed.emit()
	return _save_preferences() if persist else OK


func _load_choice(config: ConfigFile, key: String, count: int, fallback: int = 0) -> int:
	var value: Variant = config.get_value("car", key, fallback)
	return value if value is int and value >= 0 and value < count else fallback


func set_body_parts(front: int, rear: int, skirts: int, persist: bool = true) -> Error:
	if front not in range(3) or rear not in range(3) or skirts not in range(3):
		return ERR_INVALID_PARAMETER
	front_bumper = front
	rear_bumper = rear
	side_skirts = skirts
	car_style_changed.emit()
	return _save_preferences() if persist else OK


func set_kit_preset(kit: int, persist: bool = true) -> Error:
	if kit not in range(3):
		return ERR_INVALID_PARAMETER
	car_body = kit
	return set_body_parts(kit, kit, kit, persist)


func set_spoiler(style: int, finish: int, persist: bool = true) -> Error:
	if style not in range(3) or finish not in range(2):
		return ERR_INVALID_PARAMETER
	car_spoiler = style
	spoiler_finish = finish
	car_style_changed.emit()
	return _save_preferences() if persist else OK


func set_performance_brands(engine: int, brakes: int, tires: int, persist: bool = true) -> Error:
	if engine not in range(3) or brakes not in range(3) or tires not in range(3):
		return ERR_INVALID_PARAMETER
	engine_brand = engine
	brakes_brand = brakes
	tires_brand = tires
	performance_changed.emit()
	return _save_preferences() if persist else OK


func set_performance(engine: int, brakes: int, tires: int, persist: bool = true) -> Error:
	if engine < 0 or engine > 3 or brakes < 0 or brakes > 3 or tires < 0 or tires > 3:
		return ERR_INVALID_PARAMETER
	engine_level = engine
	brakes_level = brakes
	tires_level = tires
	performance_changed.emit()
	return _save_preferences() if persist else OK


func performance_multipliers() -> Dictionary:
	# Increasing tiers stay distinct; brands shift the emphasis within each tier.
	var engine_speed: float=[1.0,1.08,1.18,1.30][engine_level]
	var engine_pull: float=[1.0,1.20,1.48,1.82][engine_level]
	return {
		"top_speed": engine_speed + engine_level * [0.0,-0.015,0.015][engine_brand],
		"acceleration": (engine_pull + engine_level * [0.0,0.05,-0.05][engine_brand]) * (1.0 + tires_level * [0.0,-0.005,0.005][tires_brand]),
		"braking": [1.0,1.10,1.20,1.30][brakes_level] + brakes_level * [0.0,0.015,-0.015][brakes_brand],
		"grip": (1.0 + tires_level * [0.08,0.09,0.07][tires_brand]) * (1.0 + brakes_level * [0.0,-0.003,0.003][brakes_brand])
	}


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
	config.set_value("car", "engine_brand", engine_brand)
	config.set_value("car", "brakes_brand", brakes_brand)
	config.set_value("car", "tires_brand", tires_brand)
	config.set_value("car", "front_bumper", front_bumper)
	config.set_value("car", "rear_bumper", rear_bumper)
	config.set_value("car", "side_skirts", side_skirts)
	config.set_value("car", "spoiler", car_spoiler)
	config.set_value("car", "spoiler_finish", spoiler_finish)
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
