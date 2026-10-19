extends RefCounted
## Shared route-following controls; movement remains in the real vehicle controller.
static func command(driver: CharacterBody3D,path: PackedVector3Array,distances: PackedFloat64Array,cursor: int,cruise_speed: float,lane_offset: float) -> Dictionary:
	var best:=INF
	for i in range(maxi(0,cursor-4),mini(path.size()-1,cursor+38)):
		var separation:=Vector2(driver.global_position.x-path[i].x,driver.global_position.z-path[i].z).length()
		if separation<best:
			best=separation;cursor=i
	var speed:=Vector2(driver.velocity.x,driver.velocity.z).length()
	var lookahead:=12.0+speed*0.35
	var target:=cursor
	while target<path.size()-1 and distances[target]<distances[cursor]+lookahead:
		target+=1
	var tangent: Vector3=(path[mini(target+1,path.size()-1)]-path[maxi(0,target-1)]).normalized()
	var desired: Vector3=path[target]+tangent.cross(Vector3.UP)*lane_offset-driver.global_position
	desired.y=0
	var angle:=(-driver.global_basis.z).signed_angle_to(desired.normalized(),Vector3.UP)
	var target_speed:=cruise_speed
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
			target_speed=minf(target_speed,maxf(0,obstacle.collider.velocity.length()-2))
	return {"cursor":cursor,"distance":best,"throttle":1.0 if speed<target_speed else 0.0,"steering":clampf(-angle*2.7,-1,1),"brake":speed>target_speed+0.7}
