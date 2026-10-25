@tool
extends Node3D
## Real footprint, estimated architecture. Edit these properties to refine a property.
@export var source_id:=0
@export var front_target:=Vector2.ZERO
@export_range(.5,20,.1) var foundation_depth:=1.5:
 set(v):foundation_depth=v;_queue()
@export_enum("Generated facade","Stone corner","Retail A","Retail B","Modern office") var architecture_variant:=0:
 set(v):architecture_variant=v;_queue()
@export var footprint:=PackedVector2Array():
 set(v):footprint=v;_queue()
@export_range(2,80,.1) var wall_height:=6.3:
 set(v):wall_height=v;_queue()
@export_enum("Flat roof","Hip roof") var roof_style:=1:
 set(v):roof_style=v;_queue()
@export_range(0,7) var facade_style:=0:
 set(v):facade_style=v;_queue()
var _pending:=false
static var walls:Array[Material]=[]
static var roofs:Array[Material]=[]
func _ready()->void:
 set_meta("workshop_item",true);set_meta("real_footprint",true);set_meta("height_verified",false)
 if not has_node("Shell"):rebuild()
 if has_node("Shell"):get_node("Shell").visibility_range_end=0 if Engine.is_editor_hint() else 850
 if has_node("DetailedArchitecture"):
  get_node("DetailedArchitecture").visibility_range_end=220;get_node("DetailedArchitecture").visibility_range_end_margin=0
  get_node("DistantArchitecture").visibility_range_begin=220;get_node("DistantArchitecture").visibility_range_begin_margin=0
func _queue()->void:
 if _pending or not is_inside_tree():return
 _pending=true;call_deferred("rebuild")
func _tri(t:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,uv_a:Vector2,uv_b:Vector2,uv_c:Vector2)->void:
 t.set_uv(uv_a);t.add_vertex(a);t.set_uv(uv_c);t.add_vertex(c);t.set_uv(uv_b);t.add_vertex(b)
func rebuild()->void:
 _pending=false
 if footprint.size()<3:return
 for n:String in ["Shell","Collision","ArchitecturalDetail","DetailedArchitecture","DistantArchitecture","Foundation"]:
  var old:=get_node_or_null(n)
  if old:remove_child(old);old.queue_free()
 if walls.is_empty():
  for color:String in ["a88c70","c4bca5","747e85","b6bcae","854f3d","c3b6a2","8a8d84","b7a68a"]:
   var mat:=ShaderMaterial.new();mat.shader=load("res://world/plattsburgh/footprint_facade.gdshader");mat.set_shader_parameter("wall_color",Color(color));walls.append(mat)
   var roof:=StandardMaterial3D.new();roof.albedo_color=Color("3e4549").lightened(walls.size()*.012);roof.roughness=.98;roofs.append(roof)
 var wall:=SurfaceTool.new();wall.begin(Mesh.PRIMITIVE_TRIANGLES);var mat:ShaderMaterial=walls[facade_style].duplicate();mat.set_shader_parameter("house",roof_style==1);mat.set_shader_parameter("seed",float(source_id%1009));wall.set_material(mat)
 var ring:=footprint
 if not Geometry2D.is_polygon_clockwise(ring):ring.reverse()
 var front:=0;var nearest:=INF
 for i in range(ring.size()):
  var mid:Vector2=(ring[i]+ring[(i+1)%ring.size()])*.5
  if mid.distance_squared_to(front_target)<nearest:nearest=mid.distance_squared_to(front_target);front=i
 var distance:=0.0
 for i in range(ring.size()):
  var a:=Vector3(ring[i].x,-foundation_depth,ring[i].y);var b:=Vector3(ring[(i+1)%ring.size()].x,-foundation_depth,ring[(i+1)%ring.size()].y);var span:=a.distance_to(b);var c:=b+Vector3.UP*(wall_height+foundation_depth);var d:=a+Vector3.UP*(wall_height+foundation_depth)
  wall.set_uv2(Vector2(1 if i==front else 0,span))
  _tri(wall,a,b,c,Vector2(0,-foundation_depth),Vector2(span,-foundation_depth),Vector2(span,wall_height));_tri(wall,a,c,d,Vector2(0,-foundation_depth),Vector2(span,wall_height),Vector2(0,wall_height));distance+=span
 wall.generate_normals();wall.index();var mesh:=wall.commit()
 var roof:=SurfaceTool.new();roof.begin(Mesh.PRIMITIVE_TRIANGLES);roof.set_material(roofs[facade_style]);var center:=Vector2.ZERO
 for p:Vector2 in ring:center+=p
 center/=ring.size()
 if roof_style==1 and Geometry2D.is_point_in_polygon(center,ring):
  for i in range(ring.size()):
   var a:=Vector3(ring[i].x,wall_height,ring[i].y);var b:=Vector3(ring[(i+1)%ring.size()].x,wall_height,ring[(i+1)%ring.size()].y);var c:=Vector3(center.x,wall_height+2.1,center.y)
   if (b-a).cross(c-a).y<0:var swap:=a;a=b;b=swap
   _tri(roof,a,b,c,Vector2(a.x,a.z),Vector2(b.x,b.z),Vector2(c.x,c.z))
 else:
  var indices:=Geometry2D.triangulate_polygon(ring)
  for i in range(0,indices.size(),3):
   var a:=Vector3(ring[indices[i]].x,wall_height,ring[indices[i]].y);var b:=Vector3(ring[indices[i+1]].x,wall_height,ring[indices[i+1]].y);var c:=Vector3(ring[indices[i+2]].x,wall_height,ring[indices[i+2]].y)
   if (b-a).cross(c-a).y<0:var swap:=a;a=b;b=swap
   _tri(roof,a,b,c,Vector2(a.x,a.z),Vector2(b.x,b.z),Vector2(c.x,c.z))
 roof.generate_normals();roof.index();roof.commit(mesh)
 var visual:=MeshInstance3D.new();visual.name="Shell";visual.mesh=mesh;visual.visibility_range_end=850;add_child(visual)
 var body:=StaticBody3D.new();body.name="Collision";add_child(body);var shape:=CollisionShape3D.new();shape.name="Shape";shape.shape=mesh.create_trimesh_shape();body.add_child(shape)
 var trim:=SurfaceTool.new();trim.begin(Mesh.PRIMITIVE_TRIANGLES)
 var trim_mat:=StandardMaterial3D.new();trim_mat.albedo_color=Color("777369") if roof_style==0 else Color("c6bba2");trim_mat.roughness=.88;trim_mat.cull_mode=BaseMaterial3D.CULL_DISABLED;trim.set_material(trim_mat)
 for i in range(ring.size()):
  var a:=Vector3(ring[i].x,wall_height-.12,ring[i].y);var b:=Vector3(ring[(i+1)%ring.size()].x,wall_height-.12,ring[(i+1)%ring.size()].y)
  _beam(trim,a,b,.24,.32)
  if roof_style==0 and wall_height>8:_beam(trim,a-Vector3.UP*(wall_height-3.15),b-Vector3.UP*(wall_height-3.15),.16,.19)
 var a:=Vector3(ring[front].x,0,ring[front].y);var b:=Vector3(ring[(front+1)%ring.size()].x,0,ring[(front+1)%ring.size()].y);var midpoint:=(a+b)*.5;var tangent:=(b-a).normalized()
 if a.distance_to(b)>3:_beam(trim,midpoint-tangent*1.05+Vector3.UP*2.4,midpoint+tangent*1.05+Vector3.UP*2.4,.18,1.1)
 if roof_style==0:_beam(trim,Vector3(center.x-1,wall_height+.45,center.y),Vector3(center.x+1,wall_height+.45,center.y),.9,1.4)
 else:_beam(trim,Vector3(center.x,wall_height+1.4,center.y),Vector3(center.x,wall_height+2.8,center.y),.65,.65)
 trim.generate_normals();trim.index();var detail:=MeshInstance3D.new();detail.name="ArchitecturalDetail";detail.mesh=trim.commit();detail.visibility_range_end=180;add_child(detail)
 if owner:visual.owner=owner;body.owner=owner;shape.owner=owner
 if owner:detail.owner=owner
 if architecture_variant>0:
  _detailed_architecture(ring)
func _detailed_architecture(ring:PackedVector2Array)->void:
 var best:=INF;var angle:=0.0;var rect:=Rect2()
 for i in range(ring.size()):
  var yaw:float=(ring[(i+1)%ring.size()]-ring[i]).angle();var bounds:=Rect2(ring[0].rotated(-yaw),Vector2.ZERO)
  for p:Vector2 in ring:bounds=bounds.expand(p.rotated(-yaw))
  if bounds.get_area()<best:best=bounds.get_area();angle=yaw;rect=bounds
 var key:String=["","stone_corner","retail_a","retail_b","modern_office"][architecture_variant]
 var center:Vector2=rect.get_center().rotated(angle)
 for lod:String in ["near","far"]:
  var mesh:Mesh=load("res://assets/licensed/modern_city_architecture/"+key+"_"+lod+".res")
  if mesh==null:return
  var source:=mesh.get_aabb();var scale_value:=Vector3(rect.size.x*.98/source.size.x,wall_height/source.size.y,rect.size.y*.98/source.size.z)
  var basis:=Basis(Vector3.UP,-angle).scaled_local(scale_value)
  var visual:=MeshInstance3D.new();visual.name="DetailedArchitecture" if lod=="near" else "DistantArchitecture";visual.mesh=mesh;visual.transform=Transform3D(basis,Vector3(center.x,0,center.y)-basis*Vector3(source.get_center().x,source.position.y,source.get_center().z));visual.visibility_range_end=240 if lod=="near" else 1000;visual.visibility_range_end_margin=20
  if lod=="far":visual.visibility_range_begin=220;visual.visibility_range_begin_margin=20;visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  add_child(visual)
  if owner:visual.owner=owner
 get_node("Shell").hide();get_node("ArchitecturalDetail").hide()
 var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);var mat:=StandardMaterial3D.new();mat.albedo_color=Color("555c5b");mat.roughness=.96;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;tool.set_material(mat)
 for i in range(ring.size()):
  var a:=Vector3(ring[i].x,-foundation_depth,ring[i].y);var b:=Vector3(ring[(i+1)%ring.size()].x,-foundation_depth,ring[(i+1)%ring.size()].y);var c:=b+Vector3.UP*(foundation_depth+.04);var d:=a+Vector3.UP*(foundation_depth+.04)
  _tri(tool,a,b,c,Vector2.ZERO,Vector2.ONE,Vector2.ONE);_tri(tool,a,c,d,Vector2.ZERO,Vector2.ONE,Vector2.ZERO)
 tool.generate_normals();tool.index();var foundation:=MeshInstance3D.new();foundation.name="Foundation";foundation.mesh=tool.commit();foundation.visibility_range_end=800;add_child(foundation)
 if owner:foundation.owner=owner
func _beam(t:SurfaceTool,a:Vector3,b:Vector3,height_value:float,width:float)->void:
 var axis:=(b-a).normalized();var right:=axis.cross(Vector3.UP).normalized()
 if right.length_squared()<.1:right=Vector3.RIGHT
 var up:=right.cross(axis).normalized()*height_value*.5;right*=width*.5
 var v:=[a-right-up,a+right-up,a+right+up,a-right+up,b-right-up,b+right-up,b+right+up,b-right+up]
 for face:Array in [[0,3,2,1],[4,5,6,7],[0,1,5,4],[3,7,6,2],[0,4,7,3],[1,2,6,5]]:
  for ids:Array in [[0,1,2],[0,2,3]]:
   t.set_uv(Vector2.ZERO);t.add_vertex(v[face[ids[0]]]);t.add_vertex(v[face[ids[1]]]);t.add_vertex(v[face[ids[2]]])
