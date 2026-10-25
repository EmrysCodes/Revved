extends Node
## Local career and launch intent; online modes will use this same profile later.
var path:="user://street_legacy.cfg"
var launch_mode:="free"
const CAMPAIGN=preload("res://core/career_catalog.gd")
var selected_event:="capital_run"
var event_results:Dictionary={}
var credits:=5000
var purchased_tiers:Array[int]=[0,0,0]
var career_finishes:=0
var career_wins:=0
var reputation:=0
var last_award:=""
var fullscreen:=false
var vsync:=true
var master_volume:=0.8
var ambience_volume:=0.7
var vehicle_volume:=0.7
var touch_mode:=0
var antialiasing:=2
const IDENTITY=preload("res://core/driver_identity.gd")
var driver_created:=false
var driver_name:="Alex Mercer"
var driver_presentation:=0
var driver_portrait:=0
var driver_background:=0
var return_to_legacy:=false
const STORY=preload("res://core/story_catalog.gd")
var story_seen:Dictionary={}
var story_request:Dictionary={}
var story_voice:=true
var story_auto:=true
var dialogue_volume:=0.9
var music_volume:=0.55
var story_save_error:=""
var story_setback_pending:=false
const SERIES=preload("res://core/challenge_series.gd")
var series_id:=-1
var series_round:=0
var series_results:Array[Dictionary]=[]
var series_report:=""
var series_active:=false
var last_backup_path:=""
func new_story()->Error:
	# The menu asks for confirmation. Preserve the old profile before replacing it.
	var backup:=path+"."+str(Time.get_unix_time_from_system()).replace(".","-")+".bak"
	if FileAccess.file_exists(path):
		var copied:=DirAccess.copy_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(backup))
		if copied!=OK:return copied
		last_backup_path=backup
	var defaults:Dictionary={"driver_created":false,"driver_name":"Alex Mercer","driver_presentation":0,"driver_portrait":0,"driver_background":0,"event_results":{},"credits":5000,"purchased_tiers":[0,0,0],"career_finishes":0,"career_wins":0,"reputation":0,"last_award":"","selected_event":"capital_run","story_seen":{},"story_setback_pending":false}
	var previous:Dictionary={}
	for key:String in defaults:
		var value:Variant=get(key)
		previous[key]=value.duplicate(true) if value is Array or value is Dictionary else value
		if key=="purchased_tiers":purchased_tiers.assign(defaults[key])
		else:set(key,defaults[key])
	var error:=save()
	if error!=OK:
		for key:String in previous:set(key,previous[key])
		return error
	story_request.clear();return_to_legacy=false;series_active=false;series_report=""
	return OK
func begin_series(index:int)->void:
	if index not in range(SERIES.SERIES.size()):return
	series_id=index;series_round=0;series_results.clear();series_report="";series_active=true
	launch_event(SERIES.SERIES[index].events[0],"series")
func record_series(place:int,seconds:float)->void:
	if launch_mode!="series" or series_id<0:return
	var result:Dictionary={"place":clampi(place,1,4),"seconds":seconds,"points":SERIES.points(place),"event":selected_event}
	if series_results.size()>series_round:series_results[series_round]=result
	else:series_results.append(result)
func series_score()->int:
	var score:=0
	for result in series_results:score+=int(result.points)
	return score
func series_summary()->String:
	if series_id<0:return ""
	var score:=series_score()
	return "%s / ROUND %d OF 3\n%d POINTS / GOLD 24 • SILVER 18 • BRONZE 12\nNO CAREER REWARDS"%[SERIES.SERIES[series_id].name,series_round+1,score]
func advance_series()->void:
	if series_id<0 or series_results.size()<=series_round:return
	if series_round<2:
		series_round+=1;launch_event(SERIES.SERIES[series_id].events[series_round],"series")
	else:
		series_active=false
		series_report=SERIES.SERIES[series_id].name+" / "+SERIES.medal(series_score())+" / %d POINTS"%series_score()
		get_tree().change_scene_to_file("res://ui/front_end/main_menu.tscn")
func resume_series()->void:
	if series_active and series_id>=0:launch_event(SERIES.SERIES[series_id].events[series_round],"series")
func _ready() -> void:
	var file:=ConfigFile.new()
	if file.load(path)==OK:
		selected_event=str(file.get_value("career","selected_event","capital_run"))
		credits=maxi(0,int(file.get_value("career","credits",5000)))
		var saved_results:Variant=file.get_value("career","events",{})
		if saved_results is Dictionary:
			for item in CAMPAIGN.EVENTS:
				var data:Variant=saved_results.get(item.id,{})
				if data is Dictionary:
					event_results[item.id]={"wins":maxi(0,int(data.get("wins",0))),"attempts":maxi(0,int(data.get("attempts",0))),"best":maxf(0,float(data.get("best",0))),"place":clampi(int(data.get("place",4)),1,4),"route_version":maxi(1,int(data.get("route_version",1)))}
		for i in range(3):purchased_tiers[i]=clampi(int(file.get_value("garage","owned_tier_%d"%i,[GameSettings.engine_level,GameSettings.brakes_level,GameSettings.tires_level][i])),0,3)
		career_finishes=maxi(0,int(file.get_value("career","finishes",0)))
		career_wins=maxi(0,int(file.get_value("career","wins",0)))
		reputation=maxi(0,int(file.get_value("career","reputation",0)))
		fullscreen=bool(file.get_value("display","fullscreen",false))
		vsync=bool(file.get_value("display","vsync",true))
		master_volume=clampf(float(file.get_value("audio","master",0.8)),0,1)
		ambience_volume=clampf(float(file.get_value("audio","ambience",0.7)),0,1)
		vehicle_volume=clampf(float(file.get_value("audio","vehicles",0.7)),0,1)
		touch_mode=clampi(int(file.get_value("input","touch_mode",0)),0,2)
		antialiasing=clampi(int(file.get_value("display","antialiasing",2)),0,3)
		driver_created=bool(file.get_value("driver","created",false))
		driver_name=str(file.get_value("driver","name","Alex Mercer")).strip_edges().left(24)
		driver_presentation=clampi(int(file.get_value("driver","presentation",0)),0,1)
		driver_portrait=clampi(int(file.get_value("driver","portrait",0)),0,9)
		driver_background=clampi(int(file.get_value("driver","background",0)),0,IDENTITY.BACKGROUNDS.size()-1)
		if driver_name.is_empty(): driver_created=false
		story_voice=bool(file.get_value("story","voice",true))
		story_setback_pending=bool(file.get_value("story","setback",false))
		story_auto=bool(file.get_value("story","auto",true))
		dialogue_volume=clampf(float(file.get_value("story","volume",0.9)),0,1)
		music_volume=clampf(float(file.get_value("audio","music",0.55)),0,1)
		var saved_seen:Variant=file.get_value("story","seen",{})
		if saved_seen is Dictionary:
			for key in STORY.data().scenes:
				if saved_seen.get(key,false):story_seen[key]=true
		# Existing wins are kept. Avoid replaying hours of old setup on a migrated save.
		if int(file.get_value("story","revision",0))<1 and CAMPAIGN.wins(event_results)>0:
			story_seen["prologue"]=true
			for item in CAMPAIGN.EVENTS:
				if CAMPAIGN.won(event_results,item.id):
					story_seen[item.id+"_before"]=true;story_seen[item.id+"_after"]=true
	apply_display()
func save() -> Error:
	var file:=ConfigFile.new()
	file.set_value("career","selected_event",selected_event)
	file.set_value("career","events",event_results)
	file.set_value("career","credits",credits)
	for i in range(3):file.set_value("garage","owned_tier_%d"%i,purchased_tiers[i])
	file.set_value("career","finishes",career_finishes)
	file.set_value("career","wins",career_wins)
	file.set_value("career","reputation",reputation)
	file.set_value("display","fullscreen",fullscreen)
	file.set_value("display","vsync",vsync)
	file.set_value("display","antialiasing",antialiasing)
	file.set_value("audio","master",master_volume)
	file.set_value("audio","ambience",ambience_volume)
	file.set_value("audio","vehicles",vehicle_volume)
	file.set_value("input","touch_mode",touch_mode)
	file.set_value("driver","created",driver_created)
	file.set_value("driver","name",driver_name)
	file.set_value("driver","presentation",driver_presentation)
	file.set_value("driver","portrait",driver_portrait)
	file.set_value("driver","background",driver_background)
	file.set_value("story","revision",1)
	file.set_value("story","setback",story_setback_pending)
	file.set_value("story","seen",story_seen)
	file.set_value("story","voice",story_voice)
	file.set_value("story","auto",story_auto)
	file.set_value("story","volume",dialogue_volume)
	file.set_value("audio","music",music_volume)
	return file.save(path)
func create_driver(value: String,presentation: int,portrait: int,background: int) -> Error:
	if driver_created: return ERR_ALREADY_EXISTS
	value=value.strip_edges()
	if value.is_empty() or value.length()>24 or presentation not in [0,1] or portrait not in range(10) or background not in range(IDENTITY.BACKGROUNDS.size()): return ERR_INVALID_PARAMETER
	var previous: Array=[driver_created,driver_name,driver_presentation,driver_portrait,driver_background]
	driver_created=true;driver_name=value;driver_presentation=presentation;driver_portrait=portrait;driver_background=background
	var error:=save()
	if error!=OK:
		driver_created=previous[0];driver_name=previous[1];driver_presentation=previous[2];driver_portrait=previous[3];driver_background=previous[4]
	return error
func apply_display() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	get_viewport().msaa_3d=(mini(antialiasing,1) if OS.has_feature("mobile") else antialiasing) as Viewport.MSAA
	get_viewport().scaling_3d_scale=0.75 if OS.has_feature("mobile") else 1.0
	get_viewport().use_taa=antialiasing>0 and RenderingServer.get_current_rendering_method()=="forward_plus" and not OS.has_feature("mobile")
	apply_audio()
func apply_audio() -> void:
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(master_volume,0.0001)))
	AudioServer.set_bus_mute(0,master_volume<=0)
	var vehicle_bus:=AudioServer.get_bus_index("Vehicles")
	if vehicle_bus>=0:
		AudioServer.set_bus_volume_db(vehicle_bus,linear_to_db(maxf(vehicle_volume,0.0001)))
		AudioServer.set_bus_mute(vehicle_bus,vehicle_volume<=0)
	var ambience_bus:=AudioServer.get_bus_index("Ambience")
	if ambience_bus>=0:
		AudioServer.set_bus_volume_db(ambience_bus,linear_to_db(maxf(ambience_volume,0.0001)))
		AudioServer.set_bus_mute(ambience_bus,ambience_volume<=0)
func record_finish(place: int,recoveries:=0,event_id:="",seconds:=0.0,successful:=true,route_version:=1) -> void:
	if launch_mode!="career": return
	if not event_id.is_empty() and not CAMPAIGN.unlock_reason(event_id,event_results).is_empty():return
	career_finishes+=1
	if place==1 and successful: career_wins+=1
	var base: int=[250,150,100,50][clampi(place-1,0,3)]
	var earned:=roundi(base*IDENTITY.multiplier(driver_background,place,recoveries))
	reputation+=earned
	last_award="+%d reputation • Street Legacy"%earned
	if not event_id.is_empty():
		var item:Dictionary=CAMPAIGN.event(event_id)
		var result:Dictionary=event_results.get(event_id,{"wins":0,"attempts":0,"best":0.0,"place":4})
		var first_win:bool=int(result.wins)==0 and place==1 and successful
		story_setback_pending=not (place==1 and successful)
		if int(result.get("route_version",1))!=route_version:result.best=0.0
		result.route_version=route_version
		result.attempts=int(result.attempts)+1
		if place==1 and successful:result.wins=int(result.wins)+1
		result.place=mini(int(result.place),place)
		if seconds>0 and (float(result.best)<=0 or seconds<float(result.best)):result.best=seconds
		event_results[event_id]=result
		var payout:int=roundi(float(item.cash)*(1.0 if first_win else (.35 if successful and place==1 else .12)))
		credits+=payout
		last_award+="\n+%s CR%s"%[str(payout)," / FIRST WIN" if first_win else ""]
		if first_win and event_id=="capitol_crown":last_award+="\nVALCOUR / CHAMPLAIN COAST UNLOCKED"
		if first_win and event_id=="eastside_crown" and CAMPAIGN.complete(event_results):last_award+="\nLAST LIGHT / STREET LEGACY COMPLETE"
		elif first_win:
			var next_id:=CAMPAIGN.next_event(event_results)
			if not next_id.is_empty():last_award+="\nNEXT / "+CAMPAIGN.event(next_id).name.to_upper()
	if driver_background!=0: last_award+="\n"+IDENTITY.BACKGROUNDS[driver_background].name
	if save()!=OK: last_award+=" • save failed; session only"
func select_event(id:String) -> bool:
	var item:Dictionary=CAMPAIGN.event(id)
	if item.id!=id:return false
	selected_event=id;return true
func upgrade_price(slot:int,tier:int) -> int:
	if tier<=purchased_tiers[slot]:return 0
	return [[0,1200,4000,10000],[0,700,2200,6500],[0,900,2800,8000]][slot][tier]
func buy_upgrade(slot:int,tier:int) -> Error:
	if slot not in range(3) or tier not in range(4):return ERR_INVALID_PARAMETER
	var price:=upgrade_price(slot,tier)
	if credits<price:return ERR_UNAVAILABLE
	var old_credits:=credits;var old_tier:=purchased_tiers[slot]
	credits-=price;purchased_tiers[slot]=maxi(purchased_tiers[slot],tier)
	var error:=save()
	if error!=OK:credits=old_credits;purchased_tiers[slot]=old_tier
	return error
func launch_event(id:String,mode:="career") -> void:
	if not select_event(id):return
	if mode=="career" and not CAMPAIGN.unlock_reason(id,event_results).is_empty():return
	launch(mode)
func launch(mode: String) -> void:
	if mode=="career":
		if not CAMPAIGN.unlock_reason(selected_event,event_results).is_empty():return
		var prelude:=selected_event+"_before"
		if not story_seen.get(prelude,false):
			play_story(prelude,"race");return
	launch_mode=mode;last_award=""
	get_tree().paused=false
	if mode in ["career","legacy_roam","garage"] and driver_created:
		GameSettings.set_performance(mini(GameSettings.engine_level,purchased_tiers[0]),mini(GameSettings.brakes_level,purchased_tiers[1]),mini(GameSettings.tires_level,purchased_tiers[2]),false)
	save()
	get_tree().change_scene_to_file("res://ui/front_end/loading_screen.tscn")
func pending_story()->String:
	if not driver_created:return ""
	if not story_seen.get("prologue",false):return "prologue"
	for item in CAMPAIGN.EVENTS:
		if CAMPAIGN.won(event_results,item.id) and not story_seen.get(item.id+"_after",false):return item.id+"_after"
	if CAMPAIGN.complete(event_results) and not story_seen.get("epilogue",false):return "epilogue"
	if story_setback_pending:return "setback"
	return ""
func play_story(key:String,destination:="hub",replay:=false)->void:
	if STORY.scene(key).is_empty():return
	if replay and not story_seen.get(key,false):return
	story_request={"key":key,"destination":destination,"replay":replay}
	get_tree().paused=false
	get_tree().change_scene_to_file("res://ui/story/story_scene.tscn")
func finish_story()->bool:
	if story_request.is_empty():return false
	var key:String=story_request.key
	if not story_request.get("replay",false):
		var old:Dictionary=story_seen.duplicate();var old_setback:=story_setback_pending;story_seen[key]=true
		if key=="setback":story_setback_pending=false
		var error:=save()
		if error!=OK:
			story_seen=old;story_setback_pending=old_setback;story_save_error="Could not save the story. Check available storage and retry.";return false
	var destination:String=story_request.get("destination","hub")
	story_request.clear();story_save_error=""
	if destination=="race":launch("career")
	else:get_tree().change_scene_to_file("res://ui/legacy/legacy_hub.tscn")
	return true
func main_menu() -> void:
	return_to_legacy=launch_mode in ["career","legacy_roam","garage"] and driver_created
	get_tree().paused=false
	get_tree().change_scene_to_file("res://ui/front_end/main_menu.tscn")
