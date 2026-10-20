extends Control
## North-up local navigation: 200 metres around the car, refreshed at 20 Hz.
const VIEW_RADIUS := 200.0
@onready var city: Node3D = get_node("../../..")
var cached_roads: Array = []
var water_polygon := PackedVector2Array()
var refresh_time := 0.0
var cached_course := PackedVector2Array()
var cached_event_id := 0
var map_minimum := Vector2.ZERO
var map_scale := Vector2.ONE
var map_canvas: Control
var view_bounds := Rect2()
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_canvas = Control.new(); map_canvas.name = "NearbyStreets"
	map_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE; map_canvas.clip_contents = true
	add_child(map_canvas); map_canvas.draw.connect(_draw_map)
	resized.connect(_cache_roads); _cache_roads()
func _process(delta: float) -> void:
	refresh_time += delta
	if refresh_time >= 0.05:
		refresh_time = 0; _update_view(); map_canvas.queue_redraw()
func _update_view() -> void:
	if not is_instance_valid(city) or not is_instance_valid(city.car): return
	var center := Vector2(city.car.global_position.x,city.car.global_position.z)
	var extent := map_canvas.size / map_scale * 0.5
	map_minimum = center - extent; view_bounds = Rect2(map_minimum,extent*2)
func _point(point: Vector3) -> Vector2:
	return (Vector2(point.x,point.z)-map_minimum)*map_scale
func _cache_roads() -> void:
	if not is_instance_valid(city) or city.get("map_roads")==null or not is_instance_valid(map_canvas): return
	map_canvas.position = Vector2(8,26); map_canvas.size = Vector2(maxf(1,size.x-16),maxf(1,size.y-34))
	map_scale = Vector2.ONE*minf(map_canvas.size.x,map_canvas.size.y)/(VIEW_RADIUS*2)
	cached_event_id = 0; cached_roads.clear(); water_polygon.clear()
	for point: Vector3 in city.get_meta("water_map",PackedVector3Array()): water_polygon.append(Vector2(point.x,point.z)*map_scale)
	var groups: Array = [city.map_roads,city.highway_roads,city.ramp_roads]
	var colors: Array[Color] = [Color("9baabd"),Color("22cdea"),Color("ffb333")]
	for index in range(3):
		for road: PackedVector3Array in groups[index]:
			if road.size()<2: continue
			var points := PackedVector2Array()
			var bounds := Rect2(Vector2(road[0].x,road[0].z),Vector2.ZERO)
			for point in road:
				var flat := Vector2(point.x,point.z); points.append(flat*map_scale); bounds = bounds.expand(flat)
			cached_roads.append([points,colors[index],bounds.grow(2)])
	_update_view(); queue_redraw(); map_canvas.queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.025,0.04,0.055,0.94))
	draw_string(get_theme_default_font(),Vector2(12,18),"NEARBY / N" if size.x<160 else "NEARBY STREETS / N",HORIZONTAL_ALIGNMENT_LEFT,-1,11 if size.x<160 else 13,Color(0.85,0.92,1))
func _draw_map() -> void:
	if not is_instance_valid(city) or not is_instance_valid(city.car): return
	# Cached world-space lines translate with the player; the inset clips long roads.
	map_canvas.draw_set_transform(-map_minimum*map_scale)
	if water_polygon.size()>2: map_canvas.draw_colored_polygon(water_polygon,Color(0.1,0.3,0.42))
	for road in cached_roads:
		if view_bounds.intersects(road[2]): map_canvas.draw_polyline(road[0],road[1],2,true)
	var event := city.get_node_or_null("CityRace")
	if is_instance_valid(event):
		if event.is_active():
			if cached_event_id!=event.get_instance_id():
				cached_event_id = event.get_instance_id(); cached_course.clear()
				for i in range(0,event.finish_index+1,5): cached_course.append(Vector2(event.route[i].x,event.route[i].z)*map_scale)
			if cached_course.size()>1: map_canvas.draw_polyline(cached_course,Color(1,0.8,0.2),3.5,true)
			var target: int = event.next_checkpoint.get(city.car.get_instance_id(),0)
			if target<event.checkpoint_indices.size(): _dot(event.route[event.checkpoint_indices[target]],4,Color(0.15,1,0.65))
			for rival in event.opponents: _dot(rival.global_position,3,rival.rival_color)
		else: _dot(event.entry_position,4,Color(1,0.8,0.2))
	map_canvas.draw_set_transform(Vector2.ZERO)
	var marker := _point(city.car.global_position)
	var direction := Vector2(-city.car.global_basis.z.x,-city.car.global_basis.z.z).normalized()
	var side := Vector2(-direction.y,direction.x)
	map_canvas.draw_circle(marker,9,Color(0.02,0.04,0.06,0.9))
	map_canvas.draw_colored_polygon(PackedVector2Array([marker+direction*8,marker-direction*5+side*5,marker-direction*5-side*5]),Color("ff6538"))
	var scale_start := Vector2(map_canvas.size.x-100*map_scale.x-9,map_canvas.size.y-8)
	map_canvas.draw_line(scale_start,scale_start+Vector2(100*map_scale.x,0),Color("a5b5c1"),2)
	var distance: String = get_tree().root.get_node("GameSettings").format_distance(100,true)
	map_canvas.draw_string(get_theme_default_font(),scale_start+Vector2(0,-5),distance,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("a5b5c1"))
func _dot(point: Vector3,radius: float,color: Color) -> void:
	if view_bounds.has_point(Vector2(point.x,point.z)): map_canvas.draw_circle(Vector2(point.x,point.z)*map_scale,radius,color)
