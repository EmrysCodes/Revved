extends "res://tools/build_capital_run.gd"
const CATALOG=preload("res://core/career_catalog.gd")
func plan(id:String) -> Array:
	match id:
		"pearl_dash":return [[-690,-70],[-340,-70],[0,0],[5,-155],[-340,-155],[-760,-265]]
		"bushnell_clock":return [[-305,190],[-565,80],[-825,190],[-565,300],[-305,190]]
		"asylum_circuit":return [[-40,180],[0,0],[5,-155],[-340,-155],[-298,155],[-50,266],[-40,180]]
		"columbus_sprint":return [[425,-450],[425,0],[410,425],[-100,990],[-125,1260]]
		"northbound_run":return [[15,-1000],[15,-435],[-340,-435],[-760,-265],[-340,-155],[0,0],[-50,266]]
		"downtown_endurance":return [[-40,180],[0,0],[5,-155],[-340,-155],[-298,155],[-50,266],[-40,180]]
		"capitol_duel":return [[-760,-265],[-1240,-255],[-1240,400],[-900,400],[-100,990],[410,425],[425,0],[0,0]]
		"capitol_crown":return [[-40,180],[0,0],[15,-435],[-340,-435],[-760,-265],[-1240,-255],[-1240,400],[-100,990],[410,425],[425,0],[5,-155]]
		"founders_entry":return [[425,0],[1137,-11],[1590,-50],[1810,-35],[1810,205],[1575,220],[1435,500]]
		"pitkin_dash":return [[1137,180],[1575,220],[1790,530],[1580,730],[1445,880],[1137,1000]]
		"river_clock":return [[1590,-180],[1590,-340],[1137,-310],[1137,180],[1575,220],[1590,500],[1435,500],[1445,880],[1560,970]]
		"main_street_circuit":return [[1575,280],[1590,500],[1435,500],[1445,210],[1575,220],[1575,280]]
		"foundry_sprint":return [[1445,880],[1560,970],[1560,830],[1670,730],[1680,530],[1690,365],[1680,205],[1575,220],[1137,180]]
		"silver_lane_rush":return [[1560,830],[1740,810],[1790,530],[1810,205],[1790,-310],[1590,-340],[1137,-310]]
		"eastside_endurance":return [[1575,280],[1590,500],[1580,730],[1760,720],[1790,530],[1810,205],[1810,-35],[1790,-310],[1590,-340],[1445,-330],[1445,210],[1575,220],[1575,280]]
		"river_duel":return [[1435,500],[1137,490],[1137,180],[1575,220],[1590,-340],[1790,-310],[1790,530],[1560,830],[1137,1000]]
		"eastside_crown":return [[1137,180],[1575,220],[1590,-340],[1137,-310],[1137,-11],[425,0],[0,0],[-340,-155],[-760,-265],[-1240,400],[-100,990],[1137,1000],[1560,830],[1790,530],[1575,220]]
	return []
func _run() -> void:
	root.get_node("StreetProfile").launch_mode="free"
	city=load("res://scenes/hartford_district.tscn").instantiate();city.set_meta("offline_build",true);root.add_child(city)
	city.car.set_physics_process(false);_index_roads()
	DirAccess.make_dir_recursive_absolute("res://racing/events")
	for item in CATALOG.EVENTS:
		if item.id=="capital_run":continue
		var anchors:Array=plan(item.id)
		var raw:=PackedVector3Array()
		for i in range(1,anchors.size()):
			var a:Vector3=Vector3(anchors[i-1][0],0,anchors[i-1][1]);var b:Vector3=Vector3(anchors[i][0],0,anchors[i][1])
			var section:=local_route(a,b)
			if section.size()<2:push_error("Disconnected career route: "+item.id);quit(1);return
			raw.append_array(section if raw.is_empty() else section.slice(1))
		var clean:=PackedVector3Array()
		for point:Vector3 in raw:
			if clean.size()>1 and point.distance_to(clean[-2])<.15:clean.resize(clean.size()-1)
			elif clean.is_empty() or point.distance_to(clean[-1])>.05:clean.append(point)
		var base:=preload("res://racing/course_smoothing.gd").smooth_course(clean)
		var course:=PackedVector3Array()
		var sections:Array=[]
		for lap in range(item.laps):
			var start:=course.size()
			course.append_array(base if lap==0 else base.slice(1))
			sections.append({"start":start,"end":course.size()-1,"label":("LAP %d / %d  •  "%[lap+1,item.laps] if item.laps>1 else "")+("DOWNTOWN / CAPITOL" if item.chapter==0 else "EASTSIDE / FOUNDERS")})
		var finish:=course.size()-1
		var runout:=PackedVector3Array()
		if item.laps>1:runout=base.slice(1,mini(20,base.size()))
		else:
			var direction:Vector3=(course[-1]-course[-4]).normalized()
			for i in range(1,7):runout.append(course[-1]+direction*i*3)
		course.append_array(runout)
		var distances:=PackedFloat64Array([0.0])
		for i in range(1,course.size()):distances.append(distances[-1]+course[i-1].distance_to(course[i]))
		var guidance=preload("res://racing/route_guidance.gd")
		var checkpoints:=guidance.safe_checkpoints(course,distances,finish)
		var serial:Array=[];var traffic:Array=[]
		for p in course:serial.append([snappedf(p.x,.001),snappedf(p.y,.001),snappedf(p.z,.001)])
		if item.laps>1:
			for p in base:traffic.append([p.x,p.y,p.z])
		var target:float=ceil(distances[finish]/20+float(guidance.maneuvers(course,distances,finish).size())*3.5+18)
		var data:Dictionary={"version":2,"name":item.name,"points":serial,"distances":Array(distances),"checkpoints":Array(checkpoints),"sections":sections,"finish_index":finish,"length":distances[finish],"laps":item.laps,"target_seconds":target,"traffic_loop":traffic}
		var file:=FileAccess.open(CATALOG.route_path(item.id),FileAccess.WRITE);file.store_string(JSON.stringify(data));file.close()
		print("CAREER_ROUTE ",item.id," ",roundi(distances[finish]),"m / ",checkpoints.size()," checkpoints / ",item.laps," laps")
	print("PASS: 18 career events across two districts (Capital Run preserved)")
	quit()
