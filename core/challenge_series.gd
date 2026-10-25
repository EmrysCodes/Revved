extends RefCounted
## Offline score challenges. No entry fees or career rewards.
const SERIES:Array[Dictionary]=[
	{"name":"DOWNTOWN TRIPLE","description":"Three city races. Keep your points across the night.","events":["capital_run","asylum_circuit","capitol_crown"]},
	{"name":"COAST AFTER HOURS","description":"Leave the grid behind for three coastal rounds.","events":["pitkin_dash","main_street_circuit","eastside_crown"]},
	{"name":"CREW SHOWDOWN","description":"A city sprint, a coastal sprint, and the whole-region finale.","events":["northbound_run","silver_lane_rush","eastside_crown"]}
]
static func points(place:int)->int:return [10,6,3,1][clampi(place-1,0,3)]
static func medal(score:int)->String:return "GOLD" if score>=24 else ("SILVER" if score>=18 else ("BRONZE" if score>=12 else "FINISHER"))
