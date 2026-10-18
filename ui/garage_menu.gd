extends Control

signal back_requested

@onready var _body: OptionButton = $Frame/Stack/Content/Options/Padding/Rows/Body
@onready var _wheels: OptionButton = $Frame/Stack/Content/Options/Padding/Rows/Wheels
@onready var _paint: OptionButton = $Frame/Stack/Content/Options/Padding/Rows/Paint
@onready var _feedback: Label = $Frame/Stack/Content/Options/Padding/Rows/Feedback
@onready var _back: Button = $Frame/Stack/Content/Options/Padding/Rows/Back
@onready var _viewport: SubViewport = $Frame/Stack/Content/Preview/Viewport
@onready var _model: Node3D = $Frame/Stack/Content/Preview/Viewport/Stage/Car


func _ready() -> void:
	for title in ["Street kit", "Aero kit", "Widebody kit"]:
		_body.add_item(title)
	for title in ["Multi-spoke", "Sport spokes", "Deep dish", "Classic spokes"]:
		_wheels.add_item(title)
	for title in preload("res://vehicles/s64_compact_visual.gd").PAINT_NAMES:
		_paint.add_item(title)
	_body.item_selected.connect(_on_choice)
	_wheels.item_selected.connect(_on_choice)
	_paint.item_selected.connect(_on_choice)
	_back.pressed.connect(func() -> void: back_requested.emit())
	$Frame/Stack/Content/Options/Padding/Rows/Rotation/Left.pressed.connect(func() -> void: _model.rotate_y(deg_to_rad(-30.0)))
	$Frame/Stack/Content/Options/Padding/Rows/Rotation/Right.pressed.connect(func() -> void: _model.rotate_y(deg_to_rad(30.0)))
	$Frame/Stack/Content/Preview/Viewport/Stage/Camera.look_at(Vector3(0, 0.65, 0))
	visibility_changed.connect(_update_rendering)
	_update_rendering()


func open_garage() -> void:
	_body.select(GameSettings.car_body)
	_wheels.select(GameSettings.car_wheels)
	_paint.select(GameSettings.car_paint)
	_feedback.text = "Changes apply to your car and save automatically."
	_model.rotation = Vector3.ZERO
	show()
	_body.grab_focus()


func _on_choice(_index: int) -> void:
	var result: Error = GameSettings.set_car_style(_body.selected, _wheels.selected, _paint.selected)
	_feedback.text = "Car style saved." if result == OK else "Style applied for this session. Could not save preferences."


func _update_rendering() -> void:
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if is_visible_in_tree() else SubViewport.UPDATE_DISABLED
