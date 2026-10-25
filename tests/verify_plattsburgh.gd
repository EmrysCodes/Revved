extends SceneTree
var failed:=false
func _initialize()->void:call_deferred("run")
func check(v:bool,message:String)->void:
 if not v:failed=true;push_error(message)
func run()->void:
 var begin:=Time.get_ticks_msec();var world:Node3D=load("res://world/handbuilt/plattsburgh_region.scn").instantiate();root.add_child(world)
 for i in range(25):await physics_frame
 print("REGION LOAD ms ",Time.get_ticks_msec()-begin)
 var network:Node3D=world.get_node("Roads");check(network.stats.get("roads",0)==1633,"All 1633 source roads render through the shared network")
 var count:=0
 for tile:Node in world.get_node("Buildings").get_children():count+=tile.get_child_count()
 check(count==8101,"All 8101 real building footprints are editable scene objects")
 check(world.get_node("Terrain").get_child_count()==391,"Full-size measured terrain is present")
 check(world.car!=null and world.car.has_node("HUD/Screen/TouchControls"),"Existing vehicle and mobile controls are present")
 check(world.terrain_bounds.w-world.terrain_bounds.y>20000,"Regional sample uses full geographic scale")
 var query:=PhysicsRayQueryParameters3D.new();query.collision_mask=1;query.exclude=[world.car.get_rid()];var good:=0;var tested:=0;var problems:Array=[]
 for road:Node3D in network.get_children():
  if not road.has_meta("workshop_road"):continue
  # Exact vertices + segment midpoints catch terrain poking through pavement.
  if tested%5!=0:tested+=1;continue
  var points:PackedVector3Array=road.points
  for idx in [0,points.size()/2,points.size()-1]:
   var point:=road.to_global(points[int(idx)]);query.from=point+Vector3.UP*1.5;query.to=point-Vector3.UP*1.5
   var hit:=world.get_world_3d().direct_space_state.intersect_ray(query)
   if not hit.is_empty() and absf(hit.position.y-point.y)<.2:good+=1
   elif problems.size()<12:problems.append({"road":str(road.name),"point":point,"hit":hit.get("position",Vector3.INF),"body":str(hit.get("collider","none"))})
  tested+=1
 print("REGION pavement samples good=",good," / ",ceili(tested/5.0)*3," examples=",problems)
 check(good==ceili(tested/5.0)*3,"Every sampled pavement point is physically exposed within 20 cm of source road height")
 # Drive a real source segment using the established arcade-car route pilot.
 var road:Node3D=null;var longest:=0.0
 for candidate:Node3D in network.get_children():
  if not candidate.has_meta("workshop_road") or not str(candidate.name).begins_with("Route_9_"):continue
  var length:=0.0;var points:PackedVector3Array=candidate.points
  for i in range(1,points.size()):length+=points[i-1].distance_to(points[i])
  if length>longest:longest=length;road=candidate
 check(road!=null,"US-9 source alignment exists")
 if road:
  var points:PackedVector3Array=road.points;var car:CharacterBody3D=world.car;car.set_physics_process(false);car.global_position=points[0]+Vector3.UP*.4;var d:=points[1]-points[0];car.rotation.y=atan2(-d.x,-d.z);car.velocity=Vector3.ZERO;car.reset_physics_interpolation();world._stream_tiles()
  for i in range(25):car._step_motion(1.0/60,0,0,true,false);await physics_frame
  var distances:=PackedFloat64Array([0.0]);for i in range(1,points.size()):distances.append(distances[-1]+points[i-1].distance_to(points[i]))
  var cursor:=0;var air:=0;var completed:=false
  for frame in range(9000):
   var command:Dictionary=preload("res://racing/route_pilot.gd").command(car,points,distances,cursor,18,0);cursor=command.cursor;car._step_motion(1.0/60,command.throttle,command.steering,command.brake,false);await physics_frame
   if not car.is_on_floor():air+=1
   if cursor>=points.size()-4:completed=true;break
  print("REGION DRIVE US9 length=",longest," complete=",completed," airborne=",air," cursor=",cursor)
  check(completed and air<100,"US-9 is drivable with the actual vehicle")
 print("PLATTSBURGH REGION ","FAIL" if failed else "PASS");world.queue_free();await process_frame;quit(1 if failed else 0)
