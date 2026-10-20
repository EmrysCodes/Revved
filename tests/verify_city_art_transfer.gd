extends SceneTree
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)
func collision_snapshot(city: Node3D) -> Array:
	var result := []
	for body: CollisionObject3D in city.find_children("*","CollisionObject3D",true,false):
		if body is CharacterBody3D: continue
		var shapes := []
		for shape: CollisionShape3D in body.find_children("*","CollisionShape3D",true,false):
			shapes.append([shape.shape,shape.global_transform,shape.disabled])
		result.append([body.get_path(),body.global_transform,body.collision_layer,body.collision_mask,shapes])
	return result
func run() -> void:
	var profile := root.get_node("StreetProfile")
	profile.launch_mode = "free"
	var saved := [profile.credits,profile.purchased_tiers.duplicate(),profile.event_results.duplicate(true),profile.driver_name]
	var city: Node3D = load("res://scenes/hartford_district.tscn").instantiate()
	city.set_meta("offline_build",true); root.add_child(city)
	city.add_child(load("res://world/eastside/frontage.tscn").instantiate())
	var before := collision_snapshot(city)
	var roads: Array = [city.map_roads.duplicate(true),city.highway_roads.duplicate(true),city.ramp_roads.duplicate(true)]
	var art := Node3D.new(); art.set_script(load("res://world/hartford/modern_art.gd")); city.add_child(art)
	await process_frame
	check(city.get_meta("modern_city_buildings",0)==2252,"All existing city lots receive detailed architecture")
	check(city.get_meta("modern_city_surfaces",0)>=888,"Real map street and sidewalk materials replaced")
	check(before==collision_snapshot(city),"Every existing static collision shape and transform survives transfer")
	check(roads==[city.map_roads,city.highway_roads,city.ramp_roads],"City, highway and ramp centerlines unchanged")
	var instances := 0; var hidden := 0
	for visual: MultiMeshInstance3D in city.find_children("*","MultiMeshInstance3D",true,false):
		if visual.get_meta("modern_lod",-1)==0: instances += visual.placements.size()
		if visual.multimesh and visual.multimesh.mesh and visual.multimesh.mesh.resource_path.contains("quaternius_downtown/runtime/Building_"):
			hidden += 1; check(not visual.visible,"Old building art hidden")
	check(instances==2252 and hidden>=800,"Replacement batch coverage and removal of old art")
	for label in ["road","sidewalk"]:
		var mat: BaseMaterial3D = load("res://assets/licensed/modern_city_architecture/"+label+".tres")
		check(mat.albedo_texture!=null and mat.normal_texture!=null and mat.uv1_world_triplanar,"Packable PBR "+label)
		check(mat.albedo_texture.resource_path.contains("modern_city_architecture/"),"Runtime independent of street study")
		check(mat.albedo_texture.get_image().has_mipmaps(),"Distance filtering available for "+label)
	var traffic: Node3D = load("res://assets/traffic/kenney/sedan.glb").instantiate()
	var palette_found := false
	for visual: MeshInstance3D in traffic.find_children("*","MeshInstance3D",true,false):
		for index in range(visual.mesh.get_surface_count()):
			var mat: BaseMaterial3D = visual.mesh.surface_get_material(index)
			if mat and mat.resource_name=="colormap": palette_found = mat.albedo_texture!=null
	check(palette_found,"Traffic palette imported correctly"); traffic.free()
	check(saved==[profile.credits,profile.purchased_tiers,profile.event_results,profile.driver_name],"Career identity, progress and purchases preserved")
	var minimap: Control = city.get_node("CityHUD/Screen/Map")
	var original_position: Vector3 = city.car.global_position
	for position in [Vector3(-45,8,250),Vector3(1540,6,400),Vector3(-2150,18,-1700)]:
		city.car.global_position = position; minimap._update_view()
		check(minimap._point(position).distance_to(minimap.map_canvas.size*0.5)<0.01,"Local minimap follows player across districts and map edges")
		check(minimap.map_scale.x==minimap.map_scale.y,"Local map preserves road proportions")
		check(minimap.view_bounds.size.x<=440 and minimap.view_bounds.size.y<=440,"Only nearby streets visible")
		check(not minimap.view_bounds.has_point(Vector2(position.x+1000,position.z)),"Distant city outside minimap")
	check(minimap.map_canvas.clip_contents,"Nearby roads and course line clipped to minimap panel")
	city.car.global_position = original_position
	print("MAIN CITY TRANSFER ","PASS" if failures.is_empty() else "FAIL "+str(failures),": ",before.size()," collision objects preserved; 2252 detailed buildings; unchanged highway and race map")
	city.queue_free(); await process_frame; quit(0 if failures.is_empty() else 1)
