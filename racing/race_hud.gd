extends CanvasLayer
signal retry_pressed
signal roam_pressed
var count_sound:AudioStreamPlayer
var last_count_text:=""
var full_readout:=""
var compact_readout:=""
var event_title:="CAPITAL RUN"
var event_kind:="Street sprint"
var driver_count:=4
var target_time:=0.0
var result_message:=""
var screen: Control
var card: PanelContainer
var readout: Label
var hint: Label
var gps:Control
var navigation: Label
var countdown: Label
var results_overlay: ColorRect
var results_card: PanelContainer
var result_title: Label
var result_time: Label
var result_best: Label
var standings: VBoxContainer
var retry: Button
var roam: Button
func _ready() -> void:
	layer=15
	count_sound=AudioStreamPlayer.new();add_child(count_sound);count_sound.volume_db=-13
	screen=Control.new();screen.name="Screen";add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter=Control.MOUSE_FILTER_IGNORE
	card=PanelContainer.new();screen.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	card.offset_left=-306;card.offset_right=-18;card.offset_top=18;card.offset_bottom=162
	var stack:=_contents(card,18)
	readout=_label(stack,"CAPITAL RUN",18)
	hint=_label(stack,"E — Enter race",14)
	hint.modulate=Color(1,0.78,0.3)
	navigation=Label.new();screen.add_child(navigation)
	navigation.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	navigation.offset_left=-260;navigation.offset_right=260;navigation.offset_top=200;navigation.offset_bottom=240
	navigation.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	navigation.add_theme_font_size_override("font_size",22)
	navigation.add_theme_color_override("font_shadow_color",Color.BLACK)
	navigation.add_theme_constant_override("shadow_offset_x",2)
	navigation.add_theme_constant_override("shadow_offset_y",2)
	gps=Control.new();gps.name="RaceGPS";gps.set_script(load("res://ui/race_gps.gd"));screen.add_child(gps)
	countdown=Label.new();screen.add_child(countdown)
	countdown.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	countdown.offset_left=-240;countdown.offset_right=240;countdown.offset_top=-80;countdown.offset_bottom=50
	countdown.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	countdown.add_theme_font_size_override("font_size",66)
	countdown.add_theme_color_override("font_shadow_color",Color.BLACK)
	countdown.add_theme_constant_override("shadow_offset_x",3)
	countdown.add_theme_constant_override("shadow_offset_y",3)
	results_overlay=ColorRect.new();screen.add_child(results_overlay)
	results_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	results_overlay.color=Color(0.01,0.02,0.035,0.86)
	var center:=Control.new();results_overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	results_card=PanelContainer.new();center.add_child(results_card)
	results_card.custom_minimum_size=Vector2(500,0)
	var result_stack:=_contents(results_card,26)
	result_stack.add_theme_constant_override("separation",14)
	result_title=_label(result_stack,"CAPITAL RUN / RESULTS",27)
	result_time=_label(result_stack,"",23)
	result_best=_label(result_stack,"",17)
	result_best.modulate=Color(0.65,0.85,0.96)
	standings=VBoxContainer.new();result_stack.add_child(standings)
	standings.add_theme_constant_override("separation",12)
	var buttons:=HBoxContainer.new();result_stack.add_child(buttons)
	buttons.add_theme_constant_override("separation",12)
	retry=Button.new();buttons.add_child(retry);retry.text="Race again"
	roam=Button.new();buttons.add_child(roam);roam.text="Free roam"
	for button in [retry,roam]:
		button.custom_minimum_size=Vector2(210,48)
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",20)
	retry.pressed.connect(func():retry_pressed.emit())
	roam.pressed.connect(func():
		if StreetProfile.launch_mode=="career" and StreetProfile.driver_created:StreetProfile.main_menu()
		else:roam_pressed.emit())
	screen.resized.connect(_layout_results)
	screen.resized.connect(_layout_race_card)
	card.minimum_size_changed.connect(func():call_deferred("_layout_race_card"))
	_layout_race_card()
	results_card.minimum_size_changed.connect(func():call_deferred("_layout_results"))
	results_overlay.hide();navigation.hide();countdown.hide()
func _contents(panel: PanelContainer,padding: int) -> VBoxContainer:
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.025,0.04,0.06,0.95)
	style.border_color=Color(0.23,0.35,0.43)
	style.set_border_width_all(1);style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel",style)
	var margins:=MarginContainer.new();panel.add_child(margins)
	for side in ["left","top","right","bottom"]:
		margins.add_theme_constant_override("margin_"+side,padding)
	var stack:=VBoxContainer.new();margins.add_child(stack)
	stack.add_theme_constant_override("separation",8)
	return stack
func _label(parent: Node,text: String,size: int) -> Label:
	var label:=Label.new();parent.add_child(label)
	label.text=text;label.add_theme_font_size_override("font_size",size)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return label
func touch_enabled() -> bool:
	var car=get_parent().get("player")
	var controls=car.get_node_or_null("HUD/Screen/TouchControls") if car else null
	return controls!=null and controls.enabled
func bind_navigation(event:Node) -> void:
	gps.bind_race(event)
func entry(length_text: String,nearby: bool,slow: bool) -> void:
	card.visible=nearby;navigation.hide();countdown.hide();results_overlay.hide()
	full_readout=event_title+"\n"+event_kind+" • "+length_text+" • %d rivals"%(driver_count-1)
	compact_readout=event_title+"\n"+length_text+" / "+("TAP RACE" if touch_enabled() else "E TO RACE")
	_layout_race_card()
	hint.text=("Tap RACE below" if touch_enabled() else "E — Enter race") if slow else "Slow down to enter"
func racing(position_text: String,time: String,checkpoint: String,section: String,instruction: String) -> void:
	card.show();navigation.hide();results_overlay.hide()
	full_readout=event_title+"   "+position_text+"\n"+time+"   •   "+checkpoint+"\n"+section
	compact_readout=event_title+"   "+position_text+"\n"+(time+" / %02d:%02d TARGET"%[int(target_time)/60,int(target_time)%60] if target_time>0 else time+"   •   "+checkpoint)
	_layout_race_card()
	hint.text="Tap RESET to recover • PAUSE for menu" if touch_enabled() else "R recover   •   Esc pause   •   Q leave race"
	navigation.text=instruction
func center_text(value: String) -> void:
	if value!=last_count_text and not value.is_empty():
		count_sound.stream=load("res://assets/audio/interface/go.wav" if value=="GO!" else "res://assets/audio/interface/countdown.wav")
		count_sound.play()
	last_count_text=value
	countdown.text=value;countdown.visible=not value.is_empty()
func show_results(place: int,time: String,best: String,rows: Array,saved: bool) -> void:
	var was_open:=results_overlay.visible
	roam.text="EVENT MAP" if StreetProfile.launch_mode=="career" and StreetProfile.driver_created else "Free roam"
	card.hide();navigation.hide();countdown.hide();results_overlay.show()
	result_title.text=event_title+" / FINISHED"
	result_time.text=("%d / %d    •    %s"%[place,driver_count,time]) if target_time<=0 else result_message+"\n"+time
	result_best.text=("Best  " if saved else "Session best  ")+best
	if not StreetProfile.last_award.is_empty(): result_best.text+="\n"+StreetProfile.last_award
	for child in standings.get_children():
		standings.remove_child(child);child.queue_free()
	for index in range(rows.size()):
		var row:=HBoxContainer.new();standings.add_child(row)
		var name_label:=_label(row,"%d   %s"%[index+1,rows[index].name],19)
		name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
		name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		_label(row,rows[index].time,19)
		if rows[index].player: row.modulate=Color(1,0.8,0.3)
	call_deferred("_layout_results")
	if not was_open: retry.grab_focus()

func _layout_results() -> void:
	if not is_instance_valid(results_card):return
	var desired:=results_card.get_combined_minimum_size()
	desired.x=maxf(500,desired.x)
	results_card.size=desired
	var available:=screen.size-Vector2(24,24)
	var factor:=minf(1.0,minf(available.x/desired.x,available.y/desired.y))
	results_card.scale=Vector2.ONE*maxf(.1,factor)
	results_card.position=(screen.size-desired*factor)*.5

func _layout_race_card() -> void:
	if not is_instance_valid(readout):return
	var compact:bool=screen.size.x<1200
	hint.visible=not compact
	var next_text:String=compact_readout if compact else full_readout
	if not next_text.is_empty() and readout.text!=next_text:readout.text=next_text
	var wanted_size:int=16 if compact else 18
	if readout.get_theme_font_size("font_size")!=wanted_size:readout.add_theme_font_size_override("font_size",wanted_size)
	card.offset_top=10 if compact else 18
	card.offset_bottom=108 if compact else 162
	card.size=Vector2(288,maxf(98 if compact else 144,card.get_combined_minimum_size().y))
