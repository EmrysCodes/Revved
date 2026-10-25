# REVVED 0.4.0 — City & Results Update

## Rendering and streets

The main playable city now uses twelve opaque facade families with metre-scaled windows, distinct bay/floor spacing, brick, stone, apartment, warehouse and office treatments, stepped towers, cornices and roof plant. These replace the stretched photographic buildings and overlapping four-view distant impostors across 2,252 original lots. A fixed, subdued street reflection capture replaces the moving capture. Asphalt has a dry, rough finish. The architecture remains stylized and needs further bespoke landmark and street-level art.

A single terrain-following mesh and collision surface replace 222 overlapping ground-level street sheets, their sidewalk collision strips and the old ground sheet. One filtered coverage map gives junctions continuous asphalt and pavement coverage. Highway, ramp and two elevated street/bridge surfaces keep their original geometry. All authored route coordinates remain unchanged. The endpoint audit found no safe short missing links to add; the fixes address surface joins rather than inventing extra junctions. Road coverage has mipmaps, and the new building families have no near/far impostor overlap.

There are 1,052 additional low-rise parcels along Downtown and Eastside street edges. Placement excludes existing buildings, street corridors, every highway/ramp footprint, current race paths, Bushnell Park and the authored public spaces. Nearby vegetation/furniture responds to the new solid buildings. Existing detailed trees, storefronts, shelters and other dressing remain. No money was spent, and no assets were downloaded. The facades reuse the existing Quaternius brick texture and the game's own geometry/shaders.

## Finish screen and UI

The finish screen now uses the shared racing theme: large single-line placing, victory/target status, finish time, a real personal-best indicator, a separate rewards/unlocks section and highlighted player classification. It hides stale career rewards in practice. The time-trial failure state has a distinct red RETRY indicator. Classification can scroll while the 50-pixel action buttons remain visible. Career returns to EVENT MAP; practice returns to FREE ROAM. Keyboard focus and interaction sounds follow the menu theme. Race information now shares that theme too.

The finish-screen screenshots are UI previews populated with example results; they do not represent a recorded career victory. The driving screenshot comes from the actual running race.

## Validation

- 1,474 downward physics checks across the ground streets; upright, continuous driving surface.
- 6,656 real car-volume samples across all 18 route files; no new infill blocks a route.
- Real controller driving through the downtown race section: completed with zero airborne frames.
- Real controller driving through neighborhood links, thirteen named highway connectors, eight perimeter ramps and the glass arcade: passed. An initial ramp obstruction from infill was corrected by reserving all highway/ramp footprints.
- Results at 1600×900, 1280×720, 640×360 and 393×852: fit, readable unscaled action targets, one-line placing, long names, target failure, practice reward isolation and both button signals.
- Existing GPS turn semantics, distance and touch-layout checks passed.
- Short 1600×900 live driving sample with rivals, traffic and pedestrians: 7.08 ms average / 9.17 ms 95th percentile, one frame above 50 ms, about 1.61 GiB reported video memory. This is a local laptop sample, not a whole-city or phone performance guarantee. Actual phone performance was not tested.
- The environment still reports its existing log/certificate restrictions and shutdown texture/resource warnings. No antivirus scan was verified.

## Git milestone

Summary: Stabilize city rendering, join street surfaces and redesign race results

Description: Replace stretched repeated buildings and overlapping distant impostors with twelve opaque facade families, and add 1,052 low-rise parcels with street, race, highway and ramp clearances. Replace overlapping ground street/sidewalk sheets with a continuous rendered and physical surface while retaining elevated roads and authored race routes. Stabilize street reflections and reduce asphalt glare. Redesign the finish screen with clear placement/time, records, separate rewards, highlighted standings and persistent responsive actions; apply the shared racing theme to the race HUD.

Validate city floor coverage, all event corridors, actual downtown/highway/ramp/arcade driving, GPS behavior and responsive results interactions. Version 0.4.0-city-polish. Changes are local; no commit or push was performed.

Rebuild order: tools/build_city_architecture_v2.gd; tools/audit_city_streets.gd; tools/prepare_street_mask.py; import street_coverage.png with mipmaps; tools/build_continuous_streets.gd; tools/build_city_infill.gd. The older build_city_art.gd produces the previous art and should not be used for this milestone.
