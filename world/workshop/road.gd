@tool
extends Node3D
## Editable spline road. Only its control points/settings are saved; geometry is rebuilt locally.
@export var points: PackedVector3Array = PackedVector3Array():
	set(value): points=value; _schedule()
@export_range(4,40,.5) var road_width := 12.0:
	set(value): road_width=value; _schedule()
@export_range(0,10,.25) var sidewalk_width := 3.0:
	set(value): sidewalk_width=value; _schedule()
@export var closed := false:
	set(value): closed=value; _schedule()
@export_range(0,.45,.01) var curve_softness := .22:
	set(value): curve_softness=value; _schedule()
@export_range(1,12,1) var sample_spacing := 2.0:
	set(value): sample_spacing=value; _schedule()
var network_bounds:=AABB()
var _pending := false
var _samples := PackedVector3Array()
var _junctions:Array[Node3D]=[]
func _inside_junction(point:Vector3)->bool:
	for junction:Node3D in _junctions:
		if not is_instance_valid(junction) or not junction.is_inside_tree():continue
		var local:=junction.to_local(to_global(point))
		if absf(local.x)<14 and absf(local.z)<14 and absf(local.y)<1:return true
	return false
func _ready() -> void:
	set_meta("workshop_item",true);set_meta("workshop_road",true);set_notify_transform(true);rebuild()
func _notification(what:int)->void:
	if what==NOTIFICATION_TRANSFORM_CHANGED and is_inside_tree():_schedule()
func _schedule() -> void:
	if _pending:return
	_pending=true;call_deferred("rebuild")
func samples() -> PackedVector3Array:
	if _samples.is_empty():_samples=_make_curve()
	return _samples
func _make_curve() -> PackedVector3Array:
	var output:=PackedVector3Array()
	if points.size()<2:return output
	# Imported survey vertices already describe the alignment and grade. Baking a
	# zero-handle curve can skip short source segments and change their elevation.
	if is_zero_approx(curve_softness):
		output=points.duplicate()
		if closed:output.append(points[0])
		return output
	var curve:=Curve3D.new();curve.bake_interval=sample_spacing
	var count:=points.size()
	for i in range(count+(1 if closed else 0)):
		var k:=i%count;var previous:=points[(k-1+count)%count] if closed or k>0 else points[k]
		var next:=points[(k+1)%count] if closed or k<count-1 else points[k]
		var direction:=(next-previous).normalized()
		var before:=points[k].distance_to(previous)*curve_softness
		var after:=points[k].distance_to(next)*curve_softness
		curve.add_point(points[k],-direction*before,direction*after)
	return curve.get_baked_points()
func _quad(tool:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,d:Vector3) -> void:
	for v:Vector3 in [a,d,b,b,d,c]:tool.set_uv(Vector2(v.x,v.z));tool.add_vertex(v)
func _strip(tool:SurfaceTool,a:Vector3,b:Vector3,right_a:Vector3,right_b:Vector3,start:float,end:float,y0:float,y1:float) -> void:
	_quad(tool,a+right_a*start+Vector3.UP*y0,a+right_a*end+Vector3.UP*y1,b+right_b*end+Vector3.UP*y1,b+right_b*start+Vector3.UP*y0)
func _material(file:String,color:Color)->Material:
	var path:="res://assets/licensed/modern_city_architecture/"+file+".tres"
	if ResourceLoader.exists(path):
		var mat:BaseMaterial3D=load(path).duplicate();mat.roughness=.92;mat.metallic=0;mat.metallic_texture=null;mat.roughness_texture=null;return mat
	var fallback:=StandardMaterial3D.new();fallback.albedo_color=color;fallback.roughness=.95;return fallback
func rebuild() -> void:
	_pending=false
	if not is_inside_tree():return
	if get_parent().has_method("request_rebuild"):
		_samples=_make_curve();get_parent().request_rebuild();update_gizmos();return
	var old:=get_node_or_null("_Generated")
	if old:remove_child(old);old.queue_free()
	_samples=_make_curve()
	if _samples.size()<2:return
	_junctions.clear()
	var world:Node=get_parent()
	while world and not world.has_meta("workshop_world"):world=world.get_parent()
	if world:
		for item:Node3D in world.find_children("*","Node3D",true,false):
			if str(item.get_meta("workshop_asset","")).begins_with("junction") and not item.has_meta("workshop_generated"):_junctions.append(item)
	var generated:=Node3D.new();generated.name="_Generated";generated.set_meta("workshop_generated",true);add_child(generated)
	var asphalt:=SurfaceTool.new();asphalt.begin(Mesh.PRIMITIVE_TRIANGLES);asphalt.set_material(_material("road",Color("242b30")))
	var walk:=SurfaceTool.new();walk.begin(Mesh.PRIMITIVE_TRIANGLES);walk.set_material(_material("sidewalk",Color("838982")))
	var marks:=SurfaceTool.new();marks.begin(Mesh.PRIMITIVE_TRIANGLES)
	var paint:=StandardMaterial3D.new();paint.albedo_color=Color("c2ac62");paint.roughness=.95;marks.set_material(paint)
	var has_marks:=false
	var has_walk:=false
	for i in range(_samples.size()-1):
		var a:=_samples[i];var b:=_samples[i+1]
		var ra:=(_samples[mini(i+1,_samples.size()-1)]-_samples[maxi(0,i-1)]).cross(Vector3.UP).normalized()
		var rb:=(_samples[mini(i+2,_samples.size()-1)]-_samples[i]).cross(Vector3.UP).normalized()
		_strip(asphalt,a,b,ra,rb,-road_width*.5,road_width*.5,0,0)
		var junction:=_inside_junction((a+b)*.5)
		if sidewalk_width>0 and not junction:
			has_walk=true
			var bevel:=minf(.5,sidewalk_width)
			_strip(walk,a,b,ra,rb,road_width*.5,road_width*.5+bevel,0,.12)
			_strip(walk,a,b,ra,rb,-road_width*.5-bevel,-road_width*.5,.12,0)
			if sidewalk_width>bevel:
				_strip(walk,a,b,ra,rb,road_width*.5+bevel,road_width*.5+sidewalk_width,.12,.12)
				_strip(walk,a,b,ra,rb,-road_width*.5-sidewalk_width,-road_width*.5-bevel,.12,.12)
		if road_width>=8 and not junction:
			for offset:float in [-.14,.14]:_strip(marks,a,b,ra,rb,offset-.04,offset+.04,.025,.025)
			has_marks=true
	_add_mesh(generated,asphalt,"Asphalt",true)
	if has_walk:_add_mesh(generated,walk,"Sidewalk",true)
	if has_marks:_add_mesh(generated,marks,"Markings",false)
func _add_mesh(parent:Node,tool:SurfaceTool,title:String,solid:bool)->void:
	tool.generate_normals();tool.index();var mesh:=tool.commit()
	var visual:=MeshInstance3D.new();visual.name=title;visual.mesh=mesh;visual.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF;parent.add_child(visual)
	if solid:
		var body:=StaticBody3D.new();parent.add_child(body)
		var shape:=CollisionShape3D.new();shape.shape=mesh.create_trimesh_shape();body.add_child(shape)
func maximum_grade() -> float:
	var grade:=0.0
	for i in range(1,points.size()):
		var d:=points[i]-points[i-1];grade=maxf(grade,absf(d.y)/maxf(.01,Vector2(d.x,d.z).length()))
	return grade
