extends CharacterBody3D
## First flat-road arcade prototype. Forward is local -Z; distances are meters.

@export var top_speed: float = 32.0
@export var reverse_speed: float = 9.0
@export var acceleration: float = 12.0
@export var braking: float = 26.0
@export var rolling_drag: float = 4.0
@export var steering_rate: float = 1.6

var _speed: float = 0.0
var _spawn_transform: Transform3D

@onready var _readout: Label = $HUD/Readout


func _ready() -> void:
	_spawn_transform = global_transform
	$CameraArm.add_excluded_object(get_rid())


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R:
			_reset_car()


func _physics_process(delta: float) -> void:
	var throttle: float = float(_held(KEY_W, KEY_UP)) - float(_held(KEY_S, KEY_DOWN))
	var steering: float = float(_held(KEY_D, KEY_RIGHT)) - float(_held(KEY_A, KEY_LEFT))
	var grounded: bool = is_on_floor()
	if grounded:
		if Input.is_physical_key_pressed(KEY_SPACE):
			_speed = move_toward(_speed, 0.0, braking * delta)
		elif not is_zero_approx(throttle):
			var target: float = top_speed if throttle > 0.0 else -reverse_speed
			var rate: float = braking if _speed * throttle < 0.0 else acceleration
			_speed = move_toward(_speed, target, rate * delta)
		else:
			_speed = move_toward(_speed, 0.0, rolling_drag * delta)
		# Reverse steering follows the direction of travel; no turning in place.
		var steering_weight: float = clampf(absf(_speed) / 6.0, 0.0, 1.0)
		rotate_y(-steering * steering_rate * steering_weight * signf(_speed) * delta)

	var forward: Vector3 = -global_transform.basis.z
	velocity.x = forward.x * _speed
	velocity.z = forward.z * _speed
	if grounded:
		velocity.y = -0.5
	else:
		velocity.y -= 22.0 * delta
	move_and_slide()
	# Use collision-resolved motion so barriers do not preserve stored speed.
	_speed = Vector3(velocity.x, 0.0, velocity.z).dot(forward)
	_readout.text = "REVVED | DRIVE TEST\n%03d km/h\nW / Up: accelerate    S / Down: brake / reverse\nA / D or arrows: steer    Space: brake    R: reset" % roundi(absf(_speed) * 3.6)
	if global_position.y < -10.0:
		_reset_car()


func _held(first: Key, second: Key) -> bool:
	return Input.is_physical_key_pressed(first) or Input.is_physical_key_pressed(second)


func _reset_car() -> void:
	global_transform = _spawn_transform
	velocity = Vector3.ZERO
	_speed = 0.0
	reset_physics_interpolation()
