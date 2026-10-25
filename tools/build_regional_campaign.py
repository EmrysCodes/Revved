"""Build a complete two-chapter prototype campaign on the real regional road graph."""
import json,pathlib,math,heapq,collections,argparse,sys
p=argparse.ArgumentParser();p.add_argument('--vendor',required=True);a=p.parse_args();sys.path.insert(0,a.vendor)
from pyproj import Transformer
import numpy as np
root=pathlib.Path(__file__).resolve().parents[1];m=json.loads((root/'world/plattsburgh/data/region.json').read_text());dress=json.loads((root/'world/plattsburgh/data/dressing.json').read_text());out=root/'racing/region_events';out.mkdir(exist_ok=True)
graph=collections.defaultdict(list);nodes={};roads=m['roads']
def key(p):return tuple(round(v,1) for v in p)
for i,r in enumerate(roads):
 aa,bb=key(r['points'][0]),key(r['points'][-1]);nodes[aa]=r['points'][0];nodes[bb]=r['points'][-1];length=sum(math.dist(p,q) for p,q in zip(r['points'],r['points'][1:]));cost=length*(1.02 if r['fcc']=='A15' else 1)
 if r['one_way']!='TF':graph[aa].append((bb,cost,i,False))
 if r['one_way']!='FT':graph[bb].append((aa,cost,i,True))
fwd=Transformer.from_crs(4326,32618,always_xy=True)
def at(lon,lat):
 x,n=fwd.transform(lon,lat);x-=m['origin_utm'][0];z=m['origin_utm'][1]-n
 return min(nodes,key=lambda k:(k[0]-x)**2+(k[2]-z)**2)
def between(start,end):
 heap=[(0,start)];best={start:0};prev={}
 while heap:
  cost,at=heapq.heappop(heap)
  if cost!=best[at]:continue
  if at==end:break
  for nxt,weight,i,reverse in graph[at]:
   nc=cost+weight
   if nc<best.get(nxt,math.inf):best[nxt]=nc;prev[nxt]=(at,i,reverse);heapq.heappush(heap,(nc,nxt))
 if end not in best:raise RuntimeError(f'Unreachable campaign waypoint {end}')
 steps=[];cursor=end
 while cursor!=start:
  before,i,reverse=prev[cursor];steps.append((i,reverse));cursor=before
 points=[]
 for i,reverse in reversed(steps):
  line=roads[i]['points'][::-1] if reverse else roads[i]['points'];points.extend(line if not points else line[1:])
 return points
def via(coords):
 points=[];keys=[at(*p) for p in coords]
 for start,end in zip(keys,keys[1:]):
  line=between(start,end);points.extend(line if not points else line[1:])
 cleaned=[]
 for point in points:
  if len(cleaned)>1 and math.dist(point,cleaned[-2])<.01:cleaned.pop()
  elif not cleaned or math.dist(point,cleaned[-1])>.01:cleaned.append(point)
 return cleaned if len(cleaned)>10 else points
def rotate_loop(line):
 # The grid and finish sit in the middle of a straight road, away from junctions.
 best=max(range(len(line)-2),key=lambda i:math.dist(line[i],line[i+1]))
 line=line[:-1];return line[best:]+line[:best]+[line[best]]
def sample(line,closed):
 # Round small GIS corner vertices inside the intersection pavement footprint.
 if closed:line=rotate_loop(line)
 for _ in range(2):
  result=[]
  if not closed:result.append(line[0])
  for p,q in zip(line,line[1:]):
   for t in [.15,.85]:result.append([p[k]*(1-t)+q[k]*t for k in range(3)])
  result.append(result[0] if closed else line[-1]);line=result
 values=np.asarray(line);distances=np.r_[0,np.cumsum(np.linalg.norm(np.diff(values,axis=0),axis=1))];samples=np.r_[np.arange(0,distances[-1],3),distances[-1]]
 return [[round(float(v),3) for v in point] for point in np.stack([np.interp(samples,distances,values[:,k]) for k in range(3)],axis=1)]
city=dress['traffic_routes'];north=(-73.4261,44.775);downtown=(-73.4509,44.696);south=(-73.448,44.665);valcour=(-73.4398,44.608);lake=(-73.425,44.631);airport=(-73.459,44.671)
coast_loop=via([south,valcour,lake,south]);river_loop=via([downtown,south,airport,downtown])
# Keep repeat-lap events compact; long north/south sprints cover the full region.
compact=[]
for ri,r in enumerate(roads):
 if r['fcc']=='A15' or r['one_way'] or not 3000<r['points'][0][2]<10000:continue
 start,end=key(r['points'][-1]),key(r['points'][0]);heap=[(0,start)];best={start:0};prev={}
 while heap:
  cost,node=heapq.heappop(heap)
  if cost!=best[node] or cost>6000:continue
  if node==end:break
  for nxt,weight,i,reverse in graph[node]:
   if i==ri or roads[i]['fcc']=='A15':continue
   nc=cost+weight
   if nc<best.get(nxt,math.inf):best[nxt]=nc;prev[nxt]=(node,i,reverse);heapq.heappush(heap,(nc,nxt))
 if end not in best or best[end]>6000:continue
 steps=[];cursor=end
 while cursor!=start:before,i,reverse=prev[cursor];steps.append((i,reverse));cursor=before
 if len(steps)<3:continue
 line=list(r['points'])
 for i,reverse in reversed(steps):line.extend((roads[i]['points'][::-1] if reverse else roads[i]['points'])[1:])
 length=sum(math.dist(p,q) for p,q in zip(line,line[1:]));center=sum(p[2] for p in line)/len(line)
 if 1200<length<6500:compact.append((abs(center-7500)+abs(length-3000)*.4,line))
if compact:coast_loop=min(compact,key=lambda v:v[0])[1]
specs=[
 ('capital_run','Ignition Run',0,0,1100,3,1,city[0],'Mara: Your first night in Plattsburgh. Read the streets and bring it home.'),
 ('pearl_dash','Margaret After Dark',0,0,900,3,1,city[1],'The downtown grid rewards a clean braking line.'),
 ('bushnell_clock','Riverbank Deadline',0,0,1000,0,1,city[2],'A solo clock run through the river district.'),
 ('asylum_circuit','Plattsburgh Nights',0,1,1600,3,2,city[3],'Two laps. Learn the junctions and keep your exit speed.'),
 ('columbus_sprint','Saranac Run',0,1,1400,3,1,via([downtown,south]),'Follow the Saranac streets into the south end.'),
 ('northbound_run','North Country Heat',0,1,1500,3,1,via([downtown,north]),'The city opens into US-9. Keep your line through the northern neighbourhoods.'),
 ('downtown_endurance','Downtown Endurance',0,2,2500,3,3,city[4],'Three laps through the downtown street grid.'),
 ('capitol_duel','Voss / Night Line',0,2,2200,1,1,city[5],'Mara: No pack to hide in. One clean lap, just you and me.'),
 ('capitol_crown','Crown of Plattsburgh',0,3,5000,3,2,city[6],'Win the downtown final to open the Champlain Coast chapter.'),
 ('founders_entry','Southbound',1,0,1800,3,1,via([downtown,south,valcour]),'Inez: Leave the grid behind. The coast has its own rhythm.'),
 ('pitkin_dash','Valcour Pulse',1,0,1900,3,1,coast_loop,'An open-road loop through Valcour and the lakeshore approaches.'),
 ('river_clock','Coastal Deadline',1,0,2000,0,1,via([valcour,south]),'One car, one clock, and the road back north.'),
 ('main_street_circuit','Champlain Midnight',1,1,2800,3,2,coast_loop,'Two laps along the southern road network.'),
 ('foundry_sprint','Night Shift',1,1,2500,3,1,via([airport,south,valcour]),'Run from the airport approaches to the southern edge.'),
 ('silver_lane_rush','Lake Road Rush',1,1,2600,3,1,via([lake,valcour,south]),'A lakeshore departure with a fast run back toward the city.'),
 ('eastside_endurance','Coast Endurance',1,2,3800,3,3,coast_loop,'Three laps. Smooth inputs beat a single desperate corner.'),
 ('river_duel','Inez / Ghost Line',1,2,3500,1,1,via([valcour,south,downtown]),'Inez: Show me you can carry a clean line all the way back to town.'),
 ('eastside_crown','City to Coast / One Legacy',1,3,8500,3,1,via([north,downtown,south,valcour]),'The prototype finale crosses the entire region. Win to complete Street Legacy.')]
events=[]
for event_id,title,chapter,tier,cash,rivals,laps,raw,brief in specs:
 closed=math.dist(raw[0],raw[-1])<.5;line=sample(raw,closed)
 if not closed:line=line[5:-10] # keep the start/finish out of junction mouths
 points=list(line)
 if laps>1:
  for _ in range(laps-1):points.extend(line[1:])
 finish=len(points)-1
 if closed:points.extend(line[1:16])
 else:
  # A short runoff stays on the source route instead of extending through scenery.
  finish=max(1,finish-12)
 distances=[0.0]
 for p,q in zip(points,points[1:]):distances.append(round(distances[-1]+math.dist(p,q),4))
 checkpoints=[];last=0
 for i in range(12,finish-15):
  if distances[i]-last>=150:
   # Place a gate on a straight approach, never in the middle of a sharp turn.
   a=[points[i][k]-points[i-5][k] for k in [0,2]];b=[points[i+5][k]-points[i][k] for k in [0,2]]
   dot=sum(x*y for x,y in zip(a,b))/max(.001,math.hypot(*a)*math.hypot(*b))
   if dot>.97:checkpoints.append(i);last=distances[i]
 checkpoints.append(finish);length=distances[finish];district='DOWNTOWN / PLATTSBURGH' if chapter==0 else 'VALCOUR / CHAMPLAIN COAST'
 sections=[{'start':0,'end':finish,'label':district}]
 if laps>1:sections=[{'start':j*(len(line)-1),'end':min(finish,(j+1)*(len(line)-1)),'label':f'LAP {j+1} / {laps}  •  {district}'} for j in range(laps)]
 payload={'name':title,'version':101,'points':points,'distances':distances,'checkpoints':checkpoints,'finish_index':finish,'length':length,'laps':laps,'target_seconds':round(length/16+25),'sections':sections,'traffic_loop':line if closed else []}
 (out/(event_id+'.json')).write_text(json.dumps(payload,separators=(',',':')))
 kind='Time attack' if rivals==0 else ('District final' if tier==3 else ('Circuit' if laps>1 else ('Crew duel' if rivals==1 else 'Street sprint')))
 events.append({'id':event_id,'name':title,'kind':kind,'chapter':chapter,'tier':tier,'cash':cash,'rivals':rivals,'laps':laps,'point':[points[0][0],points[0][2]],'brief':brief,'route':f'res://racing/region_events/{event_id}.json'})
chapters=[{'name':'IGNITION','district':'Downtown / Plattsburgh','crew':'NORTH COUNTRY COLLECTIVE','leader':'Mara Voss','color':'ffcb5a','story':'Earn your place around downtown and the Saranac. Beat Mara to open the coast.'},{'name':'COAST AFTER DARK','district':'Valcour / Champlain Coast','crew':'LAKE GHOSTS','leader':'Inez Vale','color':'56dcea','story':'Race the southern road network, then prove yourself across the whole region.'}]
def gd(v):
 if isinstance(v,dict):return '{'+','.join(json.dumps(k)+':'+gd(value) for k,value in v.items())+'}'
 if isinstance(v,list):return '['+','.join(gd(x) for x in v)+']'
 return json.dumps(v,ensure_ascii=False)
event_text=[]
for e in events:
 point=e.pop('point');text=gd(e)[:-1]+',"point":Vector2('+str(point[0])+','+str(point[1])+')}';event_text.append(text)
chapter_text=[]
for c in chapters:
 color=c.pop('color');chapter_text.append(gd(c)[:-1]+',"color":Color("'+color+'")}')
(root/'core/regional_campaign.gd').write_text('extends RefCounted\n## Geography-based prototype campaign. IDs preserve existing local progress.\nconst CHAPTERS:=['+','.join(chapter_text)+']\nconst EVENTS:Array[Dictionary]=['+',\n'.join(event_text)+']\n',encoding='utf8')
print('REGIONAL CAMPAIGN',len(events),'events',[(e['id'],json.loads((out/(e['id']+'.json')).read_text())['length']) for e in events],flush=True)
