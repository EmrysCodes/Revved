extends Node3D
## Visual steering and rolling are independent of the car's collision body.

@export var wheel_radius: float = 0.292335
@export var maximum_steer_degrees: float = 30.0

const BODY_SCENES: Array[PackedScene] = [preload("res://assets/vehicles/s64_compact/S64Compact_Body_1.glb"), preload("res://assets/vehicles/s64_compact/S64Compact_Body_2.glb"), preload("res://assets/vehicles/s64_compact/S64Compact_Body_3.glb")]
const LEFT_WHEELS: Array[PackedScene] = [preload("res://assets/vehicles/s64_compact/Rims_L.glb"), preload("res://assets/vehicles/s64_compact/Rims_1_L.glb"), preload("res://assets/vehicles/s64_compact/Rims_2_L.glb"), preload("res://assets/vehicles/s64_compact/Rims_3_L.glb")]
const RIGHT_WHEELS: Array[PackedScene] = [preload("res://assets/vehicles/s64_compact/Rims_R.glb"), preload("res://assets/vehicles/s64_compact/Rims_1_R.glb"), preload("res://assets/vehicles/s64_compact/Rims_2_R.glb"), preload("res://assets/vehicles/s64_compact/Rims_3_R.glb")]
const BODY_OFFSETS: Array[Vector3] = [Vector3(0, 0.080392, 0.14696), Vector3(0, 0.0542, 0.07218), Vector3(0, 0.0241, -0.03331)]
const PAINT_NAMES: Array[String] = ["Electric blue", "Racing red", "Midnight black", "Pearl white", "Sunburst yellow", "Violet"]
const PAINT_COLORS: Array[Color] = [Color(0.015, 0.09, 0.55), Color(0.65, 0.012, 0.025), Color(0.012, 0.016, 0.022), Color(0.8, 0.82, 0.85), Color(0.9, 0.5, 0.01), Color(0.26, 0.025, 0.6)]

var _body_index: int = -1
var _wheel_index: int = -1

var _roll_angle: float = 0.0
@onready var _wheels: Array[Node3D] = [$FrontLeft/Spin, $FrontRight/Spin, $RearLeft/Spin, $RearRight/Spin]


func _ready() -> void:
	GameSettings.car_style_changed.connect(apply_saved_style)
	apply_saved_style()


func apply_saved_style() -> void:
	if _body_index != GameSettings.car_body:
		var body: Node3D = _replace_model(self, "Body", BODY_SCENES[GameSettings.car_body])
		body.position = BODY_OFFSETS[GameSettings.car_body]
		_body_index = GameSettings.car_body
	if _wheel_index != GameSettings.car_wheels:
		for index in range(_wheels.size()):
			var scene: PackedScene = LEFT_WHEELS[GameSettings.car_wheels] if index % 2 == 0 else RIGHT_WHEELS[GameSettings.car_wheels]
			_replace_model(_wheels[index], "Model", scene)
		_wheel_index = GameSettings.car_wheels
	for mesh in $Body.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var original: Material = mesh.mesh.surface_get_material(surface)
			if original != null and original.resource_name == "Car":
				var paint: StandardMaterial3D = original.duplicate()
				paint.albedo_color = PAINT_COLORS[GameSettings.car_paint]
				mesh.set_surface_override_material(surface, paint)


func _replace_model(parent_node: Node, model_name: String, scene: PackedScene) -> Node3D:
	var old: Node3D = parent_node.get_node(model_name)
	var transform_before: Transform3D = old.transform
	parent_node.remove_child(old)
	old.queue_free()
	var replacement: Node3D = scene.instantiate()
	replacement.name = model_name
	replacement.transform = transform_before
	parent_node.add_child(replacement)
	return replacement


func update_wheels(steering: float, forward_speed: float, delta: float) -> void:
	var angle: float = -clampf(steering, -1.0, 1.0) * deg_to_rad(maximum_steer_degrees)
	$FrontLeft.rotation.y = angle
	$FrontRight.rotation.y = angle
	_roll_angle = wrapf(_roll_angle - forward_speed * delta / wheel_radius, -PI, PI)
	for wheel in _wheels:
		wheel.rotation.x = _roll_angle


func reset_wheels() -> void:
	_roll_angle = 0.0
	$FrontLeft.rotation = Vector3.ZERO
	$FrontRight.rotation = Vector3.ZERO
	for wheel in _wheels:
		wheel.rotation = Vector3.ZERO
