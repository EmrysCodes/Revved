extends Control
signal event_selected(index:int)
const CATALOG=preload("res://core/career_catalog.gd")
const EVENTS=CATALOG.EVENTS
const STYLE=preload("res://ui/racing_theme.gd")
var roads:Dictionary={}
var water:=PackedVector2Array()
var zoom:=1.0
var pan:=Vector2.ZERO
var dragging:=false
var markers:Array[Button]=[]
var selected:=0
var chapter_filter:=-1
var route_cache:Dictionary={}
func _ready() -> void:
	clip_contents=true;mouse_default_cursor_shape=Control.CURSOR_DRAG
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://ui/legacy/city_map.json"))
	for key in ["roads","highways","ramps"]:
		roads[key]=[]
		for path:Array in data[key]:
			var line:=PackedVector2Array()
			for p:Array in path:line.append(Vector2(p[0],p[1]))
			roads[key].append(line)
	for p:Array in data.water:water.append(Vector2(p[0],p[1]))
	for index in range(EVENTS.size()):
		var marker:=Button.new();add_child(marker);markers.append(marker);marker.custom_minimum_size=Vector2(32,32);marker.add_theme_font_size_override("font_size",14)
		marker.pressed.connect(func():event_selected.emit(index))
	resized.connect(refresh);refresh()
func point(p:Vector2) -> Vector2:
	var factor:=maxf(.015,minf((size.x-55)/4500.0,(size.y-45)/3800.0))*zoom
	return size*.5+p*factor+pan
func refresh() -> void:
	var placed:Array[Vector2]=[]
	var offsets:=[Vector2.ZERO,Vector2(34,-10),Vector2(-34,10),Vector2(0,34),Vector2(0,-34),Vector2(40,32),Vector2(-40,-32),Vector2(70,0),Vector2(-70,0),Vector2(70,40)]
	for index in range(markers.size()):
		var event:Dictionary=EVENTS[index];var marker:=markers[index]
		marker.visible=chapter_filter<0 or event.chapter==chapter_filter
		if not marker.visible:continue
		var open:bool=CATALOG.unlock_reason(event.id,StreetProfile.event_results).is_empty()
		var completed:bool=CATALOG.won(StreetProfile.event_results,event.id)
		var color:Color=CATALOG.CHAPTERS[event.chapter].color if open else Color("607582")
		var style:=STYLE.box(color if index==selected else Color("122630"),color,18,2)
		style.content_margin_left=0;style.content_margin_right=0;style.content_margin_top=0;style.content_margin_bottom=0
		for state in ["normal","hover","pressed","focus"]:marker.add_theme_stylebox_override(state,style)
		marker.add_theme_color_override("font_color",STYLE.INK if index==selected else color)
		marker.text="✓" if completed else "%02d"%(index+1)
		marker.tooltip_text=event.name+" / "+event.kind+(" / LOCKED" if not open else "")
		marker.size=Vector2(32,32)
		var location:=point(event.point)
		for offset:Vector2 in offsets:
			var candidate:Vector2=location+offset
			candidate.x=clampf(candidate.x,20,maxf(20,size.x-20));candidate.y=clampf(candidate.y,42,maxf(42,size.y-30))
			var clear:=true
			for other in placed:
				if other.distance_to(candidate)<34:clear=false;break
			location=candidate
			if clear:break
		marker.position=location-Vector2(16,16);placed.append(location)
	queue_redraw()
func reset_view() -> void:
	zoom=1;pan=Vector2.ZERO;chapter_filter=-1;refresh()
func focus_chapter(chapter:int) -> void:
	chapter_filter=chapter;zoom=1.35 if chapter==0 else 2.0;pan=Vector2.ZERO
	var center:=Vector2(-400,150) if chapter==0 else Vector2(1430,300)
	pan=size*.5-point(center);refresh()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("0c202b"))
	for x in range(0,int(size.x),55):draw_line(Vector2(x,0),Vector2(x,size.y),Color("17313c"))
	for y in range(0,int(size.y),55):draw_line(Vector2(0,y),Vector2(size.x,y),Color("17313c"))
	var river:=PackedVector2Array()
	for p in water:river.append(point(p))
	if river.size()>2:draw_colored_polygon(river,Color("225067"))
	for key in roads:
		for path:PackedVector2Array in roads[key]:
			var line:=PackedVector2Array()
			for p in path:line.append(point(p))
			if line.size()>1:draw_polyline(line,Color("807350") if key!="roads" else Color("496976"),2.0 if key!="roads" else 1.2,true)
	if selected>=0 and selected<EVENTS.size():
		var id:String=EVENTS[selected].id
		if not route_cache.has(id):
			var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CATALOG.route_path(id)))
			var preview:=PackedVector2Array()
			for p:Array in data.points:preview.append(Vector2(p[0],p[2]))
			route_cache[id]=preview
		var preview:=PackedVector2Array()
		for p:Vector2 in route_cache[id]:preview.append(point(p))
		if preview.size()>1:
			draw_polyline(preview,Color("07141c"),8,true);draw_polyline(preview,STYLE.CYAN,3.5,true)
	for index in range(markers.size()):
		if markers[index].visible:draw_line(point(EVENTS[index].point),markers[index].position+Vector2(16,16),Color("6c97a3"),1,true)
	draw_string(ThemeDB.fallback_font,Vector2(16,24),"STREET LEGACY / CITY EVENT BOARD",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("d5e7ed"))
	if size.y>180:draw_string(ThemeDB.fallback_font,Vector2(16,size.y-14),"DRAG TO PAN  •  WHEEL TO ZOOM  •  SELECT AN EVENT",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("91adbb"))
func _gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:dragging=event.pressed
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			var old:=zoom;zoom=clampf(zoom*(1.15 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1/1.15),.8,4)
			pan=(pan-(event.position-size*.5))*(zoom/old)+(event.position-size*.5);refresh();accept_event()
	if event is InputEventMouseMotion and dragging:pan+=event.relative;refresh();accept_event()
