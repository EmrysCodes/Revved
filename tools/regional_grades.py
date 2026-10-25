"""Road engineering over measured terrain; topology levels are not metre offsets."""
import math
import numpy as np

def repair(m,water,surface):
 xmin,zmin,_,_=m['bounds'];step=m['step'];nx,nz=m['grid_size']
 def raster(image,x,z):return image[min(nz-1,max(0,round((z-zmin)/step))),min(nx-1,max(0,round((x-xmin)/step)))]
 nodes={};floors={};edges=[]
 for road in m['roads']:
  keys=[]
  for end,level in zip([0,-1],road['levels']):
   p=road['points'][end];key=(round(p[0],1),round(p[2],1),int(level));keys.append(key);nodes[key]=p[1]
   if raster(water,p[0],p[2]):floors[key]=float(raster(surface,p[0],p[2]))+2;nodes[key]=max(nodes[key],floors[key])
  length=sum(math.hypot(q[0]-p[0],q[2]-p[2]) for p,q in zip(road['points'],road['points'][1:]));edges.append((road,keys,length))
 stacked={}
 for key in nodes:stacked.setdefault(key[:2],[]).append(key)
 for iteration in range(500):
  peak=0
  for road,(aa,bb),length in edges:
   delta=nodes[bb]-nodes[aa];excess=abs(delta)-length*.12
   if excess>0:
    adjustment=math.copysign(excess*.5,delta);nodes[aa]+=adjustment;nodes[bb]-=adjustment;peak=max(peak,excess)
  for refs in stacked.values():
   refs=sorted(refs,key=lambda k:k[2])
   for lo,hi in zip(refs,refs[1:]):
    missing=4.8*(hi[2]-lo[2])-(nodes[hi]-nodes[lo])
    if missing>0:nodes[hi]+=missing*.5;nodes[lo]-=missing*.5;peak=max(peak,missing)
  for key,floor in floors.items():
   if nodes[key]<floor:peak=max(peak,floor-nodes[key]);nodes[key]=floor
  if peak<.0005:break
 kernel=np.exp(-.5*(np.arange(-16,17)/4)**2);kernel/=kernel.sum();max_grade=0
 for road,(aa,bb),length in edges:
  points=np.asarray(road['points'],dtype=float);dist=np.r_[0,np.cumsum(np.linalg.norm(np.diff(points[:,[0,2]],axis=0),axis=1))];old_y=points[:,1].copy()
  wet=np.array([raster(water,p[0],p[2]) for p in points]);road['water_crossing']=bool(wet.any())
  road.setdefault('source_elevated',road['elevated']);road['elevated']=road['source_elevated'] or road['water_crossing']
  cursor=0
  while cursor<len(points):
   if not wet[cursor]:cursor+=1;continue
   end=cursor
   while end+1<len(points) and wet[end+1]:end+=1
   before=max(0,cursor-1);after=min(len(points)-1,end+1)
   for j in range(cursor,end+1):
    t=(dist[j]-dist[before])/max(.01,dist[after]-dist[before]);old_y[j]=max(old_y[before]*(1-t)+old_y[after]*t,float(raster(surface,points[j,0],points[j,2]))+2)
   cursor=end+1
  desired=old_y+np.interp(dist,[0,max(.01,length)],[nodes[aa]-old_y[0],nodes[bb]-old_y[-1]])
  samples=np.r_[np.arange(0,length,2),length];ys=np.interp(samples,dist,desired);ys=np.convolve(np.pad(ys,(16,16),mode='edge'),kernel,mode='valid')
  first,last=nodes[aa],nodes[bb];limit=max(.12,abs(last-first)/max(.01,length)+.00001)
  ys=np.clip(ys,np.maximum(first-limit*samples,last-limit*(length-samples)),np.minimum(first+limit*samples,last+limit*(length-samples)));ys[0]=first;ys[-1]=last
  for _ in range(4):
   for j in range(1,len(samples)-1):ys[j]=np.clip(ys[j],ys[j-1]-limit*(samples[j]-samples[j-1]),ys[j-1]+limit*(samples[j]-samples[j-1]))
   for j in range(len(samples)-2,0,-1):ys[j]=np.clip(ys[j],ys[j+1]-limit*(samples[j+1]-samples[j]),ys[j+1]+limit*(samples[j+1]-samples[j]))
  road['points']=[[round(float(x),3),round(float(y),3),round(float(z),3)] for x,y,z in zip(np.interp(samples,dist,points[:,0]),ys,np.interp(samples,dist,points[:,2]))]
  max_grade=max(max_grade,max(abs(np.diff(ys))/np.maximum(.01,np.diff(samples))))
 print('ROAD GRADE REPAIR iterations',iteration+1,'max grade',round(max_grade,4),flush=True)

def trim_rails(m,segments):
 from shapely.geometry import Point
 from shapely.strtree import STRtree
 nodes={}
 for road in m['roads']:
  for at in [0,-1]:
   p=road['points'][at];key=tuple(round(v,1) for v in p);nodes.setdefault(key,[]).append(p)
 junctions=[values[0] for values in nodes.values() if len(values)>1];tree=STRtree([Point(p[0],p[2]) for p in junctions]);kept=[]
 for segment in segments:
  mid=[(p+q)/2 for p,q in zip(segment['a'],segment['b'])];point=Point(mid[0],mid[2]);radius=max(10,segment['width']*1.2)
  if any(point.distance(Point(junctions[i][0],junctions[i][2]))<radius and abs(mid[1]-junctions[i][1])<2.1 for i in tree.query(point.buffer(radius))):continue
  kept.append(segment)
 return kept
