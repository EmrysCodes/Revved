extends RefCounted
## Background perks affect career reputation only, never vehicle performance.
const BACKGROUNDS: Array[Dictionary]=[
	{"name":"Independent","story":"You arrived with your own car and no crew. Every result speaks for itself.","perk":"Steady rewards: no bonus or penalty.","rule":"neutral"},
	{"name":"Club Racer","story":"Weekend competition taught you to chase the podium, but the streets expect results.","perk":"+10% reputation for 1st–2nd; −10% for 3rd–4th.","rule":"podium"},
	{"name":"Neighborhood Favorite","story":"Your block backs you even on a rough night. Winning is expected; showing up matters.","perk":"+10% reputation for 3rd–4th; −10% for 1st–2nd.","rule":"underdog"},
	{"name":"Workshop Apprentice","story":"Long nights fixing cars taught you precision. Clean runs earn respect; recovery costs it.","perk":"+10% reputation without recovery; −10% if you recover.","rule":"clean"},
	{"name":"Second Wind","story":"You have rebuilt your life before. A setback is where your story starts moving.","perk":"+10% reputation after recovery; −10% without recovery. Recovery still costs race time.","rule":"comeback"}
]
static func multiplier(background: int,place: int,recoveries: int) -> float:
	match clampi(background,0,BACKGROUNDS.size()-1):
		1: return 1.1 if place<=2 else 0.9
		2: return 0.9 if place<=2 else 1.1
		3: return 1.1 if recoveries==0 else 0.9
		4: return 0.9 if recoveries==0 else 1.1
	return 1.0
static func portrait(presentation: int,index: int) -> AtlasTexture:
	var texture: Texture2D=load("res://assets/drivers/"+("men" if presentation==0 else "women")+".png")
	var cell:=Vector2(texture.get_width()/5.0,texture.get_height()/2.0)
	var atlas:=AtlasTexture.new();atlas.atlas=texture
	atlas.region=Rect2(Vector2(index%5,index/5)*cell,cell);atlas.filter_clip=true
	return atlas
