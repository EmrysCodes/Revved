extends SceneTree
const C=preload("res://core/career_catalog.gd")
var failed:=false
func check(value:bool,message:String) -> void:
	if not value:failed=true;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var profile=root.get_node("StreetProfile")
	profile.path="res://tests/campaign-test.tmp";profile.event_results={};profile.credits=5000;profile.purchased_tiers.assign([0,0,0])
	profile.launch_mode="single";profile.record_finish(1,0,"capital_run",70)
	check(profile.event_results.is_empty() and profile.credits==5000,"Practice has no campaign rewards")
	check(not C.unlock_reason("founders_entry",{}).is_empty(),"Eastside initially locked")
	profile.launch_mode="career";profile.record_finish(1,0,"capital_run",72)
	check(profile.credits==6100 and profile.event_results.capital_run.wins==1,"First win pays full reward")
	profile.record_finish(1,0,"capital_run",68)
	check(profile.credits==6485 and profile.event_results.capital_run.best==68,"Repeat reward and personal best")
	profile.record_finish(1,0,"capital_run",80,true,3)
	check(profile.event_results.capital_run.best==80 and profile.event_results.capital_run.wins==3 and profile.credits==6870,"New course revision resets only its time, preserving wins and repeat-reward status")
	check(not C.unlock_reason("asylum_circuit",profile.event_results).is_empty(),"Repeated wins do not unlock unique-event tiers")
	profile.record_finish(1,0,"pearl_dash",90)
	check(C.unlock_reason("asylum_circuit",profile.event_results).is_empty(),"Two different wins unlock next tier")
	check(profile.buy_upgrade(0,1)==OK and profile.purchased_tiers[0]==1,"Purchase saved upgrade")
	var balance:int=profile.credits
	check(profile.buy_upgrade(0,1)==OK and profile.credits==balance,"Owned upgrade is free")
	check(profile.buy_upgrade(0,3)==ERR_UNAVAILABLE and profile.credits==balance,"Unaffordable purchase preserves balance")
	profile.path="res://missing-directory/campaign-test.tmp"
	check(profile.buy_upgrade(1,1)!=OK and profile.credits==balance and profile.purchased_tiers[1]==0,"Failed save rolls back purchase")
	profile.path="res://tests/campaign-test.tmp"
	for item:Dictionary in C.EVENTS:
		check(FileAccess.file_exists(C.route_path(item.id)),"Route exists: "+item.id)
		var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(C.route_path(item.id)))
		check(data.points.size()==data.distances.size() and data.points.size()>100,"Route sample structure: "+item.id)
		check(data.checkpoints[-1]==data.finish_index,"Finish checkpoint: "+item.id)
		var previous:=-1
		for index in data.checkpoints:check(index>previous,"Ordered checkpoints: "+item.id);previous=int(index)
		var gap:=0.0
		for i in range(1,data.distances.size()):gap=maxf(gap,float(data.distances[i])-float(data.distances[i-1]))
		check(gap<12,"Continuous route: "+item.id)
		if item.rivals==0:check(data.target_seconds>30,"Timed challenge target")
		if C.unlock_reason(item.id,profile.event_results).is_empty():profile.record_finish(1,0,item.id,100)
		else:check(false,"Campaign event reachable in order: "+item.id)
	check(C.complete(profile.event_results),"Both district finals reachable")
	var config:=ConfigFile.new();check(config.load(profile.path)==OK,"Campaign save readable")
	check(config.get_value("career","events",{}).size()==18,"All event results persisted")
	DirAccess.remove_absolute(profile.path)
	print("CAMPAIGN ","FAIL" if failed else "PASS",": progression, practice isolation, rewards, purchases, rollback, 18 route structures and saves")
	quit(1 if failed else 0)
