"""Bake one coverage map, so intersecting roads do not fight for the same pixels."""
from pathlib import Path
import json
from PIL import Image, ImageDraw
root = Path(__file__).resolve().parents[1]
data = json.loads((root / 'world/hartford/street_plan.json').read_text())
size = (4096, 3456)
scale = size[0] / 4500
road = Image.new('L', size)
walk = Image.new('L', size)
rd, wd = ImageDraw.Draw(road), ImageDraw.Draw(walk)
def point(p): return ((p[0]+2250)*scale, (p[2]+1900)*scale)
def stroke(draw, points, width):
    width = max(1, round(width*scale))
    coords = [point(p) for p in points]
    draw.line(coords, fill=255, width=width, joint='curve')
    radius = width / 2
    for x,y in [coords[0], coords[-1]]:
        draw.ellipse((x-radius,y-radius,x+radius,y+radius),fill=255)
for lot in data['lots']: wd.polygon([point(p) for p in lot],fill=255)
for route in data['roads'] + data['connections']:
    stroke(wd,route['points'],route['width']+8)
    stroke(rd,route['points'],route['width'])
mask = Image.merge('RGB',(road,walk,Image.new('L',size)))
mask.save(root / 'world/hartford/street_coverage.png',optimize=True)
print('STREET MASK PASS',size,len(data['roads']),'joined paths')
