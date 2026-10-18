extends CharacterBody3D
## Flat-road arcade handling. Physics uses meters and seconds; HUD uses GameSettings.

signal reset_to_spawn

@export_group("Power and braking")
@export var top_speed: float = 32.0
@export var reverse_speed: float = 9.0
@export var acceleration: float = 12.0
@export var braking: float = 26.0
@export var rolling_drag: float = 2.0
@export var handbrake_drag: float = 5.0

@export_group("Steering and grip")
@export var low_speed_turn_rate: float = 2.0
@export var high_speed_turn_rate: float = 0.85
@export var steering_response: float = 5.0
@export var steering_return: float = 7.5
@export var road_grip: float = 10.0
@export var slide_grip: float = 1.6
@export var handbrake_turn_boost: float = 1.45

var _speed: float = 0.0
var _steering: float = 0.0
var _yaw_rate: float = 0.0
var _grip: float = 10.0
var _spawn_transform: Transform3D
var _handbraking: bool = false

@onready var _readout: Label = $HUD/Screen/DrivePanel/Padding/Stack/Readout
@onready var _status: Label = $HUD/Screen/DrivePanel/Padding/Stack/Status
@onready var _visuals: Node3D = $Visuals
@onready var _camera_arm: SpringArm3D = $CameraArm
@onready var _camera: Camera3D = $CameraArm/FollowCamera


func _ready() -> void:
	_spawn_transform = global_transform
	_grip = road_grip
	_camera_arm.add_excluded_object(get_rid())
	_camera_arm.top_level = true
	_snap_camera()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R:
			_reset_car()


func _physics_process(delta: float) -> void:
	var throttle: float = float(_held(KEY_W, KEY_UP)) - float(_held(KEY_S, KEY_DOWN))
	var steering: float = float(_held(KEY_D, KEY_RIGHT)) - float(_held(KEY_A, KEY_LEFT))
	_step_motion(delta, throttle, steering, Input.is_physical_key_pressed(KEY_SHIFT), Input.is_physical_key_pressed(KEY_SPACE))
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	_readout.text = GameSettings.format_speed(horizontal_speed)
	_status.text = "HANDBRAKE" if _handbraking else "GRIP"
	if global_position.y < -10.0:
		_reset_car()


func _step_motion(delta: float, throttle: float, steering: float, footbrake: bool, handbrake: bool) -> void:
	var planar: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var grounded: bool = is_on_floor()
	var forward: Vector3 = -global_basis.z
	var right: Vector3 = global_basis.x
	_speed = planar.dot(forward)
	_handbraking = handbrake and grounded and planar.length() > 3.0
	var response: float = steering_return if is_zero_approx(steering) else steering_response
	_steering = move_toward(_steering, clampf(steering, -1.0, 1.0), response * delta)
	if grounded:
		if footbrake:
			planar = planar.move_toward(Vector3.ZERO, braking * delta)
		elif not is_zero_approx(throttle):
			var target: float = top_speed if throttle > 0.0 else -reverse_speed
			var rate: float = braking if _speed * throttle < 0.0 else acceleration
			var longitudinal: float = move_toward(_speed, target, rate * delta)
			planar += forward * (longitudinal - _speed)
		else:
			planar = planar.move_toward(Vector3.ZERO, rolling_drag * delta)
		if _handbraking:
			planar = planar.move_toward(Vector3.ZERO, handbrake_drag * delta)

		var speed_ratio: float = clampf(planar.length() / top_speed, 0.0, 1.0)
		var turn_rate: float = lerpf(low_speed_turn_rate, high_speed_turn_rate, speed_ratio)
		var travel_sign: float = signf(planar.dot(forward))
		var low_speed_weight: float = clampf(absf(planar.dot(forward)) / 4.0, 0.0, 1.0)
		var boost: float = handbrake_turn_boost if _handbraking else 1.0
		var target_yaw: float = -_steering * turn_rate * low_speed_weight * travel_sign * boost
		_yaw_rate = lerpf(_yaw_rate, target_yaw, 1.0 - exp(-10.0 * delta))
		rotate_y(_yaw_rate * delta)

		# Turn the body without snapping its world-space momentum to the new heading.
		right = global_basis.x
		var target_grip: float = slide_grip if _handbraking else road_grip
		_grip = lerpf(_grip, target_grip, 1.0 - exp(-8.0 * delta))
		planar -= right * planar.dot(right) * (1.0 - exp(-_grip * delta))
		planar = planar.limit_length(top_speed)
		velocity.y = -0.5
	else:
		velocity.y -= 22.0 * delta
	velocity.x = planar.x
	velocity.z = planar.z
	move_and_slide()
	_speed = Vector3(velocity.x, 0.0, velocity.z).dot(-global_basis.z)


func _process(delta: float) -> void:
	var speed_ratio: float = clampf(Vector2(velocity.x, velocity.z).length() / top_speed, 0.0, 1.0)
	var follow: float = 1.0 - exp(-14.0 * delta)
	_camera_arm.global_position = _camera_arm.global_position.lerp(global_position + Vector3.UP * 1.5, follow)
	_camera_arm.rotation.y = lerp_angle(_camera_arm.rotation.y, global_rotation.y, 1.0 - exp(-7.0 * delta))
	_camera_arm.spring_length = lerpf(_camera_arm.spring_length, 7.5 + speed_ratio, follow)
	_camera.fov = lerpf(_camera.fov, 75.0 + speed_ratio * 7.0, 1.0 - exp(-3.0 * delta))
	_visuals.rotation.z = lerpf(_visuals.rotation.z, _steering * speed_ratio * deg_to_rad(4.0), follow)


func _held(first: Key, second: Key) -> bool:
	return Input.is_physical_key_pressed(first) or Input.is_physical_key_pressed(second)


func _snap_camera() -> void:
	_camera_arm.global_position = global_position + Vector3.UP * 1.5
	_camera_arm.global_rotation = Vector3(deg_to_rad(-15.0), global_rotation.y, 0.0)
	_camera_arm.spring_length = 7.5
	_camera.fov = 75.0


func _reset_car() -> void:
	global_transform = _spawn_transform
	velocity = Vector3.ZERO
	_speed = 0.0
	_steering = 0.0
	_yaw_rate = 0.0
	_grip = road_grip
	_handbraking = false
	_visuals.rotation = Vector3.ZERO
	_snap_camera()
	reset_physics_interpolation()
	reset_to_spawn.emit()
