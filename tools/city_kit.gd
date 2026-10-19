extends RefCounted
## Shared imported meshes, spatial instance batches and simple vehicle collision.
const ROOT := "res://assets/city/quaternius_downtown/models/"
var city: Node3D
var parent: Node3D
var meshes: Dictionary = {}
var batches: Dictionary = {}
var count := 0
var props := 0
func _init(owner_node: Node3D, target: Node3D) -> void:
	city=owner_node;parent=target
func mesh_for(label: String) -> Mesh:
	if not meshes.has(label):
		var source: Node3D=load(ROOT+label+".gltf").instantiate()
		var visual: MeshInstance3D=source.find_children("*","MeshInstance3D",true,false)[0]
		for i in range(visual.mesh.get_surface_count()):
			var material: StandardMaterial3D=visual.mesh.surface_get_material(i)
			# The source kit uses vertex channels as wear masks, not visible red paint.
			material.vertex_color_use_as_albedo=false
			material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		var folder:="res://assets/city/quaternius_downtown/runtime/"
		DirAccess.make_dir_recursive_absolute(folder)
		var path: String=folder+label+".res"
		assert(ResourceSaver.save(visual.mesh,path,ResourceSaver.FLAG_COMPRESS)==OK)
		meshes[label]=ResourceLoader.load(path,"ArrayMesh",ResourceLoader.CACHE_MODE_IGNORE)
		source.free()
	return meshes[label]
func add(label: String, transform: Transform3D) -> void:
	var key: String="%s_%d_%d"%[label,floori(transform.origin.x/160),floori(transform.origin.z/160)]
	if not batches.has(key):
		batches[key]=[label,[]]
	batches[key][1].append(transform)
func building(point: Vector3, size: Vector3, yaw: float, style: int) -> void:
	var label: String=["Building_Small_1","Building_Medium_2_001","Building_Large_2"][style%3]
	var bounds:=mesh_for(label).get_aabb()
	var scale:=size/bounds.size
	var basis:=Basis(Vector3.UP,yaw).scaled_local(scale)
	var anchor:=bounds.position+Vector3(bounds.size.x*0.5,0,bounds.size.z*0.5)
	add(label,Transform3D(basis,point-basis*anchor))
	var body:=StaticBody3D.new()
	body.name="QuaterniusBuilding_%04d"%count
	body.position=point;body.rotation.y=yaw
	parent.add_child(body,true);body.owner=city
	body.set_meta("kit_model",label)
	body.set_meta("height",size.y)
	var shape:=BoxShape3D.new()
	shape.size=Vector3(size.x,size.y+2,size.z)
	var collision:=CollisionShape3D.new()
	collision.shape=shape;collision.position.y=size.y*0.5-1
	body.add_child(collision);collision.owner=city
	count+=1
func prop(label: String, point: Vector3, yaw:=0.0) -> void:
	add(label,Transform3D(Basis(Vector3.UP,yaw),point))
	props+=1
func flush() -> void:
	for key in batches:
		var batch: Array=batches[key]
		var multi:=MultiMesh.new()
		multi.transform_format=MultiMesh.TRANSFORM_3D
		multi.mesh=mesh_for(batch[0])
		multi.instance_count=batch[1].size()
		for i in range(multi.instance_count):
			multi.set_instance_transform(i,batch[1][i])
		var visual:=MultiMeshInstance3D.new()
		visual.name=key;visual.multimesh=multi
		visual.set_script(load("res://world/hartford/kit_instances.gd"))
		visual.set("placements",Array(batch[1],TYPE_TRANSFORM3D,"",null))
		visual.visibility_range_end=1250 if batch[0].begins_with("Building") else 250
		visual.visibility_range_end_margin=80
		visual.lod_bias=1.5
		parent.add_child(visual,true);visual.owner=city
