extends Control

signal back_requested

const ROWS: String = "Frame/Stack/Content/Options/Padding/Rows"
const SECTION_CONTROLS: Array = [
	["EngineLabel", "Engine", "EngineBrand", "EngineDetails", "BrakesLabel", "Brakes", "BrakesBrand", "BrakesDetails", "TiresLabel", "Tires", "TiresBrand", "TiresDetails"],
	["BodyLabel", "Body", "HoodLabel", "Hood", "FrontBumperLabel", "FrontBumper", "RearBumperLabel", "RearBumper", "SideSkirtsLabel", "SideSkirts", "WheelsLabel", "Wheels", "SpoilerLabel", "Spoiler", "SpoilerFinishLabel", "SpoilerFinish"],
	["PaintLabel", "Paint", "VinylLabel", "Vinyl", "VinylColorLabel", "VinylColor"]
]
var _vehicle_selector: OptionButton
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
@onready var _back: Button = $Frame/Stack/Back
@onready var _sections: TabBar = $Frame/Stack/Sections
@onready var _preview: SubViewportContainer = $Frame/Stack/Content/Preview
@onready var _viewport: SubViewport = $Frame/Stack/Content/Preview/Viewport
@onready var _model: Node3D = $Frame/Stack/Content/Preview/Viewport/Stage/Car
@onready var _camera: Camera3D = $Frame/Stack/Content/Preview/Viewport/Stage/Camera
@onready var _stats: Label = $Frame/Stack/Content/Preview/StatsPanel/Padding/Stats


func _ready() -> void:
	preload("res://ui/racing_theme.gd").apply(self)
	var hood_label:=Label.new();hood_label.name="HoodLabel";hood_label.text="Hood";get_node(ROWS).add_child(hood_label)
	get_node(ROWS).move_child(hood_label,4)
	var hood:=OptionButton.new();hood.name="Hood";get_node(ROWS).add_child(hood);get_node(ROWS).move_child(hood,5)
	for title in ["Original hood","Stock replacement","Vented hood"]:hood.add_item(title)
	hood.item_selected.connect(func(index):_show_save_result(GameSettings.set_hood(index)))
	var heading:=Label.new();heading.text="CURRENT CAR";get_node(ROWS).add_child(heading);get_node(ROWS).move_child(heading,0)
	_vehicle_selector=OptionButton.new();_vehicle_selector.custom_minimum_size.y=44
	get_node(ROWS).add_child(_vehicle_selector);get_node(ROWS).move_child(_vehicle_selector,1)
	var catalog=preload("res://vehicles/vehicle_catalog.gd")
	for id in range(12):
		_vehicle_selector.add_item(catalog.title(id),id)
		_vehicle_selector.set_item_disabled(id,not catalog.available(id))
	_vehicle_selector.item_selected.connect(func(index):
		_show_save_result(GameSettings.set_vehicle(_vehicle_selector.get_item_id(index)))
		_show_section(_sections.current_tab);_refresh_summary())
	for title in ["Performance", "Visuals", "Paint / decals"]:
		_sections.add_tab(title)
	for title in ["Street kit", "Aero kit", "Widebody kit"]:
		_body.add_item(title)
	for slot in ["FrontBumper", "RearBumper", "SideSkirts"]:
		var selector: OptionButton = get_node(ROWS + "/" + slot)
		for title in ["Street", "Aero", "Widebody"]:
			selector.add_item(title)
		selector.item_selected.connect(_on_parts_choice)
	for index in range(3):
		var selector: OptionButton = get_node(ROWS + "/" + ["EngineBrand", "BrakesBrand", "TiresBrand"][index])
		for title in GameSettings.BRAND_NAMES[index]:
			selector.add_item(title)
		selector.item_selected.connect(_on_brand_choice)
	for title in ["Multi-spoke", "Sport spokes", "Deep dish", "Classic spokes"]:
		_wheels.add_item(title)
	for title in ["None", "Street wing", "Competition wing"]:
		get_node(ROWS + "/Spoiler").add_item(title)
	for title in ["Match body paint", "Satin black"]:
		get_node(ROWS + "/SpoilerFinish").add_item(title)
	get_node(ROWS + "/Spoiler").item_selected.connect(_on_spoiler_choice)
	get_node(ROWS + "/SpoilerFinish").item_selected.connect(_on_spoiler_choice)
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
	_body.item_selected.connect(_on_kit_choice)
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
	_vehicle_selector.select(GameSettings.vehicle_id if preload("res://vehicles/vehicle_catalog.gd").available(GameSettings.vehicle_id) else 0)
	get_node(ROWS+"/Hood").select(GameSettings.car_hood)
	_body.select(GameSettings.car_body)
	_wheels.select(GameSettings.car_wheels)
	_paint.select(GameSettings.car_paint)
	_vinyl.select(GameSettings.car_vinyl)
	_vinyl_color.select(GameSettings.car_vinyl_color)
	_engine.select(GameSettings.engine_level)
	_brakes.select(GameSettings.brakes_level)
	_tires.select(GameSettings.tires_level)
	get_node(ROWS + "/EngineBrand").select(GameSettings.engine_brand)
	get_node(ROWS + "/BrakesBrand").select(GameSettings.brakes_brand)
	get_node(ROWS + "/TiresBrand").select(GameSettings.tires_brand)
	_sync_parts()
	get_node(ROWS + "/Spoiler").select(GameSettings.car_spoiler)
	get_node(ROWS + "/SpoilerFinish").select(GameSettings.spoiler_finish)
	get_node(ROWS + "/SpoilerFinish").disabled = GameSettings.car_spoiler == 0
	_refresh_brands()
	_refresh_prices()
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
		("Spend earned CR on a level; its three balanced brands are included." if _career_garage() else "Practice garage / all performance parts available for testing."),
		"Mix body parts, wheels and spoilers. Scroll for more options.",
		"Choose paint and preset vinyl graphics."
	][section]
	var custom:=preload("res://vehicles/vehicle_catalog.gd").customization(GameSettings.vehicle_id)
	for group in [1,2]:
		for key in SECTION_CONTROLS[group]:
			var control=get_node(ROWS+"/"+key)
			if control is OptionButton: control.disabled=not custom
	get_node(ROWS+"/Hood").visible=section==1 and GameSettings.vehicle_id==11
	get_node(ROWS+"/HoodLabel").visible=section==1 and GameSettings.vehicle_id==11
	if GameSettings.vehicle_id==11:
		for key in ["FrontBumper","RearBumper","SideSkirts"]:
			var select:OptionButton=get_node(ROWS+"/"+key)
			for i in range(3):select.set_item_text(i,["Original","Stock replacement","Aero replacement"][i])
		for i in range(4):_wheels.set_item_text(i,["Meshy stock / silver","Meshy sport / silver","Meshy stock / dark","Meshy sport / dark"][i])
	else:
		for key in ["FrontBumper","RearBumper","SideSkirts"]:
			for i in range(3):get_node(ROWS+"/"+key).set_item_text(i,["Street","Aero","Widebody"][i])
		for i in range(4):_wheels.set_item_text(i,["Multi-spoke","Sport spokes","Deep dish","Classic spokes"][i])
	get_node(ROWS+"/SpoilerFinish").disabled=not custom or GameSettings.car_spoiler==0
	get_node(ROWS+"/BodyLabel").text="KIT PRESET" if GameSettings.vehicle_id==11 else "KIT PRESET / UPPER BODY"
	if not custom and section>0: get_node(ROWS+"/Description").text="Original pack body, wheels and finish. Visual alterations are disabled for these cars."
	$Frame/Stack/Content/Options.set_deferred("scroll_vertical", 0)


func _sync_parts() -> void:
	get_node(ROWS + "/FrontBumper").select(GameSettings.front_bumper)
	get_node(ROWS + "/RearBumper").select(GameSettings.rear_bumper)
	get_node(ROWS + "/SideSkirts").select(GameSettings.side_skirts)


func _on_kit_choice(index: int) -> void:
	GameSettings.set_car_style(index, _wheels.selected, _paint.selected, false)
	_show_save_result(GameSettings.set_kit_preset(index))
	_sync_parts()


func _on_parts_choice(_index: int) -> void:
	_show_save_result(GameSettings.set_body_parts(get_node(ROWS + "/FrontBumper").selected, get_node(ROWS + "/RearBumper").selected, get_node(ROWS + "/SideSkirts").selected))


func _on_spoiler_choice(_index: int) -> void:
	_show_save_result(GameSettings.set_spoiler(get_node(ROWS + "/Spoiler").selected, get_node(ROWS + "/SpoilerFinish").selected))
	get_node(ROWS + "/SpoilerFinish").disabled = GameSettings.car_spoiler == 0


func _on_choice(_index: int) -> void:
	_show_save_result(GameSettings.set_car_style(_body.selected, _wheels.selected, _paint.selected))


func _on_vinyl_choice(_index: int) -> void:
	_show_save_result(GameSettings.set_vinyl(_vinyl.selected, _vinyl_color.selected))


func _career_garage() -> bool:
	return StreetProfile.driver_created and StreetProfile.launch_mode in ["garage","career","legacy_roam"]

func _refresh_prices() -> void:
	for slot in range(3):
		var selector:OptionButton=[_engine,_brakes,_tires][slot]
		for tier in range(4):
			var price:int=StreetProfile.upgrade_price(slot,tier) if _career_garage() else 0
			selector.set_item_text(tier,["Stock","Street","Sport","Race"][tier]+(" / %d CR"%price if price>0 else " / OWNED" if _career_garage() else ""))

func _on_performance_choice(_index: int) -> void:
	var selectors:Array=[_engine,_brakes,_tires]
	var before:Array=[GameSettings.engine_level,GameSettings.brakes_level,GameSettings.tires_level]
	var feedback:="Selection saved."
	if _career_garage():
		for slot in range(3):
			if selectors[slot].selected==before[slot]:continue
			var price:int=StreetProfile.upgrade_price(slot,selectors[slot].selected)
			var result:Error=StreetProfile.buy_upgrade(slot,selectors[slot].selected)
			if result!=OK:
				selectors[slot].select(before[slot])
				feedback="Not enough credits." if result==ERR_UNAVAILABLE else "Could not save purchase. Balance unchanged."
			else:feedback="Upgrade purchased / %d CR. All brands at this level are included."%price if price>0 else "Owned part equipped."
	var saved:Error=GameSettings.set_performance(_engine.selected,_brakes.selected,_tires.selected)
	_refresh_brands();_refresh_prices();_refresh_summary()
	_feedback.text=feedback if saved==OK else feedback+" Preferences save failed."


func _on_brand_choice(_index: int) -> void:
	_show_save_result(GameSettings.set_performance_brands(get_node(ROWS + "/EngineBrand").selected, get_node(ROWS + "/BrakesBrand").selected, get_node(ROWS + "/TiresBrand").selected))
	_refresh_brands()
	_refresh_summary()


func _refresh_brands() -> void:
	var levels := [GameSettings.engine_level, GameSettings.brakes_level, GameSettings.tires_level]
	for index in range(3):
		var key: String = ["Engine", "Brakes", "Tires"][index]
		var selector: OptionButton = get_node(ROWS + "/" + key + "Brand")
		selector.disabled = levels[index] == 0
		get_node(ROWS + "/" + key + "Details").text = "Stock part. Choose an upgrade level for brands." if levels[index] == 0 else GameSettings.BRAND_DETAILS[index][selector.selected]


func _show_save_result(result: Error) -> void:
	_feedback.text = "Selection saved." if result == OK else "Applied for this session. Could not save preferences."


func _refresh_summary() -> void:
	var car: CharacterBody3D = get_parent().get_parent()
	var upgrades: Dictionary = GameSettings.performance_multipliers()
	_refresh_prices()
	_stats.text = "TOP SPEED LIMIT  %s\nAcceleration %+.0f%%   Braking %+.0f%%   Grip %+.0f%%\nDrag to rotate / tilt. Scroll to zoom." % [GameSettings.format_speed(car.top_speed), (upgrades.acceleration - 1.0) * 100.0, (upgrades.braking - 1.0) * 100.0, (upgrades.grip - 1.0) * 100.0]

	if _career_garage():_stats.text="BALANCE %d CR\n"%StreetProfile.credits+_stats.text


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
