import argparse,pathlib,json,sys
p=argparse.ArgumentParser();p.add_argument('--vendor',required=True);p.add_argument('--source',required=True,type=pathlib.Path);a=p.parse_args();sys.path.insert(0,a.vendor)
from pyproj import Transformer
from shapely.geometry import Polygon
root=pathlib.Path(__file__).resolve().parents[1];m=json.loads((root/'world/plattsburgh/data/region.json').read_text());fwd=Transformer.from_crs(4326,32618,always_xy=True)
def proj(p):
 x,n=fwd.transform(*p[:2]);return [round(x-m['origin_utm'][0],1),round(m['origin_utm'][1]-n,1)]
data={'roads':[],'highways':[],'ramps':[],'water':[],'water_rings':[],'map_size':[11500,22000],'map_center':[1800,0]}
for r in m['roads']:
 category='highways' if r['fcc']=='A15' else ('ramps' if r['fcc'] in ['A63','A60','A61','A62'] else 'roads');line=[[p[0],p[2]] for p in r['points']];data[category].append(line[::2]+[line[-1]])
for feature in json.loads((a.source/'water.json').read_text())['features']:
 for ring in feature['geometry']['rings']:
  hole=sum(p[0]*q[1]-q[0]*p[1] for p,q in zip(ring,ring[1:]))>0
  poly=Polygon([proj(p) for p in ring]).simplify(15,preserve_topology=True)
  if not poly.is_empty and poly.geom_type=='Polygon':data['water_rings'].append({'points':list(poly.exterior.coords),'hole':hole})
(root/'ui/legacy/city_map.json').write_text(json.dumps(data,separators=(',',':')))
print('REGIONAL EVENT MAP',len(data['roads']),'streets',len(data['water_rings']),'water rings')
