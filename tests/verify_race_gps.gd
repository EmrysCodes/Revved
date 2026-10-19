extends SceneTree
const GUIDANCE=preload("res://racing/route_guidance.gd")
var failed:=false
func check(value:bool,message:String) -> void:
	if not value:failed=true;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var line:=PackedVector3Array();var distances:=PackedFloat64Array([0.0])
	for i in range(41):line.append(Vector3(0,0,-i*5))
	for i in range(1,41):line.append(Vector3(i*5,0,-200))
	for i in range(1,line.size()):distances.append(distances[-1]+line[i-1].distance_to(line[i]))
	var turns:=GUIDANCE.maneuvers(line,distances,line.size()-1)
	check(turns.size()==2 and turns[0].kind=="right","GPS recognizes a right turn before the finish")
	var early:Dictionary=GUIDANCE.next_turn(turns,40)
	var later:Dictionary=GUIDANCE.next_turn(turns,90)
	check(is_equal_approx(early.distance-later.distance,50),"Turn countdown follows along-road progress")
	check(GUIDANCE.next_turn(turns,turns[0].start+1).in_turn,"Turn instruction remains through the corner")
	check(GUIDANCE.next_turn(turns,turns[0].end+1).kind=="finish","Passed turn advances to finish")
	root.get_node("StreetProfile").touch_mode=1
	var city:Node3D=load("res://scenes/hartford_district.tscn").instantiate();city.set_meta("disable_population",true);root.add_child(city)
	for i in range(14):await physics_frame
	city.car.set_physics_process(false)
	var event:Node=city.get_node("CityRace");event.start_race();event.set_physics_process(false)
	for rival in event.opponents:rival.set_physics_process(false)
	for resolution in [Vector2i(640,360),Vector2i(1080,600),Vector2i(1280,720),Vector2i(2560,1080)]:
		root.content_scale_size=resolution;root.size=resolution
		for i in range(8):await process_frame
		var gps:Control=event.hud.gps
		print("LAYOUT ",resolution," GPS ",gps.get_global_rect()," CARD ",event.hud.card.get_global_rect())
		check(root.get_visible_rect().encloses(gps.get_global_rect()),"GPS fits actual logical viewport: "+str(resolution))
		check(not gps.get_global_rect().intersects(event.hud.card.get_global_rect()),"GPS clear of race information: "+str(resolution))
		var controls:Control=city.car.get_node("HUD/Screen/TouchControls")
		for key in ["left","right","gas","brake","ebrake","pause","reset"]:
			check(not gps.get_global_rect().intersects(controls.buttons[key]),"GPS clear of touch target: "+key+str(resolution))
	print("RACE GPS ","FAIL" if failed else "PASS",": turn semantics, along-road distance and logical viewport/touch layouts")
	quit(1 if failed else 0)
