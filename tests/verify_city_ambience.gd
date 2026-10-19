extends SceneTree
func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value: push_error(message);quit(1);assert(value,message)
func run() -> void:
	var city: Node3D=load("res://scenes/hartford_district.tscn").instantiate();root.add_child(city)
	for i in range(12): await physics_frame
	var ambience: Node3D=city.get_node("CityAmbience")
	check(ambience.beds.size()==5 and ambience.crowds.size()==2,"Five ambience beds and two spatial crowd emitters")
	for key in ambience.beds:
		var stream: AudioStreamWAV=ambience.beds[key].stream
		check(stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and stream.loop_end>stream.loop_begin,"Ambience loops: "+key)
		check(stream.get_length()>20,"Real field recording loaded: "+key)
	var park: Dictionary=ambience.weights_at(Vector3(-565,8,190))
	var urban: Dictionary=ambience.weights_at(Vector3(-100,7,0))
	var bank: Dictionary=ambience.weights_at(Vector3(850,5,0))
	var highway: Dictionary=ambience.weights_at(city.highway_roads[0][20])
	check(park.park>park.city and park.park>urban.park,"Park proximity replaces city bed")
	check(bank.water>urban.water and bank.water>0.5,"Riverbank proximity adds water")
	check(highway.highway>0.6,"Highway proximity adds traffic")
	for point in [Vector3(-100,5,0),Vector3(-565,8,190),Vector3(850,5,0),Vector3(-1800,20,1200)]:
		var power:=0.0
		for value: float in ambience.weights_at(point).values(): power+=value*value
		check(power<=1.0001,"Mix power bounded during overlap")
	var before: Dictionary=ambience.weights_at(Vector3(-500,8,190))
	var after: Dictionary=ambience.weights_at(Vector3(-499.99,8,190))
	check(absf(before.park-after.park)<0.001,"Zone boundaries are continuous")
	var settings:=root.get_node("StreetProfile")
	settings.ambience_volume=0;settings.apply_audio()
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Ambience")),"Ambience volume mutes its bus")
	settings.ambience_volume=0.7;settings.apply_audio()
	city.get_node("CityRace").start_race()
	for i in range(20): ambience.call("_process",0.1)
	check(ambience.crowds[0].volume_db> -20,"Active race fades in localized crowds")
	city.get_node("CityRace").exit_to_free_roam()
	for i in range(60): ambience.call("_process",0.1)
	check(ambience.crowds[0].volume_db< -70,"Leaving race fades crowds out")
	print("PASS: installed audio loops, proximity zones, bounded/continuous mix, mute, race crowd fades")
	quit()
