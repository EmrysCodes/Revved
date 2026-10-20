extends "res://tools/build_city_art.gd"
## Prepare two licensed tree species with the same normalized near/far pipeline.
func run() -> void:
	for kind in ["tree_ash","tree_linden"]:
		var mesh := prepare(kind)
		await proxy(mesh,kind)
	print("CITY TREES BUILD PASS: two textured species with distant proxies")
	quit()
