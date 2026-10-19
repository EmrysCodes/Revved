extends SceneTree
const SMOOTH=preload("res://racing/course_smoothing.gd")
func _initialize() -> void:
	var path:="res://racing/capital_run_route.json"
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	if int(data.get("version",1))>=3:print("Capital course already refined");quit();return
	data=SMOOTH.refine_data(data)
	var output:=FileAccess.open(path,FileAccess.WRITE);output.store_string(JSON.stringify(data));output.close()
	print("CAPITAL REFINED / ",data.points.size()," samples / ",data.checkpoints.size()," checkpoints / ",roundi(data.length),"m")
	quit()
