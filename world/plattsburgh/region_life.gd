extends Node3D
## Ambient population follows closed circuits in the actual regional road graph.
var agents:Array[CharacterBody3D]=[]
var walkers:Array[Dictionary]=[]
var clock:=0.0
func _ready()->void:
 call_deferred("populate")
func populate()->void:
 if get_parent().get_meta("disable_population",false):return
 var d:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://world/plattsburgh/data/population.json"))
 for source:Array in d.traffic_routes:
  for reverse:bool in [false,true]:
   if agents.size()>=(6 if OS.has_feature("mobile") else 16):break
   var line:=PackedVector3Array()
   for p:Array in source:line.append(Vector3(p[0],p[1],p[2]))
   if reverse:line.reverse()
   # Round each bend inside the junction patch while retaining closed topology.
   for pass_index in range(2):
    var rounded:=PackedVector3Array()
    for i in range(line.size()-1):rounded.append(line[i].lerp(line[i+1],.25));rounded.append(line[i].lerp(line[i+1],.75))
    rounded.append(rounded[0]);line=rounded
   var distances:=PackedFloat64Array([0.0])
   for i in range(1,line.size()):distances.append(distances[-1]+line[i-1].distance_to(line[i]))
   var car:=CharacterBody3D.new();car.name="CoastTraffic_%s"%agents.size();car.set_script(load("res://world/traffic_car.gd"));car.fleet=self;car.path=line;car.distances=distances;car.route_length=distances[-1];car.along=distances[-1]*.25;car.serial=agents.size();car.cruise=8.5+agents.size()%4;car.lane=1.65;add_child(car);agents.append(car)
 var count:=0
 for road:Node3D in get_parent().get_node("Roads").get_children():
  if not road.has_meta("workshop_road") or road.sidewalk_width<1.5 or road.points.size()<8:continue
  if road.points[0].length()>2000 or count>=(10 if OS.has_feature("mobile") else 30):continue
  var i:=int(road.points.size()/2);var a:Vector3=road.points[maxi(1,i-2)];var b:Vector3=road.points[mini(road.points.size()-2,i+2)];var direction:Vector3=(b-a).normalized();var side:=direction.cross(Vector3.UP);var offset:Vector3=side*(road.road_width*.5+road.sidewalk_width*.6)+Vector3.UP*.12
  var model:Node3D=load("res://assets/people/quaternius/"+["Casual_2","Casual_Hoodie","Suit","Worker","Punk"][count%5]+".gltf").instantiate();add_child(model);model.position=a+offset
  var animations:=model.find_children("*","AnimationPlayer",true,false)
  if not animations.is_empty():
   var animation:AnimationPlayer=animations[0]
   if animation.has_animation("Walk"):animation.get_animation("Walk").loop_mode=Animation.LOOP_LINEAR;animation.play("Walk")
  walkers.append({"node":model,"a":a+offset,"b":b+offset,"phase":count*3.0});count+=1
 set_meta("traffic_count",agents.size());set_meta("pedestrian_count",walkers.size());print("COAST LIFE traffic=",agents.size()," pedestrians=",walkers.size())
 var audio:=Node3D.new();audio.set_script(load("res://audio/traffic_audio.gd"));add_child(audio)
func should_stop(_point:Vector3,_direction:Vector3)->bool:return false
func _process(delta:float)->void:
 clock+=delta
 if not is_instance_valid(get_parent().car):return
 for walker:Dictionary in walkers:
  var length:float=walker.a.distance_to(walker.b);var progress:=fposmod(clock+float(walker.phase),maxf(1,length*2));var forward:bool=progress<length;var ratio:float=progress/length if forward else 2-progress/length
  var model:Node3D=walker.node;model.position=walker.a.lerp(walker.b,clampf(ratio,0,1));model.rotation.y=atan2(-(walker.b.x-walker.a.x),-(walker.b.z-walker.a.z))+(0 if forward else PI)
  model.visible=model.global_position.distance_squared_to(get_parent().car.global_position)<150*150
