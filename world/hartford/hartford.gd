extends "res://world/downtown.gd"
@export var map_min := Vector2(-2250, -1900)
@export var map_max := Vector2(2250, 1900)
@export var map_title := "HARTFORD / N"
func _ready() -> void:
	super._ready()
	if get_meta("offline_build",false):return
	car.get_node("CameraArm/FollowCamera").far = 5000
	car.reset_to_spawn.connect(_restore_glass)
	if ResourceLoader.exists("res://world/eastside/frontage.tscn"):
		add_child(load("res://world/eastside/frontage.tscn").instantiate())
	if preload("res://world/hartford/modern_art.gd").available():
		var modern := Node3D.new(); modern.set_script(load("res://world/hartford/modern_art.gd")); add_child(modern)
	if ResourceLoader.exists("res://world/hartford/continuous_streets.scn"):
		add_child(load("res://world/hartford/continuous_streets.scn").instantiate())
	if ResourceLoader.exists("res://world/hartford/city_streetwall.scn"):
		add_child(load("res://world/hartford/city_streetwall.scn").instantiate())
	var detail := Node3D.new(); detail.set_script(load("res://world/hartford/downtown_detail.gd")); add_child(detail)
	call_deferred("_add_city_life")
	call_deferred("_add_ambience")
	call_deferred("_add_population")
	if FileAccess.file_exists("res://racing/capital_run_route.json"):
		call_deferred("_add_city_race")
func _add_city_race() -> void:
	if get_node_or_null("CityRace")==null:
		add_child(load("res://racing/capital_run.tscn").instantiate())
		if StreetProfile.launch_mode in ["single","career"]:
			get_node("CityRace").start_race()
		elif StreetProfile.launch_mode=="garage":
			car.get_node("PauseMenu").open_menu()
			car.get_node("PauseMenu").call("_open_garage")
func _add_city_life() -> void:
	var life:=Node3D.new();life.name="CityLife"
	life.set_script(load("res://world/hartford/city_life.gd"));add_child(life)
func _add_ambience() -> void:
	var ambience:=Node3D.new();ambience.name="CityAmbience"
	ambience.set_script(load("res://audio/city_ambience.gd"));add_child(ambience)
func _add_population() -> void:
	if get_meta("disable_population",false):return
	for entry in [["CityTraffic","res://world/city_traffic.gd"],["CityPedestrians","res://world/city_pedestrians.gd"]]:
		var population:=Node3D.new();population.name=entry[0];population.set_script(load(entry[1]));add_child(population)
func _restore_glass() -> void:
	for pane in $Shortcuts.find_children("*","Area3D",true,false):
		pane.restore()
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if car.position.y < -1.5 or absf(car.position.x) > 2180 or absf(car.position.z) > 1830:
		car.call("_reset_car")
func _update_readout() -> void:
	var district := "DOWNTOWN HARTFORD"
	if car.position.x < -850:
		district = "ASYLUM HILL / FROG HOLLOW"
	elif car.position.x > 950:
		district = "EASTSIDE / FOUNDERS DISTRICT"
	elif car.position.z > 550:
		district = "SHELDON / SOUTH END"
	elif car.position.z < -700:
		district = "NORTH END / HIGHWAY INTERCHANGE"
	# Reserve the upper-right corner for the event card and race standings.
	var race := get_node_or_null("CityRace")
	readout.visible = race==null or not is_instance_valid(race.hud) or not race.hud.card.visible
	readout.text = "%s\nDriven  %s\nI-84 / I-91 / RT 2 / RT 3 + CITY LOOP\nGlass-front arcades and park paths are driveable" % [district, GameSettings.format_distance(driven)]
