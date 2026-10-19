@tool
extends MultiMeshInstance3D
## Keep placements editable and serializable even when the city is built headlessly.
## The dummy renderer does not retain MultiMesh buffers when saving a scene.
@export var placements: Array[Transform3D] = []
func _ready() -> void:
	if multimesh==null:
		return
	multimesh.instance_count=placements.size()
	for i in range(placements.size()):
		multimesh.set_instance_transform(i,placements[i])
