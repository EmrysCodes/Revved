extends RefCounted
const PACK_PATH:="res://assets/licensed/arcade_cars/ready/Car_%d.scn"
const MESHY_PATH:="res://assets/licensed/meshy_coupe/meshy_coupe.tscn"
static func path_for(id: int) -> String:
	return MESHY_PATH if id==11 else (PACK_PATH%id if id>0 and id<=10 else "")
static func available(id: int) -> bool:
	return id==0 or ResourceLoader.exists(path_for(id))
static func title(id: int) -> String:
	return "Meshy JDM Coupe" if id==11 else ("S64 Compact" if id==0 else "Arcade Car %02d"%id)
static func customization(id: int) -> bool:
	return id in [0,11]
