extends Control
## North-up map; cache static roads and update the player marker at 20Hz.
@onready var city: Node3D = get_node("../../..")
var cached_roads: Array = []
var water_polygon:=PackedVector2Array()
var refresh_time:=0.0
var cached_course:=PackedVector2Array()
var cached_event_id:=0
var map_minimum:=Vector2(-720,-720)
var map_scale:=Vector2.ONE
func _ready() -> void:
	resized.connect(_cache_roads)
	_cache_roads()
func _process(delta: float) -> void:
	refresh_time+=delta
	if refresh_time>=0.05:
		refresh_time=0
		queue_redraw()
func _point(point: Vector3) -> Vector2:
	return Vector2(12,26)+(Vector2(point.x,point.z)-map_minimum)*map_scale

func _cache_roads() -> void:
	if not is_instance_valid(city) or city.get("map_roads")==null:
		return
	cached_event_id=0
	map_minimum=city.get("map_min") if city.get("map_min")!=null else Vector2(-720,-720)
	var maximum:Vector2=city.get("map_max") if city.get("map_max")!=null else Vector2(720,720)
	map_scale=Vector2(size.x-24,size.y-38)/(maximum-map_minimum)
	cached_roads.clear()
	water_polygon.clear()
	for point: Vector3 in city.get_meta("water_map",PackedVector3Array()):
		water_polygon.append(_point(point))
	var groups: Array=[city.map_roads,city.highway_roads,city.ramp_roads]
	var colors: Array[Color]=[Color(0.5,0.57,0.65),Color(0.1,0.8,0.95),Color(1,0.7,0.2)]
	for index in range(3):
		for road: PackedVector3Array in groups[index]:
			var points:=PackedVector2Array()
			for point in road:
				points.append(_point(point))
			cached_roads.append([points,colors[index]])
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(city) or not is_instance_valid(city.car):
		return
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.025,0.04,0.055,0.92))
	draw_string(get_theme_default_font(),Vector2(12,18),city.get("map_title") if city.get("map_title")!=null else "DOWNTOWN / N",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(0.85,0.92,1))
	if water_polygon.size()>2:
		draw_colored_polygon(water_polygon,Color(0.10,0.30,0.42))
	for road in cached_roads:
		draw_polyline(road[0],road[1],1.5,true)
	var event:=city.get_node_or_null("CityRace")
	if is_instance_valid(event):
		if event.is_active():
			if cached_event_id!=event.get_instance_id():
				cached_event_id=event.get_instance_id();cached_course.clear()
				for i in range(0,event.finish_index+1,5):cached_course.append(_point(event.route[i]))
			if cached_course.size()>1: draw_polyline(cached_course,Color(1,0.8,0.2),2.8,true)
			var target: int=event.next_checkpoint.get(city.car.get_instance_id(),0)
			if target<event.checkpoint_indices.size():
				draw_circle(_point(event.route[event.checkpoint_indices[target]]),4,Color(0.15,1,0.65))
			for rival in event.opponents:
				draw_circle(_point(rival.position),3,rival.rival_color)
		else:
			draw_circle(_point(event.entry_position),4,Color(1,0.8,0.2))
	var marker:=_point(city.car.position)
	var direction:=Vector2(-city.car.global_basis.z.x,-city.car.global_basis.z.z)
	var side:=Vector2(-direction.y,direction.x)
	draw_colored_polygon(PackedVector2Array([marker+direction*7,marker-direction*4+side*4,marker-direction*4-side*4]),Color(1,0.3,0.15))
