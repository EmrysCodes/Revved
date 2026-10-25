# REVVED — Plattsburgh / Valcour geographic first pass

Implemented October 24, 2026. Version 0.6.0-plattsburgh-first-pass.

## Open and drive

Double-click **Open REVVED World Workshop.cmd** in the outputs folder. It now opens the full regional sample. In Godot, **Starter world** also opens this map. Use **Drive / F6** to save and test it, or choose **HANDBUILT CITY** in the normal game menu.

The editable sample is `res://world/handbuilt/plattsburgh_region.scn`. This is Godot's native binary scene format; you can edit it normally in Godot. The first editor opening can be slow because this is a full regional scene. Use Scene > Save As to keep your own copy before making extensive edits. The earlier small example remains at `res://world/handbuilt/workshop_starter.tscn`; New world still makes a separate blank scene.

## Included in this pass

- Approved extent: approximately half a mile north of 7981 US-9 to the Valcour pin; approximately 12.6 miles north–south. I-87 forms the western playable edge with a small roadside margin for barriers. The actual lake shoreline remains east.
- 1,633 in-bounds motor-road segments from NYS Streets. Shared junction pavement replaces independent overlapping strips in the new sample and newly created worlds. Both highway carriageways remain represented.
- 1,083 shared junction patches. Source endpoints at distinct physical heights remain separate; a plan-view crossing alone does not create an intersection. Nearly straight two-road continuations retain their center markings through the join.
- 8,101 individual, editable buildings based on real footprint polygons. Source IDs and unverified-height metadata are retained. Smaller footprints receive estimated residential forms, larger footprints estimated commercial forms.
- Measured USGS 3DEP bare-earth elevation, projected to UTM18N. Data is sampled into a 16 m grid and rendered with 32 m terrain mesh spacing. Regional elevations are not exaggerated. A shallow road formation is cut into terrain to keep pavement exposed. This is not centimetre-accurate pavement engineering.
- Water mask from actual NYS water polygons, including island holes. Lake surface and inland-water appearance are an initial approximation; upstream river water levels still need refinement.
- 43 road-exit closure barriers, an I-87 roadside boundary, 711 editable street-name signs and 989 approximate urban street lamps. Street names come from mapped streets; sign and lamp placements are not surveyed locations.
- Permanent night, existing car/camera/HUD/touch controls, land/water boundary recovery, and distance-based terrain/building visibility and collision layers.

## Editing

**Roads:** expand Roads, select an individual named source road, then use the Inspector to change Points, width, sidewalks, sample spacing or curve softness. Road centerlines can be picked in the 3D view; selecting a road exposes its cyan line and draggable control points. Dragging keeps a point at its current height; change Y in the Inspector for elevation. Native undo/redo works for handle drags. If light or collision icons clutter a large scene, hide Light3D and CollisionShape3D in the native 3D View / Gizmos controls. The local regional editing view is configured this way. The large source roads use zero curve softness to preserve the imported alignment; newly drawn roads use smooth curves.

New roads snap to nearby sampled source roads. Finish a draft with Enter. The road network rebuilds its spatial batches after edits; a large-map edit can take a moment. Use Select mode for normal Godot object movement. Erase can resolve a batched pavement hit back to its closest source road.

**Buildings:** expand Buildings > Tile > Property. Change Wall Height, Roof Style, Facade Style or Footprint in the Inspector. A building regenerates its shell and collision after those edits. The source ID remains attached to the node. You can also move/rotate a property or replace it with more detailed art.

**Terrain:** Terrain contains ordinary editable tile meshes and collisions. This version does not add a terrain sculpting brush. Moving imported roads far from their original alignments can require terrain work because the original road formation remains baked into the terrain. The aerial macro texture can also show the original road alignment. Do not expect road deletion to repaint the ground automatically.

The original small starter and existing career city are preserved. Existing career routes still use the earlier city; this regional scene is a separate handbuilt free-drive sample. No new career events or traffic lanes are authored for it yet.

## Accuracy and remaining work

The strongest correspondence is street alignment, footprint placement, shoreline and regional terrain. Building heights, roofs, façades, sign locations and 5.5 m initial bridge-clearance estimates are not verified replicas. All bridge clearances retain explicit unverified metadata. Ground elevation is bare earth, not a surveyed bridge deck; bridges and approaches need a dedicated review before racing at high speed.

This is a full-size geographic foundation, not a finished detailed city. Landmark models, residential architectural variety, forests, surveyed traffic controls, traffic routes, parking details and event placement remain future passes. Mobile controls are retained, but the large region has not been performance-tested on a phone.

The physics body budget is raised to 32,768 to accommodate the region's editable collision objects. This avoids dropping road collisions at the engine's smaller default limit. Distant building/ground groups have their collision layer disabled; those changes are staged across frames, with nearby activation prioritized, to reduce long-distance teleport spikes. Road geometry is batched into spatial tiles.

## Verification

- Shared-network fixture: continuous T-junction pavement and open road mouths; separate elevated crossing; no generated batch geometry serialized with the authored road data.
- Regional scene: all road/property/terrain counts present; current car and touch HUD present; native runtime load and generation checked.
- Sampled 981 road positions; 956 returned collision at source pavement height within 20 cm. Some exact endpoints/caps and a few local joins still need inspection. This is a sample, not a guarantee that every imported join is perfect.
- Existing arcade car completed a 1.472 km source US-9 segment with zero airborne physics frames.
- Source graph: downtown's connected component contains 1,240 of 1,334 endpoint/junction nodes and spans both the northern and southern map ends. Smaller disconnected components were retained rather than invented connections added.
- Native editor: creation, viewport placement, snapping, duplicate/delete, road settings, undo/redo, child/material selection and scene save/reload passed. Main-menu selection of the regional scene passed.
- Real game-view and native-editor screenshots captured for inspection. This is not a zero-warning run: the restricted environment reports user-data/certificate access and shutdown warnings.

## Source data and preparation

[NYS Streets](https://nysgeohub.ny.gov/arcgis/rest/services/Transportation/NYS_Streets/MapServer), [NYS Building Footprints](https://nysgeohub.ny.gov/arcgis/rest/services/Basemap/NYS_Building_Footprints/FeatureServer/1), [NYS Hydrography](https://nysgeohub.ny.gov/arcgis/rest/services/Hydrography/NYS_Hydrography/FeatureServer), [USDA / USGS NAIP aerial imagery](https://imagery.nationalmap.gov/arcgis/rest/services/USGSNAIPImagery/ImageServer), and [USGS 3DEP elevation](https://elevation.nationalmap.gov/arcgis/rest/services/3DEPElevation/ImageServer). Source ages vary. The statewide footprint dataset combines several source organizations; these footprints do not supply verified heights. No Google imagery was copied into the game.

Data and source geometry are in `world/plattsburgh/data/`; `region.json` records the geographic origin, bounds, source IDs, estimated bridge flags, road points and footprint shapes. Runtime helpers are in `world/plattsburgh/`. `tools/prepare_plattsburgh.py` prepares data from the locally collected public GIS source files using NumPy, Shapely, PyProj and Pillow. `tools/build_plattsburgh.gd` bakes the editable scene. Preparation tools are not required for normal editing or playing. Re-running the scene builder replaces the named generated sample, so save your edited world under a different name first.

No purchases, paid services, commits or pushes were performed. Unrelated existing changes were preserved. A new game export is required to share this region; the previously packaged game ZIP has not been updated.

## Prepared Git commit

**Summary:** Build full-size Plattsburgh sample and replace strip roads with shared junctions

**Description:** Import the approved Plattsburgh–Valcour street network, building footprints, shoreline and USGS elevation into a native editable regional scene. Add shared road-junction geometry, spatial mesh batches, road-point gizmos, approximate property shells, street-name signs, urban lamps and western/map-limit closures. Connect the sample to World Workshop and the Handbuilt City menu while retaining the earlier city and starter. Raise the physics body budget for regional collision objects and stage collision streaming to reduce teleport spikes. Validate junction continuity, separate elevated crossings, native editing/save/undo, menu launch and a 1.472 km US-9 drive. Building heights, façades, prop placement and bridge clearances remain an explicitly estimated first pass.
