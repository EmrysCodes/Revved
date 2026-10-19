extends SceneTree
var failed:=false
func check(value:bool,message:String) -> void:
	if not value:failed=true;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	root.get_node("StreetProfile").launch_mode="free"
	var city:Node3D=load("res://scenes/hartford_district.tscn").instantiate();root.add_child(city)
	for i in range(16):await physics_frame
	city.car.set_physics_process(false)
	var fleet:Node3D=city.get_node("CityTraffic")
	var people:Node3D=city.get_node("CityPedestrians")
	check(fleet.agents.size()>=50,"Substantial two-way traffic population")
	var west:=0;var east:=0
	for walker:Dictionary in people.walkers:
		if walker.line[0].x>900:east+=1
		else:west+=1
		check(walker.animation.has_animation("Walk"),"Imported pedestrian has walk animation")
	check(west>=40 and east>=40,"Pedestrians distributed across both districts")
	fleet.set_process(false);fleet.clock=4
	var junction:Vector3=fleet.intersections[0]
	check(not fleet.should_stop(junction+Vector3(0,0,20),Vector3.FORWARD),"North-south signal initially green")
	check(fleet.should_stop(junction+Vector3(20,0,0),Vector3.LEFT),"Crossing direction initially red")
	fleet.clock=25
	check(fleet.should_stop(junction+Vector3(0,0,20),Vector3.FORWARD),"North-south red after signal change")
	check(not fleet.should_stop(junction+Vector3(20,0,0),Vector3.LEFT),"Crossing direction then green")
	check(city.get_node("EastsideFrontage").get_meta("infill_buildings")>=70,"Additional district frontage loaded")
	check(city.get_node("EastsideFrontage").get_meta("parking_courts")>=10,"Marked parking courts loaded")
	var car:CharacterBody3D=fleet.agents[0]
	city.car.global_position=car.global_position+Vector3(0,0,100)
	var before:Vector3=car.global_position
	for i in range(180):await physics_frame
	check(car.global_position.distance_to(before)>1,"Traffic physically advances on its lane")
	print("CITY POPULATION ","FAIL" if failed else "PASS",": ",fleet.agents.size()," vehicles / ",west," west and ",east," east walkers / signals / frontage")
	quit(1 if failed else 0)
