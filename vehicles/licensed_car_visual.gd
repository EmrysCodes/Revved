extends Node3D
## Pivots wrap the original wheel meshes; body geometry stays unchanged.
var roll:=0.0
func update_wheels(steering: float,speed: float,delta: float) -> void:
	roll=wrapf(roll-speed*delta/maxf(float(get_meta("wheel_radius",0.32)),0.1),-PI,PI)
	for pivot:Node3D in get_node("Geometry").get_children():
		if not pivot.has_node("Spin"): continue
		pivot.rotation.y=-steering*deg_to_rad(30) if pivot.name.begins_with("Front") else 0.0
		pivot.get_node("Spin").rotation.x=-roll # Source faces +Z beneath a 180-degree parent.
func reset_wheels() -> void:
	roll=0.0
	update_wheels(0,0,0)
