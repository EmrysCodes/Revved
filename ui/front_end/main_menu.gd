extends Control
const STYLE=preload("res://ui/racing_theme.gd")
const CAREER=preload("res://core/career_catalog.gd")
var content: VBoxContainer
var feedback: Label
var scroll: ScrollContainer
var preview_car: Node3D
func _ready() -> void:
	STYLE.apply(self)
	var background:=ColorRect.new();add_child(background)
	background.color=Color("0b151f");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	# Graphic street grid, rendered without loading the entire city behind the menu.
	var grid:=Control.new();add_child(grid);grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid.draw.connect(func():
		for i in range(16):
			var x:=float(i)*140-300
			grid.draw_line(Vector2(x,0),Vector2(x+500,grid.size.y),Color(0.12,0.22,0.27),2)
		for i in range(10): grid.draw_line(Vector2(0,i*100),Vector2(grid.size.x,i*100),Color(0.12,0.22,0.27),2))
	grid.resized.connect(grid.queue_redraw);grid.mouse_filter=Control.MOUSE_FILTER_IGNORE
	showroom()
	var margin:=MarginContainer.new();add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,30)
	margin.add_theme_constant_override("margin_right",int(size.x*0.48))
	resized.connect(func():margin.add_theme_constant_override("margin_right",int(size.x*0.48)))
	var layout:=VBoxContainer.new();margin.add_child(layout)
	var logo:=Label.new();layout.add_child(logo);logo.text="REVVED";logo.add_theme_font_size_override("font_size",72)
	logo.add_theme_color_override("font_color",STYLE.GOLD)
	var tagline:=Label.new();layout.add_child(tagline);tagline.text="YOUR CITY.  YOUR CAR.  YOUR LEGACY.";tagline.add_theme_font_size_override("font_size",15)
	scroll=ScrollContainer.new();layout.add_child(scroll);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	content=VBoxContainer.new();scroll.add_child(content);content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",8)
	feedback=Label.new();layout.add_child(feedback);feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	feedback.text="PLAYTEST / TWO DISTRICTS / LOCAL SAVES"
	home()
	if StreetProfile.return_to_legacy:
		StreetProfile.return_to_legacy=false;call_deferred("career")
func clear(title: String,description: String) -> void:
	for child in content.get_children(): content.remove_child(child);child.queue_free()
	label(title,30);label(description,18);scroll.scroll_vertical=0
func label(text: String,font:=20) -> Label:
	var item:=Label.new();content.add_child(item);item.text=text;item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size",font);return item
func button(text: String,action: Callable,enabled:=true) -> Button:
	var item:=Button.new();content.add_child(item);item.text=text;item.alignment=HORIZONTAL_ALIGNMENT_LEFT
	item.custom_minimum_size=Vector2(0,46);item.add_theme_font_size_override("font_size",20)
	item.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	item.disabled=not enabled;item.pressed.connect(action)
	if content.get_child_count()==3: item.grab_focus()
	return item
func back() -> void: button("← Main menu",home)
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		home();get_viewport().set_input_as_handled()
func home() -> void:
	clear("OWN THE STREETS","Two districts. Eighteen events. One name to build.")
	button("01   STREET LEGACY    /    Career",career)
	button("02   SINGLE RACE    /    Practice any event",single_race)
	button("03   FREE ROAM    /    Explore the city",func():StreetProfile.launch("free"))
	button("04   ONLINE    /    In development",online)
	button("05   SETTINGS",settings)
	button("06   CREDITS & CONTROLS",credits)
	button("QUIT GAME",func():get_tree().quit())
func single_race() -> void:
	clear("PICK YOUR RACE","Practice any event. Career locks and rewards do not apply here.")
	for chapter in range(2):
		label(CAREER.CHAPTERS[chapter].district.to_upper(),20).modulate=CAREER.CHAPTERS[chapter].color
		for event in CAREER.EVENTS:
			if event.chapter!=chapter:continue
			var id:String=event.id
			button(event.name.to_upper()+" / "+event.kind,func():StreetProfile.launch_event(id,"single"),FileAccess.file_exists(CAREER.route_path(id)))
	back()
func career() -> void:
	get_tree().change_scene_to_file("res://ui/legacy/legacy_hub.tscn" if StreetProfile.driver_created else "res://ui/legacy/create_driver.tscn")
func online() -> void:
	clear("ONLINE","Planned multiplayer hub. Network sessions and account linking are not implemented in this build.")
	button("Single Race    /    Matchmaking & private lobbies",func():online_detail("Single Race","Race friends or find a public street event. Planned: host/join, invites, ready-up and vehicle rules."))
	button("Tournament    /    Multi-event championships",func():online_detail("Tournament","Planned: event series, points tables, lobby rules and championship results."))
	button("Street Legacy Online    /    Shared career",func():online_detail("Street Legacy Online","Planned: the same driver and garage as offline career, shared challenges, crews and validated progression. Offline saves are local today."))
	button("Free Roam    /    Cruise with friends",func():online_detail("Online Free Roam","Planned: shared city sessions, meetups and challenge invitations."))
	back()
func online_detail(title: String,description: String) -> void:
	clear(title.to_upper(),description)
	button("Host session    /    Unavailable",func():pass,false)
	button("Find session    /    Unavailable",func():pass,false)
	button("← Online modes",online);back()
func settings() -> void:
	clear("SETTINGS","Preferences save locally. Units also remain available from the pause menu.")
	label("Distance & speed",21)
	var units:=OptionButton.new();content.add_child(units)
	units.add_item("US — MPH / miles / feet");units.add_item("Metric — km/h / kilometres / metres")
	units.select(GameSettings.unit_system);units.custom_minimum_size.y=44
	units.item_selected.connect(func(value):feedback.text="Units saved." if GameSettings.set_unit_system(value)==OK else "Could not save units; applied for this session.")
	var full:=CheckButton.new();content.add_child(full);full.text="Fullscreen";full.button_pressed=StreetProfile.fullscreen
	full.toggled.connect(func(value):StreetProfile.fullscreen=value;save_display())
	var sync:=CheckButton.new();content.add_child(sync);sync.text="VSync";sync.button_pressed=StreetProfile.vsync
	sync.toggled.connect(func(value):StreetProfile.vsync=value;save_display())
	label("Anti-aliasing",21)
	var aa:=OptionButton.new();content.add_child(aa)
	for option in ["Off","2× MSAA","4× MSAA","8× MSAA"]: aa.add_item(option)
	aa.select(StreetProfile.antialiasing);aa.custom_minimum_size.y=42
	aa.item_selected.connect(func(value):StreetProfile.antialiasing=value;save_display())
	label("Master volume",21)
	var volume:=HSlider.new();content.add_child(volume);volume.min_value=0;volume.max_value=100;volume.step=1
	volume.value=StreetProfile.master_volume*100;volume.custom_minimum_size.y=36
	volume.value_changed.connect(func(value):StreetProfile.master_volume=value/100.0;save_display())
	label("City ambience",21)
	var ambience:=HSlider.new();content.add_child(ambience);ambience.min_value=0;ambience.max_value=100;ambience.step=1
	ambience.value=StreetProfile.ambience_volume*100;ambience.custom_minimum_size.y=36
	ambience.value_changed.connect(func(value):StreetProfile.ambience_volume=value/100.0;save_display())
	label("Touch driving controls",21)
	var touch:=OptionButton.new();content.add_child(touch)
	for option in ["Auto / phones and tablets","Always on / desktop testing","Off"]: touch.add_item(option)
	touch.select(StreetProfile.touch_mode);touch.custom_minimum_size.y=42
	touch.item_selected.connect(func(value):StreetProfile.touch_mode=value;feedback.text="Touch preference saved." if StreetProfile.save()==OK else "Touch preference applied; save failed.")
	label("Music and vehicle engine audio are not included yet.",17)
	back()
func save_display() -> void:
	StreetProfile.apply_display();feedback.text="Display settings saved." if StreetProfile.save()==OK else "Display applied; could not save."
func credits() -> void:
	clear("CREDITS & CONTROLS","REVVED • An arcade street racing game in development.")
	label("W / arrows: accelerate • S: brake / reverse\nA / D: steer • Shift: brake • Space: handbrake\nE: enter nearby race • R: recover / reset\nEsc: pause • Q: leave active race",21)
	label("City architecture: Quaternius Downtown City MegaKit Standard (CC0). S64 Compact vehicle: IceMaan (CC0). Hartford-inspired layout is an authored approximation. Full asset license files are included in the project.",17)
	label("Traffic vehicles: Kenney Car Kit (CC0). Animated pedestrians: Quaternius Ultimate Modular Men (CC0). Arcade cars: Store InvoGames (Fab Standard License). Sources and license files are included with the project.",16)
	label("Ambience: Free City & Nature Sounds — Gregor Quendel / Cinematic Sound Design, CC BY 4.0. Excerpts looped, gain-adjusted; race crowd downmixed to mono.\nSource: fab.com/listings/15f8225f-057b-4536-af62-7a43ec328632\nLicense: creativecommons.org/licenses/by/4.0/",16)
	back()
func _process(delta: float) -> void:
	if is_instance_valid(preview_car): preview_car.rotation.y+=delta*0.12
func showroom() -> void:
	var container:=SubViewportContainer.new();add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.anchor_left=0.54;container.stretch=true;container.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var view:=SubViewport.new();container.add_child(view)
	view.own_world_3d=true;view.gui_disable_input=true;view.msaa_3d=Viewport.MSAA_4X
	var world:=Node3D.new();view.add_child(world)
	var environment:=WorldEnvironment.new();world.add_child(environment)
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("0c1722")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("b6c9e3")
	environment.environment.ambient_light_energy=0.7
	var light:=DirectionalLight3D.new();world.add_child(light);light.rotation_degrees=Vector3(-35,-35,0);light.light_energy=1.4;light.light_color=Color("ffe1b8")
	var rim:=OmniLight3D.new();world.add_child(rim);rim.position=Vector3(-3,3,-3);rim.light_color=Color("ffc668");rim.light_energy=3;rim.omni_range=12
	preview_car=load("res://vehicles/s64_compact_visual.tscn").instantiate();world.add_child(preview_car);preview_car.rotation.y=-0.35
	var platform:=MeshInstance3D.new();world.add_child(platform)
	var disk:=CylinderMesh.new();disk.top_radius=3.5;disk.bottom_radius=3.6;disk.height=0.2;disk.radial_segments=64
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("1b2e39");mat.metallic=0.3;mat.roughness=0.5
	disk.material=mat;platform.mesh=disk;platform.position.y=-0.12
	var camera:=Camera3D.new();world.add_child(camera);camera.position=Vector3(5.4,2.9,-6.7)
	camera.look_at(Vector3(0,0.65,0));camera.fov=43;camera.current=true
	var caption:=Label.new();add_child(caption);caption.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	caption.offset_left=-470;caption.offset_right=-30;caption.offset_top=190;caption.offset_bottom=250
	caption.text=preload("res://vehicles/vehicle_catalog.gd").title(GameSettings.vehicle_id).to_upper()+"\nYOUR CURRENT GARAGE BUILD";caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",23);caption.modulate=Color("d3b986")
