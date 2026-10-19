# REVVED front end / Street Legacy

F6 on Hartford still opens the city directly. F5 / Run Project starts the main
menu, with an animated preview of the current garage build.

Available now:
- Free Roam: enter the city, find the Capital Run marker and explore.
- Single Race: Capital Run starts directly at the countdown grid.
- Street Legacy: chapter 01, Ignition, starts Capital Run and awards local
  reputation for finishing (250/150/100/50). Finishes, wins and reputation save.
- Garage: opens the existing performance/body/paint garage in the paused city.
- Settings: US/metric, fullscreen, VSync, MSAA and master volume, saved locally.
  There are no music or vehicle audio tracks yet.
- Credits/controls, Quit, and a Main menu button in the pause menu.

Future content is explicitly unavailable, not simulated matchmaking:
- Additional circuits, drift events, time attacks and highway duels.
- Career chapters Local Heat, District Kings, Redline Society and City Legend.
- Online single races, tournaments, shared Street Legacy and free roam.

`StreetProfile` owns the current local career and launch mode. Online career
is designed to share this driver and garage, but account linking, networking,
cloud synchronization, progression validation and conflict handling do not exist
yet. Reputation is currently a saved milestone counter; there is no purchasing,
crew progression or unlock economy in this build. The existing garage remains
freely customizable during development.

Career/display/audio preferences are in `user://street_legacy.cfg`; existing
garage/units and race bests retain their own files. No existing save is reset.
Failed career saves are reported in the result award text. Practice races award
no career reputation.

Verification: `tests/verify_front_end.gd`, `tests/verify_mode_launch.gd`, existing
pause-menu tests and Capital Run event-flow tests. Menu pages were checked at
640×360, 1280×720 and 2560×1080, with scrollable content for longer pages.
