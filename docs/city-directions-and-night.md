# REVVED — four possible city directions and permanent night

These images were rendered directly in Godot 4.7.2 using the project's existing building, vehicle, and pedestrian assets, plus simple authored road and prop geometry. No AI image generation, purchases, downloads, or paid services were used. They are small art studies with reusable source scenes, not finished playable cities or a promise of final visual quality. The three fictional names are working names.

1. **Hartford — river city.** Dense brick downtown, connected neighborhoods, river crossings and freeway access. Closest to the city already in production, and the most practical direction to finish first.
2. **Harborpoint — coastal port.** Waterfront curves, working docks, cargo yards and long avenues. Distinct routes without requiring a completely new building library.
3. **Ironhaven — industrial city.** Lower factory blocks, warehouses, viaducts and downtown approaches. Fits industrial sprints, fast expressway runs and alley shortcuts.
4. **Ridgeport — hill city.** Rising streets, terraced blocks, curves and elevated crossings. Most varied driving; requires more work on road joins, collision and AI sightlines than the flatter options.

The concepts share the current modular facade library deliberately. More architectural variety and detailed cranes/factories would need additional free assets or original modeling. The new concept scenes are separate from the existing career and do not replace its map.

## Permanent night implementation
All four outdoor scenes now save a dark sky and cool moonlight. The shared city builder produces the same night setting, so regenerating the city preserves it. A runtime controller supplies the city night environment with light atmospheric fog. Existing streetlamp lenses emit light; a bounded pool of 12 nearby real lights (6 on mobile) follows the active camera using actual lamp positions. Player cars have two road-facing headlight beams. Interior menu and garage studio lighting stays intact. There is no daylight cycle or time-of-day option.

Validation: permanent-night regression passed for the saved outdoor skies, moon intensity, playable-car beams, actual lamp placements, active nearby lighting and the light budget. All four concept scenes rendered successfully, and the actual Hartford game was launched and captured with its normal population and nighttime lighting. Phone performance has not been tested. Existing sandbox certificate/log/cache warnings remain; the capture also reports two small texture allocations at engine shutdown, not a gameplay crash.

The earlier two-district ZIP has not been rebuilt for this change; run the updated source project to see permanent night. No commit or push has been made.

## Git commit
Summary: Set permanent night lighting and add four city art studies

Description:
- Replace daylight in all outdoor scenes and the city generator with a shared permanent-night presentation.
- Add player headlights, emissive streetlamp lenses and a capped pool of nearby streetlights with a lower mobile budget.
- Add four reproducible Godot concept scenes for Hartford, Harborpoint, Ironhaven and Ridgeport using existing assets.
- Verify saved and runtime nighttime settings, headlights, lamp placement and active-light limits; render each city study and capture the current nighttime game.
