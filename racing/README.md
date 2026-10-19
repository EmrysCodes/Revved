# Capital Run

The first city street sprint: 5,703.95 metres (3.54 miles), 41 ordered gates,
three AI rivals and one player. The course connects downtown, a service alley,
the Asylum entrance to I-84 east, the I-91 south interchange and a new Columbus
off-ramp before the riverfront finish. This is a fictional gameplay route.

## Play

- Near the original city spawn, slow below 11 MPH and press **E** to enter.
- A three-second countdown stages all four cars. Green gates, road arrows,
  navigation text and the map show the course.
- **R** recovers behind the last passed checkpoint, retaining progress with a
  two-second wait while the race clock continues.
- **Esc** pauses; Restart race retries from the grid. Leave race returns to the
  original free-roam position. **Q** also leaves during countdown/racing.
- Results show finishing order, times, a personal best, Retry and Free roam.
  Rivals still on course continue finishing while results are open.

Distances follow the existing US/metric setting. Personal bests save locally in
`user://races.cfg`. There are no rewards or campaign unlocks in this milestone.

## Implementation and rebuilding

The city adds `capital_run.tscn` at runtime. Rivals use the actual arcade vehicle
controller, lane offsets, curvature-based braking and basic lead-car avoidance.
They have fixed event tuning independent of the player's garage upgrades.
Stuck rivals recover behind their last checkpoint with a two-second wait.
Gate checks require a forward swept crossing at the correct elevation, in order;
ranking uses route progress between gates and final crossing times.

`capital_run_route.json` is authored from the city's real road and ramp paths by
`tools/build_capital_run.gd`. After rebuilding Hartford, run this builder again:

```
godot --headless --path . --script res://tools/build_hartford.gd
godot --headless --path . --script res://tools/build_capital_run.gd
```

`verify_capital_run.gd` covers race state, pause, gate rejection, recovery,
finishing order, late rival finishes, local persistence, responsive results,
retry and free-roam restoration. `verify_capital_driving.gd` drives the full
course using the real player physics alongside all three active rivals and
vehicle collisions. The verified run finished all four cars, with no rival
recoveries and no airborne player frames. These are automated driveability
checks; human steering feel and rival difficulty still need playtesting.
