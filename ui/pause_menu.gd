extends CanvasLayer

var _opened: bool = false

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
	get_parent().call("_reset_car")
	close_menu()


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
