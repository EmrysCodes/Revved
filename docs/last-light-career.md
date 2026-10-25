# REVVED 0.8 — Last Light

Street Legacy now tells one original story across the existing 18 regional races. Quinn brings the player to Mara Voss's struggling independent garage. Winning downtown draws the attention of Afterhours promoter Jade Sloane. On the coast, Inez Vale reveals why she and Mara stopped racing together. The two crews build an independent city-to-coast final, with the garage's future resolved in the ending.

## Play flow

Street Legacy → create/continue driver → prologue → city event board → Continue Story → event introduction → race → results → Continue Story → first-win resolution → next event. Every episode requires the preceding missing win. Losing leaves the same episode open and queues a short setback scene. Time attacks require their actual target time. Replay wins pay the existing smaller reward.

There are 39 scenes and 104 authored/voiced lines: a prologue, setup and first-win resolution for each race, an epilogue and a setback scene. Four cast members have fixed portraits and accents in the UI. The player's chosen name appears in subtitles. Scenes use lightweight realtime car/garage/meet sets, moving cameras, subtitles, portraits, type-on text and offline synthetic audio. They do **not** contain human actor recordings, character lip sync or bespoke full-body acting. The installed Microsoft Zira voice supplies all four roles with rate variation. This is a complete prototype narrative presentation, with a placeholder vocal performance.

Next first reveals the line, then advances. Auto, voice, repeat, pause, transcript and scene skip are available; narrow screens place secondary actions in Scene Options. The Story Journal replays watched scenes without changing rewards. An original synthesized menu loop fades during driving and ducks under dialogue. Voice, auto-advance, dialogue volume and music volume save locally. Subtitles remain visible.

## Saves

Existing identity, purchases, money, reputation and event wins remain intact. The migration marks introductions and resolutions for existing wins as watched, avoiding a backlog of old interruptions. The next objective is the first missing win in story order. A previously won later event stays replayable. Finishing the story requires all 18 wins. Story seen-state rolls back on a failed save; the scene remains open with a retry message. Scene skip marks the scene watched and continues its normal destination, without granting a race win.

New Street Legacy is a separate, explicit menu action with confirmation. It backs up the previous career file before starting a new driver with 5,000 CR; a copy or save failure keeps the current career. Visual/audio/display preferences remain. No existing career is reset automatically by this update.

## Other modes and menus

- Single Race has district/discipline filters, route preview, distance, laps and rival/target information. All 18 events remain available without career rewards or story locks.
- Three offline Challenge Series each contain three races. Placements score 10/6/3/1. Gold needs 24 points, silver 18, bronze 12. Retrying replaces that round's score. Results lead to the next round and then a series summary. Resume/End Current Series is available during the same app session; series do not persist across closing the application. They have no entry fee or career rewards.
- Free Roam remains an untimed drive. The career Garage remains on the Street Legacy map.
- The main menu shows career progress and prioritizes playable modes. Extras contains the World Workshop, credits and the explicitly unimplemented online roadmap.
- Results Continue Story now actually returns to the career story flow. Touch-size actions, portrait/landscape layouts, filter wrapping and keyboard focus were checked.

## Validation

`verify_last_light.gd`: ordered unlocks through all 18 episodes; first-win resolutions; failure nonprogression; locked-award rejection; all 104 audio resources and their durations; migration; seen-state persistence; save-failure rollback; subtitle/Next/pause/transcript controls; full dialogue-panel visibility at 1280×720, 640×360 and 393×852; series scoring and reward isolation.

`verify_story_flow.gd`: actual scene transitions through prologue, map, introduction, native regional race, result resolution and next episode. It also loads all three rounds of the downtown series, retries a round, and reaches the final summary. Results are injected for this transition test; it does not re-prove the previous milestone's physical driving coverage.

`verify_campaign.gd`, `verify_driver_legacy.gd`, `verify_results_polish.gd` and `verify_mode_menus.gd`: rewards/economy, existing driver creation and garage return, results layout/actions, practice filters and compact/portrait menu layouts. Real rendered screenshots were inspected. The underlying roads and vehicle physics were not changed for this story milestone. No physical-phone run is claimed. Sandbox log/cache warnings and some test-harness shutdown resource warnings remain.

## Build and provenance

No money spent and no new downloaded models. Story, menu score and integration were authored locally. `tools/build_story_content.py` generates the screenplay JSON; `tools/build_story_audio.ps1` renders the installed Windows speech voice; `tools/build_menu_score.py` synthesizes the music. All existing third-party asset credits continue to apply. The Windows export includes the story JSON, audio and realtime scene resources.

## Prepared Git text

Summary: **Build Last Light story career and polish playable modes**

Description: Add an original linear 18-event Street Legacy narrative with 39 cinematic dialogue scenes, 104 offline synthetic voice clips, persistent scene history, a replay journal and a resolved ending. Preserve existing saves while enforcing ordered progression. Connect results to story continuation, add a filtered Single Race browser and three offline Challenge Series, and polish music, keyboard focus and small-screen menus. Validate progression, migration, save rollback, rewards, scene transitions, series scoring and responsive layouts.

No Git commit or push is made by this milestone.
