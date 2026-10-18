extends Control
## North-up district map. Coordinates match the authored road network.
@onready var city: Node3D = get_node("../../..")
func _process(_delta: float) -> void:
	queue_redraw()
func _point(point: Vector3) -> Vector2:
	return Vector2(12, 26) + Vector2(point.x + 720.0, point.z + 720.0) / 1440.0 * Vector2(size.x - 24.0, size.y - 38.0)
func _draw() -> void:
	if not is_instance_valid(city) or not is_instance_valid(city.car):
		return
	draw_style_box(get_theme_stylebox("panel", "Panel"), Rect2(Vector2.ZERO, size))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.04, 0.055, 0.92))
	draw_string(get_theme_default_font(), Vector2(12, 18), "DOWNTOWN   /   N ↑", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.85, 0.92, 1))
	for group in [city.map_roads, city.highway_roads, city.ramp_roads]:
		var color := Color(0.5, 0.57, 0.65)
		if group == city.highway_roads:
			color = Color(0.1, 0.8, 0.95)
		elif group == city.ramp_roads:
			color = Color(1, 0.7, 0.2)
		for road: PackedVector3Array in group:
			var points := PackedVector2Array()
			for point in road:
				points.append(_point(point))
			draw_polyline(points, color, 2.0, true)
	var marker := _point(city.car.position)
	var direction := Vector2(-city.car.global_basis.z.x, -city.car.global_basis.z.z)
	var side := Vector2(-direction.y, direction.x)
	draw_colored_polygon(PackedVector2Array([marker + direction * 7.0, marker - direction * 4.0 + side * 4.0, marker - direction * 4.0 - side * 4.0]), Color(1, 0.3, 0.15))
