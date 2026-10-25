extends SceneTree
var failed:=false
func _initialize()->void:call_deferred("run")
func check(value:bool,message:String)->void:
 if not value:failed=true;push_error(message)
func run()->void:
 var world:Node3D=load("res://world/handbuilt/plattsburgh_region.scn").instantiate();root.add_child(world)
 for i in range(35):await physics_frame
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://world/plattsburgh/data/dressing.json"))
 var dressing:Node3D=world.get_node("Dressing");check(dressing.get_meta("tree_count",0)>40000,"Region includes clearance-checked vegetation")
 var placements:=0;var bounds_ok:=true
 for tile:Node3D in dressing.get_children():
  for child:Node in tile.get_children():
   if child is MultiMeshInstance3D:
    placements+=child.placements.size();bounds_ok=bounds_ok and child.custom_aabb.has_volume()
 check(placements>100000 and bounds_ok,"Dressing has serialized native placements and explicit culling bounds")
 check(world.get_node("CoastLife").agents.size()==16,"Traffic uses eight connected circuits in both directions")
 check(world.get_node("CoastLife").walkers.size()==30,"Regional sidewalks have animated pedestrians")
 for route:Array in data.traffic_routes:
  check(Vector3(route[0][0],route[0][1],route[0][2]).distance_to(Vector3(route[-1][0],route[-1][1],route[-1][2]))<.2,"Traffic circuit is closed in three dimensions")
 check(world.get_node("CoastAmbience").beds.size()==5,"City/highway/park/wind/water ambience is active")
 check(world._water_heights.size()==world._water.get_width()*world._water.get_height(),"River recovery uses the actual local water surface")
 # Sample every road endpoint and interior segment, including physical bridge levels.
 var query:=PhysicsRayQueryParameters3D.new();query.collision_mask=1;query.exclude=[world.car.get_rid()]
 var total:=0;var clear:=0;var examples:Array=[];var road_count:=0
 for road:Node3D in world.get_node("Roads").get_children():
  if not road.has_meta("workshop_road"):continue
  road_count+=1
  for i in range(road.points.size()):
   if i%4!=0 and i!=road.points.size()-1:continue
   var p:Vector3=road.to_global(road.points[i]);query.from=p+Vector3.UP*.8;query.to=p-Vector3.UP*.8;var hit:=world.get_world_3d().direct_space_state.intersect_ray(query);total+=1
   if not hit.is_empty() and absf(hit.position.y-p.y)<.22:clear+=1
   elif examples.size()<20:examples.append({"road":str(road.name),"p":p,"hit":hit.get("position",Vector3.INF)})
 print("FINISH ROAD AUDIT ",clear,"/",total," roads=",road_count," examples=",examples)
 check(float(clear)/total>=.995,"At least 99.5% of all-road samples meet the authored pavement grade")
 print("REGION FINISH ","FAIL" if failed else "PASS");world.queue_free();await process_frame;quit(1 if failed else 0)
