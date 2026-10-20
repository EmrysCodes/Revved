extends Node3D
## Decode only a few nearby engines; distant traffic uses the city ambience bed.
var slots: Array[AudioStreamPlayer3D] = []
var assigned: Array[CharacterBody3D] = []
var clock := 0.0
func _ready() -> void:
	name = "TrafficAudio"
	for index in range(2 if OS.has_feature("mobile") else 4):
		var player := AudioStreamPlayer3D.new(); player.name = "NearbyEngine%d"%index; add_child(player)
		var stream: AudioStreamOggVorbis = load("res://assets/audio/vehicles/engine.ogg").duplicate(); stream.loop = true
		player.stream = stream; player.bus = "Vehicles"; player.unit_size = 10; player.max_distance = 85
		player.volume_db = -60; player.attenuation_filter_cutoff_hz = 5000; player.play()
		slots.append(player); assigned.append(null)
func _process(delta: float) -> void:
	clock -= delta
	var listener: Node3D = get_parent().get_parent().car
	if clock<=0:
		clock = 0.25
		var nearby: Array[CharacterBody3D] = []
		for agent: CharacterBody3D in get_parent().agents:
			if agent.visible and agent.global_position.distance_squared_to(listener.global_position)<80*80: nearby.append(agent)
		nearby.sort_custom(func(a: Node3D,b: Node3D) -> bool: return a.global_position.distance_squared_to(listener.global_position)<b.global_position.distance_squared_to(listener.global_position))
		if nearby.size()>slots.size(): nearby.resize(slots.size())
		for index in range(slots.size()):
			if not is_instance_valid(assigned[index]) or not nearby.has(assigned[index]): assigned[index] = null
		for agent in nearby:
			if assigned.has(agent): continue
			var index := assigned.find(null)
			if index>=0: assigned[index] = agent; slots[index].volume_db = -50
	for index in range(slots.size()):
		var agent := assigned[index]; var player := slots[index]
		if is_instance_valid(agent):
			player.global_position = agent.global_position+Vector3.UP*0.7
			player.pitch_scale = lerpf(player.pitch_scale,0.7+absf(agent.speed)*0.025,1.0-exp(-delta*5))
			player.volume_db = move_toward(player.volume_db,-25,delta*40)
		else: player.volume_db = move_toward(player.volume_db,-60,delta*70)
