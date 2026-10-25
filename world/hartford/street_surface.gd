extends StaticBody3D
## One continuous draped surface replaces intersecting street/sidewalk sheets.
func _ready() -> void:
	var city:=get_parent()
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://world/hartford/street_plan.json"))
	var bodies:=city.get_node("Streets").get_children()
	var replaced:=0
	for i in range(mini(bodies.size(),plan.roads.size())):
		if plan.roads[i].elevated:continue
		_disable(bodies[i]);replaced+=1
	_disable(city.get_node("Sidewalks"))
	_disable(city.get_node("Terrain/ContinuousLandAndRiverBanks"))
	city.set_meta("continuous_street_count",replaced)
	print("CONTINUOUS STREETS: ",replaced," street sheets replaced; bridges and highways retained")
func _disable(node: Node) -> void:
	for visual: GeometryInstance3D in node.find_children("*","GeometryInstance3D",true,false):visual.hide()
	for shape: CollisionShape3D in node.find_children("*","CollisionShape3D",true,false):shape.set_deferred("disabled",true)
