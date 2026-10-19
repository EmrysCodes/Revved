# REVVED — cars, mobile controls, ambience and city trial

## Try the cars
Open the normal REVVED project, enter Street Legacy, open Garage, and use CURRENT CAR. Meshy JDM Coupe is the new default when its local assets are installed. The original S64 and ten Arcade Cars are also selectable.

Meshy options: original/stock/aero front bumpers, rear bumpers and skirts; original/stock/vented hoods; stock/GT spoilers; two wheel designs in silver or dark finishes; paint, two preset decal styles and performance upgrades. Front wheels steer and all four wheels roll. This is the first modular prototype: the generated replacement parts still need manual fit and surface refinement. Interior, damage, custom uploaded decals and additional body shapes are not implemented. Cars currently share the existing arcade driving tune and upgrade preferences.

The editable Blender file is REVVED-Meshy-Coupe.blend. Open-Meshy-Coupe-in-Blender.cmd opens it using the downloaded official portable Blender. Hidden alternatives are named in its outliner. Original Meshy sources are retained in the chat work/meshy-source folder. The original base had 895,838 triangles; the game uses reduced component meshes.

The ten Fab Arcade Cars retain their original body geometry and finish. Visual alterations are disabled for those cars; performance upgrades remain available.
Source: https://www.fab.com/listings/e0b94dfb-455d-4ca2-8317-c120d35c960c
License: Fab Standard. Licensed models are installed locally under assets/licensed and ignored by Git. Copy that folder privately with the project for Xogot; a Git clone alone will use the S64 fallback. Do not upload those source assets to a public repository.
City Sample Vehicles was not imported: its listing restricts it to Unreal Engine.
Source: https://www.fab.com/listings/2909157b-ddfa-4cef-a925-69dc2467021f

## Phone controls
Settings > Touch driving controls: Auto, Always on, or Off. Auto enables the controls on phones/tablets. Gas, Brake/Reverse, E-Brake, left/right steering, Reset, Pause and nearby Race entry support multiple fingers. The HUD and minimap move clear of the controls. Landscape and the mobile renderer/Metal setting are configured. Desktop input and layout tests passed; actual Xogot performance and device behavior still need an iPhone test. This is not a completed mobile optimization pass for the full city.

## Location-based audio
Installed six loops from Free City & Nature Sounds. Downtown traffic, elevated-highway traffic, park birds/wind and river water crossfade by car position. Race crowds use local 3D emitters. Settings has a separate City ambience volume slider.
Attribution: Gregor Quendel — Cinematic Sound Design.
Source: https://www.fab.com/listings/15f8225f-057b-4536-af62-7a43ec328632
License: CC BY 4.0 — https://creativecommons.org/licenses/by/4.0/
Changes: excerpts, crossfades, DC removal, gain normalization and mono crowd conversion. Full attribution and the edit manifest are in assets/audio/city_nature. REVVED-ambience-tour.wav records the actual mixer: city, highway, park, river and race crowd, about six seconds per area. No endorsement is implied.

## Modern City Environment trial
Launch-Modern-City-Trial.cmd starts a separate playable visual trial. Tab switches overview/driving; WASD drives, Space handbrakes, R resets, Esc quits. Road/sidewalk collisions and REVVED's controller are installed, with ambient audio. Building walls are not solid yet. This does not replace Hartford.
Source: https://www.fab.com/listings/6e72d76b-9cf9-4391-aa38-69772d666ac4
Publisher: OTOY360studios. Fab Standard license; sources retained locally, outside the public repository.
The sample covers roughly 260 by 220 metres. Loaded road/sidewalk/tower/building sections total about 8.95 million triangles. Parking was excluded. This needs substantial optimization and collision work before becoming a full-city or phone environment.

## Git milestone
Summary: Add selectable cars, modular Meshy coupe, touch driving and city ambience
Description: Add a persistent garage vehicle selector with the original S64, ten unmodified Fab cars and a Blender-prepared modular Meshy coupe. Add phone driving controls, mobile renderer configuration and location-based ambience with CC BY credits and volume settings. Preserve existing race and garage behavior. Keep Fab model sources local and ignored; provide a separate Modern City visual trial.

No commits or pushes were made. Modern City trial files and Blender deliverables live outside the repository; their source assets are not included in the Git milestone.
