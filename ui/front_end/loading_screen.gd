extends Control
const CITY := "res://world/handbuilt/plattsburgh_region.scn"
const TIPS := ["The handbrake helps rotate the car into a slide.","The minimap follows nearby streets. Street Legacy has the full event map.","Garage brands trade strengths within the same upgrade level.","Drag the car in the garage to rotate it. Scroll to zoom."]
var progress: ProgressBar
var status: Label
var tip: Label
var back: Button
var requested := false
var failed := false
var finishing := false
var age := 0.0
var stack: VBoxContainer
var padding: MarginContainer
var logo: Label
var heading: Label
func _ready() -> void:
	preload("res://ui/racing_theme.gd").apply(self)
	var background := ColorRect.new(); add_child(background); background.color = Color("08121c")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new(); add_child(center); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	padding = MarginContainer.new(); center.add_child(padding)
	for side in ["left","right","top","bottom"]: padding.add_theme_constant_override("margin_"+side,28)
	stack = VBoxContainer.new(); padding.add_child(stack); stack.custom_minimum_size.x = 420
	stack.add_theme_constant_override("separation",18)
	logo = Label.new(); stack.add_child(logo); logo.text = "REVVED"; logo.add_theme_font_size_override("font_size",72)
	logo.add_theme_color_override("font_color",Color("ffd05d"))
	heading = Label.new(); stack.add_child(heading); heading.text = "CHAMPLAIN COAST AFTER DARK"; heading.add_theme_font_size_override("font_size",28)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var profile := get_tree().root.get_node("StreetProfile")
	if profile.launch_mode=="garage": heading.text = "STREET LEGACY / GARAGE"
	elif profile.launch_mode in ["career","single","series"]:
		heading.text = preload("res://core/career_catalog.gd").event(profile.selected_event).name.to_upper()
		if profile.launch_mode=="series":heading.text="ROUND %d / "%[profile.series_round+1]+heading.text
	status = Label.new(); stack.add_child(status); status.text = "Opening the city…"
	progress = ProgressBar.new(); stack.add_child(progress); progress.custom_minimum_size.y = 12; progress.show_percentage = false
	tip = Label.new(); stack.add_child(tip); tip.custom_minimum_size.x = 420; tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.text = TIPS[0]; tip.modulate = Color("a0b7c7")
	back = Button.new(); stack.add_child(back); back.text = "BACK TO MENU"; back.custom_minimum_size.y = 48; back.hide()
	back.pressed.connect(func():profile.main_menu())
	resized.connect(layout_content); layout_content()
	call_deferred("request_city")
func layout_content() -> void:
	var compact := size.y<500
	var width := maxf(200,minf(520,size.x-56))
	stack.custom_minimum_size.x = width; tip.custom_minimum_size.x = width
	stack.add_theme_constant_override("separation",10 if compact else 18)
	logo.add_theme_font_size_override("font_size",46 if compact else 72)
	heading.add_theme_font_size_override("font_size",22 if compact else 28)
	for side in ["left","right","top","bottom"]: padding.add_theme_constant_override("margin_"+side,16 if compact else 28)
func request_city() -> void:
	var error := ResourceLoader.load_threaded_request(CITY,"PackedScene")
	if error!=OK: show_error(); return
	requested = true
func _process(delta: float) -> void:
	age += delta
	if is_instance_valid(tip): tip.text = TIPS[int(age/4.0)%TIPS.size()]
	if not requested or failed or finishing: return
	var amount := []
	var state := ResourceLoader.load_threaded_get_status(CITY,amount)
	if state==ResourceLoader.THREAD_LOAD_FAILED or state==ResourceLoader.THREAD_LOAD_INVALID_RESOURCE: show_error()
	elif state==ResourceLoader.THREAD_LOAD_IN_PROGRESS and not amount.is_empty(): progress.value = clampf(float(amount[0])*88.0,0,88)
	elif state==ResourceLoader.THREAD_LOAD_LOADED and age>=0.2: finish_loading()
func finish_loading() -> void:
	finishing = true
	var scene: PackedScene = ResourceLoader.load_threaded_get(CITY)
	if not scene: show_error(); return
	progress.value = 100; status.text = "Preparing the streets…"
	await get_tree().process_frame
	if get_tree().change_scene_to_packed(scene)!=OK: show_error()
func show_error() -> void:
	failed = true; status.text = "The city could not be opened. Please return to the menu and try again."
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; progress.hide(); back.show(); back.grab_focus()
