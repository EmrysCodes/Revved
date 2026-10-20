extends SceneTree
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: push_error(message);quit(1);assert(ok,message)
func run() -> void:
	var profile:=root.get_node("StreetProfile")
	profile.driver_background=0;profile.driver_created=false
	profile.path="res://tests/legacy-test.tmp";profile.launch_mode="career"
	profile.career_finishes=0;profile.career_wins=0;profile.reputation=0
	profile.record_finish(2)
	check(profile.reputation==150 and profile.career_finishes==1 and profile.career_wins==0,"Career finish awards reputation")
	var saved:=ConfigFile.new();check(saved.load(profile.path)==OK,"Career saves")
	check(saved.get_value("career","reputation")==150,"Career reputation persists")
	profile.launch_mode="single";profile.record_finish(1)
	check(profile.reputation==150,"Practice cannot award career reputation")
	profile.launch_mode="free"
	var menu: Control=load("res://ui/front_end/main_menu.tscn").instantiate();root.add_child(menu)
	for page in ["home","single_race","online","settings","credits"]:
		menu.call(page)
		for i in range(3): await process_frame
		check(menu.content.get_child_count()>2,"Menu page populated: "+page)
		for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1080)]:
			root.size=resolution
			await process_frame
			check(menu.scroll.size.y>30 and menu.scroll.size.x>200,"Scrollable responsive menu: "+page)
	menu.settings()
	var old_volume: float=profile.master_volume
	for item in menu.content.get_children():
		if item is HSlider: item.value=45
	check(is_equal_approx(profile.master_volume,0.45),"Master volume control applies")
	check(saved.load(profile.path)==OK and is_equal_approx(saved.get_value("audio","master"),0.45),"Audio setting persists")
	check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(0)),0.45),"Audio bus follows master volume")
	profile.master_volume=old_volume;profile.apply_display()
	menu.queue_free();await process_frame
	var city: Node3D=load("res://scenes/hartford_district.tscn").instantiate();root.add_child(city)
	for i in range(12): await physics_frame
	var life:=city.get_node("CityLife")
	var counts: Dictionary=life.get_meta("counts")
	check(counts.get("trunk",0)>300 and counts.get("seat",0)>100 and counts.get("pole",0)>100,"Substantial city street dressing")
	if ResourceLoader.exists("res://assets/licensed/modern_city_architecture/tree_ash_near.res"):
		check(counts.get("tree_ash_near",0)+counts.get("tree_linden_near",0)==counts.get("trunk",0),"Every planting uses a detailed tree")
		check(counts.get("tree_ash_far",0)+counts.get("tree_linden_far",0)==counts.get("trunk",0),"Every detailed tree has a distant proxy")
	check(life.find_children("*","CollisionObject3D",true,false).is_empty(),"Soft street props preserve driving corridors")
	check(city.get_node("CityTraffic/TrafficAudio").slots.size()<=4,"Nearby traffic engine playback stays bounded")
	var garage: Control=city.car.get_node("PauseMenu/Garage")
	check(garage.get_node("Frame/Stack/Content/Preview/Viewport/Stage/WorkshopDetails").find_children("*","CollisionObject3D",true,false).is_empty(),"Workshop dressing does not add collision")
	check(city.car.get_node("PauseMenu/Overlay/Center/Card/Padding/Stack/MainMenu")!=null,"Pause menu returns to front end")
	DirAccess.remove_absolute(profile.path)
	print("PASS: main menu pages/resolutions, career persistence, practice separation, city vegetation/furniture, main menu return")
	quit()
