extends RefCounted
## Guidance follows distance along the road, never the straight line to a distant gate.
static func maneuvers(path:PackedVector3Array,distances:PackedFloat64Array,finish:int) -> Array[Dictionary]:
	var turns:Array[Dictionary]=[]
	var first:=-1;var last:=-1;var total:=0.0;var sign_value:=0.0
	for i in range(2,mini(finish-1,path.size()-2)):
		var before:=path[i]-path[i-2];before.y=0
		var after:=path[i+2]-path[i];after.y=0
		if before.length()<2 or after.length()<2:continue
		var angle:=before.signed_angle_to(after,Vector3.UP)
		var curved:=absf(angle)>0.055
		if first>=0 and ((curved and signf(angle)!=sign_value) or distances[i]-distances[last]>28):
			_add(turns,path,distances,first,last,total)
			first=-1;total=0
		if curved:
			if first<0:first=i;sign_value=signf(angle)
			last=i
			# Divide by the overlapping four-segment heading window.
			total+=angle*0.5
	if first>=0:_add(turns,path,distances,first,last,total)
	turns.append({"start":distances[finish],"end":distances[finish]+8,"index":finish,"angle":0.0,"kind":"finish","label":"FINISH"})
	return turns
static func _add(result:Array[Dictionary],path:PackedVector3Array,d:PackedFloat64Array,first:int,last:int,total:float) -> void:
	if absf(total)<0.35 or d[last]-d[first]<2:return
	var direction:="left" if total>0 else "right"
	var kind:="uturn" if absf(total)>2.45 else ("sharp_"+direction if absf(total)>1.85 else direction)
	result.append({"start":maxf(0,d[first]-8),"end":d[last]+12,"index":int((first+last)/2),"angle":total,"kind":kind,"label":("U-TURN" if kind=="uturn" else ("SHARP " if kind.begins_with("sharp") else "")+direction.to_upper())})
static func next_turn(turns:Array[Dictionary],progress:float) -> Dictionary:
	for turn in turns:
		if progress<=turn.end:
			var item:=turn.duplicate();item.distance=maxf(0,turn.start-progress);item.in_turn=progress>=turn.start
			return item
	return {"kind":"finish","label":"FINISH","distance":0.0,"in_turn":true,"index":0}
static func safe_checkpoints(path:PackedVector3Array,d:PackedFloat64Array,finish:int) -> PackedInt32Array:
	var turns:=maneuvers(path,d,finish)
	var candidates:Array[float]=[]
	var at:=160.0
	while at<d[finish]-55:
		candidates.append(at);at+=190
	# Confirm a turn after the driver is through it, not halfway across the junction.
	for turn in turns:
		if turn.kind!="finish" and turn.end+24<d[finish]-45:candidates.append(turn.end+24)
	candidates.sort()
	var gates:=PackedInt32Array();var cursor:=1;var last_distance:=0.0
	for candidate:float in candidates:
		var target:=candidate
		for turn in turns:
			if turn.kind!="finish" and target>turn.start-22 and target<turn.end+18:target=turn.end+24
		while cursor<finish and d[cursor]<target:cursor+=1
		if cursor<finish and d[cursor]-last_distance>=70 and d[finish]-d[cursor]>45:
			gates.append(cursor);last_distance=d[cursor]
	gates.append(finish)
	return gates
