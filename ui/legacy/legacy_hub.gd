extends Control
const IDENTITY=preload("res://core/driver_identity.gd")
const CAMPAIGN=preload("res://core/career_catalog.gd")
const MAP_SCRIPT=preload("res://ui/legacy/city_event_map.gd")
const STYLE=preload("res://ui/racing_theme.gd")
var map:Control
var details:Label
var start:Button
var selected_event:=0
var body:Control
var panel:ScrollContainer
var event_choice:OptionButton
var mission_title:Label
var mission_meta:Label
var chapter_label:Label
var progress_label:Label
var continue_button:Button
var story_title:Label
func _ready() -> void:
	STYLE.apply(self)
	if not StreetProfile.driver_created:
		get_tree().call_deferred("change_scene_to_file","res://ui/legacy/create_driver.tscn");return
	var pending:String=StreetProfile.pending_story()
	if not pending.is_empty():
		StreetProfile.call_deferred("play_story",pending);return
	var bg:=ColorRect.new();add_child(bg);bg.color=STYLE.INK;bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin:=MarginContainer.new();add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,20)
	var stack:=VBoxContainer.new();margin.add_child(stack);stack.add_theme_constant_override("separation",10)
	var header:=HBoxContainer.new();stack.add_child(header);header.add_theme_constant_override("separation",15)
	var portrait:=TextureRect.new();header.add_child(portrait);portrait.texture=IDENTITY.portrait(StreetProfile.driver_presentation,StreetProfile.driver_portrait)
	portrait.custom_minimum_size=Vector2(70,70);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var identity:=Label.new();header.add_child(identity);identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	identity.text="STREET LEGACY / "+StreetProfile.driver_name.to_upper()+"\n"+IDENTITY.BACKGROUNDS[StreetProfile.driver_background].name+"  •  REP %d  /  %s CR"%[StreetProfile.reputation,str(StreetProfile.credits)]
	identity.add_theme_font_size_override("font_size",21);identity.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	make_button(header,"GARAGE",func():StreetProfile.launch("garage"))
	var narrative:=PanelContainer.new();stack.add_child(narrative)
	narrative.add_theme_stylebox_override("panel",STYLE.box(Color("192b35"),STYLE.GOLD,6,1))
	var narrative_row:=HBoxContainer.new();narrative.add_child(narrative_row)
	story_title=Label.new();narrative_row.add_child(story_title);story_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;story_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;story_title.add_theme_font_size_override("font_size",19)
	var next_id:String=CAMPAIGN.next_event(StreetProfile.event_results)
	story_title.text="LAST LIGHT / %02d OF 18 WINS\n"%CAMPAIGN.wins(StreetProfile.event_results)+(CAMPAIGN.event(next_id).name.to_upper() if not next_id.is_empty() else "STORY COMPLETE / THE DOOR STAYS OPEN")
	continue_button=make_button(narrative_row,"CONTINUE STORY" if not next_id.is_empty() else "CRUISE",continue_story)
	continue_button.grab_focus()
	var tabs:=HBoxContainer.new();stack.add_child(tabs)
	for chapter in range(2):
		var index:=chapter
		var tab:=make_button(tabs,CAMPAIGN.CHAPTERS[chapter].district.to_upper(),func():show_chapter(index))
		tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tab.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	body=Control.new();stack.add_child(body);body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	map=Control.new();map.set_script(MAP_SCRIPT);body.add_child(map);map.event_selected.connect(select_event)
	panel=ScrollContainer.new();body.add_child(panel);panel.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var column:=VBoxContainer.new();panel.add_child(column);column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",12)
	chapter_label=Label.new();column.add_child(chapter_label);chapter_label.add_theme_font_size_override("font_size",15)
	event_choice=OptionButton.new();column.add_child(event_choice);event_choice.custom_minimum_size.y=45
	for event in CAMPAIGN.EVENTS:event_choice.add_item(event.name)
	event_choice.item_selected.connect(select_event)
	mission_title=Label.new();column.add_child(mission_title);mission_title.add_theme_font_size_override("font_size",28);mission_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	mission_meta=Label.new();column.add_child(mission_meta);mission_meta.modulate=STYLE.GOLD;mission_meta.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	details=Label.new();column.add_child(details);details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;details.add_theme_font_size_override("font_size",17)
	start=make_button(column,"RACE EVENT",race_selected)
	make_button(column,"PRACTICE SELECTED EVENT",func():StreetProfile.launch_event(CAMPAIGN.EVENTS[selected_event].id,"single"))
	make_button(column,"GARAGE / BUILD YOUR CAR",func():StreetProfile.select_event(CAMPAIGN.EVENTS[selected_event].id);StreetProfile.launch("garage"))
	make_button(column,"CRUISE / EXPLORE THE CITY",func():StreetProfile.select_event(CAMPAIGN.EVENTS[selected_event].id);StreetProfile.launch("legacy_roam"))
	make_button(column,"DRIVER CARD",driver_card)
	make_button(column,"STORY JOURNAL / SCENE REPLAY",story_archive)
	make_button(column,"RESET MAP VIEW",func():map.reset_view())
	make_button(column,"← MAIN MENU",main_menu)
	progress_label=Label.new();stack.add_child(progress_label);progress_label.add_theme_font_size_override("font_size",13);progress_label.modulate=Color("99b3c1");progress_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.resized.connect(layout_body);layout_body()
	var index:=0
	var initial_id:String=next_id if not next_id.is_empty() else StreetProfile.selected_event
	for i in range(CAMPAIGN.EVENTS.size()):
		if CAMPAIGN.EVENTS[i].id==initial_id:index=i
	map.focus_chapter(CAMPAIGN.EVENTS[index].chapter);select_event(index)
func layout_body() -> void:
	if body.size.x>=850:
		map.position=Vector2.ZERO;map.size=Vector2(body.size.x-330,body.size.y)
		panel.position=Vector2(body.size.x-314,0);panel.size=Vector2(314,body.size.y)
	else:
		map.position=Vector2.ZERO;map.size=Vector2(body.size.x,body.size.y*.47)
		panel.position=Vector2(0,body.size.y*.47+8);panel.size=Vector2(body.size.x,maxf(40,body.size.y*.53-8))
func make_button(parent:Node,value:String,action:Callable) -> Button:
	var item:=Button.new();parent.add_child(item);item.text=value;item.custom_minimum_size.y=46;item.pressed.connect(action);return item
func show_chapter(chapter:int) -> void:
	map.focus_chapter(chapter)
	select_event(0 if chapter==0 else 9)
func select_event(index:int) -> void:
	selected_event=clampi(index,0,CAMPAIGN.EVENTS.size()-1)
	var event:Dictionary=CAMPAIGN.EVENTS[selected_event]
	StreetProfile.select_event(event.id)
	var chapter:Dictionary=CAMPAIGN.CHAPTERS[event.chapter]
	chapter_label.text=chapter.name+" / "+chapter.crew;chapter_label.modulate=chapter.color
	mission_title.text=event.name.to_upper();event_choice.select(selected_event)
	var filename:String=CAMPAIGN.route_path(event.id)
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(filename)) if FileAccess.file_exists(filename) else {}
	mission_meta.text=event.kind.to_upper()+"  /  "+GameSettings.format_distance(float(data.get("length",0)))+"\n%d LAPS  •  %d RIVALS  •  %d CR FIRST WIN"%[event.laps,event.rivals,event.cash]
	var reason:String=CAMPAIGN.unlock_reason(event.id,StreetProfile.event_results)
	var result:Dictionary=StreetProfile.event_results.get(event.id,{})
	var beat:Dictionary=StreetProfile.STORY.scene(event.id+"_before")
	details.text="EPISODE %02d / %s\n\n"%[selected_event+1,beat.get("title",event.name)]+event.brief+"\n\n"+("EVENT WON / Replay for a smaller reward." if CAMPAIGN.won(StreetProfile.event_results,event.id) else ("NEXT IN THE STORY / Win to advance." if reason.is_empty() else "LOCKED / "+reason))
	if result.get("best",0)>0 and int(result.get("route_version",1))==int(data.get("version",1)):details.text+="\nPersonal best: %02d:%05.2f"%[int(result.best)/60,fmod(float(result.best),60)]
	if event.rivals==0 and data.has("target_seconds"):details.text+="\nTarget: %02d:%02d"%[int(data.target_seconds)/60,int(data.target_seconds)%60]
	start.disabled=not reason.is_empty() or data.is_empty();start.text=("REPLAY RACE" if CAMPAIGN.won(StreetProfile.event_results,event.id) else "START STORY EVENT") if not start.disabled else "EVENT LOCKED"
	map.selected=selected_event;map.refresh()
	var wins:int=CAMPAIGN.chapter_wins(StreetProfile.event_results,event.chapter)
	progress_label.text="%s  /  %d OF 9 EVENTS WON  •  LINEAR STORY / PRACTICE ANY EVENT WITHOUT REWARDS"%[chapter.name,wins]
	if CAMPAIGN.complete(StreetProfile.event_results):progress_label.text="LAST LIGHT COMPLETE / REPLAY THE STORY JOURNAL, REFINE YOUR BUILD & EXPLORE"
func continue_story()->void:
	var id:String=CAMPAIGN.next_event(StreetProfile.event_results)
	if id.is_empty():StreetProfile.launch("legacy_roam")
	else:StreetProfile.launch_event(id,"career")
func story_archive()->void:
	var dialog:=AcceptDialog.new();add_child(dialog);dialog.title="LAST LIGHT / STORY JOURNAL";dialog.ok_button_text="BACK TO MAP"
	var scroll:=ScrollContainer.new();dialog.add_child(scroll);scroll.custom_minimum_size=Vector2(minf(600,size.x-70),minf(450,size.y-100));scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var entries:=VBoxContainer.new();scroll.add_child(entries);entries.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var introduction:=Label.new();entries.add_child(introduction);introduction.text="An independent garage. Two estranged crews. One week to keep the door open.\nReplay watched scenes without changing progress or rewards.\nVoices are an offline synthetic prototype performance.";introduction.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	for key:String in StreetProfile.STORY.data().scenes:
		if not StreetProfile.story_seen.get(key,false):continue
		var scene_key:=key
		make_button(entries,StreetProfile.STORY.scene(key).title,func():dialog.queue_free();StreetProfile.play_story(scene_key,"hub",true))
	dialog.confirmed.connect(dialog.queue_free);dialog.canceled.connect(dialog.queue_free);dialog.popup_centered()
func race_selected() -> void:
	if not start.disabled:StreetProfile.launch_event(CAMPAIGN.EVENTS[selected_event].id,"career")
func driver_card() -> void:
	details.text=StreetProfile.driver_name+"\n"+IDENTITY.BACKGROUNDS[StreetProfile.driver_background].story+"\n\n"+IDENTITY.BACKGROUNDS[StreetProfile.driver_background].perk+"\n\nFINISHES %d  /  WINS %d\nREPUTATION %d  /  BALANCE %d CR"%[StreetProfile.career_finishes,StreetProfile.career_wins,StreetProfile.reputation,StreetProfile.credits]
	start.disabled=true;start.text="SELECT AN EVENT TO RACE"
func main_menu() -> void:
	StreetProfile.return_to_legacy=false;get_tree().change_scene_to_file("res://ui/front_end/main_menu.tscn")
func _unhandled_key_input(event:InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):main_menu();get_viewport().set_input_as_handled()
