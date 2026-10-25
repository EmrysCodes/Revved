extends SceneTree
var failed:=false
func _initialize()->void:call_deferred("run")
func run()->void:
 var profile:=root.get_node("StreetProfile");profile.launch_mode="free"
 var world:Node3D=load("res://world/handbuilt/plattsburgh_region.scn").instantiate();world.set_meta("disable_population",true);root.add_child(world)
 for i in range(20):await physics_frame
 var car:CharacterBody3D=world.car;car.set_physics_process(false)
 for id:String in ["capital_run","asylum_circuit","pitkin_dash"]:
  if not OS.get_cmdline_user_args().is_empty() and OS.get_cmdline_user_args()[0]!=id:continue
  var old:Node=world.get_node("CityRace");old.exit_to_free_roam();world.remove_child(old);old.free();profile.selected_event=id
  var event:Node=load("res://racing/capital_run.tscn").instantiate();world.add_child(event);event.start_race();car.global_position=event.route[0]+Vector3.UP*15;car.collision_layer=0;car.collision_mask=0
  var finished:=false
  for frame in range(14400):
   await physics_frame
   finished=event.finish_times.size()==event.rival_count
   if finished:break
  var results:Array=[]
  for rival:CharacterBody3D in event.opponents:
   var contacts:Array=[]
   if not rival.finished:
    for i in range(rival.get_slide_collision_count()):contacts.append({"body":str(rival.get_slide_collision(i).get_collider().get_path()),"normal":rival.get_slide_collision(i).get_normal()})
   results.append({"name":str(rival.name),"finished":rival.finished,"recoveries":rival.recoveries,"cursor":rival.cursor,"position":rival.position,"contacts":contacts})
  print("REGIONAL RIVALS ",id," ",results)
  if not finished:failed=true;push_error("Rivals did not complete "+id)
  event.exit_to_free_roam()
 print("RIVAL CAMPAIGN ","FAIL" if failed else "PASS");world.queue_free();await process_frame;quit(1 if failed else 0)
