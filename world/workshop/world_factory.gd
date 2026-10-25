@tool
extends RefCounted
const CATALOG=preload("res://world/workshop/catalog.gd")
static func create(title:="My REVVED City")->Node3D:
	var world:=Node3D.new();world.name="HandbuiltCity";world.set_script(load("res://world/workshop/handbuilt_world.gd"));world.world_title=title
	world.set_meta("workshop_world",true)
	for group:String in ["Roads","Buildings","Props"]:
		var node:=Node3D.new();node.name=group;world.add_child(node);node.owner=world
		if group=="Roads":node.set_script(load("res://world/workshop/road_network.gd"))
	var ground:=StaticBody3D.new();ground.name="Ground";ground.position.y=-.25;world.add_child(ground);ground.owner=world
	var mesh:=BoxMesh.new();mesh.size=Vector3(512,.5,512)
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("69735a");mat.roughness=1
	if ResourceLoader.exists("res://assets/licensed/modern_city_architecture/grass_albedo.jpg"):
		mat.albedo_texture=load("res://assets/licensed/modern_city_architecture/grass_albedo.jpg");mat.uv1_triplanar=true;mat.uv1_world_triplanar=true;mat.uv1_scale=Vector3.ONE*.3;mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mesh.material=mat
	var visual:=MeshInstance3D.new();visual.name="Surface";visual.mesh=mesh;ground.add_child(visual);visual.owner=world
	var shape:=CollisionShape3D.new();shape.name="Collision";shape.shape=BoxShape3D.new();shape.shape.size=mesh.size;ground.add_child(shape);shape.owner=world
	var start:=Marker3D.new();start.name="PlayerStart";start.position=Vector3(0,.5,16);world.add_child(start);start.owner=world
	var environment:=WorldEnvironment.new();environment.name="NightEnvironment";environment.environment=preload("res://world/night_lighting.gd").environment();world.add_child(environment);environment.owner=world
	var moon:=DirectionalLight3D.new();moon.name="Moon";preload("res://world/night_lighting.gd").moon(moon);world.add_child(moon);moon.owner=world
	return world
static func save(world:Node3D,path:String)->Error:
	var scene:=PackedScene.new();var result:=scene.pack(world)
	return ResourceSaver.save(scene,path) if result==OK else result
