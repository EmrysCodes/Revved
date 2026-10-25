extends Control
## Local street map. Uses the same three-dimensional road sources as the level.
var car:Node3D
var cells:Dictionary={}
var street_label:Label
var span:=260.0
var street:="PLATTSBURGH"
var timer:=0.0
func setup(world:Node3D,driver:Node3D)->void:
 car=driver;custom_minimum_size=Vector2(100,100);size=Vector2(230,230);clip_contents=true;mouse_filter=Control.MOUSE_FILTER_IGNORE
 for road:Node3D in world.get_node("Roads").get_children():
  if not road.has_meta("workshop_road"):continue
  var points:PackedVector3Array=road.points
  for i in range(1,points.size()):
   var a:=road.to_global(points[i-1]);var b:=road.to_global(points[i]);var mid:=(a+b)*.5;var cell:=Vector2i(floori(mid.x/128),floori(mid.z/128))
   if not cells.has(cell):cells[cell]=[]
   cells[cell].append([a,b,str(road.get_meta("street_name",road.name)),bool(road.get_meta("highway",false))])
func _process(delta:float)->void:
 timer+=delta
 if timer<.12:return
 timer=0;queue_redraw()
func _draw()->void:
 if not is_instance_valid(car):return
 draw_style_box(_panel(),Rect2(Vector2.ZERO,size))
 var origin:=Vector2(car.global_position.x,car.global_position.z);var cell:=Vector2i(floori(origin.x/128),floori(origin.y/128));var nearest:=INF
 for x in range(-3,4):
  for z in range(-3,4):
   for segment:Array in cells.get(cell+Vector2i(x,z),[]):
    var a:=Vector2(segment[0].x,segment[0].z);var b:=Vector2(segment[1].x,segment[1].z)
    var closest:=Geometry2D.get_closest_point_to_segment(origin,a,b);var distance:=closest.distance_squared_to(origin)+pow((segment[0].y+segment[1].y)*.5-car.global_position.y,2)
    if distance<nearest:nearest=distance;street=segment[2]
    var p:=(a-origin)*size.x/(span*2)+size*.5;var q:=(b-origin)*size.x/(span*2)+size*.5
    draw_line(p,q,Color("eab55e") if segment[3] else Color("91a7ad"),3 if segment[3] else 2,true)
 var forward:=Vector2(-car.global_basis.z.x,-car.global_basis.z.z);var side:=Vector2(-forward.y,forward.x);var c:=size*.5
 draw_circle(c,10,Color("07131e"));draw_colored_polygon(PackedVector2Array([c+forward*10,c-forward*7+side*6,c-forward*7-side*6]),Color("59ecdb"))
 var font:=ThemeDB.fallback_font
 draw_string(font,Vector2(12,24),"N ↑   LOCAL STREETS",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("f0dfba"))
 var us:bool=GameSettings.unit_system==GameSettings.Units.US
 var bar:float=(160.9344 if us else 100.0)*size.x/(span*2)
 draw_rect(Rect2(13,size.y-22,bar,2),Color("f0dfba"));draw_string(font,Vector2(20+bar,size.y-16),"0.10 MI" if us else "100 m",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f0dfba"))
 if is_instance_valid(street_label):street_label.text=street.to_upper()
func _panel()->StyleBoxFlat:
 var box:=StyleBoxFlat.new();box.bg_color=Color(.025,.055,.075,.93);box.border_color=Color("577279");box.set_border_width_all(1);box.set_corner_radius_all(8);return box
