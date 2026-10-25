extends SceneTree
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: push_error(message);quit(1);assert(ok,message)
func wait_for_city() -> void:
	await process_frame; await process_frame
	var start := Time.get_ticks_msec()
	while current_scene==null or current_scene.name=="LoadingCity":
		check(Time.get_ticks_msec()-start<60000,"City loading completes")
		await process_frame
	for i in range(14): await physics_frame
func run() -> void:
	var profile:=root.get_node("StreetProfile")
	profile.driver_background=0;profile.driver_created=false;profile.path="res://tests/mode-career.tmp"
	profile.story_seen["capital_run_before"]=true
	profile.launch("single")
	await wait_for_city()
	check(current_scene.get_node("CityRace").is_active(),"Single race launches directly to grid")
	profile.main_menu()
	for i in range(4): await process_frame
	check(current_scene.name=="MainMenu" and not paused,"Main menu scene restores")
	profile.launch("garage")
	await wait_for_city()
	var menu: CanvasLayer=current_scene.car.get_node("PauseMenu")
	check(paused and menu.get_node("Garage").visible,"Garage mode opens garage and pauses world")
	menu.close_menu();profile.main_menu()
	for i in range(4): await process_frame
	profile.launch("career")
	await wait_for_city()
	check(current_scene.get_node("CityRace").is_active(),"Career launches playable first chapter")
	profile.path="res://tests/mode-career.tmp";profile.reputation=0;profile.career_finishes=0
	var event: Node=current_scene.get_node("CityRace")
	event.best_path="res://tests/mode-best.tmp"
	event.finish_times[current_scene.car.get_instance_id()]=180.0
	event.call("_finish_player")
	check(profile.reputation==250 and profile.career_finishes==1,"Real race results award career progress")
	DirAccess.remove_absolute(profile.path);DirAccess.remove_absolute(event.best_path)
	var pause_menu: CanvasLayer=current_scene.car.get_node("PauseMenu")
	pause_menu.open_menu()
	pause_menu.get_node("Overlay/Center/Card/Padding/Stack/MainMenu").pressed.emit()
	for i in range(4): await process_frame
	check(current_scene.name=="MainMenu" and not paused,"Pause button returns to main menu")
	print("PASS: Single Race, Garage and Career scene transitions; pause Main Menu return")
	quit()
