# S64 Compact — IceMaan

Source: https://icemaan.itch.io/free-low-poly-car-3-body-kits-4-rims
Author: IceMaan
License: CC0; original license is included in LICENSE.txt.
Downloaded October 18, 2026 as S64Compact_v1_C.zip.

Converted from FBX to GLB using Godot 4.7.2 FBXDocument and GLTFDocument.
Adjusted paint to blue, darkened glass, and tuned tire/rim materials.
The original archive remains in the user's Downloads folder.

The pack supplies three body variants, four paired rim choices, and two
spoilers. All converted parts are included for future customization.
The default uses Body_1 and Rims_L/R. Body and four wheels total 7,292 triangles.

vehicles/s64_compact_visual.tscn assembles the default car at approximately
13.12 feet long. Each front wheel has a steering pivot and an independent
rolling pivot; rear wheels roll without steering. Wheels animate from
the arcade controller's smoothed steering and actual longitudinal velocity.
They remain visual components; the existing CharacterBody3D collider handles
road and barrier contact. This does not add independent wheel suspension.

The retired Meshy model remains available in its original asset folder,
but is no longer the player car.
