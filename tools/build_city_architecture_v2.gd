extends SceneTree
## Closed, metre-scaled facade families avoid stretched shop photographs and flat impostors.
const PALETTES := ["805445","484b4c","b2afa0","a49177","715247","46606b","334451","85887e","c9bda4","aaa38d","975f48","858887"]
var models: Array[ArrayMesh] = []
var batches: Dictionary = {}
func _initialize() -> void: call_deferred("run")
func cube(tool: SurfaceTool,center: Vector3,size: Vector3) -> void:
	var box := BoxMesh.new();box.size=size
	var arrays := box.surface_get_arrays(0)
	var points: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL];var uvs: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV];var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	for i in indices:
		tool.set_normal(normals[i]);tool.set_uv(uvs[i]);tool.add_vertex(points[i]+center)
func model(kind: int) -> ArrayMesh:
	var mat := ShaderMaterial.new();mat.shader=load("res://world/hartford/city_facade.gdshader")
	mat.set_shader_parameter("brick",load("res://assets/city/quaternius_downtown/textures/T_RedBrick_BaseColor.png"))
	mat.set_shader_parameter("wall_color",Color(PALETTES[kind]))
	mat.set_shader_parameter("family",2 if kind in [5,6] else (4 if kind==4 else (0 if kind in [0,1,10] else 1)))
	mat.set_shader_parameter("bay_width",[2.8,2.6,3.3,3.0,3.8,2.2,2.8,3.4,2.6,2.9,2.5,3.5][kind])
	mat.set_shader_parameter("floor_height",[3.3,3.1,3.8,3.6,4.2,3.5,3.7,3.6,3.1,3.8,3.2,4.0][kind])
	var tool := SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tool.set_material(mat)
	if kind in [5,6,9]:
		cube(tool,Vector3(0,.26,0),Vector3(1,.52,1))
		cube(tool,Vector3(0,.63,0),Vector3(.87,.22,.87))
		cube(tool,Vector3(0,.87,0),Vector3(.70,.26,.70))
	else:
		cube(tool,Vector3(0,.5,0),Vector3.ONE)
		# Real cornice/parapet silhouettes; independent of facade opacity.
		cube(tool,Vector3(0,.98,0),Vector3(1.025,.035,1.025))
		if kind in [2,3,8,11]:
			cube(tool,Vector3(0,.14,0),Vector3(1.018,.018,1.018))
		if kind in [0,4,10]:
			for x in [-.48,0,.48]:cube(tool,Vector3(x,.5,.505),Vector3(.024,.95,.025))
	# Roof plant and service penthouse break up identical flat silhouettes.
	cube(tool,Vector3(-.18,1.025,.12),Vector3(.24,.05,.28))
	cube(tool,Vector3(.24,1.008,-.23),Vector3(.14,.016,.16))
	tool.index();return tool.commit()
func run() -> void:
	for i in range(12): models.append(model(i))
	var city: Node3D=load("res://scenes/hartford_district.tscn").instantiate();city.set_meta("offline_build",true);root.add_child(city)
	city.add_child(load("res://world/eastside/frontage.tscn").instantiate())
	var count:=0;var families: Dictionary={}
	for body: StaticBody3D in city.find_children("*","StaticBody3D",true,false):
		var size:=Vector3.ZERO;var p:=body.global_position
		if body.has_meta("kit_model"):size=body.get_child(0).shape.size-Vector3(0,2,0)
		elif body.get_parent().name=="Buildings" and body.has_meta("height"):
			size=body.get_node("Collision").shape.size;size.y=float(body.get_meta("height"));p.y-=size.y*.5-2
		else:continue
		if size.y>85:size.y=155
		p.y-=.65;size.y+=.65
		var hash_id:=absi(int(p.x*13+p.z*37))
		var kind:int=hash_id%12
		# Neighborhood character: brick and apartments west; civic/office core; warehouses east/south.
		if p.x < -600:kind=[0,1,3,8,10][hash_id%5]
		elif p.x>1000 or p.z>600:kind=[0,4,7,8,10,11][hash_id%6]
		elif size.y>45:kind=[2,3,5,6,7,9][hash_id%6]
		if size.y<20 and kind in [5,6,9]:kind=4
		var key:="%d_%d_%d"%[kind,floori(p.x/160),floori(p.z/160)]
		if not batches.has(key):batches[key]=[kind,[]]
		batches[key][1].append(Transform3D(body.global_basis.scaled_local(size),p))
		families[kind]=families.get(kind,0)+1;count+=1
	var art:=Node3D.new();art.name="CityArchitecture"
	for key in batches:
		var data: Array=batches[key];var node:=MultiMeshInstance3D.new();node.name="Architecture_"+key
		node.multimesh=MultiMesh.new();node.multimesh.transform_format=MultiMesh.TRANSFORM_3D;node.multimesh.mesh=models[data[0]]
		node.set_script(load("res://world/hartford/kit_instances.gd"));node.placements.assign(data[1]);node.set_meta("modern_lod",0)
		node.visibility_range_end=1400;node.visibility_range_end_margin=0;node.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
		art.add_child(node);node.owner=art
	art.set_meta("building_count",count);art.set_meta("families",families)
	var packed:=PackedScene.new();assert(packed.pack(art)==OK)
	assert(ResourceSaver.save(packed,"res://world/hartford/city_architecture.scn",ResourceSaver.FLAG_COMPRESS)==OK)
	print("ARCHITECTURE V2 PASS ",count," lots / ",families.size()," families / closed opaque shells, no overlapping impostors")
	city.free();art.free();quit()
