# Hartford-inspired city / traversal milestone

This is an approximate map-guided arcade blockout, **not a surveyed 1:1
Hartford replica**. It replaces the previous square grid as the default scene.
Godot units are metres. Downtown road waypoints use an approximate geographic
projection anchored at (-72.6732, 41.7659); street relationships and spacing
come from hand-authored reference-map interpretation. Building footprints,
heights, park boundaries, terrain and local turns are authored approximations.
The regional highway links are compressed and the perimeter loop is fictional.

## Reference material and geographic distinctions

- City of Hartford street maps and GIS:
  https://www.hartfordct.gov/Government/Departments/MHIS/MHIS-Divisions/Hartford-GIS/Static-Maps
- City roads layer and its available attributes:
  https://gis.hartford.gov/arcgis/rest/services/AssessorBaseMap/MapServer/35
- UConn downtown Hartford reference map:
  https://law.media.uconn.edu/wp-content/uploads/sites/3082/2024/11/NECC-24-maps.pdf
- CTDOT regional/core highway relationships:
  https://portal.ct.gov/dot/programs/hartfordmobility/regional-and-core-component-vision
- CTDOT Route 3 / Putnam Bridge context:
  https://portal.ct.gov/dot/ctdot-construction-advisories/2026/mandatory-20-ton-truck-detour-for-putnam-bridge-in-wethersfield-and-glastonbury
- CTDOT's official Mixmaster designation is I-84 / Route 8 in Waterbury:
  https://portal.ct.gov/dot/ctdot-press-releases/2025/ctdot-announces-the-long-term-vision-for-the-replacement-of-the-waterbury-mixmaster

No live GIS geometry was imported: public layer metadata and reference maps
were accessible, but spatial queries/downloads were unavailable in this task.
`layout.json` records the authored waypoints and their accuracy limitation.
A true 1:1 phase needs validated street/footprint geometry and terrain heights.

## Playable layout

The world covers approximately 4.5km by 3.8km. It has 460+ building masses,
64 local road/path links, a Connecticut River corridor, Bushnell-inspired park
routes, local river crossings and west/south/north/east neighborhood approaches.
There are landmark silhouettes for the Capitol, Travelers Tower, Old State
House, Union Station, XL Center, Science Center and Convention Center.

The highway network has paired I-84 and I-91 carriageways at different levels,
four directional interchange ramps, Route 2 approaches, Route 3 / Putnam bridge
connections and cloverleaf turns. These routes form a connected driving network;
they do not reproduce every real interchange movement. A separate two-way
perimeter loop surrounds the playable city and has four local access points
with ramps on both carriageways. There are 32 ramps/connectors in total.

Local streets, park drives, lawns, forecourts and open alleys are traversable.
Ordinary sidewalks have beveled edges. Junctions omit crossing sidewalk strips
and lane paint. The car can climb small steps up to 0.32m after checking forward
and overhead clearance and a valid walkable landing. Tall walls and structural
columns remain solid. Bridge supports avoid lower road corridors.

Eleven fictional glass-fronted arcades provide drive-through shortcuts.
Their upper floors sit on solid corner columns, leaving the ground level open.
Entering a glass pane breaks its visual and emits short-lived glass particles;
the pane does not behave as an invisible solid wall. R returns the car to the
Hartford spawn and restores the glass. Water and leaving the playable extent
also return the car to spawn.

The existing pause menu, garage, performance brands, body parts, spoilers,
US/metric setting and car save preferences remain available. The map caches
static road geometry and updates the player marker at 20Hz, with river context.

## Source and generated assets

- `tools/build_hartford.gd` extends the original blockout builder and generates
  `scenes/hartford_district.tscn` plus `world/hartford/generated/*.res`.
- The .tscn contains the placed objects and references compressed editable
  mesh/collision resources. Generation runs offline, not while playing.
- Rebuild with Godot: `--headless --path . --script res://tools/build_hartford.gd`.
  Rebuilding replaces the generated scene/resources; keep manual changes in a
  derived scene or update the builder.
- The previous downtown blockout and test circuit remain available separately.

## Checks

`verify_curbs.gd`: curb ascent, sidewalk traversal/descent, tall-wall rejection.
`verify_hartford.gd`: collision and obstruction probes over all local streets,
main carriageways and ramp paths.
`verify_hartford_driving.gd`: real-car runs through 13 regional connectors,
eight perimeter ramps and both panes of a glass arcade, at up to 18m/s.
The existing handling, smoothing and garage tests provide regression coverage.

These are collision/driveability checks, not a survey-accuracy or full-city
performance certification. Preview captures were taken from the running game.


## Dense neighborhood infill

Current generated totals: 1,156 ordinary/landmark building masses, 256 local road links (including 131 service alleys), 10 highway carriageways, 32 ramps and four drive-through glass arcades.

The smaller streets and service alleys are fictional gameplay additions, not GIS-derived Hartford streets. Four infill areas connect to the arterial network. Alleys are 7m wide, unmarked, flush with the road surface, and open at both ends; neighborhood roads are 12–14m wide. Small commercial/apartment parcels include shop glazing, canopies, rooftop equipment and paved service margins. The park, river, landmark envelopes, highway clearances and glass-arcade approaches remain reserved.

Free asset candidates checked against their official pages:
- [Kenney City Kit (Commercial)](https://kenney.nl/assets/city-kit-commercial): 50 assets, CC0.
- [Kenney City Kit (Roads)](https://kenney.nl/assets/city-kit-roads): 90 assets, CC0.

These packs have not been imported. The current build uses authored meshes, including continuous terrain-following roads rather than flat road tiles. Download access from this environment is restricted; the links above record suitable candidates for a later art pass.
