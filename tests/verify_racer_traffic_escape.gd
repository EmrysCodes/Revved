extends SceneTree
const PILOT=preload("res://racing/route_pilot.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var scene:=Node3D.new();root.add_child(scene)
	var floor:=StaticBody3D.new();scene.add_child(floor)
	var surface:=CollisionShape3D.new();var ground:=BoxShape3D.new();ground.size=Vector3(100,.2,300);surface.shape=ground;surface.position.y=-.1;floor.add_child(surface)
	var car:CharacterBody3D=load("res://vehicles/arcade_car.tscn").instantiate();car.is_player=false;scene.add_child(car);car.set_physics_process(false);car.position=Vector3(0,.1,6)
	var traffic:=CharacterBody3D.new();scene.add_child(traffic);traffic.collision_layer=4;traffic.collision_mask=0
	var collision:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(1.8,1.5,4.2);collision.shape=box;collision.position.y=.8;traffic.add_child(collision)
	traffic.position=Vector3(-1.6,0,0);traffic.rotation.y=.4
	var path:=PackedVector3Array();var distances:=PackedFloat64Array()
	for i in range(120):path.append(Vector3(0,0,8-i));distances.append(i)
	var cursor:=0;var reversed:=false
	for frame in range(900):
		var inputs:Dictionary=PILOT.command(car,path,distances,cursor,15,0)
		cursor=inputs.cursor
		if inputs.throttle<0:reversed=true
		car._step_motion(1.0/60,inputs.throttle,inputs.steering,inputs.brake,false)
		if frame%8==0:await physics_frame
		if frame%120==0:print("ESCAPE ",frame," pos ",car.position," blocked ",car.get_meta("blocked_frames",0)," reverse ",car.get_meta("escape_frames",0))
		if car.position.z< -25:break
	if car.position.z>=-25:push_error("Racer must get past a stopped traffic car without teleporting");quit(1);return
	print("TRAFFIC ESCAPE PASS / reversed=",reversed," / position ",car.position)
	quit()
