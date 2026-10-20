# REVVED — playable nighttime street art benchmark

## Try it
Run **Launch-REVVED-Night-Showcase.cmd** beside these notes for the enhanced desktop view. This launcher uses the existing local Godot 4.7.2 installation and the updated REVVED source project; it is not a portable friend build. It starts Forward+ with Vulkan without changing the main project's default renderer.

The normal project main menu also has **NIGHT STREET STUDY / Visual showcase**. That entry uses the renderer with which the project was started; the existing Compatibility mode also passed a rendered test. The earlier ZIP has not been rebuilt for this milestone.

WASD/arrows drive, Space is the handbrake, R resets, Tab toggles the car-view camera, Esc opens the normal pause menu. The on-screen buttons provide car view, a reduced-light setting and Main menu. Existing touch-driving controls remain available. The camera view stops the car. The road ends have physical closure barriers; this is a bounded street study.

## What changed
- Prepared the central street and adjacent storefronts from the already acquired **Modern City Environment**, by OTOY360studios. Imported real roads, sidewalks, curbs, signs, windows, interiors, trees and shop detail from the source assets.
- Reduced the roughly 8.95-million-triangle original full trial to **2,382,508 triangles** in 34 spatial geometry chunks. This subset omits the original tower and unrelated blocks; it is a first reduction rather than a completed production LOD/streaming pass.
- Deduplicated source image files and capped 273 retained textures at 1024 pixels. Preserved normal and roughness maps. Prepared native collision in advance for roads, sidewalks and lower building walls.
- Corrected imported transparency for foliage, glass and overlays and separated overlays slightly from their supporting surfaces. Flattened the imported scene before packing so runtime loading creates one geometry set.
- Authored permanent-night lighting: cool ambient/moonlight, warm streetlights, shopfront washes, small cyan accents, restrained glow and local reflection probes. Desktop has a 24-local-light cap; the reduced mode has an 8-light cap and disables optional ambient occlusion/shadows. These budgets exclude the moon and player headlights. Screen-space reflections were tested and disabled because of artifacts on thin imported signs; probes supply stable reflections.
- Used the cleaner existing **Arcade Car 05** sports coupe with local paint, window, tire, wheel, exhaust and light material overrides. The blue paint uses a clearcoat shader that preserves neutral texture details. Existing steering/rolling wheel pivots and the player controller are retained. Original source geometry is unchanged; this is a material/lighting pass, not a newly acquired production hero car.
- Added six animated sidewalk walkers, the existing city ambience, a car-view camera, responsive driving controls and a main-menu entry. The test car uses a local vehicle override; it does not replace the player's saved garage car, spend career credits or modify upgrade ownership. Garage editing is disabled inside this fixed-car art test.

## Validation
- Passed a 140.27-metre actual controller drive through the street, with zero airborne frames.
- The car climbed the 18 cm curb and stopped at the solid shopfront. Ray checks confirmed lane ground and solid frontage; reset returned to the street spawn.
- Checked saved material settings, retained normal maps, one set of 34 geometry chunks, nearby-light limits, camera/HUD/input transitions and preservation of garage/career values.
- Existing front-end regression passed: menu pages, responsive layouts, saved settings, practice separation, city dressing and menu return.
- Both Forward+ / Vulkan and Compatibility produced the final driving, car and street screenshots without script or shader errors. git diff --check passed.
- A short, stationary 90-frame 1600×900 render sample on the local RTX 3050 Ti Laptop GPU measured Forward+ mean 14.55 ms / p95 15.01 ms, about 1.94 GiB reported graphics memory; Compatibility mean 13.93 ms / p95 17.50 ms, about 1.47 GiB. This is a small scene sample with the car's movement paused and walkers active, not a guarantee for driving, the full city, other hardware or phones.
- Known environment messages: user log/cache storage and the certificate store are restricted here. Forward+ also reported seven texture allocations remaining at engine shutdown; the Compatibility capture and headless regression exited without that warning. These checks are not antivirus scans.

## Scope and next art work
This is a separate, reproducible art benchmark. The career city has not been replaced with this street. Asset style, car geometry, texture consistency, traffic detail, longer routes, architectural variety and mobile performance still need further production work. The reduced-light button is not proof of phone readiness. No actual phone/Xogot performance test was performed.

No money was spent and no new assets were purchased or downloaded in this pass. No commit or push was made.

## Source and rebuild
Modern City Environment: https://www.fab.com/listings/6e72d76b-9cf9-4391-aa38-69772d666ac4 — previously acquired under Fab Standard license. Street source and native prepared art remain private in assets/licensed/modern_city_showcase, which Git ignores. Existing car pack: https://www.fab.com/listings/e0b94dfb-455d-4ca2-8317-c120d35c960c — Store InvoGames, Fab Standard license. Existing Quaternius pedestrians and ambience credits remain in the game.

Run tools/prepare_night_showcase.py with --source pointing to the licensed City_Exports folder, import the project in Godot, then run tools/build_night_showcase.gd. The public source includes preparation and scene scripts; a clean clone without the licensed art displays a disabled showcase menu entry. Source assets must not be added to a public repository.

Godot implementation references: [reflection probes](https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/reflection_probes.html), [material transparency](https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html), and [spatial shader outputs](https://docs.godotengine.org/en/latest/tutorials/shaders/shader_reference/spatial_shader.html).

## Git milestone
**Summary:** Add a playable nighttime street visual benchmark

**Description:**
- Prepare a smaller, private Modern City street subset with PBR materials and prebuilt road, curb and building collisions.
- Add permanent-night lighting, local reflection probes, capped desktop/reduced light budgets, storefront illumination, ambience and animated pedestrians.
- Apply local clearcoat paint, glass, rubber, wheel and lamp materials to the fixed test coupe while retaining steering/rolling wheels and player handling.
- Add a main-menu showcase entry, car-view camera, desktop launcher and graceful handling of missing licensed art.
- Validate actual driving, curb climbing, wall collision, reset, camera/input transitions, saved-state isolation and the existing front end; capture both desktop rendering modes.
