# REVVED World Workshop — first version

> Updated October 24: the launcher and Starter world button now open the full-size Plattsburgh / Valcour scene (`world/handbuilt/plattsburgh_region.scn`). The small loop below remains available as a separate example. New worlds now use shared road-junction geometry, and selected roads have draggable point gizmos. See the Plattsburgh first-pass notes for accuracy limits and updated validation.

A world-building dock inside Godot 4.7.2, installed in the REVVED project at `C:\Users\joshu\Documents\Codex\Revved`. Inspired by the library-and-properties workflow of TAHAA's World Workshop.

## Start here

1. Double-click **Open REVVED World Workshop.cmd** next to this guide. It opens the editable starter city in Godot. Allow the first asset import to finish.
2. Click **World Workshop** above the 3D view if the dock is hidden. Its controls appear on the right. You can also open it through **Project > Tools > REVVED / World Workshop**.
3. Click **New world** to create a separate blank city. Each click saves a new numbered scene; it does not replace your previous work. **Starter world** returns to the small example loop, raised road and buildings.
4. Save often with **Save scene** or Ctrl+S.

The supplied launcher uses the Godot executable already downloaded on this computer. If you move the project or the runtime, open `project.godot` in Godot directly instead. This is an editor extension, not a separate game executable.

## Place buildings, trees and street props

Choose **Place assets** from the tool dropdown. Choose a category or search the library; select an asset to see its 3D preview. Click in the 3D view to place copies. There are 28 choices: 17 building styles, two trees, street furniture, parked cars and two junction pieces.

- **R** rotates the placement brush by 15 degrees. The rotation and size fields also work.
- **Grid snap** controls horizontal placement; set it to zero for free placement. Hold **Shift** to bypass snapping on a click.
- **Place assets on surfaces** places onto roads, sidewalks or ground. Build elevation adds a small vertical offset in this mode. With surfaces disabled, elevation defines a flat construction plane.
- **Esc** returns to Select mode. Native move, rotate and scale tools then adjust placed objects. Select an item in the Scene tree if it is hard to click.
- **Duplicate**, **Delete**, Ctrl+Z and Ctrl+Shift+Z use native scene undo/redo.
- Scroll the workshop dock to reach the road, selection and game-menu controls.

All placed assets are editable scene nodes with materials and collisions. Existing project assets are reused; no purchases or paid services were used.

## Make roads and elevation changes

1. Choose **Draw a curved road**. Set road width and sidewalk width. Leave elevation at **0.04 m** for ordinary ground-level roads; this keeps the road visibly above the grass surface.
2. Click several widely spaced points in the 3D view. Curves are smoothed between the points. **Backspace** removes the last draft point; **Esc** cancels the draft.
3. For a hill or ramp, change **Build elevation** before clicking its next point. Use a long approach: rise 4 m over roughly 40 m rather than building a sudden step. The status line reports the maximum grade between control points.
4. Enable **Closed road / loop** before building a circuit. Press **Enter** or **Build road** to create the surface, lane markings, beveled sidewalks and collisions.
5. Nearby road samples/endpoints and junction sockets snap together when drawing a road. Place a **Crossroads / 4-way** or **Junction / T** from Road pieces where roads meet. Use matching elevations. Roads trim their sidewalks and center paint within the placed junction footprint.
6. Select a finished road and click **Edit selected in Inspector**. Expand its **Points** array to adjust individual X/Y/Z positions. **Curve Softness** changes how rounded the bends are. The road rebuilds after editing. Width, sidewalks and loop status can also be changed in the dock and applied to the selected road.

Roads are spline strips, so very tight curves, overlapping roads and abrupt slopes still need manual review. The junction pieces cover simple joins; they do not automatically engineer arbitrary highway interchanges. Raised roads have drivable surfaces and collisions; add the supports and barriers you want as ordinary scene objects.

## Navigate the editor

Use Godot's normal 3D navigation: hold right mouse and use W/A/S/D to fly, use the wheel to adjust navigation/zoom, and use Alt+mouse to orbit. Select a building’s mesh or Ground / Surface in the Scene tree, move the pointer over the 3D view and press **F** to frame it. The view-axis widget switches to overhead or side views, which helps when laying out streets.

The blank world starts with a 512 m square ground. To expand it, scale the **Ground** node in X and Z; its surface and collision scale together. Keep its Y scale unchanged. Godot scene coordinates are metres; the driving HUD continues using your selected game units, including MPH and miles.

## Drive and use your world in the game

1. Choose **Set player start**, set brush rotation to the desired starting heading, and click on a road. The car's forward direction at zero rotation is toward negative Z.
2. Finish or cancel any draft road. Click **Drive / F6** to save and run the current scene with REVVED's existing car, camera, HUD and touch controls. Stop playtesting with **F8**.
3. When ready, scroll down and click **Use this scene for Handbuilt City**. This saves the scene and makes the game's **HANDBUILT CITY** menu option open it. Run the normal game with F5 to try that menu route.
4. Export the game again when sharing changes; the previously packaged game ZIP does not contain this new tool or your new scenes.

Playtesting a workshop world uses a separate builder launch mode and does not award career progress. The original generated city and career are still available from the regular game menu.

## Save files and scope

Your worlds are ordinary `.tscn` scenes in `world/handbuilt/`. `my_city_001.tscn` is an empty starting scene; `workshop_starter.tscn` is the editable example. Road control points and placed objects are saved. Placement ghosts and road geometry rebuilt from the control points are not serialized into the scene.

The extension is in `addons/revved_world_workshop/`; road generation, catalog and runtime support are in `world/workshop/`. If needed, enable **REVVED World Workshop** under Project Settings > Plugins.

This first version covers manual layout and immediate driving tests. Terrain sculpting, traffic-lane authoring, event/checkpoint authoring and a custom material painter are not included yet. Materials, lights and ordinary scene objects can be edited in Godot's Inspector.

The backup ZIP accompanying this guide contains the new workshop files and a small integration patch. It depends on the existing REVVED assets and vehicle code; it is not a standalone project or asset redistribution package.

## Validation

Native editor checks cover new scenes, placement, grid/elevation snapping, duplicate/delete, undo/redo, road settings, player start and save/reload without transient previews. Runtime checks build all 28 catalog assets and drive the existing car around the starter loop and up the raised road onto its deck. Both drive routes completed without airborne frames in the scripted tests. The native editor layout was also rendered and inspected. Godot reports environment certificate/user-data warnings and a shutdown message in this restricted test environment; these do not constitute a clean zero-warning editor run.

## Git milestone (prepared; changes are local and uncommitted)

**Summary:** Add native World Workshop for hand-built REVVED cities

**Description:** Add a Godot editor dock with searchable asset previews, placement tools, grid snapping, rotation, scene undo/redo and player-start placement. Build editable curved and elevated roads with sidewalks and collisions. Include blank and starter worlds, save-and-drive playtesting and a Handbuilt City menu entry that opens the selected scene. Keep runtime support outside the editor-only addon and exclude the addon from game exports. Validate native editor save/reload and vehicle traversal of the starter roads.

Built with Godot's documented [EditorPlugin](https://docs.godotengine.org/en/stable/classes/class_editorplugin.html), [EditorInterface](https://docs.godotengine.org/en/stable/classes/class_editorinterface.html) and [EditorUndoRedoManager](https://docs.godotengine.org/en/stable/classes/class_editorundoredomanager.html) APIs.
