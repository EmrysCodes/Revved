@tool
extends "res://world/workshop/handbuilt_world.gd"
## Source-based regional sample. Game units are metres; geography is UTM18N.
@export var terrain_bounds:=Vector4.ZERO
@export var play_outline:=PackedVector2Array()
@export var landmarks:Dictionary={}
var _stream_clock:=0.0
var _safe_clock:=0.0
var _water:Image
var _last_safe:=Transform3D.IDENTITY
var _tiles:Array[Node3D]=[]
var _collision_updates:Array[Dictionary]=[]
var _location:Label
var _water_heights:=PackedFloat32Array()
var map_roads:Array[PackedVector3Array]=[]
var _street_label:Label
var _map_control:Control
var _stream_cells:Dictionary={}
var _active_tiles:Dictionary={}
var _stream_initialized:=false
var _last_stream_position:=Vector3.INF
func _ready()->void:
	super._ready()
	if Engine.is_editor_hint():return
	car.align_to_slopes=true;car.floor_constant_speed=true;car.floor_snap_length=.6
	# Generated furniture is soft in this arcade map; it must never pin a racer.
	for prop:Node in get_node("Props").get_children():
		if str(prop.name).begins_with("UrbanLamp"):
			var solid:=prop.get_node_or_null("Solid")
			if solid is StaticBody3D:solid.collision_layer=0;solid.collision_mask=0
	_water=load("res://world/plattsburgh/data/water_mask.png").get_image()
	if _water.is_compressed():_water.decompress()
	_water_heights=FileAccess.get_file_as_bytes("res://world/plattsburgh/data/water_surface.bin").to_float32_array()
	_last_safe=car.global_transform
	for group:String in ["Terrain","Buildings","Dressing"]:
		for tile:Node3D in get_node(group).get_children():
			_tiles.append(tile);var cell:=Vector2i(floori(tile.global_position.x/512),floori(tile.global_position.z/512))
			if not _stream_cells.has(cell):_stream_cells[cell]=[]
			_stream_cells[cell].append(tile)
	for road:Node3D in get_node("Roads").get_children():
		if not road.has_meta("workshop_road"):continue
		var line:=PackedVector3Array()
		for p:Vector3 in road.points:line.append(road.to_global(p))
		map_roads.append(line)
	var layer:=CanvasLayer.new();layer.name="CityHUD";add_child(layer);var screen:=Control.new();screen.name="Screen";layer.add_child(screen);screen.size=get_viewport().get_visible_rect().size;get_viewport().size_changed.connect(func():screen.size=get_viewport().get_visible_rect().size);screen.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_location=Label.new();screen.add_child(_location);_location.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);_location.offset_left=-355;_location.offset_top=18;_location.offset_right=-20;_location.offset_bottom=98;_location.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;_location.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_location.add_theme_font_size_override("font_size",17);_location.add_theme_color_override("font_shadow_color",Color.BLACK);_location.add_theme_constant_override("shadow_offset_x",2);_location.add_theme_constant_override("shadow_offset_y",2)
	_location.name="Readout"
	var map:=Control.new();map.set_script(load("res://world/plattsburgh/region_map.gd"));screen.add_child(map);map.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);map.offset_left=-250;map.offset_top=-250;map.offset_right=-20;map.offset_bottom=-20;map.setup(self,car)
	map.name="Map";_map_control=map
	if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
		map.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);map.offset_left=-190;map.offset_right=-20;map.offset_top=105;map.offset_bottom=275;map.size=Vector2(170,170)
	car.get_node("HUD/Screen/TouchControls").bind_world(self)
	var street:=Label.new();screen.add_child(street);street.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP);street.offset_left=-210;street.offset_right=210;street.offset_top=20;street.offset_bottom=54;street.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;street.add_theme_font_size_override("font_size",20);street.add_theme_color_override("font_color",Color("f2cc8a"));street.add_theme_color_override("font_shadow_color",Color.BLACK);street.add_theme_constant_override("shadow_offset_x",2);street.add_theme_constant_override("shadow_offset_y",2);map.street_label=street
	_street_label=street
	street.clip_text=true;street.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	_stream_tiles()
	var ambience:=Node3D.new();ambience.name="CoastAmbience";ambience.set_script(load("res://audio/city_ambience.gd"));ambience.profile=2;add_child(ambience)
	var life:=Node3D.new();life.name="CoastLife";life.set_script(load("res://world/plattsburgh/region_life.gd"));add_child(life)
	call_deferred("_add_regional_race")
func _add_regional_race()->void:
	for i in range(4):await get_tree().physics_frame
	var race:Node3D=load("res://racing/capital_run.tscn").instantiate();add_child(race)
	var profile:=get_tree().root.get_node("StreetProfile")
	if profile.launch_mode in ["single","career","series"]:
		race.start_race();_last_safe=car.global_transform;_stream_tiles()
	elif profile.launch_mode=="garage":
		car.get_node("PauseMenu").open_menu();car.get_node("PauseMenu").call("_open_garage")
func _process(delta:float)->void:
	if Engine.is_editor_hint() or not is_instance_valid(car):return
	_apply_collision_updates()
	var race:=get_node_or_null("CityRace")
	var compact:bool=get_viewport().get_visible_rect().size.x<800
	world_header.visible=not compact and not car.get_node("HUD/Screen/TouchControls").enabled
	if race:
		_location.visible=not race.hud.card.visible and not compact
		_street_label.visible=not race.is_active() and not compact
		_map_control.visible=not (compact and race.is_active())
	_stream_clock+=delta;_safe_clock+=delta
	if _stream_clock<.5:return
	_stream_clock=0;_stream_tiles()
	var p:=car.global_position
	var uv:=(Vector2(p.x,p.z)-Vector2(terrain_bounds.x,terrain_bounds.y))/Vector2(terrain_bounds.z-terrain_bounds.x,terrain_bounds.w-terrain_bounds.y)
	var water:=_water.get_pixel(clampi(int(uv.x*(_water.get_width()-1)),0,_water.get_width()-1),clampi(int(uv.y*(_water.get_height()-1)),0,_water.get_height()-1)).r>.5
	if water:
		# A coarse shoreline pixel can overlap a bridge approach. Actual pavement
		# contact takes priority over the raster so crossing it never triggers rescue.
		var query:=PhysicsRayQueryParameters3D.create(p+Vector3.UP*.75,p-Vector3.UP*.35,1,[car.get_rid()]);var hit:=get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.collider.get_meta("driveable_road",false):water=false
	var water_index:=clampi(roundi(uv.y*(_water.get_height()-1)),0,_water.get_height()-1)*_water.get_width()+clampi(roundi(uv.x*(_water.get_width()-1)),0,_water.get_width()-1)
	if not Geometry2D.is_point_in_polygon(Vector2(p.x,p.z),play_outline) or (water and p.y<_water_heights[water_index]+.35):
		car._spawn_transform=_last_safe;car._reset_car();_location.text="MAP EDGE / RETURNED TO LAND";return
	if _safe_clock>5 and car.is_on_floor() and not water:_last_safe=car.global_transform;_safe_clock=0
	_location.text=("NORTH END" if p.z< -3500 else ("DOWNTOWN" if p.z<1800 else ("AIRPORT / SOUTH END" if p.z<6500 else "VALCOUR / LAKESHORE")))+"\nCHAMPLAIN COAST / NIGHT DRIVE"
func _stream_tiles()->void:
	var position:=car.global_position
	if _stream_initialized and position.distance_squared_to(_last_stream_position)<40*40:return
	_last_stream_position=position
	var cell:=Vector2i(floori(position.x/512),floori(position.z/512));var nearby:Dictionary={}
	for x in range(-5,6):
		for z in range(-5,6):
			for tile:Node3D in _stream_cells.get(cell+Vector2i(x,z),[]):
				if Vector2(tile.global_position.x-position.x,tile.global_position.z-position.z).length_squared()<2200*2200:nearby[tile.get_instance_id()]=tile
	# Deactivation is queued first, so nearby activation gets LIFO priority.
	if not _stream_initialized:
		for tile:Node3D in _tiles:
			if not nearby.has(tile.get_instance_id()):_set_tile_active(tile,false)
	else:
		for id:int in _active_tiles:
			if not nearby.has(id):_set_tile_active(_active_tiles[id],false)
	for id:int in nearby:
		if not _active_tiles.has(id):_set_tile_active(nearby[id],true)
	_active_tiles=nearby;_stream_initialized=true
func _set_tile_active(tile:Node3D,active:bool)->void:
	if tile.get_meta("stream_active",true)==active:return
	tile.set_meta("stream_active",active);tile.visible=active
	for body:StaticBody3D in tile.find_children("*","StaticBody3D",true,false):_collision_updates.append({"body":body,"tile":tile,"active":active})
func _apply_collision_updates()->void:
	for i in range(mini(128,_collision_updates.size())):
		var update:Dictionary=_collision_updates.pop_back()
		if not is_instance_valid(update.body) or not is_instance_valid(update.tile):continue
		if bool(update.tile.get_meta("stream_active",true))!=bool(update.active):continue
		update.body.collision_layer=1 if update.active else 0
