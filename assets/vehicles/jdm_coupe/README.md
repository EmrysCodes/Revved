# JDM Coupe Base Body

Source: user's signed-in Meshy asset library, exported October 18, 2026.
Meshy asset/task: 43af6b46-6404-5c97-80ff-00e7b6ae5241.
Original download: Meshy_AI_JDM_Coupe_Base_Body_1018141625_generate.glb.

The original download remains in the user's Downloads folder. This repository
contains an optimized derivative: 55,988 triangles / 27,865 vertices, reduced
from 895,838 triangles using Godot ImporterMesh LOD generation and vertex compaction.
No paid generation, retexturing, or remeshing action was performed in Meshy.

The source is an untextured, single-mesh model with joined wheels and body.
Its original neutral material is retained. Wheels do not animate independently;
separate wheel meshes and modular body parts are future work.

vehicles/jdm_coupe_visual.tscn normalizes the model to approximately 4 meters
(13.12 feet) long, puts its lowest point at the car origin, and turns its nose
toward Godot's -Z direction. Geometry uses metric dimensions internally;
player-facing units remain controlled by GameSettings.

The existing simple car collision box, arcade controller, reset behavior,
and HUD are reused. This is a prototype visual, not a production art asset.
