extends SceneTree
var city:Node3D
var detail:Node3D
var kit:RefCounted
var roads:Array=[]
var placed:Array[Vector3]=[]
var meshes:Dictionary={}
var batches:Dictionary={}
var serial:=0
var parking_count:=0
func _initialize() -> void:call_deferred("run")
func ground(x:float,z:float) -> float:return 4+16*(1-smoothstep(-1700,500,x))+2*sin(z/750)
func road_info(p:Vector3) -> Dictionary:
	var best:=INF;var nearest:=Vector3.ZERO
	for entry:Array in roads:
		if not entry[1].grow(minf(best,100)).has_point(Vector2(p.x,p.z)):continue
		var line:PackedVector3Array=entry[0]
		for i in range(1,line.size(),3):
			var q:=Geometry3D.get_closest_point_to_segment(p,line[maxi(0,i-3)],line[i])
			var distance:=Vector2(q.x-p.x,q.z-p.z).length()
			if distance<best:best=distance;nearest=q
	return {"distance":best,"point":nearest}
func material(color:Color) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.9;return m
func box(key:String,p:Vector3,size:Vector3,color:Color,yaw:=0.0) -> void:
	if not meshes.has(key):
		var mesh:=BoxMesh.new();mesh.size=size;mesh.material=material(color);meshes[key]=mesh
	if not batches.has(key):batches[key]=[]
	batches[key].append(Transform3D(Basis(Vector3.UP,yaw),p))
func pavement(p:Vector3,yaw:float) -> void:
	var basis:=Basis(Vector3.UP,yaw);var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tool.set_material(material(Color("484b4a")))
	var points:Array[Vector3]=[]
	for v in [Vector3(-13,0,-15),Vector3(13,0,-15),Vector3(-13,0,15),Vector3(13,0,15)]:
		var q:Vector3=p+basis*v;q.y=ground(q.x,q.z)+.025;points.append(q)
	for i in [0,1,2,1,3,2]:
		tool.set_normal(Vector3.UP);tool.add_vertex(points[i])
	var node:=MeshInstance3D.new();detail.add_child(node);node.owner=detail;node.mesh=tool.commit()
func parked(p:Vector3,yaw:float,index:int) -> void:
	var source:Node3D=load("res://assets/traffic/kenney/"+["sedan","suv","hatchback-sports","van"][index%4]+".glb").instantiate()
	collect(source,Transform3D(Basis(Vector3.UP,yaw).scaled_local(Vector3.ONE*1.3),p))
	source.free()
func collect(node:Node,transform:Transform3D) -> void:
	if node is Node3D:transform=transform*node.transform
	if node is MeshInstance3D:
		var key:String="parked_"+str(node.mesh.get_rid().get_id())
		meshes[key]=node.mesh
		if not batches.has(key):batches[key]=[]
		batches[key].append(transform)
	for child in node.get_children():collect(child,transform)
func run() -> void:
	root.get_node("StreetProfile").launch_mode="free"
	city=load("res://scenes/hartford_district.tscn").instantiate();city.set_meta("offline_build",true);root.add_child(city)
	city.car.set_physics_process(false)
	for line:PackedVector3Array in city.map_roads+city.highway_roads+city.ramp_roads:
		var bounds:=Rect2(Vector2(line[0].x,line[0].z),Vector2.ZERO)
		for p:Vector3 in line:bounds=bounds.expand(Vector2(p.x,p.z))
		roads.append([line,bounds])
	await physics_frame;await physics_frame
	detail=Node3D.new();detail.name="EastsideFrontage";kit=load("res://tools/city_kit.gd").new(detail,detail)
	var shape:=BoxShape3D.new();shape.size=Vector3(26,13,28)
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1
	var space:=city.get_world_3d().direct_space_state
	for x in range(1360,1881,27):
		for z in range(-440,1051,31):
			var p:=Vector3(x,ground(x,z),z);var info:=road_info(p)
			if info.distance<26 or info.distance>100:continue
			var yaw:=atan2(info.point.x-p.x,info.point.z-p.z)
			query.transform=Transform3D(Basis(Vector3.UP,yaw),p+Vector3.UP*7.5)
			if not space.intersect_shape(query,1).is_empty():continue
			var blocked:=false
			for other:Vector3 in placed:
				if Vector2(p.x-other.x,p.z-other.z).length()<other.y+(20 if serial%6==2 else 14):blocked=true;break
			if blocked:continue
			placed.append(Vector3(p.x,20 if serial%6==2 else 14,p.z));pavement(p,yaw)
			var basis:=Basis(Vector3.UP,yaw)
			if serial%6==2:
				parking_count+=1
				for row in range(4):
					for side in [-1,1]:
						var offset:=Vector3(-9+row*5.7,0,side*10.0);var q:Vector3=p+basis*offset;q.y=ground(q.x,q.z)+.065
						box("bay-line",q,Vector3(.10,.035,5),Color("d8d2ba"),yaw)
					if row%2==0:
						var q:Vector3=p+basis*Vector3(-6+row*5,0,9);q.y=ground(q.x,q.z)+.04;parked(q,yaw,serial+row)
			else:
				var height:=10.0+float(serial%5)*4
				kit.building(p,Vector3(18,height,21),yaw,serial%3)
				var front:Vector3=p+basis*Vector3(0,0,11)
				box("awning-"+str(serial%3),front+Vector3.UP*3.6,Vector3(17,.22,2.1),[Color("5a222b"),Color("244c59"),Color("3d4f32")][serial%3],yaw)
				kit.prop("Prop_ACUnit",p+Vector3.UP*(height+.1),yaw)
			serial+=1
	kit.flush()
	for key in batches:
		var node:=MultiMeshInstance3D.new();node.name=key;node.multimesh=MultiMesh.new();node.multimesh.transform_format=MultiMesh.TRANSFORM_3D;node.multimesh.mesh=meshes[key]
		node.set_script(load("res://world/hartford/kit_instances.gd"));node.placements.assign(batches[key]);node.visibility_range_end=500
		detail.add_child(node);node.owner=detail
	detail.set_meta("infill_buildings",kit.count);detail.set_meta("parking_courts",parking_count)
	var scene:=PackedScene.new();assert(scene.pack(detail)==OK)
	assert(ResourceSaver.save(scene,"res://world/eastside/frontage.tscn")==OK)
	print("EASTSIDE FRONTAGE: ",kit.count," additional buildings / ",parking_count," parking courts")
	detail.free();quit()
