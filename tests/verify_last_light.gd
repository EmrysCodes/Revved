extends SceneTree
const C=preload("res://core/career_catalog.gd")
const S=preload("res://core/story_catalog.gd")
var failed:=false
func _initialize()->void:call_deferred("run")
func check(value:bool,message:String)->void:
	if not value:failed=true;push_error(message)
func frames(count:int)->void:
	for i in range(count):await process_frame
func run()->void:
	var profile:=root.get_node("StreetProfile")
	profile.path="res://tests/last-light.tmp";profile.driver_created=true;profile.driver_name="River Test";profile.event_results={};profile.story_seen={};profile.story_voice=false;profile.story_auto=false;profile.story_setback_pending=false;profile.launch_mode="career";profile.credits=5000
	check(S.data().scenes.size()==39,"Complete prologue, 36 race scenes, epilogue, and setback")
	var line_total:=0
	for key:String in S.data().scenes:
		for line:Dictionary in S.scene(key).lines:
			line_total+=1;check(not S.cast(line.speaker).is_empty(),"Known cast member")
			check(ResourceLoader.exists(line.audio),"Voiced line present: "+line.audio)
			if ResourceLoader.exists(line.audio):check(load(line.audio).get_length()>1,"Actual recorded duration")
	check(line_total==104,"All 104 authored lines voiced")
	check(profile.pending_story()=="prologue","New driver receives prologue")
	profile.record_finish(1,0,"eastside_crown",100,true,101)
	check(profile.event_results.is_empty() and profile.credits==5000,"Direct attempts to award locked future episodes are rejected")
	profile.story_seen.prologue=true
	for i in range(C.EVENTS.size()):
		var event:Dictionary=C.EVENTS[i]
		check(C.next_event(profile.event_results)==event.id,"Single next episode in order")
		for later in range(i+1,C.EVENTS.size()):check(not C.unlock_reason(C.EVENTS[later].id,profile.event_results).is_empty(),"Future episode locked")
		var before_balance:int=profile.credits
		profile.record_finish(4,0,event.id,200,false,101)
		check(C.next_event(profile.event_results)==event.id,"Loss never advances story")
		check(profile.pending_story()=="setback","Setback dialogue queued")
		profile.story_setback_pending=false
		profile.record_finish(1,0,event.id,100,true,101)
		check(C.won(profile.event_results,event.id) and profile.credits>before_balance,"First victory and reward")
		check(profile.pending_story()==event.id+"_after","First-win resolution queued")
		profile.story_seen[event.id+"_before"]=true;profile.story_seen[event.id+"_after"]=true
	check(C.complete(profile.event_results) and profile.pending_story()=="epilogue","Ending requires every episode")
	var credits:int=profile.credits;var reputation:int=profile.reputation
	profile.launch_mode="single";profile.record_finish(1,0,"capital_run",50)
	check(profile.credits==credits and profile.reputation==reputation,"Practice cannot award story progress")
	profile.launch_mode="career"
	profile.story_request={"key":"epilogue","destination":"hub","replay":false}
	profile.path="res://missing-story-directory/save.cfg"
	check(not profile.finish_story() and not profile.story_seen.get("epilogue",false),"Failed story save rolls back seen state and preserves scene")
	profile.path="res://tests/last-light.tmp";profile.story_seen.epilogue=true;check(profile.save()==OK,"Story preferences and seen scenes persist")
	var reloaded:Node=load("res://core/street_profile.gd").new();reloaded.path=profile.path;root.add_child(reloaded)
	check(reloaded.story_seen.get("epilogue",false) and C.complete(reloaded.event_results),"Complete story reloads")
	reloaded.queue_free()
	var old_save:=ConfigFile.new();old_save.set_value("driver","created",true);old_save.set_value("driver","name","Returning Driver");old_save.set_value("career","events",{"capital_run":{"wins":2},"eastside_crown":{"wins":1}});old_save.set_value("career","credits",17000);old_save.save("res://tests/old-story.tmp")
	var migrated:Node=load("res://core/street_profile.gd").new();migrated.path="res://tests/old-story.tmp";root.add_child(migrated)
	check(migrated.credits==17000 and migrated.event_results.capital_run.wins==2 and migrated.event_results.eastside_crown.wins==1,"Migration preserves old credits and noncontiguous wins")
	check(C.next_event(migrated.event_results)=="pearl_dash" and migrated.pending_story().is_empty(),"Migration resumes first missing episode without an old scene backlog")
	migrated.queue_free();DirAccess.remove_absolute("res://tests/old-story.tmp")
	# Exercise all subtitle/voice/camera fixtures and skip/reveal behavior without loading city.
	profile.story_request={"key":"capital_run_before","destination":"hub","replay":true}
	var cinema:Control=load("res://ui/story/story_scene.tscn").instantiate();root.add_child(cinema);await frames(6)
	for i in range(cinema.screenplay.lines.size()):cinema.show_line(i);cinema.advance();check(cinema.subtitle.visible_characters==-1,"First Next reveals full subtitle")
	cinema.show_line(0);cinema.advance();cinema.advance();check(cinema.line_index==1,"Second Next advances exactly one line")
	check(cinema.transcript.get_parsed_text().contains("River Test"),"Player name appears in dialogue transcript")
	cinema.toggle_pause();check(cinema.held,"Cinematic can pause")
	cinema.toggle_pause();cinema.toggle_transcript();check(cinema.held and cinema.transcript.visible,"Transcript pauses autoplay")
	for resolution in [Vector2i(1280,720),Vector2i(640,360),Vector2i(393,852)]:
		root.size=resolution;root.content_scale_size=resolution;await frames(5);cinema.layout_content();await frames(5)
		check(root.get_visible_rect().encloses(cinema.next_button.get_global_rect()),"Next remains visible: "+str(resolution))
		check(root.get_visible_rect().encloses(cinema.subtitle.get_global_rect()),"Subtitles remain visible: "+str(resolution))
		check(root.get_visible_rect().encloses(cinema.dialogue.get_global_rect()),"Entire dialogue panel remains visible: "+str(resolution))
		if resolution.x<800:check(cinema.compact_menu.visible and root.get_visible_rect().encloses(cinema.compact_menu.get_global_rect()),"All secondary actions accessible through compact menu")
	cinema.queue_free();await process_frame
	profile.launch_mode="series";profile.series_id=0;profile.series_round=0;profile.series_results.clear()
	for i in range(3):
		profile.series_round=i;profile.record_series([1,2,1][i],100+i)
	check(profile.series_score()==26 and profile.SERIES.medal(26)=="GOLD","Three-round scoring and medals")
	profile.record_series(4,130);check(profile.series_score()==17,"Retry replaces round score rather than duplicating it")
	check(profile.credits==credits and profile.reputation==reputation,"Series isolated from career rewards")
	profile.launch_mode="career";profile.save()
	check(profile.new_story()==OK and profile.credits==5000 and not profile.driver_created and profile.event_results.is_empty(),"New story resets career through the explicit menu action")
	var backup:=ConfigFile.new();check(backup.load(profile.last_backup_path)==OK and int(backup.get_value("career","credits",0))==credits,"New story preserves previous career in a readable backup")
	DirAccess.remove_absolute(profile.last_backup_path)
	DirAccess.remove_absolute(profile.path)
	print("LAST LIGHT ","FAIL" if failed else "PASS",": 18 episodes, 39 scenes, 104 clips, persistence, isolation, dialogue controls, layouts and series")
	quit(1 if failed else 0)
