extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failed = true; push_error(message)
func run() -> void:
	for title in ["hartford_district", "downtown_district", "test_circuit", "test_environment"]:
		var scene: Node3D = load("res://scenes/"+title+".tscn").instantiate()
		var env: Environment = scene.get_node("WorldEnvironment").environment
		var sky: ProceduralSkyMaterial = env.sky.sky_material
		check(sky.sky_top_color.v < 0.1 and sky.sky_horizon_color.v < 0.3, title+": no daylight sky in saved scene")
		check(scene.get_node("Moonlight").light_energy < 0.5, title+": no daytime sun")
		scene.free()
	root.get_node("StreetProfile").launch_mode = "free"
	var city: Node3D = load("res://scenes/hartford_district.tscn").instantiate()
	city.set_meta("disable_population", true)
	root.add_child(city)
	for i in range(18): await physics_frame
	var night := city.get_node("PermanentNight")
	night._process(1.0)
	check(city.car.has_node("NightHeadlights"), "Playable car has working headlight rig")
	check(city.car.get_node("NightHeadlights").get_child_count() == 2, "Two road-facing beams")
	check(night.pools.size() <= 12, "Streetlight budget stays bounded")
	check(night.lamp_positions.size() > 1000, "Night controller uses actual city lamp locations")
	var lit := 0
	for pool in night.pools:
		if pool.visible:
			lit += 1
			check(pool.global_position.distance_to(city.car.global_position) < 155, "Only nearby streetlights illuminate")
	check(lit > 0, "Spawn street has live light pools")
	check(city.get_node("WorldEnvironment").environment.sky.sky_material.sky_top_color.v < 0.1,"Runtime remains nighttime")
	city.queue_free(); await process_frame
	print("PERMANENT NIGHT ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
