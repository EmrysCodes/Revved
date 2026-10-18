extends SceneTree
const STEP:=1.0/60.0
var car: CharacterBody3D
func _initialize() -> void:
	call_deferred("_run")
func reset_car() -> void:
	car.call("_reset_car")
	for frame in range(40):
		car.call("_step_motion",STEP,0.0,0.0,false,false)
		await physics_frame
func launch(target: float) -> float:
	await reset_car()
	for frame in range(4800):
		car.call("_step_motion",STEP,1.0,0.0,false,false)
		await physics_frame
		if car.velocity.length()>=target:
			return (frame+1)*STEP
	return INF
func _run() -> void:
	var settings: Node=root.get_node("GameSettings")
	settings.set_performance(0,0,0,false)
	settings.set_performance_brands(0,0,0,false)
	var floor_body:=StaticBody3D.new()
	var collision:=CollisionShape3D.new()
	var shape:=BoxShape3D.new()
	shape.size=Vector3(40000,1,40000)
	collision.shape=shape
	floor_body.add_child(collision)
	floor_body.position.y=-0.5
	root.add_child(floor_body)
	car=load("res://vehicles/arcade_car.tscn").instantiate()
	car.position.y=1
	root.add_child(car)
	car.set_physics_process(false)
	var sixty:=26.8224
	var stock_sixty:=await launch(sixty)
	var stock_hundred:=await launch(44.704)
	var stock_top:=await launch(car.top_speed-0.1)
	print("STOCK 0-60 ",stock_sixty,"s; 0-100 ",stock_hundred,"s; top ",settings.format_speed(car.top_speed)," in ",stock_top,"s")
	assert(stock_sixty>4.7 and stock_sixty<5.6,"R34-inspired stock launch window")
	assert(stock_hundred>stock_sixty*2 and stock_hundred<14,"High-speed power taper")
	assert(stock_top<45 and car.velocity.length()<=69.31,"Stock can reach higher top speed without overshoot")
	await reset_car()
	car.velocity=Vector3.FORWARD*sixty
	var start:=car.position
	for frame in range(300):
		car.call("_step_motion",STEP,0.0,0.0,true,false)
		await physics_frame
		if Vector2(car.velocity.x,car.velocity.z).length()<0.1:
			break
	var stop_distance:=start.distance_to(car.position)
	print("STOCK 60-0 distance ",stop_distance,"m")
	assert(stop_distance>30 and stop_distance<40,"Stock braking around 100-130ft")
	var previous_slowest:=stock_sixty
	var previous_highest_speed: float=car.top_speed
	for tier in range(1,4):
		var quickest:=INF
		var slowest:=0.0
		var lowest_speed:=INF
		var highest_speed:=0.0
		for brand in range(3):
			settings.set_performance(tier,tier,tier,false)
			settings.set_performance_brands(brand,brand,brand,false)
			var time:=await launch(sixty)
			print("TIER ",tier," BRAND ",brand," 0-60 ",time,"s top ",settings.format_speed(car.top_speed))
			quickest=minf(quickest,time);slowest=maxf(slowest,time)
			lowest_speed=minf(lowest_speed,car.top_speed);highest_speed=maxf(highest_speed,car.top_speed)
		assert(slowest<previous_slowest and lowest_speed>previous_highest_speed,"Every higher-tier brand improves launch and speed over previous tier")
		previous_slowest=quickest
		previous_highest_speed=highest_speed
	# Higher engine ceilings must not make steering sharper at the same road speed.
	await reset_car()
	car.velocity=Vector3.FORWARD*65
	for frame in range(20):
		car.call("_step_motion",STEP,1.0,1.0,false,false)
		await physics_frame
	assert(absf(car.get("_yaw_rate"))<0.3 and car.is_on_floor(),"Controlled high-speed steering")
	settings.set_performance(0,0,0,false)
	settings.set_performance_brands(0,0,0,false)
	assert(is_equal_approx(car.top_speed,69.3) and is_equal_approx(car.acceleration,7.0),"Stock restore has no stacked tuning")
	print("PASS: stock speed/acceleration/braking, all nine engine tier/brand launches, progression, high-speed steering, stock restore")
	quit()
