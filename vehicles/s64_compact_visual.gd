extends Node3D
## Visual steering and rolling are independent of the car's collision body.

@export var wheel_radius: float = 0.292335
@export var maximum_steer_degrees: float = 30.0

var _roll_angle: float = 0.0
@onready var _wheels: Array[Node3D] = [$FrontLeft/Spin, $FrontRight/Spin, $RearLeft/Spin, $RearRight/Spin]


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
