extends SceneTree
var failed:=false
func _initialize()->void:call_deferred("run")
func check(value:bool,message:String)->void:
 if not value:failed=true;push_error(message)
func road(parent:Node3D,points:PackedVector3Array)->Node3D:
 var n:=Node3D.new();n.set_script(load("res://world/workshop/road.gd"));n.points=points;n.curve_softness=0;n.set_meta("workshop_road",true);parent.add_child(n);return n
func run()->void:
 var world:=Node3D.new();root.add_child(world);var network:=Node3D.new();network.set_script(load("res://world/workshop/road_network.gd"));world.add_child(network)
 road(network,PackedVector3Array([Vector3(-60,0,0),Vector3.ZERO]));road(network,PackedVector3Array([Vector3.ZERO,Vector3(60,0,0)]));road(network,PackedVector3Array([Vector3.ZERO,Vector3(0,0,-60)]))
 # Same plan-view crossing, different road level: it must remain disconnected.
 road(network,PackedVector3Array([Vector3(0,6,-60),Vector3(0,6,60)]))
 for i in range(8):await physics_frame
 check(network.stats.roads==4 and network.stats.junctions==1,"Only shared same-height endpoints form a junction")
 for x in range(-18,19,2):
  var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x,2,0),Vector3(x,-1,0)))
  check(not hit.is_empty() and absf(hit.position.y)<.03,"Continuous, curb-free east/west junction at "+str(x))
 for z in range(-18,1,2):
  var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,2,z),Vector3(0,-1,z)))
  check(not hit.is_empty() and absf(hit.position.y)<.03,"Continuous T approach at "+str(z))
 var hit:=world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,8,0),Vector3(0,5,0)));check(not hit.is_empty() and absf(hit.position.y-6)<.03,"Overpass keeps its own physical surface")
 var packed:=PackedScene.new();for n:Node in network.get_children():
  if n.has_meta("workshop_road"):n.owner=world
 network.owner=world;packed.pack(world);var state:=packed.get_state();var saved_generated:=false
 for i in range(state.get_node_count()):saved_generated=saved_generated or str(state.get_node_name(i)).contains("GeneratedNetwork")
 check(not saved_generated,"Rebuildable road batches are not serialized as duplicate geometry")
 print("ROAD NETWORK ","FAIL" if failed else "PASS");world.queue_free();await process_frame;quit(1 if failed else 0)
