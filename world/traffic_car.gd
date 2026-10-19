extends CharacterBody3D
## Traffic follows an authored lane. It brakes for other vehicles instead of teleporting through them.
var fleet:Node3D
var path:PackedVector3Array
var distances:PackedFloat64Array
var route_length:=0.0
var along:=0.0
var cursor:=0
var cruise:=11.5
var speed:=0.0
var lane:=2.7
var serial:=0
var model:Node3D
var wheels:Array[Node3D]=[]
var spin:=0.0
var initialized:=false
var blocked_time:=0.0
var reverse_time:=0.0
func _ready() -> void:
	collision_layer=4;collision_mask=7
	var shape:=BoxShape3D.new();shape.size=Vector3(1.8,1.28,4.2)
	var collision:=CollisionShape3D.new();collision.shape=shape;collision.position.y=.76;add_child(collision)
	var labels:=["sedan","suv","taxi","van","hatchback-sports","delivery","sedan-sports"]
	model=load("res://assets/traffic/kenney/"+labels[serial%labels.size()]+".glb").instantiate();add_child(model)
	model.rotation.y=PI;model.scale=Vector3.ONE*1.3
	shape.size=Vector3(1.9,1.5,[3.4,3.6,3.65,3.65,3.4,4.3,3.5][serial%labels.size()]);collision.position.y=.85
	for child:Node3D in model.get_children():
		if str(child.name).begins_with("wheel"):wheels.append(child)
		if child is GeometryInstance3D:child.visibility_range_end=380
	var point:=sample(along);global_position=point[0];rotation.y=atan2(-point[1].x,-point[1].z)
	initialized=true
func sample(value:float) -> Array:
	value=fposmod(value,route_length)
	if cursor>=path.size()-1 or value<distances[cursor]:cursor=0
	while cursor<path.size()-2 and distances[cursor+1]<value:cursor+=1
	var ratio:=clampf((value-distances[cursor])/maxf(.01,distances[cursor+1]-distances[cursor]),0,1)
	var tangent:Vector3=(path[cursor+1]-path[cursor]).normalized()
	var right:=tangent.cross(Vector3.UP).normalized()
	return [path[cursor].lerp(path[cursor+1],ratio)+right*lane,tangent]
func _physics_process(delta:float) -> void:
	if not initialized or not is_instance_valid(fleet):return
	var player:CharacterBody3D=fleet.get_parent().car
	var near:=global_position.distance_squared_to(player.global_position)<420*420
	visible=near
	collision_layer=4 if near else 0
	collision_mask=7 if near else 0
	if not near:
		along=fposmod(along+cruise*delta,route_length)
		var point:=sample(along);global_position=point[0];rotation.y=atan2(-point[1].x,-point[1].z)
		velocity=Vector3.ZERO;return
	var desired:=cruise
	var direction:Vector3=-global_basis.z
	var query:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.9,global_position+Vector3.UP*.9+direction*(7+speed*.9),7,[get_rid()])
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var separation:float=global_position.distance_to(hit.position)
		desired=minf(desired,maxf(0,(separation-4)*.65))
		if hit.collider is CharacterBody3D:
			desired=minf(desired,maxf(0,hit.collider.velocity.length()-1)+maxf(0,separation-8)*.25)
			if separation<3.5 and absf(speed)<.4 and desired<.5:blocked_time+=delta
	if fleet.should_stop(global_position,direction):desired=0
	reverse_time=maxf(0,reverse_time-delta)
	if blocked_time>1.5 and reverse_time<=0:
		reverse_time=1.8;blocked_time=0
	if reverse_time>0:desired=-2.0
	speed=move_toward(speed,desired,(3.0 if desired>speed else 9.5)*delta)
	var next:=fposmod(along+speed*delta,route_length)
	var point:=sample(next)
	var motion:Vector3=point[0]-global_position
	if motion.length()>8:
		# Distant culling can leave the body on an older sample. Never jump beside the player.
		speed=0;return
	var collision:=move_and_collide(motion)
	if collision==null:along=next
	else:
		if collision.get_collider() is CharacterBody3D:blocked_time+=delta
		speed=0
	if collision==null:blocked_time=maxf(0,blocked_time-delta*.25)
	velocity=motion/maxf(delta,.001) if collision==null else Vector3.ZERO
	var steering_angle:=angle_difference(rotation.y,atan2(-point[1].x,-point[1].z))
	rotation.y+=clampf(steering_angle,-delta*2,delta*2)
	spin=wrapf(spin+speed*delta/.32,-PI,PI)
	for wheel in wheels:
		wheel.rotation.x=spin
		wheel.rotation.y=clampf(-steering_angle*3,-.4,.4) if str(wheel.name).contains("front") else 0.0
