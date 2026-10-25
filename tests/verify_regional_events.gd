extends SceneTree
const C=preload("res://core/career_catalog.gd")
var failed:=false
func _initialize()->void:call_deferred("run")
func check(value:bool,message:String)->void:
 if not value:failed=true;push_error(message)
func run()->void:
 root.get_node("StreetProfile").launch_mode="free"
 var world:Node3D=load("res://world/handbuilt/plattsburgh_region.scn").instantiate();root.add_child(world)
 for i in range(35):await physics_frame
 var query:=PhysicsRayQueryParameters3D.new();query.collision_mask=1;query.exclude=[world.car.get_rid()]
 for item:Dictionary in C.EVENTS:
  var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(C.route_path(item.id)));var tested:=0;var good:=0;var examples:Array=[]
  var indices:=[]
  for i in range(0,data.finish_index+1,10):indices.append(i)
  for i in data.checkpoints:
   if not i in indices:indices.append(int(i))
  for i:int in indices:
   var p:=Vector3(data.points[i][0],data.points[i][1],data.points[i][2]);query.from=p+Vector3.UP*.9;query.to=p-Vector3.UP*1.2;var hit:=world.get_world_3d().direct_space_state.intersect_ray(query);tested+=1
   if not hit.is_empty() and absf(hit.position.y-p.y)<.45:good+=1
   elif examples.size()<5:examples.append({"index":i,"p":p,"hit":hit.get("position",Vector3.INF)})
  print("EVENT SURFACE ",item.id," ",good,"/",tested," examples=",examples)
  check(float(good)/tested>=.99,"Event follows real pavement: "+item.id)
  check(data.version>=100 and data.points.size()==data.distances.size(),"Regional event schema/version: "+item.id)
  check(data.checkpoints[-1]==data.finish_index,"Every event has a real finish checkpoint")
 print("REGIONAL EVENTS ","FAIL" if failed else "PASS");world.queue_free();await process_frame;quit(1 if failed else 0)
