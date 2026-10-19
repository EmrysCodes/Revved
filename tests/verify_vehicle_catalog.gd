extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var settings:=root.get_node("GameSettings")
	var catalog=load("res://vehicles/vehicle_catalog.gd")
	var car:CharacterBody3D=load("res://vehicles/arcade_car.tscn").instantiate();root.add_child(car)
	var wrapper:Node3D=car.get_node("Visuals/S64Compact")
	for id in range(1,11):
		assert(catalog.available(id),"Downloaded car missing")
		assert(settings.set_vehicle(id,false)==OK)
		var model:Node3D=wrapper.get("_licensed_model")
		assert(model!=null and not wrapper.get_node("Body").visible)
		var geometry:=model.get_node("Geometry")
		var body:Node3D
		for child in geometry.get_children():
			if child is MeshInstance3D:body=child;break
		assert(body!=null)
		var before:=body.transform
		model.update_wheels(.7,5,.1)
		assert(geometry.get_node("FrontLeft").rotation.y< -.3)
		assert(absf(geometry.get_node("RearRight/Spin").rotation.x)>.1)
		assert(body.transform==before,"Wheel animation must preserve original body")
		model.reset_wheels();assert(geometry.get_node("FrontLeft").rotation.is_zero_approx())
		print("PACK_CAR_VERIFIED ",id)
	assert(settings.set_vehicle(0,false)==OK)
	assert(wrapper.get_node("Body").visible and wrapper.get("_licensed_model")==null)
	print("PASS: ten selectable pack cars, independent front steering/all-wheel rolling, unchanged bodies, S64 fallback")
	assert(settings.set_vehicle(11,false)==OK)
	var meshy:Node3D=wrapper.get("_licensed_model")
	assert(meshy.model.get_node("Core").get_aabb().size.x<2.2,"Meshy car width must fit vehicle scale")
	for variant in range(3):
		settings.set_body_parts(variant,variant,variant,false);settings.set_hood(variant,false)
		assert(meshy.model.get_node("FrontBumper_%d"%variant).visible)
		assert(meshy.model.get_node("Hood_%d"%variant).visible)
	meshy.update_wheels(.8,5,.1)
	assert(meshy.pivots[0].rotation.y< -.3 and absf(meshy.pivots[2].get_node("Spin").rotation.x)>.1)
	print("PASS: Meshy scale, modular bumper/hood swaps, steering and rolling")
	quit()

