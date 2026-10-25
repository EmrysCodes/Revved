extends SceneTree
const OUT="C:/Users/joshu/Documents/Codex/2026-10-18/referenced-chatgpt-conversation-this-is-an/outputs/"
var world:Node3D
func _initialize()->void:call_deferred("run")
func frames(count:int)->void:
 for i in range(count):await process_frame
func shot(name_value:String)->void:
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(OUT+name_value+".png")
 print("PROTOTYPE CAPTURE ",name_value)
func street_camera(prefix:String,target_z:float)->void:
 var chosen:Node3D=null;var best:=INF
 for road:Node3D in world.get_node("Roads").get_children():
  if not str(road.get_meta("street_name","")).begins_with(prefix) or road.points.size()<8:continue
  var point:Vector3=road.points[int(road.points.size()/2)]
  if absf(point.z-target_z)<best:best=absf(point.z-target_z);chosen=road
 if not chosen:return
 var i:=int(chosen.points.size()/2);var point:Vector3=chosen.points[i];var direction:Vector3=chosen.points[i+1]-point
 world.car.global_position=point+Vector3.UP*.15;world.car.rotation.y=atan2(-direction.x,-direction.z);world.car.velocity=Vector3.ZERO;world.car.reset_physics_interpolation();world.car._snap_camera();world._stream_tiles()
 for j in range(45):world.car._step_motion(1.0/60,0,0,true,false);await process_frame
 await create_timer(.7).timeout
func run()->void:
 root.size=Vector2i(1440,900)
 var profile:=root.get_node("StreetProfile");profile.launch_mode="free";profile.return_to_legacy=false
 var menu:Control=load("res://ui/front_end/main_menu.tscn").instantiate();root.add_child(menu);await frames(45);await shot("REVVED-Prototype-Main-Menu");menu.queue_free();await process_frame
 # Menu-only preview fixture; no profile or rewards are written to disk.
 profile.driver_created=true;profile.driver_name="Alex Mercer";profile.event_results={}
 var hub:Control=load("res://ui/legacy/legacy_hub.tscn").instantiate();root.add_child(hub);await frames(20);await shot("REVVED-Prototype-Event-Map");hub.show_chapter(1);await frames(10);await shot("REVVED-Prototype-Coast-Map");hub.queue_free();await process_frame
 profile.selected_event="capital_run";profile.launch_mode="free"
 world=load("res://world/handbuilt/plattsburgh_region.scn").instantiate();root.add_child(world);current_scene=world;await frames(90);world.car.set_physics_process(false);await shot("REVVED-Prototype-Downtown")
 await street_camera("Beekman St",0);await shot("REVVED-Prototype-Neighborhood")
 await street_camera("Lake Shore Rd",7500);await shot("REVVED-Prototype-Lakeshore")
 var event:=world.get_node("CityRace");event.start_race();world.car._snap_camera();world._stream_tiles()
 await frames(220);await shot("REVVED-Prototype-Race-GPS")
 event.exit_to_free_roam();world.car.get_node("PauseMenu").open_menu();world.car.get_node("PauseMenu")._open_garage();await frames(40);await shot("REVVED-Prototype-Garage");world.car.get_node("PauseMenu").close_menu()
 print("PROTOTYPE VISUAL CAPTURE PASS");quit()
