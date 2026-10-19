extends RefCounted
## Two complete district chapters; the next two districts remain a roadmap, not fake buttons.
const CHAPTERS:=[
	{"name":"IGNITION","district":"Downtown / Capitol","crew":"CAPITOL COLLECTIVE","leader":"Mara Voss","color":Color("ffcb5a"),"story":"Earn your place around Main, Pearl and Asylum. Beat Mara to take the bridge east."},
	{"name":"AFTER THE RIVER","district":"Eastside / Founders","crew":"RIVER GHOSTS","leader":"Inez Vale","color":Color("56dcea"),"story":"A new crew owns Pitkin and the industrial yards. Win their streets, then settle it across both banks."}
]
const EVENTS:Array[Dictionary]=[
	{"id":"capital_run","name":"Capital Run","kind":"Street sprint","chapter":0,"tier":0,"cash":1100,"rivals":3,"laps":1,"point":Vector2(-58.8161582946777,339.992126464844),"brief":"Mara: Anyone can floor it. Show me you can read the city.","route":"res://racing/capital_run_route.json"},
	{"id":"pearl_dash","name":"Pearl After Dark","kind":"Street sprint","chapter":0,"tier":0,"cash":900,"rivals":3,"laps":1,"point":Vector2(-687.467,-77.124),"brief":"Thread Pearl, Trumbull and the shop blocks. A clean line beats a big engine."},
	{"id":"bushnell_clock","name":"Parkside Deadline","kind":"Time attack","chapter":0,"tier":0,"cash":1000,"rivals":0,"laps":1,"point":Vector2(-305.0,190.0),"brief":"The clock is the only rival. Stay on the park drive and carry speed smoothly."},
	{"id":"asylum_circuit","name":"Asylum Nights","kind":"Circuit","chapter":0,"tier":1,"cash":1600,"rivals":3,"laps":2,"point":Vector2(-33.354,179.593),"brief":"Two laps through office blocks and late-night storefronts. Consistency matters."},
	{"id":"columbus_sprint","name":"Riverline","kind":"Street sprint","chapter":0,"tier":1,"cash":1400,"rivals":3,"laps":1,"point":Vector2(423.097,-450.229),"brief":"A fast riverfront run with tighter streets at each end. Brake before the turn."},
	{"id":"northbound_run","name":"Northbound Heat","kind":"Street sprint","chapter":0,"tier":1,"cash":1500,"rivals":3,"laps":1,"point":Vector2(16.605,-998.827),"brief":"The north-end streets open up, but the route comes back through downtown."},
	{"id":"downtown_endurance","name":"Capital Endurance","kind":"Circuit","chapter":0,"tier":2,"cash":2500,"rivals":3,"laps":3,"point":Vector2(-33.354,179.593),"brief":"Three laps. Protect the lead through every junction instead of gambling on one corner."},
	{"id":"capitol_duel","name":"Voss / One on One","kind":"Crew duel","chapter":0,"tier":2,"cash":2200,"rivals":1,"laps":1,"point":Vector2(-760.595,-266.292),"brief":"Mara: Just you and me. No pack to hide in."},
	{"id":"capitol_crown","name":"Crown of the Capitol","kind":"District final","chapter":0,"tier":3,"cash":5000,"rivals":3,"laps":1,"point":Vector2(-33.354,179.593),"brief":"Win the Capitol Collective's final and the River Ghosts will open their event board."},
	{"id":"founders_entry","name":"Across the Water","kind":"Bridge sprint","chapter":1,"tier":0,"cash":1800,"rivals":3,"laps":1,"point":Vector2(397.595,0.16),"brief":"Inez: You own the west bank. That doesn't mean you know our side."},
	{"id":"pitkin_dash","name":"Pitkin Pulse","kind":"Street sprint","chapter":1,"tier":0,"cash":1900,"rivals":3,"laps":1,"point":Vector2(1137.0,180.0),"brief":"Storefronts give way to apartment courts. Follow the GPS through the neighborhood links."},
	{"id":"river_clock","name":"Founders Deadline","kind":"Time attack","chapter":1,"tier":0,"cash":2000,"rivals":0,"laps":1,"point":Vector2(1590.0,-180.0),"brief":"Hit every gate before the target time. The last sector rewards a tidy braking line."},
	{"id":"main_street_circuit","name":"Main Street Midnight","kind":"Circuit","chapter":1,"tier":1,"cash":2800,"rivals":3,"laps":2,"point":Vector2(1578.406,277.772),"brief":"Two laps through Main, Hartland and Jayce. Learn where the road tightens."},
	{"id":"foundry_sprint","name":"Night Shift","kind":"Street sprint","chapter":1,"tier":1,"cash":2500,"rivals":3,"laps":1,"point":Vector2(1445.0,880.0),"brief":"Loading yards and service streets make this the most technical eastside run."},
	{"id":"silver_lane_rush","name":"Silver Lane Rush","kind":"Street sprint","chapter":1,"tier":1,"cash":2600,"rivals":3,"laps":1,"point":Vector2(1560.0,830.0),"brief":"Use the broad approach, then settle the car for the neighborhood corners."},
	{"id":"eastside_endurance","name":"River Ghost Endurance","kind":"Circuit","chapter":1,"tier":2,"cash":3800,"rivals":3,"laps":3,"point":Vector2(1578.406,277.772),"brief":"Three laps through the eastside. Find a rhythm that lasts."},
	{"id":"river_duel","name":"Inez / Ghost Line","kind":"Crew duel","chapter":1,"tier":2,"cash":3500,"rivals":1,"laps":1,"point":Vector2(1435.0,500.0),"brief":"Inez: Traffic, turns, the river. Let's see what you actually learned."},
	{"id":"eastside_crown","name":"Two Banks / One Legacy","kind":"District final","chapter":1,"tier":3,"cash":8500,"rivals":3,"laps":1,"point":Vector2(1137.0,180.0),"brief":"The final connects both districts. Win it to complete the first two chapters of Street Legacy."}
]
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
	var item:=event(id)
	if item.chapter==1 and not won(results,"capitol_crown"):return "Win Crown of the Capitol to cross into chapter two."
	var wins:=chapter_wins(results,item.chapter)
	var required:int=[0,2,4,6][item.tier]
	if wins<required:return "Win %d different %s events (%d / %d)."%[required,"downtown" if item.chapter==0 else "eastside",wins,required]
	return ""
static func complete(results:Dictionary) -> bool:
	return won(results,"eastside_crown")
