extends RefCounted
## Original, fixed-order Last Light screenplay. No dialogue choices affect rewards.
static var _data:Dictionary={}
static func data()->Dictionary:
	if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string("res://story/last_light.json"))
	return _data
static func scene(key:String)->Dictionary:
	return data().scenes.get(key,{})
static func cast(speaker:String)->Dictionary:
	return data().cast.get(speaker,{})
static func line_text(line:Dictionary,driver:String)->String:
	return str(line.text).replace("{driver}",driver)
static func unlocked(key:String,seen:Dictionary)->bool:
	return bool(seen.get(key,false))
