extends Node3D
## One complete street event. Driver progress is based on ordered, swept gate crossings.
signal state_changed
enum Phase { FREE_ROAM, COUNTDOWN, RUNNING, RESULTS }
const DATA_PATH:="res://racing/capital_run_route.json"
const CAR_SCENE:=preload("res://vehicles/arcade_car.tscn")
const RIVAL_SCRIPT:=preload("res://racing/rival_driver.gd")
var state: Phase=Phase.FREE_ROAM
var route:=PackedVector3Array()
var distances:=PackedFloat64Array()
var checkpoint_indices:=PackedInt32Array()
var sections: Array=[]
var length:=0.0
var finish_index:=0
var elapsed:=0.0
var countdown_remaining:=3.0
var recovery_remaining:=0.0
var go_remaining:=0.0
var best_time:=INF
var best_path:="user://races.cfg"
var best_saved:=false
var player_recoveries:=0
var opponents: Array[CharacterBody3D]=[]
var next_checkpoint: Dictionary={}
var progress: Dictionary={}
var previous_positions: Dictionary={}
var finish_times: Dictionary={}
var gates: Array[Node3D]=[]
var breadcrumbs: Array=[]
var gate_material: StandardMaterial3D
var entry_marker: Node3D
var saved_roam_transform: Transform3D
var entry_position:=Vector3.ZERO
var saved_collision_mask:=1
var ui_timer:=0.0
var last_gate:=-2
var player: CharacterBody3D
var city: Node3D
@onready var hud: CanvasLayer=$HUD
func _ready() -> void:
	city=get_parent();player=city.car
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	for point in data.points: route.append(Vector3(point[0],point[1],point[2]))
	distances=PackedFloat64Array(data.distances)
	checkpoint_indices=PackedInt32Array(data.checkpoints)
	sections=data.sections;length=data.length;finish_index=data.finish_index
	entry_position=player.global_position
	saved_roam_transform=player.global_transform;saved_collision_mask=player.collision_mask
	var config:=ConfigFile.new()
	if config.load(best_path)==OK:
		var value: Variant=config.get_value("capital_run_v1","best_seconds",INF)
		if (value is float or value is int) and value>0 and is_finite(float(value)):
			best_time=float(value);best_saved=true
	_build_markers()
	player.reset_to_spawn.connect(_on_player_reset)
	hud.retry_pressed.connect(func():start_race(true))
	hud.roam_pressed.connect(exit_to_free_roam)
	player.get_node("PauseMenu").bind_city_race(self)
	_refresh_markers();_update_ui()
func is_running() -> bool:
	return state==Phase.RUNNING
func rivals_can_drive() -> bool:
	return state in [Phase.RUNNING,Phase.RESULTS]
func is_active() -> bool:
	return state!=Phase.FREE_ROAM
func _unhandled_key_input(input: InputEvent) -> void:
	if not input is InputEventKey or not input.pressed or input.echo: return
	if input.physical_keycode==KEY_E and state==Phase.FREE_ROAM:
		if Vector2(player.position.x-entry_position.x,player.position.z-entry_position.z).length()<55 and player.velocity.length()<5:
			start_race();get_viewport().set_input_as_handled()
	elif input.physical_keycode==KEY_Q and state in [Phase.COUNTDOWN,Phase.RUNNING]:
		exit_to_free_roam();get_viewport().set_input_as_handled()
func _set_state(value: Phase) -> void:
	state=value
	city.get_node("CityHUD/Screen/Readout").visible=state==Phase.FREE_ROAM
	state_changed.emit()
func start_race(retry:=false) -> void:
	if get_tree().paused: return
	if not retry and state==Phase.FREE_ROAM:
		saved_roam_transform=player.global_transform
		saved_collision_mask=player.collision_mask
	_clear_opponents()
	next_checkpoint.clear();progress.clear();previous_positions.clear();finish_times.clear()
	elapsed=0;countdown_remaining=3;recovery_remaining=0;go_remaining=0;player_recoveries=0
	player.controls_locked=true;player.collision_mask=saved_collision_mask|2
	place_car(player,0,-2.2)
	_register(player)
	var names: Array[String]=["MARA","JAX","NOVA"]
	var colors: Array[Color]=[Color(0.7,0.02,0.025),Color(0.95,0.56,0.015),Color(0.8,0.84,0.88)]
	for i in range(3):
		var rival: CharacterBody3D=CAR_SCENE.instantiate()
		rival.set_script(RIVAL_SCRIPT)
		rival.name=names[i];rival.event=self;rival.rival_name=names[i];rival.rival_color=colors[i]
		rival.cruise_speed=[40.0,42.0,39.0][i]
		rival.lane_offset=[2.2,-2.2,0.0][i]
		rival.collision_layer=2;rival.collision_mask=3
		rival.align_to_slopes=true;rival.floor_snap_length=0.6;rival.floor_constant_speed=true
		add_child(rival);opponents.append(rival)
		place_car(rival,[2,4,6][i],rival.lane_offset)
		_register(rival)
	player.get_node("CameraArm/FollowCamera").current=true
	get_viewport().gui_release_focus()
	last_gate=-2;_set_state(Phase.COUNTDOWN);_refresh_markers();_update_ui()
func _register(driver: CharacterBody3D) -> void:
	var id:=driver.get_instance_id()
	next_checkpoint[id]=0;progress[id]=0.0
	sync_previous(driver);_project_progress(driver)
func place_car(driver: CharacterBody3D,index: int,side:=0.0) -> void:
	index=clampi(index,0,route.size()-2)
	var direction:=route[mini(index+3,route.size()-1)]-route[index]
	direction.y=0;direction=direction.normalized()
	var transform:=Transform3D(Basis(Vector3.UP,atan2(-direction.x,-direction.z)),route[index]+direction.cross(Vector3.UP)*side+Vector3.UP*0.25)
	driver.global_transform=transform;driver.velocity=Vector3.ZERO
	driver.set("_steering",0.0);driver.set("_yaw_rate",0.0);driver.set("_drift_blend",0.0)
	driver.get_node("Visuals").rotation=Vector3.ZERO
	driver.call("_snap_camera");driver.reset_physics_interpolation()
func sync_previous(driver: CharacterBody3D) -> void:
	previous_positions[driver.get_instance_id()]=driver.global_position
func _physics_process(delta: float) -> void:
	if state==Phase.COUNTDOWN:
		countdown_remaining-=delta
		if countdown_remaining<=0:
			player.controls_locked=false;go_remaining=0.8
			_set_state(Phase.RUNNING)
	elif state==Phase.RUNNING:
		elapsed+=delta
		if recovery_remaining>0:
			recovery_remaining=maxf(0,recovery_remaining-delta)
			if recovery_remaining==0: player.controls_locked=false
		go_remaining=maxf(0,go_remaining-delta)
		for driver in opponents: _check_driver(driver,delta)
		_check_driver(player,delta)
	elif state==Phase.RESULTS and finish_times.size()<4:
		elapsed+=delta
		for driver in opponents: _check_driver(driver,delta)
	ui_timer+=delta
	if ui_timer>=0.08:
		ui_timer=0;_update_ui()
func _check_driver(driver: CharacterBody3D,delta: float) -> void:
	var id:=driver.get_instance_id()
	if finish_times.has(id): return
	var before: Vector3=previous_positions.get(id,driver.position)
	var after:=driver.global_position
	var target: int=next_checkpoint[id]
	if target<checkpoint_indices.size() and before.distance_to(after)<12:
		var index:=checkpoint_indices[target]
		var center:=route[index]
		var normal:=route[mini(index+3,route.size()-1)]-route[maxi(0,index-3)]
		normal.y=0;normal=normal.normalized()
		var d0: float=(before-center).dot(normal)
		var d1: float=(after-center).dot(normal)
		if d0<=0 and d1>=0 and d1-d0>0.01:
			var fraction:=clampf(-d0/(d1-d0),0,1)
			var crossing:=before.lerp(after,fraction)
			if Vector2(crossing.x-center.x,crossing.z-center.z).length()<11 and absf(crossing.y-center.y)<2.5:
				next_checkpoint[id]=target+1
				if target+1==checkpoint_indices.size():
					finish_times[id]=elapsed-delta*(1-fraction)
					progress[id]=length
					if driver!=player:
						driver.complete()
						if state==Phase.RESULTS: _show_results()
					else: _finish_player()
	previous_positions[id]=after
	if not finish_times.has(id): _project_progress(driver)
func _project_progress(driver: CharacterBody3D) -> float:
	var id:=driver.get_instance_id()
	var next: int=next_checkpoint.get(id,0)
	var first:=0 if next==0 else checkpoint_indices[next-1]
	var last:=checkpoint_indices[mini(next,checkpoint_indices.size()-1)]
	var nearest:=INF
	var projected: float=distances[first]
	for i in range(first,last):
		var point:=Geometry3D.get_closest_point_to_segment(driver.global_position,route[i],route[i+1])
		var separation:=point.distance_to(driver.global_position)
		if separation<nearest:
			nearest=separation;projected=distances[i]+route[i].distance_to(point)
	progress[id]=clampf(projected,distances[first],minf(length,distances[last]))
	return nearest
func player_place() -> int:
	var result:=1
	var id:=player.get_instance_id()
	for driver in opponents:
		var other:=driver.get_instance_id()
		if finish_times.has(other):
			if not finish_times.has(id) or finish_times[other]<finish_times[id]: result+=1
		elif not finish_times.has(id) and progress.get(other,0)>progress.get(id,0): result+=1
	return result
func _on_player_reset() -> void:
	if state!=Phase.RUNNING: return
	var next: int=next_checkpoint[player.get_instance_id()]
	var index:=0 if next==0 else checkpoint_indices[next-1]
	place_car(player,maxi(0,index-2))
	sync_previous(player);player.controls_locked=true
	recovery_remaining=2.0;player_recoveries+=1
func _finish_player() -> void:
	player.controls_locked=true;player.velocity=Vector3.ZERO
	var time: float=finish_times[player.get_instance_id()]
	if time<best_time:
		best_time=time
		var config:=ConfigFile.new();config.load(best_path)
		config.set_value("capital_run_v1","best_seconds",best_time)
		best_saved=config.save(best_path)==OK
	_set_state(Phase.RESULTS);_refresh_markers();_show_results()
func _show_results() -> void:
	var time: float=finish_times[player.get_instance_id()]
	var drivers: Array=[player];drivers.append_array(opponents)
	drivers.sort_custom(func(a,b):
		var a_done: bool=finish_times.has(a.get_instance_id())
		var b_done: bool=finish_times.has(b.get_instance_id())
		if a_done!=b_done: return a_done
		if a_done: return finish_times[a.get_instance_id()]<finish_times[b.get_instance_id()]
		return progress.get(a.get_instance_id(),0)>progress.get(b.get_instance_id(),0))
	var rows: Array=[]
	for driver in drivers:
		var id: int=driver.get_instance_id()
		rows.append({"name":"YOU" if driver==player else driver.rival_name,"time":time_text(finish_times[id]) if finish_times.has(id) else GameSettings.format_distance(maxf(0,length-progress.get(id,0)))+" left","player":driver==player})
	hud.show_results(player_place(),time_text(time),time_text(best_time),rows,best_saved)
func exit_to_free_roam() -> void:
	if state==Phase.FREE_ROAM: return
	_clear_opponents()
	player.controls_locked=false;player.collision_mask=saved_collision_mask
	player.global_transform=saved_roam_transform;player.velocity=Vector3.ZERO
	player.set("_steering",0.0);player.set("_yaw_rate",0.0);player.set("_drift_blend",0.0)
	player.call("_snap_camera");player.reset_physics_interpolation()
	player.get_node("CameraArm/FollowCamera").current=true
	_set_state(Phase.FREE_ROAM);last_gate=-2
	_refresh_markers();_update_ui();get_viewport().gui_release_focus()
func _clear_opponents() -> void:
	for driver in opponents:
		driver.collision_layer=0;driver.collision_mask=0;driver.set_physics_process(false)
		driver.hide();driver.queue_free()
	opponents.clear()
func _section_at(index: int) -> String:
	for section in sections:
		if index>=section.start and index<=section.end: return section.label
	return "DOWNTOWN"
func _update_ui() -> void:
	if state==Phase.FREE_ROAM:
		hud.entry(GameSettings.format_distance(length),Vector2(player.position.x-entry_position.x,player.position.z-entry_position.z).length()<55,player.velocity.length()<5)
		return
	if state==Phase.RESULTS: return
	var target: int=next_checkpoint.get(player.get_instance_id(),0)
	var index:=checkpoint_indices[mini(target,checkpoint_indices.size()-1)]
	var desired:=route[index]-player.global_position;desired.y=0
	var angle:=(-player.global_basis.z).signed_angle_to(desired.normalized(),Vector3.UP)
	var instruction:= "STRAIGHT" if absf(angle)<0.35 else ("◀ LEFT" if angle>0 else "RIGHT ▶")
	if _project_progress(player)>35: instruction="OFF ROUTE — R to recover"
	elif player.velocity.length()>4 and player.velocity.dot(desired.normalized())< -2: instruction="WRONG WAY — R to recover"
	else: instruction+="  •  "+GameSettings.format_distance(desired.length(),true)
	hud.racing("%d / 4"%player_place(),time_text(elapsed),"CP %d / %d"%[target+1,checkpoint_indices.size()],_section_at(index),instruction)
	hud.center_text(str(maxi(1,ceili(countdown_remaining))) if state==Phase.COUNTDOWN else ("RECOVERING" if recovery_remaining>0 else ("GO!" if go_remaining>0 else "")))
	_refresh_markers()
func time_text(seconds: float) -> String:
	var hundredths:=int(maxf(seconds,0)*100)
	return "%02d:%02d.%02d"%[hundredths/6000,(hundredths/100)%60,hundredths%100]
func _build_markers() -> void:
	gate_material=StandardMaterial3D.new()
	gate_material.albedo_color=Color(0.15,0.95,0.65)
	gate_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	gate_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	gate_material.emission_enabled=true;gate_material.emission=Color(0.08,0.6,0.3)
	for index in checkpoint_indices:
		var gate:=_gate(route[index],index==finish_index)
		gates.append(gate)
	entry_marker=_gate(entry_position,true)
	var title:=Label3D.new();entry_marker.add_child(title)
	title.text="CAPITAL RUN\nE — ENTER";title.position.y=6;title.font_size=48;title.pixel_size=0.012
	title.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	var arrow:=ArrayMesh.new()
	var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tool.set_material(gate_material)
	for vertex in [Vector3(0,0,-3),Vector3(1.4,0,1),Vector3(-1.4,0,1)]: tool.add_vertex(vertex)
	tool.generate_normals();arrow=tool.commit()
	for i in range(8,finish_index,9):
		var node:=MeshInstance3D.new();add_child(node);node.mesh=arrow
		node.position=route[i]+Vector3.UP*0.12
		var direction:=route[mini(i+2,route.size()-1)]-route[i]
		node.rotation.y=atan2(-direction.x,-direction.z)
		breadcrumbs.append([node,i])
func _gate(point: Vector3,finish: bool) -> Node3D:
	var gate:=Node3D.new();add_child(gate);gate.position=point
	var index:=nearest_route_index(point)
	var direction:=route[mini(index+2,route.size()-1)]-route[maxi(0,index-2)]
	gate.rotation.y=atan2(-direction.x,-direction.z)
	for side in [-1,1]:
		var mesh:=MeshInstance3D.new();gate.add_child(mesh)
		var cylinder:=CylinderMesh.new();cylinder.top_radius=0.16;cylinder.bottom_radius=0.16;cylinder.height=5
		cylinder.material=gate_material;mesh.mesh=cylinder;mesh.position=Vector3(side*7,2.5,0)
	var beam:=MeshInstance3D.new();gate.add_child(beam)
	var box:=BoxMesh.new();box.size=Vector3(14,0.15,0.15);box.material=gate_material
	beam.mesh=box;beam.position.y=5
	var label:=Label3D.new();gate.add_child(label);label.position.y=5.5
	label.text="FINISH" if finish else "CHECKPOINT";label.font_size=40;label.pixel_size=0.01
	return gate
func nearest_route_index(point: Vector3) -> int:
	var best:=INF;var result:=0
	for i in range(route.size()):
		var distance:=route[i].distance_to(point)
		if distance<best: best=distance;result=i
	return result
func _refresh_markers() -> void:
	entry_marker.visible=state==Phase.FREE_ROAM
	var target: int=next_checkpoint.get(player.get_instance_id(),0)
	for i in range(gates.size()): gates[i].visible=state in [Phase.COUNTDOWN,Phase.RUNNING] and i==target
	var index:=0 if target==0 else checkpoint_indices[mini(target-1,checkpoint_indices.size()-1)]
	for arrow in breadcrumbs:
		arrow[0].visible=state in [Phase.COUNTDOWN,Phase.RUNNING] and arrow[1]>=index and distances[arrow[1]]<progress.get(player.get_instance_id(),0)+350
