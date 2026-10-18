extends SceneTree
## Rebuild with Godot --headless --path . --script res://tools/build_s64_parts.gd
## Clip the CC0 source surfaces into disjoint regions in assembled car coordinates.
const DEST := "res://assets/vehicles/s64_compact/modular/"
const OFFSETS := [Vector3(0, 0.080392, 0.14696), Vector3(0, 0.0542, 0.07218), Vector3(0, 0.0241, -0.03331)]
const PARTS := ["Core", "FrontBumper", "RearBumper", "SideSkirts"]

func _initialize() -> void:
	call_deferred("_build")

func _build() -> void:
	for kit in range(3):
		var source: Node3D = load("res://assets/vehicles/s64_compact/S64Compact_Body_%d.glb" % (kit + 1)).instantiate()
		root.add_child(source)
		var assembly := Transform3D(Basis(Vector3.UP, PI / 2.0).scaled(Vector3.ONE * 1.218064), OFFSETS[kit])
		var output: Array[ArrayMesh] = [ArrayMesh.new(), ArrayMesh.new(), ArrayMesh.new(), ArrayMesh.new()]
		for mesh: MeshInstance3D in source.find_children("*", "MeshInstance3D", true, false):
			var transform_to_car: Transform3D = assembly * mesh.global_transform
			var normal_basis := transform_to_car.basis.inverse().transposed()
			for surface in range(mesh.mesh.get_surface_count()):
				var data: Array = mesh.mesh.surface_get_arrays(surface)
				var buckets: Array = [[], [], [], []]
				var indices: PackedInt32Array = data[Mesh.ARRAY_INDEX]
				for triangle in range(0, indices.size(), 3):
					var polygon: Array = []
					for corner in range(3):
						var vertex: int = indices[triangle + corner]
						polygon.append([transform_to_car * data[Mesh.ARRAY_VERTEX][vertex], (normal_basis * data[Mesh.ARRAY_NORMAL][vertex]).normalized(), data[Mesh.ARRAY_TEX_UV][vertex]])
					var height := split(polygon, 1, 0.62)
					buckets[0].append(height[1])
					var front := split(height[0], 2, -1.5)
					buckets[1].append(front[0])
					var rear := split(front[1], 2, 1.5)
					buckets[2].append(rear[1])
					var sill := split(rear[0], 1, 0.40)
					buckets[0].append(sill[1])
					var left := split(sill[0], 0, -0.60)
					buckets[3].append(left[0])
					var right := split(left[1], 0, 0.60)
					buckets[0].append(right[0])
					buckets[3].append(right[1])
				for part in range(4):
					var builder := SurfaceTool.new()
					builder.begin(Mesh.PRIMITIVE_TRIANGLES)
					builder.set_material(mesh.mesh.surface_get_material(surface))
					var count: int = 0
					for polygon: Array in buckets[part]:
						for corner in range(1, polygon.size() - 1):
							var a: Vector3 = polygon[0][0]
							var b: Vector3 = polygon[corner][0]
							var c: Vector3 = polygon[corner + 1][0]
							if (b - a).cross(c - a).length_squared() < 0.000000000001:
								continue
							for vertex in [polygon[0], polygon[corner], polygon[corner + 1]]:
								builder.set_normal(vertex[1])
								builder.set_uv(vertex[2])
								builder.add_vertex(vertex[0])
								count += 1
					if count > 0:
						builder.generate_tangents()
						builder.index()
						builder.commit(output[part])
		for part in range(4):
			assert(output[part].get_surface_count() > 0)
			assert(ResourceSaver.save(output[part], DEST + "%s_%d.res" % [PARTS[part], kit]) == OK)
		source.free()
	print("PASS: generated 12 modular body meshes from three CC0 kits")
	quit()

func split(polygon: Array, axis: int, boundary: float) -> Array:
	var low: Array = []
	var high: Array = []
	if polygon.is_empty():
		return [low, high]
	var previous: Array = polygon[-1]
	for current: Array in polygon:
		var before: float = previous[0][axis] - boundary
		var after: float = current[0][axis] - boundary
		if (before < 0.0 and after > 0.0) or (before > 0.0 and after < 0.0):
			var weight: float = before / (before - after)
			var intersection := [previous[0].lerp(current[0], weight), previous[1].lerp(current[1], weight).normalized(), previous[2].lerp(current[2], weight)]
			low.append(intersection)
			high.append(intersection)
		if after <= 0.0:
			low.append(current)
		if after >= 0.0:
			high.append(current)
		previous = current
	return [low, high]
