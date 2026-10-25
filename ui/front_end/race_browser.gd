extends Control
const C=preload("res://core/career_catalog.gd")
const STYLE=preload("res://ui/racing_theme.gd")
var district:OptionButton
var discipline:OptionButton
var items:VBoxContainer
var map:Control
var detail:Label
var start:Button
var body:Control
var list_scroll:ScrollContainer
var side:VBoxContainer
var selected:=0
var visible_events:Array[int]=[]
var heading:Label
var description:Label
func _ready()->void:
	STYLE.apply(self)
	var bg:=ColorRect.new();add_child(bg);bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);bg.color=STYLE.INK
	var margin:=MarginContainer.new();add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+edge,20)
	var column:=VBoxContainer.new();margin.add_child(column);column.add_theme_constant_override("separation",12)
	var header:=HBoxContainer.new();column.add_child(header)
	var title:=Label.new();header.add_child(title);title.text="SINGLE RACE / OWN YOUR LINE";title.add_theme_font_size_override("font_size",30);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	heading=title
	var back:=Button.new();header.add_child(back);back.text="← MAIN MENU";back.pressed.connect(go_back)
	var note:=Label.new();column.add_child(note);note.text="All 18 courses available. Set a time, learn a route, or test your build. No story locks or career rewards.";note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;note.modulate=Color("a5becd")
	description=note
	var filters:=HFlowContainer.new();column.add_child(filters)
	district=OptionButton.new();filters.add_child(district)
	for value in ["ALL DISTRICTS","PLATTSBURGH","CHAMPLAIN COAST"]:district.add_item(value)
	discipline=OptionButton.new();filters.add_child(discipline)
	for value in ["ALL DISCIPLINES","Street sprint","Circuit","Time attack","Crew duel","District final"]:discipline.add_item(value)
	for choice in [district,discipline]:choice.clip_text=true;choice.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;choice.custom_minimum_size.y=44;choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL;choice.item_selected.connect(func(_i):refresh())
	body=Control.new();column.add_child(body);body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	list_scroll=ScrollContainer.new();body.add_child(list_scroll);list_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	items=VBoxContainer.new();list_scroll.add_child(items);items.size_flags_horizontal=Control.SIZE_EXPAND_FILL;items.add_theme_constant_override("separation",7)
	side=VBoxContainer.new();body.add_child(side)
	map=Control.new();map.set_script(load("res://ui/legacy/city_event_map.gd"));map.practice_mode=true;side.add_child(map);map.custom_minimum_size.y=120;map.size_flags_vertical=Control.SIZE_EXPAND_FILL;map.event_selected.connect(select_event)
	detail=Label.new();side.add_child(detail);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.add_theme_font_size_override("font_size",18)
	start=Button.new();side.add_child(start);start.text="START SINGLE RACE";start.clip_text=true;start.custom_minimum_size.y=48;start.pressed.connect(func():StreetProfile.launch_event(C.EVENTS[selected].id,"single"))
	body.resized.connect(layout_body);layout_body();refresh()
	district.grab_focus()
func refresh()->void:
	for child in items.get_children():items.remove_child(child);child.queue_free()
	visible_events.clear()
	for index in range(C.EVENTS.size()):
		var event:Dictionary=C.EVENTS[index]
		if district.selected>0 and event.chapter!=district.selected-1:continue
		if discipline.selected>0 and event.kind!=discipline.get_item_text(discipline.selected):continue
		visible_events.append(index)
		var id:=index;var button:=Button.new();items.add_child(button);button.text="%02d   %s\n%s"%[index+1,event.name.to_upper(),event.kind.to_upper()];button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.custom_minimum_size.y=68;button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;button.pressed.connect(func():select_event(id))
	if not visible_events.is_empty():select_event(visible_events[0])
func select_event(index:int)->void:
	selected=clampi(index,0,C.EVENTS.size()-1)
	var event:Dictionary=C.EVENTS[selected];var route:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(C.route_path(event.id)))
	map.focus_chapter(event.chapter);map.selected=selected;map.refresh()
	detail.text=event.name.to_upper()+"\n"+event.kind.to_upper()+" / "+GameSettings.format_distance(float(route.length))+"\n%d LAP%s / %d RIVALS"%[event.laps,"S" if event.laps>1 else "",event.rivals]
	if event.rivals==0:detail.text+="\nBEAT %02d:%02d"%[int(route.target_seconds)/60,int(route.target_seconds)%60]
func layout_body()->void:
	heading.add_theme_font_size_override("font_size",22 if size.x<800 else 30)
	description.visible=size.y>=500
	var wide:=body.size.x>=850
	if body.size.x<550:
		list_scroll.position=Vector2.ZERO;list_scroll.size=Vector2(body.size.x,body.size.y*.55)
		side.position=Vector2(0,list_scroll.size.y+10);side.size=Vector2(body.size.x,maxf(100,body.size.y-side.position.y))
		map.hide();detail.add_theme_font_size_override("font_size",16);return
	list_scroll.position=Vector2.ZERO;list_scroll.size=Vector2(body.size.x*.52 if wide else body.size.x*.5,body.size.y)
	side.position=Vector2(list_scroll.size.x+12,0);side.size=Vector2(maxf(120,body.size.x-side.position.x),body.size.y)
	map.visible=body.size.y>=330
	detail.add_theme_font_size_override("font_size",16 if body.size.y<330 else 18)
func go_back()->void:get_tree().change_scene_to_file("res://ui/front_end/main_menu.tscn")
func _unhandled_key_input(event:InputEvent)->void:
	if event.is_action_pressed("ui_cancel"):go_back();get_viewport().set_input_as_handled()
