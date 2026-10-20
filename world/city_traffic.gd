extends Node3D
var clock:=0.0
var race_priority:Array[Vector3]=[]
var agents:Array[CharacterBody3D]=[]
var intersections:Array[Vector3]=[]
var signal_heads:Array=[]
var timer:=0.0
const CAR=preload("res://world/traffic_car.gd")
func _ready() -> void:
	var city:=get_parent()
	var routes:Array=[]
	for path:PackedVector3Array in city.get_meta("flowing_routes",[]):routes.append(path)
	for id in ["asylum_circuit","main_street_circuit"]:
		var filename:String="res://racing/events/"+str(id)+".json"
		if not FileAccess.file_exists(filename):continue
		var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(filename))
		var line:=PackedVector3Array()
		for p:Array in data.get("traffic_loop",[]):line.append(Vector3(p[0],p[1],p[2]))
		if line.size()>2:routes.append(line)
	var serial:=0
	for path:PackedVector3Array in routes:
		if path.size()<4 or path[0].distance_to(path[-1])>12:continue
		for reverse in [false,true]:
			var line:=path.duplicate()
			if reverse:line.reverse()
			var distances:=PackedFloat64Array([0.0])
			for i in range(1,line.size()):distances.append(distances[-1]+line[i-1].distance_to(line[i]))
			var count:=clampi(int(distances[-1]/(430 if OS.has_feature("mobile") else 270)),2 if OS.has_feature("mobile") else 3,4 if OS.has_feature("mobile") else 7)
			for i in range(count):
				var car:=CharacterBody3D.new();car.name="Traffic_%03d"%serial;car.set_script(CAR)
				car.fleet=self;car.path=line;car.distances=distances;car.route_length=distances[-1]
				car.along=fposmod(float(i)*distances[-1]/count+float(serial%5)*19,distances[-1]);car.serial=serial;car.cruise=9.5+float(serial%5)*1.2
				add_child(car);agents.append(car);serial+=1
	for p in [Vector3(0,0,0),Vector3(-320,0,-156),Vector3(-315,0,-380),Vector3(1585,0,220),Vector3(1590,0,500),Vector3(1590,0,-330)]:
		p.y=ground(p.x,p.z);intersections.append(p);make_signals(p)
	set_meta("vehicle_count",agents.size())
	print("CityTraffic: ",agents.size()," lane-following vehicles")
	var audio := Node3D.new(); audio.set_script(load("res://audio/traffic_audio.gd")); add_child(audio)
func ground(x:float,z:float) -> float:
	return 4+16*(1-smoothstep(-1700,500,x))+2*sin(z/750)
func reserve_race_junctions(event:Node) -> void:
	race_priority.clear()
	if not event.is_active():return
	for section:Dictionary in event.sections:
		if str(section.label).contains("ALLEY"):
			race_priority.append(event.route[section.start]);race_priority.append(event.route[section.end])
	# Clear an occupied junction only while it is beyond the player's visible population radius.
	for agent:CharacterBody3D in agents:
		if agent.global_position.distance_to(event.player.global_position)<420:continue
		for crossing:Vector3 in race_priority:
			if agent.global_position.distance_to(crossing)<68:
				agent.along=fposmod(agent.along+160,agent.route_length)
				var sample:Array=agent.sample(agent.along);agent.global_position=sample[0];agent.rotation.y=atan2(-sample[1].x,-sample[1].z);agent.speed=0
func should_stop(point:Vector3,direction:Vector3) -> bool:
	var event:=get_parent().get_node_or_null("CityRace")
	for crossing:Vector3 in race_priority:
		var racers_near:bool=get_parent().car.global_position.distance_to(crossing)<180
		if is_instance_valid(event):
			for racer in event.opponents:
				if racer.global_position.distance_to(crossing)<180:racers_near=true
		if not racers_near:continue
		var approach:Vector3=crossing-point;approach.y=0
		if approach.length()>24 and approach.length()<65 and approach.dot(direction)>18 and absf(approach.dot(direction.cross(Vector3.UP)))<10:return true
	for i in range(intersections.size()):
		var delta:Vector3=intersections[i]-point;delta.y=0
		if delta.length()>36 or delta.dot(direction)<8 or delta.dot(direction)>29:continue
		if absf(delta.dot(direction.cross(Vector3.UP)))>8:continue
		var phase:=fposmod(clock+float(i)*7,42)
		var north_south:=absf(direction.z)>absf(direction.x)
		var green:=phase<18 if north_south else phase>=21 and phase<39
		if not green:return true
	return false
func make_signals(p:Vector3) -> void:
	for sign_value in [-1,1]:
		var pole:=MeshInstance3D.new();var cylinder:=CylinderMesh.new();cylinder.top_radius=.07;cylinder.bottom_radius=.07;cylinder.height=4.8
		var metal:=StandardMaterial3D.new();metal.albedo_color=Color("38454b");cylinder.material=metal;pole.mesh=cylinder;pole.position=p+Vector3(sign_value*14,2.4,sign_value*16);add_child(pole)
		for axis in [0,1]:
			var head:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(.43,1.3,.35);box.material=metal;head.mesh=box;head.position=pole.position+Vector3(0,2,0);head.rotation.y=axis*PI/2;add_child(head)
			for lens in range(3):
				var light:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.14;sphere.height=.28;sphere.radial_segments=8;sphere.rings=4
				var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;sphere.material=mat;light.mesh=sphere
				light.position=head.position+Vector3(0,.4-lens*.4,0)+Basis(Vector3.UP,head.rotation.y)*Vector3(0,0,.20);add_child(light)
				signal_heads.append([light,intersections.size()-1,axis,lens])
func _process(delta:float) -> void:
	clock+=delta;timer+=delta
	if timer<.15:return
	timer=0
	for item:Array in signal_heads:
		var phase:=fposmod(clock+float(item[1])*7,42)
		var green:=phase<18 if item[2]==0 else phase>=21 and phase<39
		var yellow:=phase>=18 and phase<21 if item[2]==0 else phase>=39
		var active:bool=(item[3]==2 and green) or (item[3]==1 and yellow) or (item[3]==0 and not green and not yellow)
		var colors:=[Color("ff514c"),Color("ffd55a"),Color("54ed9a")]
		item[0].mesh.material.albedo_color=colors[item[3]] if active else Color("17262a")
