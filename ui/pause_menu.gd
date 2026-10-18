extends CanvasLayer

var _opened: bool = false

@onready var _overlay: Control = $Overlay
@onready var _units: OptionButton = $Overlay/Center/Card/Padding/Stack/UnitsRow/Units
@onready var _feedback: Label = $Overlay/Center/Card/Padding/Stack/Feedback
@onready var _resume: Button = $Overlay/Center/Card/Padding/Stack/Resume
@onready var _restart: Button = $Overlay/Center/Card/Padding/Stack/Restart


func _ready() -> void:
	_units.add_item("US — MPH / miles / feet", GameSettings.Units.US)
	_units.add_item("Metric — km/h / km / m", GameSettings.Units.METRIC)
	_units.item_selected.connect(_on_units_selected)
	_resume.pressed.connect(close_menu)
	_restart.pressed.connect(_restart_attempt)
	_overlay.hide()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if _opened:
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
	get_viewport().gui_release_focus()
	get_tree().paused = false


func _on_units_selected(index: int) -> void:
	var result: Error = GameSettings.set_unit_system(_units.get_item_id(index))
	_feedback.text = "Unit preference saved." if result == OK else "Units applied for this session. Could not save preferences."


func _restart_attempt() -> void:
	get_parent().call("_reset_car")
	close_menu()


func _exit_tree() -> void:
	if _opened:
		get_tree().paused = false
