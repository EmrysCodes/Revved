extends Node3D
## Gates must be crossed in order and in the intended direction.

const GATE_DIRECTIONS: Array[Vector3] = [Vector3.FORWARD, Vector3.LEFT, Vector3.BACK, Vector3.RIGHT]

var lap_active: bool = false
var next_gate: int = 0
var elapsed: float = 0.0
var best_lap: float = INF
var completed_laps: int = 0
var distance_driven: float = 0.0

@onready var car: CharacterBody3D = $VehicleSpawn/PlayerCar
@onready var readout: Label = $RaceHUD/Screen/RacePanel/Padding/Readout


func _ready() -> void:
	for index in range(4):
		var gate: Area3D = get_node("Gates/Gate%d" % index)
		gate.body_entered.connect(_on_gate_entered.bind(index))
	car.connect("reset_to_spawn", _restart_attempt)
	_update_readout()


func _physics_process(delta: float) -> void:
	distance_driven += Vector2(car.velocity.x, car.velocity.z).length() * delta
	if lap_active:
		elapsed += delta
	_update_readout()


func _on_gate_entered(body: Node3D, index: int) -> void:
	if body != car or index != next_gate:
		return
	if car.velocity.dot(GATE_DIRECTIONS[index]) <= 0.5:
		return
	if index == 0:
		if lap_active:
			completed_laps += 1
			best_lap = minf(best_lap, elapsed)
		elapsed = 0.0
		lap_active = true
	next_gate = (index + 1) % 4
	_update_readout()


func _restart_attempt() -> void:
	lap_active = false
	elapsed = 0.0
	next_gate = 0
	_update_readout()


func _update_readout() -> void:
	var best_text: String = "--:--.--" if is_inf(best_lap) else _time_text(best_lap)
	var target: String = "START / FINISH" if next_gate == 0 else "CHECKPOINT %d" % next_gate
	readout.text = "CIRCUIT TEST | LAP %d\nTime  %s\nBest  %s\nDriven  %s\nNext: %s" % [completed_laps + 1, _time_text(elapsed), best_text, GameSettings.format_distance(distance_driven), target]


func _time_text(seconds: float) -> String:
	var hundredths: int = int(seconds * 100.0)
	return "%02d:%02d.%02d" % [hundredths / 6000, (hundredths / 100) % 60, hundredths % 100]
