extends CanvasLayer

var _opened: bool = false
var _city_race: Node
var _leave_race: Button

@onready var _overlay: Control = $Overlay
@onready var _units: OptionButton = $Overlay/Center/Card/Padding/Stack/UnitsRow/Units
@onready var _feedback: Label = $Overlay/Center/Card/Padding/Stack/Feedback
@onready var _resume: Button = $Overlay/Center/Card/Padding/Stack/Resume
@onready var _restart: Button = $Overlay/Center/Card/Padding/Stack/Restart
@onready var _garage: Control = $Garage


func _ready() -> void:
	_units.add_item("US — MPH / miles / feet", GameSettings.Units.US)
	_units.add_item("Metric — km/h / km / m", GameSettings.Units.METRIC)
	_units.item_selected.connect(_on_units_selected)
	_resume.pressed.connect(close_menu)
	_restart.pressed.connect(_restart_attempt)
	$Overlay/Center/Card/Padding/Stack/Garage.pressed.connect(_open_garage)
	_garage.back_requested.connect(_close_garage)
	_overlay.hide()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if _garage.visible:
			_close_garage()
		elif _opened:
			close_menu()
		else:
			open_menu()
		get_viewport().set_input_as_handled()


func open_menu() -> void:
	if _opened or get_tree().paused:
		return
	_opened = true
	_units.select(_units.get_item_index(GameSettings.unit_system))
	_feedback.text = "Unit preferences save automatically."
	_overlay.show()
	get_tree().paused = true
	_resume.grab_focus()


func close_menu() -> void:
	if not _opened:
		return
	_opened = false
	_overlay.hide()
	_garage.hide()
	get_viewport().gui_release_focus()
	get_tree().paused = false


func _on_units_selected(index: int) -> void:
	var result: Error = GameSettings.set_unit_system(_units.get_item_id(index))
	_feedback.text = "Unit preference saved." if result == OK else "Units applied for this session. Could not save preferences."


func _restart_attempt() -> void:
	if is_instance_valid(_city_race) and _city_race.is_active():
		close_menu()
		_city_race.start_race(true)
		return
	get_parent().call("_reset_car")
	close_menu()


func bind_city_race(event: Node) -> void:
	_city_race=event
	var stack: VBoxContainer=$Overlay/Center/Card/Padding/Stack
	_leave_race=Button.new();_leave_race.name="LeaveCityRace"
	_leave_race.text="Leave race";_leave_race.custom_minimum_size=Vector2(0,44)
	_leave_race.add_theme_font_size_override("font_size",20)
	stack.add_child(_leave_race)
	stack.move_child(_leave_race,stack.get_node("Garage").get_index())
	_leave_race.pressed.connect(func():
		close_menu()
		_city_race.exit_to_free_roam())
	_city_race.state_changed.connect(_refresh_city_race)
	_refresh_city_race()


func _refresh_city_race() -> void:
	var active: bool=is_instance_valid(_city_race) and _city_race.is_active()
	_restart.text="Restart race" if active else "Restart attempt"
	_leave_race.visible=active


func _open_garage() -> void:
	_overlay.hide()
	_garage.open_garage()


func _close_garage() -> void:
	_garage.hide()
	_overlay.show()
	$Overlay/Center/Card/Padding/Stack/Garage.grab_focus()


func _exit_tree() -> void:
	if _opened:
		get_tree().paused = false
