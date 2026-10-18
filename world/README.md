# Downtown district blockout

Play `res://scenes/downtown_district.tscn`. The original test circuit remains
available as `res://scenes/test_circuit.tscn`.

## Layout

- Downtown: 840m by 840m (about 0.52 miles square), seven streets in each
  direction, 36 blocks. Four-lane boulevards have crosswalks, sidewalks and
  signal placeholders. The city has 131 building masses, including a tall
  navigation landmark, a denser office core, lower commercial/residential
  edges, two civic squares and two parking blocks.
- Northern terrace: streets rise through intermediate plateaus to 26m
  (85ft); the west side adds another 6m (20ft). Junctions remain flat while
  mid-block grades transition smoothly. Maximum street grade is about 15%.
- East expressway: two divided carriageways, each 1,320m (0.82 miles) long,
  with piers, barriers and an independently graded deck. Highway grade stays
  below 5%, with surface streets passing underneath at both district ends.
- Four ramps: one on-ramp and one off-ramp for each direction. Each runs
  about 340m (0.21 miles), reaching deck height before moving across the
  highway edge. Barrier openings leave the merge areas clear. An east
  frontage street connects the two surface junctions.
- The two highway ends are visibly capped for future district connections.
  This is a free-roam blockout, with traffic and race routes to come later.

Start in the southern downtown boulevard facing north. To reach the highway,
follow the southern or northern edge street east, through the underpass if
needed. US driving direction: the eastern carriageway travels north and the
western carriageway travels south. The north-up map shows local streets in
slate, the expressway in cyan and ramps in gold. Orange is the player's car.
R returns to downtown spawn. Escape opens the existing pause menu and garage.

## Editing and rebuilding

The scene contains saved meshes, building objects, road collisions, barriers,
lights and the player car. The runtime does not generate the district.
Top-level groups organize Terrain, Streets, Sidewalks, Buildings, Details,
Expressway, Ramps, Signs and Boundaries. Decorative facade bands, paint and
rooftops are batched by material/block; building bodies remain separate.

`tools/build_downtown.gd` is the deterministic source builder. Run with Godot:

    --headless --path . --script res://tools/build_downtown.gd

Rebuilding replaces the generated scene, so keep manual edits in a derived
scene or update the builder. Surface road heights come from shared elevation
bands. All road triangles use Godot's clockwise winding and saved trimesh
collision. Ramp cross slopes blend into the independently graded highway.

The city player instance enables constant floor speed, 0.65m floor snap and
visual slope alignment. The original flat-road car defaults and circuit
remain intact. The chase camera uses a longer far distance for the skyline.
HUD distance continues to use the saved US/metric preference.

## Validation

`tests/verify_downtown.gd` probes every street/highway/ramp path, checks grades
and underpass collision clearance, and drives the real car through all four
ramps in both directions, including the highway merges. It also checks a
market-to-terrace hill climb, visual incline alignment, garage access and map
bounds at supported resolutions. Run with `--headless --fixed-fps 60 --script
res://tests/verify_downtown.gd --quit-after 26000`.
