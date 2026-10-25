@tool
extends Node3D
@export var world_title := "My REVVED City"
var car: CharacterBody3D
var world_header:Label
var _timer:=0.0
var _junction_hash:=0
func _process(delta:float)->void:
 if not Engine.is_editor_hint():return
 _timer+=delta
 if _timer<.5:return
 _timer=0
 var signatures:Array=[]
 for item:Node3D in find_children("*","Node3D",true,false):
  if str(item.get_meta("workshop_asset","")).begins_with("junction") and not item.has_meta("workshop_generated"):signatures.append(item.global_transform)
 var next:=hash(signatures)
 if next==_junction_hash:return
 _junction_hash=next
 for road:Node in get_node("Roads").get_children():
  if road.has_method("rebuild"):road.rebuild()
func _ready() -> void:
 set_meta("workshop_world",true)
 if Engine.is_editor_hint():return
 var start:Node3D=get_node_or_null("PlayerStart")
 if not start:push_error("Handbuilt world needs a PlayerStart marker");return
 if not has_meta("finish_version"):get_tree().root.get_node("StreetProfile").launch_mode="builder"
 car=load("res://vehicles/arcade_car.tscn").instantiate();car.name="PlayerCar"
 car.transform=global_transform.affine_inverse()*start.global_transform;add_child(car)
 car.get_node("CameraArm/FollowCamera").far=2500
 var canvas:=CanvasLayer.new();add_child(canvas)
 var label:=Label.new();canvas.add_child(label);label.position=Vector2(20,16)
 world_header=label
 label.text=world_title.to_upper()+" / WORLD WORKSHOP PLAYTEST\nR recover  /  Esc pause  /  Stop play to keep building"
 if has_meta("finish_version"):label.text=world_title.to_upper()+"\nR recover  /  Esc pause";label.add_theme_font_size_override("font_size",14)
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.size=Vector2(minf(760,get_viewport().get_visible_rect().size.x*.62),85)
 get_viewport().size_changed.connect(func():label.size.x=minf(760,get_viewport().get_visible_rect().size.x*.62))
 label.add_theme_font_size_override("font_size",17)
 if has_meta("finish_version"):label.add_theme_font_size_override("font_size",14)
 label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_x",2);label.add_theme_constant_override("shadow_offset_y",2)
