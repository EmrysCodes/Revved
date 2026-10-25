import sys,json,math,pathlib,collections
import argparse
parser=argparse.ArgumentParser(description='Prepare approved Plattsburgh GIS sources for REVVED.')
parser.add_argument('--source',required=True,type=pathlib.Path)
parser.add_argument('--vendor',type=pathlib.Path)
parser.add_argument('--output',type=pathlib.Path,default=pathlib.Path(__file__).resolve().parents[1]/'world/plattsburgh/data')
args=parser.parse_args()
if args.vendor:sys.path.insert(0,str(args.vendor.resolve()))
import numpy as np
from PIL import Image,ImageDraw
from pyproj import Transformer
from shapely.geometry import Polygon,LineString,Point,box
from shapely.ops import unary_union
import shapely
SRC=args.source;DST=args.output;DST.mkdir(parents=True,exist_ok=True)
fwd=Transformer.from_crs(4326,32618,always_xy=True);rev=Transformer.from_crs(32618,4326,always_xy=True)
OX,ON=fwd.transform(-73.451,44.696);BASE=30.4
NORTH=44.7875;SOUTH=44.6050454
raw=json.loads((SRC/'streets-full.json').read_text())['features']
def proj(p):
 x,n=fwd.transform(*p[:2]);return (x-OX,ON-n)
def unproj(x,z):return rev.transform(x+OX,ON-z)
dem=np.asarray(Image.open(SRC/'elevation.tif'));DH,DW=dem.shape

def elevation(lon,lat):
 x=np.clip((np.asarray(lon)+73.535)/.185*DW-.5,0,DW-1.001);y=np.clip((44.794-np.asarray(lat))/.204*DH-.5,0,DH-1.001)
 ix=x.astype(int);iy=y.astype(int);fx=x-ix;fy=y-iy
 return dem[iy,ix]*(1-fx)*(1-fy)+dem[iy,np.minimum(ix+1,DW-1)]*fx*(1-fy)+dem[np.minimum(iy+1,DH-1),ix]*(1-fx)*fy+dem[np.minimum(iy+1,DH-1),np.minimum(ix+1,DW-1)]*fx*fy-BASE

def height(x,z):return float(elevation(*unproj(x,z)))
# West edge follows I-87, with a 20 m roadside margin for safe branch closures.
west=[p for f in raw if f['attributes']['Label']=='Interstate 87 Southbound' for path in f['geometry']['paths'] for p in path]
west=sorted(set(tuple(p) for p in west),key=lambda p:p[1]);wlats=np.array([p[1] for p in west]);wlons=np.array([p[0] for p in west])
def westlon(lat):return float(np.interp(lat,wlats,wlons))
boundary_ll=[(westlon(SOUTH)-.00025,SOUTH)]+[(p[0]-.00025,p[1]) for p in west if SOUTH<p[1]<NORTH]+[(westlon(NORTH)-.00025,NORTH),(-73.35,NORTH),(-73.35,SOUTH)]
play=Polygon([proj(p) for p in boundary_ll]).buffer(0)
# Render full surrounding terrain, while play limits are physically closed.
lo=proj((-73.54,44.798));hi=proj((-73.345,44.585));xmin=math.floor(min(lo[0],hi[0])/1024)*1024;xmax=math.ceil(max(lo[0],hi[0])/1024)*1024
zmin=math.floor(min(lo[1],hi[1])/1024)*1024;zmax=math.ceil(max(lo[1],hi[1])/1024)*1024
STEP=16;xs=np.arange(xmin,xmax+1,STEP);zs=np.arange(zmin,zmax+1,STEP);xx,zz=np.meshgrid(xs,zs);lon,lat=unproj(xx,zz);hs=elevation(lon,lat)
# Actual water polygons, including island holes.
waters=[]
for f in json.loads((SRC/'water.json').read_text())['features']:
 outers=[];holes=[]
 for ring in f['geometry']['rings']:
  area=sum(a[0]*b[1]-b[0]*a[1] for a,b in zip(ring,ring[1:]));pr=[proj(p) for p in ring]
  (outers if area<0 else holes).append(Polygon(pr).buffer(0))
 geom=unary_union(outers)
 if holes:geom=geom.difference(unary_union(holes))
 waters.append(geom)
water=unary_union(waters).intersection(box(xmin,zmin,xmax,zmax));wm=Image.new('L',(len(xs),len(zs)));draw=ImageDraw.Draw(wm)
def gridpts(coords):return [((x-xmin)/STEP,(z-zmin)/STEP) for x,z in coords]
for g in shapely.get_parts(water):
 if not isinstance(g,Polygon):continue
 draw.polygon(gridpts(g.exterior.coords),fill=255)
 for h in g.interiors:draw.polygon(gridpts(h.coords),fill=0)
wa=np.array(wm)>127
# Lake bed is below the measured shoreline surface; elevations on land are unexaggerated.
hs[wa]=np.minimum(hs[wa],-2.5)
# Keep every motor-road segment in bounds. Source Z levels distinguish over/underpasses.
roads=[];closures=[];excluded=0
for f in raw:
 a=f['attributes'];fcc=a.get('FCC') or ''
 if fcc in ['A71','A74','A73','A76','A75','A70']:excluded+=1;continue
 for path in f['geometry']['paths']:
  source=LineString([proj(p) for p in path]);clipped=source.intersection(play)
  for line in shapely.get_parts(clipped):
   if not isinstance(line,LineString) or line.length<3:continue
   shield=a.get('SHIELD');ramp=fcc in ['A63','A60','A61','A62'];w=7.6 if shield=='I' else (6.2 if ramp else (10.5 if shield in ['S','U'] else 7.5))
   if fcc in ['A45','A40']:w=5.5
   walk=0 if shield=='I' or ramp else (1.8 if abs(line.centroid.x)<1800 and abs(line.centroid.y)<2600 else 0)
   # Resample source polylines without spline overshoot. Preserve every native vertex.
   coords=list(line.coords);dense=[]
   for p,q in zip(coords,coords[1:]):
    n=max(1,math.ceil(math.dist(p,q)/10))
    for j in range(n):dense.append((p[0]+(q[0]-p[0])*j/n,p[1]+(q[1]-p[1])*j/n))
   dense.append(coords[-1]);dist=np.array([source.project(Point(p)) for p in dense]);ratio=np.clip(dist/max(1,source.length),0,1)
   # Levels are topological identifiers; DEM supplies ground. Elevated endpoints get
   # an initial 5.5 m clearance estimate, explicitly retained as unverified metadata.
   l0=int(a.get('FromZlev') or 0);l1=int(a.get('ToZlev') or 0);lift=(1-ratio)*l0*5.5+ratio*l1*5.5
   heights=np.array([height(*p) for p in dense])
   if max(l0,l1)>0:
    bank=max(heights[0],heights[-1]);heights=np.maximum(heights,bank-1.5)
   pts=[[round(p[0],3),round(float(h)+float(l)+.22,3),round(p[1],3)] for p,h,l in zip(dense,heights,lift)]
   end_levels=[l0 if source.project(Point(coords[0]))<.5 else 0,l1 if source.project(Point(coords[-1]))>source.length-.5 else 0]
   entry={'id':int(a['OBJECTID']),'name':a['Label'] or 'Local road','width':w,'sidewalk':walk,'points':pts,'levels':end_levels,'elevated':bool(l0 or l1),'one_way':a.get('OneWay'),'fcc':fcc}
   roads.append(entry)
   if shield!='I':
    for idx in [0,-1]:
     ep=Point(coords[idx]);original_end=Point(source.coords[0 if idx==0 else -1]);is_cut=ep.distance(original_end)>1
     if is_cut:closures.append({'point':pts[idx],'toward':pts[1 if idx==0 else -2],'name':entry['name'],'width':w})
# Canonicalize connected source endpoints at the same source Z level.
endpoint_groups={}
for r in roads:
 for i,idx in enumerate([0,-1]):
  p=r['points'][idx];key=(round(p[0],1),round(p[2],1),r['levels'][i]);endpoint_groups.setdefault(key,[]).append((r,idx))
for refs in endpoint_groups.values():
 y=sum(r['points'][idx][1] for r,idx in refs)/len(refs)
 for r,idx in refs:r['points'][idx][1]=round(y,3)
# Remove duplicate road records (the service contains some coincident address splits).
unique={}
for r in roads:
 key=tuple(tuple(p) for p in [r['points'][0],r['points'][-1]])
 if key not in unique:unique[key]=r
roads=list(unique.values())
# Stamp a shallow, road-following formation into the terrain. The road mesh remains
# above it; elevated bridges do not raise the bare-earth ground underneath.
for r in roads:
 if r['elevated']:continue
 radius=r['width']/2+r['sidewalk']+STEP*1.3
 for a,b in zip(r['points'],r['points'][1:]):
  ix0=max(0,int((min(a[0],b[0])-radius-xmin)/STEP));ix1=min(len(xs)-1,int((max(a[0],b[0])+radius-xmin)/STEP)+1)
  iz0=max(0,int((min(a[2],b[2])-radius-zmin)/STEP));iz1=min(len(zs)-1,int((max(a[2],b[2])+radius-zmin)/STEP)+1)
  xg=xx[iz0:iz1+1,ix0:ix1+1];zg=zz[iz0:iz1+1,ix0:ix1+1];dx=b[0]-a[0];dz=b[2]-a[2];t=np.clip(((xg-a[0])*dx+(zg-a[2])*dz)/max(.01,dx*dx+dz*dz),0,1)
  ds=(xg-a[0]-t*dx)**2+(zg-a[2]-t*dz)**2;target=a[1]+(b[1]-a[1])*t-.65
  view=hs[iz0:iz1+1,ix0:ix1+1];sel=ds<radius*radius;view[sel]=np.minimum(view[sel],target[sel])
# 16-bit PNG = centimetre precision, with -32 m representable for lake bed.
encoded=np.clip(np.rint((hs+32)*200),0,65535).astype(np.uint16)
Image.fromarray(encoded).save(DST/'terrain_height.png');hs.astype('<f4').tofile(DST/'terrain_height.bin');wm.save(DST/'water_mask.png')
# Local-projected aerial macro colour, not Google imagery.
aerial=Image.open(SRC/'aerial.jpg').convert('RGB');am=json.loads((SRC/'aerial-metadata.json').read_text())['extent'];to_merc=Transformer.from_crs(4326,3857,always_xy=True)
aw,ah=2048,4096;ax=np.linspace(xmin,xmax,aw);az=np.linspace(zmin,zmax,ah);gx,gz=np.meshgrid(ax,az);al,at=unproj(gx,gz);mx,my=to_merc.transform(al,at);sx=np.clip(((mx-am['xmin'])/(am['xmax']-am['xmin'])*(aerial.width-1)).astype(int),0,aerial.width-1);sy=np.clip(((am['ymax']-my)/(am['ymax']-am['ymin'])*(aerial.height-1)).astype(int),0,aerial.height-1);Image.fromarray(np.asarray(aerial)[sy,sx]).save(DST/'ground_macro.jpg',quality=90)
# Buildings keep their real polygon and position. Heights/styles are estimates.
buildings=[]
for path in sorted(SRC.glob('buildings-*.json')):
 for f in json.loads(path.read_text())['features']:
  rings=f['geometry']['rings'];poly=Polygon([proj(p) for p in rings[0]]).buffer(0)
  if poly.is_empty or not isinstance(poly,Polygon) or not play.covers(poly.representative_point()) or poly.area<12:continue
  poly=poly.simplify(.22,preserve_topology=True)
  if poly.intersects(water) and water.intersection(poly).area>poly.area*.5:continue
  center=poly.centroid;x,z=center.x,center.y;ring=list(poly.exterior.coords)[:-1];area=poly.area;seed=int(f['attributes']['OBJECTID']);house=area<250
  downtown=abs(x)<1300 and abs(z)<1800
  h=(3.1 if area<65 else 6.3) if house else ((9.5+(seed%3)*3) if downtown and area<2500 else (5.5 if area<600 else 8.5))
  foundation=max(height(*p) for p in ring)
  buildings.append({'id':seed,'position':[round(x,3),round(foundation,3),round(z,3)],'footprint':[[round(px-x,3),round(pz-z,3)] for px,pz in ring],'height':h,'style':seed%8,'roof':1 if house else 0,'estimated':True})
# Close the actual western edge and N/S road exits, never put walls across I-87.
# Northern/southern interstate caps are intentional outer map limits.
for r in roads:
 if r['fcc']=='A15':
  for idx in [0,-1]:
   p=r['points'][idx];_,la=unproj(p[0],p[2])
   if abs(la-NORTH)<.00003 or abs(la-SOUTH)<.00003:closures.append({'point':p,'toward':r['points'][1 if idx==0 else -2],'name':'I-87 / map limit','width':r['width']})
# Exact western-edge fence path; collidable northern/southern caps added by scene builder.
edge=[[round(x,3),round(height(x,z),3),round(z,3)] for x,z in [proj(p) for p in boundary_ll[:-2]]]
spawn_geo=(-73.4515,44.6958);sp=np.array(proj(spawn_geo));candidates=[r for r in roads if r['name'] in ['Margaret St','Bridge St','Broad St','Cornelia St']]
spawn_road=min(candidates,key=lambda r:min((p[0]-sp[0])**2+(p[2]-sp[1])**2 for p in r['points']));spawn=min(range(len(spawn_road['points'])-1),key=lambda i:(spawn_road['points'][i][0]-sp[0])**2+(spawn_road['points'][i][2]-sp[1])**2)
# Provenance plus edit-friendly source data; no proprietary map tiles.
manifest={'name':'Plattsburgh to Valcour','projection':'EPSG:32618 / WGS84 UTM18N','origin_utm':[OX,ON],'base_elevation_m':BASE,'bounds':[xmin,zmin,xmax,zmax],'step':STEP,'grid_size':[len(xs),len(zs)],'north':NORTH,'south':SOUTH,'roads':roads,'buildings':buildings,'closures':closures,'west_edge':edge,'spawn':spawn_road['points'][spawn],'spawn_next':spawn_road['points'][spawn+1],'spawn_road':spawn_road['name'],'notes':'Geographic first pass. Building heights and bridge clearances are estimates. Ground uses USGS 3DEP bare-earth heights.'}
(DST/'region.json').write_text(json.dumps(manifest,separators=(',',':')))
print('REGION PREPARED',len(roads),'roads',len(buildings),'buildings',len(closures),'closures','grid',hs.shape,'height',float(hs.min()),float(hs.max()),'spawn',manifest['spawn_road'],flush=True)
