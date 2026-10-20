extends Node3D
## A bounded, driveable art benchmark. Career and saved garage choices are untouched.
const ART := "res://assets/licensed/modern_city_showcase/showcase.scn"
var car: CharacterBody3D
var photo_camera: Camera3D
var hint: Label
var ready_to_drive := false
var lights: Array[Light3D] = []
var showroom := false
var simple_lighting := OS.has_feature("mobile")
var light_timer := 0.0
var walkers: Array[Dictionary] = []

func _ready() -> void:
	if not ResourceLoader.exists(ART):
		push_warning("Night showcase requires the locally licensed Modern City subset.")
		get_tree().call_deferred("change_scene_to_file", "res://ui/front_end/main_menu.tscn"); return
	add_child(load(ART).instantiate())
	build_environment()
	build_lighting()
	build_boundaries()
	car = load("res://vehicles/arcade_car.tscn").instantiate()
	car.name = "ShowcaseCar"
	car.position = Vector3(-72, 0.3, -1.55)
	car.rotation.y = -PI/2
	car.get_node("Visuals/S64Compact").vehicle_override = 5
	add_child(car)
	preload("res://world/showcase/hero_materials.gd").apply(car.get_node("Visuals/S64Compact"))
	# Garage selections belong to the career; this test vehicle has a fixed body.
	var garage_button := car.get_node("PauseMenu/Overlay/Center/Card/Padding/Stack/Garage")
	garage_button.disabled = true; garage_button.text = "Showcase car / fixed visual test"
	car.get_node("CameraArm/FollowCamera").far = 380
	photo_camera = Camera3D.new(); photo_camera.name = "PhotoCamera"; photo_camera.fov = 47; photo_camera.far = 380
	add_child(photo_camera)
	build_interface()
	var ambience := Node3D.new(); ambience.name = "CityAmbience"
	ambience.set_script(load("res://audio/city_ambience.gd")); ambience.profile = 1; ambience.listener = car; add_child(ambience)
	build_walkers()
	await get_tree().physics_frame
	ready_to_drive = true
	print("NIGHT SHOWCASE READY / ",RenderingServer.get_current_rendering_method())

func build_environment() -> void:
	var node := WorldEnvironment.new(); node.name = "WorldEnvironment"; add_child(node)
	var env := preload("res://world/night_lighting.gd").environment()
	env.ambient_light_energy = 0.2
	env.fog_density = 0.0018
	env.fog_light_color = Color("122238")
	env.glow_enabled = true; env.glow_intensity = 0.55; env.glow_bloom = 0.05
	if RenderingServer.get_current_rendering_method() == "forward_plus" and not simple_lighting:
		env.ssao_enabled = true; env.ssao_radius = 0.9; env.ssao_intensity = 1.2
		# Street probes give stable reflections; SSR broke on thin imported signs.
		env.ssr_enabled = false
	node.environment = env
	var moon := DirectionalLight3D.new(); moon.name = "Moonlight"; add_child(moon)
	preload("res://world/night_lighting.gd").moon(moon)
	moon.light_energy = 0.28
	for x in [-65, 0, 65]:
		var probe := ReflectionProbe.new(); probe.name = "StreetReflection%d" % x
		probe.position = Vector3(x, 4.0, 0); probe.size = Vector3(78, 18, 48)
		probe.origin_offset = Vector3(0, -1.5, 0); probe.box_projection = true
		probe.max_distance = 105; probe.intensity = 0.85; probe.enable_shadows = false
		probe.mesh_lod_threshold = 4.0; add_child(probe)

func material(color: Color, emissive := false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new(); result.albedo_color = color
	if emissive:
		result.emission_enabled = true; result.emission = color; result.emission_energy_multiplier = 3.0
	return result

func box(label: String, point: Vector3, size_value: Vector3, mat: Material, solid := false) -> MeshInstance3D:
	var visual := MeshInstance3D.new(); visual.name = label
	var mesh := BoxMesh.new(); mesh.size = size_value; visual.mesh = mesh; visual.material_override = mat
	visual.position = point; add_child(visual)
	if solid:
		var body := StaticBody3D.new(); visual.add_child(body)
		var shape := BoxShape3D.new(); shape.size = size_value
		var collision := CollisionShape3D.new(); collision.shape = shape; body.add_child(collision)
	return visual

func build_lighting() -> void:
	var steel := material(Color("26323b")); steel.metallic = 0.65; steel.roughness = 0.34
	var lens := material(Color("ffe0ac"), true)
	for x in range(-96, 98, 16):
		for side in [-1, 1]:
			var z := float(side)*4.8
			box("LampPost",Vector3(x,2.8,z),Vector3(0.085,5.6,0.085),steel)
			box("LampArm",Vector3(x,5.5,z-side*0.5),Vector3(0.10,0.1,1.1),steel)
			box("LampLens",Vector3(x,5.45,z-side),Vector3(0.38,0.08,0.6),lens)
			var light := SpotLight3D.new(); light.name = "Streetlight"
			light.position = Vector3(x,5.3,z-side); light.rotation_degrees = Vector3(-77,0,0) if side==1 else Vector3(-103,0,0)
			light.light_color = Color("ffd8ab"); light.light_energy = 3.8
			light.spot_range = 18; light.spot_angle = 66; light.spot_attenuation = 0.8
			light.shadow_enabled = not simple_lighting and x in [-80,-64,-48]
			light.set_meta("desktop_shadow", x in [-80,-64,-48])
			add_child(light); lights.append(light)
	for x in range(-88, 95, 19):
		for side in [-1,1]:
			var lamp := OmniLight3D.new(); lamp.name = "ShopfrontLight"
			lamp.position = Vector3(x,2.7,side*7.0)
			lamp.light_color = Color("ffd6a5") if side == 1 else Color("a6dded")
			lamp.light_energy = 1.4; lamp.omni_range = 10; lamp.omni_attenuation = 1.1
			add_child(lamp); lights.append(lamp)
	# Small lights from signs carry color into the bodywork without lighting the sky.
	for x in [-72,-30,25,70]:
		box("AccentLight",Vector3(x,2.7,-6.5),Vector3(1.5,0.07,0.05),material(Color("74d3dc"),true))

func build_boundaries() -> void:
	var concrete := material(Color("66696b"))
	var reflector := material(Color("dca650"),true)
	for x in [-102,103]:
		box("ClosedStreetBarrier",Vector3(x,0.5,0),Vector3(0.6,0.9,7.8),concrete,true)
		for z in [-3,-1,1,3]: box("BarrierReflector",Vector3(x,0.7,z),Vector3(0.62,0.12,0.4),reflector)

func build_interface() -> void:
	var layer := CanvasLayer.new(); layer.name = "ShowcaseInterface"; add_child(layer)
	var margin := MarginContainer.new(); layer.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE); margin.offset_left = 24; margin.offset_top = 18; margin.offset_right = -24
	var stack := VBoxContainer.new(); margin.add_child(stack)
	var title := Label.new(); stack.add_child(title); title.text = "REVVED / NIGHT STREET STUDY"; title.add_theme_font_size_override("font_size",22); title.modulate = Color("f0ca83")
	hint = Label.new(); stack.add_child(hint); hint.text = "WASD / drive   Space / handbrake   Tab / car view   R / reset   Esc / menu"
	hint.add_theme_font_size_override("font_size",14)
	var buttons := HBoxContainer.new(); stack.add_child(buttons)
	var photo := Button.new(); photo.text = "Car view / drive"; buttons.add_child(photo); photo.pressed.connect(toggle_photo)
	var quality := Button.new(); quality.text = "Lighting: mobile" if simple_lighting else "Lighting: desktop"; buttons.add_child(quality)
	quality.pressed.connect(func():
		simple_lighting = not simple_lighting; light_timer = 1.0
		quality.text = "Lighting: mobile" if simple_lighting else "Lighting: desktop"
		for light in lights: light.shadow_enabled = not simple_lighting and light.get_meta("desktop_shadow",false)
		var env: Environment = get_node("WorldEnvironment").environment
		env.ssao_enabled = not simple_lighting and RenderingServer.get_current_rendering_method()=="forward_plus"
		env.ssr_enabled = false)
	var back := Button.new(); back.text = "Main menu"; buttons.add_child(back)
	back.pressed.connect(func(): StreetProfile.main_menu())
	for button: Button in buttons.get_children(): button.custom_minimum_size.y = 42

func build_walkers() -> void:
	for i in range(6):
		var model: Node3D = load("res://assets/people/quaternius/"+["Suit","Casual_2","Casual_Hoodie"][i%3]+".gltf").instantiate()
		add_child(model)
		var side := -1.0 if i%2==0 else 1.0
		walkers.append({"model":model,"start":-91.0+i*21.0,"side":side,"phase":float(i)*0.3})
		var animation: AnimationPlayer = model.find_child("AnimationPlayer",true,false)
		if animation:
			for label in animation.get_animation_list():
				if label.ends_with("Walk"):
					animation.get_animation(label).loop_mode = Animation.LOOP_LINEAR; animation.play(label); break

func toggle_photo() -> void:
	if not ready_to_drive: return
	showroom = not showroom
	car.controls_locked = showroom
	car.get_node("HUD").visible = not showroom
	if showroom:
		car.velocity = Vector3.ZERO; car._speed = 0.0; car._yaw_rate = 0.0
		var position_value := car.global_position
		photo_camera.position = position_value + car.global_basis * Vector3(-5.2,1.8,-6.6)
		photo_camera.look_at(position_value+Vector3.UP*0.8); photo_camera.current = true
	else:
		car.get_node("CameraArm/FollowCamera").current = true

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_TAB:
		toggle_photo(); get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not ready_to_drive: return
	for walker in walkers:
		walker.phase += delta*0.22
		var model: Node3D = walker.model
		model.position = Vector3(walker.start+sin(walker.phase)*5.0,0.19,walker.side*4.1)
		model.rotation.y = -PI/2 if cos(walker.phase)>0 else PI/2
	if car.position.y < -2 or absf(car.position.z)>23:
		car._reset_car()
	light_timer += delta
	if light_timer < 0.3: return
	light_timer = 0.0
	var active_camera := get_viewport().get_camera_3d()
	var origin: Vector3 = active_camera.global_position if active_camera else car.global_position
	var sorted: Array[Light3D] = lights.duplicate()
	sorted.sort_custom(func(a: Light3D,b: Light3D) -> bool: return a.global_position.distance_squared_to(origin)<b.global_position.distance_squared_to(origin))
	for i in range(sorted.size()): sorted[i].visible = i < (8 if simple_lighting else 24)
