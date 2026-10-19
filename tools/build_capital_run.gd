extends SceneTree
## Curate a sprint from the built city's real road paths, not straight waypoint jumps.
var city: Node3D
var points: Array[Vector3]=[]
var neighbors: Array=[]
var buckets: Dictionary={}
var heap: Array=[]
var course:=PackedVector3Array()
var sections: Array=[]
func _initialize() -> void:
	call_deferred("_run")
func _bucket(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x/8),floori(p.z/8))
func _index_roads() -> void:
	for path: PackedVector3Array in city.map_roads:
		var previous: int=-1
		for p in path:
			var index:=points.size()
			points.append(p);neighbors.append([])
			if previous>=0:
				neighbors[index].append(previous);neighbors[previous].append(index)
			var cell:=_bucket(p)
			for x in range(-1,2):
				for z in range(-1,2):
					for other: int in buckets.get(cell+Vector2i(x,z),[]):
						if absf(points[other].y-p.y)<0.6 and Vector2(points[other].x-p.x,points[other].z-p.z).length()<7:
							neighbors[index].append(other);neighbors[other].append(index)
			if not buckets.has(cell):
				buckets[cell]=[]
			buckets[cell].append(index);previous=index
func nearest(path: PackedVector3Array,p: Vector3) -> int:
	var best:=INF
	var result:=0
	for i in range(path.size()):
		var distance:=Vector2(path[i].x-p.x,path[i].z-p.z).length()
		if distance<best:
			best=distance;result=i
	return result
func _push(value: Vector2) -> void:
	heap.append(value)
	var i:=heap.size()-1
	while i>0:
		var parent: int=(i-1)/2
		if heap[parent].x<=value.x:
			break
		heap[i]=heap[parent];i=parent
	heap[i]=value
func _pop() -> Vector2:
	var result: Vector2=heap[0]
	var last: Vector2=heap.pop_back()
	if heap.is_empty():
		return result
	var i:=0
	while i*2+1<heap.size():
		var child:=i*2+1
		if child+1<heap.size() and heap[child+1].x<heap[child].x:
			child+=1
		if last.x<=heap[child].x:
			break
		heap[i]=heap[child];i=child
	heap[i]=last
	return result
func local_route(a: Vector3,b: Vector3) -> PackedVector3Array:
	var all:=PackedVector3Array(points)
	var start:=nearest(all,a)
	var goal:=nearest(all,b)
	var distances:=PackedFloat64Array();distances.resize(points.size());distances.fill(INF)
	var previous:=PackedInt32Array();previous.resize(points.size());previous.fill(-1)
	var visited:=PackedByteArray();visited.resize(points.size())
	distances[start]=0;heap.clear();_push(Vector2(0,start))
	while not heap.is_empty():
		var current:=int(_pop().y)
		if visited[current]:
			continue
		visited[current]=1
		if current==goal:
			break
		for next: int in neighbors[current]:
			var candidate:=distances[current]+points[current].distance_to(points[next])
			if candidate<distances[next]:
				distances[next]=candidate;previous[next]=current
				_push(Vector2(candidate+points[next].distance_to(points[goal]),next))
	assert(is_finite(distances[goal]),"Curated surface-road connection must exist")
	var route:=PackedVector3Array()
	var current:=goal
	while current!=-1:
		route.append(points[current]);current=previous[current]
	route.reverse()
	return route
func append_section(path: PackedVector3Array,label: String) -> void:
	var start:=course.size()
	if not course.is_empty():
		assert(course[-1].distance_to(path[0])<14,"Route sections must physically join: "+label)
	for p in path:
		if course.is_empty() or course[-1].distance_to(p)>0.1:
			course.append(p)
	sections.append({"label":label,"start":start,"end":course.size()-1})
func highway_section(label: String,a: Vector3,b: Vector3) -> PackedVector3Array:
	var named: Dictionary=city.get_meta("named_routes")
	for suffix in ["_Forward","_Reverse"]:
		var path: PackedVector3Array=named[label+suffix]
		var first:=nearest(path,a);var last:=nearest(path,b)
		if last>first and path[first].distance_to(a)<20 and path[last].distance_to(b)<20:
			return path.slice(first,last+1)
	assert(false,"Highway direction must match driving direction")
	return PackedVector3Array()
func _run() -> void:
	city=load("res://scenes/hartford_district.tscn").instantiate()
	root.add_child(city)
	city.get_node("VehicleSpawn/PlayerCar").set_physics_process(false)
	_index_roads()
	var named: Dictionary=city.get_meta("named_routes")
	var roads: Array=city.get_node("Streets").get_children()
	var main: PackedVector3Array=city.map_roads[0]
	var alley:=PackedVector3Array()
	var best:=INF
	for i in range(roads.size()):
		if String(roads[i].name).begins_with("ServiceAlley"):
			var path: PackedVector3Array=city.map_roads[i]
			var middle: Vector3=path[path.size()/2]
			var distance:=Vector2(middle.x+645,middle.z+550).length()
			if distance<best:
				best=distance;alley=path
	assert(not alley.is_empty())
	alley.reverse()
	append_section(local_route(main[nearest(main,Vector3(-60,0,340))],alley[0]),"DOWNTOWN / TRUMBULL")
	append_section(alley,"SERVICE ALLEY")
	append_section(local_route(course[-1],named.Downtown_to_I84_E[0]),"ASYLUM HILL")
	append_section(named.Downtown_to_I84_E,"I-84 EAST ON-RAMP")
	append_section(highway_section("I84",course[-1],named.I84_E_to_I91_S[0]),"I-84 EAST")
	append_section(named.I84_E_to_I91_S,"I-91 SOUTH INTERCHANGE")
	append_section(named.I91_S_to_Columbus,"DOWNTOWN / COLUMBUS EXIT")
	var front:=PackedVector3Array()
	var columbus:=PackedVector3Array()
	for i in range(roads.size()):
		if String(roads[i].name)=="Front Street": front=city.map_roads[i]
		if String(roads[i].name)=="Columbus Boulevard": columbus=city.map_roads[i]
	assert(not front.is_empty() and not columbus.is_empty())
	append_section(local_route(course[-1],front[0]),"STATE STREET")
	append_section(front,"FRONT STREET")
	var finish:=nearest(columbus,Vector3(380,0,650))
	append_section(local_route(course[-1],columbus[finish]),"RIVERFRONT FINISH")
	var finish_index:=course.size()-1
	var distances: Array[float]=[0.0]
	for i in range(1,course.size()):
		distances.append(distances[-1]+course[i-1].distance_to(course[i]))
	var gates: Array[int]=[]
	var last_distance:=-90.0
	for i in range(1,course.size()):
		var section_end:=false
		for section in sections:
			if section.end==i: section_end=true
		if distances[i]-last_distance>=150 or (section_end and distances[i]-last_distance>=45):
			gates.append(i);last_distance=distances[i]
	if gates.is_empty() or gates[-1]!=finish_index: gates.append(finish_index)
	append_section(columbus.slice(finish+1,mini(finish+24,columbus.size())),"FINISH RUNOFF")
	for i in range(distances.size(),course.size()):
		distances.append(distances[-1]+course[i-1].distance_to(course[i]))
	var serialized: Array=[]
	for p in course: serialized.append([p.x,p.y,p.z])
	var data:={"version":1,"name":"CAPITAL RUN","points":serialized,"distances":distances,"checkpoints":gates,"sections":sections,"finish_index":finish_index,"length":distances[finish_index]}
	var file:=FileAccess.open("res://racing/capital_run_route.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(data));file.close()
	print("PASS: Capital Run route ",distances[finish_index],"m, ",course.size()," samples, ",gates.size()," ordered checkpoints")
	quit()
