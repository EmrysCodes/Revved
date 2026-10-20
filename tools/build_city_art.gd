extends SceneTree
## Bake reusable Modern City architecture and distant impostors for the real map.
const DIR := "res://assets/licensed/modern_city_architecture/"
const KINDS := ["stone_corner","modern_office","retail_a","retail_b","tower"]
var models: Dictionary = {}
var batches: Dictionary = {}
var overlay: Node3D
var count := 0
func _initialize() -> void: call_deferred("run")
func fix_material(original: Material) -> Material:
	var mat: Material = original.duplicate()
	if mat is BaseMaterial3D:
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		if mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			var title := mat.resource_name.to_lower()
			if title.contains("leaves") or title.contains("branches") or title.contains("fence"):
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR; mat.alpha_scissor_threshold = 0.35
			else:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				if not title.contains("glass"):
					mat.grow = true; mat.grow_amount = 0.003
	return mat
func prepare(kind: String) -> ArrayMesh:
	var source: Node3D = load(DIR+kind+".gltf").instantiate(); root.add_child(source)
	var imports: Array[ImporterMesh] = []; var transforms: Array[Transform3D] = []
	for visual: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
		imports.append(ImporterMesh.from_mesh(visual.mesh)); transforms.append(visual.global_transform)
	var merged := ImporterMesh.merge_importer_meshes(imports,transforms,true)
	var original := merged.get_mesh(); var bounds := original.get_aabb()
	var anchor := Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
	var normalized := ImporterMesh.new()
	for surface in range(original.get_surface_count()):
		var arrays := original.surface_get_arrays(surface)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in range(points.size()): points[i] -= anchor
		arrays[Mesh.ARRAY_VERTEX] = points
		normalized.add_surface(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},fix_material(original.surface_get_material(surface)))
	normalized.generate_lods(35,60,[])
	var near := ArrayMesh.new(); var total := 0
	for surface in range(normalized.get_surface_count()):
		var arrays := normalized.get_surface_arrays(surface)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var target := maxi(120,int(indices.size()*0.3))
		for level in range(normalized.get_surface_lod_count(surface)):
			var candidate := normalized.get_surface_lod_indices(surface,level)
			if candidate.size()<indices.size(): indices = candidate
			if indices.size()<=target: break
		arrays[Mesh.ARRAY_INDEX] = indices; total += indices.size()/3
		var temporary := ArrayMesh.new(); temporary.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var tool := SurfaceTool.new(); tool.create_from(temporary,0); tool.deindex(); tool.index(); tool.commit(near)
		near.surface_set_material(near.get_surface_count()-1,normalized.get_surface_material(surface))
	assert(ResourceSaver.save(near,DIR+kind+"_near.res",ResourceSaver.FLAG_COMPRESS)==OK)
	print("CITY MODEL ",kind," triangles=",total," size=",near.get_aabb().size)
	source.free(); return near

func proxy(mesh: ArrayMesh,kind: String) -> ArrayMesh:
	var viewport := SubViewport.new(); viewport.size = Vector2i(256,256); viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.transparent_bg = true; viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS; root.add_child(viewport)
	var stage := Node3D.new(); viewport.add_child(stage)
	var model := MeshInstance3D.new(); model.mesh = mesh; stage.add_child(model)
	var env := WorldEnvironment.new(); stage.add_child(env)
	env.environment = preload("res://world/night_lighting.gd").environment(); env.environment.fog_enabled = false
	env.environment.ambient_light_energy = 0.38
	var moon := DirectionalLight3D.new(); stage.add_child(moon); preload("res://world/night_lighting.gd").moon(moon); moon.light_energy = 0.45
	var camera := Camera3D.new(); stage.add_child(camera); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.current = true
	var size := mesh.get_aabb().size; camera.size = size.y*1.005; camera.far = 2000
	var center := Vector3(0,size.y*0.5,0)
	var atlas := Image.create(1024,256,false,Image.FORMAT_RGBA8)
	var directions := [Vector3(0,0,1),Vector3(1,0,0),Vector3(0,0,-1),Vector3(-1,0,0)]
	for side in range(4):
		viewport.size = Vector2i(maxi(16,roundi(256*(size.x if side%2==0 else size.z)/size.y)),256)
		camera.position = center+directions[side]*size.length()*2.0; camera.look_at(center)
		for i in range(3): await process_frame
		await RenderingServer.frame_post_draw
		var image := viewport.get_texture().get_image(); image.convert(Image.FORMAT_RGBA8); image.resize(256,256,Image.INTERPOLATE_LANCZOS)
		atlas.blit_rect(image,Rect2i(0,0,256,256),Vector2i(side*256,0))
	atlas.generate_mipmaps()
	var mat := StandardMaterial3D.new(); mat.albedo_texture = ImageTexture.create_from_image(atlas)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR; mat.alpha_scissor_threshold = 0.2
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var builder := SurfaceTool.new(); builder.begin(Mesh.PRIMITIVE_TRIANGLES); builder.set_material(mat)
	var x := size.x*0.5; var z := size.z*0.5; var h := size.y
	var faces := [[Vector3(-x,0,z),Vector3(x,0,z),Vector3(-x,h,z),Vector3(x,h,z)], [Vector3(x,0,z),Vector3(x,0,-z),Vector3(x,h,z),Vector3(x,h,-z)], [Vector3(x,0,-z),Vector3(-x,0,-z),Vector3(x,h,-z),Vector3(-x,h,-z)], [Vector3(-x,0,-z),Vector3(-x,0,z),Vector3(-x,h,-z),Vector3(-x,h,z)]]
	for side in range(4):
		var uv := [Vector2(side*0.25,1),Vector2((side+1)*0.25,1),Vector2(side*0.25,0),Vector2((side+1)*0.25,0)]
		for index in [0,2,1,1,2,3]: builder.set_uv(uv[index]); builder.add_vertex(faces[side][index])
	builder.generate_normals(); builder.index(); var output := builder.commit()
	assert(ResourceSaver.save(output,DIR+kind+"_far.res",ResourceSaver.FLAG_COMPRESS)==OK)
	viewport.queue_free(); await process_frame; return output

func batch(kind: String, transform: Transform3D) -> void:
	var p := transform.origin
	var key := "%s_%d_%d"%[kind,floori(p.x/100),floori(p.z/100)]
	if not batches.has(key): batches[key] = [kind,[]]
	batches[key][1].append(transform)

func run() -> void:
	AudioServer.set_bus_mute(0,true)
	for kind: String in KINDS:
		var mesh: ArrayMesh
		var distant: ArrayMesh
		if ResourceLoader.exists(DIR+kind+"_near.res") and ResourceLoader.exists(DIR+kind+"_far.res"):
			mesh = load(DIR+kind+"_near.res"); distant = load(DIR+kind+"_far.res")
			if "--refresh-materials" in OS.get_cmdline_user_args():
				for index in range(mesh.get_surface_count()): mesh.surface_set_material(index,fix_material(mesh.surface_get_material(index)))
				assert(ResourceSaver.save(mesh,DIR+kind+"_near.res",ResourceSaver.FLAG_COMPRESS)==OK)
				distant = await proxy(mesh,kind)
		else:
			mesh = prepare(kind); distant = await proxy(mesh,kind)
		models[kind] = [mesh,distant]
	var source: Node3D = load("res://scenes/hartford_district.tscn").instantiate(); source.set_meta("offline_build",true); source.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF; root.add_child(source)
	source.add_child(load("res://world/eastside/frontage.tscn").instantiate())
	overlay = Node3D.new(); overlay.name = "ModernArchitecture"
	for body: StaticBody3D in source.find_children("*","StaticBody3D",true,false):
		var size := Vector3.ZERO
		var point := body.global_position
		if body.has_meta("kit_model"):
			var collider: CollisionShape3D = body.get_child(0)
			size = collider.shape.size-Vector3(0,2,0)
		elif body.get_parent().name=="Buildings" and body.has_meta("height"):
			var height: float = body.get_meta("height")
			var collider: CollisionShape3D = body.get_node("Collision")
			size = collider.shape.size; size.y = height
			point.y -= height*0.5-2.0
			if height>85: size.y = 155
		else: continue
		var kind: String = KINDS[count%4]
		if size.y>85: kind = "tower"
		elif size.y<22: kind = "retail_a" if count%2==0 else "retail_b"
		var bounds: AABB = models[kind][0].get_aabb()
		var basis := body.global_basis.scaled_local(size/bounds.size)
		batch(kind,Transform3D(basis,point)); count += 1
	for key in batches:
		var data: Array = batches[key]
		for level in range(2):
			var node := MultiMeshInstance3D.new(); node.name = key+("_near" if level==0 else "_far")
			var multi := MultiMesh.new(); multi.transform_format = MultiMesh.TRANSFORM_3D; multi.mesh = models[data[0]][level]
			node.multimesh = multi; node.set_script(load("res://world/hartford/kit_instances.gd")); node.placements.assign(data[1])
			node.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
			node.visibility_range_end = 235 if level==0 else 1500; node.visibility_range_end_margin = 15
			node.visibility_range_begin = 0 if level==0 else 205; node.visibility_range_begin_margin = 15
			if level==1: node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			node.set_meta("modern_lod",level); overlay.add_child(node); node.owner = overlay
	overlay.set_meta("building_count",count)
	var packed := PackedScene.new(); assert(packed.pack(overlay)==OK)
	assert(ResourceSaver.save(packed,DIR+"city_overlay.scn",ResourceSaver.FLAG_COMPRESS)==OK)
	# Street textures are prepared independently of the separate art study.
	assert(ResourceLoader.exists(DIR+"road.tres") and ResourceLoader.exists(DIR+"sidewalk.tres"),"Run prepare_city_materials.py and import its textures")
	source.free(); overlay.free()
	print("MAIN CITY ART BUILD PASS: ",count," existing building footprints replaced; road/collision layout unchanged")
	quit()
