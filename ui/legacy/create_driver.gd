extends Control
const IDENTITY=preload("res://core/driver_identity.gd")
var driver_name:="Alex Mercer"
var presentation:=0
var portrait_index:=0
var background_index:=0
var stage:=0
var stack: VBoxContainer
var error_label: Label
var name_input: LineEdit
var portrait_set: OptionButton
func _ready() -> void:
	var bg:=ColorRect.new();add_child(bg);bg.color=Color("101b25");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin:=MarginContainer.new();add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	var outer:=VBoxContainer.new();margin.add_child(outer)
	var title:=Label.new();outer.add_child(title);title.text="STREET LEGACY / CREATE YOUR DRIVER";title.add_theme_font_size_override("font_size",30)
	var scroll:=ScrollContainer.new();outer.add_child(scroll);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	stack=VBoxContainer.new();scroll.add_child(stack);stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stack.add_theme_constant_override("separation",12)
	error_label=Label.new();outer.add_child(error_label);error_label.modulate=Color("ffbe71");error_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	identity_page()
func clear(value: int) -> void:
	stage=value;error_label.text=""
	for child in stack.get_children(): stack.remove_child(child);child.queue_free()
func text(value: String,size_value:=20) -> Label:
	var label:=Label.new();stack.add_child(label);label.text=value;label.add_theme_font_size_override("font_size",size_value)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return label
func button(value: String,action: Callable) -> Button:
	var item:=Button.new();stack.add_child(item);item.text=value;item.custom_minimum_size.y=44
	item.add_theme_font_size_override("font_size",20);item.pressed.connect(action);return item
func identity_page() -> void:
	clear(0);text("01 / YOUR NAME",28)
	text("Pick a driver name and portrait set. Appearance has no effect on rewards or car handling.",18)
	name_input=LineEdit.new();stack.add_child(name_input);name_input.max_length=24;name_input.text=driver_name
	name_input.placeholder_text="Driver name";name_input.custom_minimum_size.y=48;name_input.add_theme_font_size_override("font_size",24)
	name_input.text_submitted.connect(func(_value):accept_identity())
	portrait_set=OptionButton.new();stack.add_child(portrait_set);portrait_set.add_item("Man — 10 portraits");portrait_set.add_item("Woman — 10 portraits")
	portrait_set.select(presentation);portrait_set.custom_minimum_size.y=44
	button("Next / Choose portrait",accept_identity)
	button("← Main menu",func():get_tree().change_scene_to_file("res://ui/front_end/main_menu.tscn"))
	name_input.grab_focus()
func accept_identity() -> void:
	var value:=name_input.text.strip_edges()
	if value.is_empty(): error_label.text="Enter a driver name before continuing.";return
	driver_name=value
	if presentation!=portrait_set.selected: portrait_index=0
	presentation=portrait_set.selected;portrait_page()
func portrait_page() -> void:
	clear(1);text("02 / CHOOSE YOUR PORTRAIT",28)
	text(driver_name+" • "+("Men" if presentation==0 else "Women")+" • Select one of ten portraits",18)
	var grid:=GridContainer.new();stack.add_child(grid);grid.columns=5
	grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12)
	for index in range(10):
		var item:=Button.new();grid.add_child(item);item.toggle_mode=true;item.button_pressed=index==portrait_index
		item.size_flags_horizontal=Control.SIZE_EXPAND_FILL;item.custom_minimum_size=Vector2(150,174)
		var margins:=MarginContainer.new();item.add_child(margins);margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side in ["left","right","top","bottom"]: margins.add_theme_constant_override("margin_"+side,5)
		margins.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var portrait:=TextureRect.new();margins.add_child(portrait);portrait.texture=IDENTITY.portrait(presentation,index)
		portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
		item.tooltip_text="Portrait %02d"%(index+1)
		item.pressed.connect(func():portrait_index=index;portrait_page())
		if index==portrait_index: item.grab_focus()
	button("Next / Choose your background",background_page)
	button("← Name & portrait set",identity_page)
func background_page() -> void:
	clear(2);text("03 / WHERE YOU CAME FROM",28)
	text("Each specialty trades a 10% reputation bonus for a 10% shortfall elsewhere. Independent stays neutral. Car physics are identical. Your background is fixed when you confirm.",18)
	for index in range(IDENTITY.BACKGROUNDS.size()):
		var entry: Dictionary=IDENTITY.BACKGROUNDS[index]
		var item:=button(("✓  " if index==background_index else "    ")+entry.name,func():background_index=index;background_page())
		item.alignment=HORIZONTAL_ALIGNMENT_LEFT
		text(entry.story,16);text(entry.perk,17).modulate=Color("e6c17d")
	button("Next / Review driver",review_page);button("← Portraits",portrait_page)
func review_page() -> void:
	clear(3);text("04 / YOUR LEGACY STARTS HERE",28)
	var portrait:=TextureRect.new();stack.add_child(portrait);portrait.texture=IDENTITY.portrait(presentation,portrait_index)
	portrait.custom_minimum_size=Vector2(220,220);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	text(driver_name,30);text(IDENTITY.BACKGROUNDS[background_index].name,23);text(IDENTITY.BACKGROUNDS[background_index].perk,18)
	text("This creates your driver without resetting existing reputation, finishes or garage choices.",17)
	button("Start Street Legacy / Open city map",confirm_driver)
	button("← Background",background_page)
func confirm_driver() -> void:
	var result:=StreetProfile.create_driver(driver_name,presentation,portrait_index,background_index)
	if result!=OK: error_label.text="Could not save your driver. Please try again. Your existing career is unchanged.";return
	get_tree().change_scene_to_file("res://ui/legacy/legacy_hub.tscn")
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		match stage:
			0: get_tree().change_scene_to_file("res://ui/front_end/main_menu.tscn")
			1: identity_page()
			2: portrait_page()
			3: background_page()
		get_viewport().set_input_as_handled()
