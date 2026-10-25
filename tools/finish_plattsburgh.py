"""Deterministic, clearance-checked dressing from the approved regional GIS base.

Imagery informs broad land cover only. Props and architecture are approximations,
not surveyed inventories. Re-running never changes the geographic road alignment.
"""
import argparse, json, math, pathlib, sys, random
p=argparse.ArgumentParser();p.add_argument('--vendor',required=True);p.add_argument('--source',type=pathlib.Path);a=p.parse_args()
sys.path.insert(0,a.vendor)
import numpy as np
from PIL import Image,ImageDraw,ImageFilter
import shapely
from shapely.geometry import Polygon,LineString,Point
from shapely.strtree import STRtree
root=pathlib.Path(__file__).resolve().parents[1];d=root/'world/plattsburgh/data'
m=json.loads((d/'region.json').read_text());xmin,zmin,xmax,zmax=m['bounds'];step=m['step'];nx,nz=m['grid_size']
joins={}
for road in m['roads']:
 if 'source_points' not in road:road['source_points']=[[p[0],y,p[2]] for p,y in zip(road['points'],road.get('source_grade',[p[1] for p in road['points']]))]
 road['points']=[list(p) for p in road['source_points']]
 if 'source_grade' not in road:road['source_grade']=[p[1] for p in road['points']]
 for point,y in zip(road['points'],road['source_grade']):point[1]=y
 for end in [0,-1]:
  p=road['points'][end];joins.setdefault(tuple(round(v,1) for v in p),[]).append((road,end))
for refs in joins.values():
 if len(refs)!=2:continue
 branches=[]
 for road,end in refs:
  line=road['points'] if end==0 else list(reversed(road['points']));p=line[0];q=min(line[1:],key=lambda q:abs(math.hypot(q[0]-p[0],q[2]-p[2])-55));dist=max(1,math.hypot(q[0]-p[0],q[2]-p[2]));branches.append((line,[(q[0]-p[0])/dist,(q[2]-p[2])/dist],(q[1]-p[1])/dist))
 if sum(a*b for a,b in zip(branches[0][1],branches[1][1]))<.65:continue
 slope=sum(b[2] for b in branches)/2
 for line,_,_ in branches:
  origin=line[0]
  for point in line[1:]:
   dist=math.hypot(point[0]-origin[0],point[2]-origin[2])
   if dist>55:break
   blend=max(0,min(1,(55-dist)/20));point[1]=round(point[1]*(1-blend)+(origin[1]+slope*dist)*blend,3)
heights=np.fromfile(d/'terrain_height.bin',dtype='<f4').reshape(nz,nx)
water=np.asarray(Image.open(d/'water_mask.png'))>127
if a.source:
 from pyproj import Transformer
 dem=np.asarray(Image.open(a.source/'elevation.tif'));dh,dw=dem.shape
 xx,zz=np.meshgrid(np.arange(nx)*step+xmin,np.arange(nz)*step+zmin)
 rev=Transformer.from_crs(32618,4326,always_xy=True);lon,lat=rev.transform(xx+m['origin_utm'][0],m['origin_utm'][1]-zz)
 sx=np.clip((lon+73.535)/.185*dw-.5,0,dw-1.001);sy=np.clip((44.794-lat)/.204*dh-.5,0,dh-1.001);ix=sx.astype(int);iz=sy.astype(int);fx=sx-ix;fz=sy-iz
 surface=dem[iz,ix]*(1-fx)*(1-fz)+dem[iz,ix+1]*fx*(1-fz)+dem[iz+1,ix]*(1-fx)*fz+dem[iz+1,ix+1]*fx*fz-m['base_elevation_m']
 heights=surface.copy()
 # Lake Champlain is the vertical datum. Upstream river reaches retain their
 # measured water elevation instead of being flattened to the lake surface.
 surface=np.where(surface<2,0,surface);surface.astype('<f4').tofile(d/'water_surface.bin')
 heights[water]=surface[water]-1.5
else:surface=np.fromfile(d/'water_surface.bin',dtype='<f4').reshape(nz,nx)
from regional_grades import repair
repair(m,water,surface)
# Cut the complete road formation, including transition ramps. The original pass
# skipped all elevated-tagged records, leaving raised bare earth across ramps.
formation=np.full_like(heights,np.inf)
formation_distance=np.full_like(heights,np.inf);cuts=np.full_like(heights,np.inf);cut_distance=np.full_like(heights,np.inf)
for road in m['roads']:
 radius=road['width']/2+road['sidewalk']+step*1.3
 for p,q in zip(road['points'],road['points'][1:]):
  ix0=max(0,int((min(p[0],q[0])-radius-xmin)/step));ix1=min(nx-1,int((max(p[0],q[0])+radius-xmin)/step)+1)
  iz0=max(0,int((min(p[2],q[2])-radius-zmin)/step));iz1=min(nz-1,int((max(p[2],q[2])+radius-zmin)/step)+1)
  xx,zz=np.meshgrid(np.arange(ix0,ix1+1)*step+xmin,np.arange(iz0,iz1+1)*step+zmin);dx=q[0]-p[0];dz=q[2]-p[2]
  t=np.clip(((xx-p[0])*dx+(zz-p[2])*dz)/max(.001,dx*dx+dz*dz),0,1);dist=(xx-p[0]-t*dx)**2+(zz-p[2]-t*dz)**2
  target=p[1]+(q[1]-p[1])*t-.25;sel=dist<radius*radius
  goals=cuts[iz0:iz1+1,ix0:ix1+1];best=cut_distance[iz0:iz1+1,ix0:ix1+1];near=sel&(dist<best-.01);tie=sel&(abs(dist-best)<=.01)
  goals[near]=target[near];best[near]=dist[near];goals[tie]=np.minimum(goals[tie],target[tie])
  if not road['source_elevated']:
   goals=formation[iz0:iz1+1,ix0:ix1+1];best=formation_distance[iz0:iz1+1,ix0:ix1+1];near=sel&(dist<best-.01);tie=sel&(abs(dist-best)<=.01)
   goals[near]=target[near];best[near]=dist[near];goals[tie]=np.minimum(goals[tie],target[tie])
sel=np.isfinite(cuts);heights[sel]=np.minimum(heights[sel],cuts[sel])
sel=np.isfinite(formation)&~water;heights[sel]=formation[sel]
# Narrow river polygons include occasional bank pixels in a bare-earth DEM.
# Keep inland water below its bridge deck; the large lake retains its datum.
sel=water&np.isfinite(cuts)&(surface>2)
surface[sel]=np.minimum(surface[sel],np.maximum(0,cuts[sel]-1.25));heights[sel]=np.minimum(heights[sel],surface[sel]-1.5)
surface.astype('<f4').tofile(d/'water_surface.bin')
heights.astype('<f4').tofile(d/'terrain_height.bin');Image.fromarray(np.clip(np.rint((heights+32)*200),0,65535).astype(np.uint16)).save(d/'terrain_height.png')
def height(x,z):
 gx=np.clip((x-xmin)/step,0,nx-1.001);gz=np.clip((z-zmin)/step,0,nz-1.001);ix=int(gx);iz=int(gz);fx=gx-ix;fz=gz-iz
 return float(heights[iz,ix]*(1-fx)*(1-fz)+heights[iz,ix+1]*fx*(1-fz)+heights[iz+1,ix]*(1-fx)*fz+heights[iz+1,ix+1]*fx*fz)
def wet(x,z):return bool(water[min(nz-1,max(0,round((z-zmin)/step))),min(nx-1,max(0,round((x-xmin)/step)))])
roads=[LineString([(p[0],p[2]) for p in r['points']]) for r in m['roads']];rt=STRtree(roads)
buildings=[Polygon([(b['position'][0]+p[0],b['position'][2]+p[1]) for p in b['footprint']]).buffer(0) for b in m['buildings']];bt=STRtree(buildings)
west=m['west_edge'];outline=Polygon([(p[0],p[2]) for p in west]+[(xmax,west[-1][2]),(xmax,west[0][2])]).buffer(0)
def clearance(x,z,margin=2):
 pt=Point(x,z)
 if not outline.contains(pt) or wet(x,z):return False
 if len(bt.query(pt.buffer(margin),predicate='intersects')):return False
 for idx in rt.query(pt.buffer(22)):
  r=m['roads'][idx]
  if roads[idx].distance(pt)<r['width']/2+r['sidewalk']+margin:return False
 return True
# Replace the ghosted aerial roofs/roads with continuous grass/soil land cover.
im=Image.open(d/'ground_macro.jpg').convert('RGB');rgb=np.asarray(im).astype(float)/255
green=(rgb[:,:,1]>rgb[:,:,0]*1.04)&(rgb[:,:,1]>rgb[:,:,2]*1.08)
dark=rgb.mean(axis=2)<.29
cover=np.zeros((*rgb.shape[:2],3),dtype=np.uint8)
cover[:]=[79,91,59];cover[green]=[62,82,47];cover[dark & green]=[43,64,39]
cover[~green & (rgb.mean(axis=2)>.55)]=[100,99,76]
Image.fromarray(cover).filter(ImageFilter.GaussianBlur(3)).save(d/'land_cover.png')
def cover_green(x,z):
 ix=int(np.clip((x-xmin)/(xmax-xmin)*(im.width-1),0,im.width-1));iz=int(np.clip((z-zmin)/(zmax-zmin)*(im.height-1),0,im.height-1))
 return bool(green[iz,ix]),bool(dark[iz,ix])
rng=random.Random(87092026);trees=[];furniture=[];lots=[];bridges=[];drives=[];pads=[];pad_polygons=[]
# Frontage follows nearest street; create small drives / commercial aprons only
# when their full polygon avoids other properties and unrelated road surfaces.
for b,poly in zip(m['buildings'],buildings):
 ground_values=[height(x,z) for x,z in poly.exterior.coords];b['position'][1]=round(max(ground_values),3);b['foundation_depth']=round(max(1.5,max(ground_values)-min(ground_values)+.35),3)
 pt=poly.centroid;idx=int(rt.nearest(pt));line=roads[idx];r=m['roads'][idx];near=line.interpolate(line.project(pt));edges=list(poly.exterior.coords)
 front=min(range(len(edges)-1),key=lambda i:LineString(edges[i:i+2]).distance(near));b['front_edge']=front
 # Geometry2D changes winding in the building generator: use a world-facing target.
 b['front_target']=[round(near.x-b['position'][0],3),round(near.y-b['position'][2],3)]
 dist=pt.distance(near);house=b['roof']==1
 rect=poly.minimum_rotated_rectangle;edges=list(rect.exterior.coords);sides=[math.dist(edges[i],edges[i+1]) for i in range(2)];aspect=max(sides)/max(.1,min(sides))
 b['architecture']=0
 if not house and 250<poly.area<4000 and poly.area/rect.area>.84 and aspect<3 and b['id']%4!=0:
  b['architecture']=(2+b['id']%2) if b['height']<8 else (1 if b['id']%3 else 4)
 if not house:
  apron=poly.buffer(6 if poly.area<1500 else 10,join_style='mitre').difference(poly)
  for ri in rt.query(apron):apron=apron.difference(roads[ri].buffer(m['roads'][ri]['width']/2+m['roads'][ri]['sidewalk']+.2))
  for bi in bt.query(apron):
   if buildings[bi]!=poly:apron=apron.difference(buildings[bi].buffer(.3))
  if not apron.is_empty:
   pad_polygons.append(apron)
   for tri in shapely.get_parts(shapely.constrained_delaunay_triangles(apron)):
    points=list(tri.exterior.coords)[:3]
    if not any(wet(x,z) for x,z in points):pads.append([[round(x,2),round(height(x,z)+.055,3),round(z,2)] for x,z in points])
 if dist<95 and r['fcc']!='A15':
  boundary=poly.boundary.intersection(LineString([pt,near]))
  if not boundary.is_empty:
   start=shapely.get_parts(boundary)[0]
   if isinstance(start,Point):
    v=np.array([near.x-start.x,near.y-start.y]);length=np.linalg.norm(v)
    if length>2:
     v/=length;right=np.array([-v[1],v[0]]);width=3.1 if house else min(10,math.sqrt(poly.area)*.35)
     end=np.array([near.x,near.y])-v*(r['width']*.5+.05);sp=np.array([start.x,start.y])+v*.3
     if np.dot(end-sp,v)>1:
      corners=[sp-right*width/2,end-right*width/2,end+right*width/2,sp+right*width/2];drive=Polygon(corners)
      hits=bt.query(drive.buffer(.15),predicate='intersects')
      if len(hits)==0:
       drives.append({'points':[[round(x,3),round(height(x,z)+.07,3),round(z,3)] for x,z in corners],'house':house})
 if not house and 300<poly.area<12000 and dist<130 and r['fcc']!='A15':
  # A measured footprint defines orientation; lot dimensions are an approximation.
  angle=math.atan2(near.y-pt.y,near.x-pt.x);v=np.array([math.cos(angle),math.sin(angle)]);right=np.array([-v[1],v[0]])
  center=np.array([pt.x,pt.y])+v*(math.sqrt(poly.area)*.5+11)
  corners=[center+right*sx+v*sz for sx,sz in [(-9,-6),(-9,6),(9,6),(9,-6)]];area=Polygon(corners)
  if all(clearance(x,z,.6) for x,z in corners) and not len(bt.query(area,predicate='intersects')):
   if max(height(x,z) for x,z in corners)-min(height(x,z) for x,z in corners)<1.1:
    lots.append({'center':[round(center[0],3),round(height(*center)+.09,3),round(center[1],3)],'yaw':round(-angle,5),'width':18,'depth':12,'seed':b['id']})
# Roadside trees, benches, bins and bus shelters: clear pavements and junctions.
for r,line in zip(m['roads'],roads):
 if r['fcc']=='A15' or r['elevated']:continue
 spacing=33 if r['sidewalk'] else 70
 for s in np.arange(22,line.length-18,spacing):
  q=line.interpolate(s);prev=line.interpolate(max(0,s-2));nxt=line.interpolate(min(line.length,s+2));v=np.array([nxt.x-prev.x,nxt.y-prev.y]);v/=max(.001,np.linalg.norm(v));right=np.array([-v[1],v[0]])
  for side in [-1,1]:
   off=r['width']/2+r['sidewalk']+3.5;x,z=np.array([q.x,q.y])+right*side*off
   if clearance(x,z,2.1):trees.append([round(x,2),round(height(x,z),2),round(z,2),round(rng.uniform(7,13),2),rng.randrange(2),round(rng.uniform(0,math.tau),3)])
   if r['sidewalk'] and int(s)%3==1:
    x,z=np.array([q.x,q.y])+right*side*(r['width']/2+r['sidewalk']+1.25)
    if clearance(x,z,.65):furniture.append({'kind':'bench' if int(s)%2 else 'bin','p':[round(x,2),round(height(x,z),2),round(z,2)],'yaw':round(-math.atan2(v[1],v[0]),4)})
# Broad forest/meadow cover from USGS imagery, never on roads, footprints or water.
for z in np.arange(min(p[2] for p in west),max(p[2] for p in west),25):
 for x in np.arange(-6500,6500,25):
  x=float(x)+rng.uniform(-10,10);zz=float(z)+rng.uniform(-10,10);is_green,is_dark=cover_green(x,zz)
  if not is_green or rng.random()>(.85 if is_dark else .28):continue
  if clearance(x,zz,5):trees.append([round(x,2),round(height(x,zz),2),round(zz,2),round(rng.uniform(8,17),2),rng.randrange(2),round(rng.uniform(0,math.tau),3)])
# Rails/decks only where an elevated source road clears the underlying DEM;
# bridge labels are topological hints, not surveyed structural dimensions.
for r in m['roads']:
 if not r['elevated']:continue
 for i in sorted(set(list(range(4,len(r['points']),4))+[len(r['points'])-1])):
  p,q=r['points'][max(0,i-4)],r['points'][i];mid=[(p[k]+q[k])/2 for k in range(3)];clear=mid[1]-height(mid[0],mid[2])
  if clear>2.4:
   support=i%20==0 and clear>4
   if support:
    pt=Point(mid[0],mid[2])
    for idx in rt.query(pt.buffer(9)):
     if m['roads'][idx]['id']!=r['id'] and roads[idx].distance(pt)<m['roads'][idx]['width']/2+1.5:support=False;break
   bridges.append({'a':p,'b':q,'width':r['width'],'support':support,'clearance':round(clear,2)})
# Closed, connected neighbourhood circuits for ambient traffic. Never loop a
# vehicle by teleporting it back down a disconnected road segment.
from collections import deque,defaultdict
graph=defaultdict(list)
def key(p):return (round(p[0],1),round(p[1],1),round(p[2],1))
eligible=[]
for idx,r in enumerate(m['roads']):
 if r['fcc']=='A15' or r['elevated'] or r['one_way'] or roads[idx].length>700:continue
 if abs(roads[idx].centroid.x)>2100 or abs(roads[idx].centroid.y)>2800:continue
 aa,bb=key(r['points'][0]),key(r['points'][-1]);graph[aa].append((bb,idx));graph[bb].append((aa,idx));eligible.append(idx)
routes=[];seen=set();centers=[]
for idx in sorted(eligible,key=lambda i:roads[i].centroid.distance(Point(0,0))):
 r=m['roads'][idx];start,end=key(r['points'][0]),key(r['points'][-1]);queue=deque([(end,[])]);visited={end};path=None
 while queue:
  at,edges=queue.popleft()
  if len(edges)>10:continue
  if at==start:path=edges;break
  for nxt,j in graph[at]:
   if j==idx or nxt in visited:continue
   visited.add(nxt);queue.append((nxt,edges+[(at,nxt,j)]))
 if not path or len(path)<3:continue
 signature=tuple(sorted([idx]+[j for _,_,j in path]))
 if signature in seen:continue
 seen.add(signature);points=list(r['points'])
 for at,nxt,j in path:
  line=m['roads'][j]['points'];line=line if key(line[0])==at else list(reversed(line));points.extend(line[1:])
 center=np.asarray(points)[:,[0,2]].mean(axis=0)
 if any(np.linalg.norm(center-c)<300 for c in centers):continue
 if sum(math.dist(p,q) for p,q in zip(points,points[1:]))>2600:continue
 routes.append(points);centers.append(center)
 if len(routes)>=8:break
ptree=STRtree(pad_polygons)
trees=[t for t in trees if not len(ptree.query(Point(t[0],t[2]).buffer(1.5),predicate='intersects'))]
from regional_grades import trim_rails
bridges=trim_rails(m,bridges)
out={'trees':trees,'furniture':furniture,'lots':lots,'drives':drives,'bridges':bridges,'traffic_routes':routes,'paving_triangles':pads,'notes':'Procedural dressing; inferred cover and property frontages, not surveyed prop locations.'}
spawn_roads=[r for r in m['roads'] if r['name'] in ['Margaret St','Court St'] and not r['elevated'] and len(r['points'])>8]
if spawn_roads:
 r=min(spawn_roads,key=lambda r:min((p[0]+100)**2+(p[2]+500)**2 for p in r['points'][2:-2]));idx=min(range(2,len(r['points'])-2),key=lambda i:(r['points'][i][0]+100)**2+(r['points'][i][2]+500)**2)
 m['spawn']=r['points'][idx];m['spawn_next']=r['points'][idx+1];m['spawn_road']=r['name']
(d/'dressing.json').write_text(json.dumps(out,separators=(',',':')))
(d/'population.json').write_text(json.dumps({'traffic_routes':routes},separators=(',',':')))
endpoints={}
for road in m['roads']:
 for at in [0,-1]:
  point=road['points'][at];endpoints.setdefault((round(point[0],2),round(point[2],2)),[]).append((point,road['points'][1 if at==0 else -2]))
for closure in m['closures']:
 point=closure['point'];choices=endpoints.get((round(point[0],2),round(point[2],2)),[])
 if choices:closure['point'],closure['toward']=min(choices,key=lambda pair:abs(pair[0][1]-point[1]))
(d/'region.json').write_text(json.dumps(m,separators=(',',':')))
print({k:len(v) for k,v in out.items() if isinstance(v,list)},flush=True)

