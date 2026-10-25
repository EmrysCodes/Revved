@tool
extends RefCounted
const STYLES := ["Brick / red","Brick / charcoal","Stone / civic","Stone / tan","Warehouse","Glass / blue","Glass / dark","Office / concrete","Apartments / cream","Art deco tower","Brick / warm","Civic / gray"]
static var _family_meshes: Dictionary={}
static func entries()->Array[Dictionary]:
	var result:Array[Dictionary]=[]
	for i in range(12):result.append({"id":"family_%d"%i,"name":STYLES[i],"category":"Buildings"})
	for item:Array in [["modern_stone","Modern City / stone"],["modern_office","Modern City / office"],["modern_retail_a","Modern City / shops A"],["modern_retail_b","Modern City / shops B"],["modern_tower","Modern City / tower"]]:
		result.append({"id":item[0],"name":item[1],"category":"Buildings"})
	for item:Array in [["tree_ash","Ash tree"],["tree_linden","Linden tree"],["bench","Bench"],["lamp","Street light"],["planter","Planter"],["bollard","Bollard"],["car_2","Parked coupe"],["car_4","Parked sports car"],["car_8","Parked sedan"],["junction","Crossroads / 4-way"],["junction_t","Junction / T"]]:
		result.append({"id":item[0],"name":item[1],"category":"Road pieces" if item[0].begins_with("junction") else "Street props"})
	return result
static func _family(id:int)->Mesh:
	if _family_meshes.is_empty() and ResourceLoader.exists("res://world/hartford/city_architecture.scn"):
		var scene:Node=load("res://world/hartford/city_architecture.scn").instantiate()
		for child:MultiMeshInstance3D in scene.get_children():
			var key:=int(str(child.name).split("_")[1])
			_family_meshes[key]=child.multimesh.mesh
		scene.free()
	return _family_meshes.get(id)
static func _material(color:Color)->StandardMaterial3D:
	var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=.9;return mat
static func _box(parent:Node3D,p:Vector3,size:Vector3,color:Color)->MeshInstance3D:
	var node:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size;mesh.material=_material(color);node.mesh=mesh;node.position=p;parent.add_child(node);return node
static func _visual(parent:Node3D,mesh:Mesh,transform_value:=Transform3D.IDENTITY)->MeshInstance3D:
	var visual:=MeshInstance3D.new();visual.mesh=mesh;visual.transform=transform_value;parent.add_child(visual);return visual
static func _copy_meshes(source:Node,parent:Node3D,transform_value:=Transform3D.IDENTITY)->void:
	var current:=transform_value
	if source is Node3D:current=transform_value*source.transform
	if source is MeshInstance3D:
		var visual:=_visual(parent,source.mesh,current);visual.material_override=source.material_override
		for i in range(source.mesh.get_surface_count()):visual.set_surface_override_material(i,source.get_surface_override_material(i))
	for child in source.get_children():_copy_meshes(child,parent,current)
static func create(id:String,solid:=true)->Node3D:
	var root:=Node3D.new();root.name=id.to_pascal_case();root.set_meta("workshop_item",true);root.set_meta("workshop_asset",id)
	var bounds:=Vector3(1,1,1)
	if id.begins_with("family_"):
		var index:=id.trim_prefix("family_").to_int();var mesh:=_family(index)
		if not mesh:root.free();return null
		bounds=Vector3(22,18 if index not in [5,6,9] else 42,18)
		_visual(root,mesh,Transform3D(Basis.IDENTITY.scaled(bounds),Vector3.ZERO))
	elif id.begins_with("modern_") or id.begins_with("tree_"):
		var key:=id.trim_prefix("modern_")
		if id=="modern_stone":key="stone_corner"
		elif id=="modern_office":key="modern_office"
		var path:="res://assets/licensed/modern_city_architecture/"+key+"_near.res"
		if not ResourceLoader.exists(path):root.free();return null
		var mesh:Mesh=load(path);var box:=mesh.get_aabb()
		var factor:float=(8.0 if id.begins_with("tree_") else (60.0 if id=="modern_tower" else 22.0))/box.size.y
		bounds=box.size*factor
		_visual(root,mesh,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*factor),Vector3.ZERO))
	elif id.begins_with("car_"):
		var path:=preload("res://vehicles/vehicle_catalog.gd").path_for(id.trim_prefix("car_").to_int())
		if not ResourceLoader.exists(path):root.free();return null
		var source:Node=load(path).instantiate();_copy_meshes(source,root);source.free();bounds=Vector3(2,1.5,4.5)
	elif id=="bench":
		bounds=Vector3(2,.95,.65)
		for z:float in [-.22,-.07,.08,.23]:_box(root,Vector3(0,.5,z),Vector3(2,.08,.12),Color("92734e"))
		for y:float in [.73,.91]:_box(root,Vector3(0,y,.28),Vector3(2,.1,.07),Color("92734e"))
		for x:float in [-.75,.75]:_box(root,Vector3(x,.24,0),Vector3(.09,.48,.55),Color("293943"))
	elif id=="lamp":
		bounds=Vector3(.2,7,.2);_box(root,Vector3(0,3.5,0),bounds,Color("40515b"))
		_box(root,Vector3(.8,6.95,0),Vector3(1.6,.12,.12),Color("40515b"))
		var bulb:=_box(root,Vector3(1.5,6.9,0),Vector3(.6,.08,.35),Color("ffe0a0"))
		bulb.mesh.material.emission_enabled=true;bulb.mesh.material.emission=Color("ffd49a");bulb.mesh.material.emission_energy_multiplier=1.5
		var light:=OmniLight3D.new();light.position=Vector3(1.5,6.5,0);light.light_color=Color("ffd49a");light.light_energy=2;light.omni_range=18;light.distance_fade_enabled=true;light.distance_fade_begin=90;light.distance_fade_length=25;light.shadow_enabled=false;root.add_child(light)
	elif id=="planter":
		bounds=Vector3(2,.7,2);_box(root,Vector3(0,.35,0),bounds,Color("85897d"));_box(root,Vector3(0,.74,0),Vector3(1.8,.12,1.8),Color("324c35"))
	elif id=="bollard":
		bounds=Vector3(.22,.9,.22);_box(root,Vector3(0,.45,0),bounds,Color("4c5b63"))
	elif id.begins_with("junction"):
		bounds=Vector3(28,.1,28)
		var road_material:Material=load("res://assets/licensed/modern_city_architecture/road.tres").duplicate()
		road_material.roughness=.92;road_material.metallic_texture=null;road_material.roughness_texture=null
		var patch:=_box(root,Vector3(0,-.025,0),Vector3(28,.05,28),Color("252d32"));patch.mesh.material=road_material
		for offset:Vector3 in [Vector3(-14,0,0),Vector3(14,0,0),Vector3(0,0,-14),Vector3(0,0,14)]:
			if id=="junction_t" and offset.z<0:continue
			var socket:=Marker3D.new();socket.name="RoadSocket";socket.position=offset;socket.set_meta("workshop_socket",true);root.add_child(socket)
		for x:int in [-1,1]:
			for z:int in [-1,1]:_box(root,Vector3(x*11,.04,z*11),Vector3(6,.08,6),Color("8d938c"))
		if id=="junction_t":_box(root,Vector3(0,.04,-11),Vector3(16,.08,6),Color("8d938c"))
	else:root.free();return null
	if solid:
		var body:=StaticBody3D.new();body.name="Solid";root.add_child(body)
		var collision:=CollisionShape3D.new();collision.shape=BoxShape3D.new();collision.shape.size=bounds
		collision.position.y=bounds.y*.5 if not id.begins_with("junction") else -.05;body.add_child(collision)
		if id.begins_with("tree_"):collision.shape.size=Vector3(.35,3,.35);collision.position.y=1.5
	return root
static func own(node:Node,scene:Node)->void:
	node.owner=scene
	for child:Node in node.get_children():
		if not child.has_meta("workshop_generated"):own(child,scene)
