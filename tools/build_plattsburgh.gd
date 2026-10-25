extends SceneTree
const ROAD=preload("res://world/workshop/road.gd")
const HOUSE=preload("res://world/plattsburgh/footprint_building.gd")
const CATALOG=preload("res://world/workshop/catalog.gd")
var world:Node3D
var data:Dictionary
var heights:PackedFloat32Array
var water_heights:PackedFloat32Array
var bounds:Vector4
var size:Vector2i
var building_tiles:Dictionary={}
var roadside_cells:Dictionary={}
func _initialize()->void:call_deferred("run")
func own(node:Node)->void:CATALOG.own(node,world)
func vec(p:Array)->Vector3:return Vector3(p[0],p[1],p[2])
func height(x:float,z:float)->float:
 var gx:=clampf((x-bounds.x)/data.step,0,size.x-1.001);var gz:=clampf((z-bounds.y)/data.step,0,size.y-1.001);var ix:=int(gx);var iz:=int(gz);var fx:=gx-ix;var fz:=gz-iz
 return lerpf(lerpf(heights[iz*size.x+ix],heights[iz*size.x+ix+1],fx),lerpf(heights[(iz+1)*size.x+ix],heights[(iz+1)*size.x+ix+1],fx),fz)
func water_height(x:float,z:float)->float:
 var ix:=clampi(roundi((x-bounds.x)/data.step),0,size.x-1);var iz:=clampi(roundi((z-bounds.y)/data.step),0,size.y-1)
 return water_heights[iz*size.x+ix]
func tile_for(group:Node3D,point:Vector3,tiles:Dictionary)->Node3D:
 var id:=Vector2i(floori(point.x/1024),floori(point.z/1024))
 if not tiles.has(id):
  var tile:=Node3D.new();tile.name="Tile_%s_%s"%[id.x,id.y];tile.position=Vector3(id.x*1024,0,id.y*1024);group.add_child(tile);tiles[id]=tile;tile.owner=world
 return tiles[id]
func material(color:Color)->StandardMaterial3D:
 var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=.95;return m
func clear_roadside(p:Vector3)->bool:
 var cell:=Vector2i(floori(p.x/32),floori(p.z/32))
 for x in range(-1,2):
  for z in range(-1,2):
   for segment:Array in roadside_cells.get(cell+Vector2i(x,z),[]):
    var point:=Geometry2D.get_closest_point_to_segment(Vector2(p.x,p.z),Vector2(segment[0].x,segment[0].z),Vector2(segment[1].x,segment[1].z))
    if point.distance_to(Vector2(p.x,p.z))<segment[2]*.5+.7 and absf(p.y-(segment[0].y+segment[1].y)*.5)<2.4:return false
 return true
func make_box(parent:Node3D,title:String,position:Vector3,box_size:Vector3,mat:Material,solid:=false)->Node3D:
 var node:Node3D=StaticBody3D.new() if solid else Node3D.new();node.name=title;node.position=position;parent.add_child(node)
 var visual:=MeshInstance3D.new();visual.name="Visual";var mesh:=BoxMesh.new();mesh.size=box_size;mesh.material=mat;visual.mesh=mesh;node.add_child(visual)
 if solid:
  var collision:=CollisionShape3D.new();collision.name="Shape";var shape:=BoxShape3D.new();shape.size=box_size;collision.shape=shape;node.add_child(collision)
 own(node);return node
func run()->void:
 var region_script:Script=load("res://world/plattsburgh/region_world.gd")
 if region_script==null:quit(1);return
 data=JSON.parse_string(FileAccess.get_file_as_string("res://world/plattsburgh/data/region.json"));heights=FileAccess.get_file_as_bytes("res://world/plattsburgh/data/terrain_height.bin").to_float32_array()
 bounds=Vector4(data.bounds[0],data.bounds[1],data.bounds[2],data.bounds[3]);size=Vector2i(data.grid_size[0],data.grid_size[1])
 water_heights=FileAccess.get_file_as_bytes("res://world/plattsburgh/data/water_surface.bin").to_float32_array()
 world=Node3D.new();world.name="PlattsburghValcour";world.set_script(load("res://world/plattsburgh/region_world.gd"));world.world_title="PLATTSBURGH / THE CHAMPLAIN COAST";world.terrain_bounds=bounds;world.set_meta("workshop_world",true);world.set_meta("geographic_first_pass",false);world.set_meta("finish_version",1)
 var outline:=PackedVector2Array()
 for p:Array in data.west_edge:outline.append(Vector2(p[0],p[2]))
 # Eastern clipping limit is water; land/water recovery uses the actual mask.
 outline.append(Vector2(bounds.z,outline[-1].y));outline.append(Vector2(bounds.z,outline[0].y));world.play_outline=outline
 for name_value:String in ["Roads","Buildings","Props","Terrain","Dressing"]:
  var node:=Node3D.new();node.name=name_value;world.add_child(node);node.owner=world
 world.get_node("Roads").set_script(load("res://world/workshop/road_network.gd"))
 for entry:Dictionary in data.roads:
  var road:=Node3D.new();road.name="%s_%s"%[str(entry.name).validate_node_name().replace(" ","_"),entry.id];road.set_script(ROAD);road.set_meta("workshop_road",true);road.set_meta("workshop_item",true);road.set_meta("source_id",entry.id);road.set_meta("bridge_clearance_verified",false);road.set_meta("source_levels",entry.levels);road.road_width=entry.width;road.sidewalk_width=entry.sidewalk;road.curve_softness=0;road.sample_spacing=8
  road.set_meta("highway",entry.fcc=="A15");road.set_meta("street_name",entry.name)
  road.set_meta("elevated",entry.elevated)
  var points:=PackedVector3Array()
  for p:Array in entry.points:points.append(vec(p))
  road.points=points;world.get_node("Roads").add_child(road);road.owner=world
 print("REGION roads authored ",data.roads.size())
 for entry:Dictionary in data.buildings:
  var node:=Node3D.new();node.name="Property_%s"%entry.id;node.set_script(HOUSE);node.source_id=entry.id;node.wall_height=entry.height;node.facade_style=entry.style;node.roof_style=entry.roof
  if entry.has("front_target"):node.front_target=Vector2(entry.front_target[0],entry.front_target[1])
  node.architecture_variant=entry.get("architecture",0)
  node.foundation_depth=entry.get("foundation_depth",1.5)
  if not entry.has("foundation_depth"):
   var lowest:=INF
   for p:Array in entry.footprint:lowest=minf(lowest,height(entry.position[0]+p[0],entry.position[2]+p[1]))
   node.foundation_depth=maxf(1.5,entry.position[1]-lowest+.35)
  var points:=PackedVector2Array()
  for p:Array in entry.footprint:points.append(Vector2(p[0],p[1]))
  node.footprint=points;var position:=vec(entry.position);var tile:=tile_for(world.get_node("Buildings"),position,building_tiles);node.position=position-tile.position;tile.add_child(node);node.owner=world;node.set_meta("workshop_item",true);node.set_meta("real_footprint",true);node.set_meta("height_verified",false);node.rebuild();own(node)
 print("REGION buildings authored ",data.buildings.size())
 var terrain_material:=ShaderMaterial.new();terrain_material.shader=load("res://world/plattsburgh/terrain.gdshader");terrain_material.set_shader_parameter("macro_map",load("res://world/plattsburgh/data/land_cover.png"));terrain_material.set_shader_parameter("detail_map",load("res://assets/licensed/modern_city_architecture/grass_albedo.jpg"));terrain_material.set_shader_parameter("bounds",bounds)
 var terrain:=world.get_node("Terrain");var count:=0
 for tx in range(int(bounds.x/1024),int(bounds.z/1024)):
  for tz in range(int(bounds.y/1024),int(bounds.w/1024)):
   var tile:=Node3D.new();tile.name="Ground_%s_%s"%[tx,tz];tile.position=Vector3(tx*1024,0,tz*1024);terrain.add_child(tile);tile.owner=world
   var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var uvs:=PackedVector2Array();var indices:=PackedInt32Array();var grid:=65
   for iz in range(grid):
    for ix in range(grid):
     var x:=tile.position.x+ix*16;var z:=tile.position.z+iz*16;vertices.append(Vector3(ix*16,height(x,z),iz*16));normals.append(Vector3(height(x-2,z)-height(x+2,z),4,height(x,z-2)-height(x,z+2)).normalized());uvs.append(Vector2(x,z))
   for iz in range(grid-1):
    for ix in range(grid-1):
     var a:=iz*grid+ix;var b:=a+1;var c:=a+grid;var d:=c+1;indices.append_array(PackedInt32Array([a,b,c,b,d,c]))
   var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_TEX_UV]=uvs;arrays[Mesh.ARRAY_INDEX]=indices
   var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);mesh.surface_set_material(0,terrain_material)
   var visual:=MeshInstance3D.new();visual.name="Land";visual.mesh=mesh;tile.add_child(visual)
   var body:=StaticBody3D.new();body.name="GroundCollision";tile.add_child(body);var shape:=CollisionShape3D.new();shape.name="Shape";shape.shape=mesh.create_trimesh_shape();body.add_child(shape);own(tile);count+=1
 print("REGION terrain tiles ",count)
 var water:=Node3D.new();water.name="LakeChamplain";world.add_child(water);water.owner=world
 var water_material:=ShaderMaterial.new();water_material.shader=load("res://world/plattsburgh/water.gdshader");water_material.set_shader_parameter("water_mask",load("res://world/plattsburgh/data/water_mask.png"));water_material.set_shader_parameter("bounds",bounds)
 var mask:Image=load("res://world/plattsburgh/data/water_mask.png").get_image()
 if mask.is_compressed():mask.decompress()
 for tx in range(int(bounds.x/1024),int(bounds.z/1024)):
  for tz in range(int(bounds.y/1024),int(bounds.w/1024)):
   var origin:=Vector3(tx*1024,0,tz*1024);var vertices:=PackedVector3Array();var indices:=PackedInt32Array();var normals:=PackedVector3Array();var wet:=false
   for z in range(65):
    for x in range(65):
     var px:=origin.x+x*16;var pz:=origin.z+z*16;var ix:=clampi(roundi((px-bounds.x)/16),0,size.x-1);var iz:=clampi(roundi((pz-bounds.y)/16),0,size.y-1)
     if mask.get_pixel(ix,iz).r>.1:wet=true
     vertices.append(Vector3(x*16,water_height(px,pz),z*16));normals.append(Vector3.UP)
   if not wet:continue
   for z in range(64):
    for x in range(64):
     var a:=z*65+x;indices.append_array(PackedInt32Array([a,a+1,a+65,a+1,a+66,a+65]))
   var arrays:=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_INDEX]=indices
   var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);mesh.surface_set_material(0,water_material);var visual:=MeshInstance3D.new();visual.name="Water_%s_%s"%[tx,tz];visual.position=origin;visual.mesh=mesh;water.add_child(visual);visual.owner=world
 var props:=world.get_node("Props");var red:=material(Color("aa3d3a"));var gray:=material(Color("59616a"));var white:=material(Color("d6c7ad"))
 for i in range(data.closures.size()):
  var entry:Dictionary=data.closures[i];var p:=vec(entry.point);var toward:=vec(entry.toward);var direction:=(toward-p).normalized();var barrier:=make_box(props,"ClosedRoad_%s"%i,p+direction*2+Vector3.UP*.55,Vector3(entry.width+1,1.1,.8),red,true);barrier.rotation.y=atan2(direction.x,direction.z);barrier.set_meta("workshop_item",true)
  var label:=Label3D.new();label.text="ROAD CLOSED";label.font_size=48;label.pixel_size=.012;label.position=Vector3(0,.3,-.42);label.no_depth_test=false;label.modulate=Color("fff2c5");barrier.add_child(label);label.owner=world
 # A roadside boundary follows I-87, with smooth ground-following segments.
 for i in range(1,data.west_edge.size()):
  var a:=vec(data.west_edge[i-1]);var b:=vec(data.west_edge[i]);var span:=a.distance_to(b);var n:=maxi(1,ceili(span/24))
  for j in range(n):
   var p:=a.lerp(b,float(j)/n);var q:=a.lerp(b,float(j+1)/n);p.y=height(p.x,p.z);q.y=height(q.x,q.z);var rail:=make_box(props,"WestBoundary",(p+q)/2+Vector3.UP*1.2,Vector3(.3,2.4,p.distance_to(q)+.15),gray,true);rail.rotation.y=atan2(q.x-p.x,q.z-p.z)
 print("REGION closures ",data.closures.size())
 # Street names come from the source. Sign positions are editable approximations.
 var junctions:Dictionary={}
 for r:Dictionary in data.roads:
  if r.fcc=="A15":continue
  for at:int in [0,r.points.size()-1]:
   var point:=vec(r.points[at]);var key:=Vector2i(roundi(point.x),roundi(point.z))
   if not junctions.has(key):junctions[key]={"p":point,"names":[]}
   if not r.name in junctions[key].names:junctions[key].names.append(r.name)
 var signs:=0;var green:=material(Color("23544c"))
 for key:Vector2i in junctions:
  var info:Dictionary=junctions[key]
  if info.names.size()<2:continue
  var origin:Vector3=info.p+Vector3(7,0,7);var pole:=make_box(props,"StreetSign_%s"%signs,origin+Vector3.UP*1.9,Vector3(.08,3.8,.08),gray);var board:=make_box(pole,"StreetNames",Vector3(0,1.5,0),Vector3(3.8,.7,.1),green)
  var label:=Label3D.new();label.text=str(info.names[0])+"\n"+str(info.names[1]);label.font_size=38;label.pixel_size=.008;label.position.z=.07;label.double_sided=true;label.visibility_range_end=120;board.add_child(label);label.owner=world;pole.set_meta("workshop_item",true);pole.set_meta("placement_verified",false);own(pole);signs+=1
 # Approximate urban street lighting, kept away from junction mouths.
 for r:Dictionary in data.roads:
  for i in range(1,r.points.size()):
   var a:=vec(r.points[i-1]);var b:=vec(r.points[i]);var mid:=(a+b)*.5;var cell:=Vector2i(floori(mid.x/32),floori(mid.z/32))
   if not roadside_cells.has(cell):roadside_cells[cell]=[]
   roadside_cells[cell].append([a,b,float(r.width)])
 var lamps:=0
 for r:Dictionary in data.roads:
  if r.sidewalk<=0:continue
  var distance:=0.0
  for i in range(1,r.points.size()):
   var p:=vec(r.points[i-1]);var q:=vec(r.points[i]);distance+=p.distance_to(q)
   if distance<65 or i==r.points.size()-1:continue
   distance=0
   var side:=(q-p).cross(Vector3.UP).normalized();var candidate:Vector3=q+side*(float(r.width)*.5+float(r.sidewalk)*.7)
   if not clear_roadside(candidate):continue
   var lamp:=CATALOG.create("lamp",false);lamp.name="UrbanLamp_%s"%lamps;lamp.position=candidate;lamp.rotation.y=atan2(-side.z,side.x);lamp.set_meta("placement_verified",false);props.add_child(lamp);own(lamp);lamps+=1
 print("REGION urban lamps ",lamps)
 preload("res://world/plattsburgh/finish_dressing.gd").new().build(world,height)
 var start:=Marker3D.new();start.name="PlayerStart";start.position=vec(data.spawn)+Vector3.UP*.55;var direction:=vec(data.spawn_next)-vec(data.spawn);start.rotation.y=atan2(-direction.x,-direction.z);world.add_child(start);start.owner=world
 var env:=WorldEnvironment.new();env.name="NightEnvironment";env.environment=preload("res://world/night_lighting.gd").environment();env.environment.fog_density=.00038;env.environment.ambient_light_energy=.34;env.environment.glow_enabled=true;env.environment.glow_intensity=.35;env.environment.glow_bloom=.06;world.add_child(env);env.owner=world
 var moon:=DirectionalLight3D.new();moon.name="Moon";preload("res://world/night_lighting.gd").moon(moon);world.add_child(moon);moon.owner=world
 var packed:=PackedScene.new();assert(packed.pack(world)==OK);assert(ResourceSaver.save(packed,"res://world/handbuilt/plattsburgh_region.scn",ResourceSaver.FLAG_COMPRESS)==OK)
 print("REGION BUILD PASS: ",data.roads.size()," roads / ",data.buildings.size()," buildings / ",count," terrain tiles / ",signs," street signs")
 world.free();quit()
