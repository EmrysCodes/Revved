extends RefCounted
## Authored, compressed East Hartford district informed by the town's Founders Plaza plan.
## Street relationships and land uses are references, not surveyed coordinates.
var road_indices:Dictionary={}
var parcels:=0
var parking_lots:=0
var storefronts:=0
var junctions:Array[Vector3]=[]
var b
const SHOPS:=["PITKIN COFFEE","RIVER CITY CYCLES","EASTSIDE MARKET","MAIN ST RECORDS","FOUNDRY AUTO","HARTLAND DINER","NIGHT SHIFT GARAGE","CORNER PHARMACY","RIVERFRONT BOOKS","EASTSIDE LAUNDRY","BLOCK 84 SNEAKERS","FOUNDERS PIZZA"]
func _init(builder) -> void:b=builder
func street(name:String,points:Array,width:float) -> void:
	var anchors:=PackedVector3Array()
	for p:Array in points:anchors.append(b.pos(p[0],p[1]))
	road_indices[name]=b.road_map.size()
	b.local_path("Eastside_"+name,b.smooth_route(anchors),width)
func roads() -> void:
	street("MainStreet",[[1570,-520],[1590,-180],[1575,220],[1600,570],[1560,970]],20)
	street("ConnecticutBoulevard",[[1137,-310],[1390,-330],[1590,-340],[1790,-310]],20)
	street("PitkinStreet",[[1137,180],[1370,200],[1575,220],[1810,205]],18)
	street("HartlandStreet",[[1137,490],[1370,500],[1590,500],[1790,530]],16)
	street("SilverLane",[[1137,1000],[1360,875],[1560,830],[1740,810]],20)
	street("JayceStreet",[[1450,-330],[1435,0],[1445,210],[1435,500],[1445,880]],14)
	street("ProspectStreet",[[1790,-310],[1810,-35],[1810,205],[1790,530],[1740,810]],14)
	street("MeadowStreet",[[1137,710],[1350,725],[1580,730],[1760,720]],14)
	street("NeighborhoodNorth",[[1440,-60],[1600,-50],[1810,-35]],12)
	street("NeighborhoodCenter",[[1440,350],[1580,360],[1800,365]],12)
	street("DarlinStreet",[[1375,-325],[1380,-70],[1380,200],[1360,500]],12)
	street("FoundryService",[[1680,205],[1690,365],[1680,530],[1670,730]],8)
	street("FoundryLoading",[[1445,880],[1450,940],[1558,970]],8)
	for name in ["FoundryService","FoundryLoading"]:
		b.alley_count+=1
		# No sidewalk lips or lane paint across service entrances.
		var index:int=road_indices[name]
		b.paint_requests=b.paint_requests.filter(func(request):return request[2]!=index)
		b.sidewalk_requests=b.sidewalk_requests.filter(func(request):return request[2]!=index)
	for z in [-330.0,-50.0,220.0,360.0,500.0,730.0,830.0]:
		var nearest:=Vector3.ZERO;var best:=INF
		for point:Vector3 in b.road_map[road_indices.MainStreet]:
			if absf(point.z-z)<best:best=absf(point.z-z);nearest=point
		junctions.append(nearest)
	b.city.set_meta("eastside_roads",road_indices)
	b.city.set_meta("districts",[
		{"id":"downtown","name":"DOWNTOWN / CAPITOL","bounds":Rect2(-1820,-1350,2320,2770),"style":"Tight mixed-use blocks, civic landmarks, park edges and office towers"},
		{"id":"eastside","name":"EASTSIDE / FOUNDERS","bounds":Rect2(990,-520,920,1550),"style":"Main Street shops, apartments, industrial service yards and riverfront open space"}])
func lots() -> void:
	# Every parcel is checked against the complete road, ramp and highway network.
	# Narrower shop lots, apartment courts and larger industrial parcels alternate.
	for x in range(1065,1866,42):
		for z in range(-400,981,47):
			var p:Vector3=b.pos(x,z)
			if x<1350:continue # Existing riverfront blocks and park reserve remain intact.
			if x>1770 and z>740 or x>1870 and z>420:continue
			var width:=25.0 if x<1710 else 29.0
			var depth:=28.0
			var radius:=Vector2(width,depth).length()*.5+2
			if not b.clear_parcel(p,radius):continue
			if b.road_distance(p,b.highway_map)<radius+19 or b.road_distance(p,b.ramp_map)<radius+14:continue
			var blocked:=false
			for other:Vector3 in b.reserved_blocks:
				if Vector2(p.x-other.x,p.z-other.z).length()<radius+other.y:blocked=true;break
			if blocked:continue
			# Open parking courts are intentional land uses, never unassigned empty slabs.
			if parcels%8==5:
				parking(p,width+5,depth+4);parking_lots+=1
			else:
				var height:=12.0+float(parcels%4)*5
				if z>760:height=12
				b.building(p.x,p.z,width,depth,height,parcels%3)
				b.terrain_patch("EastsideParcel",p.x-width*.5-2,p.z-depth*.5-2,p.x+width*.5+2,p.z+depth*.5+2,"Walk",.006,b.groups.Details,false)
				if parcels%3!=0:shop(p,depth,b.frontage_yaw(p),SHOPS[parcels%SHOPS.size()])
			b.reserved_blocks.append(Vector3(p.x,radius+2,p.z));parcels+=1
	for p in junctions:crosswalks(p)
	for entry in [["EASTSIDE / FOUNDERS",Vector3(1450,0,-300)],["PITKIN STREET",Vector3(1525,0,220)],["MAIN STREET",Vector3(1600,0,630)],["GREAT RIVER PARK",Vector3(1080,0,650)],["NIGHT SHIFT / INDUSTRIAL ROW",Vector3(1450,0,900)]]:
		var p:Vector3=entry[1];p.y=b.ground(p.x,p.z)+5
		b.label_sign(entry[0],p,0,b.groups.Signs)
	b.city.set_meta("eastside_parcels",parcels)
	b.city.set_meta("eastside_parking",parking_lots)
	b.city.set_meta("eastside_shops",storefronts)
func shop(p:Vector3,depth:float,yaw:float,title:String) -> void:
	var basis:=Basis(Vector3.UP,yaw)
	var front:=p+basis*Vector3(0,0,depth*.5+.35)
	var glass:Node3D=b.box("EastsideShopWindow",front+Vector3.UP*2,Vector3(17,2.6,.08),"Window",b.groups.Details,false)
	glass.rotation.y=yaw
	var awning:Node3D=b.box("ShopAwning",front+Vector3.UP*4.1+basis*Vector3(0,0,.7),Vector3(18,.22,2),"GreenSign" if storefronts%2==0 else "Gold",b.groups.Details,false)
	awning.rotation.y=yaw
	b.label_sign(title,front+Vector3.UP*4.9+basis*Vector3(0,0,.9),yaw,b.groups.Signs)
	for side in [-1,1]:
		var post:Node3D=b.box("ShopWindowFrame",front+Vector3.UP*2+basis*Vector3(side*8.5,0,.04),Vector3(.12,2.9,.12),"Concrete",b.groups.Details,false);post.rotation.y=yaw
	storefronts+=1
func parking(p:Vector3,width:float,depth:float) -> void:
	b.terrain_patch("MarkedParkingCourt",p.x-width*.5,p.z-depth*.5,p.x+width*.5,p.z+depth*.5,"Asphalt",.018,b.groups.Details,false)
	for side in [-1,1]:
		for j in range(5):
			var x:float=p.x-width*.5+3+j*5.5
			b.stripe(b.pos(x,p.z+side*(depth*.5-1),.04),b.pos(x,p.z+side*(depth*.5-6),.04),.11,"White",b.groups.Details)
	var sign:Vector3=b.pos(p.x-width*.5+1,p.z-depth*.5+1,2.2)
	b.label_sign("P / CUSTOMER PARKING",sign,0,b.groups.Signs)
func crosswalks(p:Vector3) -> void:
	for approach in [-1,1]:
		for band in range(8):
			var x:float=p.x-8.5+band*2.4
			b.stripe(b.pos(x,p.z+approach*16-2,.055),b.pos(x,p.z+approach*16+2,.055),1.2,"White",b.groups.Details)
	# Corner islands leave a generous accessible, driveable pavement edge.
	for side in [-1,1]:
		b.kit.prop("Prop_Planter_Single",b.pos(p.x+side*15,p.z+23),0)
