extends "res://world/hartford/city_life.gd"
## Authored Main / Pearl / Trumbull / Asylum street-level pass.
## Soft furnishings do not add collision to the arcade driving surface.
const SITES := [Rect2(-251,-196,52,22),Rect2(-208,-72,24,26)]
var reserved_spaces: Array = SITES.duplicate()
var city: Node3D
var labels := 0
var storefronts := 0
var crossings := 0
var feature_points: Array[Vector3] = []

func _ready() -> void:
	name = "DowntownDetail"
	city = get_parent()
	city.set_meta("downtown_reserved_spaces",reserved_spaces)
	await get_tree().physics_frame
	space = get_world_3d().direct_space_state
	_setup_meshes()
	_parking_court(Vector2(-225,-185))
	_pocket_plaza(Vector2(-196,-59))
	_transit_stop(Vector2(-325,-108),-PI/2,"TRUMBULL / SOUTHBOUND")
	_transit_stop(Vector2(-13,-310),-PI/2,"MAIN / DOWNTOWN")
	_junctions()
	_storefronts()
	_service_courts()
	flush()
	set_meta("counts",counts)
	set_meta("storefront_count",storefronts)
	set_meta("crossing_count",crossings)
	set_meta("label_count",labels)
	city.set_meta("downtown_detail_ready",true)
	print("DOWNTOWN DETAIL: ",storefronts," storefronts, ",crossings," crossings, ",counts)

func _setup_meshes() -> void:
	var colors := {"metal":"27343b","wood":"796250","stone":"96958b","cream":"ddd7c4","green":"2d4f40","blue":"254a63","white":"d8d6bf","yellow":"b6a46b","black":"161d24","rubber":"202527"}
	for key: String in colors:
		meshes[key] = box_mesh(Vector3.ONE,Color(colors[key]))
	meshes.pole = cylinder(0.055,1,Color("65727a"))
	meshes.bollard = cylinder(0.075,0.85,Color("46565f"))
	meshes.seat = box_mesh(Vector3(2,0.08,0.12),Color("98724d"))
	meshes.back = box_mesh(Vector3(2,0.12,0.08),Color("98724d"))
	meshes.leg = box_mesh(Vector3(0.1,0.5,0.5),Color("283943"))
	meshes.planter = box_mesh(Vector3(1,1,1),Color("777b72"))
	meshes.shrub = SphereMesh.new(); meshes.shrub.radius = 0.5; meshes.shrub.height = 0.7
	meshes.shrub.material = material(Color("365742"))
	for kind: String in ["tree_ash","tree_linden"]:
		for level: String in ["near","far"]:
			var path := "res://assets/licensed/modern_city_architecture/"+kind+"_"+level+".res"
			if ResourceLoader.exists(path): meshes[kind+"_"+level] = load(path)
	for key: String in ["warm","cool"]:
		meshes[key] = box_mesh(Vector3.ONE,Color("eac48d") if key=="warm" else Color("9cc4d1"))
		meshes[key].material.emission_enabled = true
		meshes[key].material.emission = meshes[key].material.albedo_color
		meshes[key].material.emission_energy_multiplier = 1.4
	meshes.shop_window = box_mesh(Vector3.ONE,Color("3b352b"))
	meshes.shop_window.material.emission_enabled = true
	meshes.shop_window.material.emission = Color("886a3e")
	meshes.shop_window.material.emission_energy_multiplier = 0.35
	meshes.glass = box_mesh(Vector3.ONE,Color(0.11,0.21,0.27,0.35))
	meshes.glass.material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	meshes.glass.material.roughness = 0.12
	meshes.glass.material.cull_mode = BaseMaterial3D.CULL_DISABLED

func at(v: Vector2,up := 0.0) -> Vector3:
	return Vector3(v.x,ground(v.x,v.y)+up,v.y)

func block(key: String,p: Vector3,size: Vector3,yaw := 0.0) -> void:
	prop(key,p,yaw,size)

func _text(words: String,p: Vector3,yaw: float,width: float,color := Color("e4daca")) -> void:
	var label := Label3D.new(); label.text = words; label.font_size = 48
	label.pixel_size = width / maxf(1,words.length()*29)
	label.position = p; label.rotation.y = yaw; label.modulate = color
	label.outline_size = 0; label.no_depth_test = false
	label.visibility_range_end = 95; label.visibility_range_end_margin = 12
	label.shaded = false; label.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(label); labels += 1

func _surface(rect: Rect2,path: String,height: float) -> void:
	var surface := SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mat: Material = load(path); surface.set_material(mat)
	var a := at(rect.position,height); var b := at(rect.position+Vector2(rect.size.x,0),height)
	var c := at(rect.end,height); var d := at(rect.position+Vector2(0,rect.size.y),height)
	for p: Vector3 in [a,c,b,a,d,c]: surface.set_uv(Vector2(p.x,p.z)); surface.add_vertex(p)
	surface.generate_normals(); surface.index()
	var mesh := MeshInstance3D.new(); mesh.mesh = surface.commit(); mesh.name = "GradedSurface"
	mesh.visibility_range_end = 300; mesh.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(mesh)

func _parking_court(center: Vector2) -> void:
	_surface(SITES[0],"res://assets/licensed/modern_city_architecture/road.tres",0.028)
	# Two entrances remain open; paint and wheel stops delineate the court.
	for x in range(-249,-200,3):
		block("white",at(Vector2(x,-190),0.043),Vector3(0.085,0.018,5.0))
		if x < -201: block("rubber",at(Vector2(x+1.5,-192),0.1),Vector3(1.65,0.15,0.2))
	for x in [-249,-201]:
		block("stone",at(Vector2(x,-182),0.18),Vector3(1.8,0.35,3.8))
		block("green",at(Vector2(x,-182),0.4),Vector3(1.6,0.18,3.5))
		for z in [-183,-181]: prop("shrub",at(Vector2(x,z),0.7),0,Vector3(1.2,1,1.2))
	block("pole",at(center+Vector2(22,7),1.3),Vector3(1,2.6,1))
	block("blue",at(center+Vector2(22,7),2.6),Vector3(1.1,1.25,0.1))
	_text("P",at(center+Vector2(22,6.93),2.6),PI,0.65)
	_text("PUBLIC\nPARKING",at(center+Vector2(22,6.93),2.0),PI,0.85)
	for i in range(6):
		var catalog := preload("res://vehicles/vehicle_catalog.gd")
		var id: int = [2,4,8,2,4,8][i]
		var parked: Node3D = load(catalog.path_for(id)).instantiate()
		parked.name = "ParkedVehicle%02d"%i; parked.position = at(Vector2(-247.5+[0,2,5,8,11,14][i]*3,-190),0.04)
		parked.rotation.y = PI if i%2==0 else 0
		parked.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF; add_child(parked)
		for visual: MeshInstance3D in parked.find_children("*","MeshInstance3D",true,false):
			visual.visibility_range_end = 220; visual.visibility_range_end_margin = 20
	feature_points.append(at(center))
	set_meta("parking_spaces",16)

func _pocket_plaza(center: Vector2) -> void:
	_surface(SITES[1],"res://assets/licensed/modern_city_architecture/sidewalk.tres",0.035)
	for dz in [-9,9]:
		var site := center+Vector2(-6,dz)
		block("planter",at(site,0.24),Vector3(3,0.45,3))
		block("green",at(site,0.49),Vector3(2.8,0.08,2.8))
		if meshes.has("tree_ash_near"): tree(at(site,0.5),0 if dz<0 else 1)
		bench(at(center+Vector2(4,dz),0.06),PI/2)
	# Low paving bands reinforce the plaza without fencing off shortcuts.
	for dz in range(-11,12,4): block("stone",at(center+Vector2(0,dz),0.05),Vector3(23,0.02,0.12))
	block("stone",at(center+Vector2(-6,0),0.6),Vector3(0.55,1.2,2.8))
	_text("PEARL\nCOURT",at(center+Vector2(-5.7,0),0.85),PI/2,1.6)
	feature_points.append(at(center))
	set_meta("plaza_count",1)

func _transit_stop(center: Vector2,yaw: float,title: String) -> void:
	var base := at(center,0.12); var basis := Basis(Vector3.UP,yaw)
	# A roof, slim frame and three glass panels form a lit, human-scale shelter.
	for x in [-2.5,2.5]:
		for z in [-0.9,0.9]: block("metal",base+basis*Vector3(x,1.35,z),Vector3(0.08,2.7,0.08),yaw)
	block("metal",base+Vector3.UP*2.75,Vector3(5.5,0.15,2.3),yaw)
	block("warm",base+Vector3.UP*2.65,Vector3(4.6,0.025,0.5),yaw)
	block("glass",base+basis*Vector3(0,1.4,-0.9),Vector3(5,2.35,0.025),yaw)
	block("glass",base+basis*Vector3(-2.5,1.4,0),Vector3(0.025,2.35,1.8),yaw)
	bench(base+basis*Vector3(-0.4,0,-0.35),yaw)
	block("blue",base+basis*Vector3(1.75,1.5,-0.86),Vector3(1.1,1.7,0.07),yaw)
	_text("CITY\nTRANSIT",base+basis*Vector3(1.75,1.8,-0.81),yaw,0.85)
	block("pole",base+basis*Vector3(3.4,1.6,0),Vector3(1,3.2,1),yaw)
	block("blue",base+basis*Vector3(3.4,3.05,0),Vector3(0.65,0.75,0.08),yaw)
	_text("BUS",base+basis*Vector3(3.4,3.05,0.05),yaw,0.5)
	_text(title,base+basis*Vector3(0,2.83,1.17),yaw,4.2)
	lamp_positions.append(base+Vector3.UP*2.5)
	feature_points.append(base)

func _closest(point: Vector3,path: PackedVector3Array) -> Array:
	var best := INF; var found := point; var tangent := Vector3.FORWARD
	for i in range(path.size()-1):
		var a := path[i]; var b := path[i+1]; a.y=0; b.y=0
		var flat := Vector3(point.x,0,point.z)
		var q := Geometry3D.get_closest_point_to_segment(flat,a,b)
		var distance := flat.distance_squared_to(q)
		if distance<best: best=distance; found=q; tangent=(b-a).normalized()
	return [found,tangent,sqrt(best)]

func _junctions() -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://world/hartford/layout.json"))
	for key: String in ["PearlMain","AsylumMain","TrumbullPearl","TrumbullAsylum","TrumbullJewell","WellsMain"]:
		var geo: Array = layout.nodes[key]
		var p := at(Vector2((float(geo[0])+72.6732)*83025,-(float(geo[1])-41.7659)*111132))
		var names: Array[String] = []
		for index in range(layout.roads.size()):
			var road: Dictionary = layout.roads[index]
			if key not in road.nodes: continue
			names.append(road.name.trim_suffix(" Street"))
			var projected := _closest(p,city.map_roads[index])
			for side in [-1,1]:
				if side==-1 and key==road.nodes[0]: continue
				if side==1 and key==road.nodes[-1]: continue
				var sample: Vector3 = projected[0]+projected[1]*side*23
				var fit := _closest(sample,city.map_roads[index])
				if fit[0].distance_to(sample)>5: continue
				var tangent: Vector3 = fit[1]; var right := tangent.cross(Vector3.UP)
				var yaw := atan2(tangent.x,tangent.z)
				for stripe in range(-2,3):
					var q: Vector3 = fit[0]+tangent*stripe*0.85
					q.y = ground(q.x,q.z)+0.065
					block("white",q,Vector3(float(road.width)-1,0.02,0.42),yaw)
				crossings += 1
				var sign: Vector3 = fit[0]+right*(float(road.width)*0.5+2.1)
				sign.y = ground(sign.x,sign.z)
				block("pole",sign+Vector3.UP*1.7,Vector3(1,3.4,1))
				block("green",sign+Vector3.UP*3.15,Vector3(2.6,0.38,0.1),yaw)
				_text(road.name.to_upper(),sign+Vector3.UP*3.15+tangent*0.065,yaw,2.35)
		feature_points.append(p)

func _storefronts() -> void:
	var titles := ["PEARL COFFEE","NIGHT OWL RECORDS","CAPITAL CYCLE","TRUMBULL MARKET","LATE SHIFT DELI","RIVER CITY PRINT","UNION SNEAKERS","AFTER HOURS","CITY BOOKS","CORNER KITCHEN","CAPITAL PHOTO","STREET WORKS"]
	for body: StaticBody3D in city.find_children("*","StaticBody3D",true,false):
		if not body.has_meta("kit_model"): continue
		var p := body.global_position
		if p.x < -390 or p.x > 55 or p.z < -250 or p.z > 80: continue
		var nearest: Array = []; var distance := INF
		for index in [0,1,2,3,4]:
			var hit := _closest(p,city.map_roads[index])
			if hit[2]<distance: distance=hit[2]; nearest=hit
		if distance>52 or storefronts>=12: continue
		var size: Vector3 = body.get_child(0).shape.size
		var local: Vector3 = body.global_basis.inverse()*(nearest[0]-Vector3(p.x,0,p.z))
		var face: Vector3; var width: float
		if absf(local.x)/size.x>absf(local.z)/size.z:
			face=Vector3(signf(local.x),0,0); width=size.z
		else: face=Vector3(0,0,signf(local.z)); width=size.x
		var offset := face*size*0.5
		var normal := body.global_basis*face
		var front := p+body.global_basis*offset+normal*0.22
		if _road_distance(front)<15: continue
		front.y = ground(front.x,front.z)+0.08
		var yaw := atan2(normal.x,normal.z); var basis := Basis(Vector3.UP,yaw)
		var w := minf(10,width*0.65)
		block("black",front+Vector3.UP*1.5,Vector3(w,3,0.16),yaw)
		for side in [-1,1]:
			block("shop_window",front+basis*Vector3(side*w*0.32,1.55,0.1),Vector3(w*0.27,1.9,0.025),yaw)
			for shelf in [0.95,1.7]: block("wood",front+basis*Vector3(side*w*0.32,shelf,0.13),Vector3(w*0.26,0.055,0.04),yaw)
			for x in [-0.5,0,0.5]: block("metal",front+basis*Vector3(side*w*0.32+x*w*0.24,1.55,0.14),Vector3(0.045,2,0.035),yaw)
		block("glass",front+basis*Vector3(0,1.2,0.12),Vector3(1.25,2.4,0.04),yaw)
		block("metal",front+basis*Vector3(0.5,1.1,0.19),Vector3(0.04,0.35,0.04),yaw)
		block("green" if storefronts%2 else "blue",front+basis*Vector3(0,3.15,0.7),Vector3(w+0.5,0.2,1.5),yaw)
		block("black",front+basis*Vector3(0,3.65,0.05),Vector3(w,0.65,0.15),yaw)
		_text(titles[storefronts],front+basis*Vector3(0,3.65,0.14),yaw,w*0.86)
		block("warm",front+basis*Vector3(0,3.05,0.65),Vector3(w*0.8,0.025,0.08),yaw)
		lamp_positions.append(front+normal*1.5+Vector3.UP*2.8)
		reserved_spaces.append(Rect2(Vector2(front.x-7,front.z-7),Vector2(14,14)))
		feature_points.append(front); storefronts += 1

func _road_distance(p: Vector3) -> float:
	var best := INF
	for index in range(17): best=minf(best,_closest(p,city.map_roads[index])[2])
	return best

func _service_courts() -> void:
	# A narrow, usable service apron between the Asylum and rear-access streets.
	for x in [-295,-175,-65]:
		var p := at(Vector2(x,-184))
		block("green",p+Vector3.UP*0.6,Vector3(2.5,1.2,1.25))
		block("black",p+Vector3.UP*1.23,Vector3(2.6,0.1,1.35))
		for side in [-1,1]: block("rubber",p+Vector3(side,0.12,0.4),Vector3(0.18,0.24,0.18))
		block("wood",p+Vector3(2.1,0.12,0),Vector3(1.2,0.24,1))
		block("stone",p+Vector3(2.1,0.5,0),Vector3(0.8,0.5,0.65))
		feature_points.append(p)
