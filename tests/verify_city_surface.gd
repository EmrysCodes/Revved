extends SceneTree
var failed:=false
func _initialize()->void:call_deferred("run")
func check(value:bool,message:String)->void:
	if not value:failed=true;push_error(message)
func run()->void:
	var city: Node3D=load("res://scenes/hartford_district.tscn").instantiate();city.set_meta("disable_population",true);root.add_child(city)
	for i in range(8):await physics_frame
	check(city.get_meta("continuous_street_count",0)==222,"Every ground street joins the continuous surface")
	var art: Node3D=city.get_node("ModernCityArt/CityArchitecture")
	check(art.get_meta("families",{}).size()==12,"Twelve facade families")
	for batch:MultiMeshInstance3D in art.get_children():check(batch.get_meta("modern_lod",-1)==0,"No overlapping flat building impostors")
	var infill: Node3D=city.get_node("CityStreetwall");check(infill.get_meta("infill_count",0)>=1000,"Denser low-rise street edges")
	var state:=city.get_world_3d().direct_space_state
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://world/hartford/street_plan.json"))
	var samples:=0
	for road: Dictionary in plan.roads:
		if road.elevated:continue
		for i in range(0,road.points.size(),15):
			var v: Array=road.points[i];var p:=Vector3(v[0],v[1],v[2])
			var query:=PhysicsRayQueryParameters3D.create(p+Vector3.UP*1.5,p-Vector3.UP*2)
			query.exclude=[city.car.get_rid()]
			var hit:=state.intersect_ray(query)
			check(not hit.is_empty() and hit.normal.y>.9,"Continuous upright drivable surface at "+str(p));samples+=1
	# Sweep actual car-sized volumes through all authored event routes against new infill.
	var shape:=BoxShape3D.new();shape.size=Vector3(2,1.4,4.4)
	var routes:=0;var queries:=0
	var files:=DirAccess.get_files_at("res://racing/events/");files.append("../capital_run_route.json")
	for filename in files:
		if not filename.ends_with(".json"):continue
		var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://racing/events/"+filename));var points: Array=data.get("points",[])
		if points.is_empty():continue
		routes+=1
		for i in range(0,points.size()-1,3):
			var v: Array=points[i];var next: Array=points[i+1];var p:=Vector3(v[0],v[1],v[2]);var dir:=Vector3(next[0],next[1],next[2])-p
			var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform=Transform3D(Basis(Vector3.UP,atan2(-dir.x,-dir.z)),p+Vector3.UP*.9)
			query.exclude=[city.car.get_rid()]
			for hit: Dictionary in state.intersect_shape(query,16):check(not infill.is_ancestor_of(hit.collider),"New building blocks event "+filename+" at "+str(i))
			queries+=1
	print("CITY SURFACE ","FAIL" if failed else "PASS",": ",samples," ground checks, ",queries," car-volume samples across ",routes," route files; 12 families; ",infill.get_meta("infill_count")," infill parcels")
	city.queue_free();await process_frame;quit(1 if failed else 0)
