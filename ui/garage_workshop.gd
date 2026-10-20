extends Node3D
## Visual workshop dressing, intentionally without gameplay collision or purchases.
var probe: ReflectionProbe
var steel: StandardMaterial3D
var rubber: StandardMaterial3D
func material(color: String,metallic := 0.0,roughness := 0.6) -> StandardMaterial3D:
	var result := StandardMaterial3D.new(); result.albedo_color = Color(color)
	result.metallic = metallic; result.roughness = roughness; return result
func box(label: String,size: Vector3,point: Vector3,mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new(); node.name = label; add_child(node)
	var mesh := BoxMesh.new(); mesh.size = size; node.mesh = mesh; node.material_override = mat; node.position = point
	return node
func _ready() -> void:
	name = "WorkshopDetails"
	var stage := get_parent()
	steel = material("667784",0.8,0.32); rubber = material("12161b",0,0.9)
	var wall := material("17232e",0.12,0.78)
	for label in ["BackWall","SideWall"]: stage.get_node(label).material_override = wall
	var floor := material("26313a",0.15,0.4)
	var path := "res://assets/licensed/modern_city_architecture/sidewalk.tres"
	if ResourceLoader.exists(path):
		floor = load(path).duplicate(); floor.albedo_color = Color("657079"); floor.roughness = 0.38
		floor.metallic = 0.12; floor.uv1_scale = Vector3.ONE*0.6
	stage.get_node("Floor").material_override = floor
	stage.get_node("Platform").material_override = material("283b49",0.4,0.28)
	var environment: Environment = stage.get_node("Environment").environment
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC; environment.ambient_light_energy = 0.4
	environment.glow_enabled = true; environment.glow_intensity = 0.35
	stage.get_node("KeyLight").light_color = Color("dfebf6"); stage.get_node("KeyLight").light_energy = 0.8
	stage.get_node("FillLight").light_color = Color("7caec7"); stage.get_node("FillLight").light_energy = 0.35
	# Sheet-metal ribs, a service bench and storage shelves give the room scale.
	for index in range(29): box("WallRib%02d"%index,Vector3(0.035,3.7,0.045),Vector3(-5.5+index*0.4,1.9,3.9),steel)
	var wood := material("7e6347",0,0.53)
	box("WorkbenchTop",Vector3(2.8,0.11,0.8),Vector3(1.8,1.0,3.3),wood)
	for x in [0.65,2.95]: box("WorkbenchLeg",Vector3(0.09,0.94,0.65),Vector3(x,0.47,3.3),steel)
	box("Pegboard",Vector3(2.8,0.95,0.04),Vector3(1.8,1.9,3.82),material("394955",0.4))
	for index in range(8):
		var tool := box("HangingTool%02d"%index,Vector3(0.045,0.28+index%3*0.06,0.035),Vector3(0.75+index*0.3,1.95,3.77),steel)
		tool.rotation.z = -0.1+index%3*0.1
		box("ToolHead",Vector3(0.13,0.06,0.05),tool.position+Vector3.UP*0.18,steel)
	box("PartsBox",Vector3(0.55,0.25,0.38),Vector3(2.3,1.18,3.3),material("a23029",0.3))
	for index in range(4): box("DrawerHandle",Vector3(1.1,0.025,0.045),Vector3(-3.4,0.2+index*0.24,2.62),steel)
	for height in [0.35,1.15,1.95]: box("Shelf",Vector3(0.8,0.07,2.8),Vector3(-4.4,height,0.8),steel)
	for z in [-0.5,2.1]: box("ShelfPost",Vector3(0.08,2.5,0.08),Vector3(-4.8,1.25,z),steel)
	for index in range(6):
		var tire := MeshInstance3D.new(); tire.name = "SpareTire%d"%index; add_child(tire)
		var mesh := TorusMesh.new(); mesh.inner_radius = 0.19; mesh.outer_radius = 0.36; mesh.rings = 24; mesh.ring_segments = 12
		tire.mesh = mesh; tire.material_override = rubber; tire.position = Vector3(-4.4,0.52+(index/3)*0.8,-0.15+(index%3)*0.7)
	var sign := Label3D.new(); add_child(sign); sign.text = "REVVED\nSTREET WORKS"; sign.font_size = 80
	sign.pixel_size = 0.005; sign.position = Vector3(1.7,2.95,3.85); sign.rotation.y = PI; sign.modulate = Color("eec779")
	for x in [-2.2,2.2]:
		var strip_mat := material("cee7f5"); strip_mat.emission_enabled = true; strip_mat.emission = Color("c7e7fa"); strip_mat.emission_energy_multiplier = 2
		box("OverheadStrip",Vector3(0.15,0.07,4.8),Vector3(x,3.8,0),strip_mat)
		var lamp := SpotLight3D.new(); add_child(lamp); lamp.position = Vector3(x,3.7,-0.5); lamp.look_at(Vector3(0,0.6,0))
		lamp.light_color = Color("ddeeff"); lamp.light_energy = 3; lamp.spot_range = 10; lamp.spot_angle = 52
	probe = ReflectionProbe.new(); probe.name = "WorkshopReflections"; add_child(probe)
	probe.position.y = 2; probe.size = Vector3(14,9,14); probe.box_projection = true; probe.cull_mask = 1; probe.intensity = 0.85
	stage.get_node("Camera").cull_mask = 3
	get_tree().root.get_node("GameSettings").car_style_changed.connect(func():call_deferred("refresh_car"))
	call_deferred("refresh_car")
func refresh_car() -> void:
	for visual: MeshInstance3D in get_parent().get_node("Car").find_children("*","MeshInstance3D",true,false): visual.layers = 2
	probe.visible = false; probe.visible = true
