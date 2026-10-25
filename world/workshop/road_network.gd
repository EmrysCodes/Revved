@tool
extends Node3D
## Shared pavement topology. Only endpoints at the same actual elevation join.
## Geometry is batched spatially; source roads remain individual editable nodes.
@export var tile_size:=1024.0
var _pending:=false
var revision:=0
var stats:Dictionary={}
var _tiles:Dictionary={}
var _materials:Array[Material]=[]
var _collision_tool:SurfaceTool
func _ready()->void:
 child_entered_tree.connect(func(n:Node):
  if n.has_meta("workshop_road"):request_rebuild())
 child_exiting_tree.connect(func(n:Node):
  if n.has_meta("workshop_road"):request_rebuild())
 request_rebuild()
func request_rebuild()->void:
 if _pending or not is_inside_tree():return
 _pending=true;call_deferred("_flush_rebuild")
func _flush_rebuild()->void:
 if not is_inside_tree():_pending=false;return
 await get_tree().process_frame
 if is_inside_tree():rebuild_network()
func _mat(color:Color)->StandardMaterial3D:
 var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=.95;return mat
func _key(p:Vector3)->Vector3i:return Vector3i(roundi(p.x*10),roundi(p.y*10),roundi(p.z*10))
func _tile(p:Vector3)->Dictionary:
 var id:=Vector2i(floori(p.x/tile_size),floori(p.z/tile_size))
 if not _tiles.has(id):
  var tools:Array[SurfaceTool]=[]
  for i in range(5):
   var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tool.set_material(_materials[i]);tools.append(tool)
  _tiles[id]={"tools":tools,"counts":[0,0,0,0,0],"origin":Vector3(id.x*tile_size,0,id.y*tile_size)}
 return _tiles[id]
func _tri(kind:int,a:Vector3,b:Vector3,c:Vector3)->void:
 if (b-a).cross(c-a).length_squared()<.0000001:return
 if (b-a).cross(c-a).y>0:
  var swap:=b;b=c;c=swap
 var tile:=_tile((a+b+c)/3);var tool:SurfaceTool=tile.tools[kind]
 for point:Vector3 in [a,b,c]:tool.set_uv(Vector2(point.x,point.z)*.12);tool.add_vertex(point-tile.origin)
 if kind<2 or kind==4:
  for point:Vector3 in [a,b,c]:_collision_tool.add_vertex(point)
 tile.counts[kind]+=3
func _quad(kind:int,a:Vector3,b:Vector3,c:Vector3,d:Vector3)->void:_tri(kind,a,b,c);_tri(kind,a,c,d)
func _length(points:PackedVector3Array)->float:
 var result:=0.0
 for i in range(1,points.size()):result+=points[i-1].distance_to(points[i])
 return result
func _at(points:PackedVector3Array,distance:float)->Vector3:
 for i in range(1,points.size()):
  var span:=points[i-1].distance_to(points[i])
  if distance<=span:return points[i-1].lerp(points[i],distance/maxf(.0001,span))
  distance-=span
 return points[-1]
func _trim(points:PackedVector3Array,start:float,end:float)->PackedVector3Array:
 var total:=_length(points);var output:=PackedVector3Array([_at(points,start)]);var distance:=0.0
 for i in range(1,points.size()):
  distance+=points[i-1].distance_to(points[i])
  if distance>start+.01 and distance<total-end-.01:output.append(points[i])
 output.append(_at(points,total-end));return output
func _right(points:PackedVector3Array,i:int)->Vector3:
 var d:=points[mini(i+1,points.size()-1)]-points[maxi(0,i-1)];d.y=0;return d.cross(Vector3.UP).normalized()
func _walk(a:Vector3,b:Vector3,ra:Vector3,rb:Vector3,half:float,width:float)->void:
 if width<=0:return
 for side:float in [-1,1]:
  var a0:=a+ra*half*side;var b0:=b+rb*half*side
  var a1:=a+ra*(half+.45)*side+Vector3.UP*.12;var b1:=b+rb*(half+.45)*side+Vector3.UP*.12
  var a2:=a+ra*(half+width)*side+Vector3.UP*.12;var b2:=b+rb*(half+width)*side+Vector3.UP*.12
  _quad(1,a0,b0,b1,a1);_quad(1,a1,b1,b2,a2)
  _quad(1,a2,b2,b+rb*(half+width+.75)*side-Vector3.UP*.25,a+ra*(half+width+.75)*side-Vector3.UP*.25)
func rebuild_network()->void:
 _pending=false
 if not is_inside_tree():return
 _collision_tool=SurfaceTool.new();_collision_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 var old:=get_node_or_null("_GeneratedNetwork")
 if old:remove_child(old);old.queue_free()
 _tiles.clear();_materials=[_mat(Color("30353b")),_mat(Color("8b8a80")),_mat(Color("c5ac64")),_mat(Color("d8d7ca")),_mat(Color("6b6859"))]
 if ResourceLoader.exists("res://assets/licensed/modern_city_architecture/sidewalk.tres"):
  _materials[1]=load("res://assets/licensed/modern_city_architecture/sidewalk.tres").duplicate();_materials[1].roughness=.96;_materials[1].metallic=0;_materials[1].roughness_texture=null;_materials[1].metallic_texture=null
 # Shared source texture, deliberately rough to avoid flickering/specular roads.
 if ResourceLoader.exists("res://assets/licensed/modern_city_architecture/road.tres"):
  _materials[0]=load("res://assets/licensed/modern_city_architecture/road.tres").duplicate();_materials[0].roughness=.96;_materials[0].metallic=0;_materials[0].roughness_texture=null;_materials[0].metallic_texture=null
 var sources:Array[Dictionary]=[];var endpoints:Dictionary={}
 for road:Node3D in get_children():
  if not road.has_meta("workshop_road"):continue
  var points:PackedVector3Array=road._make_curve();var to_parent:=road.transform
  for i in range(points.size()):points[i]=to_parent*points[i]
  if points.size()<2:continue
  var box:=AABB(points[0],Vector3.ZERO)
  for p:Vector3 in points:box=box.expand(p)
  road.network_bounds=box.grow(road.road_width*.5+road.sidewalk_width+2)
  sources.append({"road":road,"points":points})
  endpoints[_key(points[0])]=points[0];endpoints[_key(points[-1])]=points[-1]
 # An endpoint clicked onto an existing sampled road also splits that road into a T.
 var edges:Array[Dictionary]=[];var nodes:Dictionary={}
 for source:Dictionary in sources:
  var pts:PackedVector3Array=source.points;var cut:=0
  for i in range(1,pts.size()):
   if i<pts.size()-1 and not endpoints.has(_key(pts[i])):continue
   var sub:=pts.slice(cut,i+1);cut=i
   if _length(sub)<.05:continue
   var edge:Dictionary={"points":sub,"width":source.road.road_width,"walk":source.road.sidewalk_width,"road":source.road,"a":_key(sub[0]),"b":_key(sub[-1])}
   var index:=edges.size();edges.append(edge)
   for end:int in [0,1]:
    var k:Vector3i=edge.a if end==0 else edge.b
    if not nodes.has(k):nodes[k]=[]
    nodes[k].append({"edge":index,"end":end})
 var mouths:Dictionary={};var junctions:=0
 for index in range(edges.size()):
  var edge:Dictionary=edges[index];var pts:PackedVector3Array=edge.points;var length:=_length(pts);var cuts:=[0.0,0.0]
  for end:int in [0,1]:
   var k:Vector3i=edge.a if end==0 else edge.b
   if nodes[k].size()>1:cuts[end]=minf(edge.width*.9,length*.32)
  var clipped:=_trim(pts,cuts[0],cuts[1])
  # Slight overlap closes the numerical seams between a strip and its junction.
  # Terminal caps extend beyond the source point so ray/tyre contact is stable.
  var start_direction:Vector3=(clipped[1]-clipped[0]).normalized()
  var end_direction:Vector3=(clipped[-1]-clipped[-2]).normalized()
  clipped[0]-=start_direction*.12;clipped[-1]+=end_direction*.12
  for end:int in [0,1]:
   var k:Vector3i=edge.a if end==0 else edge.b
   if nodes[k].size()<2:continue
   var at:=0 if end==0 else clipped.size()-1;var p:=clipped[at];var right:Vector3=_right(clipped,at)*float(edge.width)*.5
   if not mouths.has(k):mouths[k]=[]
   mouths[k].append({"left":p-right,"right":p+right,"walk":edge.walk,"edge":index})
  for i in range(clipped.size()-1):
   var a:=clipped[i];var b:=clipped[i+1];var ra:=_right(clipped,i);var rb:=_right(clipped,i+1);var half:float=edge.width*.5
   _quad(0,a-ra*half,b-rb*half,b+rb*half,a+ra*half);_walk(a,b,ra,rb,half,edge.walk)
   if edge.walk<=0 and not edge.road.get_meta("elevated",false):
    for side:float in [-1,1]:_quad(4,a+ra*half*side,b+rb*half*side,b+rb*(half+2.4)*side-Vector3.UP*.55,a+ra*(half+2.4)*side-Vector3.UP*.55)
   # Continuous edge lines make the carriageway readable at night.
   if edge.width>=6:
    for side:float in [-1,1]:
     var offset:float=(half-.22)*side
     _quad(3,a+ra*(offset-.055)+Vector3.UP*.024,b+rb*(offset-.055)+Vector3.UP*.024,b+rb*(offset+.055)+Vector3.UP*.024,a+ra*(offset+.055)+Vector3.UP*.024)
   if edge.road.get_meta("highway",false):
    if i%2==0:_quad(3,a-ra*.055+Vector3.UP*.024,b-rb*.055+Vector3.UP*.024,b+rb*.055+Vector3.UP*.024,a+ra*.055+Vector3.UP*.024)
   elif edge.width>=7.5:
    for offset:float in [-.14,.14]:_quad(2,a+ra*(offset-.045)+Vector3.UP*.018,b+rb*(offset-.045)+Vector3.UP*.018,b+rb*(offset+.045)+Vector3.UP*.018,a+ra*(offset+.045)+Vector3.UP*.018)
 for key:Vector3i in mouths:
  var branches:Array=mouths[key];var polygon:=PackedVector2Array();var records:Array[Dictionary]=[]
  if branches.size()>=3:
   for branch:Dictionary in branches:
    if branch.walk<=0:continue
    var midpoint:Vector3=(branch.left+branch.right)*.5
    var across:Vector3=(branch.right-branch.left).normalized()
    var outward:Vector3=(midpoint-Vector3(key)/10).normalized()
    var span:float=branch.left.distance_to(branch.right)
    for stripe in range(floori((span-1)/.85)):
     var a:Vector3=branch.left+across*(.5+stripe*.85)+outward*.7+Vector3.UP*.03
     _quad(3,a,a+across*.4,a+across*.4+outward*2.5,a+outward*2.5)
  for branch:Dictionary in branches:
   for point:Vector3 in [branch.left,branch.right]:polygon.append(Vector2(point.x,point.z));records.append({"p":point,"edge":branch.edge,"walk":branch.walk})
  # Include the actual node inside the patch, including acute merges / cul-de-sacs.
  # This prevents trimming two same-side approaches away from their shared endpoint.
  var node_point:=Vector3(key)/10
  for j in range(12):
   var angle:=TAU*j/12;var p:=node_point+Vector3(cos(angle),0,sin(angle))*.25
   polygon.append(Vector2(p.x,p.z));records.append({"p":p,"edge":-1,"walk":0.0})
  var hull:=Geometry2D.convex_hull(polygon)
  if hull.size()<4:continue
  var center:=Vector3(key)/10;var ring:Array[Dictionary]=[]
  for i in range(hull.size()-1):
   var best:Dictionary=records[0];var distance:=INF
   for rec:Dictionary in records:
    var d:=Vector2(rec.p.x,rec.p.z).distance_squared_to(hull[i])
    if d<distance:distance=d;best=rec
   ring.append(best)
  for i in range(ring.size()):
   var a:Dictionary=ring[i];var b:Dictionary=ring[(i+1)%ring.size()]
   _tri(0,center,a.p,b.p)
   # Leave each incoming mouth completely open; curb only the corner edges.
   if a.edge==b.edge:continue
   var width:float=minf(a.walk,b.walk)
   if width<=0:continue
   var outward:Vector3=(b.p-a.p).cross(Vector3.UP).normalized()
   if outward.dot((a.p+b.p)*.5-center)<0:outward=-outward
   var up:=Vector3.UP*.12
   _quad(1,a.p,b.p,b.p+outward*.45+up,a.p+outward*.45+up)
   _quad(1,a.p+outward*.45+up,b.p+outward*.45+up,b.p+outward*width+up,a.p+outward*width+up)
   _quad(1,a.p+outward*width+up,b.p+outward*width+up,b.p+outward*(width+.75)-Vector3.UP*.25,a.p+outward*(width+.75)-Vector3.UP*.25)
  if branches.size()==2:
   var a:Vector3=(branches[0].left+branches[0].right)*.5;var b:Vector3=(branches[1].left+branches[1].right)*.5
   if (a-center).normalized().dot((b-center).normalized())< -.94:
    var ra:Vector3=(branches[0].right-branches[0].left).normalized();var rb:Vector3=(branches[1].right-branches[1].left).normalized()
    if ra.dot(rb)<0:rb=-rb
    if a.distance_to(branches[0].left)>=3.7 and b.distance_to(branches[1].left)>=3.7:
     for offset:float in [-.14,.14]:_quad(2,a+ra*(offset-.045)+Vector3.UP*.018,b+rb*(offset-.045)+Vector3.UP*.018,b+rb*(offset+.045)+Vector3.UP*.018,a+ra*(offset+.045)+Vector3.UP*.018)
  junctions+=1
 var generated:=Node3D.new();generated.name="_GeneratedNetwork";generated.set_meta("workshop_generated",true);add_child(generated)
 var triangles:=0
 for id:Vector2i in _tiles:
  var data:Dictionary=_tiles[id];var tile:=Node3D.new();tile.name="Tile_%s_%s"%[id.x,id.y];tile.position=data.origin;generated.add_child(tile)
  for kind in range(5):
   if data.counts[kind]==0:continue
   var tool:SurfaceTool=data.tools[kind];tool.generate_normals();tool.index();var mesh:=tool.commit();var visual:=MeshInstance3D.new();visual.name=["Pavement","Sidewalks","Paint","WhiteMarkings","Shoulders"][kind];visual.mesh=mesh;tile.add_child(visual)
   if not Engine.is_editor_hint():visual.visibility_range_end=2200
   triangles+=data.counts[kind]/3
 # Keep collision vertices in one coordinate frame. Splitting connected triangles
 # across translated tile bodies creates tiny cracks along Jolt's active edges.
 _collision_tool.index();var collision_mesh:=_collision_tool.commit();_collision_tool=null
 if collision_mesh:
  var body:=StaticBody3D.new();body.name="RoadCollision";body.set_meta("driveable_road",true);generated.add_child(body);var shape:=CollisionShape3D.new();shape.shape=collision_mesh.create_trimesh_shape();body.add_child(shape)
 _tiles.clear();revision+=1;stats={"roads":sources.size(),"edges":edges.size(),"junctions":junctions,"triangles":triangles}
 print("ROAD NETWORK ",stats)

