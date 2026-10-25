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
var new_personal_best:=false
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
var result_position: Label
var result_status: Label
var result_award: Label
var result_scroll: ScrollContainer
var result_buttons: HBoxContainer
const STYLE = preload("res://ui/racing_theme.gd")
func _ready() -> void:
	layer=15
	count_sound=AudioStreamPlayer.new();add_child(count_sound);count_sound.volume_db=-13
	screen=Control.new();screen.name="Screen";add_child(screen)
	STYLE.apply(screen)
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
	results_overlay.color=Color(0.006,0.012,0.024,0.91)
	var center:=Control.new();results_overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	results_card=PanelContainer.new();center.add_child(results_card)
	var result_outer:=_contents(results_card,20)
	var result_style:=STYLE.box(Color("101d28"),Color("3c5664"),8,1)
	result_style.border_width_top=4;result_style.border_color=STYLE.GOLD
	results_card.add_theme_stylebox_override("panel",result_style)
	result_scroll=ScrollContainer.new();result_outer.add_child(result_scroll)
	result_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	result_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	result_scroll.custom_minimum_size.y=80
	var result_stack:=VBoxContainer.new();result_scroll.add_child(result_stack)
	result_stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	result_stack.add_theme_constant_override("separation",8)
	var eyebrow:=_label(result_stack,"REVVED   /   RACE RESULTS",15)
	eyebrow.modulate=STYLE.CYAN;eyebrow.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	result_title=_label(result_stack,"CAPITAL RUN",30)
	result_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	var hero:=HBoxContainer.new();result_stack.add_child(hero);hero.add_theme_constant_override("separation",22)
	result_position=_label(hero,"1ST",64);result_position.custom_minimum_size.x=120;result_position.modulate=STYLE.GOLD
	result_position.autowrap_mode=TextServer.AUTOWRAP_OFF
	var summary:=VBoxContainer.new();hero.add_child(summary);summary.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	result_status=_label(summary,"VICTORY",23);result_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	result_time=_label(summary,"",28);result_time.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	result_best=_label(result_stack,"",17)
	result_best.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT;result_best.modulate=Color("a9bcc9")
	result_award=_label(result_stack,"",18);result_award.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	result_award.modulate=STYLE.CYAN
	var heading:=HBoxContainer.new();result_stack.add_child(heading)
	var column:=_label(heading,"CLASSIFICATION",15);column.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.modulate=Color("8ba2b2")
	column=_label(heading,"TIME / STATUS",15);column.custom_minimum_size.x=120;column.modulate=Color("8ba2b2")
	column.autowrap_mode=TextServer.AUTOWRAP_OFF
	standings=VBoxContainer.new();result_stack.add_child(standings)
	standings.add_theme_constant_override("separation",5)
	var buttons:=HBoxContainer.new();result_outer.add_child(buttons);result_buttons=buttons
	buttons.add_theme_constant_override("separation",12)
	retry=Button.new();buttons.add_child(retry);retry.text="RACE AGAIN"
	roam=Button.new();buttons.add_child(roam);roam.text="FREE ROAM"
	for button in [retry,roam]:
		button.clip_text=true;button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		button.custom_minimum_size=Vector2(0,50)
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size",20)
	# Keep primary actions outside the scrolling classification on small screens.
	var caption:=_label(result_outer,"",14);caption.name="ResultsHint";caption.modulate=Color("92a6b5")
	caption.text="Choose your next move"
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
	hint.text="RESET recover  /  PAUSE menu" if touch_enabled() else "R RESET   /   ESC PAUSE   /   Q EXIT"
	navigation.text=instruction
func center_text(value: String) -> void:
	if value!=last_count_text and not value.is_empty():
		count_sound.stream=load("res://assets/audio/interface/go.wav" if value=="GO!" else "res://assets/audio/interface/countdown.wav")
		count_sound.play()
	last_count_text=value
	countdown.text=value;countdown.visible=not value.is_empty()
func show_results(place: int,time: String,best: String,rows: Array,saved: bool) -> void:
	var was_open:=results_overlay.visible
	roam.text=("CONTINUE STORY" if not StreetProfile.pending_story().is_empty() else "STORY MAP") if StreetProfile.launch_mode=="career" and StreetProfile.driver_created else "FREE ROAM"
	if StreetProfile.launch_mode=="series":roam.text="NEXT ROUND" if StreetProfile.series_round<2 else "FINISH SERIES"
	card.hide();navigation.hide();countdown.hide();results_overlay.show()
	result_title.text=event_title.to_upper()
	result_position.text=str(place)+(["ST","ND","RD","TH"][clampi(place-1,0,3)]) if target_time<=0 else ("PASS" if result_message=="TARGET BEATEN" else "RETRY")
	result_position.modulate=Color("ff897b") if target_time>0 and result_message!="TARGET BEATEN" else (STYLE.GOLD if place==1 or result_message=="TARGET BEATEN" else Color("d4e2eb"))
	result_status.text=("VICTORY" if place==1 else "RACE COMPLETE") if target_time<=0 else result_message.replace(" / TRY AGAIN","")
	result_status.modulate=STYLE.GOLD if place==1 and target_time<=0 or result_message=="TARGET BEATEN" else Color("e4edf2")
	result_time.text="FINISH TIME   "+time
	result_best.text=("NEW PERSONAL BEST   " if new_personal_best and saved else ("PERSONAL BEST   " if saved else "SESSION BEST   "))+best+"    /    "+event_kind.to_upper()
	result_award.text="STREET LEGACY / REWARDS\n"+StreetProfile.last_award if StreetProfile.launch_mode=="career" and not StreetProfile.last_award.is_empty() else "PRACTICE SESSION  /  NO CAREER REWARDS"
	if StreetProfile.launch_mode=="series":result_award.text=StreetProfile.series_summary()
	for child in standings.get_children():
		standings.remove_child(child);child.queue_free()
	for index in range(rows.size()):
		var panel:=PanelContainer.new();standings.add_child(panel)
		var row_style:=STYLE.box(Color("293529") if rows[index].player else Color("172734"),STYLE.GOLD if rows[index].player else Color.TRANSPARENT,4,1)
		row_style.content_margin_top=7;row_style.content_margin_bottom=7;panel.add_theme_stylebox_override("panel",row_style)
		var row:=HBoxContainer.new();panel.add_child(row);row.add_theme_constant_override("separation",12)
		var rank:=_label(row,"%02d"%[index+1],21);rank.custom_minimum_size.x=30;rank.modulate=STYLE.GOLD if rows[index].player else Color("8ca5b8")
		var name_label:=_label(row,str(rows[index].name)+( "  /  YOU" if rows[index].player and rows[index].name!="YOU" else ""),19)
		name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
		name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		name_label.autowrap_mode=TextServer.AUTOWRAP_OFF;name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		var timing:=_label(row,rows[index].time,19);timing.custom_minimum_size.x=100
		if rows[index].player: name_label.modulate=STYLE.GOLD
	call_deferred("_layout_results")
	if not was_open:
		result_scroll.scroll_vertical=0;roam.grab_focus()

func _layout_results() -> void:
	if not is_instance_valid(results_card):return
	var desired:=Vector2(minf(820,screen.size.x-28),minf(720,screen.size.y-28))
	results_card.scale=Vector2.ONE;results_card.size=desired
	results_card.position=(screen.size-results_card.size)*.5
	var small:=screen.size.x<600
	result_position.add_theme_font_size_override("font_size",40 if small else 64)
	result_position.custom_minimum_size.x=80 if small else 120
	result_title.add_theme_font_size_override("font_size",24 if small else 30)
	result_time.add_theme_font_size_override("font_size",20 if small else 28)
	for button in [retry,roam]:button.add_theme_font_size_override("font_size",18 if small else 20)

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
	if screen.size.x<600:
		card.offset_left=-screen.size.x+12;card.offset_right=-12;card.offset_top=250;card.size.x=screen.size.x-24
