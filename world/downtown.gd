extends Node3D
## Free-roam presentation; the generated scene contains the editable world geometry.
@export var map_roads: Array[PackedVector3Array] = []
@export var highway_roads: Array[PackedVector3Array] = []
@export var ramp_roads: Array[PackedVector3Array] = []
var driven: float = 0.0
@onready var car: CharacterBody3D = $VehicleSpawn/PlayerCar
@onready var readout: Label = $CityHUD/Screen/Readout
func _ready() -> void:
	car.get_node("CameraArm/FollowCamera").far = 1500.0
	GameSettings.units_changed.connect(_update_readout)
	_update_readout()
func _physics_process(delta: float) -> void:
	driven += Vector2(car.velocity.x, car.velocity.z).length() * delta
	_update_readout()
func _update_readout() -> void:
	var district := "DOWNTOWN"
	if car.position.x > 500.0:
		district = "EAST EXPRESSWAY"
	elif car.position.z < -245.0:
		district = "UPTOWN TERRACE"
	elif car.position.z > 230.0:
		district = "MARKET / WAREHOUSE ROW"
	readout.text = "%s / FREE ROAM\nDriven  %s\nEast: expressway access at Market St & Terrace Ave\nR: return to downtown spawn" % [district, GameSettings.format_distance(driven)]
