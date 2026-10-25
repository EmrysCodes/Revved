"""Author the complete Last Light script. No network, purchases, or paid voices."""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
CAST = {
 'mara': {'name':'MARA VOSS','role':'North Country Collective / garage owner','presentation':1,'portrait':2,'color':'ffca63','rate':0},
 'inez': {'name':'INEZ VALE','role':'Lake Ghosts / coast captain','presentation':1,'portrait':6,'color':'59dce8','rate':-1},
 'quinn': {'name':'QUINN REYES','role':'Mechanic / your oldest friend','presentation':1,'portrait':0,'color':'b2eca1','rate':1},
 'jade': {'name':'JADE SLOANE','role':'Afterhours / race promoter','presentation':1,'portrait':8,'color':'f394c0','rate':-2},
}
# Each entry is a race, a dramatic heading, its setup, and its first-win resolution.
BEATS = [
('capital_run','A NAME ON THE DOOR',[
 ('quinn','You made it, {driver}. Same car, different city. Mara is waiting by the lift.'),
 ('mara','Quinn says you can drive. I need someone who can finish. Our garage lease expires at the end of the week.'),
 ('mara','Tonight starts small. Win the Ignition Run. Earn a place here before you try to save it.')],[
 ('quinn','First win. I kept the receipt. Proof you were here before anybody knew your name.'),
 ('mara','There is a spare bay with your name on it. Use the garage. Build carefully. We have a long week ahead.')]),
('pearl_dash','WORD TRAVELS',[
 ('quinn','Margaret Street is awake now. Everybody heard about your first run.'),
 ('jade','Jade Sloane. I put on Afterhours. Win tonight and I can put you in front of people with real money.'),
 ('mara','People are not a shortcut, Jade. Let the driver earn the street.')],[
 ('jade','Clean finish. You have a face people will remember.'),
 ('quinn','She means a face she can put on a poster. Keep your name. We will handle the rest.')]),
('bushnell_clock','THE QUIET TEST',[
 ('mara','No pack tonight. Just the river and the clock. It is easy to borrow courage from another car.'),
 ('quinn','Bring it home under the target. We need precision before we need more power.'),
 ('mara','And if the run goes wrong, reset. Nobody earns respect by pretending they cannot learn.')],[
 ('mara','That is control. The kind that still works when nobody is watching.'),
 ('quinn','Inez called from the coast. Apparently your quiet little run was not so quiet.')]),
('asylum_circuit','THE COLLECTIVE',[
 ('mara','North Country Collective is not a sponsor. It is the people who keep these cars running.'),
 ('quinn','Two laps with the locals. Show them you belong here.'),
 ('mara','I used to run these streets with Inez. Before a contract taught us to keep score against each other.')],[
 ('quinn','You earned a crew tonight. Not followers. People who will help you push a dead car home.'),
 ('mara','Remember the difference. Jade will offer you plenty of the other kind.')]),
('columbus_sprint','SOUTH OF THE RIVER',[
 ('jade','Afterhours has a lease rescue program. One exclusive driver agreement. The garage could stop worrying.'),
 ('mara','And every driver in the building would owe you a cut. We have read your contracts.'),
 ('quinn','Leave the paperwork here. We have a Saranac run to win.')],[
 ('jade','You do not have to answer tonight. The offer will still be here when the rent is due.'),
 ('mara','So will we. There is another way through this.')]),
('northbound_run','OLD SIGNAL',[
 ('inez','You are the new name in Mara\'s garage. I am Inez. She probably told you I left.'),
 ('mara','I told them we stopped racing together.'),
 ('inez','Then ask her why. First, take the northern run. I want to see whether the stories match the driving.')],[
 ('inez','They match. Come find me when you have earned the downtown crown.'),
 ('quinn','She sounded like she wanted you to win. Mara went quiet when I said that.')]),
('downtown_endurance','KEEP THE LIGHTS ON',[
 ('quinn','The landlord sent the final notice. Mara put it under the parts catalogue like that could make it disappear.'),
 ('mara','Three laps. This purse keeps the lights on long enough to reach the final.'),
 ('quinn','The garage is not yours to carry alone. But tonight, we could use your help.')],[
 ('mara','The power stays on. Thank you. That is more than a result on a board.'),
 ('quinn','Now stop looking at the notice. We still have a crown to chase.')]),
('capitol_duel','NO ROOM TO HIDE',[
 ('mara','Before I put the Collective behind you, we run one on one.'),
 ('mara','Inez and I signed with Afterhours years ago. When the team split, I blamed her for leaving me with the debt.'),
 ('mara','I never asked what it cost her to leave. That is a mistake I will not make with you.')],[
 ('mara','You beat me straight. The Collective is yours to represent.'),
 ('quinn','Then let us make sure the whole city sees it.')]),
('capitol_crown','CROWN OF PLATTSBURGH',[
 ('jade','Downtown final. Win this and Afterhours can make the garage problem disappear tonight.'),
 ('mara','No signature. No borrowed name. We race for the purse.'),
 ('quinn','You came here looking for a place, {driver}. Tonight you get to keep it.')],[
 ('mara','Downtown is yours. We can cover the overdue rent. We still need a future.'),
 ('inez','I have a way to give you one. Bring your crew south. This time, Mara, come with them.'),
 ('jade','The coast does not owe you the same welcome. We will talk again.')]),
('founders_entry','A DIFFERENT RHYTHM',[
 ('inez','The coast opens up. So do your mistakes. Fast roads ask for patience.'),
 ('mara','Inez. I should have called.'),
 ('inez','You are here now. Let the driver take Southbound. We can talk while they make the introduction.')],[
 ('inez','Good introduction. The Lake Ghosts will give you a fair run.'),
 ('quinn','Mara and Inez are still talking. Nobody has walked away. That is progress.')]),
('pitkin_dash','GHOSTS ON THE LAKE',[
 ('inez','Lake Ghosts started with three cars and a toolbox. We race so everybody gets another night on the road.'),
 ('quinn','Sounds familiar.'),
 ('inez','It should. Mara taught me that part. Show the coast the same respect you showed downtown.')],[
 ('inez','The crew likes you. More importantly, they trust your line.'),
 ('mara','I recognize what you built here, Inez. I should have seen it sooner.')]),
('river_clock','WHAT THE CLOCK KEEPS',[
 ('inez','My Afterhours contract did not end when I left. I paid for two years after that last race.'),
 ('mara','I thought you left me holding everything.'),
 ('inez','They told us different stories. Beat the coastal clock. Then we stop letting them tell this one.')],[
 ('mara','I am sorry. For the silence. For making it easier to believe we were enemies.'),
 ('inez','Apology accepted. Now let us do something useful with the years we have left.')]),
('main_street_circuit','TWO CREWS, ONE NIGHT',[
 ('quinn','Two crews in one garage. We are going to need more mugs.'),
 ('inez','The Midnight circuit will show the coast we are working together.'),
 ('mara','No team orders. Everyone gets a fair race. That is what this was supposed to be.')],[
 ('inez','The Ghosts and the Collective can fill a grid without asking Jade for a single invitation.'),
 ('quinn','Then why not put on our own final? City to coast. Everybody welcome.')]),
('foundry_sprint','NIGHT SHIFT',[
 ('jade','Your independent final needs a prize pool. My events already have one. There is room for you if you stop this.'),
 ('mara','We are not shutting anybody out. We are opening another door.'),
 ('quinn','Night Shift pays the first share. One race at a time. We can do this without a contract.')],[
 ('quinn','First share is in. The crews are matching it. They want this race as much as we do.'),
 ('jade','Be careful what you promise people. They will remember if you fail.')]),
('silver_lane_rush','NOT FOR SALE',[
 ('jade','Last offer. Your name on an Afterhours car. A guaranteed seat. No more worrying about that garage.'),
 ('inez','A seat is not the same thing as a home.'),
 ('mara','This is your line, {driver}. Race Lake Road Rush. Let the finish be your answer.')],[
 ('quinn','No signature. No sale. I am keeping this result next to the first one.'),
 ('jade','All right. Then I will meet you on the road. No contracts. Just a race.')]),
('eastside_endurance','THE LONG NIGHT',[
 ('inez','The final is funded. Tonight we prove the cars and the people can go the distance.'),
 ('mara','Three coastal laps. Keep something in reserve. A fast first lap means nothing if you never finish.'),
 ('quinn','We have a bay, a toolbox, and a city full of people who showed up. Bring it back to them.')],[
 ('inez','That is endurance. The car is ready. So are you.'),
 ('mara','One more test with Inez. Then the whole road is waiting.')]),
('river_duel','THE GHOST LINE',[
 ('inez','One on one. No secret line. No magic setup. Just the road I know best.'),
 ('inez','I spent years believing independence meant being alone. Your crew proved otherwise.'),
 ('mara','Give them a proper run, Inez. They have earned that much.')],[
 ('inez','You found your own line. That is the only one that lasts.'),
 ('quinn','City to Coast is on. Everybody is coming. Let us give them a night worth remembering.')]),
('eastside_crown','LAST LIGHT',[
 ('jade','I brought a car, not a contract. If you want a place on this grid, you earn it. That was your rule.'),
 ('mara','Then welcome to the grid. Downtown to Valcour. One road, one finish.'),
 ('inez','Whatever happens, the race belongs to the people who built it.'),
 ('quinn','Look at the lights, {driver}. You are not arriving anymore. You are home.')],[
 ('quinn','You did it. The purse covers the new lease. Mara has already started arguing about a second lift.'),
 ('jade','You beat me. Keep your name. You made it worth more than anything I could have offered.'),
 ('inez','One city. Two crews. No locked doors.'),
 ('mara','Your name goes above the bay tonight. Not because you saved us. Because you stayed.')]),
]
SCENES={}
def scene(key,title,lines,chapter=0):
 SCENES[key]={'id':key,'title':title,'chapter':chapter,'lines':[{'speaker':speaker,'text':text,'audio':f'res://assets/audio/story/{key}_{i:02d}.wav'} for i,(speaker,text) in enumerate(lines)]}
scene('prologue','STREET LEGACY / LAST LIGHT',[
 ('quinn','You said you needed a fresh start. I said I knew a garage. I left out the part where it might be closing.'),
 ('mara','We keep the lights on by fixing what other people gave up on. Cars. Mostly.'),
 ('quinn','Plattsburgh after dark. The river, the city, the coast. Eighteen chances to make a name.'),
 ('mara','No shortcuts. No one owns your name. If you want a place here, we start tonight.')])
for index,(event,title,before,after) in enumerate(BEATS):
 scene(event+'_before',title,before,index//9)
 scene(event+'_after',title+' / AFTER THE FINISH',after,index//9)
scene('epilogue','THE DOOR STAYS OPEN',[
 ('quinn','First receipt. Last result. I put them both on the wall. Everything between them is yours.'),
 ('mara','The lease is signed. The garage stays independent. Tomorrow, we open the doors.'),
 ('inez','Tonight, take the coast road. No clock. No target. Just drive.'),
 ('quinn','Street Legacy complete. Come back for a better time, another build, or just another night with us.')],1)
scene('setback','ANOTHER RUN',[
 ('mara','A result is not an ending. Come back, check the car, and find the part of the road you can improve.'),
 ('quinn','We are still here. The next run is yours.')])
target=ROOT/'story'; target.mkdir(exist_ok=True)
(target/'last_light.json').write_text(json.dumps({'title':'LAST LIGHT','cast':CAST,'scenes':SCENES,'order':[beat[0] for beat in BEATS]},indent=2),encoding='utf-8')
print(f'Authored {len(SCENES)} scenes / {sum(len(s["lines"]) for s in SCENES.values())} dialogue lines')
