extends RefCounted
## Two complete district chapters; the next two districts remain a roadmap, not fake buttons.
const REGIONAL=preload("res://core/regional_campaign.gd")
const CHAPTERS=REGIONAL.CHAPTERS
const EVENTS:Array[Dictionary]=REGIONAL.EVENTS
static func event(id:String) -> Dictionary:
	for item in EVENTS:
		if item.id==id:return item
	return EVENTS[0]
static func route_path(id:String) -> String:
	var item:=event(id)
	return item.get("route","res://racing/events/"+item.id+".json")
static func won(results:Dictionary,id:String) -> bool:
	return int(results.get(id,{}).get("wins",0))>0
static func chapter_wins(results:Dictionary,chapter:int) -> int:
	var count:=0
	for item in EVENTS:
		if item.chapter==chapter and won(results,item.id):count+=1
	return count
static func unlock_reason(id:String,results:Dictionary) -> String:
	# Won events remain replayable, including saves from the former open-tier career.
	if won(results,id):return ""
	for item in EVENTS:
		if item.id==id:return ""
		if not won(results,item.id):return "Win %s to continue the story."%item.name
	return "Unknown event."
static func next_event(results:Dictionary) -> String:
	for item in EVENTS:
		if not won(results,item.id):return item.id
	return ""
static func wins(results:Dictionary) -> int:
	var total:=0
	for item in EVENTS:
		if won(results,item.id):total+=1
	return total
static func complete(results:Dictionary) -> bool:
	return next_event(results).is_empty()
