extends Node3D
## Generic CC0 engine/skid/impact mix; audio gearing never changes driving physics.
const RATIOS := [3.827,2.36,1.685,1.312,1.0,0.793]
var gear := 0
var rpm := 950.0
var shift_remaining := 0.0
var impact_cooldown := 0.3
var last_velocity := Vector3.ZERO
var engine: AudioStreamPlayer3D
var skid: AudioStreamPlayer3D
var impact: AudioStreamPlayer3D
@onready var car: CharacterBody3D = get_parent()
func _ready() -> void:
	name = "VehicleAudio"
	if AudioServer.get_bus_index("Vehicles")<0:
		AudioServer.add_bus(); AudioServer.set_bus_name(AudioServer.bus_count-1,"Vehicles")
	get_tree().root.get_node("StreetProfile").apply_audio()
	engine = player("engine",true); skid = player("skid",true); impact = player("impact",false)
	engine.volume_db = -24; skid.volume_db = -60; engine.play(); skid.play()
	last_velocity = car.velocity; car.reset_to_spawn.connect(reset_audio)
func player(label: String,loop: bool) -> AudioStreamPlayer3D:
	var node := AudioStreamPlayer3D.new(); node.name = label.capitalize(); add_child(node)
	var stream: AudioStreamOggVorbis = load("res://assets/audio/vehicles/"+label+".ogg").duplicate()
	stream.loop = loop; node.stream = stream; node.bus = "Vehicles"
	node.unit_size = 22; node.max_distance = 110; node.max_db = 0
	node.attenuation_filter_cutoff_hz = 8000; node.position.y = 0.7
	return node
func targets(speed: float,throttle: float,lateral: float,handbrake: bool,grounded: bool,delta: float) -> Dictionary:
	shift_remaining = maxf(0,shift_remaining-delta)
	var wheel_rpm: float = absf(speed)/(TAU*0.34)*60.0*3.545
	var measured: float = wheel_rpm*RATIOS[gear]
	if speed<0: gear = 0
	elif shift_remaining<=0:
		if measured>6800 and gear<RATIOS.size()-1: gear += 1; shift_remaining = 0.16
		elif measured<2300 and gear>0: gear -= 1; shift_remaining = 0.12
	var desired: float = maxf(950,wheel_rpm*RATIOS[gear])
	if absf(speed)<2 and throttle>0: desired = maxf(desired,2200)
	rpm = lerpf(rpm,clampf(desired,900,7500),1.0-exp(-delta*12))
	var load_value := clampf(throttle,0,1) if speed>=0 else clampf(-throttle,0,1)
	var tire: float = clampf((absf(lateral)-1.5)/7.0,0,1)
	if handbrake and absf(speed)>7: tire = maxf(tire,0.55)
	if not grounded or absf(speed)<4: tire = 0
	return {"pitch":lerpf(0.65,2.15,(rpm-900)/6600),"engine_db":lerpf(-24,-12,load_value)+(-7 if shift_remaining>0 else 0),"skid":tire}
func gear_label() -> String:
	return "R" if car._speed< -0.5 else str(gear+1)
func _physics_process(delta: float) -> void:
	if not engine: return
	var settings: Dictionary = targets(car._speed,car.audio_throttle,car.velocity.dot(car.global_basis.x),car._handbraking,car.is_on_floor(),delta)
	var quieter := 0.0 if car.is_player else -9.0
	engine.pitch_scale = settings.pitch; engine.volume_db = settings.engine_db+quieter
	skid.volume_db = move_toward(skid.volume_db,lerpf(-60,-13,settings.skid)+quieter,delta*150)
	skid.pitch_scale = clampf(0.85+absf(car._speed)/120.0,0.85,1.4)
	impact_cooldown = maxf(0,impact_cooldown-delta)
	var loss := (car.velocity-last_velocity).length()
	if not car.controls_locked and impact_cooldown<=0 and loss>6 and car.get_slide_collision_count()>0:
		impact.volume_db = clampf(-18+loss*0.35,-18,-5)+quieter; impact.play(); impact_cooldown = 0.5
	last_velocity = car.velocity
func reset_audio() -> void:
	gear = 0; rpm = 950; shift_remaining = 0; impact_cooldown = 0.4; last_velocity = Vector3.ZERO
	if skid: skid.volume_db = -60
func _notification(what: int) -> void:
	if what not in [NOTIFICATION_PAUSED,NOTIFICATION_UNPAUSED]: return
	for node in [engine,skid,impact]:
		if is_instance_valid(node): node.stream_paused = what==NOTIFICATION_PAUSED
	if what==NOTIFICATION_UNPAUSED: impact_cooldown = 0.3
