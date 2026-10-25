extends "res://tests/verify_city_art_transfer.gd"
## Check the new public spaces against the actual city and its static collision.
func run() -> void:
	var city: Node3D = load("res://scenes/hartford_district.tscn").instantiate()
	city.set_meta("offline_build",true); root.add_child(city)
	var before := collision_snapshot(city)
	var roads: Array = [city.map_roads.duplicate(true),city.highway_roads.duplicate(true),city.ramp_roads.duplicate(true)]
	var detail := Node3D.new(); detail.set_script(load("res://world/hartford/downtown_detail.gd")); city.add_child(detail)
	for i in range(3): await physics_frame
	check(city.get_meta("downtown_detail_ready",false),"Detail loaded into real city")
	check(detail.storefronts==12 and detail.crossings>=16,"Storefront and junction coverage")
	check(detail.find_children("*","CollisionObject3D",true,false).is_empty(),"Furnishings leave arcade shortcuts traversable")
	check(before==collision_snapshot(city),"Existing city collision shapes and transforms unchanged")
	check(roads==[city.map_roads,city.highway_roads,city.ramp_roads],"Every city/highway/ramp route unchanged")
	var state := city.get_world_3d().direct_space_state
	for rect: Rect2 in detail.SITES:
		var shape := BoxShape3D.new(); shape.size=Vector3(rect.size.x,5,rect.size.y)
		var p: Vector3 = detail.at(rect.get_center(),3.2)
		var query := PhysicsShapeQueryParameters3D.new(); query.shape=shape; query.transform.origin=p
		query.exclude=[city.car.get_rid()]
		check(state.intersect_shape(query,4).is_empty(),"Public space does not intersect existing building collision at "+str(rect))
		for i in range(city.map_roads.size()):
			var half_width := 4.0
			if i<17:
				var layout: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://world/hartford/layout.json"))
				half_width=float(layout.roads[i].width)*0.5
			for point: Vector3 in city.map_roads[i]:
				check(not rect.grow(half_width).has_point(Vector2(point.x,point.z)),"Public space stays outside road corridor "+str(i))
	var life := Node3D.new(); life.set_script(load("res://world/hartford/city_life.gd"));city.add_child(life)
	for i in range(3):await physics_frame
	for rect: Rect2 in city.get_meta("downtown_reserved_spaces"):
		check(not life.suitable(detail.at(rect.get_center()),13),"Scatter respects authored public spaces and shop entrances")
	check(detail.labels<=48,"Street lettering count bounded")
	print("DOWNTOWN DETAIL ","PASS" if failures.is_empty() else "FAIL "+str(failures))
	city.queue_free(); await process_frame; quit(0 if failures.is_empty() else 1)
