extends SceneTree
func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	if not value: push_error(message);quit(1);assert(value,message)
func run() -> void:
	var profile:=root.get_node("StreetProfile")
	profile.path="res://tests/driver-test.tmp";profile.driver_created=false
	profile.event_results={}
	var creator: Control=load("res://ui/legacy/create_driver.tscn").instantiate();root.add_child(creator)
	creator.name_input.text="  ";creator.accept_identity()
	check(creator.stage==0 and not creator.error_label.text.is_empty(),"Blank names rejected")
	creator.name_input.text="Jordan Vale";creator.portrait_set.select(1);creator.accept_identity()
	check(creator.stage==1 and creator.presentation==1,"Name and portrait set lead to portrait screen")
	for set_index in range(2):
		for index in range(10):
			var atlas: AtlasTexture=load("res://core/driver_identity.gd").portrait(set_index,index)
			check(atlas.region.size.x>300 and atlas.region.size.y>300,"All twenty portraits have valid texture regions")
	creator.portrait_index=7;creator.background_index=3;creator.background_page();creator.review_page()
	check(profile.create_driver("Jordan Vale",1,7,3)==OK,"Driver saves")
	var saved:=ConfigFile.new();check(saved.load(profile.path)==OK,"Driver file exists")
	check(saved.get_value("driver","name")=="Jordan Vale" and saved.get_value("driver","portrait")==7,"Driver identity persists")
	var reloaded: Node=load("res://core/street_profile.gd").new()
	reloaded.path=profile.path;root.add_child(reloaded)
	check(reloaded.driver_created and reloaded.driver_name=="Jordan Vale" and reloaded.driver_presentation==1 and reloaded.driver_portrait==7 and reloaded.driver_background==3,"Saved driver reloads completely")
	reloaded.queue_free()
	check(profile.create_driver("Replacement",0,0,0)==ERR_ALREADY_EXISTS,"Background cannot be swapped after confirmation")
	var identity=load("res://core/driver_identity.gd")
	for background in range(1,5):
		var total:=0.0
		for place in range(1,5):
			for recoveries in [0,1]: total+=identity.multiplier(background,place,recoveries)
		check(is_equal_approx(total/8.0,1.0),"Background has symmetric tradeoffs")
	profile.launch_mode="career";profile.reputation=0;profile.record_finish(1,0)
	check(profile.reputation==275,"Clean-run bonus applied")
	profile.record_finish(1,1);check(profile.reputation==500,"Recovery shortfall applied")
	creator.queue_free();await process_frame
	profile.story_seen={"prologue":true}
	var hub: Control=load("res://ui/legacy/legacy_hub.tscn").instantiate();root.add_child(hub)
	for i in range(4): await process_frame
	check(hub.map.markers.size()==18 and not hub.start.disabled,"City map contains event markers and playable sprint")
	hub.select_event(9);check(hub.start.disabled,"Eastside requires downtown final")
	hub.select_event(1);check(hub.start.disabled,"Second story episode requires the first win")
	hub.select_event(0);hub.map.zoom=2;hub.map.pan=Vector2(20,30);hub.map.refresh();hub.map.reset_view()
	check(hub.map.zoom==1 and hub.map.pan==Vector2.ZERO,"Map reset restores pan and zoom")
	for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1080)]:
		root.size=resolution
		for i in range(3): await process_frame
		check(root.get_visible_rect().encloses(hub.map.get_global_rect()),"Career map fits viewport "+str(resolution))
	hub.queue_free();await process_frame
	profile.launch("garage")
	var began:=Time.get_ticks_msec()
	while not paused:
		check(Time.get_ticks_msec()-began<120000,"Career garage finishes loading")
		await process_frame
	var pause_menu: CanvasLayer=current_scene.car.get_node("PauseMenu")
	check(paused and pause_menu.get_node("Garage").visible,"Career garage opens")
	pause_menu.call("_close_garage")
	for i in range(8): await process_frame
	check(not paused and current_scene.name=="LegacyHub","Garage returns directly to career map")
	DirAccess.remove_absolute(profile.path)
	print("PASS: driver creation, 20 portraits, identity persistence, locked backgrounds, symmetric perks, actual rewards, career map and responsive layout")
	quit()
