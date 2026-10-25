extends "res://tools/build_city_architecture_v2.gd"
## Add a low-rise street wall only in parcels clear of buildings, streets and every race.
var occupied: Dictionary = {}
var road_cells: Dictionary = {}
var race_cells: Dictionary = {}
func ground(x:float,z:float)->float:return 4+16*(1-smoothstep(-1700,500,x))+2*sin(z/750)
func cell_for(p: Vector2) -> Vector2i:return Vector2i(floori(p.x/64),floori(p.y/64))
func occupy(rect: Rect2) -> void:
	for x in range(floori(rect.position.x/64),floori(rect.end.x/64)+1):
		for z in range(floori(rect.position.y/64),floori(rect.end.y/64)+1):
			var key:=Vector2i(x,z)
			if not occupied.has(key):occupied[key]=[]
			occupied[key].append(rect)
func clear_rect(rect: Rect2) -> bool:
	for x in range(floori(rect.position.x/64),floori(rect.end.x/64)+1):
		for z in range(floori(rect.position.y/64),floori(rect.end.y/64)+1):
			for other: Rect2 in occupied.get(Vector2i(x,z),[]):
				if rect.intersects(other.grow(2)):return false
	return true
func index_point(table: Dictionary,p: Vector3,extra: float=0) -> void:
	var key:=cell_for(Vector2(p.x,p.z))
	if not table.has(key):table[key]=[]
	table[key].append([p,extra])
func corridor_clear(p: Vector3,basis: Basis,size: Vector3,table: Dictionary,radius: float) -> bool:
	var key:=cell_for(Vector2(p.x,p.z));var inverse:=basis.inverse()
	for x in range(-1,2):
		for z in range(-1,2):
			for sample: Array in table.get(key+Vector2i(x,z),[]):
				var local: Vector3=inverse*(sample[0]-p)
				if absf(local.x)<size.x*.5+radius+sample[1] and absf(local.z)<size.z*.5+radius+sample[1]:return false
	return true
func run() -> void:
	for i in range(12):models.append(model(i))
	var city: Node3D=load("res://scenes/hartford_district.tscn").instantiate();city.set_meta("offline_build",true);root.add_child(city)
	city.add_child(load("res://world/eastside/frontage.tscn").instantiate())
	for collider: CollisionShape3D in city.find_children("*","CollisionShape3D",true,false):
		if not collider.shape is BoxShape3D or collider.shape.size.y<3 or collider.get_parent() is CharacterBody3D:continue
		var bounds:=collider.global_transform*AABB(-collider.shape.size*.5,collider.shape.size)
		occupy(Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z)))
	for rect: Rect2 in preload("res://world/hartford/downtown_detail.gd").SITES:occupy(rect.grow(5))
	var files:=DirAccess.get_files_at("res://racing/events/");files.append("../capital_run_route.json")
	for filename in files:
		if not filename.ends_with(".json"):continue
		var event: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://racing/events/"+filename))
		for point: Array in event.get("points",[]):index_point(race_cells,Vector3(point[0],point[1],point[2]))
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://world/hartford/street_plan.json"))
	for road: Dictionary in plan.roads:
		for v: Array in road.points:index_point(road_cells,Vector3(v[0],v[1],v[2]),float(road.width)*.5)
	# Preserve every highway/ramp footprint, including routes not used by current events.
	for paths: Array in [city.highway_roads,city.ramp_roads]:
		for path: PackedVector3Array in paths:
			for p: Vector3 in path:index_point(road_cells,p,9)
	var infill:=Node3D.new();infill.name="CityStreetwall";var total:=0
	for road: Dictionary in plan.roads:
		if road.elevated or road.width<10:continue
		var last:=Vector3.INF
		for index in range(1,road.points.size()-1):
			var v: Array=road.points[index];var p:=Vector3(v[0],v[1],v[2])
			if p.distance_to(last)<26:continue
			last=p
			if not (Rect2(-1100,-650,1550,1400).has_point(Vector2(p.x,p.z)) or Rect2(980,-650,900,1600).has_point(Vector2(p.x,p.z))):continue
			if Vector2((p.x+565)/330,(p.z-190)/185).length()<1:continue
			var next: Array=road.points[index+1];var tangent:=Vector3(next[0],next[1],next[2])-p;tangent.y=0;tangent=tangent.normalized()
			for sign_value in [-1,1]:
				var side: Vector3=tangent.cross(Vector3.UP)*sign_value
				var center: Vector3=p+side*(float(road.width)*.5+9)
				center.y=ground(center.x,center.z)-.35
				var hash_id:=absi(int(center.x*13+center.z*37))
				var size:=Vector3(16+(hash_id%3)*3,10+(hash_id%4)*3.2,12)
				var basis:=Basis(Vector3.UP,atan2(-side.x,-side.z))
				var box:=Transform3D(basis,center)*AABB(Vector3(-size.x*.5,0,-size.z*.5),size)
				var rect:=Rect2(Vector2(box.position.x,box.position.z),Vector2(box.size.x,box.size.z))
				if not clear_rect(rect) or not corridor_clear(center,basis,size,road_cells,1.5) or not corridor_clear(center,basis,size,race_cells,10):continue
				var kind:int=[0,1,2,3,4,7,8,10,11][hash_id%9]
				var body:=StaticBody3D.new();body.name="Streetwall_%03d"%total;body.position=center;body.basis=basis;infill.add_child(body);body.owner=infill
				var batch_key:="%d_%d_%d"%[kind,floori(center.x/160),floori(center.z/160)]
				if not batches.has(batch_key):batches[batch_key]=[kind,[]]
				batches[batch_key][1].append(Transform3D(basis.scaled_local(size),center))
				var collision:=CollisionShape3D.new();collision.shape=BoxShape3D.new();collision.shape.size=size;collision.position.y=size.y*.5
				body.add_child(collision);collision.owner=infill
				occupy(rect);total+=1
	for key in batches:
		var data: Array=batches[key];var visual:=MultiMeshInstance3D.new();visual.name="StreetwallArt_"+key
		visual.multimesh=MultiMesh.new();visual.multimesh.transform_format=MultiMesh.TRANSFORM_3D;visual.multimesh.mesh=models[data[0]]
		visual.set_script(load("res://world/hartford/kit_instances.gd"));visual.placements.assign(data[1])
		visual.visibility_range_end=1000;visual.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
		infill.add_child(visual);visual.owner=infill
	infill.set_meta("infill_count",total)
	var packed:=PackedScene.new();assert(packed.pack(infill)==OK)
	assert(ResourceSaver.save(packed,"res://world/hartford/city_streetwall.scn",ResourceSaver.FLAG_COMPRESS)==OK)
	print("STREETWALL BUILD PASS: ",total," low-rise parcels; all event corridors protected by 10 m clearance")
	city.free();infill.free();quit()
