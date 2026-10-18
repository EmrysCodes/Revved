extends SceneTree
## Verify the retired Meshy visual remains loadable as an alternate asset.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var visual: Node3D = load("res://vehicles/jdm_coupe_visual.tscn").instantiate()
	root.add_child(visual)
	var meshes: Array[Node] = visual.find_children("*", "MeshInstance3D", true, false)
	assert(meshes.size() == 1)
	var mesh: MeshInstance3D = meshes[0]
	var bounds: AABB = mesh.global_transform * mesh.get_aabb()
	assert(absf(bounds.size.z - 4.0) < 0.02)
	assert(absf(bounds.position.y) < 0.01)
	assert(is_equal_approx(visual.get_node("ImportedModel").rotation.y, -PI / 2.0))
	print("PASS: retired Meshy model remains loadable, normalized, and oriented")
	quit()
