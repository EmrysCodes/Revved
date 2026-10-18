extends SceneTree
## Rebuild the editable .tscn blockout: Godot --headless --path . --script res://tools/build_downtown.gd
const GRID := [-420.0, -280.0, -140.0, 0.0, 140.0, 280.0, 420.0]
const Z_HEIGHT := [26.0, 26.0, 20.0, 10.0, 4.0, 0.0, 0.0]
const X_HEIGHT := [6.0, 6.0, 4.0, 0.0, 0.0, 0.0, 0.0]
const ROAD_HALF := 12.0
var city: Node3D
var groups: Dictionary = {}
var mats: Dictionary = {}
var rng := RandomNumberGenerator.new()
var road_map: Array[PackedVector3Array] = []
var highway_map: Array[PackedVector3Array] = []
var ramp_map: Array[PackedVector3Array] = []
var building_count := 0
func _initialize() -> void:
	call_deferred("_build")
func put(node: Node, parent: Node) -> Node:
	parent.add_child(node, true)
	node.owner = city
	return node
func group(label: String) -> Node3D:
	var node := Node3D.new()
	node.name = label
	put(node, city)
	groups[label] = node
	return node
func material(key: String, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.resource_name = key
	mat.albedo_color = color
	mat.roughness = 0.85
	mats[key] = mat
func height_band(value: float, heights: Array) -> float:
	for i in range(6):
		if value <= GRID[i + 1]:
			var weight: float = smoothstep(GRID[i] + 20.0, GRID[i + 1] - 20.0, value)
			return lerpf(heights[i], heights[i + 1], weight)
	return heights[6]
func ground(x: float, z: float) -> float:
	return height_band(x, X_HEIGHT) + height_band(z, Z_HEIGHT)
func highway_y(z: float) -> float:
	return 12.0 + 26.0 * smoothstep(-420.0, 420.0, -z)
func pos(x: float, z: float, lift: float = 0.0) -> Vector3:
	return Vector3(x, ground(x, z) + lift, z)
func box(label: String, center: Vector3, size: Vector3, mat: String, parent: Node, solid := true) -> Node3D:
	var node: Node3D = StaticBody3D.new() if solid else Node3D.new()
	node.name = label
	node.position = center
	put(node, parent)
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var shape := BoxMesh.new()
	shape.size = size
	shape.material = mats[mat]
	mesh.mesh = shape
	put(mesh, node)
	if solid:
		var collision := CollisionShape3D.new()
		collision.name = "Collision"
		var cube := BoxShape3D.new()
		cube.size = size
		collision.shape = cube
		put(collision, node)
	return node
func mesh_body(label: String, mesh: ArrayMesh, parent: Node, solid := true) -> MeshInstance3D:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	body.name = label
	put(body, parent)
	var visual := MeshInstance3D.new()
	visual.name = "Mesh"
	visual.mesh = mesh
	put(visual, body)
	if solid:
		var collision := CollisionShape3D.new()
		collision.name = "Collision"
		collision.shape = mesh.create_trimesh_shape()
		put(collision, body)
	return visual
func tri(builder: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	builder.add_vertex(a)
	builder.add_vertex(b)
	builder.add_vertex(c)
func quad(builder: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, flip := false) -> void:
	if flip:
		tri(builder, a, c, b)
		tri(builder, b, c, d)
	else:
		tri(builder, a, b, c)
		tri(builder, b, d, c)
func terrain_patch(label: String, x0: float, z0: float, x1: float, z1: float, mat: String, lift: float, parent: Node, solid := true) -> void:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	builder.set_material(mats[mat])
	var nx := ceili((x1 - x0) / 10.0)
	var nz := ceili((z1 - z0) / 10.0)
	for x in range(nx):
		for z in range(nz):
			var a := lerpf(x0, x1, float(x) / nx)
			var b := lerpf(x0, x1, float(x + 1) / nx)
			var c := lerpf(z0, z1, float(z) / nz)
			var d := lerpf(z0, z1, float(z + 1) / nz)
			quad(builder, pos(a, d, lift), pos(b, d, lift), pos(a, c, lift), pos(b, c, lift), true)
	builder.generate_normals()
	builder.index()
	mesh_body(label, builder.commit(), parent, solid)
func road(label: String, points: PackedVector3Array, width: float, parent: Node, elevated := false, mat := "Asphalt") -> void:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	builder.set_material(mats[mat])
	var pairs: Array[Vector3] = []
	for i in range(points.size()):
		var tangent: Vector3 = points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]
		var right := tangent.cross(Vector3.UP).normalized()
		for side in [-1.0, 1.0]:
			var point: Vector3 = points[i] + right * side * width * 0.5
			point.y = _road_edge_height(point, points[i], elevated)
			pairs.append(point)
	for i in range(points.size() - 1):
		var a := pairs[i * 2]
		var b := pairs[i * 2 + 1]
		var c := pairs[i * 2 + 2]
		var d := pairs[i * 2 + 3]
		quad(builder, a, b, c, d, true)
		if elevated:
			quad(builder, a - Vector3.UP * 0.5, a, c - Vector3.UP * 0.5, c, true)
			quad(builder, b, b - Vector3.UP * 0.5, d, d - Vector3.UP * 0.5, true)
			quad(builder, b - Vector3.UP * 0.5, a - Vector3.UP * 0.5, d - Vector3.UP * 0.5, c - Vector3.UP * 0.5, true)
	builder.generate_normals()
	builder.index()
	mesh_body(label, builder.commit(), parent)
func _road_edge_height(point: Vector3, center: Vector3, elevated: bool) -> float:
	if not elevated:
		return ground(point.x, point.z)
	var center_ground := ground(center.x, center.z)
	var blend := clampf((center.y - center_ground) / (highway_y(center.z) - center_ground), 0, 1)
	return point.y + lerpf(ground(point.x, point.z) - center_ground, highway_y(point.z) - highway_y(center.z), blend)
func line_points(a: Vector3, b: Vector3, lift := 0.0) -> PackedVector3Array:
	var points := PackedVector3Array()
	var count := ceili(a.distance_to(b) / 6.0)
	for i in range(count + 1):
		var point := a.lerp(b, float(i) / count)
		point.y = ground(point.x, point.z) + lift
		points.append(point)
	return points
func stripe(a: Vector3, b: Vector3, width: float, mat: String, parent: Node) -> void:
	var center := (a + b) * 0.5
	var node := box("Marking", center, Vector3(width, 0.025, a.distance_to(b)), mat, parent, false)
	node.look_at_from_position(center, b, Vector3.UP)
func rail(a: Vector3, b: Vector3, parent: Node) -> void:
	var center := (a + b) * 0.5 + Vector3.UP * 0.6
	var node := box("Guardrail", center, Vector3(0.3, 1.2, a.distance_to(b) + 0.08), "Concrete", parent)
	node.look_at_from_position(center, b + Vector3.UP * 0.6, Vector3.UP)
func label_sign(text: String, position: Vector3, yaw: float, parent: Node, large := false) -> void:
	var sign := Label3D.new()
	sign.name = "Sign"
	sign.text = text
	sign.position = position
	sign.rotation.y = yaw
	sign.font_size = 80 if large else 48
	sign.pixel_size = 0.018 if large else 0.014
	sign.outline_size = 12
	sign.modulate = Color(0.9, 0.97, 1)
	put(sign, parent)
func building(x: float, z: float, sx: float, sz: float, height: float, style: int) -> void:
	building_count += 1
	var y := ground(x, z)
	var base := box("Building_%03d" % building_count, Vector3(x, y + height * 0.5 - 2, z), Vector3(sx, height + 4, sz), "Building%d" % style, groups.Buildings)
	base.set_meta("height", height)
	box("Roof", Vector3(x, y + height + 0.4, z), Vector3(sx + 0.7, 0.8, sz + 0.7), "Concrete", groups.Details, false)
	if height > 38:
		box("Crown", Vector3(x, y + height + 3, z), Vector3(sx * 0.48, 6, sz * 0.55), "Building%d" % style, groups.Details, false)
	# A few continuous facade bands suggest floor scale without hundreds of draw calls.
	var bands := SurfaceTool.new()
	bands.begin(Mesh.PRIMITIVE_TRIANGLES)
	bands.set_material(mats.Window)
	for floor_index in range(1, int(height / 3.8)):
		var yy := y + floor_index * 3.8
		var lx := x - sx / 2 - 0.035
		var rx := x + sx / 2 + 0.035
		var fz := z - sz / 2 - 0.035
		var bz := z + sz / 2 + 0.035
		quad(bands, Vector3(lx, yy, fz), Vector3(rx, yy, fz), Vector3(lx, yy + 1.2, fz), Vector3(rx, yy + 1.2, fz))
		quad(bands, Vector3(rx, yy, bz), Vector3(lx, yy, bz), Vector3(rx, yy + 1.2, bz), Vector3(lx, yy + 1.2, bz))
		quad(bands, Vector3(lx, yy, bz), Vector3(lx, yy, fz), Vector3(lx, yy + 1.2, bz), Vector3(lx, yy + 1.2, fz))
		quad(bands, Vector3(rx, yy, fz), Vector3(rx, yy, bz), Vector3(rx, yy + 1.2, fz), Vector3(rx, yy + 1.2, bz))
	bands.generate_normals()
	mesh_body("Facade_%03d" % building_count, bands.commit(), groups.Details, false)
func _build() -> void:
	rng.seed = 76421
	city = Node3D.new()
	city.name = "DowntownDistrict"
	root.add_child(city)
	for title in ["Terrain", "Streets", "Sidewalks", "Buildings", "Details", "Expressway", "Ramps", "Signs", "Boundaries"]:
		group(title)
	material("Asphalt", Color(0.095, 0.11, 0.13))
	material("Concrete", Color(0.48, 0.5, 0.52))
	material("Walk", Color(0.36, 0.38, 0.39))
	material("Grass", Color(0.19, 0.26, 0.20))
	material("White", Color(0.85, 0.86, 0.8))
	material("Yellow", Color(0.85, 0.64, 0.17))
	material("Window", Color(0.13, 0.23, 0.30))
	material("Building0", Color(0.52, 0.48, 0.43))
	material("Building1", Color(0.36, 0.42, 0.46))
	material("Building2", Color(0.40, 0.29, 0.25))
	material("Building3", Color(0.54, 0.56, 0.55))
	material("GreenSign", Color(0.035, 0.20, 0.14))
	terrain_patch("DistrictGround", -720, -720, 740, 720, "Grass", -0.25, groups.Terrain)
	_build_streets()
	_build_blocks()
	_build_highway()
	_batch_details()
	_build_scene()
	city.set_script(load("res://world/downtown.gd"))
	city.set("map_roads", road_map)
	city.set("highway_roads", highway_map)
	city.set("ramp_roads", ramp_map)
	city.set_meta("building_count", building_count)
	city.set_meta("district_size_m", Vector2(840, 840))
	var packed := PackedScene.new()
	assert(packed.pack(city) == OK)
	assert(ResourceSaver.save(packed, "res://scenes/downtown_district.tscn") == OK)
	print("PASS: authored downtown, ", building_count, " buildings, ", road_map.size(), " street links, 2 carriageways, 4 ramps")
	quit()
func _build_streets() -> void:
	for x in GRID:
		for z in GRID:
			terrain_patch("Junction", x - 12, z - 12, x + 12, z + 12, "Asphalt", 0, groups.Streets)
			# Crosswalks and stop bars leave the intersection center clear.
			for side in [-1, 1]:
				for stripe_index in range(7):
					var offset := -9.0 + stripe_index * 3.0
					box("Crosswalk", pos(x + offset, z + side * 9, 0.018), Vector3(1.3, 0.025, 3.0), "White", groups.Details, false)
					box("Crosswalk", pos(x + side * 9, z + offset, 0.018), Vector3(3.0, 0.025, 1.3), "White", groups.Details, false)
			# Corner signals are placeholders; no traffic rules or NPCs yet.
			for side in [-1, 1]:
				box("SignalPole", pos(x + side * 14.0, z + side * 14.0, 3), Vector3(0.18, 6, 0.18), "Concrete", groups.Details, false)
	for axis in range(2):
		for fixed in GRID:
			for i in range(6):
				var a := Vector3(fixed, 0, GRID[i] + 12) if axis == 0 else Vector3(GRID[i] + 12, 0, fixed)
				var b := Vector3(fixed, 0, GRID[i + 1] - 12) if axis == 0 else Vector3(GRID[i + 1] - 12, 0, fixed)
				var points := line_points(a, b)
				road("Street", points, 24.0, groups.Streets)
				road_map.append(line_points(a - (b - a).normalized() * 12, b + (b - a).normalized() * 12))
				for side in [-1, 1]:
					var normal := (b - a).normalized().cross(Vector3.UP)
					var offset: Vector3 = normal * side * 14.0
					var walk := line_points(a + offset, b + offset, 0.14)
					road("Sidewalk", walk, 4, groups.Sidewalks, false, "Walk")
					# road() grounds surfaces; sidewalk lift is restored below.
					groups.Sidewalks.get_child(-1).position.y = 0.14
				var right := (b - a).normalized().cross(Vector3.UP)
				for j in range(points.size() - 1):
					for side in [-1, 1]:
						stripe(points[j] + right * side * 0.18 + Vector3.UP * 0.03, points[j + 1] + right * side * 0.18 + Vector3.UP * 0.03, 0.12, "Yellow", groups.Details)
						if j % 3 == 0:
							stripe(points[j] + right * side * 3.6 + Vector3.UP * 0.03, points[j + 1] + right * side * 3.6 + Vector3.UP * 0.03, 0.14, "White", groups.Details)
	# An arterial under each end of the diamond links the city to the east frontage.
	for z in [-420.0, 420.0]:
		var points := line_points(Vector3(432, 0, z), Vector3(660, 0, z))
		road("ExpresswayAccess", points, 24, groups.Streets)
		road_map.append(points)
		label_sign("EAST EXPRESSWAY  ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Ãƒâ€šÃ‚Â¢", pos(444, z - 15, 4), -PI / 2, groups.Signs)
	# Close unfinished street edges with visible turnaround space inside the junction.
	for fixed in GRID:
		for side in [-1.0, 1.0]:
			box("StreetEnd", pos(fixed, side * 434, 0.65), Vector3(24, 1.3, 0.5), "Concrete", groups.Boundaries)
			if fixed not in [-420.0, 420.0] or side < 0:
				box("StreetEnd", pos(side * 434, fixed, 0.65), Vector3(0.5, 1.3, 24), "Concrete", groups.Boundaries)
func _build_blocks() -> void:
	for ix in range(6):
		for iz in range(6):
			var x: float = (GRID[ix] + GRID[ix + 1]) / 2
			var z: float = (GRID[iz] + GRID[iz + 1]) / 2
			if Vector2i(ix, iz) in [Vector2i(2, 2), Vector2i(3, 3)]:
				terrain_patch("CivicSquare", x - 52, z - 52, x + 52, z + 52, "Walk", 0.03, groups.Details)
				terrain_patch("Lawn", x - 24, z - 24, x + 24, z + 24, "Grass", 0.05, groups.Details, false)
				box("Monument", pos(x, z, 5), Vector3(8, 10, 8), "Concrete", groups.Buildings)
				for side in [-1, 1]:
					box("Planter", pos(x + side * 35, z, 0.7), Vector3(5, 1.4, 35), "Concrete", groups.Details)
				continue
			if iz == 5 and ix in [1, 4]:
				terrain_patch("ParkingLot", x - 50, z - 50, x + 50, z + 50, "Asphalt", 0.015, groups.Details)
				for row in [-1, 1]:
					for bay in range(12):
						var px := x - 44 + bay * 8
						stripe(pos(px, z + row * 10, 0.035), pos(px, z + row * 25, 0.035), 0.16, "White", groups.Details)
				building(x, z - 38, 45, 18, 8, 2)
				continue
			var central: bool = ix in [2, 3, 4] and iz in [1, 2, 3]
			if central or iz >= 4:
				terrain_patch("BlockCourtyard", x - 53, z - 53, x + 53, z + 53, "Walk", 0.02, groups.Details)
			for dx in [-27.0, 27.0]:
				for dz in [-27.0, 27.0]:
					var h := rng.randf_range(45, 112) if central else rng.randf_range(12, 32)
					if iz == 5:
						h = rng.randf_range(8, 16)
					building(x + dx, z + dz, rng.randf_range(32, 43), rng.randf_range(32, 43), h, rng.randi_range(0, 3))
	# A recognizable tower gives drivers a landmark to navigate toward.
	building(205, -65, 30, 30, 145, 1)
	label_sign("REVVED / CENTRAL", pos(205, -81, 40), PI, groups.Signs, true)
func _build_highway() -> void:
	for x in [530.0, 550.0]:
		var points := line_points(Vector3(x, 0, 660), Vector3(x, 0, -660))
		for index in range(points.size()):
			points[index].y = highway_y(points[index].z)
		road("Southbound" if x == 530 else "Northbound", points, 16, groups.Expressway, true)
		highway_map.append(points)
		for i in range(points.size() - 1):
			var z := (points[i].z + points[i + 1].z) * 0.5
			var outer: float = -8.0 if x == 530 else 8.0
			var inner: float = 8.0 if x == 530 else -8.0
			rail(points[i] + Vector3.RIGHT * inner, points[i + 1] + Vector3.RIGHT * inner, groups.Expressway)
			if absf(z) < 65 or absf(z) > 150:
				rail(points[i] + Vector3.RIGHT * outer, points[i + 1] + Vector3.RIGHT * outer, groups.Expressway)
			if i % 3 == 0:
				stripe(points[i] + Vector3.UP * 0.025, points[i + 1] + Vector3.UP * 0.025, 0.16, "White", groups.Details)
		for z in range(-600, 601, 60):
			if abs(z + 420) < 25 or abs(z - 420) < 25:
				continue
			var height := highway_y(z) - ground(x, z) - 0.5
			box("ViaductPier", pos(x, z, height * 0.5), Vector3(2.2, height, 3), "Concrete", groups.Expressway)
		for side in [-1, 1]:
			box("ExpansionEnd", pos(x, side * 657.0, 12.7), Vector3(16, 1.4, 0.6), "Yellow", groups.Boundaries)
			label_sign("FUTURE DISTRICT\nHIGHWAY ENDS", pos(x, side * 620.0, 17), PI if side < 0 else 0, groups.Signs, true)
	for east in [false, true]:
		for north in [false, true]:
			var start_x: float = 600.0 if east else 480.0
			var end_x: float = 550.0 if east else 530.0
			var side: float = -1.0 if north else 1.0
			var points := PackedVector3Array()
			# Reach the gently graded deck before crossing its edge; 340m approaches.
			for i in range(51):
				var t: float = float(i) / 50
				var shoulder: float = 564.0 if east else 516.0
				var x := lerpf(start_x, shoulder, smoothstep(0.0, 0.75, t)) if t <= 0.75 else lerpf(shoulder, end_x, smoothstep(0.75, 1.0, t))
				var z := side * lerpf(420.0, 80.0, t)
				points.append(Vector3(x, lerpf(ground(x, z), highway_y(z), smoothstep(0.0, 0.72, t)), z))
			road("Ramp_%s_%s" % ["Northbound" if east else "Southbound", "Off" if (east and north) or (not east and not north) else "On"], points, 8, groups.Ramps, true)
			ramp_map.append(points)
			for i in range(2, points.size() - 14):
				var tangent := (points[i + 1] - points[i]).normalized()
				var right := tangent.cross(Vector3.UP).normalized()
				for sign_side in [-1, 1]:
					rail(points[i] + right * sign_side * 4, points[i + 1] + right * sign_side * 4, groups.Ramps)
			label_sign("EXPRESSWAY\nON RAMP" if (east and not north) or (not east and north) else "DOWNTOWN\nEXIT", pos(start_x + 7, side * 400, 4), PI if north else 0, groups.Signs)
	# East frontage joins both surface junctions into a useful local return route.
	var frontage := line_points(Vector3(650, 0, -420), Vector3(650, 0, 420))
	road("EastFrontage", frontage, 18, groups.Streets)
	road_map.append(frontage)
	for z in [-420.0, 420.0]:
		box("FrontageEnd", pos(664, z, 0.65), Vector3(0.5, 1.3, 24), "Concrete", groups.Boundaries)
func _build_scene() -> void:
	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.20, 0.36, 0.52)
	sky_mat.sky_horizon_color = Color(0.72, 0.77, 0.8)
	sky.sky_material = sky_mat
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.76, 0.84, 0.95)
	environment.ambient_light_energy = 0.65
	env.environment = environment
	put(env, city)
	var sun := DirectionalLight3D.new()
	sun.name = "AfternoonSun"
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 220
	put(sun, city)
	var spawn := Node3D.new()
	spawn.name = "VehicleSpawn"
	put(spawn, city)
	var car: CharacterBody3D = load("res://vehicles/arcade_car.tscn").instantiate()
	car.name = "PlayerCar"
	car.position = pos(5, 235, 0.3)
	car.floor_snap_length = 0.65
	car.floor_constant_speed = true
	car.align_to_slopes = true
	put(car, spawn)
	var canvas := CanvasLayer.new()
	canvas.name = "CityHUD"
	put(canvas, city)
	var screen := Control.new()
	screen.name = "Screen"
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	put(screen, canvas)
	var label := Label.new()
	label.name = "Readout"
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	label.offset_left = -510
	label.offset_top = 24
	label.offset_right = -24
	label.offset_bottom = 130
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	put(label, screen)
	var map := Control.new()
	map.name = "Map"
	map.set_script(load("res://world/district_map.gd"))
	map.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	map.offset_left = -250
	map.offset_top = -258
	map.offset_right = -24
	map.offset_bottom = -24
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	put(map, screen)

func _batch_details() -> void:
	# Merge decorative boxes/facade bands by material and block; retain every solid body.
	var builders: Dictionary = {}
	var sources: Array[Node] = []
	for child in groups.Details.get_children():
		if child is StaticBody3D:
			continue
		sources.append(child)
		for mesh: MeshInstance3D in child.find_children("*", "MeshInstance3D", true, false):
			var center: Vector3 = mesh.global_transform * mesh.get_aabb().get_center()
			for surface in range(mesh.mesh.get_surface_count()):
				var mat: Material = mesh.mesh.surface_get_material(surface)
				var key := "%d_%d_%s" % [floori(center.x / 140), floori(center.z / 140), mat.resource_name]
				if not builders.has(key):
					var builder := SurfaceTool.new()
					builder.begin(Mesh.PRIMITIVE_TRIANGLES)
					builder.set_material(mat)
					builders[key] = builder
				builders[key].append_from(mesh.mesh, surface, mesh.global_transform)
	for source in sources:
		source.free()
	for key in builders:
		var mesh := MeshInstance3D.new()
		mesh.name = "Details_" + key
		mesh.mesh = builders[key].commit()
		mesh.visibility_range_end = 750
		put(mesh, groups.Details)
