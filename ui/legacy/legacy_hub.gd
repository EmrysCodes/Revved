extends Control
const IDENTITY=preload("res://core/driver_identity.gd")
const MAP_SCRIPT=preload("res://ui/legacy/city_event_map.gd")
var map: Control
var details: Label
var start: Button
var selected_event:=0
func _ready() -> void:
	if not StreetProfile.driver_created:
		get_tree().call_deferred("change_scene_to_file","res://ui/legacy/create_driver.tscn");return
	var bg:=ColorRect.new();add_child(bg);bg.color=Color("0b151e");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin:=MarginContainer.new();add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,20)
	var stack:=VBoxContainer.new();margin.add_child(stack);stack.add_theme_constant_override("separation",12)
	var header:=HBoxContainer.new();stack.add_child(header)
	var portrait:=TextureRect.new();header.add_child(portrait);portrait.texture=IDENTITY.portrait(StreetProfile.driver_presentation,StreetProfile.driver_portrait)
	portrait.custom_minimum_size=Vector2(86,86);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var identity:=Label.new();header.add_child(identity);identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	identity.text="STREET LEGACY / "+StreetProfile.driver_name+"\n"+IDENTITY.BACKGROUNDS[StreetProfile.driver_background].name+"  •  REP %d  /  WINS %d"%[StreetProfile.reputation,StreetProfile.career_wins]
	identity.add_theme_font_size_override("font_size",23);identity.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var body:=HBoxContainer.new();stack.add_child(body);body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	map=Control.new();map.set_script(MAP_SCRIPT);body.add_child(map);map.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	map.custom_minimum_size=Vector2(500,320);map.event_selected.connect(select_event)
	var panel_scroll:=ScrollContainer.new();body.add_child(panel_scroll);panel_scroll.custom_minimum_size.x=310;panel_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var panel:=VBoxContainer.new();panel_scroll.add_child(panel);panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	details=Label.new();panel.add_child(details);details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;details.add_theme_font_size_override("font_size",19)
	start=make_button(panel,"Race event",race_selected)
	make_button(panel,"Garage / Customize car",func():StreetProfile.launch("garage"))
	make_button(panel,"Cruise the city",func():StreetProfile.launch("legacy_roam"))
	make_button(panel,"Driver card",driver_card)
	make_button(panel,"Reset map view",func():map.reset_view())
	make_button(panel,"← Main menu",main_menu)
	select_event(0)
func make_button(parent: Node,value: String,action: Callable) -> Button:
	var item:=Button.new();parent.add_child(item);item.text=value;item.custom_minimum_size.y=45
	item.add_theme_font_size_override("font_size",18);item.pressed.connect(action);return item
func select_event(index: int) -> void:
	selected_event=index
	var event: Dictionary=MAP_SCRIPT.EVENTS[index]
	details.text=event.name.to_upper()+"\n"+event.kind+"\n\n"+event.description
	start.disabled=not event.available;start.text="Race / Capital Run" if event.available else "In development"
func race_selected() -> void:
	if MAP_SCRIPT.EVENTS[selected_event].available: StreetProfile.launch("career")
func driver_card() -> void:
	details.text=StreetProfile.driver_name+"\n"+IDENTITY.BACKGROUNDS[StreetProfile.driver_background].name+"\n\n"+IDENTITY.BACKGROUNDS[StreetProfile.driver_background].story+"\n\n"+IDENTITY.BACKGROUNDS[StreetProfile.driver_background].perk+"\n\nFINISHES  %d\nWINS  %d\nREPUTATION  %d"%[StreetProfile.career_finishes,StreetProfile.career_wins,StreetProfile.reputation]
	start.disabled=true;start.text="Select an event on the map"
func main_menu() -> void:
	StreetProfile.return_to_legacy=false
	get_tree().change_scene_to_file("res://ui/front_end/main_menu.tscn")
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): main_menu();get_viewport().set_input_as_handled()
