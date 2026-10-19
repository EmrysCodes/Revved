# REVVED — two-district development pass

Work completed October 19, 2026. No purchases, subscriptions, paid generation or paid credits were used.

## City references and scope
The playable world is an authored, compressed Hartford-inspired city, not a surveyed 1:1 recreation. The street relationships, mixed-use frontage and East Hartford land uses were informed by these primary sources:

- [Hartford Complete Streets plan](https://www.hartfordct.gov/files/assets/public/v/1/development-services/planning-zoning/pz-documents/cs-projects/complete-streets-plan-city-of-hartford__final_2.pdf): connected streets, walkable frontages, sidewalks and public-space treatment.
- [Reimagining Main Street](https://www.hartfordct.gov/files/assets/public/development-services/planning-zoning/pz-documents/cs-projects/reimagining_main_st_final_report.pdf): downtown street and frontage references.
- [East Hartford Founders Plaza plan](https://www.easthartfordct.gov/sites/g/files/vyhlif9241/f/uploads/founders_plaza_chapter_8-15-24.pdf): Pitkin, Hartland, Jayce, Meadow, Darlin and Main Street relationships, riverfront access, mixed-use redevelopment and green space. This is a planning reference, not a claim that the proposed development exists today.

Eastside adds thirteen road connections, shops, apartments, service lanes, marked parking courts, awnings and crosswalks. A supplemental frontage pass adds 106 building placements and 21 parking courts, beyond the main city build. Street props remain soft so driving routes remain open. Downtown and Eastside connect over the river and through the existing highway network. Only two of the four projected districts are built.

## Street Legacy
Two chapters, nine events each: IGNITION / Capitol Collective, then AFTER THE RIVER / River Ghosts. Sprints, two time attacks, multi-lap circuits, one-on-one crew duels and district finals. Wins unlock tiers; the downtown final opens chapter two. First wins pay full fictional CR rewards; repeat wins pay less. Saved personal-best times are separated by course revision, while victories and earned credits survive a route update. Career upgrades spend fictional CR and include all balanced brand variants at the purchased level. Practice has no career rewards. The map shows event locations, availability, wins and the selected route. Garage is available in Street Legacy.

## Navigation and population
The top-center GPS uses a large turn arrow, an along-route distance countdown in feet/miles, a heading-up route preview on wide screens, and wrong-way/off-route warnings. Race information is at the top right. Checkpoints are positioned away from turn entries where possible. The course generator removes immediate dead-end backtracking and rounds the original Capital Run joins. Narrow alley race junctions give approaching racers priority.

Desktop population: 70 lane-following traffic vehicles with steering/rolling wheels, braking and close-contact yield checks, six alternating signal junctions, and 110 animated pedestrians split 55/55 across both districts. Distant pedestrians stop animating. Mobile population and animation distance are reduced. Pedestrians do not block the player. This is a first city population system, not a full traffic simulation: unusual congestion and intersection conflicts can still occur.

## Free assets researched and used
| Source | Rights stated by creator | Status / practical fit |
|---|---|---|
| [Kenney Car Kit](https://kenney.nl/assets/car-kit) | CC0 | Downloaded and imported selected GLB vehicles and wheels for traffic and parking. Lightweight, separate wheel nodes; stylized rather than realistic hero cars. |
| [Quaternius Ultimate Modular Men](https://quaternius.com/packs/ultimatemodularcharacters.html) | Pack page explicitly CC0 | Five characters imported with walk/run/idle animations for city pedestrians. Creator-linked glTF download used. |
| [Quaternius Downtown City MegaKit](https://quaternius.com/packs/downtowncitymegakit.html) | Included Standard FREE license explicitly CC0 | Existing free building subset reused. No paid Source-kit models or engine projects acquired. Three complete building models mean visible architectural repetition remains. |
| [Quaternius Cars](https://quaternius.com/packs/cars.html) | CC0 on pack page | Researched fallback; eight cars in FBX/OBJ/Blend. Not imported in this pass. |
| [Kenney Racing Kit](https://kenney.nl/assets/racing-kit) | Verify pack page before a later import | Candidate for racing props. Not downloaded or installed in this pass. |
| [Poly Haven asphalt textures](https://polyhaven.com/textures/asphalt-bitumen) | Verify selected asset page before import | Candidate for a later materials pass. Not downloaded or installed in this pass. |
| [Rims n Tyres kit](https://sketchfab.com/3d-models/rims-n-tyres-kit-10-cc0-97c7a90210974cb089f15ee7682e4d65) | Not independently verified here | Search lead only; direct page access failed. Not downloaded or installed. |

Existing Fab playable vehicles and the Meshy coupe remain available locally. Their proprietary source assets remain under the ignored licensed-assets directory. No additional visual body-kit changes are applied to the Fab arcade cars. Meshy replacement parts remain a prototype and need a separate model-quality pass. This city remains stylized; it is not a photorealistic rebuild.

Original interface/countdown tones were generated for REVVED without third-party recordings. Existing ambient-audio attribution still applies; see the game credits and audio manifest.

## Outstanding scope
Online modes are still clearly labeled in development. The other two districts, a production traffic system, engine audio/music, final vehicle art and device-specific mobile performance work remain future work. No antivirus scan has been verified: Windows Defender access was denied in this environment. A successful import or export does not establish that a downloaded file is malware-free.

## Git milestone
Summary: Build two-district Street Legacy campaign and living-city navigation

Description:
- Add Eastside street connections, frontage, parking courts and city-reference notes.
- Add lane-following traffic, traffic signals and animated pedestrians with mobile population limits.
- Add 18 events across two career chapters, unlocks, saved results, fictional credit rewards and upgrade purchases.
- Add prominent turn-by-turn race GPS, refine checkpoints and remove routing backtracks.
- Refresh menu styling, event-map route previews, garage access and original interface/countdown tones.
- Add campaign, route-driving and city-population validation.

No commit or push has been made by the assistant. The following are suggested Git commit fields, not records of commits already made.

## Validation completed
- All 17 new event routes completed an automated drive through real static world collisions, including all circuit laps and ordered gates; no extended falling was observed. Capital Run also passed after its route refinement, for 18 validated course layouts total.
- Campaign progression, unique-event locks, practice isolation, first/repeat rewards, upgrade affordability, save rollback and all 18 saved event entries passed.
- Career garage purchase, insufficient-funds restore, included brands and wallet presentation passed.
- Race entry/countdown, camera ownership, pause, ordered/directional/height-sensitive gates, recovery, rankings, best-time persistence, retry, results layouts and free-roam restoration passed.
- Main-menu pages, settings persistence, twenty portrait selections, driver identity, balanced backgrounds, event-map layouts and the garage-to-career return passed.
- Multitouch gas/steering/handbrake, braking, release/drag, pause/focus cleanup and countdown input locking passed.
- GPS turn semantics and along-route countdown passed. Actual logical viewport tests at 640x360, 1080x600, 1280x720 and 2560x1080 confirmed separation from the race card and touch controls.
- Population checks confirmed 70 vehicles, 55 west-bank and 55 east-bank animated walkers, alternating signals and the additional frontage/parking scene.
- The Windows release export passed resource checks for all 12 playable vehicles, all 18 event files, career map, new frontage, traffic, pedestrians, GPS and audio. The live traffic race check then completed all 31 player checkpoints with zero airborne frames; two rivals finished ahead of the test driver, and the third had reached checkpoint 29 with one recovery. The final export passed the packaged-resource check and Windows executable startup check. A final density pass was followed by another drive check of all nine eastside events.

Automated route driving is a useful collision/path check, not a substitute for human handling feedback or performance measurement on phones. Headless tests in this sandbox also report unavailable user-log storage and a root certificate-store error; those are environment limitations, not antivirus results.

## Rebuilding authored content
Run these Godot editor scripts in order when changing the city layout:
1. tools/build_hartford.gd
2. tools/build_eastside_detail.gd
3. tools/build_capital_run.gd (includes narrow-ramp-safe course fillets)
4. tools/build_career_routes.gd
5. tools/export_legacy_map.gd

The supplemental frontage scene is deliberately separate from the main city bake. Rebuild it after changing road or building placement so its collision-checked infill stays valid. Proprietary local vehicle assets remain ignored by Git; the compiled friend package includes them, while a clean source checkout falls back to the original S64 when those files are absent.

## Suggested milestone commits

### City and navigation
Summary: Expand Eastside streets and add living-city navigation

Description:
- Add connected Main, Pitkin, Hartland, Jayce, Meadow and service-street routes with frontage, parking courts, crosswalks and props.
- Add CC0 traffic cars and animated pedestrians, right-of-way signals, racer-aware alley junctions and reduced mobile population counts.
- Add a prominent turn-by-turn GPS, improve checkpoint placement and cache map projections to reduce repeated calculations.
- Round Capital Run's joins and constrain AI lane offsets on narrow ramps.

### Career and menus
Summary: Build an eighteen-event Street Legacy career across two districts

Description:
- Add two crew chapters with sprints, time attacks, circuits, duels and district finals.
- Save event results, unlocks, fictional credit rewards and purchased performance tiers; preserve victories across course revisions.
- Add event-map route previews, garage purchases, wallet feedback and an Event Map return from career results.
- Refresh the menu theme, responsive race/touch layouts and original interface/countdown sounds.
- Validate route driving, campaign progression, purchases, traffic, GPS and interface behavior.

### Friend package
Summary: Update the Windows playtest export for the two-district campaign

Description:
- Include all eighteen event files, new traffic/pedestrian assets, district frontage, navigation and interface audio.
- Package the release executable and resources with instructions, credits and development limitations.
- Verify packed resources and archive integrity. Proprietary source assets remain ignored by Git.

## Release verification
Final packed resources and the Windows executable startup passed. The nine eastside routes were driven again after the final density pass, with all gates completed and zero airborne frames. The distributable archive was CRC-checked; its SHA-256 is in the adjacent checksum file. No commit or push was made.
