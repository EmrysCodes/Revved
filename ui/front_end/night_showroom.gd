extends RefCounted
## A lightweight preview made from the same runtime city materials as normal play.
static func decorate(world: Node3D, car: Node3D, platform: MeshInstance3D, camera: Camera3D, environment: Environment) -> void:
	environment.background_color = Color("070d18")
	environment.ambient_light_color = Color("9ab8dc"); environment.ambient_light_energy = 0.26
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true; environment.glow_intensity = 0.4
	for child in world.get_children():
		if child is DirectionalLight3D: child.light_energy = 0.24; child.light_color = Color("9fbbe0")
		elif child is OmniLight3D: child.light_color = Color("75d1f0"); child.light_energy = 2.2
	var paint := StandardMaterial3D.new(); paint.albedo_color = Color("141f2b"); paint.metallic = 0.45; paint.roughness = 0.27
	platform.material_override = paint
	var floor := MeshInstance3D.new(); floor.name = "NightStreetFloor"; world.add_child(floor)
	var plane := PlaneMesh.new(); plane.size = Vector2(60,60); floor.mesh = plane; floor.position.y = -0.24
	var road_path := "res://assets/licensed/modern_city_architecture/road.tres"
	floor.material_override = load(road_path) if ResourceLoader.exists(road_path) else paint
	var model_path := "res://assets/licensed/modern_city_architecture/stone_corner_near.res"
	if ResourceLoader.exists(model_path):
		var building := MeshInstance3D.new(); building.mesh = load(model_path); world.add_child(building)
		building.position = Vector3(-12,-0.2,15)
		building.scale = Vector3(22,34,20)/building.mesh.get_aabb().size
		building.rotation.y = PI*0.5
	# Studio strips provide readable contours and long reflections in the paint.
	for side in [-1,1]:
		var lamp := SpotLight3D.new(); world.add_child(lamp)
		lamp.position = Vector3(side*3.2,5.8,-1.5); lamp.look_at(Vector3(0,0.7,0))
		lamp.light_color = Color("dfedff"); lamp.light_energy = 5.0; lamp.spot_range = 15; lamp.spot_angle = 46
		var strip := MeshInstance3D.new(); world.add_child(strip)
		var box := BoxMesh.new(); box.size = Vector3(0.14,0.05,5.0); strip.mesh = box; strip.position = Vector3(side*2.5,4.4,0)
		var glow := StandardMaterial3D.new(); glow.albedo_color = Color("b5d9ee"); glow.emission_enabled = true
		glow.emission = Color("c3e5ff"); glow.emission_energy_multiplier = 2; strip.material_override = glow
	var probe := ReflectionProbe.new(); probe.name = "ShowroomReflections"; world.add_child(probe)
	probe.position = Vector3(0,3,0); probe.size = Vector3(38,20,38); probe.box_projection = true
	probe.cull_mask = 1; probe.intensity = 0.85; probe.enable_shadows = false
	for visual: MeshInstance3D in car.find_children("*","MeshInstance3D",true,false): visual.layers = 2
	camera.cull_mask = 3
