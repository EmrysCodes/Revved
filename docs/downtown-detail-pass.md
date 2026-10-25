# REVVED 0.3.3 — Downtown Detail

This milestone furnishes the Main / Trumbull / Asylum / Pearl driving loop in the normal city. Free Roam, Single Race and Street Legacy all load it. Street names and layout remain approximate, with fictional businesses.

- Twelve fitted shopfronts with doors, window mullions, canopies, business signs and warm entrance lighting.
- Twenty striped crossings and street-name signs around six downtown junctions.
- Two glass transit shelters with seating, route boards and overhead lighting.
- A sixteen-space parking court between Asylum and the rear-access street, with six parked licensed car models, paint, wheel stops and planting.
- Pearl Court, a small furnished space between existing buildings, with two detailed trees, benches and paving bands.
- Three service-apron clusters with bins and delivery pallets.
- Authored reservations keep the general tree/furniture scatter out of these spaces and shop entrances. Nearby entrance/shelter light points use the existing bounded streetlight pool.

The original road/highway/ramp routes and static collision geometry are preserved. These new furnishings and parked cars have no driving collision, consistent with the game's soft street props. Crossings are visual markings; this pass does not add pedestrian right-of-way logic or new destinations. It improves a small downtown area; the entire city still needs more varied architecture and proportion work. No money was spent and no assets were downloaded.

Validation: the new detail test checks unchanged static collision and route arrays, clearance of both public-space footprints from road corridors and building collision, detail coverage and scatter exclusions. The real car controller completes the first 439 sampled points of Capital Run's downtown section, reaching cursor 432 with zero airborne frames. Existing front-end, career persistence and street-dressing checks pass. Rendered screenshots were inspected and a misplaced plaza and shopfront tree overlap were corrected. Phone performance was not tested. The test environment still reports its existing log/certificate restrictions and shutdown resource warnings.

Git Summary:
Add a furnished downtown driving loop

Git Description:
Add twelve lit shopfronts, twenty crossings, street-name signs, two transit shelters, a sixteen-space parking court with six licensed cars, Pearl Court and service-apron details to the normal Hartford city. Reserve authored spaces from generic vegetation and furniture placement, and share nearby shop and shelter lighting through the existing light pool. Preserve city collision, highway routes and race geometry. Include the street-layout data in exports and label the release 0.3.3-downtown-detail.

Validated public-space clearances, unchanged static collision and routes, actual downtown controller driving and front-end/career regressions. No commit or push was performed.
