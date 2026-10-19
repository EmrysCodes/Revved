extends SceneTree
func _initialize() -> void:
	var city: Node3D=load("res://scenes/hartford_district.tscn").instantiate()
	var data: Dictionary={"roads":[],"highways":[],"ramps":[],"water":[]}
	for key in ["roads","highways","ramps"]:
		var paths: Array=city.get({"roads":"map_roads","highways":"highway_roads","ramps":"ramp_roads"}[key])
		for path: PackedVector3Array in paths:
			var points: Array=[]
			for p in path: points.append([snappedf(p.x,0.1),snappedf(p.z,0.1)])
			data[key].append(points)
	for p: Vector3 in city.get_meta("water_map"): data.water.append([p.x,p.z])
	var file:=FileAccess.open("res://ui/legacy/city_map.json",FileAccess.WRITE);file.store_string(JSON.stringify(data))
	city.free();print("PASS: lightweight career map exported");quit()
