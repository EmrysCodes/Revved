# Street Legacy driver and city hub

Street Legacy opens driver creation once, then a lightweight interactive map of the actual current city roads. Existing career and garage progress is retained when creating a driver.

Creation: name (1–24 characters), Man/Woman portrait set, one of ten portraits in that set, background, review and save. The name defaults to Alex Mercer and is editable. Portraits and presentation do not affect stats. Backgrounds are fixed after confirmation, with equal +10%/−10% reputation modifiers:

| Background | Bonus | Shortfall |
| --- | --- | --- |
| Independent | No modifier | No modifier |
| Club Racer | 1st–2nd | 3rd–4th |
| Neighborhood Favorite | 3rd–4th | 1st–2nd |
| Workshop Apprentice | No recovery | Any recovery |
| Second Wind | Any recovery | No recovery |

Rewards use the actual finishing place and recovery count. Vehicle handling and performance are unaffected. Recovery still costs race time. Driver creation and settings save all existing profile fields; a failed creation save restores the prior in-memory identity and leaves the creator open.

The hub includes Capital Run (playable), four future event markers (in development), a driver card, Garage and city cruising. Drag to pan, wheel to zoom, Reset map view to recenter. Garage moved out of the top-level menu into this hub. Leaving a garage opened here returns directly to the hub. The pause menu returns to the career map when driving from a career context.

`city_map.json` is a compact export of the current Hartford scene's road paths and river polygon, not live GIS. Regenerate it after changing city roads. Future event points and labels are authored in `city_event_map.gd`; unavailable markers cannot launch races.

Re-export with Godot: `--headless --path . --script res://tools/export_legacy_map.gd`.

Identity fields save in `user://street_legacy.cfg` alongside the existing career/display/audio preferences. Only one local driver is supported; this does not implement online profile synchronization.

Checks: `verify_driver_legacy.gd` verifies creation, all twenty atlas regions, persistence/reload, immutable backgrounds, reward modifiers, map availability, pan/zoom reset, responsive bounds and Garage return. Existing front-end, launch and race tests cover regressions.
