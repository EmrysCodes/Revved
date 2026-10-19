extends Control
signal event_selected(index: int)
const EVENTS: Array[Dictionary]=[
	{"name":"Capital Run","kind":"Street sprint","point":Vector2(-60,340),"available":true,"description":"IGNITION / 3.54 miles / 41 gates / 3 rivals\nRace through downtown, I-84, I-91 and the riverfront. Your background modifies the reputation reward."},
	{"name":"Asylum Circuit","kind":"Circuit","point":Vector2(-1090,-430),"available":false,"description":"LOCAL HEAT / Planned neighborhood circuit. Event content is in development."},
	{"name":"Riverfront Slide","kind":"Drift","point":Vector2(380,790),"available":false,"description":"DISTRICT KINGS / Planned riverfront drift event. Event content is in development."},
	{"name":"Redline North","kind":"Highway duel","point":Vector2(150,-1060),"available":false,"description":"REDLINE SOCIETY / Planned highway challenge. Event content is in development."},
	{"name":"Eastside Finals","kind":"Championship","point":Vector2(1250,240),"available":false,"description":"CITY LEGEND / Planned championship event. Event content is in development."}
]
var roads: Dictionary={}
var water:=PackedVector2Array()
var zoom:=1.0
var pan:=Vector2.ZERO
var dragging:=false
var markers: Array[Button]=[]
func _ready() -> void:
	clip_contents=true;mouse_default_cursor_shape=Control.CURSOR_DRAG
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://ui/legacy/city_map.json"))
	for key in ["roads","highways","ramps"]:
		roads[key]=[]
		for path: Array in data[key]:
			var line:=PackedVector2Array()
			for p: Array in path: line.append(Vector2(p[0],p[1]))
			roads[key].append(line)
	for p: Array in data.water: water.append(Vector2(p[0],p[1]))
	for index in range(EVENTS.size()):
		var marker:=Button.new();add_child(marker);markers.append(marker)
		marker.text=("● " if EVENTS[index].available else "◇ ")+EVENTS[index].name
		marker.add_theme_font_size_override("font_size",15)
		marker.modulate=Color("f4c05d") if EVENTS[index].available else Color("a3b7c4")
		marker.tooltip_text=EVENTS[index].kind+(" / Available" if EVENTS[index].available else " / In development")
		marker.pressed.connect(func():event_selected.emit(index))
	resized.connect(refresh);refresh()
func point(p: Vector2) -> Vector2:
	var scale_value:=minf((size.x-80)/4500.0,(size.y-60)/3800.0)*zoom
	return size*0.5+p*scale_value+pan
func refresh() -> void:
	for index in range(markers.size()):
		var marker:=markers[index]
		marker.size=marker.get_combined_minimum_size()
		marker.position=point(EVENTS[index].point)-marker.size*0.5
	queue_redraw()
func reset_view() -> void:
	zoom=1;pan=Vector2.ZERO;refresh()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("101f2a"))
	for x in range(0,int(size.x),70): draw_line(Vector2(x,0),Vector2(x,size.y),Color("172c37"))
	for y in range(0,int(size.y),70): draw_line(Vector2(0,y),Vector2(size.x,y),Color("172c37"))
	var river:=PackedVector2Array()
	for p in water: river.append(point(p))
	if river.size()>2: draw_colored_polygon(river,Color("25485b"))
	for key in roads:
		for path: PackedVector2Array in roads[key]:
			var line:=PackedVector2Array()
			for p in path: line.append(point(p))
			if line.size()>1: draw_polyline(line,Color("bc9760") if key!="roads" else Color("526b78"),2.2 if key!="roads" else 1.1,true)
	draw_string(ThemeDB.fallback_font,Vector2(16,24),"HARTFORD  /  N ↑",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("d0e4ed"))
	draw_string(ThemeDB.fallback_font,Vector2(16,size.y-14),"Drag to pan  •  Wheel to zoom  •  Select an event",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("a3b7c4"))
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT: dragging=event.pressed
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			var old:=zoom
			zoom=clampf(zoom*(1.15 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1/1.15),0.8,3)
			pan=(pan-(event.position-size*0.5))*(zoom/old)+(event.position-size*0.5)
			refresh();accept_event()
	if event is InputEventMouseMotion and dragging:
		pan+=event.relative;refresh();accept_event()
