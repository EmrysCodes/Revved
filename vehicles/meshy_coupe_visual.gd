extends Node3D
## Prepared modular meshes exported from the user's Meshy assets in Blender.
const STYLE=preload("res://vehicles/s64_compact_visual.gd")
var model:Node3D
var pivots:Array[Node3D]=[]
var roll:=0.0
var wheel_choice:=-1
func _ready() -> void:
	model=load("res://assets/licensed/meshy_coupe/meshy_parts.glb").instantiate();add_child(model)
	for i in range(4):
		var pivot:=Node3D.new();pivot.name=["FrontLeft","FrontRight","RearLeft","RearRight"][i];add_child(pivot)
		pivot.position=Vector3(-.82 if i%2==0 else .82,.32,-1.27 if i<2 else 1.3)
		var spin:=Node3D.new();spin.name="Spin";pivot.add_child(spin);pivots.append(pivot)
	apply_saved_style()
func apply_saved_style() -> void:
	if model==null:return
	var choices={"FrontBumper":GameSettings.front_bumper,"RearBumper":GameSettings.rear_bumper,"SideSkirts":GameSettings.side_skirts,"Hood":GameSettings.car_hood,"Spoiler":GameSettings.car_spoiler}
	for child:Node3D in model.get_children():
		var key:=str(child.name).split("_")
		child.visible=key[0]=="Core"
		if choices.has(key[0]) and key.size()>1:
			child.visible=int(key[1])==choices[key[0]] or int(key[1])==0
			if key[0]=="Spoiler" and GameSettings.car_spoiler==0:child.hide()
	if wheel_choice!=GameSettings.car_wheels:
		var template:Node3D=model.get_node("Wheel_%d"%(GameSettings.car_wheels%2))
		for pivot in pivots:
			var spin:=pivot.get_node("Spin")
			for old in spin.get_children():spin.remove_child(old);old.queue_free()
			var copy:Node3D=template.duplicate();spin.add_child(copy);copy.show()
			if pivot.name.ends_with("Right"):copy.rotation.y=PI
		wheel_choice=GameSettings.car_wheels
	for mesh:MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		for surface in range(mesh.mesh.get_surface_count()):
			var source:Material=mesh.mesh.surface_get_material(surface)
			if source==null:continue
			mesh.set_surface_override_material(surface,null)
			if source.resource_name.begins_with("Car"):
				if GameSettings.car_vinyl>0:
					var vinyl:=ShaderMaterial.new();vinyl.shader=STYLE.VINYL_SHADER
					vinyl.set_shader_parameter("base_color",STYLE.PAINT_COLORS[GameSettings.car_paint])
					vinyl.set_shader_parameter("vinyl_color",STYLE.VINYL_COLORS[GameSettings.car_vinyl_color])
					vinyl.set_shader_parameter("vinyl_style",GameSettings.car_vinyl)
					vinyl.set_shader_parameter("base_metallic",.35);vinyl.set_shader_parameter("base_roughness",.4)
					vinyl.set_shader_parameter("mesh_to_car",global_transform.affine_inverse()*mesh.global_transform)
					mesh.set_surface_override_material(surface,vinyl)
				else:
					var paint:StandardMaterial3D=source.duplicate();paint.cull_mode=BaseMaterial3D.CULL_DISABLED;paint.albedo_color=STYLE.PAINT_COLORS[GameSettings.car_paint];paint.roughness=.4;paint.metallic=.35
					mesh.set_surface_override_material(surface,paint)
			elif source.resource_name.begins_with("Rim") and GameSettings.car_wheels>=2:
				var dark:StandardMaterial3D=source.duplicate();dark.albedo_color=Color(.035,.04,.05);mesh.set_surface_override_material(surface,dark)
			if "Spoiler" in str(mesh.name) and GameSettings.spoiler_finish==1:
				var satin:=StandardMaterial3D.new();satin.albedo_color=Color(.02,.025,.03);satin.roughness=.6;mesh.set_surface_override_material(surface,satin)
	reset_physics_interpolation()
func update_wheels(steering:float,speed:float,delta:float) -> void:
	roll=wrapf(roll-speed*delta/.32,-PI,PI)
	for i in range(pivots.size()):
		pivots[i].rotation.y=-steering*deg_to_rad(30) if i<2 else 0.0
		pivots[i].get_node("Spin").rotation.x=roll
func reset_wheels() -> void:
	roll=0;update_wheels(0,0,0)
