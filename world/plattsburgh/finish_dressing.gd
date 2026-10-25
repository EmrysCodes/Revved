@tool
extends RefCounted
## Offline scene authoring: shared meshes, spatially bounded batches and native ownership.
const CATALOG=preload("res://world/workshop/catalog.gd")
var world:Node3D
var parent:Node3D
var batches:Dictionary={}
var meshes:Dictionary={}
var tiles:Dictionary={}
var ground:Callable
var collision_boxes:Array[Transform3D]=[]
func mat(color:String)->StandardMaterial3D:
 var m:=StandardMaterial3D.new();m.albedo_color=Color(color);m.roughness=.92;return m
func box(key:String,size:Vector3,color:String)->void:
 var mesh:=BoxMesh.new();mesh.size=size;mesh.material=mat(color);meshes[key]=mesh
func add(key:String,p:Vector3,yaw:=0.0,scale_value:=Vector3.ONE)->void:
 var cell:=Vector2i(floori(p.x/128),floori(p.z/128));var id:="%s_%s_%s"%[key,cell.x,cell.y]
 if not batches.has(id):batches[id]={"key":key,"cell":cell,"transforms":[]}
 var transform_value:=Transform3D(Basis(Vector3.UP,yaw).scaled_local(scale_value),p);batches[id].transforms.append(transform_value)
 if key=="rail":collision_boxes.append(transform_value)
func beam(key:String,a:Vector3,b:Vector3,width:float,tall:float)->void:
 var d:=b-a
 var basis:=Basis.looking_at(d.normalized(),Vector3.UP).scaled_local(Vector3(width,tall,d.length()))
 var p:=(a+b)*.5;var cell:=Vector2i(floori(p.x/128),floori(p.z/128));var id:="%s_%s_%s"%[key,cell.x,cell.y]
 if not batches.has(id):batches[id]={"key":key,"cell":cell,"transforms":[]}
 var transform_value:=Transform3D(basis,p);batches[id].transforms.append(transform_value)
 if key=="rail":collision_boxes.append(transform_value)
func tile(cell:Vector2i)->Node3D:
 if not tiles.has(cell):
  var t:=Node3D.new();t.name="Detail_%s_%s"%[cell.x,cell.y];t.position=Vector3(cell.x*128,0,cell.y*128);parent.add_child(t);tiles[cell]=t;t.owner=world
 return tiles[cell]
func build(root:Node3D,height_function:Callable)->void:
 world=root;ground=height_function;parent=world.get_node("Dressing")
 var d:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://world/plattsburgh/data/dressing.json"))
 var paving_tools:Dictionary={}
 for triangle:Array in d.paving_triangles:
  var a:=Vector3(triangle[0][0],triangle[0][1],triangle[0][2]);var b:=Vector3(triangle[1][0],triangle[1][1],triangle[1][2]);var c:=Vector3(triangle[2][0],triangle[2][1],triangle[2][2]);var center:=(a+b+c)/3;var cell:=Vector2i(floori(center.x/128),floori(center.z/128));var t:=tile(cell)
  if not paving_tools.has(cell):
   var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tool.set_material(load("res://assets/licensed/modern_city_architecture/road.tres"));paving_tools[cell]=tool
  var tool:SurfaceTool=paving_tools[cell]
  if (b-a).cross(c-a).y>0:var swap:=b;b=c;c=swap
  for p:Vector3 in [a,b,c]:tool.set_uv(Vector2(p.x,p.z)*.2);tool.add_vertex(p-t.position)
 for cell:Vector2i in paving_tools:
  var tool:SurfaceTool=paving_tools[cell];tool.generate_normals();tool.index();var visual:=MeshInstance3D.new();visual.name="PropertyAprons";visual.mesh=tool.commit();visual.visibility_range_end=850;tile(cell).add_child(visual);visual.owner=world
 for key:String in ["tree_ash","tree_linden"]:
  for lod:String in ["near","far"]:meshes[key+"_"+lod]=load("res://assets/licensed/modern_city_architecture/"+key+"_"+lod+".res")
 box("rail",Vector3.ONE,"939991");box("deck",Vector3.ONE,"565b58");box("white",Vector3.ONE,"c9c9bb");box("paving",Vector3.ONE,"373b3d");box("concrete",Vector3.ONE,"8b897c")
 box("seat",Vector3(1.9,.09,.16),"745437");box("back",Vector3(1.9,.14,.09),"745437");box("leg",Vector3(.09,.48,.52),"27373a");box("bin",Vector3(.55,.85,.55),"344943")
 for tree:Array in d.trees:
  var key:String="tree_ash" if int(tree[4])==0 else "tree_linden";var p:=Vector3(tree[0],tree[1],tree[2]);var scale_value:float=float(tree[3])/meshes[key+"_near"].get_aabb().size.y
  for lod:String in ["near","far"]:add(key+"_"+lod,p,tree[5],Vector3.ONE*scale_value)
 for f:Dictionary in d.furniture:
  var p:=Vector3(f.p[0],f.p[1],f.p[2]);var yaw:float=f.yaw;var b:=Basis(Vector3.UP,yaw)
  if f.kind=="bin":add("bin",p+Vector3.UP*.425);continue
  for z:float in [-.24,-.08,.08,.24]:add("seat",p+b*Vector3(0,.52,z),yaw)
  for y:float in [.78,.98]:add("back",p+b*Vector3(0,y,.30),yaw)
  for x:float in [-.73,.73]:add("leg",p+b*Vector3(x,.24,0),yaw)
 for drive:Dictionary in d.drives:
  var p:=Vector3(drive.points[0][0],drive.points[0][1],drive.points[0][2]);var q:=Vector3(drive.points[1][0],drive.points[1][1],drive.points[1][2]);var end:=Vector3(drive.points[2][0],drive.points[2][1],drive.points[2][2]);var width:=q.distance_to(end)
  # Thin slabs follow the endpoint grade, allowing a low traversable lip.
  beam("paving",(p+Vector3(drive.points[3][0],drive.points[3][1],drive.points[3][2]))*.5,(q+end)*.5,width,.08)
 var parked:=0
 for lot:Dictionary in d.lots:
  var p:=Vector3(lot.center[0],lot.center[1],lot.center[2]);var yaw:float=lot.yaw;var basis:=Basis(Vector3.UP,yaw)
  add("paving",p,yaw,Vector3(18,.10,12))
  for side:float in [-1,1]:
   for n in range(7):add("white",p+basis*Vector3(-8+n*2.65,.07,side*3.8),yaw,Vector3(.09,.025,4.2))
  if parked<90 and int(lot.seed)%3==0:
   var car:=CATALOG.create("car_8",true)
   if car:
    car.name="ParkedCar_%s"%parked;var t:=tile(Vector2i(floori(p.x/128),floori(p.z/128)));t.add_child(car);car.position=p-t.position+basis*Vector3(-4,.1,3.7);car.rotation.y=yaw;CATALOG.own(car,world);parked+=1
 for segment:Dictionary in d.bridges:
  var a:=Vector3(segment.a[0],segment.a[1],segment.a[2]);var b:=Vector3(segment.b[0],segment.b[1],segment.b[2]);var right:Vector3=(b-a).cross(Vector3.UP).normalized();var width:float=segment.width
  beam("deck",a-Vector3.UP*.48,b-Vector3.UP*.48,width+.8,.8)
  for side:float in [-1,1]:
   var p:Vector3=a+right*(width*.5+.35)*side;var q:Vector3=b+right*(width*.5+.35)*side
   beam("rail",p+Vector3.UP*.65,q+Vector3.UP*.65,.20,.28)
   beam("rail",p+Vector3.UP*1.1,q+Vector3.UP*1.1,.12,.12)
   add("rail",p+Vector3.UP*.55,0,Vector3(.18,1.1,.18))
  if segment.support:
   var p:Vector3=(a+b)*.5;var h:float=p.y-float(ground.call(p.x,p.z))-.9
   if h>2:add("concrete",p-Vector3.UP*(h*.5+.9),0,Vector3(1.2,h,width*.6))
 flush()
 var collision_tool:=SurfaceTool.new();collision_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 for transform_value:Transform3D in collision_boxes:collision_tool.append_from(meshes.rail,0,transform_value)
 collision_tool.index();var collision_mesh:=collision_tool.commit()
 if collision_mesh:
  var body:=StaticBody3D.new();body.name="BridgeRailCollision";parent.add_child(body);var shape:=CollisionShape3D.new();shape.name="Shape";shape.shape=collision_mesh.create_trimesh_shape();body.add_child(shape);CATALOG.own(body,world)
 parent.set_meta("tree_count",d.trees.size());parent.set_meta("parking_lots",d.lots.size());parent.set_meta("driveways",d.drives.size());parent.set_meta("furniture",d.furniture.size());parent.set_meta("bridge_segments",d.bridges.size())
 print("REGION FINISH trees=",d.trees.size()," lots=",d.lots.size()," drives=",d.drives.size()," furniture=",d.furniture.size()," parked=",parked," batches=",batches.size())
func flush()->void:
 for id:String in batches:
  var batch:Dictionary=batches[id];var t:=tile(batch.cell);var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=meshes[batch.key];mm.instance_count=batch.transforms.size()
  var placements:Array[Transform3D]=[];var bounds:=AABB()
  for i in range(mm.instance_count):
   var transform_value:Transform3D=batch.transforms[i];transform_value.origin-=t.position;placements.append(transform_value)
   var instance_bounds:AABB=transform_value*mm.mesh.get_aabb()
   bounds=instance_bounds if i==0 else bounds.merge(instance_bounds)
  var visual:=MultiMeshInstance3D.new();visual.name=batch.key;visual.multimesh=mm;visual.visibility_range_end=600;visual.visibility_range_end_margin=30
  visual.set_script(load("res://world/plattsburgh/dressing_instances.gd"));visual.placements=placements;visual.custom_aabb=bounds
  if str(batch.key).ends_with("_near"):visual.visibility_range_end=160;visual.visibility_range_end_margin=15
  elif str(batch.key).ends_with("_far"):visual.visibility_range_begin=145;visual.visibility_range_begin_margin=15;visual.visibility_range_end=1500;visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  t.add_child(visual);visual.owner=world
 batches.clear()
