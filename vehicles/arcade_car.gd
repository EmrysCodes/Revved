extends CharacterBody3D
## Arcade handling. Physics uses meters and seconds; HUD uses GameSettings.

signal reset_to_spawn

@export_group("Power and braking")
@export var top_speed: float = 69.3
@export var reverse_speed: float = 9.0
@export var acceleration: float = 7.0
@export var braking: float = 10.5
@export var rolling_drag: float = 1.0
## Arcade approximation of gearing/drag: acceleration falls with road speed.
@export var power_falloff_speed: float = 27.0
@export var steering_speed_reference: float = 32.0
@export var cornering_acceleration: float = 38.0
@export var handbrake_drag: float = 5.5

@export_group("Steering and grip")
@export var low_speed_turn_rate: float = 2.0
@export var high_speed_turn_rate: float = 0.85
@export var steering_response: float = 8.0
@export var steering_return: float = 10.0
@export var road_grip: float = 10.0
@export var slide_grip: float = 3.0
@export var handbrake_turn_boost: float = 1.45
@export var align_to_slopes: bool = false
@export var max_step_height: float = 0.32

var _speed: float = 0.0
var _steering: float = 0.0
var _yaw_rate: float = 0.0
var _grip: float = 10.0
var _spawn_transform: Transform3D
var _handbraking: bool = false
var _drift_blend: float = 0.0
var _stock_stats: Dictionary
var controls_locked := false

@onready var _readout: Label = $HUD/Screen/DrivePanel/Padding/Stack/Readout
@onready var _status: Label = $HUD/Screen/DrivePanel/Padding/Stack/Status
@onready var _visuals: Node3D = $Visuals
@onready var _camera_arm: SpringArm3D = $CameraArm
@onready var _camera: Camera3D = $CameraArm/FollowCamera
@onready var _car_model: Node3D = $Visuals/S64Compact


func _ready() -> void:
	_spawn_transform = global_transform
	_stock_stats = {"top_speed": top_speed, "acceleration": acceleration, "braking": braking, "grip": road_grip}
	_apply_performance()
	GameSettings.performance_changed.connect(_apply_performance)
	_grip = road_grip
	_camera_arm.add_excluded_object(get_rid())
	_camera_arm.top_level = true
	_camera_arm.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_snap_camera()
	GameSettings.units_changed.connect(_update_speed_readout)
	reset_physics_interpolation()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R and not controls_locked:
			_reset_car()


func _physics_process(delta: float) -> void:
	if controls_locked:
		_step_motion(delta,0.0,0.0,true,false)
		_update_speed_readout()
		return
	var throttle: float = float(_held(KEY_W, KEY_UP)) - float(_held(KEY_S, KEY_DOWN))
	var steering: float = float(_held(KEY_D, KEY_RIGHT)) - float(_held(KEY_A, KEY_LEFT))
	_step_motion(delta, throttle, steering, Input.is_physical_key_pressed(KEY_SHIFT), Input.is_physical_key_pressed(KEY_SPACE))
	_update_speed_readout()
	_status.text = "HANDBRAKE" if _handbraking else ("DRIFT / RECOVER" if _drift_blend > 0.15 else "GRIP")
	if global_position.y < -10.0:
		_reset_car()


func _step_motion(delta: float, throttle: float, steering: float, footbrake: bool, handbrake: bool) -> void:
	var planar: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	var grounded: bool = is_on_floor()
	var forward: Vector3 = -global_basis.z
	var right: Vector3 = global_basis.x
	_speed = planar.dot(forward)
	_handbraking = handbrake and grounded and planar.length() > 3.0
	_drift_blend = move_toward(_drift_blend, 1.0 if _handbraking else 0.0, (12.0 if _handbraking else 3.6) * delta)
	var response: float = steering_return if is_zero_approx(steering) else steering_response
	_steering = move_toward(_steering, clampf(steering, -1.0, 1.0), response * delta)
	if grounded:
		if footbrake:
			planar = planar.move_toward(Vector3.ZERO, braking * delta)
		elif not is_zero_approx(throttle):
			var target: float = top_speed if throttle > 0.0 else -reverse_speed
			var rate: float = braking if _speed * throttle < 0.0 else _drive_acceleration(_speed)
			var longitudinal: float = move_toward(_speed, target, rate * delta)
			planar += forward * (longitudinal - _speed)
		else:
			planar = planar.move_toward(Vector3.ZERO, rolling_drag * delta)
		if _handbraking:
			planar = planar.move_toward(Vector3.ZERO, handbrake_drag * delta)

		var speed_ratio: float = clampf(planar.length() / steering_speed_reference, 0.0, 1.0)
		var turn_rate: float = lerpf(low_speed_turn_rate, high_speed_turn_rate, speed_ratio)
		# Keep high-speed steering stable when engine upgrades raise the speed ceiling.
		turn_rate = minf(turn_rate, cornering_acceleration * road_grip / 10.0 / maxf(planar.length(), 1.0))
		var travel_sign: float = signf(planar.dot(forward))
		var low_speed_weight: float = clampf(absf(planar.dot(forward)) / 4.0, 0.0, 1.0)
		var boost: float = lerpf(1.0, handbrake_turn_boost, _drift_blend)
		var target_yaw: float = -_steering * turn_rate * low_speed_weight * travel_sign * boost
		_yaw_rate = lerpf(_yaw_rate, target_yaw, 1.0 - exp(-16.0 * delta))
		rotate_y(_yaw_rate * delta)

		# Turn the body without snapping its world-space momentum to the new heading.
		right = global_basis.x
		var target_grip: float = lerpf(road_grip, slide_grip, _drift_blend)
		_grip = lerpf(_grip, target_grip, 1.0 - exp(-(18.0 if _handbraking else 8.0) * delta))
		planar -= right * planar.dot(right) * (1.0 - exp(-_grip * delta))
		planar = planar.limit_length(top_speed)
		velocity.y = -0.5
	else:
		velocity.y -= 22.0 * delta
	velocity.x = planar.x
	velocity.z = planar.z
	if grounded:
		_try_small_step(planar * delta)
	move_and_slide()
	_speed = Vector3(velocity.x, 0.0, velocity.z).dot(-global_basis.z)
	_car_model.update_wheels(_steering, _speed if is_on_floor() else 0.0, delta)
	var roll_ratio: float = clampf(planar.length() / top_speed, 0.0, 1.0)
	var pitch: float = 0.0
	var bank: float = 0.0
	if align_to_slopes and is_on_floor():
		var normal: Vector3 = get_floor_normal()
		pitch = atan2(-normal.dot(-global_basis.z), normal.y)
		bank = atan2(-normal.dot(global_basis.x), normal.y)
	_visuals.rotation.x = lerpf(_visuals.rotation.x, pitch, 1.0 - exp(-14.0 * delta))
	_visuals.rotation.z = lerpf(_visuals.rotation.z, bank + _steering * roll_ratio * deg_to_rad(4.0), 1.0 - exp(-14.0 * delta))


func _drive_acceleration(speed: float) -> float:
	if speed<0.0:
		return acceleration
	return acceleration / (1.0 + pow(speed / maxf(power_falloff_speed, 1.0), 2.0))


func _try_small_step(motion: Vector3) -> void:
	if max_step_height <= 0.0 or motion.length_squared() < 0.000001:
		return
	var obstacle := KinematicCollision3D.new()
	if not test_move(global_transform, motion, obstacle):
		return
	if obstacle.get_normal().dot(Vector3.UP) >= cos(floor_max_angle):
		return
	var lift := Vector3.UP * max_step_height
	if test_move(global_transform, lift):
		return
	var raised: Transform3D = global_transform.translated(lift)
	if test_move(raised, motion):
		return
	var landing := KinematicCollision3D.new()
	if not test_move(raised.translated(motion), Vector3.DOWN * (max_step_height + 0.08), landing):
		return
	if landing.get_normal().dot(Vector3.UP) < cos(floor_max_angle):
		return
	var rise: float = max_step_height + landing.get_travel().y
	if rise > 0.002 and rise <= max_step_height:
		global_position.y += rise + 0.002


func _process(delta: float) -> void:
	var speed_ratio: float = clampf(Vector2(velocity.x, velocity.z).length() / top_speed, 0.0, 1.0)
	var follow: float = 1.0 - exp(-14.0 * delta)
	var rendered_transform: Transform3D = get_global_transform_interpolated()
	_camera_arm.global_position = _camera_arm.global_position.lerp(rendered_transform.origin + Vector3.UP * 1.5, follow)
	_camera_arm.rotation.y = lerp_angle(_camera_arm.rotation.y, rendered_transform.basis.get_euler().y, 1.0 - exp(-7.0 * delta))
	_camera.fov = lerpf(_camera.fov, 75.0 + speed_ratio * 7.0, 1.0 - exp(-3.0 * delta))


func _apply_performance() -> void:
	var upgrades: Dictionary = GameSettings.performance_multipliers()
	top_speed = _stock_stats.top_speed * upgrades.top_speed
	acceleration = _stock_stats.acceleration * upgrades.acceleration
	braking = _stock_stats.braking * upgrades.braking
	road_grip = _stock_stats.grip * upgrades.grip


func _held(first: Key, second: Key) -> bool:
	return Input.is_physical_key_pressed(first) or Input.is_physical_key_pressed(second)


func _update_speed_readout() -> void:
	_readout.text = GameSettings.format_speed(Vector2(velocity.x, velocity.z).length())


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
	_drift_blend = 0.0
	_visuals.rotation = Vector3.ZERO
	_car_model.reset_wheels()
	_snap_camera()
	reset_physics_interpolation()
	reset_to_spawn.emit()
