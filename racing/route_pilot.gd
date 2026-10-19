extends RefCounted
## Shared route-following controls; movement remains in the real vehicle controller.
static func command(driver: CharacterBody3D,path: PackedVector3Array,distances: PackedFloat64Array,cursor: int,cruise_speed: float,lane_offset: float,lane_limit:=3.8) -> Dictionary:
	lane_offset=clampf(lane_offset,-lane_limit,lane_limit)
	var best:=INF
	for i in range(maxi(0,cursor-4),mini(path.size()-1,cursor+38)):
		var separation:=Vector2(driver.global_position.x-path[i].x,driver.global_position.z-path[i].z).length()
		if separation<best:
			best=separation;cursor=i
	var speed:=Vector2(driver.velocity.x,driver.velocity.z).length()
	var contact_normal:=Vector3.ZERO
	for i in range(driver.get_slide_collision_count()):
		var hit:KinematicCollision3D=driver.get_slide_collision(i)
		if hit.get_collider() is CharacterBody3D:
			contact_normal=hit.get_normal()
			break
	var contact_age:int=maxi(0,int(driver.get_meta("vehicle_contact_age",0))-1)
	if contact_normal.length_squared()>.1:
		contact_age=90;driver.set_meta("vehicle_contact_normal",contact_normal)
	elif contact_age>0:contact_normal=driver.get_meta("vehicle_contact_normal",Vector3.ZERO)
	driver.set_meta("vehicle_contact_age",contact_age)
	var blocked:int=int(driver.get_meta("blocked_frames",0))+1 if speed<1.5 and contact_age>0 else 0
	driver.set_meta("blocked_frames",blocked)
	var escape:int=int(driver.get_meta("escape_frames",0))
	if blocked>55 and escape==0:
		escape=50;driver.set_meta("blocked_frames",0)
		var road_right:Vector3=(path[mini(cursor+3,path.size()-1)]-path[cursor]).cross(Vector3.UP).normalized()
		driver.set_meta("pass_lane",2.3*signf(contact_normal.dot(road_right)));driver.set_meta("pass_hold",220)
	if escape>0:
		driver.set_meta("escape_frames",escape-1)
		return {"cursor":cursor,"distance":best,"throttle":-1.0,"steering":0.0,"brake":false}
	var lookahead:=12.0+speed*0.35
	if int(driver.get_meta("pass_hold",0))>0:lookahead=minf(lookahead,maxf(7,speed*.4))
	var target:=cursor
	while target<path.size()-1 and distances[target]<distances[cursor]+lookahead:
		target+=1
	var tangent: Vector3=(path[mini(target+1,path.size()-1)]-path[maxi(0,target-1)]).normalized()
	var pass_hold:int=maxi(0,int(driver.get_meta("pass_hold",0))-1)
	driver.set_meta("pass_hold",pass_hold)
	var effective_lane:float=clampf(float(driver.get_meta("pass_lane",lane_offset)),-lane_limit,lane_limit) if pass_hold>0 else lane_offset
	var desired: Vector3=path[target]+tangent.cross(Vector3.UP)*effective_lane-driver.global_position
	desired.y=0
	var angle:=(-driver.global_basis.z).signed_angle_to(desired.normalized(),Vector3.UP)
	var target_speed:=minf(cruise_speed,20) if pass_hold>0 else cruise_speed
	var braking_horizon:=maxf(45,speed*speed/(2*driver.braking*0.8)+25)
	for i in range(cursor,mini(path.size()-3,cursor+70),3):
		var ahead: float=distances[i]-distances[cursor]
		if ahead>braking_horizon: break
		var a: Vector3=path[i]-path[maxi(0,i-3)]
		var b: Vector3=path[mini(path.size()-1,i+3)]-path[i]
		a.y=0;b.y=0
		if a.length()<0.1 or b.length()<0.1: continue
		var curvature:=absf(a.signed_angle_to(b,Vector3.UP))/maxf((a.length()+b.length())*0.5,1)
		var corner_speed:=clampf(sqrt(17.0/maxf(curvature,0.001)),11.0,cruise_speed)
		target_speed=minf(target_speed,sqrt(corner_speed*corner_speed+2*driver.braking*0.75*maxf(ahead-12,0)))
	# A short forward vehicle check avoids simply pushing through the player.
	if driver.is_on_floor() and speed>2:
		var query:=PhysicsRayQueryParameters3D.create(driver.global_position+Vector3.UP*0.7,driver.global_position-driver.global_basis.z*maxf(7,speed*0.55)+Vector3.UP*0.7)
		query.exclude=[driver.get_rid()]
		var obstacle:=driver.get_world_3d().direct_space_state.intersect_ray(query)
		if not obstacle.is_empty() and obstacle.collider is CharacterBody3D:
			var passing:=false
			if obstacle.collider.collision_layer&7:
				var right:Vector3=tangent.cross(Vector3.UP)
				var obstacle_side:float=(obstacle.collider.global_position-path[cursor]).dot(right)
				var preferred:float=-2.3 if obstacle_side>lane_offset else 2.3
				for side:float in [preferred,-preferred,preferred*1.5,-preferred*1.5]:
					if absf(side)>lane_limit:continue
					var passing_target:=cursor
					while passing_target<path.size()-1 and distances[passing_target]<distances[cursor]+maxf(7,speed*.4):passing_target+=1
					var next:Vector3=path[passing_target]+right*side
					var clear:=true
					for edge in [-.85,.85]:
						var check:=PhysicsRayQueryParameters3D.create(driver.global_position+Vector3.UP*.9+right*edge,next+Vector3.UP*.9+right*edge,7,[driver.get_rid()])
						if not driver.get_world_3d().direct_space_state.intersect_ray(check).is_empty():clear=false
					var shape:=SphereShape3D.new();shape.radius=.85
					var volume:=PhysicsShapeQueryParameters3D.new();volume.shape=shape;volume.collision_mask=7;volume.exclude=[driver.get_rid()]
					for index:int in [mini(cursor+3,passing_target),int((cursor+passing_target)/2),passing_target]:
						volume.transform=Transform3D(Basis.IDENTITY,path[index]+right*side+Vector3.UP)
						if not driver.get_world_3d().direct_space_state.intersect_shape(volume,1).is_empty():clear=false
					if clear:
						driver.set_meta("pass_lane",side);driver.set_meta("pass_hold",100)
						desired=next-driver.global_position;desired.y=0
						angle=(-driver.global_basis.z).signed_angle_to(desired.normalized(),Vector3.UP);target_speed=minf(target_speed,20);passing=true;break

			if not passing:target_speed=minf(target_speed,maxf(0,obstacle.collider.velocity.length()-2))
	return {"cursor":cursor,"distance":best,"throttle":1.0 if speed<target_speed else 0.0,"steering":clampf(-angle*2.7,-1,1),"brake":speed>target_speed+0.7}

static func lane_limit_for_section(section:String) -> float:
	return .8 if section.contains("RAMP") or section.contains("INTERCHANGE") or section.contains("EXIT") else 3.8
