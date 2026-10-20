# REVVED Night City Update — 0.3.2 — October 20, 2026

The updated normal game is in REVVED-Night-City-Update.zip. Extract the entire
archive and run REVVED.exe. It contains the main playable city; Free Roam,
Single Race and Street Legacy all load it. No separate study launcher is needed.
The editable project is C:\Users\joshu\Documents\Codex\Revved.

## Milestone 1 — main city transfer

Git Summary: Integrate detailed night-city art into the playable city

Git Description: Replace 2,252 existing building visuals with prepared Modern
City architecture and distance proxies. Apply PBR road and sidewalk materials,
permanent night lighting, local reflections and Car 05's finished materials.
Restore traffic palettes. Preserve collision geometry, race routes and saves.

## Milestone 2 — playable polish

Git Summary: Polish night-city rendering, navigation, garage and vehicle audio

Git Description: Enable GPU-compressed city textures with mipmaps and refresh
distant building/tree art. Replace 2,430 simple trees with two textured models;
texture the grass. Make the driving minimap follow the car and show about
650 feet in each direction, retaining the full career map. Add threaded city
loading; give menus and the workshop matching night lighting and reflections.
Add generic CC0 engine, tire-skid and impact sounds, a capped nearby-traffic
engine mix and saved vehicle volume. Enable six paint finishes for Car 05
while retaining factory geometry. Add garage finger rotation/pinch zoom and
reduce mobile rendering cost while preserving full-resolution UI.

No commit or push has been performed. Licensed Modern City and car source
assets remain local and Git-ignored. No money was spent.

## Validation

- Transfer: all 3,330 existing static/area collision objects, shapes and
  transforms unchanged; city/highway/ramp centerline arrays unchanged.
- Coverage: 2,252 detailed building lots; 888 PBR street/sidewalk surfaces;
  804 old building batches hidden; 2,430 textured trees with distance proxies.
- Actual driving: Capital Run crossed 31/31 gates; Founders Entry crossed
  14/14, using the real controller with city art loaded and no airborne frames.
- Front end, campaign garage purchases/insufficient funds/brands, mode
  transitions, loading, multitouch driving, garage rotation/pinch/cleanup,
  Car 05 paint with unchanged meshes, audio gearing/pause/mute/persistence,
  and unchanged collision/map checks passed.
- At the same stationary 1600x900 test street, one short graphics-memory
  sample fell from about 2.1 GiB to 1.55 GiB after texture optimization.
  This is not a whole-city or phone performance benchmark.
- Exported 0.3.2 package passed: all 12 vehicles, 18 events, career map,
  frontage, traffic, pedestrians, GPS, ambience, vehicle/traffic audio,
  loading screen, grass texture and nearby minimap resources.
  The executable matches the official Godot release export template.
- Actual game/menu/workshop images are included as separate output files.

GPS correction: densely sampled junction corners were previously rejected
as too short, skipping local turns and showing a distant instruction. The
GPS now retains those corners and broad bends. Sharp, broad and sub-metre
turn regressions and viewport/touch layouts pass. Route JSON/checkpoint
coordinates remain unchanged.

Moving Downtown test: 2,667 rendered frame samples, 13.1 ms at the 95th
percentile, two frames above 50 ms, with live rivals/traffic and GPS. This
is a short test on the development laptop, not a hardware requirement.

Final audio regression: race entry/finish control freezes no longer
produce a false impact sound. The grounded-contact regression passes.

## Free audio sources

Engine and impact: Kenney Starter Kit Racing (CC0).
Tire skid: Landeplage, included in that kit (CC0).
https://github.com/KenneyNL/Starter-Kit-Racing/blob/main/README.md
Audio manifests and the original license statement are in CREDITS.
These are generic game engine sounds, not an R34-specific recording.

## Rebuilding the privately licensed city art

Use the locally acquired City_Exports directory as --source for
prepare_city_architecture.py, prepare_city_materials.py and
prepare_city_ground.py. Import in Godot. Run configure_city_textures.py and
import again, then run build_city_art.gd and build_city_trees.gd with a GPU.
The main-city pipeline no longer requires the separate street-study scene.
Licensed images/models must be obtained separately; keep them private.

## Limits

This remains a development build: repeated architecture fitted to old lots,
some simple props, two of four planned districts and preview-only online
menus. Desktop uses Forward+ / Vulkan. Mobile uses reduced rendering detail
and retains touch controls, but actual phone performance is unverified.
Source HUD and menu layouts were exercised on desktop at multiple sizes.

The sandbox cannot write its normal Godot user logs/cache or access its root
certificate store. Godot also reports small texture/refcount cleanup warnings
at test shutdown. No script failures were present in the passed checks.
Windows Defender status access was denied, so an antivirus scan is not
verified. Downloaded audio was checked for OGG headers and SHA-256 hashes.
