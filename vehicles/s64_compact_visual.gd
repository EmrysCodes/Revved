extends Node3D
## Visual steering and rolling are independent of the car's collision body.

@export var wheel_radius: float = 0.292335
@export var maximum_steer_degrees: float = 30.0

const LEFT_WHEELS: Array[PackedScene] = [preload("res://assets/vehicles/s64_compact/Rims_L.glb"), preload("res://assets/vehicles/s64_compact/Rims_1_L.glb"), preload("res://assets/vehicles/s64_compact/Rims_2_L.glb"), preload("res://assets/vehicles/s64_compact/Rims_3_L.glb")]
const RIGHT_WHEELS: Array[PackedScene] = [preload("res://assets/vehicles/s64_compact/Rims_R.glb"), preload("res://assets/vehicles/s64_compact/Rims_1_R.glb"), preload("res://assets/vehicles/s64_compact/Rims_2_R.glb"), preload("res://assets/vehicles/s64_compact/Rims_3_R.glb")]
const PAINT_NAMES: Array[String] = ["Electric blue", "Racing red", "Midnight black", "Pearl white", "Sunburst yellow", "Violet"]
const PAINT_COLORS: Array[Color] = [Color(0.015, 0.09, 0.55), Color(0.65, 0.012, 0.025), Color(0.012, 0.016, 0.022), Color(0.8, 0.82, 0.85), Color(0.9, 0.5, 0.01), Color(0.26, 0.025, 0.6)]
const VINYL_COLORS: Array[Color] = [Color(0.95, 0.95, 0.95), Color(0.008, 0.008, 0.01), Color(1.0, 0.65, 0.015)]
const VINYL_SHADER: Shader = preload("res://vehicles/car_vinyl.gdshader")
const SPOILERS: Array[PackedScene] = [preload("res://assets/vehicles/s64_compact/S64_Compact_Spoiler.glb"), preload("res://assets/vehicles/s64_compact/S64_Compact_Spoiler_2.glb")]

const PART_NAMES := ["Core", "FrontBumper", "RearBumper", "SideSkirts"]
var _parts_signature := Vector4i(-1, -1, -1, -1)
var _body_index: int = -1
var _wheel_index: int = -1
var _spoiler_index: int = -1

var _roll_angle: float = 0.0
@onready var _wheels: Array[Node3D] = [$FrontLeft/Spin, $FrontRight/Spin, $RearLeft/Spin, $RearRight/Spin]


func _ready() -> void:
	GameSettings.car_style_changed.connect(apply_saved_style)
	apply_saved_style()


func apply_saved_style() -> void:
	var parts := Vector4i(GameSettings.car_body, GameSettings.front_bumper, GameSettings.rear_bumper, GameSettings.side_skirts)
	if parts != _parts_signature:
		var old: Node3D = $Body
		remove_child(old)
		old.queue_free()
		var body := Node3D.new()
		body.name = "Body"
		add_child(body)
		for slot in range(4):
			var part := MeshInstance3D.new()
			part.name = PART_NAMES[slot]
			part.mesh = load("res://assets/vehicles/s64_compact/modular/%s_%d.res" % [PART_NAMES[slot], parts[slot]])
			body.add_child(part)
		_body_index = GameSettings.car_body
		_parts_signature = parts
	if _wheel_index != GameSettings.car_wheels:
		for index in range(_wheels.size()):
			var scene: PackedScene = LEFT_WHEELS[GameSettings.car_wheels] if index % 2 == 0 else RIGHT_WHEELS[GameSettings.car_wheels]
			_replace_model(_wheels[index], "Model", scene)
		_wheel_index = GameSettings.car_wheels
	_apply_spoiler()
	for mesh in $Body.find_children("*", "MeshInstance3D", true, false):
		for surface in range(mesh.mesh.get_surface_count()):
			var original: Material = mesh.mesh.surface_get_material(surface)
			mesh.set_surface_override_material(surface, null)
			if original == null:
				continue
			var is_paint: bool = original.resource_name == "Car"
			if GameSettings.car_vinyl != 0 and (is_paint or original.resource_name in ["Det", "Det2"]):
				var vinyl := ShaderMaterial.new()
				vinyl.shader = VINYL_SHADER
				vinyl.set_shader_parameter("base_color", PAINT_COLORS[GameSettings.car_paint] if is_paint else original.albedo_color)
				vinyl.set_shader_parameter("vinyl_color", VINYL_COLORS[GameSettings.car_vinyl_color])
				vinyl.set_shader_parameter("vinyl_style", GameSettings.car_vinyl)
				vinyl.set_shader_parameter("base_metallic", original.metallic)
				vinyl.set_shader_parameter("base_roughness", original.roughness)
				vinyl.set_shader_parameter("mesh_to_car", global_transform.affine_inverse() * mesh.global_transform)
				mesh.set_surface_override_material(surface, vinyl)
			elif is_paint:
				var paint: StandardMaterial3D = original.duplicate()
				paint.albedo_color = PAINT_COLORS[GameSettings.car_paint]
				mesh.set_surface_override_material(surface, paint)
	reset_physics_interpolation()


func _apply_spoiler() -> void:
	if _spoiler_index != GameSettings.car_spoiler:
		for old in $Spoiler.get_children():
			$Spoiler.remove_child(old)
			old.queue_free()
		if GameSettings.car_spoiler > 0:
			var model: Node3D = SPOILERS[GameSettings.car_spoiler - 1].instantiate()
			model.name = "Model"
			model.rotation.y = -PI / 2.0
			model.scale = Vector3.ONE * 1.218064
			$Spoiler.add_child(model)
		_spoiler_index = GameSettings.car_spoiler
	# The widebody upper hatch sits about 0.01m lower at the shared mounting point.
	$Spoiler.position = Vector3(0, 0.97 if GameSettings.car_body == 2 else 0.98, 1.82)
	for mesh: MeshInstance3D in $Spoiler.find_children("*", "MeshInstance3D", true, false):
		var finish := StandardMaterial3D.new()
		finish.albedo_color = PAINT_COLORS[GameSettings.car_paint] if GameSettings.spoiler_finish == 0 else Color(0.018, 0.021, 0.025)
		finish.metallic = 0.45 if GameSettings.spoiler_finish == 0 else 0.1
		finish.roughness = 0.3 if GameSettings.spoiler_finish == 0 else 0.65
		mesh.material_override = finish


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
