# Hartford-inspired city / traversal milestone

## Green buffers and street life

Vacant outer parcels and highway buffers now use grass instead of continuous
concrete; the compact downtown retains paving and existing beveled sidewalks.
`city_life.gd` deterministically adds 2,273 clustered-canopy trees, 936 slatted
benches, 870 bins, 2,407 street lamps, 646 banners, 522 planters and 264 small
path tiles. These are original simple meshes, batched spatially and distance
culled. Placement checks reject road corridors, buildings and low structural
clearances. Soft street props have no vehicle collision, preserving traversal.
They are runtime dressing, rather than additional saved building geometry.
This milestone does not add moving traffic, pedestrians or a day/night cycle.

This is an approximate map-guided arcade city, **not a surveyed 1:1
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

The world covers approximately 4.5km by 3.8km. It has 2,092 Quaternius buildings,
seven landmark masses and 211 local road/path links, a Connecticut River corridor, Bushnell-inspired park
routes, local river crossings and west/south/north/east neighborhood approaches.
There are landmark silhouettes for the Capitol, Travelers Tower, Old State
House, Union Station, XL Center, Science Center and Convention Center.

The highway network has paired I-84 and I-91 carriageways at different levels,
four directional interchange ramps, Route 2 approaches, Route 3 / Putnam bridge
connections and cloverleaf turns. These routes form a connected driving network;
they do not reproduce every real interchange movement. A separate two-way
perimeter loop surrounds the playable city and has four local access points
with ramps on both carriageways. There are 33 ramps/connectors in total,
including the I-91 south to Columbus exit used by Capital Run.

Local streets, park drives, lawns, forecourts and open alleys are traversable.
Ordinary sidewalks have beveled edges. Junctions omit crossing sidewalk strips
and lane paint. The car can climb small steps up to 0.32m after checking forward
and overhead clearance and a valid walkable landing. Tall walls and structural
columns remain solid. Bridge supports avoid lower road corridors.

Three fictional glass-fronted arcades provide drive-through shortcuts.
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
- `assets/city/quaternius_downtown` contains the CC0 Standard kit (153 models,
  29 shared textures and license). `tools/city_kit.gd` places its building models
  and props in spatial rendering groups with individual simple building collisions.
  Saved placements restore in the editor and game through `kit_instances.gd`;
  this avoids the headless renderer dropping grouped instance buffers when saving.
- Asphalt and sidewalks use kit textures; urban lots use textured paving while
  park grounds and river banks stay green. Imported textures have mipmaps and
  anisotropic filtering, and source vertex wear masks are not treated as red paint.
- Rebuild with Godot: `--headless --path . --script res://tools/build_hartford.gd`.
  Rebuilding replaces the generated scene/resources; keep manual changes in a
  derived scene or update the builder.
- The previous downtown blockout and test circuit remain available separately.

## Checks

`verify_curbs.gd`: curb ascent, sidewalk traversal/descent, tall-wall rejection.
`verify_hartford.gd`: collision and obstruction probes over all local streets,
main carriageways and ramp paths, vehicle-height clearance on local roads,
kit placement persistence and imported architecture counts.
`verify_hartford_driving.gd`: real-car runs through 13 regional connectors,
eight perimeter ramps and both panes of a glass arcade, at up to 18m/s.
The existing handling, smoothing and garage tests provide regression coverage.
`verify_flowing_city.gd`: drives all four rounded neighborhood boulevards at
30m/s (about 67 MPH) and their four arterial approaches.
`verify_high_speed_control.gd`: planted turns, bounded handbrake slides and
release recovery at 80, 120 and 150 MPH.

These are collision/driveability checks, not a survey-accuracy or full-city
performance certification. Preview captures were taken from the running game.


## Dense neighborhood infill

Current generated totals: 2,099 ordinary/landmark buildings (2,092 use imported Quaternius architecture), 1,693 kit props, 211 local road links (including 131 service alleys), 10 highway carriageways, 33 ramps and three drive-through glass arcades.

The smaller streets and service alleys are fictional gameplay additions, not GIS-derived Hartford streets. Four infill areas connect to the arterial network. Their 16m perimeter boulevards have 65m-radius rounded corners; local streets use gentle shared bends, and main road paths use smooth curves through their geographic anchors. Alleys are 7m wide, unmarked and flush; neighborhood roads are 12–14m wide. Imported buildings face nearby streets and include detailed facades, entrances, windows and roofs. AC units, planters and manhole covers add detail. The park, river, landmark envelopes, highway clearances and glass-arcade approaches remain reserved.

Free asset candidates checked against their official pages:
- [Kenney City Kit (Commercial)](https://kenney.nl/assets/city-kit-commercial): 50 assets, CC0.
- [Kenney City Kit (Roads)](https://kenney.nl/assets/city-kit-roads): 90 assets, CC0.

The Kenney packs were not imported. The city now uses the [Quaternius Downtown City MegaKit Standard edition](https://quaternius.com/packs/downtowncitymegakit.html), with its license retained. Roads remain continuous terrain-following geometry using kit materials, rather than placing flat road tiles across the hills. The free kit's three complete building models are reused with varying dimensions, heights and orientation; more individual-module combinations can expand facade variety later. The seven landmark silhouettes remain approximate authored masses.
