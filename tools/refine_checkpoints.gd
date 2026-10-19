extends SceneTree
func _initialize() -> void:
	var file:="res://racing/capital_run_route.json"
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(file))
	var path:=PackedVector3Array()
	for p in data.points:path.append(Vector3(p[0],p[1],p[2]))
	var gates=preload("res://racing/route_guidance.gd").safe_checkpoints(path,PackedFloat64Array(data.distances),data.finish_index)
	data.checkpoints=Array(gates)
	data.checkpoint_policy="Along-road gates approximately 190m apart and after turns, away from intersection centers."
	var output:=FileAccess.open(file,FileAccess.WRITE);output.store_string(JSON.stringify(data));output.close()
	print("PASS: refined ",gates.size()," Capital Run gates, finish retained")
	quit()
