extends Node3D
## Wide stereo ambience beds are crossfaded by position; race crowds are spatial emitters.
@export_enum("Hartford","Modern City Trial","Champlain Coast") var profile:=0
var listener: Node3D
var beds: Dictionary={}
var gains: Dictionary={}
var targets: Dictionary={}
var crowds: Array[AudioStreamPlayer3D]=[]
var highway_segments: Array=[]
var sample_timer:=0.0
func _ready() -> void:
	if listener==null: listener=get_parent().get("car")
	if listener==null: return
	var audio_listener:=AudioListener3D.new();listener.add_child(audio_listener);audio_listener.make_current()
	if AudioServer.get_bus_index("Ambience")<0:
		AudioServer.add_bus();var index:=AudioServer.bus_count-1;AudioServer.set_bus_name(index,"Ambience")
		AudioServer.set_bus_send(index,"Master")
		var limiter:=AudioEffectLimiter.new();limiter.ceiling_db=-1;limiter.threshold_db=-4
		AudioServer.add_bus_effect(index,limiter)
	StreetProfile.apply_audio()
	for key: String in ["city","highway","park","wind","water"]:
		var player:=AudioStreamPlayer.new();add_child(player);player.bus="Ambience"
		player.stream=loop_stream(key);player.volume_db=-80;player.play(randf()*player.stream.get_length())
		beds[key]=player;gains[key]=0.0
	if profile==0:
		for path: PackedVector3Array in get_parent().get("highway_roads"):
			for i in range(path.size()-1): highway_segments.append([path[i],path[i+1]])
	elif profile==2:
		for road:Node3D in get_parent().get_node("Roads").get_children():
			if not road.get_meta("highway",false):continue
			for i in range(1,road.points.size()):highway_segments.append([road.points[i-1],road.points[i]])
	var source_points:Array=[] if profile==2 else ([Vector3(-60,5,340),Vector3(358,6,648)] if profile==0 else [Vector3(-90,1,0)])
	for point_value in source_points:
		var crowd:=AudioStreamPlayer3D.new();add_child(crowd);crowd.position=point_value
		crowd.stream=loop_stream("crowd");crowd.bus="Ambience";crowd.unit_size=25;crowd.max_distance=150
		crowd.volume_db=-80;crowd.play(randf()*crowd.stream.get_length());crowds.append(crowd)
	targets=weights_at(listener.global_position)
func loop_stream(key: String) -> AudioStreamWAV:
	var stream: AudioStreamWAV=load("res://assets/audio/city_nature/"+key+".wav").duplicate()
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_begin=0;stream.loop_end=roundi(stream.get_length()*stream.mix_rate)
	return stream
func weights_at(point_value: Vector3) -> Dictionary:
	var park:=0.0;var highway:=0.0;var river:=0.0;var urban:=1.0
	if profile==0:
		park=1-smoothstep(0.65,1.3,(Vector2(point_value.x+565,point_value.z-190)/Vector2(310,165)).length())
		river=1-smoothstep(90,240,absf(point_value.x-(730+35*sin(point_value.z/800))))
		urban=maxf(1-smoothstep(0.65,1.4,(Vector2(point_value.x+350,point_value.z)/Vector2(1300,1300)).length()),1-smoothstep(0.65,1.3,(Vector2(point_value.x-1200,point_value.z-400)/Vector2(400,1100)).length()))
		var distance:=INF
		for segment: Array in highway_segments:
			# Three-dimensional proximity distinguishes raised highways from streets below.
			distance=minf(distance,Geometry3D.get_closest_point_to_segment(point_value,segment[0],segment[1]).distance_to(point_value))
		highway=1-smoothstep(10,95,distance)
	elif profile==2:
		urban=1-smoothstep(1100,3300,Vector2(point_value.x,point_value.z).length())
		var distance:=INF
		for segment:Array in highway_segments:
			if absf(segment[0].z-point_value.z)>250:continue
			distance=minf(distance,Geometry3D.get_closest_point_to_segment(point_value,segment[0],segment[1]).distance_to(point_value))
		highway=1-smoothstep(10,110,distance)
		var world:=get_parent();var bounds:Vector4=world.terrain_bounds
		for radius:float in [0,60,140,220]:
			for angle in range(8):
				var p:=point_value+Vector3(cos(angle*TAU/8),0,sin(angle*TAU/8))*radius
				var uv:=(Vector2(p.x,p.z)-Vector2(bounds.x,bounds.y))/Vector2(bounds.z-bounds.x,bounds.w-bounds.y)
				var image:Image=world._water
				if image.get_pixel(clampi(int(uv.x*(image.get_width()-1)),0,image.get_width()-1),clampi(int(uv.y*(image.get_height()-1)),0,image.get_height()-1)).r>.5:river=maxf(river,1-radius/250)
		park=(1-urban)*.7
	else:
		park=1-smoothstep(15,45,Vector2(point_value.x-85,point_value.z-30).length())
		highway=smoothstep(2,7,point_value.y)
	var values: Dictionary={"city":urban*(1-0.85*park)*(1-0.75*highway)*(1-0.5*river),"highway":highway,"park":maxf(park,(1-urban)*0.35)*(1-highway*0.8),"wind":0.12+(1-urban)*0.5,"water":river*(1-highway*0.65)}
	var power:=0.0
	for value: float in values.values(): power+=value*value
	var normalization:=maxf(1,sqrt(power))
	for key in values: values[key]/=normalization
	return values
func _process(delta: float) -> void:
	if not is_instance_valid(listener): return
	sample_timer+=delta
	if sample_timer>=0.1:
		sample_timer=0;targets=weights_at(listener.global_position)
	var blend:=1-exp(-delta*1.6)
	for key in beds:
		gains[key]=lerpf(gains[key],targets.get(key,0),blend)
		beds[key].volume_db=linear_to_db(maxf(0.0001,gains[key]))-3
	var event:=get_parent().get_node_or_null("CityRace")
	var active: bool=is_instance_valid(event) and event.is_active()
	for crowd in crowds:
		crowd.volume_db=lerpf(crowd.volume_db,-8.0 if active else -80.0,blend)
func _exit_tree() -> void:
	for key in beds: beds[key].stop()
	for crowd in crowds: crowd.stop()
