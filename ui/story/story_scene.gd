extends Control
## Small realtime sets, camera coverage, always-visible subtitles and offline voices.
const CATALOG=preload("res://core/story_catalog.gd")
const STYLE=preload("res://ui/racing_theme.gd")
const IDENTITY=preload("res://core/driver_identity.gd")
var screenplay:Dictionary={}
var line_index:=0
var elapsed:=0.0
var line_age:=0.0
var line_duration:=4.0
var type_clock:=0.0
var held:=false
var ending:=false
var camera:Camera3D
var voice:AudioStreamPlayer
var speaker:Label
var role:Label
var subtitle:Label
var portrait:TextureRect
var progress:Label
var dialogue:PanelContainer
var text_column:VBoxContainer
var next_button:Button
var auto_button:CheckButton
var voice_button:CheckButton
var pause_button:Button
var error_label:Label
var transcript:RichTextLabel
var header:VBoxContainer
var fade:ColorRect
var speaking_color:=STYLE.GOLD
var extra_controls:Array[Control]=[]
var compact_menu:MenuButton
var header_shade:ColorRect
func _ready()->void:
	STYLE.apply(self)
	var key:String=StreetProfile.story_request.get("key","prologue")
	screenplay=CATALOG.scene(key)
	if screenplay.is_empty():StreetProfile.main_menu();return
	_create_set(int(screenplay.chapter))
	var shade:=ColorRect.new();add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.color=Color(0.01,0.02,0.04,.20);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	header_shade=ColorRect.new();add_child(header_shade);header_shade.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);header_shade.color=Color(.008,.016,.025,.80);header_shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	header=VBoxContainer.new();add_child(header);header.position=Vector2(28,22)
	var eyebrow:=_label(header,"STREET LEGACY   /   LAST LIGHT",16);eyebrow.modulate=STYLE.CYAN
	_label(header,screenplay.title,30)
	progress=_label(header,"",15)
	var border:=ColorRect.new();add_child(border);border.color=Color.BLACK;border.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);border.offset_bottom=8;border.mouse_filter=Control.MOUSE_FILTER_IGNORE
	dialogue=PanelContainer.new();add_child(dialogue);dialogue.add_theme_stylebox_override("panel",STYLE.box(Color(.025,.045,.065,.97),STYLE.GOLD,6,1))
	var stack:=VBoxContainer.new();dialogue.add_child(stack);stack.add_theme_constant_override("separation",10)
	var row:=HBoxContainer.new();stack.add_child(row);row.add_theme_constant_override("separation",18)
	portrait=TextureRect.new();row.add_child(portrait);portrait.custom_minimum_size=Vector2(104,120);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	text_column=VBoxContainer.new();row.add_child(text_column);text_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	speaker=_label(text_column,"",21);role=_label(text_column,"",14);role.modulate=Color("9bb1c2")
	subtitle=_label(text_column,"",23);subtitle.custom_minimum_size.y=86
	error_label=_label(stack,"",16);error_label.modulate=Color("ff9c8b");error_label.hide()
	var controls:=HFlowContainer.new();stack.add_child(controls);controls.add_theme_constant_override("h_separation",10)
	next_button=_button(controls,"NEXT  /  ENTER",advance)
	extra_controls.append(_button(controls,"REPEAT LINE",func():show_line(line_index)))
	pause_button=_button(controls,"PAUSE",toggle_pause)
	extra_controls.append(pause_button)
	auto_button=CheckButton.new();controls.add_child(auto_button);auto_button.text="AUTO";auto_button.button_pressed=StreetProfile.story_auto;auto_button.toggled.connect(func(value):StreetProfile.story_auto=value)
	voice_button=CheckButton.new();controls.add_child(voice_button);voice_button.text="VOICE";voice_button.button_pressed=StreetProfile.story_voice;voice_button.toggled.connect(set_voice)
	extra_controls.append(auto_button);extra_controls.append(voice_button)
	extra_controls.append(_button(controls,"TRANSCRIPT",toggle_transcript))
	extra_controls.append(_button(controls,"SKIP SCENE",complete_scene))
	compact_menu=MenuButton.new();controls.add_child(compact_menu);compact_menu.text="SCENE OPTIONS";compact_menu.flat=false;compact_menu.custom_minimum_size.y=44;controls.move_child(compact_menu,1)
	var options:=compact_menu.get_popup()
	for option in ["Pause / Resume","Repeat line","Toggle automatic advance","Toggle voice","Read transcript","Skip scene"]:options.add_item(option)
	options.id_pressed.connect(scene_option)
	transcript=RichTextLabel.new();stack.add_child(transcript);transcript.custom_minimum_size.y=140;transcript.fit_content=false;transcript.hide()
	for line:Dictionary in screenplay.lines:transcript.append_text(CATALOG.cast(line.speaker).name+": "+CATALOG.line_text(line,StreetProfile.driver_name)+"\n\n")
	voice=AudioStreamPlayer.new();add_child(voice)
	resized.connect(layout_content);dialogue.minimum_size_changed.connect(func():call_deferred("layout_content"));layout_content();show_line(0);next_button.grab_focus()
	fade=ColorRect.new();add_child(fade);fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);fade.color=Color.BLACK;fade.mouse_filter=Control.MOUSE_FILTER_IGNORE;create_tween().tween_property(fade,"color:a",0.0,.65)
func scene_option(id:int)->void:
	match id:
		0:toggle_pause()
		1:show_line(line_index)
		2:StreetProfile.story_auto=not StreetProfile.story_auto;auto_button.set_pressed_no_signal(StreetProfile.story_auto)
		3:set_voice(not StreetProfile.story_voice);voice_button.set_pressed_no_signal(StreetProfile.story_voice)
		4:toggle_transcript()
		5:complete_scene()
func _label(parent:Node,value:String,font:int)->Label:
	var label:=Label.new();parent.add_child(label);label.text=value;label.add_theme_font_size_override("font_size",font);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return label
func _button(parent:Node,value:String,action:Callable)->Button:
	var button:=Button.new();parent.add_child(button);button.text=value;button.custom_minimum_size.y=44;button.add_theme_font_size_override("font_size",16);button.pressed.connect(action);return button
func layout_content()->void:
	var compact:=size.x<800 or size.y<560
	header_shade.offset_bottom=104 if size.y<500 else 136
	if size.y<500:transcript.hide()
	for control in extra_controls:control.visible=not compact
	compact_menu.visible=compact
	header.get_child(1).add_theme_font_size_override("font_size",22 if compact else 30)
	progress.visible=size.y>=500
	header.size.x=maxf(180,size.x-56)
	portrait.visible=not compact
	subtitle.add_theme_font_size_override("font_size",18 if compact else 23)
	subtitle.custom_minimum_size.y=62 if compact else 86
	var height:=maxf(dialogue.get_combined_minimum_size().y,215 if compact else 258)
	dialogue.position=Vector2(18,maxf(112,size.y-height-18));dialogue.size=Vector2(maxf(200,size.x-36),height)
	if transcript.visible:transcript.custom_minimum_size.y=80 if compact else 140
func show_line(index:int)->void:
	if index>=screenplay.lines.size():complete_scene();return
	line_index=index;line_age=0;type_clock=0
	var line:Dictionary=screenplay.lines[index];var person:Dictionary=CATALOG.cast(line.speaker)
	speaker.text=person.name;speaker.modulate=Color(person.color);speaking_color=Color(person.color);role.text=person.role
	portrait.texture=IDENTITY.portrait(int(person.presentation),int(person.portrait))
	subtitle.text=CATALOG.line_text(line,StreetProfile.driver_name);subtitle.visible_characters=0
	progress.text="%02d / %02d   •   %s"%[index+1,screenplay.lines.size(),"REPLAY" if StreetProfile.story_request.get("replay",false) else "STORY"]
	next_button.text="FINISH SCENE" if index==screenplay.lines.size()-1 else "NEXT  /  ENTER"
	voice.stop();voice.stream=null
	if ResourceLoader.exists(line.audio):voice.stream=load(line.audio)
	line_duration=maxf(3.5,subtitle.text.length()/16.0+1)
	if voice.stream:line_duration=maxf(line_duration,voice.stream.get_length()+.6)
	voice.volume_db=linear_to_db(maxf(.0001,StreetProfile.dialogue_volume))
	if StreetProfile.story_voice and voice.stream and not held:voice.play()
	layout_content()
func advance()->void:
	if ending:return
	if subtitle.visible_characters>=0 and subtitle.visible_characters<subtitle.text.length():subtitle.visible_characters=-1;return
	show_line(line_index+1)
func set_voice(value:bool)->void:
	StreetProfile.story_voice=value
	if not value:voice.stop()
	elif voice.stream and not held:voice.play()
func toggle_pause()->void:
	held=not held;voice.stream_paused=held;pause_button.text="RESUME" if held else "PAUSE"
func toggle_transcript()->void:
	if size.y<500:
		if not held:toggle_pause()
		var popup:=AcceptDialog.new();add_child(popup);popup.title="LAST LIGHT / TRANSCRIPT"
		var text:=RichTextLabel.new();popup.add_child(text);text.custom_minimum_size=Vector2(maxf(220,size.x-90),maxf(120,size.y-120));text.text=transcript.get_parsed_text()
		popup.confirmed.connect(popup.queue_free);popup.canceled.connect(popup.queue_free);popup.popup_centered();return
	transcript.visible=not transcript.visible
	if transcript.visible and not held:toggle_pause()
	layout_content()
func complete_scene()->void:
	if ending:return
	ending=true;voice.stop()
	if not StreetProfile.finish_story():
		ending=false;error_label.text=StreetProfile.story_save_error;error_label.show();StreetProfile.story_auto=false;auto_button.set_pressed_no_signal(false);layout_content()
func _unhandled_key_input(event:InputEvent)->void:
	if event.is_action_pressed("ui_accept"):advance();get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):toggle_pause();get_viewport().set_input_as_handled()
func _process(delta:float)->void:
	MenuScore.dialogue_active=is_instance_valid(voice) and voice.playing
	if not is_instance_valid(camera) or ending:return
	elapsed+=delta
	var close:=line_index%3==1
	var target:=Vector3(0,.7,0) if not close else Vector3(-1.1,.65,0)
	var offset:=Vector3(5.8+sin(elapsed*.09)*.6,2.2,-6.0) if not close else Vector3(3.6,1.35,-4.4)
	camera.position=camera.position.lerp(offset,1-exp(-delta*.8));camera.look_at(target)
	if held:return
	line_age+=delta;type_clock+=delta
	if subtitle.visible_characters>=0:subtitle.visible_characters=mini(subtitle.text.length(),int(type_clock*48))
	if StreetProfile.story_auto and not transcript.visible and line_age>line_duration and not voice.playing:show_line(line_index+1)
func _exit_tree()->void:MenuScore.dialogue_active=false
func _create_set(chapter:int)->void:
	var container:=SubViewportContainer.new();add_child(container);container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);container.stretch=true;container.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var viewport:=SubViewport.new();container.add_child(viewport);viewport.own_world_3d=true;viewport.msaa_3d=Viewport.MSAA_2X
	var world:=Node3D.new();viewport.add_child(world)
	var env:=WorldEnvironment.new();world.add_child(env);env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("080f1d");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy=.35
	var car:Node3D=load("res://vehicles/s64_compact_visual.tscn").instantiate();world.add_child(car)
	camera=Camera3D.new();world.add_child(camera);camera.position=Vector3(6,2.8,-7);camera.current=true;camera.fov=48
	var platform:=MeshInstance3D.new();world.add_child(platform);var disk:=CylinderMesh.new();disk.height=.12;disk.top_radius=3.6;disk.bottom_radius=3.6;platform.mesh=disk;platform.position.y=-.12
	preload("res://ui/front_end/night_showroom.gd").decorate(world,car,platform,camera,env.environment)
	# An authored garage frontage / coast meet set, kept small for quick story transitions.
	var wall_mat:=StandardMaterial3D.new();wall_mat.albedo_color=Color("192632");wall_mat.roughness=.6
	for x:float in [-5.0,5.0]:
		var column:=MeshInstance3D.new();world.add_child(column);var mesh:=BoxMesh.new();mesh.size=Vector3(.65,5,.65);column.mesh=mesh;column.position=Vector3(x,2.2,4);column.material_override=wall_mat
	var sign:=Label3D.new();world.add_child(sign);sign.text="VOSS MOTOR WORKS" if chapter==0 else "LAKE GHOSTS / AFTER DARK";sign.position=Vector3(0,3.3,4);sign.rotation.y=PI;sign.font_size=72;sign.pixel_size=.008;sign.modulate=STYLE.GOLD if chapter==0 else STYLE.CYAN;sign.no_depth_test=false
	var lamp:=OmniLight3D.new();world.add_child(lamp);lamp.position=Vector3(-2,2,-3);lamp.omni_range=14;lamp.light_energy=3;lamp.light_color=STYLE.GOLD if chapter==0 else STYLE.CYAN
	var fill:=OmniLight3D.new();world.add_child(fill);fill.position=Vector3(3,2,1);fill.omni_range=12;fill.light_energy=2.2;fill.light_color=Color("a9cbee")
