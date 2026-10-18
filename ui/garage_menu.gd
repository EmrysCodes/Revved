extends Control

signal back_requested

const ROWS: String = "Frame/Stack/Content/Options/Padding/Rows"
const SECTION_CONTROLS: Array = [
	["EngineLabel", "Engine", "BrakesLabel", "Brakes", "TiresLabel", "Tires"],
	["BodyLabel", "Body", "WheelsLabel", "Wheels"],
	["PaintLabel", "Paint", "VinylLabel", "Vinyl", "VinylColorLabel", "VinylColor"]
]
var _dragging: bool = false
var _orbit_pitch: float = 0.28
var _orbit_distance: float = 7.6

@onready var _body: OptionButton = get_node(ROWS + "/Body")
@onready var _wheels: OptionButton = get_node(ROWS + "/Wheels")
@onready var _paint: OptionButton = get_node(ROWS + "/Paint")
@onready var _vinyl: OptionButton = get_node(ROWS + "/Vinyl")
@onready var _vinyl_color: OptionButton = get_node(ROWS + "/VinylColor")
@onready var _engine: OptionButton = get_node(ROWS + "/Engine")
@onready var _brakes: OptionButton = get_node(ROWS + "/Brakes")
@onready var _tires: OptionButton = get_node(ROWS + "/Tires")
@onready var _feedback: Label = get_node(ROWS + "/Feedback")
@onready var _back: Button = get_node(ROWS + "/Back")
@onready var _sections: TabBar = $Frame/Stack/Sections
@onready var _preview: SubViewportContainer = $Frame/Stack/Content/Preview
@onready var _viewport: SubViewport = $Frame/Stack/Content/Preview/Viewport
@onready var _model: Node3D = $Frame/Stack/Content/Preview/Viewport/Stage/Car
@onready var _camera: Camera3D = $Frame/Stack/Content/Preview/Viewport/Stage/Camera
@onready var _stats: Label = $Frame/Stack/Content/Preview/StatsPanel/Padding/Stats


func _ready() -> void:
	for title in ["Performance", "Visuals", "Paint / decals"]:
		_sections.add_tab(title)
	for title in ["Street kit", "Aero kit", "Widebody kit"]:
		_body.add_item(title)
	for title in ["Multi-spoke", "Sport spokes", "Deep dish", "Classic spokes"]:
		_wheels.add_item(title)
	for title in preload("res://vehicles/s64_compact_visual.gd").PAINT_NAMES:
		_paint.add_item(title)
	for title in ["None", "Twin hood stripes", "Side flash"]:
		_vinyl.add_item(title)
	for title in ["White", "Black", "Gold"]:
		_vinyl_color.add_item(title)
	for selector in [_engine, _brakes, _tires]:
		for title in ["Stock", "Street", "Sport", "Race"]:
			selector.add_item(title)
		selector.item_selected.connect(_on_performance_choice)
	_body.item_selected.connect(_on_choice)
	_wheels.item_selected.connect(_on_choice)
	_paint.item_selected.connect(_on_choice)
	_vinyl.item_selected.connect(_on_vinyl_choice)
	_vinyl_color.item_selected.connect(_on_vinyl_choice)
	_sections.tab_changed.connect(_show_section)
	_back.pressed.connect(func() -> void: back_requested.emit())
	_preview.gui_input.connect(_on_preview_input)
	_preview.mouse_default_cursor_shape = Control.CURSOR_DRAG
	GameSettings.units_changed.connect(_refresh_summary)
	visibility_changed.connect(_update_rendering)
	_position_camera()
	_show_section(0)
	_update_rendering()


func open_garage() -> void:
	_body.select(GameSettings.car_body)
	_wheels.select(GameSettings.car_wheels)
	_paint.select(GameSettings.car_paint)
	_vinyl.select(GameSettings.car_vinyl)
	_vinyl_color.select(GameSettings.car_vinyl_color)
	_engine.select(GameSettings.engine_level)
	_brakes.select(GameSettings.brakes_level)
	_tires.select(GameSettings.tires_level)
	_feedback.text = "Changes apply immediately and save automatically."
	_model.rotation = Vector3.ZERO
	_orbit_pitch = 0.28
	_orbit_distance = 7.6
	_dragging = false
	_position_camera()
	_sections.current_tab = 0
	_show_section(0)
	_refresh_summary()
	show()
	_engine.grab_focus()


func _show_section(section: int) -> void:
	for index in range(SECTION_CONTROLS.size()):
		for control_name in SECTION_CONTROLS[index]:
			get_node(ROWS + "/" + control_name).visible = index == section
	get_node(ROWS + "/Description").text = [
		"Upgrade driving stats. All levels are unlocked for testing.",
		"Change body kits and wheels. Performance stays the same.",
		"Choose paint and preset vinyl graphics."
	][section]


func _on_choice(_index: int) -> void:
	_show_save_result(GameSettings.set_car_style(_body.selected, _wheels.selected, _paint.selected))


func _on_vinyl_choice(_index: int) -> void:
	_show_save_result(GameSettings.set_vinyl(_vinyl.selected, _vinyl_color.selected))


func _on_performance_choice(_index: int) -> void:
	_show_save_result(GameSettings.set_performance(_engine.selected, _brakes.selected, _tires.selected))
	_refresh_summary()


func _show_save_result(result: Error) -> void:
	_feedback.text = "Selection saved." if result == OK else "Applied for this session. Could not save preferences."


func _refresh_summary() -> void:
	var car: CharacterBody3D = get_parent().get_parent()
	_stats.text = "TOP SPEED LIMIT  %s\nAcceleration +%d%%   Braking +%d%%   Grip +%d%%\nDrag to rotate / tilt. Scroll to zoom." % [GameSettings.format_speed(car.top_speed), GameSettings.engine_level * 15, GameSettings.brakes_level * 20, GameSettings.tires_level * 10]


func _on_preview_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			_preview.accept_event()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var direction: float = -1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
			_orbit_distance = clampf(_orbit_distance + direction * 0.4, 5.2, 10.0)
			_position_camera()
			_preview.accept_event()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		_dragging = false
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false
	if _dragging and event is InputEventMouseMotion:
		_model.rotate_y(event.relative.x * 0.008)
		_orbit_pitch = clampf(_orbit_pitch + event.relative.y * 0.006, 0.12, 0.85)
		_position_camera()
		get_viewport().set_input_as_handled()


func _position_camera() -> void:
	var horizontal: float = _orbit_distance * cos(_orbit_pitch)
	_camera.position = Vector3(horizontal * 0.7071068, 0.65 + _orbit_distance * sin(_orbit_pitch), -horizontal * 0.7071068)
	_camera.look_at(Vector3(0, 0.65, 0))


func _update_rendering() -> void:
	_dragging = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if is_visible_in_tree() else SubViewport.UPDATE_DISABLED
