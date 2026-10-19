extends RefCounted
## Shared road-course fillets; the optional trim respects narrow ramps.
static func simplify(path:PackedVector3Array,tolerance:=1.5) -> PackedVector3Array:
	if path.size()<3:return path
	var farthest:=0.0;var middle:=0
	for i in range(1,path.size()-1):
		var distance:=path[i].distance_to(Geometry3D.get_closest_point_to_segment(path[i],path[0],path[-1]))
		if distance>farthest:farthest=distance;middle=i
	if farthest<tolerance:return PackedVector3Array([path[0],path[-1]])
	var first:=simplify(path.slice(0,middle+1),tolerance);var second:=simplify(path.slice(middle),tolerance)
	first.append_array(second.slice(1));return first
static func sample_line(output:PackedVector3Array,a:Vector3,b:Vector3) -> void:
	var count:=maxi(1,ceili(a.distance_to(b)/3.5))
	for i in range(1,count+1):output.append(a.lerp(b,float(i)/count))
static func smooth_course(raw:PackedVector3Array,max_trim:=17.0) -> PackedVector3Array:
	var coarse:=simplify(raw)
	var output:=PackedVector3Array([coarse[0]])
	for i in range(1,coarse.size()-1):
		var a:=coarse[i-1];var corner:=coarse[i];var b:=coarse[i+1]
		var trim:=minf(max_trim,minf(a.distance_to(corner)*.32,b.distance_to(corner)*.32))
		var before:=corner+(a-corner).normalized()*trim;var after:=corner+(b-corner).normalized()*trim
		sample_line(output,output[-1],before)
		for j in range(1,9):
			var t:=float(j)/8
			output.append(pow(1-t,3)*before+3*pow(1-t,2)*t*before.lerp(corner,.65)+3*(1-t)*t*t*after.lerp(corner,.65)+pow(t,3)*after)
	sample_line(output,output[-1],coarse[-1])
	return output

static func refine_data(data:Dictionary,max_trim:=8.0,version:=3) -> Dictionary:
	var original:=PackedVector3Array()
	for p:Array in data.points:original.append(Vector3(p[0],p[1],p[2]))
	var route:=smooth_course(original,max_trim)
	var distances:=PackedFloat64Array([0.0])
	for i in range(1,route.size()):distances.append(distances[-1]+route[i-1].distance_to(route[i]))
	var finish_point:Vector3=original[data.finish_index]
	var finish:=0;var nearest:=INF
	for i in range(route.size()):
		if route[i].distance_to(finish_point)<nearest:nearest=route[i].distance_to(finish_point);finish=i
	var old_distances:Array=data.distances
	for section:Dictionary in data.sections:
		for key in ["start","end"]:
			var previous:int=section[key]
			var predicted:int=roundi(float(old_distances[previous])/float(old_distances[-1])*(route.size()-1))
			var index:=predicted;var best:=INF
			for i in range(maxi(0,predicted-100),mini(route.size(),predicted+100)):
				if route[i].distance_to(original[previous])<best:best=route[i].distance_to(original[previous]);index=i
			section[key]=index
	var serial:Array=[]
	for p:Vector3 in route:serial.append([p.x,p.y,p.z])
	data.points=serial;data.distances=Array(distances);data.finish_index=finish;data.length=distances[finish];data.version=version
	data.checkpoints=Array(preload("res://racing/route_guidance.gd").safe_checkpoints(route,distances,finish))
	return data
