extends SceneTree
var failed:=false
func _initialize() -> void:call_deferred("run")
func check(value:bool,message:String)->void:
	if not value:failed=true;push_error(message)
func run() -> void:
	var profile=root.get_node("StreetProfile");var saved:=[profile.launch_mode,profile.driver_created,profile.last_award]
	profile.launch_mode="career";profile.driver_created=true;profile.last_award="+250 reputation\n+1250 CR / FIRST WIN\nEASTSIDE / FOUNDERS UNLOCKED"
	var hud=load("res://racing/race_hud.tscn").instantiate();root.add_child(hud)
	var rows:=[{"name":"A long player name in Street Legacy","time":"02:14.83","player":true},{"name":"Mara","time":"02:17.21","player":false},{"name":"Jax","time":"02:19.05","player":false},{"name":"Quinn","time":"240 ft left","player":false}]
	for resolution:Vector2i in [Vector2i(1600,900),Vector2i(1280,720),Vector2i(640,360),Vector2i(393,852)]:
		root.size=resolution;root.content_scale_size=resolution
		hud.event_title="CAPITAL RUN";hud.new_personal_best=true;hud.show_results(1,"02:14.83","02:14.83",rows,true)
		for i in range(6):await process_frame
		check(root.get_visible_rect().encloses(hud.results_card.get_global_rect()),"Results fit "+str(resolution))
		for button:Button in [hud.retry,hud.roam]:
			check(root.get_visible_rect().encloses(button.get_global_rect()),"Actions remain visible "+str(resolution))
		check(hud.retry.size.y>=48 and hud.roam.size.y>=48,"Unscaled touch targets "+str(resolution))
		check(hud.standings.get_child_count()==4,"Complete classification")
		check(hud.result_position.get_line_count()==1,"Placement stays on one line")
		check(hud.result_best.text.begins_with("NEW PERSONAL BEST"),"Record banner reflects actual flag")
		check(hud.roam.text in ["CONTINUE STORY","STORY MAP"],"Career return action")
	profile.launch_mode="single";hud.target_time=180;hud.result_message="TARGET MISSED / TRY AGAIN";hud.show_results(4,"03:15.12","02:14.83",rows,false)
	check(hud.result_position.text=="RETRY","Time target failure distinguished from a placement")
	check(not hud.result_award.text.contains("1250"),"Practice does not expose stale career rewards")
	var presses:=[0,0];hud.retry_pressed.connect(func():presses[0]+=1);hud.roam_pressed.connect(func():presses[1]+=1)
	hud.retry.pressed.emit();hud.roam.pressed.emit();check(presses==[1,1],"Both result actions emit exactly once")
	profile.launch_mode=saved[0];profile.driver_created=saved[1];profile.last_award=saved[2]
	hud.queue_free();await process_frame;print("RESULTS POLISH ","FAIL" if failed else "PASS");quit(1 if failed else 0)
