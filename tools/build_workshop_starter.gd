extends SceneTree
const CATALOG=preload("res://world/workshop/catalog.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	DirAccess.make_dir_recursive_absolute("res://world/handbuilt")
	var factory:=preload("res://world/workshop/world_factory.gd")
	var world:=factory.create("Workshop / Starter City")
	world.get_node("PlayerStart").position=Vector3(-70,.55,20)
	var road:=Node3D.new();road.set_script(load("res://world/workshop/road.gd"));road.name="StarterLoop";road.closed=true
	road.points=PackedVector3Array([Vector3(-70,.04,45),Vector3(-70,.04,-45),Vector3(-45,.04,-70),Vector3(45,.04,-70),Vector3(70,.04,-45),Vector3(70,.04,45),Vector3(45,.04,70),Vector3(-45,.04,70)])
	world.get_node("Roads").add_child(road);CATALOG.own(road,world)
	var ramp:=Node3D.new();ramp.set_script(load("res://world/workshop/road.gd"));ramp.name="RaisedStreet";ramp.points=PackedVector3Array([Vector3(76,.04,0),Vector3(110,.04,0),Vector3(142,6.04,0),Vector3(164,6.04,0)])
	world.get_node("Roads").add_child(ramp);CATALOG.own(ramp,world)
	for entry:Array in [["junction",Vector3(76,.04,0),0],["family_0",Vector3(-40,0,-34),0],["family_2",Vector3(3,0,-38),0],["family_5",Vector3(38,0,-34),0],["family_8",Vector3(-35,0,30),0],["family_4",Vector3(30,0,35),0],["tree_ash",Vector3(-48,0,2),0],["tree_linden",Vector3(0,0,30),0],["bench",Vector3(-48,0,-12),-PI/2],["planter",Vector3(-48,0,12),0],["car_2",Vector3(-38,0,5),PI/2]]:
		var node:=CATALOG.create(entry[0]);node.position=entry[1];node.rotation.y=entry[2]
		world.get_node("Buildings" if str(entry[0]).begins_with("family") else "Props").add_child(node);CATALOG.own(node,world)
	for p:Vector3 in [Vector3(-60,0,-20),Vector3(-60,0,35),Vector3(0,0,-60),Vector3(60,0,28),Vector3(0,0,60)]:
		var lamp:=CATALOG.create("lamp");lamp.position=p;world.get_node("Props").add_child(lamp);CATALOG.own(lamp,world)
	var deck:=StaticBody3D.new();deck.name="RaisedStreetDeck";deck.position=Vector3(164,5.69,0);deck.set_meta("workshop_item",true)
	world.get_node("Props").add_child(deck)
	var mesh:=BoxMesh.new();mesh.size=Vector3(26,.7,24);var material:=StandardMaterial3D.new();material.albedo_color=Color("48565e");material.roughness=.9;mesh.material=material
	var visual:=MeshInstance3D.new();visual.mesh=mesh;deck.add_child(visual)
	var shape:=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=mesh.size;deck.add_child(shape);CATALOG.own(deck,world)
	assert(factory.save(world,"res://world/handbuilt/workshop_starter.tscn")==OK)
	world.free();print("WORKSHOP STARTER PASS: editable scene / curved loop / ramp / asset examples");quit()
