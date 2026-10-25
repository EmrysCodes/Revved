@tool
extends VBoxContainer
signal command(action:String)
signal mode_changed(index:int)
signal asset_changed(id:String)
var asset_list:ItemList
var search:LineEdit
var category:OptionButton
var modes:OptionButton
var grid:SpinBox
var elevation:SpinBox
var yaw:SpinBox
var brush_scale:SpinBox
var road_width:SpinBox
var sidewalk:SpinBox
var closed:CheckBox
var surface:CheckBox
var status:Label
var world_label:Label
var selection_label:Label
var visible_entries:Array[Dictionary]=[]
var preview:SubViewport
var preview_stage:Node3D
var preview_camera:Camera3D
var preview_model:Node3D
func _ready()->void:
	custom_minimum_size.x=315
	var title:=_label(self,"REVVED / WORLD WORKSHOP",20);title.modulate=Color("ffd05d")
	world_label=_label(self,"Open a handbuilt world or create one.",14)
	var top:=HBoxContainer.new();add_child(top);_button(top,"New world","new");_button(top,"Starter world","starter")
	top=HBoxContainer.new();add_child(top);_button(top,"Save scene","save");_button(top,"Drive / F6","play")
	modes=OptionButton.new();add_child(modes)
	for name_value:String in ["Select / move / rotate / scale","Place assets","Draw a curved road","Set player start","Erase placed item"]:modes.add_item(name_value)
	modes.item_selected.connect(func(index:int):mode_changed.emit(index))
	status=_label(self,"Select mode: use Godot's normal 3D tools.",14);status.modulate=Color("91cadb")
	var scroll:=ScrollContainer.new();add_child(scroll);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var body:=VBoxContainer.new();scroll.add_child(body);body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",7)
	category=OptionButton.new();body.add_child(category)
	for name_value:String in ["All assets","Buildings","Street props","Road pieces"]:category.add_item(name_value)
	category.item_selected.connect(func(_index:int):refresh_assets())
	search=LineEdit.new();body.add_child(search);search.placeholder_text="Find a building or street prop...";search.text_changed.connect(func(_text:String):refresh_assets())
	asset_list=ItemList.new();body.add_child(asset_list);asset_list.custom_minimum_size.y=170;asset_list.item_selected.connect(_asset_selected)
	var container:=SubViewportContainer.new();body.add_child(container);container.custom_minimum_size.y=145;container.stretch=true;container.mouse_filter=Control.MOUSE_FILTER_IGNORE
	preview=SubViewport.new();preview.size=Vector2i(300,145);preview.own_world_3d=true;preview.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE;container.add_child(preview)
	preview_stage=Node3D.new();preview.add_child(preview_stage)
	var environment:=WorldEnvironment.new();preview_stage.add_child(environment);environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("14202b");environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("c1d3df");environment.environment.ambient_light_energy=.8
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-25,0);light.light_energy=1.5;preview_stage.add_child(light)
	preview_camera=Camera3D.new();preview_stage.add_child(preview_camera);preview_camera.current=true
	_label(body,"PLACEMENT",15)
	grid=_spin(body,"Grid snap (m)",0,20,1,.5)
	elevation=_spin(body,"Build elevation (m)",-100,300,.04,.01)
	yaw=_spin(body,"Brush rotation (degrees)",-360,360,0,15)
	brush_scale=_spin(body,"Brush size",.1,10,1,.1)
	surface=CheckBox.new();body.add_child(surface);surface.text="Place assets on surfaces";surface.button_pressed=true
	_label(body,"ROADS",15)
	road_width=_spin(body,"Road width (m)",4,40,12,.5)
	sidewalk=_spin(body,"Sidewalk width (m)",0,10,3,.25)
	closed=CheckBox.new();body.add_child(closed);closed.text="Closed road / loop"
	top=HBoxContainer.new();body.add_child(top);_button(top,"Build road / Enter","road");_button(top,"Cancel / Esc","cancel")
	_button(body,"Apply road settings to selection","road_settings")
	_label(body,"SELECTION",15)
	selection_label=_label(body,"Nothing selected",14)
	top=HBoxContainer.new();body.add_child(top);_button(top,"Duplicate","duplicate");_button(top,"Delete","delete")
	_button(body,"Edit selected in Inspector","inspect")
	_button(body,"Use this scene for Handbuilt City","publish")
	_label(body,"For an overview: select Ground / Surface in the Scene tree, move the pointer over the 3D view and press F. Edit individual road points in the Inspector.",13)
	_label(body,"Place: click in 3D. R turns the brush. Shift bypasses snap. Roads: click points, Enter builds, Backspace removes the last point. Esc returns to Select. Use Ctrl+Z / Ctrl+Shift+Z for undo / redo. Right mouse and Alt keep Godot camera navigation.",13)
	refresh_assets()
func _label(parent:Node,text:String,font:int)->Label:
	var label:=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",font);parent.add_child(label);return label
func _button(parent:Node,text:String,action:String)->void:
	var button:=Button.new();button.text=text;button.custom_minimum_size.y=32;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(button);button.pressed.connect(func():command.emit(action))
func _spin(parent:Node,title:String,minimum:float,maximum:float,value:float,step_value:float)->SpinBox:
	var row:=HBoxContainer.new();parent.add_child(row);var label:=_label(row,title,14);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var spin:=SpinBox.new();spin.min_value=minimum;spin.max_value=maximum;spin.step=step_value;spin.value=value;spin.custom_minimum_size.x=100;row.add_child(spin);return spin
func refresh_assets()->void:
	asset_list.clear();visible_entries.clear()
	for entry:Dictionary in preload("res://world/workshop/catalog.gd").entries():
		if category.selected>0 and entry.category!=category.get_item_text(category.selected):continue
		if not search.text.is_empty() and not str(entry.name).to_lower().contains(search.text.to_lower()):continue
		visible_entries.append(entry);asset_list.add_item(entry.name)
	if not visible_entries.is_empty():asset_list.select(0);_asset_selected(0)
func _asset_selected(index:int)->void:
	if index<0 or index>=visible_entries.size():return
	var id:String=visible_entries[index].id
	if is_instance_valid(preview_model):preview_stage.remove_child(preview_model);preview_model.queue_free()
	preview_model=preload("res://world/workshop/catalog.gd").create(id,false)
	if preview_model:
		preview_stage.add_child(preview_model)
		for node:Light3D in preview_model.find_children("*","Light3D",true,false):node.hide()
		var bounds:=AABB();var first:=true
		for mesh:MeshInstance3D in preview_model.find_children("*","MeshInstance3D",true,false):
			var box:=mesh.transform*mesh.get_aabb();bounds=box if first else bounds.merge(box);first=false
		var center:=bounds.get_center();var distance:=maxf(2,bounds.size.length())
		preview_camera.position=center+Vector3(.9,.55,1.2).normalized()*distance;preview_camera.look_at(center)
	asset_changed.emit(id)
