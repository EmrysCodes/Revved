extends Node3D
## Animated sidewalk life. Characters step away from approaching cars; they do not block races.
var walkers:Array=[]
var clock:=0.0
var timer:=0.0
var templates:Array[PackedScene]=[]
var road_cells:Dictionary={}
var space:PhysicsDirectSpaceState3D
func ground(x:float,z:float) -> float:
	return 4+16*(1-smoothstep(-1700,500,x))+2*sin(z/750)
func _ready() -> void:
	call_deferred("populate")
func populate() -> void:
	var city:=get_parent();space=get_world_3d().direct_space_state
	for name in ["Casual_2","Casual_Hoodie","Suit","Worker","Punk"]:templates.append(load("res://assets/people/quaternius/"+name+".gltf"))
	for path:PackedVector3Array in city.map_roads:
		for p in path:
			var cell:=Vector2i(floori(p.x/24),floori(p.z/24))
			if not road_cells.has(cell):road_cells[cell]=[]
			road_cells[cell].append(p)
	var paths:Array=[]
	var roads:=city.get_node("Streets").get_children()
	for i in range(city.map_roads.size()):
		var title:String=str(roads[i].name) if i<roads.size() else ""
		if title.contains("Alley") or title.contains("Service") or title.contains("LoopAccess"):continue
		if title in ["Main Street","Trumbull Street","Pearl Street","Asylum Street","Columbus Boulevard","East River Drive"] or title.begins_with("Eastside_") or title.contains("CurvingNeighborhood"):
			paths.append([city.map_roads[i],20.0 if not title.begins_with("Eastside_") else (20.0 if title.contains("Main") or title.contains("Boulevard") else 16.0)])
	var limit:int=40 if OS.has_feature("mobile") else 110
	var serial:=0;var west_count:=0;var east_count:=0
	for entry:Array in paths:
		var path:PackedVector3Array=entry[0]
		for i in range(8,path.size()-13,17):
			if walkers.size()>=limit:break
			var side:int=-1 if serial%2==0 else 1
			var line:=PackedVector3Array()
			for j in range(i,i+9):
				var direction:Vector3=path[j+1]-path[j-1];direction.y=0;direction=direction.normalized()
				var p:Vector3=path[j]+direction.cross(Vector3.UP)*side*(entry[1]*.5+2.2)
				p.y=ground(p.x,p.z)+.14;line.append(p)
			if not suitable(line):continue
			var east:bool=line[0].x>900
			if east and east_count>=limit/2 or not east and west_count>=limit/2:continue
			var model:Node3D=templates[serial%templates.size()].instantiate();add_child(model)
			model.name="Pedestrian_%03d"%serial
			var animation:AnimationPlayer=model.find_children("*","AnimationPlayer",true,false)[0]
			for label in ["Walk","Run","Idle","Idle_Neutral","Wave"]:
				if animation.has_animation(label):animation.get_animation(label).loop_mode=Animation.LOOP_LINEAR
			animation.play("Walk");animation.seek(float(serial%7)*.11,true)
			model.position=line[0]
			var distances:=PackedFloat64Array([0.0])
			for j in range(1,line.size()):distances.append(distances[-1]+line[j-1].distance_to(line[j]))
			walkers.append({"node":model,"animation":animation,"line":line,"distances":distances,"length":distances[-1],"phase":float(serial)*2.1,"speed":.9+float(serial%5)*.11,"avoid":0.0})
			serial+=1
			if east:east_count+=1
			else:west_count+=1
	set_meta("pedestrian_count",walkers.size());print("CityPedestrians: ",walkers.size()," animated sidewalk walkers")
func suitable(line:PackedVector3Array) -> bool:
	for p in [line[0],line[line.size()/2],line[-1]]:
		var shape:=SphereShape3D.new();shape.radius=.42
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform=Transform3D(Basis.IDENTITY,p+Vector3.UP)
		if not space.intersect_shape(query,1).is_empty():return false
		var cell:=Vector2i(floori(p.x/24),floori(p.z/24))
		for x in range(-1,2):
			for z in range(-1,2):
				for road:Vector3 in road_cells.get(cell+Vector2i(x,z),[]):
					if Vector2(road.x-p.x,road.z-p.z).length()<8.2:return false
	return true
func _process(delta:float) -> void:
	clock+=delta;timer+=delta
	if timer<.05 or walkers.is_empty():return
	var step:=timer;timer=0
	var car:CharacterBody3D=get_parent().car
	for walker:Dictionary in walkers:
		var model:Node3D=walker.node
		var near:bool=model.global_position.distance_squared_to(car.global_position)<pow(90 if OS.has_feature("mobile") else 165,2)
		model.visible=near;walker.animation.active=near
		if not near:continue
		var period:float=walker.length*2/maxf(walker.speed,.1)
		var phase:float=fposmod(clock+walker.phase,period)/period
		var forward:bool=phase<.5
		var along:float=(phase*2 if forward else 2-phase*2)*walker.length
		var index:=0
		while index<walker.line.size()-2 and walker.distances[index+1]<along:index+=1
		var ratio:float=clampf((along-walker.distances[index])/maxf(.01,walker.distances[index+1]-walker.distances[index]),0,1)
		var point:Vector3=walker.line[index].lerp(walker.line[index+1],ratio)
		var direction:Vector3=(walker.line[index+1]-walker.line[index]).normalized()*(1 if forward else -1)
		var danger:=point.distance_to(car.global_position)<12 and car.velocity.length()>4
		walker.avoid=move_toward(walker.avoid,1.4 if danger else 0.0,step*3)
		if walker.avoid>.1:
			var away:=point-car.global_position;away.y=0
			point+=away.normalized()*walker.avoid
		model.position=point;model.rotation.y=atan2(direction.x,direction.z)
		var wanted:="Run" if danger else "Walk"
		if walker.animation.current_animation!=wanted:walker.animation.play(wanted,.2)
