extends AudioStreamPlayer
## Persistent menu score; fades away during loading/driving and ducks under speech.
var dialogue_active:=false
var level:=0.0
func _ready()->void:
	stream=load("res://assets/audio/interface/last_light_menu.wav")
	if stream is AudioStreamWAV:
		stream.loop_begin=0;stream.loop_end=roundi(stream.get_length()*stream.mix_rate);stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	volume_db=-60;play()
func _process(delta:float)->void:
	var scene:=get_tree().current_scene
	var in_menu:bool=scene!=null and scene.name in ["MainMenu","LegacyHub","CreateDriver","StoryScene","RaceBrowser"]
	var target:float=StreetProfile.music_volume*(.17 if dialogue_active else .32) if in_menu else 0.0
	level=lerpf(level,target,1-exp(-delta*3));volume_db=linear_to_db(maxf(.0001,level))
