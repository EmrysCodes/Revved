extends SceneTree
const STEP:=1.0/60.0
var car: CharacterBody3D
func _initialize() -> void:
	call_deferred("_run")
func settle() -> void:
	car.call("_reset_car")
	for i in range(40):
		car.call("_step_motion",STEP,0.0,0.0,false,false)
		await physics_frame
func slip() -> float:
	var velocity:=Vector3(car.velocity.x,0,car.velocity.z)
	return absf(atan2(velocity.dot(car.global_basis.x),velocity.dot(-car.global_basis.z)))
func _run() -> void:
	var settings: Node=root.get_node("GameSettings")
	settings.set_performance(0,0,0,false)
	settings.set_performance_brands(0,0,0,false)
	var floor_body:=StaticBody3D.new()
	var collision:=CollisionShape3D.new()
	var shape:=BoxShape3D.new()
	shape.size=Vector3(10000,1,10000)
	collision.shape=shape;floor_body.position.y=-0.5
	floor_body.add_child(collision);root.add_child(floor_body)
	car=load("res://vehicles/arcade_car.tscn").instantiate()
	car.position.y=1;root.add_child(car);car.set_physics_process(false)
	for mph in [80,120,150]:
		var normal_turn:=0.0
		for handbrake in [false,true]:
			await settle()
			car.velocity=Vector3.FORWARD*(mph*0.44704)
			for i in range(60):
				car.call("_step_motion",STEP,1.0,1.0,false,handbrake)
				await physics_frame
			var turn:=absf(car.rotation.y)
			var angle:=slip()
			var speed:=Vector2(car.velocity.x,car.velocity.z).length()
			print("CONTROL ",mph," MPH handbrake ",handbrake," heading ",rad_to_deg(turn)," slip ",rad_to_deg(angle)," speed ",settings.format_speed(speed))
			assert(turn>0.4 and turn<1.5 and car.is_on_floor(),"Tight usable high-speed turn without spinning")
			if handbrake:
				assert(turn>normal_turn*1.15,"Handbrake tightens turning arc")
				assert(angle>0.10 and angle<0.65,"Bounded controllable drift angle")
				for i in range(36):
					car.call("_step_motion",STEP,1.0,0.0,false,false)
					await physics_frame
				assert(slip()<0.05,"Release catches slide within 0.6 seconds")
			else:
				normal_turn=turn
				assert(angle<0.14,"Normal cornering remains planted")
	print("PASS: 80/120/150 MPH grip turns, tighter bounded handbrake arcs and fast drift recovery")
	quit()
