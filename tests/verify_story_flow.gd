extends SceneTree
var failed:=false
func _initialize()->void:call_deferred("run")
func check(value:bool,message:String)->void:
	if not value:failed=true;push_error(message)
func frames(count:int)->void:
	for i in range(count):await process_frame
func wait_scene(expected:String)->void:
	var began:=Time.get_ticks_msec()
	await frames(3)
	while current_scene==null or current_scene.name!=expected:
		if Time.get_ticks_msec()-began>120000:push_error("Timed out waiting for "+expected);quit(1);return
		await process_frame
	await frames(8)
func wait_race()->Node:
	await wait_scene("PlattsburghRegion")
	var began:=Time.get_ticks_msec()
	while current_scene.get_node_or_null("CityRace")==null:
		if Time.get_ticks_msec()-began>120000:push_error("Race did not appear");quit(1);return null
		await process_frame
	await frames(10)
	return current_scene.get_node("CityRace")
func run()->void:
	var p:=root.get_node("StreetProfile");p.path="res://tests/story-flow.tmp";p.driver_created=true;p.driver_name="Flow Tester";p.driver_background=0;p.event_results={};p.story_seen={};p.story_setback_pending=false;p.story_auto=false;p.story_voice=false;p.music_volume=0;p.credits=5000;p.reputation=0
	change_scene_to_file("res://ui/legacy/legacy_hub.tscn")
	await wait_scene("StoryScene");check(p.story_request.key=="prologue","Career begins with prologue")
	current_scene.complete_scene();await wait_scene("LegacyHub")
	print("FLOW prologue and map ready")
	check(p.story_seen.prologue and not current_scene.continue_button.disabled,"Skipped prologue saves and returns to map")
	current_scene.continue_story();await wait_scene("StoryScene")
	check(p.story_request.key=="capital_run_before","Continue selects the first story setup")
	current_scene.complete_scene()
	# Native scene uses this root name; query readiness rather than relying on a guessed name.
	var began:=Time.get_ticks_msec()
	while current_scene==null or current_scene.get_node_or_null("CityRace")==null:
		if Time.get_ticks_msec()-began>120000:push_error("Career loading timed out");quit(1);return
		await process_frame
	await frames(12)
	var race:Node=current_scene.get_node("CityRace")
	check(race.is_active() and p.launch_mode=="career","Setup leads to an active career race")
	print("FLOW native career race ready")
	race.best_path="res://tests/story-flow-races.tmp";race.finish_times[current_scene.car.get_instance_id()]=100.0;race._finish_player()
	check(p.event_results.capital_run.wins==1 and race.hud.roam.text=="CONTINUE STORY","Actual race result queues resolution")
	race.hud.roam.pressed.emit();await wait_scene("StoryScene")
	check(p.story_request.key=="capital_run_after","Result Continue opens first-win dialogue")
	current_scene.complete_scene();await wait_scene("LegacyHub")
	check(p.selected_event=="pearl_dash","Story map selects exactly the next episode")
	print("FLOW result dialogue and next episode ready")
	var credits:int=p.credits;var reputation:int=p.reputation
	p.begin_series(0)
	for round_index in range(3):
		began=Time.get_ticks_msec()
		while current_scene==null or current_scene.get_node_or_null("CityRace")==null:
			if Time.get_ticks_msec()-began>120000:push_error("Series loading timed out");quit(1);return
			await process_frame
		await frames(12);race=current_scene.get_node("CityRace")
		print("FLOW series round ",round_index+1," ready")
		check(p.launch_mode=="series" and race.is_active(),"Series round auto-starts")
		race.best_path="res://tests/story-flow-races.tmp";race.finish_times[current_scene.car.get_instance_id()]=100.0;race._finish_player()
		check(p.series_results.size()==round_index+1,"Exactly one scored result per round")
		if round_index==0:
			race.hud.retry.pressed.emit();await frames(5)
			race.finish_times[current_scene.car.get_instance_id()]=100.0;race.finish_times[race.opponents[0].get_instance_id()]=90.0;race._finish_player()
			check(p.series_results.size()==1 and p.series_score()==6,"A retried round replaces its score")
		race.hud.roam.pressed.emit();await frames(5)
	await wait_scene("MainMenu")
	check(p.series_score()==26 and p.credits==credits and p.reputation==reputation,"Gold series completion preserves career state")
	DirAccess.remove_absolute(p.path);DirAccess.remove_absolute("res://tests/story-flow-races.tmp")
	print("STORY FLOW ","FAIL" if failed else "PASS",": prologue, setup, native race, result dialogue, next episode, three real series transitions and replay scoring")
	quit(1 if failed else 0)
