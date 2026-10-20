extends Node3D
## Small, reproducible in-engine art studies, not full playable cities.
@export_range(0, 3) var city_index := 0
const TITLES := ["HARTFORD", "HARBORPOINT", "IRONHAVEN", "RIDGEPORT"]
const SUBTITLES := ["RIVER CITY / DOWNTOWN + BRIDGES", "COASTAL CITY / DOCKS + WATERFRONT", "INDUSTRIAL CITY / FOUNDRIES + EXPRESSWAYS", "HILL CITY / TERRACES + CLIMBING STREETS"]
var random := RandomNumberGenerator.new()
var windows: Array[Transform3D] = []
var mats: Dictionary = {}

func mat(key: String, color: Color, emission := false) -> StandardMaterial3D:
	if mats.has(key): return mats[key]
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.76
	if emission:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = 1.3
	mats[key] = result
	return result

func box(label: String, center: Vector3, size: Vector3, material: Material, yaw := 0.0, solid := false) -> MeshInstance3D:
	var mesh := BoxMesh.new(); mesh.size = size
	var visual := MeshInstance3D.new(); visual.name = label
	visual.mesh = mesh; visual.material_override = material
	visual.position = center; visual.rotation.y = yaw; add_child(visual)
	if solid:
		var body := StaticBody3D.new(); visual.add_child(body)
		var shape := CollisionShape3D.new(); var bounds := BoxShape3D.new()
		bounds.size = size; shape.shape = bounds; body.add_child(shape)
	return visual

func road_x(z: float) -> float:
	return sin(z / [95.0, 80.0, 130.0, 48.0][city_index]) * [8.0, 17.0, 5.0, 17.0][city_index]

func height(z: float) -> float:
	return maxf(0.0, -z * 0.115) if city_index == 3 else 0.0

func _ready() -> void:
	random.seed = 6500 + city_index
	var env := WorldEnvironment.new(); env.name = "WorldEnvironment"
	env.environment = preload("res://world/night_lighting.gd").environment(); add_child(env)
	var moon := DirectionalLight3D.new(); preload("res://world/night_lighting.gd").moon(moon); add_child(moon)
	box("Terrain", Vector3(-164 if city_index in [0,1] else 0, -1.0, -120), Vector3(430 if city_index in [0,1] else 750, 1.8, 800), mat("land", Color("25302b")), 0, true)
	var asphalt := mat("asphalt", Color("333a44"))
	asphalt.albedo_texture = load("res://assets/city/quaternius_downtown/textures/T_Concrete_Asphalt_BaseColor.png")
	asphalt.uv1_triplanar = true; asphalt.uv1_world_triplanar = true; asphalt.uv1_scale = Vector3.ONE * 0.18
	var sidewalk := mat("walk", Color("7e8687"))
	var paint := mat("paint", Color("ddd6bb"))
	for z in range(-300, 81, 2):
		var h := height(z); var x := road_x(z)
		var tangent := Vector3(road_x(z-2)-x, height(z-2)-h, -2.0)
		var yaw := atan2(-tangent.x, -tangent.z)
		var road := box("Street", Vector3(x, h, z), Vector3(20, 0.22, 2.5), asphalt, yaw, true)
		road.rotation.x = atan2(tangent.y, 2.0)
		for side in [-1, 1]:
			var walk := box("Sidewalk", Vector3(x+side*12.0, h+0.05, z), Vector3(3.5, 0.2, 2.5), sidewalk, yaw)
			walk.rotation.x = road.rotation.x
		for lane in [-0.18, 0.18]: box("CenterLine", Vector3(x+lane, h+0.125, z), Vector3(0.12,0.018,2.4), mat("yellow", Color("cb9d42")), yaw)
		if posmod(z, 10) < 4:
			for lane in [-5, 5]: box("LanePaint", Vector3(x+lane, h+0.13, z), Vector3(0.12,0.015,2.2), paint, yaw)
	for z in [-45, -130, -215]:
		var h := height(z)
		box("CrossStreet",Vector3(0,h+0.03,z),Vector3(250,0.18,17),asphalt,0,true)
		for stripe in range(9):
			for end in [-12,12]:box("Crosswalk",Vector3(road_x(z)-8+stripe*2,h+0.15,z+end),Vector3(1.1,0.025,3),paint)
	for side in [-1, 1]:
		for row in range(10):
			var z := 20.0-row*30.0
			if row in [2,5,8]: continue
			if city_index == 1 and side == 1: continue
			var size := Vector3(random.randf_range(19,25), random.randf_range(17,46), random.randf_range(21,26))
			if city_index == 2: size.y *= 0.6
			if city_index == 3: size.y *= 0.7
			building(Vector3(road_x(z)+side*(16.0+size.x*0.5),height(z),z),size,row)
			if city_index != 1:
				building(Vector3(road_x(z)+side*(60+size.x*0.5),height(z),z-8),size*Vector3(1.2,1.2,1),row+1)
	for i in range(12):
		var x := (i-6)*25.0
		building(Vector3(x,height(-290),-300-random.randf_range(0,45)),Vector3(21,random.randf_range(40,100),24),i)
	for z in range(-270, 61, 22):
		for side in [-1,1]: streetlamp(Vector3(road_x(z)+side*11.3,height(z),z),side)
	for z in [-8,-72,-162,-246]:
		for side in [-1,1]:
			var p := Vector3(road_x(z)+side*12.5,height(z),z)
			box("BenchSeat",p+Vector3(0,0.6,0),Vector3(0.55,0.14,2),mat("wood",Color("8c6745")))
			box("BenchBack",p+Vector3(side*0.25,0.95,0),Vector3(0.12,0.6,2),mats.wood)
			box("LitterBin",p+Vector3(0,0.45,2.4),Vector3(0.6,0.9,0.6),mat("steel",Color("304853")))
	for z in [-18,-87,-174,-251]:
		for side in [-1,1]:
			var p := Vector3(road_x(z)+side*13.2,height(z),z)
			box("TreeTrunk",p+Vector3.UP*1.8,Vector3(0.25,3.6,0.25),mat("trunk",Color("665444")))
			var crown := SphereMesh.new(); crown.radius = 1.8; crown.height = 4; crown.radial_segments = 12; crown.rings = 6
			var tree := MeshInstance3D.new(); tree.mesh = crown; tree.material_override = mat("leaves",Color("3b593d")); tree.position = p+Vector3.UP*4.4; add_child(tree)
			var walker: Node3D = load("res://assets/people/quaternius/Casual_Hoodie.gltf").instantiate()
			walker.position = p+Vector3(0,0.2,3.5); walker.rotation.y = PI if side == 1 else 0; add_child(walker)
			var animation: AnimationPlayer = walker.find_child("AnimationPlayer",true,false)
			if animation:
				for label in animation.get_animation_list():
					if label.ends_with("Idle"): animation.play(label); break
	if city_index in [0,1]: waterfront()
	if city_index == 2: industrial()
	if city_index == 3: hills()
	flush_windows()
	traffic()
	var camera := Camera3D.new(); camera.name = "ConceptCamera"; camera.far = 1300; camera.fov = 62
	add_child(camera)
	camera.position = [Vector3(18,18,67), Vector3(23,18,67), Vector3(22,23,72), Vector3(14,20,70)][city_index]
	camera.look_at(Vector3(0,15 if city_index == 3 else 8,-105)); camera.current = true
	caption()

func building(point: Vector3, size: Vector3, style: int) -> void:
	var label: String = ["Building_Small_1","Building_Medium_2_001","Building_Large_2"][style%3]
	var source: Mesh = load("res://assets/city/quaternius_downtown/runtime/"+label+".res")
	var bounds := source.get_aabb()
	var visual := MeshInstance3D.new(); visual.mesh = source
	var basis := Basis.IDENTITY.scaled(size/bounds.size)
	var anchor := bounds.position + Vector3(bounds.size.x*0.5,0,bounds.size.z*0.5)
	visual.transform = Transform3D(basis,point-basis*anchor); add_child(visual)
	# Lit panels are real, cheap geometry; no ray tracing or painted-in reflections.
	for face in [-1,1]:
		for floor_index in range(2, int(size.y/3.1)):
			for col in range(1,int(size.z/2.8)):
				if random.randf() > 0.44: continue
				var p := point+Vector3(face*(size.x*0.5+0.035),floor_index*3.1,-size.z*0.5+col*2.8)
				windows.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.025,1.15,1.1)),p))
	if point.z > -200:
		var sign_color: Color = [Color("ffc36c"),Color("6ed9df"),Color("e58169"),Color("8cbbff")][city_index]
		box("ShopCanopy",point+Vector3(0,3.8,size.z*0.5+0.4),Vector3(size.x*0.86,0.28,1.2),mat("sign",sign_color,true))
		var ac: Mesh = load("res://assets/city/quaternius_downtown/runtime/Prop_ACUnit.res")
		var unit := MeshInstance3D.new(); unit.mesh = ac; unit.position = point+Vector3(0,size.y,0); add_child(unit)

func flush_windows() -> void:
	var mesh := BoxMesh.new(); mesh.material = mat("window",Color("a0865f"),true)
	var multi := MultiMesh.new(); multi.transform_format = MultiMesh.TRANSFORM_3D; multi.mesh = mesh; multi.instance_count = windows.size()
	for i in range(windows.size()): multi.set_instance_transform(i,windows[i])
	var visual := MultiMeshInstance3D.new(); visual.multimesh = multi; add_child(visual)

func streetlamp(p: Vector3, side: int) -> void:
	box("LampPost",p+Vector3.UP*4,Vector3(0.13,8,0.13),mat("post",Color("4e565c")))
	box("LampArm",p+Vector3(-side*0.75,7.8,0),Vector3(1.6,0.12,0.12),mats.post)
	box("LampHead",p+Vector3(-side*1.5,7.7,0),Vector3(0.7,0.12,0.45),mat("bulb",Color("ffe1a8"),true))
	if p.z > -155:
		var light := OmniLight3D.new(); light.position = p+Vector3(-side*1.5,7.1,0)
		light.light_color = Color("ffd5a0"); light.light_energy = 2.0; light.omni_range = 24; light.omni_attenuation = 0.8; add_child(light)

func waterfront() -> void:
	box("Water",Vector3(125,-0.35,-140),Vector3(145,0.1,600),mat("water",Color("102e43")))
	box("Quay",Vector3(51,-0.05,-140),Vector3(2,0.5,600),mat("quay",Color("69767d")))
	for z in range(-340,80,8):box("RiversideRail",Vector3(51,0.7,z),Vector3(0.1,1.3,0.1),mats.post)
	box("RailTop",Vector3(51,1.3,-130),Vector3(0.14,0.14,440),mats.post)
	if city_index == 0:
		box("RiverBridge",Vector3(115,13,-150),Vector3(180,1.3,17),mat("bridge",Color("6c737d")),0,true)
		for x in [45,105,165,200]:box("BridgePier",Vector3(x,5.8,-150),Vector3(3,14,10),mats.bridge)
	else:
		for z in [-30,-100,-180]:
			box("Pier",Vector3(90,0.2,z),Vector3(70,0.4,14),mats.quay)
			for stack in range(3):
				box("Cargo",Vector3(63+stack*8,1.5,z),Vector3(6,2.8,6),mat("cargo%d"%stack,[Color("a24735"),Color("2a6470"),Color("9a773a")][stack]))
			box("CraneTower",Vector3(102,14,z),Vector3(1.1,28,1.1),mat("crane",Color("ad8541")))
			box("CraneBoom",Vector3(105,27,z),Vector3(32,0.8,0.8),mats.crane)
			box("CraneCable",Vector3(118,19,z),Vector3(0.05,16,0.05),mats.post)

func industrial() -> void:
	var brick := mat("factory",Color("794b3c"))
	for z in [-65,-155]:
		box("Foundry",Vector3(84,6,z),Vector3(52,12,42),brick,0,true)
		for x in [70,88,103]:
			box("Chimney",Vector3(x,24,z-10),Vector3(3.5,48,3.5),brick)
			box("WarningLight",Vector3(x,48.1,z-10),Vector3(0.5,0.35,0.5),mat("red",Color("ff3e2c"),true))
	box("ElevatedExpressway",Vector3(90,14,-140),Vector3(20,1.2,460),mat("concrete",Color("737a7e")),0,true)
	for z in range(-340,70,35):box("ViaductPier",Vector3(90,6,z),Vector3(3,14,9),mats.concrete)

func hills() -> void:
	for side in [-1,1]:
		for z in range(-300,0,30):
			box("Terrace",Vector3(side*110,height(z)*0.5-0.5,z),Vector3(120,maxf(0.5,height(z)),30),mat("hill",Color("34423c")),0,true)
	box("Skyway",Vector3(0,47,-205),Vector3(300,1.2,12),mat("skyway",Color("6f7f88")),0,true)
	for x in [-115,-70,70,115]:box("SkywayPier",Vector3(x,23,-205),Vector3(2.2,47,5),mats.skyway)

func traffic() -> void:
	for i in range(9):
		var z := 18.0-i*26.0
		var path := "res://assets/licensed/arcade_cars/ready/Car_%d.scn" % (1+i%10)
		if not ResourceLoader.exists(path): path = "res://vehicles/s64_compact_visual.tscn"
		var car: Node3D = load(path).instantiate()
		car.position = Vector3(road_x(z)+(4.5 if i%2 == 0 else -4.5),height(z)+0.15,z)
		car.rotation.y = PI if i%2 == 0 else 0.0; add_child(car)
	var player: Node3D = load("res://vehicles/s64_compact_visual.tscn").instantiate()
	player.position = Vector3(3.7,0.18,24); add_child(player)
	preload("res://world/night_lighting.gd").headlights(player)

func caption() -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	var frame := ColorRect.new(); frame.color = Color(0.02,0.03,0.05,0.94); frame.position = Vector2(30,30); frame.size = Vector2(710,123); layer.add_child(frame)
	var title := Label.new(); title.text = "REVVED  /  "+TITLES[city_index]; title.position = Vector2(50,39); title.add_theme_color_override("font_color",Color("ffcc70")); title.add_theme_font_size_override("font_size",32); layer.add_child(title)
	var sub := Label.new(); sub.text = SUBTITLES[city_index]; sub.position = Vector2(51,83); sub.add_theme_font_size_override("font_size",18); layer.add_child(sub)
	var note := Label.new(); note.text = "GODOT IN-ENGINE STUDY  /  EXISTING ASSETS  /  PERMANENT NIGHT"; note.position = Vector2(51,117); note.add_theme_font_size_override("font_size",13); note.modulate = Color("92a9bc"); layer.add_child(note)
