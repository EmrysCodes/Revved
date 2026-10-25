extends Node3D
## Main-city art replacement; road geometry, collision and race coordinates stay intact.
const DIR := "res://assets/licensed/modern_city_architecture/"
var probe: ReflectionProbe
static func available() -> bool: return ResourceLoader.exists(DIR+"city_overlay.scn")
func _ready() -> void:
	name = "ModernCityArt"
	var city := get_parent()
	if not available(): return
	var path := "res://world/hartford/city_architecture.scn" if ResourceLoader.exists("res://world/hartford/city_architecture.scn") else DIR+"city_overlay.scn"
	var art: Node3D = load(path).instantiate(); add_child(art)
	var hidden := 0
	for visual: MultiMeshInstance3D in city.find_children("*","MultiMeshInstance3D",true,false):
		if visual.multimesh and visual.multimesh.mesh and visual.multimesh.mesh.resource_path.contains("quaternius_downtown/runtime/Building_"):
			visual.hide(); hidden += 1
		if OS.has_feature("mobile") and visual.has_meta("modern_lod"):
			if visual.get_meta("modern_lod")==0: visual.visibility_range_end = 700 if art.has_meta("families") else 150
			else: visual.visibility_range_begin = 130
	var legacy := city.get_node_or_null("Buildings")
	if legacy:
		for building in legacy.get_children():
			if not building.has_meta("height"): continue
			for visual: MeshInstance3D in building.find_children("*","MeshInstance3D",true,false): visual.hide()
			var number := str(building.name).trim_prefix("Building_")
			var facade := city.get_node_or_null("Details/Facade_"+number)
			if facade: facade.hide()
	for title in ["TravelersUpperTower","TravelersCrown"]:
		var node := city.get_node_or_null("Landmarks/"+title)
		if node:
			for visual: MeshInstance3D in node.find_children("*","MeshInstance3D",true,false): visual.hide()
	var palette: Texture2D = load("res://assets/traffic/kenney/Textures/colormap.png")
	for visual in city.find_children("*","GeometryInstance3D",true,false):
		var mesh: Mesh = visual.mesh if visual is MeshInstance3D else (visual.multimesh.mesh if visual is MultiMeshInstance3D and visual.multimesh else null)
		if not mesh: continue
		for index in range(mesh.get_surface_count()):
			var material: Material = mesh.surface_get_material(index)
			if material is BaseMaterial3D and material.resource_name.to_lower()=="colormap": material.albedo_texture = palette
	var road: Material = load(DIR+"road.tres").duplicate()
	road.roughness = 0.9; road.metallic = 0.0; road.metallic_texture = null; road.roughness_texture = null; road.normal_scale = 0.3
	var pavement: Material = load(DIR+"sidewalk.tres")
	var surfaces := 0
	for visual: MeshInstance3D in city.find_children("*","MeshInstance3D",true,false):
		if not visual.mesh: continue
		for index in range(visual.mesh.get_surface_count()):
			var old: Material = visual.mesh.surface_get_material(index)
			if not old: continue
			if old.resource_name=="Asphalt": visual.set_surface_override_material(index,road); surfaces += 1
			elif old.resource_name=="Walk": visual.set_surface_override_material(index,pavement); surfaces += 1
			elif old is ShaderMaterial and old.shader and old.shader.resource_path.ends_with("urban_ground.gdshader"):
				var updated: ShaderMaterial = old.duplicate()
				updated.set_shader_parameter("pavement",pavement.albedo_texture); visual.set_surface_override_material(index,updated)
				if ResourceLoader.exists(DIR+"grass_albedo.jpg"):
					updated.set_shader_parameter("grass",load(DIR+"grass_albedo.jpg"))
					updated.set_shader_parameter("detailed_grass",true)
	probe = ReflectionProbe.new(); probe.name = "CityStreetReflections"
	probe.size = Vector3(4700,220,4000); probe.max_distance = 500; probe.box_projection = false
	probe.intensity = 0.28; probe.enable_shadows = false; probe.mesh_lod_threshold = 6
	probe.cull_mask = 1; probe.visible = false; add_child(probe)
	probe.position = city.car.position+Vector3.UP*10
	probe.visible = true
	city.set_meta("modern_city_buildings",art.get_meta("building_count",0))
	city.set_meta("modern_city_surfaces",surfaces)
	call_deferred("exclude_player_from_reflections")
	get_tree().root.get_node("GameSettings").car_style_changed.connect(func():call_deferred("exclude_player_from_reflections"))
	print("MAIN CITY ART ACTIVE: ",art.get_meta("building_count",0)," buildings / ",surfaces," PBR street surfaces / ",hidden," old batches hidden")
func exclude_player_from_reflections() -> void:
	var car: Node3D = get_parent().car
	for mesh: MeshInstance3D in car.get_node("Visuals").find_children("*","MeshInstance3D",true,false): mesh.layers = 2
