extends Node3D
## Permanent night. Nearby lamp pools are reused instead of thousands of live lights.
const SKY_TOP := Color("020610")
const SKY_HORIZON := Color("142239")
var lamp_positions := PackedVector3Array()
var pools: Array[OmniLight3D] = []
var clock := 0.0

static func environment() -> Environment:
	var result := Environment.new()
	result.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var material := ProceduralSkyMaterial.new()
	material.sky_top_color = SKY_TOP
	material.sky_horizon_color = SKY_HORIZON
	material.ground_bottom_color = SKY_TOP
	material.ground_horizon_color = SKY_HORIZON
	material.sun_curve = 0.0
	sky.sky_material = material
	result.sky = sky
	result.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	result.ambient_light_color = Color("91a9d1")
	result.ambient_light_energy = 0.48
	result.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	result.fog_enabled = true
	result.fog_light_color = Color("172238")
	result.fog_light_energy = 0.5
	result.fog_density = 0.00045
	return result

static func moon(light: DirectionalLight3D) -> void:
	light.light_color = Color("a6bce6")
	light.light_energy = 0.42
	light.rotation_degrees = Vector3(-38, -32, 0)
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 160

func _ready() -> void:
	name = "PermanentNight"
	var world := get_parent()
	var env: WorldEnvironment = world.get_node_or_null("WorldEnvironment")
	if env: env.environment = environment()
	var detailed := preload("res://world/hartford/modern_art.gd").available()
	if detailed and env:
		env.environment.ambient_light_energy = 0.2
		env.environment.fog_density = 0.0013
		env.environment.glow_enabled = true; env.environment.glow_intensity = 0.5; env.environment.glow_bloom = 0.04
		env.environment.ssao_enabled = RenderingServer.get_current_rendering_method()=="forward_plus" and not OS.has_feature("mobile")
	for child in world.get_children():
		if child is DirectionalLight3D:
			moon(child)
			if detailed: child.light_energy = 0.28
	for i in range(6 if OS.has_feature("mobile") else 12):
		var pool := OmniLight3D.new()
		pool.name = "StreetlightPool%02d" % i
		pool.light_color = Color("ffd59a")
		pool.light_energy = 3.0 if detailed else 2.0
		pool.omni_range = 32.0 if detailed else 23.0
		pool.omni_attenuation = 0.8
		pool.shadow_enabled = false
		pool.visible = false
		add_child(pool)
		pools.append(pool)

func _process(delta: float) -> void:
	clock += delta
	if clock < 0.35: return
	clock = 0.0
	var life := get_parent().get_node_or_null("CityLife")
	if life and lamp_positions.is_empty(): lamp_positions = life.lamp_positions
	var camera := get_viewport().get_camera_3d()
	if not camera: return
	var origin := camera.global_position
	var candidates: Array[Vector3] = []
	for point in lamp_positions:
		if point.distance_squared_to(origin) < 140.0 * 140.0: candidates.append(point)
	candidates.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.distance_squared_to(origin) < b.distance_squared_to(origin))
	for i in range(pools.size()):
		pools[i].visible = i < candidates.size()
		if pools[i].visible: pools[i].global_position = candidates[i] - Vector3.UP * 0.6

static func headlights(car: Node3D) -> void:
	var rig := Node3D.new()
	rig.name = "NightHeadlights"
	car.add_child(rig)
	# CharacterBody drives toward local -Z; beam pitch keeps the road lit ahead.
	for side in [-0.62, 0.62]:
		var lamp := SpotLight3D.new()
		lamp.position = Vector3(side, 0.72, -1.85)
		lamp.rotation_degrees.x = -5
		lamp.light_color = Color("e6efff")
		lamp.light_energy = 3.0
		lamp.spot_range = 62.0
		lamp.spot_angle = 30.0
		lamp.spot_attenuation = 0.65
		lamp.shadow_enabled = false
		rig.add_child(lamp)
