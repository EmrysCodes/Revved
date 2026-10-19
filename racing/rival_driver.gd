extends "res://vehicles/arcade_car.gd"
## Rivals drive the same collision/controller code as the player.
var event: Node
var rival_name := "RIVAL"
var rival_color := Color.RED
var cruise_speed := 40.0
var lane_offset := 0.0
var cursor := 0
var finished := false
var stuck_time := 0.0
var recovery_time := 0.0
var recoveries := 0
func _ready() -> void:
	super._ready()
	GameSettings.performance_changed.disconnect(_apply_performance)
	GameSettings.car_style_changed.disconnect(_car_model.apply_saved_style)
	$HUD.hide()
	$PauseMenu.process_mode=Node.PROCESS_MODE_DISABLED
	_camera.current=false
	top_speed=cruise_speed;acceleration=7.5;braking=11.5;road_grip=11
	for mesh: MeshInstance3D in _car_model.get_node("Body").get_children():
		for surface in range(mesh.mesh.get_surface_count()):
			var source: Material=mesh.mesh.surface_get_material(surface)
			mesh.set_surface_override_material(surface,null)
			if source is StandardMaterial3D and source.resource_name=="Car":
				var paint: StandardMaterial3D=source.duplicate()
				paint.albedo_color=rival_color
				mesh.set_surface_override_material(surface,paint)
func _unhandled_key_input(_input: InputEvent) -> void:
	pass
func _process(_delta: float) -> void:
	pass
func _physics_process(delta: float) -> void:
	if finished or not is_instance_valid(event) or not event.rivals_can_drive():
		_step_motion(delta,0,0,true,false)
		return
	if recovery_time>0:
		recovery_time-=delta
		_step_motion(delta,0,0,true,false)
		return
	drive_route(delta)
func drive_route(delta: float) -> void:
	var path: PackedVector3Array=event.route
	var distances: PackedFloat64Array=event.distances
	var inputs: Dictionary=preload("res://racing/route_pilot.gd").command(self,path,distances,cursor,cruise_speed,lane_offset,preload("res://racing/route_pilot.gd").lane_limit_for_section(event._section_at(cursor)))
	cursor=inputs.cursor
	var speed:=Vector2(velocity.x,velocity.z).length()
	var best: float=inputs.distance
	_step_motion(delta,inputs.throttle,inputs.steering,inputs.brake,false)
	stuck_time=stuck_time+delta if speed<1.5 else 0.0
	if stuck_time>5 or best>45 or position.y< -1:
		cursor=maxi(0,cursor-5)
		event.place_car(self,cursor,lane_offset)
		event.sync_previous(self)
		stuck_time=0;recovery_time=2;recoveries+=1
func complete() -> void:
	finished=true;velocity=Vector3.ZERO
	# Finished rivals cannot park an invisible collision barrier on the finish line.
	collision_layer=0
