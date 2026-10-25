@tool
extends EditorPlugin
const CATALOG=preload("res://world/workshop/catalog.gd")
const FACTORY=preload("res://world/workshop/world_factory.gd")
const ROAD=preload("res://world/workshop/road.gd")
const STARTER:="res://world/handbuilt/plattsburgh_region.scn"
enum Mode { SELECT, PLACE, ROAD, START, ERASE }
var dock:VBoxContainer
var road_gizmo:EditorNode3DGizmoPlugin
var toolbar:Button
var mode:=Mode.SELECT
var asset_id:="family_0"
var ghost:Node3D
var draft:=PackedVector3Array()
var cursor:=Vector3.ZERO
var cursor_valid:=false
var camera:Camera3D
var _previous_road:Node3D
var _selection_guard:=false
func _enter_tree()->void:
 road_gizmo=load("res://addons/revved_world_workshop/road_gizmo.gd").new();road_gizmo.workshop=weakref(self);add_node_3d_gizmo_plugin(road_gizmo)
 dock=VBoxContainer.new();dock.name="World Workshop";dock.set_script(load("res://addons/revved_world_workshop/dock.gd"))
 dock.command.connect(_command);dock.mode_changed.connect(_set_mode);dock.asset_changed.connect(_asset_changed)
 add_control_to_dock(DOCK_SLOT_RIGHT_UL,dock)
 toolbar=Button.new();toolbar.text="World Workshop";toolbar.tooltip_text="Hand-build REVVED scenes in the 3D editor"
 add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU,toolbar);toolbar.pressed.connect(_show)
 add_tool_menu_item("REVVED / World Workshop",_show)
 set_input_event_forwarding_always_enabled()
 set_force_draw_over_forwarding_enabled()
 scene_changed.connect(_scene_changed);EditorInterface.get_selection().selection_changed.connect(_selection_changed)
 _scene_changed(EditorInterface.get_edited_scene_root())
 if "--workshop-self-test" in OS.get_cmdline_user_args():call_deferred("_self_test")
 if "--workshop-preview" in OS.get_cmdline_user_args():call_deferred("_preview")
func _exit_tree()->void:
 if road_gizmo:remove_node_3d_gizmo_plugin(road_gizmo)
 _clear_ghost();draft.clear()
 if is_instance_valid(dock):remove_control_from_docks(dock);dock.queue_free()
 if is_instance_valid(toolbar):remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU,toolbar);toolbar.queue_free()
 remove_tool_menu_item("REVVED / World Workshop")
func _handles(object:Object)->bool:return object is Node3D
func _show()->void:
 dock.show();EditorInterface.set_main_screen_editor("3D")
 var child:Node=dock
 while child.get_parent():
  var parent:=child.get_parent()
  if parent is TabContainer:parent.current_tab=parent.get_tab_idx_from_control(child);break
  child=parent
 if not _world() and ResourceLoader.exists(STARTER):EditorInterface.open_scene_from_path(STARTER)
func _world()->Node3D:
 var scene:=EditorInterface.get_edited_scene_root()
 return scene if scene is Node3D and scene.has_meta("workshop_world") else null
func _scene_changed(_scene:Node)->void:
 _clear_ghost();draft.clear();cursor_valid=false;_set_mode(Mode.SELECT)
 if not is_instance_valid(dock):return
 var world:=_world();dock.world_label.text=world.world_title if world else "Create a world or open the starter scene."
 update_overlays()
func _set_mode(value:int)->void:
 mode=value as Mode;_clear_ghost();draft.clear();cursor_valid=false
 if is_instance_valid(dock):
  dock.modes.select(value)
  _message(["Select: use the native move / rotate / scale gizmos.","Place: click in 3D. R rotates. Esc returns to Select.","Road: click points. Enter builds. Backspace removes a point.","Click to set PlayerStart. Brush rotation sets the car heading.","Click a placed asset or road to erase it. Ctrl+Z restores it."][value])
 update_overlays()
func _asset_changed(id:String)->void:
 asset_id=id;_clear_ghost()
func _message(text:String)->void:
 if is_instance_valid(dock) and is_instance_valid(dock.status):dock.status.text=text
func _item(node:Node)->Node3D:
 var world:=_world()
 while node and node!=world:
  if node is Node3D and node.has_meta("workshop_item"):return node
  node=node.get_parent()
 return null
func selected_item()->Node3D:
 var nodes:=EditorInterface.get_selection().get_selected_nodes()
 return _item(nodes[0]) if nodes.size()==1 else null
func _selection_changed()->void:
 if _selection_guard or not is_instance_valid(dock):return
 if is_instance_valid(_previous_road):_previous_road.update_gizmos()
 var item:=selected_item()
 _previous_road=item if item and item.has_meta("workshop_road") else null
 if is_instance_valid(_previous_road):_previous_road.update_gizmos()
 dock.selection_label.text=str(item.name) if item else "Choose an item in the 3D view or Scene tree."
 # Keep native child selection so meshes, lights and materials remain editable.
 # Workshop commands resolve the selected child to its owning placed item.
func _clear_ghost()->void:
 if is_instance_valid(ghost):
  if ghost.get_parent():ghost.get_parent().remove_child(ghost)
  ghost.queue_free()
 ghost=null
func _hit(view:Camera3D,position:Vector2,use_surface:bool)->Dictionary:
 var world:=_world()
 if not world:return {}
 var origin:=view.project_ray_origin(position);var direction:=view.project_ray_normal(position)
 if use_surface:
  var query:=PhysicsRayQueryParameters3D.create(origin,origin+direction*10000)
  var result:=world.get_world_3d().direct_space_state.intersect_ray(query)
  if not result.is_empty():return result
 var plane:=Plane(Vector3.UP,world.global_position.y+float(dock.elevation.value))
 var hit:Variant=plane.intersects_ray(origin,direction)
 return {"position":hit} if hit is Vector3 else {}
func snap_point(point:Vector3,bypass:=false)->Vector3:
 if bypass:return point
 var world:=_world();var best:=maxf(2,float(dock.grid.value)*1.5);var found:=point;var snapped_to_road:=false
 if world and mode==Mode.ROAD:
  for road:Node in world.get_node("Roads").get_children():
   if not road.get_meta("workshop_road",false):continue
   if road.network_bounds.size.length_squared()>0 and not road.network_bounds.grow(best).has_point(world.get_node("Roads").to_local(world.to_global(point))):continue
   for sample:Vector3 in road.samples():
    var candidate:=world.to_local(road.to_global(sample));var distance:=candidate.distance_to(point)
    if distance<best:best=distance;found=candidate;snapped_to_road=true
  for marker:Marker3D in world.find_children("*","Marker3D",true,false):
   if not marker.has_meta("workshop_socket"):continue
   var candidate:=world.to_local(marker.global_position);var distance:=candidate.distance_to(point)
   if distance<best:best=distance;found=candidate;snapped_to_road=true
 if snapped_to_road and mode==Mode.ROAD:return found
 var interval:float=dock.grid.value
 return Vector3(snappedf(point.x,interval),point.y,snappedf(point.z,interval)) if interval>0 else point
func _forward_3d_gui_input(view:Camera3D,event:InputEvent)->int:
 if not _world() or mode==Mode.SELECT or not dock.visible:return AFTER_GUI_INPUT_PASS
 camera=view
 if event is InputEventMouse:
  if event.alt_pressed or (event.button_mask&MOUSE_BUTTON_MASK_RIGHT)!=0:return AFTER_GUI_INPUT_PASS
  var hit:=_hit(view,event.position,dock.surface.button_pressed and mode in [Mode.PLACE,Mode.ERASE,Mode.START])
  cursor_valid=not hit.is_empty()
  if cursor_valid:
   cursor=_world().to_local(hit.position)
   if mode==Mode.PLACE and dock.surface.button_pressed:cursor.y+=dock.elevation.value
   cursor=snap_point(cursor,event.shift_pressed)
  if event is InputEventMouseMotion:
   _update_ghost();update_overlays()
  if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and cursor_valid:
   match mode:
    Mode.PLACE:place_asset(cursor)
    Mode.ROAD:draft.append(cursor);_message("%d road points / Enter builds / Esc cancels"%draft.size())
    Mode.START:set_start(cursor)
    Mode.ERASE:
     if hit.has("collider"):
      var item:=_item(hit.collider)
      if not item:item=_road_at(hit.position)
      delete_item(item)
   update_overlays();return AFTER_GUI_INPUT_STOP
 if event is InputEventKey and event.pressed and not event.echo and not event.ctrl_pressed:
  match event.physical_keycode:
   KEY_ESCAPE:_set_mode(Mode.SELECT);return AFTER_GUI_INPUT_STOP
   KEY_R:
    if mode==Mode.PLACE:dock.yaw.value=wrapf(dock.yaw.value+15,-360,360);_update_ghost();return AFTER_GUI_INPUT_STOP
   KEY_ENTER,KEY_KP_ENTER:
    if mode==Mode.ROAD:commit_road();return AFTER_GUI_INPUT_STOP
   KEY_BACKSPACE:
    if mode==Mode.ROAD and not draft.is_empty():draft.remove_at(draft.size()-1);update_overlays();return AFTER_GUI_INPUT_STOP
 return AFTER_GUI_INPUT_PASS
func _road_at(global_point:Vector3)->Node3D:
 var world:=_world()
 if not world:return null
 var network:Node3D=world.get_node("Roads");var p:=network.to_local(global_point);var best:=INF;var found:Node3D
 for road:Node3D in network.get_children():
  if not road.has_meta("workshop_road"):continue
  if road.network_bounds.size.length_squared()>0 and not road.network_bounds.has_point(p):continue
  var local:=road.to_local(global_point);var points:PackedVector3Array=road.samples()
  for i in range(1,points.size()):
   var closest:=Geometry3D.get_closest_point_to_segment(local,points[i-1],points[i]);var distance:=closest.distance_squared_to(local)
   if distance<best and distance<pow(road.road_width*.5+road.sidewalk_width+1,2):best=distance;found=road
 return found
func _update_ghost()->void:
 if mode!=Mode.PLACE or not cursor_valid:return
 var world:=_world()
 if not is_instance_valid(ghost):
  ghost=CATALOG.create(asset_id,false)
  if not ghost:return
  ghost.name="_PlacementPreview";ghost.set_meta("workshop_generated",true);world.add_child(ghost)
  for mesh:GeometryInstance3D in ghost.find_children("*","GeometryInstance3D",true,false):mesh.transparency=.55;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  for light:Light3D in ghost.find_children("*","Light3D",true,false):light.hide()
 ghost.transform=Transform3D(Basis(Vector3.UP,deg_to_rad(dock.yaw.value)).scaled(Vector3.ONE*dock.brush_scale.value),cursor)
func _forward_3d_force_draw_over_viewport(control:Control)->void:
 if mode!=Mode.ROAD or not is_instance_valid(camera) or not _world():return
 var points:=draft.duplicate()
 if cursor_valid:points.append(cursor)
 var previous:=Vector2.ZERO;var previous_valid:=false
 for point:Vector3 in points:
  var global_point:=_world().to_global(point)
  if camera.is_position_behind(global_point):previous_valid=false;continue
  var screen:=camera.unproject_position(global_point)
  control.draw_circle(screen,5,Color("ffd05d"))
  if previous_valid:control.draw_line(previous,screen,Color("4ee5ef"),3,true)
  previous=screen;previous_valid=true
func _attach(node:Node3D,parent:Node,world:Node)->void:
 parent.add_child(node,true);CATALOG.own(node,world)
func _select_item(node:Node)->void:
 EditorInterface.get_selection().clear();EditorInterface.get_selection().add_node(node)
func add_item(node:Node3D,parent:Node,label:String)->void:
 var world:=_world();var undo:=get_undo_redo()
 undo.create_action(label,UndoRedo.MERGE_DISABLE,world)
 undo.add_do_method(self,"_attach",node,parent,world);undo.add_do_method(self,"_select_item",node)
 undo.add_undo_method(parent,"remove_child",node);undo.add_do_reference(node);undo.commit_action()
func place_asset(point:Vector3)->Node3D:
 var world:=_world()
 if not world:return null
 var node:=CATALOG.create(asset_id)
 if not node:_message("That asset is unavailable in this project.");return null
 var parent:Node3D=world.get_node("Buildings" if asset_id.begins_with("family_") or asset_id.begins_with("modern_") else "Props")
 node.transform=parent.global_transform.affine_inverse()*world.global_transform*Transform3D(Basis(Vector3.UP,deg_to_rad(dock.yaw.value)).scaled(Vector3.ONE*dock.brush_scale.value),point)
 add_item(node,parent,"Place "+str(node.name));_message("Placed "+str(node.name)+" / Ctrl+Z undoes it")
 return node
func commit_road()->Node3D:
 var world:=_world()
 if not world or draft.size()<2:_message("Click at least two road points first.");return null
 var road:=Node3D.new();road.name="Road";road.set_script(ROAD);road.set_meta("workshop_item",true);road.set_meta("workshop_road",true)
 var knots:=draft.duplicate()
 if dock.closed.button_pressed and knots[0].distance_to(knots[-1])<.1:knots.remove_at(knots.size()-1)
 var length:=0.0
 for i in range(1,knots.size()):length+=knots[i].distance_to(knots[i-1])
 if length<.5 or (dock.closed.button_pressed and knots.size()<3):
  road.free();_message("Use separate points; a closed loop needs at least three.");return null
 road.points=knots;road.road_width=dock.road_width.value;road.sidewalk_width=dock.sidewalk.value;road.closed=dock.closed.button_pressed
 road.transform=world.get_node("Roads").global_transform.affine_inverse()*world.global_transform
 add_item(road,world.get_node("Roads"),"Draw road");draft.clear()
 _message("Road built / %.0f%% maximum control-point grade"%(road.maximum_grade()*100));update_overlays();return road
func delete_item(node:Node3D)->void:
 if not is_instance_valid(node) or not _world() or not _world().is_ancestor_of(node):return
 var parent:=node.get_parent();var index:=node.get_index();var undo:=get_undo_redo()
 undo.create_action("Remove "+str(node.name),UndoRedo.MERGE_DISABLE,_world())
 undo.add_do_method(parent,"remove_child",node);undo.add_undo_method(self,"_attach",node,parent,_world());undo.add_undo_method(parent,"move_child",node,index);undo.add_undo_reference(node);undo.commit_action()
 EditorInterface.get_selection().clear()
func duplicate_item()->Node3D:
 var selected:=selected_item()
 if not selected:return null
 var copy:Node3D=selected.duplicate();copy.position+=Vector3(maxf(1,dock.grid.value),0,maxf(1,dock.grid.value));add_item(copy,selected.get_parent(),"Duplicate item");return copy
func set_start(point:Vector3)->void:
 var world:=_world();var marker:Marker3D=world.get_node("PlayerStart")
 var next:=Transform3D(Basis(Vector3.UP,deg_to_rad(dock.yaw.value)),point+Vector3.UP*.45)
 var undo:=get_undo_redo();undo.create_action("Set player start",UndoRedo.MERGE_DISABLE,world)
 undo.add_do_property(marker,"transform",next);undo.add_undo_property(marker,"transform",marker.transform);undo.commit_action();_message("Player start set / Drive tests from here")
func apply_road_settings()->void:
 var road:=selected_item()
 if not road or not road.get_meta("workshop_road",false):_message("Select a road first.");return
 var undo:=get_undo_redo();undo.create_action("Change road settings",UndoRedo.MERGE_DISABLE,_world())
 for pair:Array in [["road_width",dock.road_width.value],["sidewalk_width",dock.sidewalk.value],["closed",dock.closed.button_pressed]]:
  undo.add_do_property(road,pair[0],pair[1]);undo.add_undo_property(road,pair[0],road.get(pair[0]))
 undo.commit_action()
func new_world()->String:
 DirAccess.make_dir_recursive_absolute("res://world/handbuilt")
 var number:=1;var path:="res://world/handbuilt/my_city_001.tscn"
 while FileAccess.file_exists(path):number+=1;path="res://world/handbuilt/my_city_%03d.tscn"%number
 var world:=FACTORY.create("My City %03d"%number);var result:=FACTORY.save(world,path);world.free()
 if result!=OK:_message("Could not save the new world: "+error_string(result));return ""
 EditorInterface.get_resource_filesystem().scan();EditorInterface.open_scene_from_path(path);EditorInterface.set_main_screen_editor("3D")
 return path
func _command(action:String)->void:
 match action:
  "new":new_world()
  "starter":EditorInterface.open_scene_from_path(STARTER);EditorInterface.set_main_screen_editor("3D")
  "cancel":_set_mode(Mode.SELECT)
  "road":commit_road()
  "road_settings":apply_road_settings()
  "duplicate":duplicate_item()
  "delete":delete_item(selected_item())
  "inspect":
   if selected_item():EditorInterface.edit_node(selected_item())
  "save":
   if _world():_clear_ghost();_message("Scene saved." if EditorInterface.save_scene()==OK else "Save failed. Check the scene path.")
  "publish":
   if not _world() or not _world().scene_file_path.begins_with("res://"):_message("Save a handbuilt scene inside this project first.");return
   if not draft.is_empty():_message("Build or cancel the road draft first.");return
   _clear_ghost()
   if EditorInterface.save_scene()!=OK:_message("Could not save this scene.");return
   var key:="revved/world_workshop/active_scene";var before:Variant=ProjectSettings.get_setting(key,STARTER)
   ProjectSettings.set_setting(key,_world().scene_file_path)
   var result:=ProjectSettings.save()
   if result!=OK:ProjectSettings.set_setting(key,before);_message("Could not update the Handbuilt City menu.")
   else:_message("Handbuilt City now opens "+str(_world().name)+". Export again when sharing a game build.")
  "play":
   if not _world():_message("Open a handbuilt world first.");return
   _clear_ghost()
   if not draft.is_empty():_message("Build or cancel the road draft before driving.");return
   if EditorInterface.save_scene()!=OK:_message("Save the scene before driving.");return
   EditorInterface.play_custom_scene(_world().scene_file_path)
func _self_test()->void:
 var checks:RefCounted=load("res://tests/world_workshop_editor_checks.gd").new()
 await checks.run(self);get_tree().quit(1 if checks.failed else 0)
func _preview()->void:
 await load("res://tools/workshop_editor_preview.gd").new().run(self)
 get_tree().quit()
