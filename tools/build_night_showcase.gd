extends SceneTree
## Prepare native collisions once; never rebuild collision meshes during play.
const DEST := "res://assets/licensed/modern_city_showcase/"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(ResourceLoader.exists(DEST+"street.gltf"), "Prepare and import the licensed street subset first")
	var source: Node3D = load(DEST+"street.gltf").instantiate()
	# Flatten the imported scene before packing editable children. Otherwise the
	# imported instance and explicit children can both be reconstructed at load.
	source.scene_file_path = ""
	var result := Node3D.new(); result.name = "ModernCityStreet"
	root.add_child(result); result.add_child(source); source.name = "Architecture"
	var solids := Node3D.new(); solids.name = "Collision"; result.add_child(solids)
	var triangles := 0; var bodies := 0
	var materials: Dictionary = {}
	for visual: MeshInstance3D in source.find_children("*", "MeshInstance3D", true, false):
		# Local resources serialize the material pass into the native scene instead
		# of referring back to unchanged materials in the imported GLTF cache.
		visual.mesh = visual.mesh.duplicate()
		for index in range(visual.mesh.get_surface_count()):
			var material: Material = visual.mesh.surface_get_material(index)
			if not materials.has(material): materials[material] = material.duplicate()
			material = materials[material]
			visual.mesh.surface_set_material(index, material)
			if material is BaseMaterial3D:
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				var title := material.resource_name.to_lower()
				if material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					if title.contains("leaves") or title.contains("branches") or title.contains("fence"):
						material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
						material.alpha_scissor_threshold = 0.35
					else:
						material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
						if not title.contains("glass"):
							material.grow = true; material.grow_amount = 0.003
				# Imported source has normal and roughness maps; retain both.
				if material.resource_name.begins_with("Road / ") and material.resource_name.to_lower().contains("road"):
					material.roughness = minf(material.roughness, 0.45)
			triangles += visual.mesh.surface_get_array_index_len(index)/3
		var faces := visual.mesh.get_faces()
		if str(visual.name).begins_with("Building"):
			# Ground-floor walls stay solid; roof/upper facade detail has no vehicle collision.
			var lower := PackedVector3Array()
			for i in range(0, faces.size(), 3):
				if minf(faces[i].y, minf(faces[i+1].y, faces[i+2].y)) > 5.0: continue
				lower.append(faces[i]); lower.append(faces[i+1]); lower.append(faces[i+2])
			faces = lower
		if faces.is_empty(): continue
		var shape := ConcavePolygonShape3D.new(); shape.set_faces(faces)
		var body := StaticBody3D.new(); body.name = str(visual.name)+"Solid"
		body.transform = visual.transform; solids.add_child(body)
		var collision := CollisionShape3D.new(); collision.shape = shape; body.add_child(collision)
		bodies += 1
	own(result, result)
	var packed := PackedScene.new(); assert(packed.pack(result) == OK)
	assert(ResourceSaver.save(packed, DEST+"showcase.scn", ResourceSaver.FLAG_COMPRESS) == OK)
	print("SHOWCASE BUILD PASS: ", triangles, " triangles, ", bodies, " prebuilt collision bodies")
	result.free(); quit()
func own(node: Node, target: Node) -> void:
	for child in node.get_children(): child.owner = target; own(child, target)
