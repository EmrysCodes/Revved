@tool
extends EditorNode3DGizmoPlugin
var workshop:WeakRef
func _init()->void:
 create_material("center",Color(.2,.8,.9,.7));create_handle_material("points")
func _get_gizmo_name()->String:return "REVVED road points"
func _has_gizmo(node:Node3D)->bool:return node.has_meta("workshop_road")
func _redraw(gizmo:EditorNode3DGizmo)->void:
 gizmo.clear();var road:=gizmo.get_node_3d();var points:PackedVector3Array=road._make_curve();var lines:=PackedVector3Array()
 for i in range(1,points.size()):lines.append(points[i-1]+Vector3.UP*.08);lines.append(points[i]+Vector3.UP*.08)
 gizmo.add_collision_segments(lines)
 if EditorInterface.get_selection().get_selected_nodes().has(road):gizmo.add_lines(lines,get_material("center",gizmo));gizmo.add_handles(road.points,get_material("points",gizmo),PackedInt32Array())
func _get_handle_name(_gizmo:EditorNode3DGizmo,id:int,_secondary:bool)->String:return "Road point %s / height in Inspector"%id
func _get_handle_value(gizmo:EditorNode3DGizmo,_id:int,_secondary:bool)->Variant:return gizmo.get_node_3d().points.duplicate()
func _set_handle(gizmo:EditorNode3DGizmo,id:int,_secondary:bool,camera:Camera3D,screen:Vector2)->void:
 var road:=gizmo.get_node_3d();var points:PackedVector3Array=road.points.duplicate()
 if id>=points.size():return
 var global_point:Vector3=road.to_global(points[id]);var plane:=Plane(Vector3.UP,global_point.y);var hit:Variant=plane.intersects_ray(camera.project_ray_origin(screen),camera.project_ray_normal(screen))
 if not hit is Vector3:return
 var p:Vector3=road.to_local(hit);var plugin:EditorPlugin=workshop.get_ref();var snap:float=plugin.dock.grid.value if plugin else 0
 if snap>0 and not Input.is_key_pressed(KEY_SHIFT):p.x=snappedf(p.x,snap);p.z=snappedf(p.z,snap)
 points[id]=p;road.points=points;road.update_gizmos()
func _commit_handle(gizmo:EditorNode3DGizmo,_id:int,_secondary:bool,restore:Variant,cancel:bool)->void:
 var road:=gizmo.get_node_3d()
 if cancel:road.points=restore;road.update_gizmos();return
 var plugin:EditorPlugin=workshop.get_ref()
 if not plugin:return
 var undo:=plugin.get_undo_redo();undo.create_action("Move road point",UndoRedo.MERGE_DISABLE,EditorInterface.get_edited_scene_root());undo.add_do_property(road,"points",road.points.duplicate());undo.add_undo_property(road,"points",restore);undo.commit_action(false)
