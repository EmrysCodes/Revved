extends Control
## High-contrast, heading-up route preview with an along-road turn countdown.
var event:Node
var turns:Array[Dictionary]=[]
var maneuver:Dictionary={}
var traveled:=0.0
var warning:=""
var road_bounds:Array[Rect2]=[]
var frame_origin:=Vector3.ZERO
var frame_inverse:=Basis.IDENTITY
var time_value:=0.0
var cadence:=0.0
const GUIDANCE=preload("res://racing/route_guidance.gd")
const GOLD:=Color("ffd45a")
const CYAN:=Color("4ee5ff")
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	resized.connect(queue_redraw)
	get_parent().resized.connect(layout)
	layout()
func layout() -> void:
	var wide:float=get_parent().size.x
	var width:=minf(wide-24,clampf(wide*.46,310,590))
	offset_left=-width*.5;offset_right=width*.5;offset_top=16;offset_bottom=188
	if wide<1200:offset_top=122;offset_bottom=240
	queue_redraw()
func bind_race(value:Node) -> void:
	event=value;turns=GUIDANCE.maneuvers(event.route,event.distances,event.finish_index)
	road_bounds.clear()
	for road:PackedVector3Array in event.get_parent().map_roads:
		var bounds:=Rect2(Vector2(road[0].x,road[0].z),Vector2.ZERO)
		for p:Vector3 in road:bounds=bounds.expand(Vector2(p.x,p.z))
		road_bounds.append(bounds)
func _process(delta:float) -> void:
	time_value+=delta;cadence+=delta
	if not is_instance_valid(event):hide();return
	visible=event.state in [event.Phase.COUNTDOWN,event.Phase.RUNNING]
	if cadence<0.06 or not visible:return
	cadence=0
	traveled=event.progress.get(event.player.get_instance_id(),0)
	maneuver=GUIDANCE.next_turn(turns,traveled)
	warning=""
	var separation:float=event._project_progress(event.player)
	if separation>35:warning="OFF ROUTE  /  RESET TO RECOVER"
	else:
		var i:=clampi(event.route_index_at_distance(traveled),0,event.finish_index-1)
		var forward:Vector3=event.route[mini(i+5,event.finish_index)]-event.route[i]
		forward.y=0
		if event.player.velocity.length()>4 and event.player.velocity.dot(forward.normalized())< -2:warning="WRONG WAY  /  TURN AROUND"
	queue_redraw()
func panel(rect:Rect2,color:Color,border:=Color.TRANSPARENT) -> void:
	var style:=StyleBoxFlat.new();style.bg_color=color;style.set_corner_radius_all(12)
	style.border_color=border;style.set_border_width_all(2)
	draw_style_box(style,rect)
func text(value:String,point:Vector2,font_size:int,color:=Color.WHITE,width:float=-1) -> void:
	draw_string(ThemeDB.fallback_font,point,value,HORIZONTAL_ALIGNMENT_LEFT,width,font_size,color)
func _draw() -> void:
	if not is_instance_valid(event) or maneuver.is_empty():return
	var urgent:bool=maneuver.distance<45
	var accent:=Color("ff6b55") if not warning.is_empty() else GOLD
	panel(Rect2(Vector2.ZERO,size),Color("08121bec"),accent.lightened(.12) if urgent else Color("42616f"))
	draw_rect(Rect2(0,0,7,size.y),accent)
	text("REVVED  /  GPS",Vector2(21,23),13,CYAN)
	var compact:bool=size.y<140
	var map_width:float=0 if compact else minf(210,size.x*.38)
	var map_box:=Rect2(size.x-map_width-10,11,map_width,size.y-22)
	if not compact:
		panel(map_box,Color("152a35"));_draw_route(map_box)
	var left_width:=size.x-map_width-32
	var heading:String="WRONG WAY" if warning.begins_with("WRONG") else "OFF ROUTE" if not warning.is_empty() else ("TURN NOW" if maneuver.in_turn and maneuver.kind!="finish" else ("FINISH AHEAD" if maneuver.kind=="finish" else "NEXT TURN"))
	text(heading,Vector2(100,43 if compact else 51),13,accent,left_width-92)
	text(maneuver.label if warning.is_empty() else "RECOVER",Vector2(100,69 if compact else 82),22,Color.WHITE,left_width-94)
	var distance_text:=GameSettings.format_distance(maneuver.distance,true) if not maneuver.in_turn else ("THROUGH CORNER" if maneuver.kind!="finish" else "CROSS THE LINE")
	text(distance_text,Vector2(100,96 if compact else 109),17,accent,left_width-94)
	if not compact:text(GameSettings.format_distance(maxf(0,event.length-traveled))+" TO FINISH",Vector2(22,size.y-19),14,Color("b4cbd6"),left_width)
	_draw_arrow(Vector2(51,73 if compact else 79),maneuver.kind,accent,urgent)

func _draw_arrow(center:Vector2,kind:String,color:Color,urgent:bool) -> void:
	var points:=PackedVector2Array()
	if kind=="finish":
		draw_line(center+Vector2(-22,30),center+Vector2(-22,-29),Color.WHITE,5,true)
		for x in range(4):
			for y in range(3):draw_rect(Rect2(center+Vector2(-20+x*12,-29+y*12),Vector2(12,12)),Color.WHITE if (x+y)%2==0 else Color("17212a"))
		return
	if kind=="uturn":
		points=PackedVector2Array([Vector2(24,28),Vector2(24,-12),Vector2(12,-26),Vector2(-10,-26),Vector2(-23,-12),Vector2(-23,10)])
	else:
		var side:float=-1 if "left" in kind else 1
		points=PackedVector2Array([Vector2(0,31),Vector2(0,-2),Vector2(side*8,-15),Vector2(side*31,-15)])
	var alpha:=.82+.18*sin(time_value*7) if urgent else 1.0
	color.a=alpha
	_arrow_line(points,center,color)
	var tip:=points[-1]+center;var direction:Vector2=(points[-1]-points[-2]).normalized();var normal:=Vector2(-direction.y,direction.x)
	draw_colored_polygon(PackedVector2Array([tip+direction*14,tip-direction*10+normal*17,tip-direction*10-normal*17]),color)
func _arrow_line(points:PackedVector2Array,center:Vector2,color:Color) -> void:
	var transformed:=PackedVector2Array()
	for p in points:transformed.append(p+center)
	draw_polyline(transformed,color,12,true)
func _map_point(world:Vector3,box:Rect2) -> Vector2:
	var difference:Vector3=world-frame_origin
	var local_point:Vector3=frame_inverse*difference
	var scale_value:=box.size.x/310.0
	return Vector2(box.get_center().x,box.position.y+box.size.y*.78)+Vector2(local_point.x,local_point.z)*scale_value
func _draw_route(box:Rect2) -> void:
	var city:Node=event.get_parent()
	var clip:=box.grow(-6)
	frame_origin=event.player.global_position;frame_inverse=event.player.global_basis.inverse()
	for road_index in range(city.map_roads.size()):
		if road_index<road_bounds.size() and not road_bounds[road_index].grow(310).has_point(Vector2(frame_origin.x,frame_origin.z)):continue
		var road:PackedVector3Array=city.map_roads[road_index]
		for i in range(1,road.size(),3):
			var a:=_map_point(road[maxi(0,i-3)],box);var b:=_map_point(road[i],box)
			if clip.has_point(a) and clip.has_point(b):draw_line(a,b,Color("344f5c"),3,true)
	var marker:=Vector2(box.get_center().x,box.position.y+box.size.y*.78)
	var index:=maxi(0,event.route_index_at_distance(traveled)-3)
	for i in range(index+1,mini(event.finish_index+1,index+160)):
		var a:=_map_point(event.route[i-1],box);var b:=_map_point(event.route[i],box)
		if clip.has_point(a) and clip.has_point(b):
			draw_line(a,b,Color("072331"),11,true);draw_line(a,b,CYAN,6,true)
	var turn_point:=_map_point(event.route[mini(int(maneuver.index),event.finish_index)],box)
	if clip.has_point(turn_point):draw_circle(turn_point,8,GOLD)
	draw_colored_polygon(PackedVector2Array([marker+Vector2(0,-13),marker+Vector2(-9,8),marker+Vector2(9,8)]),Color.WHITE)
	text("ROUTE UP",box.position+Vector2(8,15),10,Color("90b1c4"))
