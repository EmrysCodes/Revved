extends "res://tools/build_downtown.gd"
## Hartford-inspired metre-scale core; approximate authored waypoints, not surveyed GIS.
const RX := 2050.0
const RZ := 1650.0
var layout: Dictionary
var named_routes: Dictionary = {}
var glass_locations: Array[Vector3] = []
var pier_candidates: Array[Vector3] = []
var ring_profile := false
var paint_requests: Array = []
var sidewalk_requests: Array = []
var path_widths: Array[float] = []
var infill_routes: Array = []
var alley_count := 0
var reserved_blocks: Array[Vector3] = []
var plan_cache: Dictionary = {}
var street_plans: Array = []
var street_bounds: Array[Rect2] = []
var kit: RefCounted
var landmark_mode := false
var flowing_routes: Array = []
func ground(x: float, z: float) -> float:
	var land := 4.0 + 16.0 * (1.0 - smoothstep(-1700, 500, x)) + 2.0 * sin(z / 750.0)
	var river_x := 730.0 + 35.0 * sin(z / 800.0)
	var bank := smoothstep(72.0, 112.0, absf(x - river_x))
	return lerpf(-5.0, land, bank)
func ring_y(point: Vector3) -> float:
	var angle := atan2(point.z/RZ,point.x/RX)
	point = Vector3(RX*cos(angle),0,RZ*sin(angle))
	var base := 18.0 + 16.0*(1.0-smoothstep(-1700,500,point.x))+2.0*sin(point.z/750.0)
	var over84 := 1.0 - smoothstep(40, 650, absf(point.z + 850))
	var over91 := 1.0 - smoothstep(40, 550, absf(point.x - 550))
	var over2 := 1.0 - smoothstep(40, 550, absf(point.x - 1300))
	return maxf(lerpf(base, 46, over84), maxf(lerpf(base, 34, over91), lerpf(base, 34, over2)))
func highway_y(_z: float) -> float:
	return 46.0
func geo(point: Array) -> Vector3:
	return pos((float(point[0]) + 72.6732) * 83025.0, -(float(point[1]) - 41.7659) * 111132.0)
func node_point(key: String) -> Vector3:
	return geo(layout.nodes[key])
func _road_edge_height(point: Vector3, center: Vector3, elevated: bool) -> float:
	if not elevated:
		return ground(point.x, point.z)
	if not ring_profile:
		return point.y
	var target := ring_y(center)
	var floor_y := ground(center.x, center.z)
	var weight := clampf((center.y - floor_y) / maxf(target - floor_y, 1.0), 0, 1)
	return point.y + lerpf(ground(point.x, point.z) - floor_y, ring_y(point) - target, weight)
func _build() -> void:
	layout = JSON.parse_string(FileAccess.get_file_as_string("res://world/hartford/layout.json"))
	rng.seed = 76421
	city = Node3D.new()
	city.name = "HartfordDistrict"
	root.add_child(city)
	for title in ["Terrain", "Streets", "Sidewalks", "Buildings", "Details", "Expressway", "Ramps", "Signs", "Boundaries", "Shortcuts", "Landmarks", "UrbanKit"]:
		group(title)
	for entry in [["Asphalt",Color(0.105,0.115,0.13)],["Concrete",Color(0.48,0.5,0.52)],["Walk",Color(0.4,0.41,0.4)],["Grass",Color(0.22,0.3,0.2)],["White",Color(0.86,0.86,0.82)],["Yellow",Color(0.86,0.65,0.2)],["Window",Color(0.12,0.24,0.3)],["Building0",Color(0.57,0.5,0.4)],["Building1",Color(0.36,0.44,0.49)],["Building2",Color(0.43,0.28,0.23)],["Building3",Color(0.57,0.57,0.53)],["GreenSign",Color(0.025,0.16,0.1)],["Water",Color(0.10,0.29,0.34)],["Gold",Color(0.78,0.58,0.16)]]:
		material(entry[0], entry[1])
	kit=load("res://tools/city_kit.gd").new(city,groups.UrbanKit)
	for key in ["Asphalt","Walk"]:
		mats[key].albedo_color=Color(0.7,0.7,0.7) if key=="Asphalt" else Color(0.8,0.8,0.8)
		mats[key].albedo_texture=load("res://assets/city/quaternius_downtown/textures/T_Concrete_Asphalt_BaseColor.png" if key=="Asphalt" else "res://assets/city/quaternius_downtown/textures/T_Concrete_BaseColor.png")
		mats[key].uv1_triplanar=true
		mats[key].uv1_world_triplanar=true
		mats[key].uv1_scale=Vector3.ONE*0.2
	_build_land()
	_build_streets()
	_build_infill_streets()
	index_streets()
	paint_streets()
	for request in sidewalk_requests:
		beveled_walk(request[0],request[1],request[2])
	_build_highway()
	flush_piers()
	_build_blocks()
	flush_rails()
	kit.flush()
	_batch_details()
	store_geometry()
	_build_scene()
	city.set_script(load("res://world/hartford/hartford.gd"))
	city.set("map_roads", road_map)
	city.set("highway_roads", highway_map)
	city.set("ramp_roads", ramp_map)
	city.set_meta("building_count", building_count)
	city.set_meta("kit_buildings", kit.count)
	city.set_meta("kit_props", kit.props)
	city.set_meta("flowing_routes", flowing_routes)
	city.set_meta("infill_routes", infill_routes)
	city.set_meta("alley_count", alley_count)
	city.set_meta("named_routes", named_routes)
	city.set_meta("glass_locations", glass_locations)
	var water_map:=PackedVector3Array()
	for z in range(-1900,1901,100):
		water_map.append(Vector3(650+35*sin(z/800.0),0,z))
	for z in range(1900,-1901,-100):
		water_map.append(Vector3(810+35*sin(z/800.0),0,z))
	city.set_meta("water_map",water_map)
	city.set_meta("geographic_accuracy", layout.accuracy)
	var packed := PackedScene.new()
	assert(packed.pack(city) == OK)
	assert(ResourceSaver.save(packed,"res://scenes/hartford_district.tscn") == OK)
	print("PASS: Hartford-inspired core, ",building_count," masses, ",road_map.size()," local links, ",highway_map.size()," highway carriageways, ",ramp_map.size()," ramps, ",glass_locations.size()," glass shortcuts")
	quit()
func _build_land() -> void:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var urban:=ShaderMaterial.new()
	urban.shader=load("res://world/hartford/urban_ground.gdshader")
	urban.set_shader_parameter("pavement",load("res://assets/city/quaternius_downtown/textures/T_Concrete_BaseColor.png"))
	builder.set_material(urban)
	for x in range(-2250,2250,25):
		for z in range(-1900,1900,25):
			quad(builder,pos(x,z+25,-0.18),pos(x+25,z+25,-0.18),pos(x,z,-0.18),pos(x+25,z,-0.18),true)
	builder.generate_normals()
	builder.index()
	mesh_body("ContinuousLandAndRiverBanks",builder.commit(),groups.Terrain)
	var water := SurfaceTool.new()
	water.begin(Mesh.PRIMITIVE_TRIANGLES)
	water.set_material(mats.Water)
	for z in range(-1900,1900,20):
		var x0 := 730.0+35.0*sin(z/800.0)
		var x1 := 730.0+35.0*sin((z+20)/800.0)
		quad(water,Vector3(x1-85,-0.6,z+20),Vector3(x1+85,-0.6,z+20),Vector3(x0-85,-0.6,z),Vector3(x0+85,-0.6,z),true)
	water.generate_normals()
	mesh_body("ConnecticutRiver",water.commit(),groups.Details,false)
func sampled(a: Vector3,b: Vector3) -> PackedVector3Array:
	var output := PackedVector3Array()
	var count := maxi(1,ceili(a.distance_to(b)/5.0))
	for i in range(count+1):
		output.append(a.lerp(b,float(i)/count))
	return output
func local_link(label: String,a: Vector3,b: Vector3,width: float,bridge := false) -> void:
	var points := sampled(a,b)
	local_path(label,points,width,bridge)
func local_path(label: String,points: PackedVector3Array,width: float,bridge:=false) -> void:
	for i in range(points.size()):
		var p := points[i]
		p.y = ground(p.x,p.z)
		if bridge and p.x > 440 and p.x < 980:
			var blend := smoothstep(440,620,p.x)*(1.0-smoothstep(880,980,p.x))
			p.y = lerpf(p.y,12.0,blend)
		points[i] = p
	road(label,points,width,groups.Streets,bridge)
	road_map.append(points)
	path_widths.append(width)
	if not bridge:
		sidewalk_requests.append([points,width,road_map.size()-1])
	paint_requests.append([points,width,road_map.size()-1])
func beveled_walk(points: PackedVector3Array,width: float,source: int) -> void:
	for side in [-1.0,1.0]:
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		builder.set_material(mats.Walk)
		var offsets := [0.0,0.6,3.4,4.0]
		var heights := [0.002,0.12,0.12,0.002]
		for i in range(points.size()-1):
			var right := (points[i+1]-points[i]).cross(Vector3.UP).normalized()
			var midpoint: Vector3 = (points[i]+points[i+1])*0.5+right*side*(width*0.5+2.0)
			if crosses_other_street(midpoint,source):
				continue
			for j in range(3):
				var vertices: Array[Vector3]=[]
				for p in [points[i],points[i+1]]:
					for k in [j,j+1]:
						var v: Vector3=p+right*side*(width*0.5+offsets[k])
						v.y=ground(v.x,v.z)+heights[k]
						vertices.append(v)
				quad(builder,vertices[0],vertices[1],vertices[2],vertices[3],side>0)
		builder.generate_normals()
		builder.index()
		mesh_body("BeveledSidewalk",builder.commit(),groups.Sidewalks)
func _build_streets() -> void:
	for route in layout.roads:
		var keys: Array=route.nodes
		var anchors:=PackedVector3Array()
		for key in keys:
			anchors.append(node_point(key))
		local_path(route.name,smooth_route(anchors),route.width,route.get("bridge",false))
		var point := node_point(keys[maxi(0,keys.size()/2)])
		label_sign(route.name,point+Vector3(14,4,0),0,groups.Signs)
	# Several independent local approaches, not a highway-only district graph.
	local_link("NorthEndContinuation",node_point("MainNorth"),pos(0,-1740),22)
	local_link("SouthEndContinuation",node_point("MainSouth"),pos(0,1430),22)
	local_link("SouthLoopAccess",pos(0,1430),pos(0,1740),22)
	local_link("WestNeighborhoodContinuation",node_point("FarmingtonWest"),pos(-1830,0),22)
	local_link("WestLoopAccess",pos(-1830,0),pos(-2140,0),22)
	local_link("EastNeighborhoodContinuation",node_point("EastFounders"),pos(2140,0),22)
	local_link("BridgeStreetSouth",node_point("ColumbusSouth"),pos(1140,1000),20,true)
	local_link("EastNeighborhoodCrossStreet",pos(1140,1000),node_point("EastSouth"),20)
	local_link("AsylumHighwayAccess",node_point("UnionAsylum"),pos(-1000,-480),22)
	local_link("AsylumExitUnderpass",pos(-1000,-1100),pos(-1000,-480),18)
	# A broad curved park edge and cross-park shortcuts create non-grid racing lines.
	var path := PackedVector3Array()
	for i in range(61):
		var a: float=TAU*float(i)/60
		path.append(pos(-565+260*cos(a),190+110*sin(a)))
	road("BushnellParkDrive",path,9,groups.Streets)
	road_map.append(path)
	path_widths.append(9.0)
	local_link("ParkNorthApproach",node_point("TrumbullJewell"),pos(-305,190),12)
	local_link("ParkWestApproach",node_point("TrinityElm"),pos(-825,190),12)
	local_link("ParkCrossing",pos(-825,190),pos(-305,190),8)
# Fictional neighborhood infill, connected to the authored arterial network.
func _build_infill_streets() -> void:
	for district in [Rect2(-1740,-650,660,1900),Rect2(-1080,520,1440,730),Rect2(-720,-620,960,500),Rect2(1010,-380,300,1320)]:
		var xs: Array[float]=[]
		var zs: Array[float]=[]
		var x: float=district.position.x
		while x<=district.end.x:
			xs.append(x);x+=150.0
		var z: float=district.position.y
		while z<=district.end.y:
			zs.append(z);z+=140.0
		var perimeter:=rounded_block(Rect2(xs[0],zs[0],xs[-1]-xs[0],zs[-1]-zs[0]),65)
		local_path("CurvingNeighborhoodBoulevard",perimeter,16)
		infill_routes.append(road_map[-1]);flowing_routes.append(road_map[-1])
		for i in range(1,xs.size()-1):
			infill_link("WindingNeighborhoodStreet",pos(xs[i],zs[0]),pos(xs[i],zs[-1]),12)
		for j in range(1,zs.size()-1):
			infill_link("WindingCrossStreet",pos(xs[0],zs[j]),pos(xs[-1],zs[j]),12)
		for i in range(xs.size()-1):
			for j in range(zs.size()-1):
				infill_link("ServiceAlley",pos((xs[i]+xs[i+1])*0.5,zs[j]),pos((xs[i]+xs[i+1])*0.5,zs[j+1]),7)
		# Round the four turns of each boulevard instead of ending in square corners.
	for entry in [["WestInfillLink",pos(-1140,50),node_point("JewellWest")],["SouthInfillLink",pos(-780,520),node_point("ParkTrinity")],["SouthMainLink",pos(270,1080),node_point("ColumbusSouth")],["EastInfillLink",pos(1010,40),node_point("EastFounders")]]:
		local_link(entry[0],neighborhood_point(entry[1]),entry[2],14)
		infill_routes.append(road_map[-1])
func neighborhood_point(p: Vector3) -> Vector3:
	return pos(p.x+22*sin(p.z/210.0),p.z+18*sin(p.x/240.0))
func rounded_block(rect: Rect2,radius: float) -> PackedVector3Array:
	var points:=PackedVector3Array()
	var centers: Array[Vector2]=[rect.position+Vector2(radius,radius),Vector2(rect.end.x-radius,rect.position.y+radius),rect.end-Vector2(radius,radius),Vector2(rect.position.x+radius,rect.end.y-radius)]
	for corner in range(4):
		var arc:=PackedVector3Array()
		for i in range(25):
			var angle: float=PI+corner*PI*0.5+i*PI*0.5/24
			arc.append(pos(centers[corner].x+radius*cos(angle),centers[corner].y+radius*sin(angle)))
		if not points.is_empty():
			points.append_array(sampled(points[-1],arc[0]).slice(1))
			points.append_array(arc.slice(1))
		else:
			points.append_array(arc)
	points.append_array(sampled(points[-1],points[0]).slice(1))
	for i in range(points.size()):
		points[i]=neighborhood_point(points[i])
	return points
func smooth_route(anchors: PackedVector3Array) -> PackedVector3Array:
	var out:=PackedVector3Array()
	for i in range(anchors.size()-1):
		var a:=anchors[i]
		var b:=anchors[i+1]
		var previous:=anchors[maxi(i-1,0)]
		var following:=anchors[mini(i+2,anchors.size()-1)]
		var handle:=minf(a.distance_to(b)*0.25,55.0)
		var c1:=a+(b-previous).normalized()*handle
		var c2:=b-(following-a).normalized()*handle
		var count:=maxi(2,ceili(a.distance_to(b)/4))
		for j in range(count):
			var t:=float(j)/count
			var v: Vector3=pow(1-t,3)*a+3*pow(1-t,2)*t*c1+3*(1-t)*t*t*c2+t*t*t*b
			out.append(pos(v.x,v.z))
	out.append(anchors[-1])
	return out
func infill_link(label: String,a: Vector3,b: Vector3,width: float) -> void:
	# Reject routes through existing landmark envelopes, rather than burying buildings.
	for landmark in [Vector3(-900,0,220),Vector3(5,0,300),Vector3(-450,0,-300),Vector3(-820,0,-220),Vector3(350,0,350),Vector3(470,0,200),Vector3(60,0,0)]:
		if Vector2(landmark.x,landmark.z).distance_to(Geometry2D.get_closest_point_to_segment(Vector2(landmark.x,landmark.z),Vector2(a.x,a.z),Vector2(b.x,b.z)))<75:
			return
	var points:=sampled(a,b)
	for i in range(points.size()):
		points[i]=neighborhood_point(points[i])
	local_path(label,points,width)
	infill_routes.append(road_map[-1])
	if width<8:
		# Alleys are unmarked and flush; intersections stay open to vehicles.
		alley_count+=1
		paint_requests.pop_back()
		sidewalk_requests.pop_back()
func offset_path(path: PackedVector3Array,offset: float) -> PackedVector3Array:
	var out:=PackedVector3Array()
	for i in range(path.size()):
		var tangent:=path[mini(i+1,path.size()-1)]-path[maxi(0,i-1)]
		out.append(path[i]+tangent.cross(Vector3.UP).normalized()*offset)
	return out
func freeway(label: String,points: PackedVector3Array) -> void:
	road(label,points,16,groups.Expressway,true)
	highway_map.append(points)
	named_routes[label]=points
	for i in range(points.size()-1):
		var center: Vector3=(points[i]+points[i+1])*0.5
		var right: Vector3=(points[i+1]-points[i]).cross(Vector3.UP).normalized()
		var junction: bool=(absf(center.x-550)<420 and absf(center.z+850)<470) or (center.x>1000 and center.z< -400) or (center.z>700 and center.x>250) or (center.x< -500 and absf(center.z+850)<400)
		if not junction:
			for side in [-1,1]:
				rail(points[i]+right*side*8,points[i+1]+right*side*8,groups.Expressway)
		if i%3==0:
			stripe(points[i]+Vector3.UP*0.025,points[i+1]+Vector3.UP*0.025,0.16,"White",groups.Details)
		if i%12==0:
			var height: float=center.y-ground(center.x,center.z)-0.5
			if height>1 and road_distance(center,road_map)>20:
				pier_candidates.append(center)
func trunk(label: String,center: PackedVector3Array) -> void:
	var forward:=offset_path(center,12)
	var back:=offset_path(center,-12)
	back.reverse()
	freeway(label+"_Forward",forward)
	freeway(label+"_Reverse",back)
func curve(a: Vector3,c1: Vector3,c2: Vector3,b: Vector3,hump:=0.0) -> PackedVector3Array:
	var points:=PackedVector3Array()
	for i in range(101):
		var t:=float(i)/100
		var p: Vector3=pow(1-t,3)*a+3*pow(1-t,2)*t*c1+3*(1-t)*t*t*c2+t*t*t*b
		p.y=maxf(ground(p.x,p.z),lerpf(a.y,b.y,smoothstep(0.2,0.8,t))+hump*pow(sin(PI*t),2))
		points.append(p)
	return points
func connector(label: String,a: Vector3,c1: Vector3,c2: Vector3,b: Vector3,hump:=0.0) -> void:
	var points:=curve(a,c1,c2,b,hump)
	road(label,points,8,groups.Ramps,true)
	ramp_map.append(points)
	named_routes[label]=points
	for i in range(12,points.size()-13):
		var right: Vector3=(points[i+1]-points[i]).cross(Vector3.UP).normalized()
		for side in [-1,1]:
			rail(points[i]+right*side*4,points[i+1]+right*side*4,groups.Ramps)
func _build_highway() -> void:
	trunk("I84",sampled(Vector3(-2000,34,-850),Vector3(1700,34,-850)))
	trunk("I91",sampled(Vector3(550,22,1500),Vector3(550,22,-1500)))
	var rt2:=sampled(Vector3(1400,22,-1400),Vector3(1400,22,-400))
	var middle:=sampled(Vector3(1400,22,-400),Vector3(1300,22,0))
	var end:=sampled(Vector3(1300,22,0),Vector3(1300,22,1500))
	rt2.append_array(middle.slice(1));rt2.append_array(end.slice(1))
	trunk("Route2",rt2)
	trunk("Route3_Putnam",sampled(Vector3(550,12,1100),Vector3(1650,12,1100)))
	# Four directional ramps form the I-84/I-91 stacked interchange.
	connector("I84_E_to_I91_S",Vector3(280,34,-838),Vector3(420,34,-838),Vector3(538,22,-720),Vector3(538,22,-580))
	connector("I91_S_to_I84_W",Vector3(538,22,-1120),Vector3(538,22,-980),Vector3(420,34,-862),Vector3(280,34,-862))
	connector("I84_W_to_I91_N",Vector3(820,34,-862),Vector3(680,34,-862),Vector3(562,22,-980),Vector3(562,22,-1120))
	connector("I91_N_to_I84_E",Vector3(562,22,-580),Vector3(562,22,-720),Vector3(680,34,-838),Vector3(820,34,-838))
	# East Hartford Route 2 approaches and the south Route 3 / Putnam crossing.
	connector("I84_E_to_R2_S",Vector3(1100,34,-838),Vector3(1260,34,-838),Vector3(1388,22,-700),Vector3(1388,22,-540))
	clover("R2_N_to_I84_W",Vector2(1650,-1100),238,PI,22,34)
	clover("I91_S_to_R3_E",Vector2(300,1350),238,0,22,12,Vector3(550,12,1112))
	connector("R3_W_to_I91_N",Vector3(840,12,1088),Vector3(680,12,1088),Vector3(562,22,960),Vector3(562,22,800))
	connector("I91_N_to_R3_E",Vector3(562,22,1400),Vector3(562,22,1240),Vector3(680,12,1112),Vector3(840,12,1112))
	clover("R3_W_to_I91_S",Vector2(300,850),238,PI/2,12,22,Vector3.ZERO,Vector3(550,12,1088))
	clover("R3_E_to_R2_N",Vector2(1550,1350),238,PI*1.5,12,22)
	connector("R2_S_to_R3_W",Vector3(1288,22,800),Vector3(1288,22,960),Vector3(1180,12,1088),Vector3(1020,12,1088))
	connector("R3_E_to_R2_S",Vector3(1020,12,1112),Vector3(1180,12,1112),Vector3(1288,22,1240),Vector3(1288,22,1400))
	clover("R2_N_to_R3_W",Vector2(1550,850),238,PI,22,12)
	var access:=pos(-1000,-480)
	connector("Downtown_to_I84_E",access,access+Vector3(-300,0,0),Vector3(-1000,34,-838),Vector3(-700,34,-838))
	clover("I84_W_to_Downtown",Vector2(-1238,-1100),238,PI/2,34,ground(-1000,-1100))
	_build_ring()
	for entry in [["I-84 / I-91\nHARTFORD INTERCHANGE",Vector3(550,43,-850)],["ROUTE 2\nEAST HARTFORD",Vector3(1400,30,-400)],["ROUTE 3 / PUTNAM\nI-91 ↔ ROUTE 2",Vector3(900,20,1100)]]:
		label_sign(entry[0],entry[1],0,groups.Signs,true)
func ring_point(angle: float,offset:=0.0) -> Vector3:
	var point:=Vector3((RX+offset)*cos(angle),0,(RZ+offset)*sin(angle))
	point.y=ring_y(point)
	return point
func _build_ring() -> void:
	ring_profile=true
	for carriage in [-12.0,12.0]:
		var points:=PackedVector3Array()
		for i in range(721):
			points.append(ring_point(TAU*float(i)/720,carriage))
		road("CityPerimeterLoop",points,16,groups.Expressway,true)
		highway_map.append(points)
		for i in range(points.size()-1):
			var tangent: Vector3=points[i+1]-points[i]
			var right:=tangent.cross(Vector3.UP).normalized()
			var a:=TAU*(float(i)+0.5)/720
			var near_merge:=false
			for junction in [0.0,PI*0.5,PI,PI*1.5]:
				if absf(absf(angle_difference(a,junction))-0.40)<0.085:
					near_merge=true
			for side in [-1,1]:
				# Open only the ramp-facing edge; keep the median intact.
				if not near_merge or (carriage>0 and side==1) or (carriage<0 and side==-1):
					rail(points[i]+right*side*8,points[i+1]+right*side*8,groups.Expressway)
			if i%3==0:
				stripe(points[i]+Vector3.UP*0.025,points[i+1]+Vector3.UP*0.025,0.16,"White",groups.Details)
			if i%12==0:
				var p: Vector3=points[i]
				var height:=p.y-ground(p.x,p.z)-0.5
				if road_distance(p,road_map)>20:
						pier_candidates.append(p)
	for angle in [0.0,PI*0.5,PI,PI*1.5]:
		for carriage in [-12.0,12.0]:
			for direction in [-1.0,1.0]:
				var points:=PackedVector3Array()
				var shoulder: float=80*signf(carriage)
				for i in range(101):
					var t:=float(i)/100
					var a: float=angle+direction*0.4*t
					var radius: float=lerpf(shoulder,carriage,smoothstep(0.0,1.0,t))
					# Stay outside the deck until reaching its elevation.
					if t<0.75:
						radius=lerpf(shoulder,carriage+signf(carriage)*18,smoothstep(0.0,0.75,t))
					else:
						radius=lerpf(carriage+signf(carriage)*18,carriage,smoothstep(0.75,1.0,t))
					var p:=ring_point(a,radius)
					p.y=lerpf(ground(p.x,p.z),p.y,smoothstep(0.0,0.70,t))
					points.append(p)
				road("PerimeterAccessRamp",points,8,groups.Ramps,true)
				ramp_map.append(points)
				for i in range(4,72):
					var right: Vector3=(points[i+1]-points[i]).cross(Vector3.UP).normalized()
					for side in [-1,1]:
						rail(points[i]+right*side*4,points[i+1]+right*side*4,groups.Ramps)
	ring_profile=false
var rail_batches: Dictionary = {}
func rail(a: Vector3,b: Vector3,parent: Node) -> void:
	var center: Vector3=(a+b)*0.5+Vector3.UP*0.6
	var key: String=parent.name+"_%d_%d"%[floori(center.x/300),floori(center.z/300)]
	if not rail_batches.has(key):
		var builder:=SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		builder.set_material(mats.Concrete)
		rail_batches[key]=[builder,parent]
	var beam:=BoxMesh.new()
	beam.size=Vector3(0.28,1.2,a.distance_to(b)+0.06)
	beam.material=mats.Concrete
	var transform:=Transform3D(Basis.looking_at((b-a).normalized(),Vector3.UP),center)
	rail_batches[key][0].append_from(beam,0,transform)
func flush_rails() -> void:
	for key in rail_batches:
		mesh_body("Guardrails_"+key,rail_batches[key][0].commit(),rail_batches[key][1])
func plan_segments(path: PackedVector3Array) -> PackedVector3Array:
	var key:=hash(path)
	if plan_cache.has(key):
		return plan_cache[key]
	var result:=PackedVector3Array([path[0]])
	for i in range(1,path.size()-1):
		var a:=Vector2(result[-1].x,result[-1].z)
		var b:=Vector2(path[i+1].x,path[i+1].z)
		var p:=Vector2(path[i].x,path[i].z)
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b))>0.05:
			result.append(path[i])
	result.append(path[-1])
	plan_cache[key]=result
	return result
func road_distance(point: Vector3,paths: Array) -> float:
	var best:=INF
	var p:=Vector2(point.x,point.z)
	for original: PackedVector3Array in paths:
		var path:=plan_segments(original)
		for i in range(path.size()-1):
			var a:=Vector2(path[i].x,path[i].z)
			var b:=Vector2(path[i+1].x,path[i+1].z)
			if p.x<minf(a.x,b.x)-best or p.x>maxf(a.x,b.x)+best or p.y<minf(a.y,b.y)-best or p.y>maxf(a.y,b.y)+best:
				continue
			best=minf(best,p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b)))
	return best
func _build_blocks() -> void:
	# Park grounds are continuous terrain; only paths and monuments constrain driving.
	terrain_patch("BushnellParkLawn",-825,80,-305,300,"Grass",-0.05,groups.Details,false)
	var landmarks: Array[Vector3]=[Vector3(-900,0,220),Vector3(5,0,300),Vector3(-450,0,-300),Vector3(-820,0,-220),Vector3(350,0,350),Vector3(470,0,200),Vector3(60,0,0)]
	var candidates: Array[Vector3]=[]
	for x in range(-1680,1450,85):
		for z in range(-1200,1250,85):
			var p:=pos(x+rng.randf_range(-15,15),z+rng.randf_range(-15,15))
			if p.x>510 and p.x<980:
				continue
			if p.x< -290 and p.x> -850 and p.z>45 and p.z<330:
				continue
			if p.x>510 and p.x<1450 and p.z< -470:
				continue
			if p.x> -350 and p.x<1300 and p.z< -600:
				continue
			if road_distance(p,road_map)<43 or road_distance(p,highway_map)<34 or road_distance(p,ramp_map)<40:
				continue
			var blocked:=false
			for landmark in landmarks:
				if Vector2(p.x-landmark.x,p.z-landmark.z).length()<80:
					blocked=true
			if blocked:
				continue
			candidates.append(p)
	for index in range(candidates.size()):
		var p: Vector3=candidates[index]
		if index%37==0 and road_distance(p,road_map)>60:
			glass_lobby(p.x,p.z)
			reserved_blocks.append(Vector3(p.x,55,p.z))
			continue
		var central: bool=p.x> -500 and p.x<450 and absf(p.z)<600
		var height: float=rng.randf_range(28,95) if central else rng.randf_range(8,25)
		var sx:=rng.randf_range(26,46)
		var sz:=rng.randf_range(28,48)
		var radius:=Vector2(sx,sz).length()*0.5+1
		if not clear_parcel(p,radius) or road_distance(p,highway_map)<radius+16 or road_distance(p,ramp_map)<radius+10:
			continue
		building(p.x,p.z,sx,sz,height,rng.randi_range(0,3))
		reserved_blocks.append(Vector3(p.x,Vector2(sx,sz).length()*0.5+3,p.z))
		if central or index%4==0:
			terrain_patch("DriveableForecourt",p.x-33,p.z-34,p.x+33,p.z+34,"Walk",0.008,groups.Details)
	_dense_frontage(landmarks)
	_build_landmarks()
func _dense_frontage(landmarks: Array[Vector3]) -> void:
	# Small parcels create shop rows, apartments and warehouses between larger masses.
	for x in range(-1780,1430,30):
		for z in range(-1280,1400,30):
			var p:=pos(x+rng.randf_range(-2,2),z+rng.randf_range(-2,2))
			if p.x>490 and p.x<990 or p.x> -870 and p.x< -280 and p.z>35 and p.z<340:
				continue
			if p.x>500 and p.z< -470 or p.x> -350 and p.x<1300 and p.z< -600:
				continue
			var sx:=rng.randf_range(14,23)
			var sz:=rng.randf_range(16,25)
			var radius:=Vector2(sx,sz).length()*0.5+1
			var blocked:=false
			for landmark in landmarks:
				if Vector2(p.x-landmark.x,p.z-landmark.z).length()<80+radius:
					blocked=true
			for other in reserved_blocks:
				if Vector2(p.x-other.x,p.z-other.z).length()<radius+other.y:
					blocked=true
			if blocked or road_distance(p,highway_map)<radius+16 or road_distance(p,ramp_map)<radius+10:
				continue
			# Width-aware clearance preserves both street and alley shoulders.
			blocked=not clear_parcel(p,radius)
			if blocked:
				continue
			var central:=p.x> -720 and p.x<450 and absf(p.z)<650
			var height:=rng.randf_range(16,58) if central else rng.randf_range(7,19)
			building(p.x,p.z,sx,sz,height,rng.randi_range(0,3))
			# Paved service yards, ground-floor shop glazing and rooftop equipment.
			terrain_patch("PavedParcel",p.x-sx*0.5-2,p.z-sz*0.5-2,p.x+sx*0.5+2,p.z+sz*0.5+2,"Walk",0.006,groups.Details,false)
func _build_landmarks() -> void:
	landmark_mode=true
	# Recognizable blockout silhouettes and approximate locations; no exact facade claim.
	building(-900,220,84,48,34,0)
	var dome:=MeshInstance3D.new()
	dome.name="CapitolGoldDome"
	var sphere:=SphereMesh.new()
	sphere.radius=15;sphere.height=30;sphere.material=mats.Gold
	dome.mesh=sphere;dome.position=pos(-900,220,45)
	put(dome,groups.Landmarks)
	label_sign("STATE CAPITOL",pos(-900,190,12),PI,groups.Signs,true)
	building(5,300,42,42,92,0)
	box("TravelersUpperTower",pos(5,300,121),Vector3(22,58,22),"Building0",groups.Landmarks)
	box("TravelersCrown",pos(5,300,155),Vector3(10,10,10),"Gold",groups.Landmarks,false)
	label_sign("TRAVELERS TOWER",pos(5,278,14),PI,groups.Signs)
	building(-450,-300,102,78,28,1)
	label_sign("XL CENTER",pos(-450,-341,12),PI,groups.Signs,true)
	building(-820,-220,90,25,18,2)
	label_sign("UNION STATION",pos(-820,-236,10),PI,groups.Signs,true)
	building(350,350,72,60,25,3)
	label_sign("CONVENTION CENTER",pos(330,323,12),PI,groups.Signs)
	building(470,200,44,55,42,1)
	label_sign("SCIENCE CENTER",pos(470,170,14),PI,groups.Signs)
	building(60,0,45,30,16,0)
	box("OldStateHouseCupola",pos(60,0,23),Vector3(7,14,7),"Building3",groups.Landmarks)
	label_sign("OLD STATE HOUSE",pos(60,-17,8),PI,groups.Signs)
func glass_lobby(x: float,z: float) -> void:
	glass_locations.append(Vector3(x,ground(x,z),z))
	var y:=ground(x,z)
	box("ArcadeUpperFloors",Vector3(x,y+23,z),Vector3(44,34,66),"Building1",groups.Shortcuts)
	for side in [-1,1]:
		for end in [-1,1]:
			box("StructuralColumn",Vector3(x+side*20,y+3,z+end*29),Vector3(3,6,3),"Concrete",groups.Shortcuts)
	terrain_patch("ArcadeFloor",x-23,z-45,x+23,z+45,"Walk",0.005,groups.Details)
	var glass:=StandardMaterial3D.new()
	glass.albedo_color=Color(0.3,0.7,0.85,0.32)
	glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode=BaseMaterial3D.CULL_DISABLED
	glass.roughness=0.1
	for end in [-1,1]:
		var pane:=Area3D.new()
		pane.name="BreakableGlass"
		pane.position=Vector3(x,y+3,z+end*33)
		pane.collision_layer=0;pane.collision_mask=1
		pane.set_script(load("res://world/hartford/shortcut_glass.gd"))
		var visual:=MeshInstance3D.new()
		visual.name="Pane"
		var mesh:=BoxMesh.new()
		mesh.size=Vector3(37,6,0.15);mesh.material=glass
		visual.mesh=mesh
		pane.add_child(visual)
		var collision:=CollisionShape3D.new()
		var shape:=BoxShape3D.new()
		shape.size=Vector3(37,6,0.6);collision.shape=shape
		pane.add_child(collision)
		var shards:=CPUParticles3D.new()
		shards.name="Shards"
		shards.emitting=false;shards.one_shot=true;shards.amount=36;shards.lifetime=0.9;shards.explosiveness=1
		shards.direction=Vector3.UP;shards.spread=90;shards.initial_velocity_min=2;shards.initial_velocity_max=7;shards.gravity=Vector3(0,-12,0)
		shards.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX;shards.emission_box_extents=Vector3(17,2,0.2)
		var fragment:=BoxMesh.new();fragment.size=Vector3(0.18,0.22,0.04);fragment.material=glass;shards.mesh=fragment
		pane.add_child(shards)
		put(pane,groups.Shortcuts)
		for child in pane.get_children():
			child.owner=city
	label_sign("GLASS ARCADE\nDRIVE THROUGH",Vector3(x,y+7,z-34),PI,groups.Signs)
func _build_scene() -> void:
	super._build_scene()
	var car: CharacterBody3D=city.get_node("VehicleSpawn/PlayerCar")
	car.position=node_point("WellsMain")+Vector3(4,0.3,0)
	car.floor_snap_length=0.6
	var hud: Label=city.get_node("CityHUD/Screen/Readout")
	hud.add_theme_font_size_override("font_size",15)

func index_streets() -> void:
	for path: PackedVector3Array in road_map:
		var plan:=plan_segments(path)
		street_plans.append(plan)
		var bounds:=Rect2(Vector2(plan[0].x,plan[0].z),Vector2.ZERO)
		for point in plan:
			bounds=bounds.expand(Vector2(point.x,point.z))
		street_bounds.append(bounds)
func crosses_other_street(point: Vector3,source: int) -> bool:
	var p:=Vector2(point.x,point.z)
	for index in range(street_plans.size()):
		if index==source:
			continue
		var width: float=path_widths[index]*0.5+0.8
		if not street_bounds[index].grow(width).has_point(p):
			continue
		var path: PackedVector3Array=street_plans[index]
		for i in range(path.size()-1):
			if p.distance_squared_to(Geometry2D.get_closest_point_to_segment(p,Vector2(path[i].x,path[i].z),Vector2(path[i+1].x,path[i+1].z)))<width*width:
				return true
	return false
func clear_parcel(point: Vector3,radius: float) -> bool:
	var p:=Vector2(point.x,point.z)
	for index in range(street_plans.size()):
		var width: float=radius+path_widths[index]*0.5+2.5
		if not street_bounds[index].grow(width).has_point(p):
			continue
		var path: PackedVector3Array=street_plans[index]
		for i in range(path.size()-1):
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p,Vector2(path[i].x,path[i].z),Vector2(path[i+1].x,path[i+1].z)))<width:
				return false
	return true
func frontage_yaw(point: Vector3) -> float:
	var p:=Vector2(point.x,point.z)
	var best:=INF
	var outward:=Vector2(0,1)
	for index in range(street_plans.size()):
		if not street_bounds[index].grow(minf(best,150)).has_point(p):
			continue
		var path: PackedVector3Array=street_plans[index]
		for i in range(path.size()-1):
			var closest:=Geometry2D.get_closest_point_to_segment(p,Vector2(path[i].x,path[i].z),Vector2(path[i+1].x,path[i+1].z))
			if p.distance_to(closest)<best:
				best=p.distance_to(closest);outward=closest-p
	return atan2(outward.x,outward.y)
func building(x: float,z: float,sx: float,sz: float,height: float,style: int) -> void:
	if landmark_mode:
		super.building(x,z,sx,sz,height,style)
		return
	building_count+=1
	var p:=pos(x,z)
	var yaw:=frontage_yaw(p)
	var actual_height:=clampf(height,12,55)
	kit.building(p,Vector3(sx,actual_height,sz),yaw,style)
	if building_count%4==0:
		kit.prop("Prop_ACUnit",p+Vector3(0,actual_height+0.05,0),yaw)
	if building_count%3==0:
		var front:=p+Basis(Vector3.UP,yaw)*Vector3(0,0,sz*0.5+1)
		kit.prop("Prop_Planter_Single",front,yaw)
func clover(label: String,center: Vector2,radius: float,start: float,from_y: float,to_y: float,extension:=Vector3.ZERO,approach:=Vector3.ZERO) -> void:
	var points:=PackedVector3Array()
	for i in range(241):
		var t:=float(i)/240
		var angle:=start+PI*1.5*t
		var p:=Vector3(center.x+radius*cos(angle),lerpf(from_y,to_y,smoothstep(0.2,0.8,t)),center.y+radius*sin(angle))
		p.y=maxf(p.y,ground(p.x,p.z))
		points.append(p)
	if approach!=Vector3.ZERO:
		var entry:=sampled(approach,points[0])
		entry.append_array(points.slice(1))
		points=entry
	if extension!=Vector3.ZERO:
		points.append_array(sampled(points[-1],extension).slice(1))
	road(label,points,8,groups.Ramps,true)
	ramp_map.append(points)
	named_routes[label]=points
	for i in range(12,points.size()-13):
		var right: Vector3=(points[i+1]-points[i]).cross(Vector3.UP).normalized()
		for side in [-1,1]:
			rail(points[i]+right*side*4,points[i+1]+right*side*4,groups.Ramps)

func flush_piers() -> void:
	for p in pier_candidates:
		var blocked:=false
		for group in [highway_map,ramp_map]:
			for path: PackedVector3Array in group:
				for i in range(path.size()-1):
					var a:=Vector2(path[i].x,path[i].z)
					var b:=Vector2(path[i+1].x,path[i+1].z)
					var q:=Geometry2D.get_closest_point_to_segment(Vector2(p.x,p.z),a,b)
					if q.distance_squared_to(Vector2(p.x,p.z))>16*16:
						continue
					var weight:=clampf((q-a).length()/maxf(a.distance_to(b),0.001),0,1)
					var y:=lerpf(path[i].y,path[i+1].y,weight)
					if y<p.y-2 and y>ground(p.x,p.z)-0.1:
						blocked=true
						break
				if blocked:
					break
			if blocked:
				break
		if not blocked:
			var height:=p.y-ground(p.x,p.z)-0.5
			box("ViaductPier",pos(p.x,p.z,height*0.5),Vector3(2.2,height,2.2),"Concrete",groups.Expressway)

func store_geometry() -> void:
	var folder:="res://world/hartford/generated/"
	assert(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))==OK)
	var index:=0
	for parent in groups.values():
		for mesh: MeshInstance3D in parent.find_children("*","MeshInstance3D",true,false):
			if mesh.mesh is ArrayMesh:
				var path: String = folder+"mesh_%04d.res"%index
				assert(ResourceSaver.save(mesh.mesh,path,ResourceSaver.FLAG_COMPRESS)==OK)
				mesh.mesh=ResourceLoader.load(path,"ArrayMesh",ResourceLoader.CACHE_MODE_IGNORE)
				index+=1
		for collision: CollisionShape3D in parent.find_children("*","CollisionShape3D",true,false):
			if collision.shape is ConcavePolygonShape3D:
				var path: String = folder+"collision_%04d.res"%index
				assert(ResourceSaver.save(collision.shape,path,ResourceSaver.FLAG_COMPRESS)==OK)
				collision.shape=ResourceLoader.load(path,"ConcavePolygonShape3D",ResourceLoader.CACHE_MODE_IGNORE)
				index+=1

func paint_streets() -> void:
	for request in paint_requests:
		var points: PackedVector3Array=request[0]
		for i in range(8,points.size()-8,32):
			kit.prop("Prop_ManholeCover",points[i]+Vector3.UP*0.015)
		if request[1]<10:
			continue
		for i in range(points.size()-1):
			if crosses_other_street((points[i]+points[i+1])*0.5,request[2]):
				continue
			var right: Vector3=(points[i+1]-points[i]).cross(Vector3.UP).normalized()
			for side in [-1,1]:
				stripe(points[i]+right*side*0.16+Vector3.UP*0.025,points[i+1]+right*side*0.16+Vector3.UP*0.025,0.12,"Yellow",groups.Details)
				if i%3==0:
					stripe(points[i]+right*side*3.6+Vector3.UP*0.025,points[i+1]+right*side*3.6+Vector3.UP*0.025,0.14,"White",groups.Details)
func _batch_details() -> void:
	super._batch_details()
	for mesh in groups.Details.get_children():
		# Water spans the district and must remain visible in distant skyline views.
		if mesh is MeshInstance3D and mesh.mesh.get_surface_count()>0 and mesh.mesh.surface_get_material(0).resource_name=="Water":
			mesh.visibility_range_end=0
