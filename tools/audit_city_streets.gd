extends SceneTree
const OUT := "res://world/hartford/street_plan.json"
var city: Node3D
var lots: Array = []
func _initialize() -> void:call_deferred("run")
func ground(x:float,z:float)->float:
	var land:=4+16*(1-smoothstep(-1700,500,x))+2*sin(z/750)
	return lerpf(-5,land,smoothstep(72,112,absf(x-(730+35*sin(z/800)))))
func vec(p: Vector3) -> Array:return [p.x,p.y,p.z]
func clear_link(a: Vector3,b: Vector3) -> bool:
	for lot: Array in lots:
		var body: Node3D=lot[0];var half: Vector3=lot[1]*.5
		if body.global_position.distance_to(a)>100 and body.global_position.distance_to(b)>100:continue
		for i in range(13):
			var local:=body.to_local(a.lerp(b,i/12.0))
			if absf(local.x)<half.x+5 and absf(local.z)<half.z+5:return false
	return true
func run() -> void:
	city=load("res://scenes/hartford_district.tscn").instantiate();city.set_meta("offline_build",true);root.add_child(city)
	city.add_child(load("res://world/eastside/frontage.tscn").instantiate())
	var data: Dictionary={"roads":[],"lots":[],"connections":[],"bounds":[-2250,-1900,4500,3800]}
	for body: StaticBody3D in city.find_children("*","StaticBody3D",true,false):
		if body.has_meta("kit_model"):
			var size: Vector3=body.get_child(0).shape.size;lots.append([body,size])
			var corners:=[]
			for corner: Vector3 in [Vector3(-.5,0,-.5),Vector3(.5,0,-.5),Vector3(.5,0,.5),Vector3(-.5,0,.5)]:
				corners.append(vec(body.global_position+body.global_basis*(corner*size*1.08)))
			data.lots.append(corners)
	var layout: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://world/hartford/layout.json"))
	var bodies:=city.get_node("Streets").get_children()
	for index in range(city.map_roads.size()):
		var path: PackedVector3Array=city.map_roads[index];var width:=12.0
		if index<17:width=float(layout.roads[index].width)
		elif index<bodies.size():
			var meshes:=bodies[index].find_children("*","MeshInstance3D",true,false)
			if not meshes.is_empty():
				var vertices: PackedVector3Array=meshes[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
				width=clampf(vertices[0].distance_to(path[0])*2,6,24)
		var road: Dictionary={"width":width,"points":[],"elevated":false}
		for point in path:
			road.points.append(vec(point))
			if point.y-ground(point.x,point.z)>1:road.elevated=true
		data.roads.append(road)
	var rejected:=0
	for index in range(city.map_roads.size()):
		var path: PackedVector3Array=city.map_roads[index]
		if path[0].distance_to(path[-1])<10 or data.roads[index].elevated:continue
		for end in [0,path.size()-1]:
			var p:=path[end];var flat:=Vector3(p.x,0,p.z)
			var outward: Vector3=p-path[1 if end==0 else path.size()-2];outward.y=0;outward=outward.normalized()
			var nearest:=INF;var target:=p;var other_width:=12.0
			for j in range(city.map_roads.size()):
				if j==index or data.roads[j].elevated:continue
				var other: PackedVector3Array=city.map_roads[j]
				for i in range(other.size()-1):
					var a:=other[i];var b:=other[i+1]
					if minf(a.x,b.x)>p.x+50 or maxf(a.x,b.x)<p.x-50 or minf(a.z,b.z)>p.z+50 or maxf(a.z,b.z)<p.z-50:continue
					a.y=0;b.y=0;var q:=Geometry3D.get_closest_point_to_segment(flat,a,b)
					var d:=flat.distance_to(q)
					if d<nearest:nearest=d;target=q;other_width=float(data.roads[j].width)
			if nearest<=maxf(float(data.roads[index].width),other_width)*.5+1 or nearest>45:continue
			target.y=ground(target.x,target.z)
			if outward.dot((target-p).normalized())<.3 or absf(target.y-p.y)>2 or not clear_link(p,target):rejected+=1;continue
			var duplicate:=false
			for link: Dictionary in data.connections:
				var a:=Vector3(link.points[0][0],link.points[0][1],link.points[0][2])
				var b:=Vector3(link.points[1][0],link.points[1][1],link.points[1][2])
				if p.distance_to(b)<10 and target.distance_to(a)<10:duplicate=true
			if duplicate:continue
			data.connections.append({"source":index,"width":minf(float(data.roads[index].width),other_width),"points":[vec(p),vec(target)]})
	var file:=FileAccess.open(OUT,FileAccess.WRITE);file.store_string(JSON.stringify(data));file.close()
	print("STREET AUDIT: ",data.roads.size()," roads; ",data.connections.size()," safe short-gap connectors; ",rejected," obstructed/backward candidates rejected")
	city.free();quit()
