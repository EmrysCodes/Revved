# S64 Compact â€” IceMaan

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

The pause menu's Garage now exposes the three body variants, four wheel
styles, and six paint presets. Choices apply live to the car and its isolated
3D preview and are stored alongside unit preferences in user://settings.cfg.
The modular meshes bake in adjusted offsets to keep their wheel arches aligned
with the shared wheel pivots. Both spoiler assets are available through the garage spoiler selector.

The garage now separates Performance, Visuals, and Paint/decals. Performance
levels change acceleration/top-speed limits, braking, and road grip without
changing meshes. Paint/decals offers procedural twin hood stripes and a side
flash in three vinyl colors. The spatial material works without UV textures
or Decal nodes, keeping the Compatibility renderer supported. These are
preset vinyl graphics, not a free-placement decal editor.

Drag the car preview to rotate and tilt inspection, or scroll to zoom.
The preview stage has workshop walls, lighting, a display platform, and a
tool cabinet. Physics interpolation and an interpolated chase-camera target
reduce tick-rate stepping in driving. The handbrake retains lateral momentum
and blends grip back after release; the controller is still a kinematic arcade
model rather than a full AWD/RWD drivetrain simulation.

## Modular garage parts and brand variants

Visuals offers three complete-kit presets plus independent front bumper,
rear bumper and paired side-skirt choices from those kits. The preset also
selects the upper body; reselecting a preset resets all three part slots.
Paint, vinyl and wheel changes preserve mixed parts. Cosmetics do not change
collision geometry or driving stats. The current car has 81 upper-body/part
combinations before wheel and paint choices. Hood, fenders and lights remain
part of the upper body; this is the first modular-body pass.

`modular/*.res` contains real ArrayMesh parts, not overlapping whole shells.
Rebuild them with Godot's `--headless --path . --script
res://tools/build_s64_parts.gd`. The builder transforms the source triangles
into common car coordinates, clips fascia below 0.62m at longitudinal cuts
+/-1.5m, then extracts outer sills below 0.40m. It interpolates normals and UVs,
preserves material names for paint/vinyl, and leaves all unselected geometry
in Core. Matched parts reconstruct the source surface. Mixed kits use the
same cut planes; their seam contours can differ with the source styling.
Original GLBs remain intact. Default assembled car is 7,896 triangles.

Performance brands are fictional tuning profiles. Each Street/Sport/Race
level offers three brands; all values below are gain per level:

- Engine: Vector +15% acceleration/+6% speed, Forge +18%/+4.5%,
  Zenith +12%/+7.5%.
- Brakes: Vector +20% braking, Anchor +24% braking/-0.5% grip,
  Modula +16% braking/+0.5% grip.
- Tires: Vector +10% grip, Apex +12% grip/-1% acceleration,
  Stride +8% grip/+1% acceleration.

Cross-part effects multiply; the preview summary shows the combined result.
All profiles are neutral at Stock, where brand selectors are disabled.
Changing brands preserves the selected upgrade level. Values always derive
from stock controller stats, so repeated selections never compound.
Choices persist alongside existing preferences. Older saves inherit matching
bumper/skirt choices from their saved kit and default to Vector brands.
The parts list scrolls; Back remains outside the scrolling area.


## Spoiler choices

Visuals now includes None, Street wing and Competition wing, with either
body-matched paint or a satin-black finish. Both CC0 source spoilers are
instanced independently at a shared rear-hatch mount. The widebody hatch uses
a slightly lower mounting height. Source GLBs remain untouched.

Spoilers are cosmetic and do not change acceleration, grip or collision.
Kit presets, wheel changes and mixed body parts preserve the chosen spoiler.
Body-matched finishes follow paint changes; satin black stays black. Material
overrides are local to each instance. None removes the mesh and disables its
finish selector. Saved preferences include spoiler and finish; older saves
default to None.
