# First Contact stage art handoff

**23 November 2026 · C1-01 / T01 · Godot 4.7.2**

The backdrop, tile, interface and effect textures are prepared for the Godot integration pass. T01 retains the original deployment cells and route. Use the approved Scout, Patrolman, E01 and Logistics Post artwork alongside this kit. The previews show the intended composition with the exported assets. [W27 character approval](W27_FIRST_CONTACT_ART.md) · [Import acceptance](w27/IMPORT_ACCEPTANCE.md)

| Preview | What to check |
|---|---|
| [Battle](first-contact-stage/battle_preview.jpg) | Continuous ground lane, raised cell edges, visible entrance and tree-veiled exit, underfoot HP, Starter Post across two raised cells and Scout's shot. |
| [Tutorial deployment](first-contact-stage/tutorial_preview.jpg) | The free Starter Post is available at zero Tokens. The guide calls out one valid pair from the existing map. |
| [Opening briefing](first-contact-stage/briefing_preview.jpg) | Operations Manager, existing radio dialogue and a readable pause overlay. |
| [Story map at Control Lv.1](first-contact-stage/story_control_1.jpg) · [Lv.5](first-contact-stage/story_control_5.jpg) | Same 15 slots throughout. Fog, previous-mission lock, focused operation and cleared stamps have distinct appearances. |
| [Result](first-contact-stage/result_preview.jpg) | The perfect-clear emblem sits beside the operation report. Funds and bonus status come from the settled result. |

## Source and visual rules

The GDD establishes a quiet noninteractive backdrop, an unmistakable sand lane, marked raised cells, and a tree-veiled forest tunnel. The storyboard uses a waterfall and rocks on the left, low-contrast foliage around the field, dark headers and beige controls. The approved W27 characters use the same dark warm outline and olive or rust accents. The stage plate keeps the waterfall and the framing trees. The actual exit is a separate tile at the east end of the route. [GDD p. 17 § K and p. 22 § M.4](../canon/GAME_RULES.md) · [Storyboard pp. 3–6, 20–25, 32–36](../canon/ART_AND_UI_SPEC.md#storyboard-frame-index) · [Source receipts](../../assets/source-art/first-contact/source_receipts.json)

## Battle assets and placement

| Asset | Integration contract |
|---|---|
| [1280 × 720 forest backdrop](../../assets/imported/first_contact/t01_forest_backdrop.jpg) | Fit as an opaque cover plate behind the field. Keep the waterfall and outline-heavy vegetation on the perimeter. Use the existing camera or board transform for all interactive tiles. |
| [Terrain atlas](../../assets/imported/first_contact/t01_terrain_atlas.png) | Crop each region by the [atlas index](../../assets/source-art/first-contact/atlas_regions.json). Use a 128 px tile face at 80 preview units and retain the four-pixel edge extrusion for linear filtering. Draw ground strips flush with their connected edges. Draw only the edge and corner details listed for each raised cell. |
| [Presentation registrations](../../assets/source-art/first-contact/presentation.json) | T01 is 12 × 5, with west entry at `(0,1)`, a south turn at `(4,1)`, east turn at `(4,3)` and tunnel at `(11,3)`. The board uses 12 interior route cells and 19 elevated cells. Draw entry sign `KRT_46` and east tunnel `KRT_48` in the corresponding endpoint cells. Rotate the separate east-authored arrow using the ordered route. |
| Ground, elevation and facility states | Use the authoring preview origin `(160,152)` only at 1280 × 720. Live art should use `tile_size()`, `grid_origin()` and the live footprint. Keep the three artwork layers for route, elevation and placement feedback independent. The Starter Post's art center is the midpoint of the selected 2×1 pair, with HP in a separate underfoot layer. The preview highlights `(1,0)+(2,0)`. Any legal pair comes from existing placement validation. |
| [UI atlas](../../assets/imported/first_contact/first_contact_ui_atlas.png) and [actor badge sheet](../../assets/imported/first_contact/first_contact_actor_badges.png) | Use the HUD, tutorial/briefing and result panels as stretchable 9-slices. Keep approximately 16 px on each outer edge, 15 px on tray frames. Keep Tokens, cost, names, cooldown, HP and result text as live labels. Display the first supplied Post on the amber card. Derive ready, waiting and deactivated states from the existing tray. |
| Independent dialogue poses | Manager `briefing` and `concerned` share the radio pose. Manager `relieved` uses the relaxed pose. Leader `steady` and `reassuring` share the faceless radio pose. The three portraits are 448 × 448 with bottom-center registration at `(224,448)`. The bindings match the current C1-01 sequence keys. |
| [Effects atlas](../../assets/imported/first_contact/first_contact_fx_atlas.png) | `scout_muzzle`, `scout_bolt` and `scout_impact` are separate sprites. The flight asset points right at rest. Attach the visual start to Scout's `tranq_tool` at local `(31.18,16.88)` and let facing/pose transform it. Aim the streak toward the captured target position. Keep it short and use the shared presentation clock. Damage, target choice and combat timing still come from the resolved combat event. The remaining regions cover block, baton sweep, enemy hit, Post ready and ground deploy. |

Use the [T01 map](../../data/stages/t01_forgotten_patrol.tres) and [route](../../data/stages/t01_route.tres) as authority. The presentation JSON documents crops, suggested registrations and visual states. It can seed typed Godot presentation resources in the integration pass. Keep fog, projectiles, panels and decoration out of collision and placement logic. At 1280 × 720 the field begins below the HUD and ends above the tray. For other phone sizes, scale the art through the board rather than generating a new mask. The editable atlas SVGs sit next to their index under [source art](../../assets/source-art/first-contact/).

## Story mission selection

Use the [text-free node backplate](../../assets/imported/first_contact/story_node_backplate.svg), six medallion states and fog region from the UI atlas. The plate is a sequence of nodes with five regional groups. It carries no geographic features or embedded mission text. Use the exact 15 centers and mission IDs in the presentation manifest. Keep actual tap targets at least as large as the 76 × 76 preview rectangles and check phone scaling. [Storyboard p. 14 S03](../canon/ART_AND_UI_SPEC.md#storyboard-frame-index) · [GDD pp. 19, 22 and 32 §§ M.1, M.4, T.2](../canon/GAME_RULES.md#story-progression)

| Control Room level | Newly visible | Visible total |
|---:|---|---:|
| 1 | C1-01–03 | 3 |
| 2 | C1-04–05 | 5 |
| 3 | C2-01–04 | 9 |
| 4 | C2-05–08 | 13 |
| 5 | C2-09–10 | 15 |

Use `CampaignProgress.is_visible()` to clear fog and reveal the title and region. For a visible node, use `access_error()` to decide whether a prerequisite lock remains. The saved record determines cleared and perfect stamps. Replaying a cleared stage leaves the medallions at their original coordinates. The level 5 preview uses an example profile that has cleared through C2-02 and can plan C2-03. [Campaign progress](../../scripts/persistence/campaign_progress.gd) · [Campaign operation data](w13/campaign.json)

## Verification and simulation handoff

Run from the project root after installing the pinned editor.

```sh
python3 -B tools/run_regression.py --logs build/qa/first-contact-art
python3 -B tools/verify_first_contact_art.py
python3 -B tools/verify_w27_art.py
```

Godot 4.7.2 passed editor import, startup and **2,011 checks across 28 runners**. The art verifier checked **56 atlas regions**, their gutters, the exact T01 cells and path, all 15 mission IDs and all five reveal levels. Godot loaded all **9 stage textures** at their registered dimensions. The existing rig probe passed **916 pose samples** across the 32 approved character exports. The six previews are assembled from production assets.

For the integration pass, reproduce the tutorial pair highlight, a refused drop over an endpoint, Scout firing from elevation, Patrolman stopping E01 on sand, and a Post on a valid pair. Verify pause and both speed settings against the same combat timeline. Exercise the opening dialogue, results and replay. On a landscape Android device, verify the tray, text wrapping, dimmed tiles, hit areas and all five Control reveal tiers with an example save. [C26 Campaign verification](../qa/C26_CAMPAIGN_MATRIX.md)
