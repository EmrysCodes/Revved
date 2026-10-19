extends Node
## Local career and launch intent; online modes will use this same profile later.
var path:="user://street_legacy.cfg"
var launch_mode:="free"
var career_finishes:=0
var career_wins:=0
var reputation:=0
var last_award:=""
var fullscreen:=false
var vsync:=true
var master_volume:=0.8
var ambience_volume:=0.7
var touch_mode:=0
var antialiasing:=2
const IDENTITY=preload("res://core/driver_identity.gd")
var driver_created:=false
var driver_name:="Alex Mercer"
var driver_presentation:=0
var driver_portrait:=0
var driver_background:=0
var return_to_legacy:=false
func _ready() -> void:
	var file:=ConfigFile.new()
	if file.load(path)==OK:
		career_finishes=maxi(0,int(file.get_value("career","finishes",0)))
		career_wins=maxi(0,int(file.get_value("career","wins",0)))
		reputation=maxi(0,int(file.get_value("career","reputation",0)))
		fullscreen=bool(file.get_value("display","fullscreen",false))
		vsync=bool(file.get_value("display","vsync",true))
		master_volume=clampf(float(file.get_value("audio","master",0.8)),0,1)
		ambience_volume=clampf(float(file.get_value("audio","ambience",0.7)),0,1)
		touch_mode=clampi(int(file.get_value("input","touch_mode",0)),0,2)
		antialiasing=clampi(int(file.get_value("display","antialiasing",2)),0,3)
		driver_created=bool(file.get_value("driver","created",false))
		driver_name=str(file.get_value("driver","name","Alex Mercer")).strip_edges().left(24)
		driver_presentation=clampi(int(file.get_value("driver","presentation",0)),0,1)
		driver_portrait=clampi(int(file.get_value("driver","portrait",0)),0,9)
		driver_background=clampi(int(file.get_value("driver","background",0)),0,IDENTITY.BACKGROUNDS.size()-1)
		if driver_name.is_empty(): driver_created=false
	apply_display()
func save() -> Error:
	var file:=ConfigFile.new()
	file.set_value("career","finishes",career_finishes)
	file.set_value("career","wins",career_wins)
	file.set_value("career","reputation",reputation)
	file.set_value("display","fullscreen",fullscreen)
	file.set_value("display","vsync",vsync)
	file.set_value("display","antialiasing",antialiasing)
	file.set_value("audio","master",master_volume)
	file.set_value("audio","ambience",ambience_volume)
	file.set_value("input","touch_mode",touch_mode)
	file.set_value("driver","created",driver_created)
	file.set_value("driver","name",driver_name)
	file.set_value("driver","presentation",driver_presentation)
	file.set_value("driver","portrait",driver_portrait)
	file.set_value("driver","background",driver_background)
	return file.save(path)
func create_driver(value: String,presentation: int,portrait: int,background: int) -> Error:
	if driver_created: return ERR_ALREADY_EXISTS
	value=value.strip_edges()
	if value.is_empty() or value.length()>24 or presentation not in [0,1] or portrait not in range(10) or background not in range(IDENTITY.BACKGROUNDS.size()): return ERR_INVALID_PARAMETER
	var previous: Array=[driver_created,driver_name,driver_presentation,driver_portrait,driver_background]
	driver_created=true;driver_name=value;driver_presentation=presentation;driver_portrait=portrait;driver_background=background
	var error:=save()
	if error!=OK:
		driver_created=previous[0];driver_name=previous[1];driver_presentation=previous[2];driver_portrait=previous[3];driver_background=previous[4]
	return error
func apply_display() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	get_viewport().msaa_3d=antialiasing as Viewport.MSAA
	apply_audio()
func apply_audio() -> void:
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(master_volume,0.0001)))
	AudioServer.set_bus_mute(0,master_volume<=0)
	var ambience_bus:=AudioServer.get_bus_index("Ambience")
	if ambience_bus>=0:
		AudioServer.set_bus_volume_db(ambience_bus,linear_to_db(maxf(ambience_volume,0.0001)))
		AudioServer.set_bus_mute(ambience_bus,ambience_volume<=0)
func record_finish(place: int,recoveries:=0) -> void:
	if launch_mode!="career": return
	career_finishes+=1
	if place==1: career_wins+=1
	var base: int=[250,150,100,50][clampi(place-1,0,3)]
	var earned:=roundi(base*IDENTITY.multiplier(driver_background,place,recoveries))
	reputation+=earned
	last_award="+%d reputation • Street Legacy"%earned
	if driver_background!=0: last_award+="\n"+IDENTITY.BACKGROUNDS[driver_background].name
	if save()!=OK: last_award+=" • save failed; session only"
func launch(mode: String) -> void:
	launch_mode=mode;last_award=""
	get_tree().change_scene_to_file("res://scenes/hartford_district.tscn")
func main_menu() -> void:
	return_to_legacy=launch_mode in ["career","legacy_roam","garage"] and driver_created
	get_tree().paused=false
	get_tree().change_scene_to_file("res://ui/front_end/main_menu.tscn")
