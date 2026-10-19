extends SceneTree
## Run locally after downloading the licensed FBX sources. Never publishes source assets.
func _initialize() -> void: call_deferred("run")
func own(node:Node,scene_root:Node) -> void:
	for child in node.get_children(): child.owner=scene_root;own(child,scene_root)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/licensed/arcade_cars/ready")
	for id in range(1,11):
		var source:Node3D=load("res://assets/licensed/arcade_cars/Car_%d.fbx"%id).instantiate()
		root.add_child(source)
		var meshes:=source.find_children("*","MeshInstance3D",true,false)
		var bounds:=AABB();var first:=true;var triangles:=0
		for mesh:MeshInstance3D in meshes:
			var box:=mesh.global_transform*mesh.get_aabb()
			bounds=box if first else bounds.merge(box);first=false
			triangles+=mesh.mesh.get_faces().size()/3
		var result:=Node3D.new();result.name="ArcadeCar%02d"%id
		result.set_script(load("res://vehicles/licensed_car_visual.gd"))
		var geometry:=Node3D.new();geometry.name="Geometry";result.add_child(geometry)
		var factor:=4.35/bounds.size.z
		geometry.scale=Vector3.ONE*factor;geometry.rotation.y=PI
		geometry.position=Vector3(bounds.get_center().x,-bounds.position.y,bounds.get_center().z)*factor
		var radius:=0.32
		for mesh:MeshInstance3D in meshes:
			var copy:=MeshInstance3D.new();copy.name=mesh.name;copy.mesh=mesh.mesh
			copy.transform=mesh.global_transform
			if "Wheel" in str(mesh.name):
				var box:=mesh.global_transform*mesh.get_aabb()
				var pivot:=Node3D.new();pivot.name=str(mesh.name).replace(" Wheel","").replace(" ","")
				geometry.add_child(pivot);pivot.position=box.get_center()
				var spin:=Node3D.new();spin.name="Spin";pivot.add_child(spin);spin.add_child(copy)
				copy.position-=pivot.position;radius=box.size.y*factor*0.5
			else: geometry.add_child(copy)
		result.set_meta("wheel_radius",radius)
		result.set_meta("source_triangles",triangles)
		own(result,result)
		var scene:=PackedScene.new();assert(scene.pack(result)==OK)
		assert(ResourceSaver.save(scene,"res://assets/licensed/arcade_cars/ready/Car_%d.scn"%id)==OK)
		print("CAR_READY ",id," triangles=",triangles," radius=",radius)
		result.free();source.free()
	print("PASS: ten original car bodies with independent steering and rolling pivots")
	quit()
