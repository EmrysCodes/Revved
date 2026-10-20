extends SceneTree
func _initialize():call_deferred("run")
func run():
 var gs=root.get_node("GameSettings");var saved=[gs.vehicle_id,gs.car_paint]
 gs.vehicle_id=5
 var model:Node3D=load("res://vehicles/s64_compact_visual.tscn").instantiate();root.add_child(model)
 var original_meshes:Array=[]
 for visual:MeshInstance3D in model._licensed_model.find_children("*","MeshInstance3D",true,false):original_meshes.append(visual.mesh)
 var colors:Array=[]
 for color in range(6):
  gs.car_paint=color;model.apply_saved_style()
  var meshes:Array=[];var paint:Color
  for visual:MeshInstance3D in model._licensed_model.find_children("*","MeshInstance3D",true,false):
   meshes.append(visual.mesh)
   for index in range(visual.mesh.get_surface_count()):
    var mat:Material=visual.get_surface_override_material(index)
    if mat is ShaderMaterial:paint=mat.get_shader_parameter("paint_color")
  assert(meshes==original_meshes,"Paint changes retain factory geometry")
  colors.append(paint)
 assert(colors.size()==6 and colors[1]!=colors[2] and colors[3]!=colors[4],"Distinct paint finishes")
 model.free();gs.vehicle_id=saved[0];gs.car_paint=saved[1]
 print("CAR 05 PAINT PASS: six finishes, unchanged factory meshes");quit()
