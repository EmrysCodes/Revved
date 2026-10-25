extends Control
## Per-finger driving input: no keyboard emulation and no shared input between racers.
var car: CharacterBody3D
var enabled:=false
var fingers: Dictionary={}
var buttons: Dictionary={}
var touch_seen:=false
var timer:=0.0
var city: Node
var panel: Control
var old_panel: Array=[]
var map_control: Control
var old_map: Array=[]
const HELD: Array[String]=["left","right","gas","brake","ebrake"]
const LABELS: Dictionary={"left":"◀","right":"▶","gas":"GAS","brake":"BRAKE\n/ REVERSE","ebrake":"E-BRAKE","pause":"PAUSE","reset":"RESET","race":"RACE"}
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel=car.get_node("HUD/Screen/DrivePanel")
	old_panel=snapshot(panel)
	city=car.get_parent()
	while city!=null and not city.has_node("CityHUD"): city=city.get_parent()
	if city!=null:
		map_control=city.get_node("CityHUD/Screen/Map");old_map=snapshot(map_control)
	resized.connect(layout_buttons)
	set_enabled(StreetProfile.touch_mode==1 or (StreetProfile.touch_mode==0 and (OS.has_feature("mobile") or DisplayServer.is_touchscreen_available())))
	layout_buttons()
func snapshot(control: Control) -> Array:
	return [control.anchor_left,control.anchor_top,control.anchor_right,control.anchor_bottom,control.offset_left,control.offset_top,control.offset_right,control.offset_bottom]
func bind_world(world:Node)->void:
	city=world;map_control=world.get_node_or_null("CityHUD/Screen/Map")
	if is_instance_valid(map_control):old_map=snapshot(map_control)
	layout_buttons()
func restore(control: Control,values: Array) -> void:
	control.anchor_left=values[0];control.anchor_top=values[1];control.anchor_right=values[2];control.anchor_bottom=values[3]
	control.offset_left=values[4];control.offset_top=values[5];control.offset_right=values[6];control.offset_bottom=values[7]
func set_enabled(value: bool) -> void:
	enabled=value;release_all();visible=value
	if panel==null: return
	car.get_node("HUD/Screen/DrivePanel/Padding/Stack/Controls").visible=not value
	if value:
		panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		panel.offset_left=24;panel.offset_top=24;panel.offset_right=285;panel.offset_bottom=135
		if is_instance_valid(map_control):
			map_control.anchor_top=0;map_control.anchor_bottom=0;map_control.offset_top=206;map_control.offset_bottom=440
	else:
		restore(panel,old_panel)
		if is_instance_valid(map_control): restore(map_control,old_map)
	layout_buttons()
func layout_buttons() -> void:
	var padding:=12.0 if size.x<1050 else 24.0
	var left:=padding;var right:=size.x-padding;var bottom:=size.y-padding
	if OS.has_feature("mobile"):
		var area:=DisplayServer.get_display_safe_area();var physical:=Vector2(DisplayServer.window_get_size())
		if physical.x>0 and physical.y>0:
			left+=clampf(area.position.x/physical.x*size.x,0,160)
			right-=clampf((physical.x-area.end.x)/physical.x*size.x,0,160)
			bottom-=clampf((physical.y-area.end.y)/physical.y*size.y,0,100)
	var factor:=minf(1,minf(size.x/1050.0,size.y/620.0))
	factor=maxf(.4,factor)
	buttons={"left":Rect2(left,bottom-110*factor,110*factor,110*factor),"right":Rect2(left+122*factor,bottom-110*factor,110*factor,110*factor),"gas":Rect2(right-126*factor,bottom-145*factor,126*factor,145*factor),"brake":Rect2(right-250*factor,bottom-110*factor,110*factor,110*factor),"ebrake":Rect2(right-250*factor,bottom-224*factor,110*factor,100*factor),"pause":Rect2(size.x*.5-95*factor,bottom-52*factor,90*factor,52*factor),"reset":Rect2(size.x*.5+5*factor,bottom-52*factor,90*factor,52*factor),"race":Rect2(size.x*.5-95*factor,bottom-116*factor,190*factor,50*factor)}
	if is_instance_valid(panel):
		car.get_node("HUD/Screen/DrivePanel/Padding/Stack/Readout").add_theme_font_size_override("font_size",30 if size.x<1050 else 40)
		car.get_node("HUD/Screen/DrivePanel/Padding/Stack/Controls").visible=not enabled and size.x>=1050
	if not enabled and is_instance_valid(panel):
		restore(panel,old_panel)
		if is_instance_valid(map_control):restore(map_control,old_map)
		if size.x<1050:
			panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
			panel.offset_left=left;panel.offset_right=left+261;panel.offset_top=-114;panel.offset_bottom=-12
			if is_instance_valid(map_control):
				map_control.offset_left=-132;map_control.offset_right=-12;map_control.anchor_top=0;map_control.anchor_bottom=0;map_control.offset_top=126;map_control.offset_bottom=246
	if enabled and is_instance_valid(panel):
		panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		panel.offset_left=left;panel.offset_top=12 if size.x<1050 else 24
		panel.offset_right=left+261;panel.offset_bottom=108 if size.x<1050 else 135
		if is_instance_valid(map_control):
			restore(map_control,old_map)
			map_control.anchor_top=0;map_control.anchor_bottom=0
			if size.x<1050:
				map_control.anchor_left=0;map_control.anchor_right=0
				map_control.offset_left=left;map_control.offset_right=left+120;map_control.offset_top=126;map_control.offset_bottom=246
			else:map_control.offset_top=206;map_control.offset_bottom=440

	queue_redraw()
func event_node() -> Node:
	return city.get_node_or_null("CityRace") if is_instance_valid(city) else null
func blocked() -> bool:
	if get_tree().paused: return true
	var event:=event_node()
	return is_instance_valid(event) and event.state==event.Phase.RESULTS
func race_available() -> bool:
	var event:=event_node()
	return is_instance_valid(event) and not event.is_active() and Vector2(car.global_position.x-event.entry_position.x,car.global_position.z-event.entry_position.z).length()<55 and car.velocity.length()<5
func _process(delta: float) -> void:
	timer+=delta
	if timer>=0.15:
		timer=0
		var desired: bool=StreetProfile.touch_mode==1 or (StreetProfile.touch_mode==0 and (touch_seen or OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()))
		if desired!=enabled: set_enabled(desired)
	visible=enabled and not blocked()
	if not visible or car.controls_locked: release_all()
	queue_redraw()
func held(key: String) -> bool:
	return enabled and not blocked() and fingers.values().has(key)
func release_all() -> void:
	fingers.clear();queue_redraw()
func hit(point_value: Vector2,held_only:=false) -> String:
	for key: String in buttons:
		if held_only and key not in HELD: continue
		if key=="race" and not race_available(): continue
		if buttons[key].has_point(point_value): return key
	return ""
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and StreetProfile.touch_mode==0 and not enabled:
		touch_seen=true;set_enabled(true)
	if not enabled or blocked(): release_all();return
	if event is InputEventScreenTouch:
		if not event.pressed:
			fingers.erase(event.index);queue_redraw();return
		var key:=hit(event.position)
		if key.is_empty(): return
		if key in HELD:
			if not car.controls_locked: fingers[event.index]=key
		elif key=="pause":
			var menu:=car.get_node_or_null("PauseMenu")
			if is_instance_valid(menu): menu.open_menu()
		elif key=="reset" and not car.controls_locked: car.call("_reset_car")
		elif key=="race": event_node().start_race()
		get_viewport().set_input_as_handled();queue_redraw()
	elif event is InputEventScreenDrag and fingers.has(event.index):
		var key:=hit(event.position,true)
		if key.is_empty() or car.controls_locked: fingers.erase(event.index)
		else: fingers[event.index]=key
		get_viewport().set_input_as_handled();queue_redraw()
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: release_all()
func _draw() -> void:
	if not enabled: return
	for key: String in buttons:
		if key=="race" and not race_available(): continue
		var rect: Rect2=buttons[key]
		var style:=StyleBoxFlat.new();style.bg_color=Color(0.025,0.06,0.09,0.82)
		style.border_color=Color(0.4,0.62,0.7,0.8);style.set_border_width_all(2);style.set_corner_radius_all(16)
		if held(key): style.bg_color=Color(0.25,0.46,0.55,0.95)
		if key=="gas": style.border_color=Color("9ed693")
		if key=="ebrake": style.border_color=Color("edb75e")
		draw_style_box(style,rect)
		var lines: PackedStringArray=LABELS[key].split("\n")
		for i in range(lines.size()):
			var factor:=minf(1,minf(size.x/1050.0,size.y/620.0))
			var font_size:=maxi(12 if key in HELD else 10,roundi((21 if key in HELD else 16)*factor))
			var extent:=ThemeDB.fallback_font.get_string_size(lines[i],HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
			draw_string(ThemeDB.fallback_font,rect.get_center()+Vector2(-extent.x*.5,font_size*.32+(i-(lines.size()-1)*.5)*(font_size+4)),lines[i],HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color.WHITE)
