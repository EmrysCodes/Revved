extends SceneTree
var failures: Array[String] = []
func check(value: bool,message: String) -> void:
	if not value: failures.append(message); push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var profile := root.get_node("StreetProfile"); profile.path = "res://tests/city-loading.tmp"
	for mode in ["free","single","garage"]:
		profile.driver_created = true; profile.selected_event = "capital_run"
		profile.launch(mode)
		await process_frame; await process_frame
		check(current_scene!=null and current_scene.name=="LoadingCity","Launch uses visible loading screen")
		var started := Time.get_ticks_msec()
		while current_scene and current_scene.name=="LoadingCity" and Time.get_ticks_msec()-started<60000:
			if current_scene.failed: break
			await process_frame
		check(current_scene!=null and current_scene.name!="LoadingCity","Loading completes: "+mode)
		if current_scene and current_scene.name!="LoadingCity":
			for i in range(18): await physics_frame
			check(current_scene.has_meta("modern_city_buildings"),"Normal updated city is the destination: "+mode)
			if mode=="single": check(current_scene.get_node("CityRace").is_active(),"Practice race starts after load")
			elif mode=="garage": check(paused and current_scene.car.get_node("PauseMenu/Garage").visible,"Career garage opens after load")
		paused = false
		if current_scene: current_scene.queue_free(); current_scene = null
		for i in range(4): await process_frame
	DirAccess.remove_absolute(profile.path)
	print("CITY LOADING ","PASS" if failures.is_empty() else "FAIL "+str(failures))
	quit(0 if failures.is_empty() else 1)
