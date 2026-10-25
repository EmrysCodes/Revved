@tool
extends "res://world/hartford/kit_instances.gd"
func _ready()->void:
 physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
 super._ready()
 if str(name).ends_with("_near"):visibility_range_end=160;visibility_range_end_margin=0
 elif str(name).ends_with("_far"):visibility_range_begin=160;visibility_range_begin_margin=0
 if not Engine.is_editor_hint() and OS.has_feature("mobile"):
  if str(name).ends_with("_near"):visible=false
  elif str(name).ends_with("_far"):visibility_range_begin=0;visibility_range_end=850
