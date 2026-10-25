# Champlain Coast map and prototype integration — 0.7.0

This checkpoint finishes the regional map and connects the existing single-player systems to it. The next action is Git review and commit. This step does not publish a release or create a new distributable game package.

## Changes

- Free Roam, Single Race, Street Legacy, the event board and career garage use the Plattsburgh / Valcour region. The menu footer identifies `CHAMPLAIN COAST PROTOTYPE / v0.7.0 / SINGLE PLAYER`.
- The approved bounds remain: just north of 7981 US-9 to Valcour, I-87 at the western playable edge and Lake Champlain to the east. The north–south span remains approximately 12.6 miles at real horizontal scale.
- The editable native scene contains 1,633 road records, 8,101 building footprints, 391 terrain tiles and 711 street-name signs. Suitable commercial footprints use 597 detailed instances from the already available Modern City Environment models. Generated properties have improved façades, roofs, entrances, cornices and foundations.
- Added 49,271 clearance-checked trees, 4,178 drives, 290 parking areas, commercial aprons, 4,380 furniture placements and 90 parked cars. The final lamp pass places 1,043 lights and checks neighbouring carriageways. Generated lamps are non-blocking.
- Repaired grades and bridge approaches: topology levels no longer create impossible short ramps. Engineered road grades stay within approximately 12%; broad terrain elevations come from USGS 3DEP. Terrain follows the nearest road formation, curbs have traversable bevels, bridge rails leave junction mouths open, and inland water remains below crossing decks.
- Merged road collision into one coordinate frame to remove seams between translated tile bodies. Pavement contact takes priority over coarse water pixels during recovery.
- Added eight traffic circuits, up to 16 ambient cars and 30 animated pedestrians on desktop, bounded nearby-engine playback and city / highway / nature / wind / water ambience. Mobile population and tree detail are reduced.
- Added a local street map, current-street header, live US/metric scale and regional labels. Race GPS uses the regional road network. Touch controls bind to the generated map and event.
- Built 18 events across Downtown / Plattsburgh and Valcour / Champlain Coast: circuits, sprints, time attacks, crew duels and finals. Route revision 101 separates these course records from old Hartford times. Event IDs preserve existing driver identity, credits and wins.
- Preserved driver creation, 20 portraits, balanced backgrounds, upgrade tiers/brand tradeoffs, garage previews, supported visual customization, saving, unit preferences, audio/display settings, pause/retry and results actions.

## Validation

- All **18 events** completed with the actual stock-car controller, ordered checkpoint crossings and finish logic.
- All **nine AI entrants** tested across the opening race, a downtown circuit and a coastal circuit finished without recovery.
- Final regional audit: **41,784 / 41,815** sampled road positions meet the authored pavement grade within 22 cm (**99.93%**). The test passes its 99.5% threshold. The remaining samples include overlaps and local terrain/grade differences; this is not a claim that every road has been surveyed or manually driven.
- Campaign progression, practice/reward separation, purchase rollback, route structures and local save persistence passed.
- Driver creation, portrait selection, career map layout, garage entry and return passed.
- GPS turn semantics and separation from race information / touch controls passed at the tested desktop and small-window sizes.
- US/metric conversion and persistence, R34-style performance progression, garage brand/part combinations and finish-screen layout passed.
- World Workshop closed-loop driving, elevated road/deck driving and menu launch passed.
- Native rendered captures are available for the main menu, event maps, streets, race GPS and garage. These are engine screenshots, not generated concept art.

Tests use Godot's fixed-frame simulation where appropriate. This is actual controller/collision coverage, followed by rendered inspection, rather than a substitute for human playtesting. Console logs include environment-specific certificate/log/cache-folder warnings. Some old test harnesses also retain shutdown resource warnings; no warning-free engine shutdown is claimed.

## Scope and limitations

This is a single-player prototype, not a finished commercial game. Online remains an explicitly unavailable menu preview. No money was spent; the work reused available assets and geographic data.

Street alignments, building footprints and shoreline come from geographic sources. Individual façades, building heights, planting, signs, parking layouts, bridge structures and road widths are approximations. Road grades and adjacent terrain are engineered for driving. There are no building interiors or surveyed individual real-world signs; the environment mixes detailed models and generated architecture.

Touch input and responsive layouts were tested on desktop. No physical-phone/Xogot run is claimed. No new Windows or phone distribution package is included in this commit checkpoint.

## Project and editing

Checkout: `C:\Users\joshu\Documents\Codex\Revved`.

Branch: `main`. Origin: `https://github.com/EmrysCodes/Revved.git`.

Active scene: `world/handbuilt/plattsburgh_region.scn`. This is a compressed native Godot scene with editable source roads and properties. Repeated vegetation/furniture use saved batches. Save a copy before rerunning generators over hand edits.

Preparation: `tools/prepare_plattsburgh.py`, `tools/finish_plattsburgh.py`, `tools/regional_grades.py`, `tools/build_regional_campaign.py`, `tools/build_regional_event_map.py` and `tools/build_plattsburgh.gd`. Original local GIS/DEM inputs remain in the task's `work/plattsburgh-reference`; geometry libraries remain in `work/geo_vendor`.

The compressed map is about 84 MB, below GitHub's 100 MiB single-file limit. Fab source assets remain ignored under `assets/licensed/` and must remain available locally. `.godot` and Python caches stay ignored.

## Git commit text

**Summary**

Finish Champlain Coast map and connect Street Legacy

**Description**

Finish the Plattsburgh–Valcour map with joined roads, repaired grades and bridge approaches, varied buildings, terrain dressing, traffic, pedestrians and positional ambience. Add a local street map and integrate Free Roam, the garage and the two-chapter, 18-event Street Legacy campaign with the regional level.

Fix curb traversal, misplaced lamp collisions, bridge-water recovery, AI racing lines and event-map rendering. Preserve local progression and settings; version the new course records separately. Validate all 18 events with the stock controller, representative AI races, saving/progression, garage flows, GPS, touch layouts and World Workshop driving.

## Provenance

NYS ITS Geospatial Services: Streets, Building Footprints and Hydrography. USGS: 3DEP terrain. USDA/USGS NAIP: broad land-cover inference. Existing project credits retain Modern City Environment, vehicle, Quaternius, Kenney, sound-pack and engine attribution/license information. No new paid asset license was acquired.
