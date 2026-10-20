extends SceneTree
var failures: Array[String] = []
func check(value: bool,message: String) -> void:
	if not value: failures.append(message); push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world: Node3D = load("res://scenes/test_environment.tscn").instantiate(); root.add_child(world)
	var car: CharacterBody3D = world.find_child("PlayerCar",true,false)
	check(car!=null,"Playable vehicle exists")
	car.set_physics_process(false)
	var audio: Node3D = car.get_node("VehicleAudio"); audio.set_physics_process(false)
	for i in range(3): await physics_frame
	for player in [audio.engine,audio.skid,audio.impact]: check(player.stream.get_length()>0.01,"Imported CC0 sound contains audio")
	check(audio.engine.stream.loop and audio.skid.stream.loop and not audio.impact.stream.loop,"Engine and tires loop; impact is one shot")
	var idle: Dictionary = audio.targets(0,0,0,false,true,0.1)
	check(idle.skid==0 and idle.engine_db< -20,"Stationary idle remains quiet without tire squeal")
	var shifted := false; var pitch_drop := false
	for index in range(600):
		var previous_gear: int = audio.gear; var previous_rpm: float = audio.rpm
		var state: Dictionary = audio.targets(float(index)*0.1,1,0,false,true,0.05)
		check(state.pitch>=0.6 and state.pitch<=2.2,"Pitch remains in playback range")
		if audio.gear>previous_gear:
			shifted = true; pitch_drop = pitch_drop or audio.rpm<previous_rpm
	check(shifted and pitch_drop and audio.gear>=3,"Acceleration produces successive upshifts and an RPM drop")
	check(audio.targets(20,1,4,true,true,0.1).skid>0,"Handbrake/slip produces tire sound")
	check(audio.targets(20,1,4,true,false,0.1).skid==0,"Airborne tires stay silent")
	check(audio.targets(0,1,4,true,true,0.1).skid==0,"Stationary handbrake does not squeal")
	car._speed = -5; audio.targets(-5,-1,0,false,true,0.1)
	check(audio.gear_label()=="R","Reverse uses reverse gear readout")
	paused = true; await process_frame
	check(audio.engine.stream_paused and audio.skid.stream_paused,"Pause silences continuous vehicle sounds")
	paused = false; await process_frame
	check(not audio.engine.stream_paused,"Resume restores audio")
	var profile := root.get_node("StreetProfile"); var old_volume: float = profile.vehicle_volume; var old_path: String = profile.path
	profile.path = "res://tests/vehicle-audio-test.tmp"; profile.vehicle_volume = 0; profile.apply_audio()
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Vehicles")),"Separate vehicle volume can mute the mix")
	check(profile.save()==OK,"Vehicle volume saves")
	var config := ConfigFile.new(); config.load(profile.path)
	check(config.get_value("audio","vehicles",1)==0,"Saved vehicle volume survives config reload")
	DirAccess.remove_absolute(profile.path); profile.path = old_path; profile.vehicle_volume = old_volume; profile.apply_audio()
	car._reset_car(); check(audio.gear==0 and audio.rpm<1000 and audio.impact_cooldown>0,"Recovery resets engine state without a false impact")
	for i in range(45):
		car._step_motion(1.0/60,0,0,true,false); await physics_frame
	check(car.get_slide_collision_count()>0,"Ground contact present for finish-freeze regression")
	car.controls_locked = true; car.velocity = Vector3.ZERO; audio.last_velocity = Vector3(25,0,0); audio.impact_cooldown = 0
	audio._physics_process(1.0/60)
	for i in range(2): await physics_frame
	check(not audio.impact.playing,"Race entry/finish freezes do not produce a false crash sound")
	print("VEHICLE AUDIO ","PASS" if failures.is_empty() else "FAIL "+str(failures))
	world.queue_free(); await process_frame; quit(0 if failures.is_empty() else 1)
