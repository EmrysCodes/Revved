extends SceneTree
const PILOT=preload("res://racing/route_pilot.gd")
var failed:=false
func _initialize()->void:call_deferred("run")
func check(value:bool,message:String)->void:
	if not value:failed=true;push_error(message)
func drive(world:Node3D,road:Node3D,label:String)->void:
	var car:CharacterBody3D=world.car;var path:PackedVector3Array=road.samples();var distances:=PackedFloat64Array([0.0])
	for i in range(1,path.size()):distances.append(distances[-1]+path[i-1].distance_to(path[i]))
	car.global_position=road.to_global(path[0])+Vector3.UP*.35;car.rotation.y=atan2(-(path[1].x-path[0].x),-(path[1].z-path[0].z));car.velocity=Vector3.ZERO
	car.reset_physics_interpolation()
	for i in range(30):car._step_motion(1.0/60,0,0,true,false);await physics_frame
	var global_path:=PackedVector3Array()
	for point:Vector3 in path:global_path.append(road.to_global(point))
	var cursor:=0;var air:=0;var completed:=false
	for frame in range(6000):
		var command:Dictionary=PILOT.command(car,global_path,distances,cursor,16,0);cursor=command.cursor
		car._step_motion(1.0/60,command.throttle,command.steering,command.brake,false);await physics_frame
		if not car.is_on_floor():air+=1
		if cursor>=path.size()-5:completed=true;break
	check(completed and air<80,"Drive "+label+" / cursor="+str(cursor)+" / airborne="+str(air))
	print("WORKSHOP DRIVE ",label," completed=",completed," air_frames=",air)
func run()->void:
	var catalog:=preload("res://world/workshop/catalog.gd")
	for entry:Dictionary in catalog.entries():
		var node:Node3D=catalog.create(entry.id);check(node!=null,"Catalog asset "+entry.id)
		if node:check(node.get_meta("workshop_item",false),"Selectable placed asset "+entry.id);node.free()
	var world:Node3D=load("res://world/handbuilt/workshop_starter.tscn").instantiate();root.add_child(world)
	for i in range(8):await physics_frame
	check(world.car!=null and world.car.has_node("HUD/Screen/TouchControls"),"Existing vehicle and touch controls play in the authored scene")
	world.car.set_physics_process(false)
	await drive(world,world.get_node("Roads/StarterLoop"),"closed loop")
	await drive(world,world.get_node("Roads/RaisedStreet"),"elevated road to deck")
	var road:Node3D=world.get_node("Roads/RaisedStreet");var original:PackedVector3Array=road.points
	road.road_width=14;road.sidewalk_width=0;road.rebuild();check(road.points==original,"Changing widths does not move authored control points")
	check(not road.has_node("_Generated/Sidewalk"),"Zero sidewalk width supported")
	world.queue_free();await process_frame
	var menu:Control=load("res://ui/front_end/main_menu.tscn").instantiate();root.add_child(menu);current_scene=menu
	for i in range(4):await process_frame
	menu.handbuilt_city()
	for i in range(15):await process_frame
	check(current_scene!=null and current_scene.has_meta("workshop_world"),"Main menu opens the published handbuilt scene")
	check(root.get_node("StreetProfile").launch_mode=="builder","World authoring uses the builder launch mode")
	print("WORLD WORKSHOP ","FAIL" if failed else "PASS")
	if current_scene:current_scene.queue_free()
	await process_frame;quit(1 if failed else 0)
