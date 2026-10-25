extends Node3D
## Deterministic street dressing. Soft props intentionally have no driving collision.
var batches: Dictionary={}
var meshes: Dictionary={}
var counts: Dictionary={}
var road_cells: Dictionary={}
var space: PhysicsDirectSpaceState3D
var lamp_positions := PackedVector3Array()
func ground(x: float,z: float) -> float:
	var land:=4.0+16.0*(1.0-smoothstep(-1700,500,x))+2.0*sin(z/750.0)
	var river_x:=730.0+35.0*sin(z/800.0)
	return lerpf(-5.0,land,smoothstep(72.0,112.0,absf(x-river_x)))
func material(color: Color) -> StandardMaterial3D:
	var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=0.9
	return mat
func box_mesh(size: Vector3,color: Color) -> BoxMesh:
	var mesh:=BoxMesh.new();mesh.size=size;mesh.material=material(color);return mesh
func cylinder(radius: float,height: float,color: Color) -> CylinderMesh:
	var mesh:=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=height
	mesh.radial_segments=8;mesh.material=material(color);return mesh
func _ready() -> void:
	await get_tree().physics_frame
	space=get_world_3d().direct_space_state
	for kind: String in ["tree_ash","tree_linden"]:
		for level: String in ["near","far"]:
			var path: String = "res://assets/licensed/modern_city_architecture/"+kind+"_"+level+".res"
			if ResourceLoader.exists(path): meshes[kind+"_"+level] = load(path)
	meshes.trunk=cylinder(0.18,3.4,Color("62503c"))
	for i in range(3):
		var crown:=SphereMesh.new();crown.radius=2.2;crown.height=4.8;crown.radial_segments=10;crown.rings=5
		crown.material=material([Color("29462a"),Color("3c5930"),Color("5b6331")][i]);meshes["leaves"+str(i)]=crown
	meshes.seat=box_mesh(Vector3(2.0,0.08,0.12),Color("98724d"))
	meshes.back=box_mesh(Vector3(2.0,0.12,0.08),Color("98724d"))
	meshes.leg=box_mesh(Vector3(0.1,0.5,0.5),Color("283943"))
	meshes.bin=cylinder(0.32,0.85,Color("334e4a"))
	meshes.bin_lid=cylinder(0.36,0.1,Color("192c30"))
	meshes.pole=cylinder(0.09,7.2,Color("36434b"))
	meshes.arm=box_mesh(Vector3(1.8,0.12,0.12),Color("36434b"))
	meshes.light=box_mesh(Vector3(0.65,0.12,0.35),Color("f9e7b3"))
	meshes.light.material.emission_enabled = true
	meshes.light.material.emission = Color("ffd59a")
	meshes.light.material.emission_energy_multiplier = 2.0
	meshes.planter=box_mesh(Vector3(1.6,0.35,1.6),Color("aaa79b"))
	var shrub:=SphereMesh.new();shrub.radius=0.72;shrub.height=0.7;shrub.radial_segments=10;shrub.rings=5
	shrub.material=material(Color("3c613c"));meshes.shrub=shrub
	meshes.path=box_mesh(Vector3(3.8,0.04,3.8),Color("b7b3a5"))
	meshes.banner=box_mesh(Vector3(0.7,1.7,0.05),Color("b47d38"))
	var city:=get_parent()
	for path: PackedVector3Array in city.map_roads:
		for point in path:
			var cell:=Vector2i(floori(point.x/32),floori(point.z/32))
			if not road_cells.has(cell): road_cells[cell]=[]
			road_cells[cell].append(point)
	var serial:=0
	for path: PackedVector3Array in city.map_roads:
		var last:=Vector3.INF
		for i in range(1,path.size()-1):
			var point:=path[i]
			if point.distance_to(last)<42: continue
			last=point;serial+=1
			var direction:=path[i+1]-path[i-1];direction.y=0;direction=direction.normalized()
			var yaw:=atan2(-direction.x,-direction.z)
			var side:=direction.cross(Vector3.UP)
			for sign_value in [-1,1]:
				var p: Vector3=point+side*sign_value*17
				p.y=ground(p.x,p.z)
				if not suitable(p,13): continue
				if serial%3==0:
					bench(p,yaw);prop("bin",p+side*2.0+Vector3.UP*0.44,yaw)
					prop("bin_lid",p+side*2.0+Vector3.UP*0.91,yaw)
				else:
					tree(p,serial%3)
				var lamp_point: Vector3=p+direction*4.5
				if suitable(lamp_point,13): lamp(lamp_point,yaw,serial%4==0)
				if serial%5==0:
					prop("planter",p-direction*4+Vector3.UP*0.18,yaw)
					prop("shrub",p-direction*4+Vector3.UP*0.6,yaw)
	# Meadow groves and pocket plazas turn unused interchange land into a green buffer.
	var random:=RandomNumberGenerator.new();random.seed=21084
	for i in range(1200):
		var p:=Vector3(random.randf_range(-1850,1450),0,random.randf_range(-1450,1450));p.y=ground(p.x,p.z)
		if not suitable(p,27): continue
		tree(p,i%3)
		if i%7==0:
			bench(p+Vector3(4,0,0),0)
			for tile in range(4):
				var q:=p+Vector3(4,0,tile*3.8);q.y=ground(q.x,q.z)
				prop("path",q,0)
	flush()
	set_meta("counts",counts)
	print("CityLife: ",counts)
func suitable(p: Vector3,road_clearance: float) -> bool:
	for reserved: Rect2 in get_parent().get_meta("downtown_reserved_spaces",[]):
		if reserved.grow(4).has_point(Vector2(p.x,p.z)): return false
	if p.y<0 or absf(p.x-(730+35*sin(p.z/800)))<118: return false
	var cell:=Vector2i(floori(p.x/32),floori(p.z/32))
	for x in range(-1,2):
		for z in range(-1,2):
			for road: Vector3 in road_cells.get(cell+Vector2i(x,z),[]):
				if Vector2(p.x-road.x,p.z-road.z).length()<road_clearance: return false
	var shape:=BoxShape3D.new();shape.size=Vector3(5,8,5)
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape
	query.transform=Transform3D(Basis.IDENTITY,p+Vector3.UP*4.6)
	return space.intersect_shape(query,1).is_empty()
func prop(key: String,p: Vector3,yaw: float,scale_value:=Vector3.ONE) -> void:
	var cell_size := 80.0 if key.begins_with("tree_") else 220.0
	var cell:="%s_%d_%d"%[key,floori(p.x/cell_size),floori(p.z/cell_size)]
	if not batches.has(cell): batches[cell]=[key,[]]
	batches[cell][1].append(Transform3D(Basis(Vector3.UP,yaw).scaled_local(scale_value),p))
	counts[key]=counts.get(key,0)+1
func tree(p: Vector3,color: int) -> void:
	var kind := "tree_ash" if color%2==0 else "tree_linden"
	if meshes.has(kind+"_near") and meshes.has(kind+"_far"):
		# Existing planting points stay clear of roads; replace only the visual mesh.
		var height := 6.0+fposmod(p.x*0.13+p.z*0.19,2.5)
		var scale_value: float = height/meshes[kind+"_near"].get_aabb().size.y
		var yaw := fposmod(p.x*0.37+p.z*0.23,TAU)
		prop(kind+"_near",p,yaw,Vector3.ONE*scale_value)
		prop(kind+"_far",p,yaw,Vector3.ONE*scale_value)
		counts["trunk"] = counts.get("trunk",0)+1
		return
	prop("trunk",p+Vector3.UP*1.7,0)
	prop("leaves"+str(color),p+Vector3.UP*4.6,0,Vector3(0.9,0.9,0.85))
	prop("leaves"+str(color),p+Vector3(1.0,4.0,0.2),0,Vector3(0.75,0.7,0.8))
	prop("leaves"+str(color),p+Vector3(-0.8,4.0,-0.6),0,Vector3(0.7,0.75,0.75))
func bench(p: Vector3,yaw: float) -> void:
	var basis:=Basis(Vector3.UP,yaw)
	for offset in [-0.23,-0.08,0.08,0.23]: prop("seat",p+basis*Vector3(0,0.55,offset),yaw)
	for height in [0.78,0.96,1.14]: prop("back",p+basis*Vector3(0,height,0.28),yaw)
	for side in [-0.75,0.75]: prop("leg",p+basis*Vector3(side,0.25,0),yaw)
func lamp(p: Vector3,yaw: float,banner: bool) -> void:
	var basis:=Basis(Vector3.UP,yaw)
	lamp_positions.append(p+basis*Vector3(1.6,7.0,0))
	prop("pole",p+Vector3.UP*3.6,yaw)
	prop("arm",p+basis*Vector3(0.8,7.1,0),yaw)
	prop("light",p+basis*Vector3(1.6,7.0,0),yaw)
	if banner: prop("banner",p+basis*Vector3(0.45,5.3,0),yaw)
func flush() -> void:
	for key in batches:
		var data: Array=batches[key]
		var multi:=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D
		multi.mesh=meshes[data[0]];multi.instance_count=data[1].size()
		for i in range(multi.instance_count): multi.set_instance_transform(i,data[1][i])
		var visual:=MultiMeshInstance3D.new();visual.name=key;visual.multimesh=multi
		visual.visibility_range_end=420 if data[0].begins_with("leaves") else 260
		visual.visibility_range_end_margin=40
		if data[0].begins_with("tree_"):
			var far: bool = data[0].ends_with("_far")
			visual.visibility_range_begin = (100 if OS.has_feature("mobile") else 165) if far else 0
			visual.visibility_range_end = (340 if OS.has_feature("mobile") else 520) if far else (120 if OS.has_feature("mobile") else 185)
			visual.visibility_range_begin_margin = 10; visual.visibility_range_end_margin = 10
			if far: visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		visual.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		add_child(visual)
