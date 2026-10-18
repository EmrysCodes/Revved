extends Node
## Shared display preference for the future settings menu. Physics stays in SI units.

signal units_changed

enum Units { US, METRIC }

const SETTINGS_PATH: String = "user://settings.cfg"
const METERS_PER_MILE: float = 1609.344
const METERS_PER_FOOT: float = 0.3048

var unit_system: Units = Units.US
var settings_path: String = SETTINGS_PATH


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		var saved_units: Variant = config.get_value("display", "units", Units.US)
		if saved_units is int and saved_units in [Units.US, Units.METRIC]:
			unit_system = saved_units


func set_unit_system(value: int, persist: bool = true) -> Error:
	if value not in [Units.US, Units.METRIC]:
		return ERR_INVALID_PARAMETER
	unit_system = value as Units
	units_changed.emit()
	if not persist:
		return OK
	var config := ConfigFile.new()
	config.load(settings_path)
	config.set_value("display", "units", unit_system)
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
