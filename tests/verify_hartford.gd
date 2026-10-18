extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var city: Node3D=load("res://scenes/hartford_district.tscn").instantiate()
	root.add_child(city)
	for frame in range(10):
		await physics_frame
	var car: CharacterBody3D=city.get_node("VehicleSpawn/PlayerCar")
	car.set_physics_process(false)
	var space:=city.get_world_3d().direct_space_state
	var problems:=0
	for group in [city.map_roads,city.highway_roads,city.ramp_roads]:
		for path_index in range(group.size()):
			var path: PackedVector3Array=group[path_index]
			for i in range(1,path.size()-1):
				var point:=path[i]
				var tangent: Vector3=(path[i+1]-path[i-1]).normalized()
				var sample:=point+tangent.cross(Vector3.UP)*0.11+tangent*0.07
				var query:=PhysicsRayQueryParameters3D.create(sample+Vector3.UP*0.7,sample-Vector3.UP*0.3)
				query.exclude=[car.get_rid()]
				var hit:=space.intersect_ray(query)
				if hit.is_empty() or absf(hit.position.y-point.y)>0.12 or hit.collider.get_parent().name=="Terrain":
					if problems<24:
						print("SURFACE ",path_index," ",point," ",hit)
					problems+=1
				var block_query:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.9,path[i+1]+Vector3.UP*0.9)
				block_query.exclude=[car.get_rid()]
				var block:=space.intersect_ray(block_query)
				if not block.is_empty():
					if problems<24:
						print("BLOCKED ",path_index," ",point," ",block.collider.get_path()," at ",block.position)
					problems+=1
	print("ROAD PROBLEMS ",problems)
	assert(problems==0,"Roads and ramps must have continuous clear driving corridors")
	var panes: Array[Node]=city.get_node("Shortcuts").find_children("*","Area3D",true,false)
	assert(panes.size()==city.get_meta("glass_locations").size()*2 and panes.size()>0,"Two fronts per glass arcade")
	assert(city.get_meta("building_count")>1000,"Dense building infill")
	assert(city.get_meta("infill_routes").size()>100 and city.get_meta("alley_count")>50,"Connected neighborhood streets and alleys")
	panes[0].call("_entered",car)
	assert(panes[0].get("broken") and not panes[0].get_node("Pane").visible)
	car.call("_reset_car")
	assert(not panes[0].get("broken") and panes[0].get_node("Pane").visible,"Reset restores shortcut glass")
	car.position.y=-3
	city.call("_physics_process",0.0)
	assert(car.position.y>0,"Water returns car to safe spawn")
	var menu: CanvasLayer=car.get_node("PauseMenu")
	menu.open_menu()
	menu.call("_open_garage")
	assert(paused and menu.get_node("Garage").visible,"Garage works in Hartford scene")
	menu.close_menu()
	for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1080)]:
		root.size=resolution
		for frame in range(3):
			await process_frame
		assert(root.get_visible_rect().encloses(city.get_node("CityHUD/Screen/Map").get_global_rect()))
	print("PASS: Hartford road/bridge/ramp collision probes, glass restore, water recovery, garage and map bounds")
	quit()
