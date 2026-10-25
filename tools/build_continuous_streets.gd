extends SceneTree
func _initialize() -> void:call_deferred("run")
func ground(x:float,z:float)->float:
	var land:=4+16*(1-smoothstep(-1700,500,x))+2*sin(z/750)
	return lerpf(-5,land,smoothstep(72,112,absf(x-(730+35*sin(z/800)))))
func run() -> void:
	var mat:=ShaderMaterial.new();mat.shader=load("res://world/hartford/street_surface.gdshader")
	mat.set_shader_parameter("coverage",load("res://world/hartford/street_coverage.png"))
	var road: BaseMaterial3D=load("res://assets/licensed/modern_city_architecture/road.tres")
	var walk: BaseMaterial3D=load("res://assets/licensed/modern_city_architecture/sidewalk.tres")
	mat.set_shader_parameter("asphalt",road.albedo_texture);mat.set_shader_parameter("pavement",walk.albedo_texture)
	mat.set_shader_parameter("grass",load("res://assets/licensed/modern_city_architecture/grass_albedo.jpg"))
	var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tool.set_material(mat)
	for x in range(-2250,2250,10):
		for z in range(-1900,1900,10):
			for p: Vector2 in [Vector2(x,z),Vector2(x+10,z),Vector2(x+10,z+10),Vector2(x,z),Vector2(x+10,z+10),Vector2(x,z+10)]:
				tool.add_vertex(Vector3(p.x,ground(p.x,p.y),p.y))
	tool.generate_normals();tool.index();var mesh:=tool.commit()
	var body:=StaticBody3D.new();body.name="ContinuousStreets";body.set_script(load("res://world/hartford/street_surface.gd"))
	var visual:=MeshInstance3D.new();visual.mesh=mesh;body.add_child(visual);visual.owner=body
	visual.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	var collision:=CollisionShape3D.new();collision.shape=mesh.create_trimesh_shape();body.add_child(collision);collision.owner=body
	var packed:=PackedScene.new();assert(packed.pack(body)==OK)
	assert(ResourceSaver.save(packed,"res://world/hartford/continuous_streets.scn",ResourceSaver.FLAG_COMPRESS)==OK)
	body.free();print("CONTINUOUS STREET BUILD PASS: joined surface + collision");quit()
