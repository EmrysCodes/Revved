@tool
extends RefCounted
var failed:=false
func check(value:bool,message:String)->void:
	if not value:failed=true;push_error(message)
func frames(plugin:EditorPlugin,count:int)->void:
	for i in range(count):await plugin.get_tree().process_frame
func run(plugin:EditorPlugin)->void:
	await frames(plugin,40)
	var path:String=plugin.new_world()
	for i in range(600):
		if plugin._world():break
		await plugin.get_tree().process_frame
	var world:Node3D=plugin._world()
	check(world!=null,"New world opens in the real editor")
	if not world:return
	check(world.has_node("Ground") and world.has_node("PlayerStart"),"Scene foundation and spawn exist")
	plugin.dock.grid.value=2;plugin._set_mode(1);plugin._asset_changed("family_2")
	check(is_equal_approx(plugin.dock.elevation.value,.04),"Road placement stays above ground; SpinBox preserves centimetres")
	var point:Vector3=plugin.snap_point(Vector3(5.2,.04,7.1));check(point==Vector3(6,.04,8),"XZ grid snapping keeps elevation")
	var placed:Node3D=plugin.place_asset(point);await frames(plugin,3)
	check(placed.owner==world and placed.get_parent().name=="Buildings","Placed object belongs to saved scene")
	var undo:EditorUndoRedoManager=plugin.get_undo_redo();var history:=undo.get_history_undo_redo(undo.get_object_history_id(world))
	history.undo();check(placed.get_parent()==null,"Place undo")
	history.redo();check(placed.get_parent()==world.get_node("Buildings"),"Place redo restores owner and parent")
	var copy:Node3D=plugin.duplicate_item();check(copy!=null and copy.owner==world,"Duplicate preserves scene ownership")
	plugin.delete_item(copy);check(copy.get_parent()==null,"Delete removes item")
	history.undo();check(copy.get_parent()!=null,"Delete undo restores item")
	var mesh:Node=placed.find_children("*","MeshInstance3D",true,false)[0]
	plugin._select_item(mesh);await frames(plugin,3)
	check(EditorInterface.get_selection().get_selected_nodes()[0]==mesh and plugin.selected_item()==placed,"Native child selection stays available for material editing")
	var view:Camera3D=EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	view.global_position=Vector3(0,80,80);view.look_at(Vector3.ZERO)
	plugin._set_mode(1);plugin.dock.surface.button_pressed=false
	var click:=InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=view.get_viewport().get_visible_rect().size*.5
	var before:=world.get_node("Buildings").get_child_count()
	check(plugin._forward_3d_gui_input(view,click)==EditorPlugin.AFTER_GUI_INPUT_STOP,"3D viewport click is handled by the placement tool")
	check(world.get_node("Buildings").get_child_count()==before+1,"Viewport ray/plane intersection places an actual scene object")
	history.undo();plugin.dock.surface.button_pressed=true
	plugin._set_mode(2);plugin.draft=PackedVector3Array([Vector3(-20,.04,0),Vector3(0,.04,0),Vector3(30,4.04,0)])
	var road:Node3D=plugin.commit_road();await frames(plugin,5)
	check(road!=null and road.samples().size()>10 and road.get_parent().has_node("_GeneratedNetwork"),"Curved/elevated road builds in editor")
	plugin.dock.grid.value=0
	check(plugin.snap_point(Vector3(30.4,4.04,.1)).distance_to(Vector3(30,4.04,0))<.001,"Road endpoints snap exactly across elevation changes")
	plugin.dock.road_width.value=16;plugin.apply_road_settings();await frames(plugin,3)
	check(road.road_width==16,"Selected-road settings apply")
	history.undo();await frames(plugin,3);check(road.road_width==12,"Road settings undo")
	var old:Transform3D=world.get_node("PlayerStart").transform
	plugin.set_start(Vector3(-20,.04,0));check(world.get_node("PlayerStart").position.y>.4,"Spawn clears the road")
	history.undo();check(world.get_node("PlayerStart").transform==old,"Player start undo")
	plugin._set_mode(1);plugin.cursor=Vector3.ZERO;plugin.cursor_valid=true;plugin._update_ghost()
	check(plugin.ghost!=null and plugin.ghost.owner==null,"Placement ghost is transient")
	if DisplayServer.get_name()=="headless":EditorInterface.save_scene_as(path,false);check(FileAccess.file_exists(path),"Native scene save without dummy-renderer thumbnail")
	else:check(EditorInterface.save_scene()==OK,"Native scene save")
	var packed:PackedScene=load(path);var state:=packed.get_state();var ghost_saved:=false;var generated_saved:=false
	for i in range(state.get_node_count()):
		var name_value:=str(state.get_node_name(i));ghost_saved=ghost_saved or name_value=="_PlacementPreview";generated_saved=generated_saved or name_value=="_Generated"
	check(not ghost_saved and not generated_saved,"Saved scene excludes previews and rebuildable road geometry")
	plugin._set_mode(0);var key:=InputEventKey.new();key.physical_keycode=KEY_R;key.pressed=true
	check(plugin._forward_3d_gui_input(null,key)==EditorPlugin.AFTER_GUI_INPUT_PASS,"Select mode preserves native shortcuts")
	var reloaded:Node3D=packed.instantiate();check(reloaded.get_node("Roads").get_child_count()==1,"Road control data survives save/load");reloaded.free()
	plugin._clear_ghost();EditorInterface.close_scene()
	# Remove only the uniquely-created QA scene, never any existing scene.
	if path.begins_with("res://world/handbuilt/my_city_"):DirAccess.remove_absolute(path)
	EditorInterface.open_scene_from_path(plugin.STARTER);await frames(plugin,10)
	print("WORKSHOP EDITOR ","FAIL" if failed else "PASS",": native editor, scene creation, placement, grid/elevation snap, duplicate/delete, per-scene undo/redo, road settings, spawn, save/reload and transient previews")
