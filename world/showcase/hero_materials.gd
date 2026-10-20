extends RefCounted
## Local finish shared by normal play, menus and the visual study; source art stays untouched.
static func apply(model: Node3D, body_color := Color(0.08,0.25,0.45)) -> void:
	var cache: Dictionary = {}
	for visual: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for surface in range(visual.mesh.get_surface_count()):
			var original: Material = visual.mesh.surface_get_material(surface)
			if not original is BaseMaterial3D: continue
			if cache.has(original):
				visual.set_surface_override_material(surface, cache[original]); continue
			var title := original.resource_name.to_lower()
			var result: Material
			if title.begins_with("body"):
				var paint := ShaderMaterial.new()
				paint.shader = preload("res://vehicles/showcase_paint.gdshader")
				if original.albedo_texture: paint.set_shader_parameter("source_texture", original.albedo_texture)
				paint.set_shader_parameter("source_tint", original.albedo_color)
				paint.set_shader_parameter("paint_color", body_color)
				result = paint
			else:
				var material: BaseMaterial3D = original.duplicate()
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				if title == "screens":
					material.albedo_texture = null
					material.albedo_color = Color("101d29")
					material.metallic = 0.25; material.roughness = 0.08
					material.clearcoat_enabled = true; material.clearcoat = 1.0; material.clearcoat_roughness = 0.1
				elif title == "tyre":
					material.albedo_color = Color("34383d"); material.metallic = 0.0; material.roughness = 0.88
				elif title == "wheels" or title == "exhaust":
					material.metallic = 0.88; material.roughness = 0.25
				elif title.contains("red light") or title.contains("back light"):
					material.emission_enabled = true; material.emission = Color("ff3022"); material.emission_energy_multiplier = 1.5
				elif title in ["light", "front light"]:
					material.emission_enabled = true; material.emission = Color("d8eaff"); material.emission_energy_multiplier = 2.5
				elif title in ["carbon", "grill"]:
					material.metallic = 0.1; material.roughness = 0.56
				result = material
			cache[original] = result
			visual.set_surface_override_material(surface, result)
