extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var city: Node3D = load("res://scenes/downtown_district.tscn").instantiate()
	root.add_child(city)
	for frame in range(10):
		await physics_frame
	var car: CharacterBody3D = city.get_node("VehicleSpawn/PlayerCar")
	car.set_physics_process(false)
	assert(city.get_meta("building_count") >= 120)
	assert(city.map_roads.size() == 87 and city.ramp_roads.size() == 4 and city.highway_roads.size() == 2)
	var space := city.get_world_3d().direct_space_state
	var grade := 0.0
	for roads in [city.map_roads, city.highway_roads, city.ramp_roads]:
		for path: PackedVector3Array in roads:
			for sample_index in range(path.size()):
				var point: Vector3 = path[sample_index]
				var tangent := (path[mini(sample_index + 1, path.size() - 1)] - path[maxi(sample_index - 1, 0)]).normalized()
				var sample: Vector3 = point + tangent.cross(Vector3.UP) * 0.13 + tangent * (0.17 if sample_index < path.size() - 1 else -0.17)
				var query := PhysicsRayQueryParameters3D.create(sample + Vector3.UP, sample - Vector3.UP * 1.5)
				query.exclude = [car.get_rid()]
				var hit := space.intersect_ray(query)
				if hit.is_empty() or absf(hit.position.y - point.y) >= 0.07:
					print("MISSING ROAD ", point, " HIT ", hit)
					quit(1)
					return
			for i in range(path.size() - 1):
				var delta := path[i + 1] - path[i]
				grade = maxf(grade, absf(delta.y) / Vector2(delta.x, delta.z).length())
	assert(grade < 0.16, "Street/ramp grades must stay below 16 percent")
	# Surface arterials must remain open beneath both carriageways.
	for z in [-420.0, 420.0]:
		for x in [530.0, 550.0]:
			var query := PhysicsRayQueryParameters3D.create(Vector3(x, 9 if z > 0 else 35, z), Vector3(x, -1 if z > 0 else 25, z))
			query.exclude = [car.get_rid()]
			var hit := space.intersect_ray(query)
			assert(not hit.is_empty() and absf(hit.position.y - (0.0 if z > 0 else 26.0)) < 0.05, "Ground road under viaduct is driveable")
	for index in range(4):
		var path: PackedVector3Array = city.ramp_roads[index]
		# Exercise both descent and ascent with the real controller.
		for reverse in [false, true]:
			var route := path.duplicate()
			var highway: PackedVector3Array = city.highway_roads[0 if index < 2 else 1]
			var beyond: Vector3 = highway_point(highway, route[-1].z - signf(route[-1].z) * 60.0)
			if reverse:
				route.reverse()
				route.insert(0, beyond)
			else:
				route.append(beyond)
			var first := route[0]
			car.global_position = first + Vector3.UP * 0.25
			car.velocity = Vector3.ZERO
			car.rotation.y = atan2(-(route[1].x - first.x), -(route[1].z - first.z))
			car.reset_physics_interpolation()
			for frame in range(20):
				car.call("_step_motion", 1.0 / 60.0, 0.0, 0.0, false, false)
				await physics_frame
			car.top_speed = 12.0
			var target := 1
			var finished := false
			var airborne := 0
			for frame in range(2600):
				while target < route.size() - 1 and Vector2(car.position.x - route[target].x, car.position.z - route[target].z).length() < 9.0:
					target += 1
				var desired: Vector3 = route[target] - car.position
				desired.y = 0
				if target == route.size() - 1 and desired.length() < 5.0:
					finished = true
					break
				var angle := (-car.global_basis.z).signed_angle_to(desired.normalized(), Vector3.UP)
				car.call("_step_motion", 1.0 / 60.0, 1.0, clampf(-angle * 2.2, -1, 1), false, false)
				if not car.is_on_floor():
					airborne += 1
				assert(car.position.y > -1, "Ramp drive must not fall through")
				await physics_frame
			print("Ramp ", index, " reverse ", reverse, " finished ", finished, " at ", car.position, " air frames ", airborne)
			assert(finished, "Real car must traverse entire ramp")
			assert(airborne < 80, "No extended falling or deck clipping")
	car.position = Vector3(5, 0.925, 235)
	car.rotation = Vector3.ZERO
	car.velocity = Vector3.ZERO
	car.top_speed = 22
	car.reset_physics_interpolation()
	var max_pitch := 0.0
	for frame in range(2400):
		car.call("_step_motion", 1.0 / 60.0, 1.0, 0.0, false, false)
		max_pitch = maxf(max_pitch, car.get_node("Visuals").rotation.x)
		await physics_frame
		if car.position.z < -400:
			break
	assert(car.position.z < -400 and car.position.y > 25, "Drive from market to upper terrace")
	assert(max_pitch > 0.08, "Car presentation follows street inclines")
	var menu: CanvasLayer = car.get_node("PauseMenu")
	menu.open_menu()
	menu.call("_open_garage")
	assert(paused and menu.get_node("Garage").visible, "Garage works in the district")
	menu.close_menu()
	for resolution in [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(2560, 1080)]:
		root.size = resolution
		for frame in range(3):
			await process_frame
		assert(root.get_visible_rect().encloses(city.get_node("CityHUD/Screen/Map").get_global_rect()), "District map fits supported screens")
	print("PASS: street collision continuity, grade ", grade, ", underpass clearance, 8 real ramp traversals, building population and road network")
	quit()

func highway_point(path: PackedVector3Array, z: float) -> Vector3:
	for i in range(path.size() - 1):
		if z <= path[i].z and z >= path[i + 1].z:
			return path[i].lerp(path[i + 1], (z - path[i].z) / (path[i + 1].z - path[i].z))
	return path[0]
