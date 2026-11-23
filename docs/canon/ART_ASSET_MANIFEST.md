# W08 art asset manifest

**Target** Godot 4.7.2 · Android landscape

**References** UI = *Kenyalang_Rangers_Tileset_UI_Storyboard.pdf*, GDD = *SimSimi.pdf*, Task 1, and Archive = the separate `Kenyalang_Rangers_Design_Pack_v2.zip`. See the [source inventory](../production/SOURCE_INVENTORY.md), [source identities](DECISION_LOG.md#source-identity) and [UI component bindings](UI_COMPONENT_SPEC.md).

The [W21 production audit](../production/W21_PRODUCTION_ASSET_AUDIT.md) records the C20 build's current asset bindings, placeholder locations and ticket priorities. The W08 tables document the design sources and geometry.

## Source and runtime availability

| Status | Item | Evidence and intended use |
|---|---|---|
| Reference PDF | 127-page storyboard, 116 labeled views | UI pp. 12–127 carry one frame per page. UI pp. 2–11 define the visual system, maps and handoff. Use frame IDs as acceptance cases. |
| Recovered design sources | 116 `screens/<frame>.svg`, 116 `renders/<frame>.png`, `storyboard_manifest.json`, `index.html`, `PROJECT_MEMORY.md` | In the separate Archive. IDs and 1280 × 720 raster dimensions match the PDF and all 483 relative art links resolve. SVGs retain text and vector geometry. See [source validation](#source-validation). |
| Recovered technical sources | `tile_grammar.svg`, `tile_layouts.json`, `tile_atlas_spec.svg`, `tile_piece_catalog.json` | In the Archive. The six layouts match C20 geometry. The 56 technical pieces have archived geometry and await production art exports. [UI pp. 4–6, 10] · [W21 verification](../production/W21_PRODUCTION_ASSET_AUDIT.md#verification) |
| Recovered illustration candidates | Ten PNGs in the Archive's `assets/` | The exact files are listed below. Use them as style or layer candidates pending production review. |
| Verified off-device | W06 Scout Sniper v0.2.0 source and 19 cutouts, C07 rig pilot | In the repository, exercised in the isolated Godot preview. Physical landscape readability and rig validation remain open. [W06 specification](../production/W06_RANGER_SPRITE_SPEC.md) · [C07 rig guide](../production/C07_SCOUT_RIG.md) |
| Production gaps | Runtime atlas with original textures and region overlays, remaining clean cutouts and portraits, deployable/context icons, room and garden layers, authored text banks | Work is listed by dependency in [asset tickets](#prioritized-asset-tickets). Final story, education and Restoration source text follow D-004. Release rights and credits follow D-014. |

The two-PDF handoff supplied the reference PDFs. GitHub main records their identities and carries W06/C07. The PDFs and recovered archive remain external to the repository. See the [repository reference policy](../reference/README.md) for the public repository and source files.

### Recovered illustrations and production use

The Archive values below identify the input files in `assets/`. Alpha describes the file, while the production column describes the deliverable.

| Candidate | Size and alpha | Intended production use | Review or redraw needed |
|---|---|---|---|
| `battlefield.png` | 1672 × 941 RGB | T01 forest backdrop with quiet center for the grid. UI pp. 22–33. | Check lane and lift contrast, crop and camera. Deliver the tunnel and entry markers as reusable layers aligned to the board. |
| `battlefield_mulu.png` | 1672 × 941 RGB | T02 Gunung Mulu ridge/mountain backdrop. UI pp. 5, 117–125. | Check both entrances and shared forest exit across aspect ratios. Deliver gate, tunnel and overlay layers independently. |
| `tileset_concept.png` | 1536 × 1024 RGB | Ground, raised faces, lips, foliage, water and tunnel material study. UI pp. 4–6. | Author individual transparent pieces and packed regions against the technical catalog. |
| `headquarters.png` | 1672 × 941 RGB | Modular cross-section composition guide. UI pp. 12, 38–39. | Supply shell and separable room contents, closed/unbuilt module, trophy mount and props. Bind eleven live room targets. |
| `garden.png` | 1672 × 941 RGB | Garden setting, six plots and guide composition. UI pp. 89–93, 111. | Supply clean scenery, plot frame, water/collect marks, plant stages, hornbill and nest-box layers. |
| `rangers.png` | 1448 × 1086 RGBA | Ranger silhouettes and small roster portrait reference. UI pp. 16, 23, 126. | Use the W06 Scout art. Review and author the rest by canonical Ranger ID with independent parts, anchors and portrait exports. |
| `facilities.png` | 1261 × 1247 RGBA | Facility silhouettes, roster illustrations and construction intent. UI pp. 17, 28–29, 66, 127. | Redraw canonical 13 Facility views, utility markers and construction layers, with art width separate from occupancy. |
| `enemies.png` | 1774 × 887 RGBA | Enemy silhouettes and inspection image language. UI pp. 19, 30–31, 72. | Author per-ID images and animation layers for 15 enemy types and three bosses. Validate tags, distinct silhouettes and warning compatibility. |
| `manager.png` | 1774 × 887 RGBA | Dialogue Manager and Outreach expression reference. UI pp. 20, 77–84, 103–105. | Create keyed expressions for dialogue and all grades, with clear text area and editable portrait sources. |
| `leader_poacher.png` | 1774 × 887 RGBA | Separate Leader and Poacher dialogue subjects. UI pp. 21, 24, 120–121. | Separate speaker/pose exports and define portrait anchors. Preserve the faceless androgynous Leader. Bind future portraits to the authored dialogue. |

### Unique art and reusable states

| Art family | Unique artwork to deliver | Reusable composition and state data |
|---|---|---|
| Regions and terrain | One scenery treatment for each of six maps. Review forest and Mulu candidates. Remaining regional backdrop layers cover Batang Ai, Tanjung Datu, Imbak Canyon and Sepilok-Kabili. Author one shared terrain kit and a few region-specific scenery sets. | Same board renderer and atlas. T01 repeats across Chapter 1. Each Chapter 2 pair reuses its region. Gates, arrows, route, Heat and Siege move with map and encounter data. |
| Battle roster | 12 canonical Ranger identities, 13 Facility identities, 15 enemy IDs and three bosses. Reuse the Scout cutout pilot and derive its card thumbnail from the approved art. Create separate portrait or cutout assets where pose, readability or expression requires them. | Card, upgrade view, construction, HP, lock, cooldown, price and range overlays use shared UI. Deployable art needs world/sprite anchors, while legal occupancy comes from data. |
| Dialogue and Outreach | Larger Manager, faceless Leader and Poacher portrait families. Add speakers and poses only when called for in reviewed scripts. | One dialogue overlay with pose/portrait keys. Share the Manager for Outreach and Story. Grade, explanation, speaker name and progress are data. |
| Headquarters and trophy | One modular office shell, room identity art for 11 rooms, and three achieved trophy appearances with a base mount or empty state. | Built/unbuilt and Lv.1–5 share module and detail templates. Trophy art changes only at thresholds. Use the same trophy art in HQ and Chaos. |
| Habitat Restoration and education | One quiet Garden backdrop, reusable plot frame, distinct Seed/Sapling/Mature art for four species, plus one hornbill guide, nest-box and visitor treatment. Reviewed facts can use species art with provenance. | Plot geometry and six controls are shared. Water, pause, locked, mature and payout states use UI. Quiz reactions, timers, chapter results and article reading share their components. |
| Icons and theme | One coherent original icon set for ticket Tokens, Funds, abilities and roles, pause/speed, gates, status/interaction HUD, room identity, growth and confirmation. Use a cleared offline font. | Recolor, swap badge, or wrap text where appropriate. Render control shapes, shadows and state treatments with the shared theme. See [theme and touch](UI_COMPONENT_SPEC.md#layout-theme-and-touch). |

## Six map geometry layouts

**Source** UI pp. 4–5 and the Archive's `tile_layouts.json` read against `tile_grammar.svg`. GDD pp. 6–8, 17, 21–22, 32 §§ F.2–4, G.2, K, M.4, T.2 set the mission/route relationship and tile rules. UI p. 5 and pp. 117–119 show the two Gunung Mulu entrances.

### Resource mapping

| Contract or field | How to build and validate it |
|---|---|
| Identity and size | Use the exact `T01`–`T06` ID in the `BattleMap` resource and referenced stage data. All six design grids are 12 × 5. Coordinates `(x,y)` start at zero in the upper-left and increase right/down. Keep the 80-unit displayed grid independent of source raster density. |
| Gates and tunnel | Put `entries` into `spawns` and `exit` into `tunnel`. Preserve gate A/B assignment for T02. Exclude all of these cells from deployable ground and elevation. Place a tree-veiled tunnel at the common exit and show the actual travel direction. |
| Routes and ground | Each ordered `routes` list becomes a route resource. Use the inclusive waypoints below and expand each straight segment through adjacent cells. Include the endpoints in route arrays. The union of interior cells is the ground placement mask. For T02 read both ordered routes. The single `entry` and `ground_path` fields in the design JSON are first-route views. |
| Elevated and remaining cells | Copy the per-row masks exactly. Other cells are scenery/nondeployable. No route cell overlaps an elevated top. Two-cell deployables validate every occupied cell. Most Facilities need 2×1 elevated. Sentry Tower requires one elevated cell and one valid reservation above. |
| Layering and encounter | Preserve backdrop → ground → elevation → placement preview → entities → effects → HUD. The art projection and input grid share one transform, including the safe HUD/tray margins. Heat, supply, waves and bonuses belong to the encounter. |
| Runtime check | T01–T06 map and route resources match the archived raised cells and ordered routes. Endpoints are excluded from ground deployment. Keep T01 shared by Chapter 1 and confirm the final atlas aligns with all approved footprints. [W21 verification](../production/W21_PRODUCTION_ASSET_AUDIT.md#verification) |

[Existing T01 map](../../data/stages/t01_forgotten_patrol.tres) · [Existing T01 route](../../data/stages/t01_route.tres) · [Existing resource validator](../../scripts/data/battle_map.gd) · [Map data contract](DATA_CONTRACTS.md#maps-stages-and-battle-state)

### Per-map coordinates

Arrows list ordered waypoints, including turn/join points. Include a joint cell once as a route proceeds to the next segment. All elevations below are x columns at the given row y. `—` means an empty row.

| Map and Story use | Entry-to-tunnel waypoint sequences | Ground deploy / elevated | Reference |
|---|---|---:|---|
| T01 Forgotten Patrol · C1-01–C1-05 | `(0,1) → (4,1) → (4,3) → (11,3)` | 12 / 19 | UI pp. 4, 22–23 S10/S11 |
| T02 Gunung Mulu · C2-01–C2-02 | A `(0,1) → (5,1) → (5,2) → (9,2) → (9,3) → (11,3)`<br>B `(0,3) → (5,3) → (5,2) → (9,2) → (9,3) → (11,3)` | 17 / 20 | UI pp. 4–5, 117–119 M01–M03 |
| T03 Batang Ai · C2-03–C2-04 | `(0,3) → (3,3) → (3,1) → (8,1) → (8,3) → (11,3)` | 14 / 18 | UI pp. 4, 8 |
| T04 Tanjung Datu · C2-05–C2-06 | `(0,2) → (11,2)` | 10 / 12 | UI pp. 4, 8 |
| T05 Imbak Canyon · C2-07–C2-08 | `(0,1) → (7,1) → (7,3) → (11,3)` | 12 / 18 | UI pp. 4, 8, 31 S18 |
| T06 Sepilok-Kabili · C2-09–C2-10 | `(0,3) → (6,3) → (6,1) → (11,1)` | 12 / 16 | UI pp. 4, 8 |

| Map | y=0 | y=1 | y=2 | y=3 | y=4 |
|---|---|---|---|---|---|
| T01 | 1, 2, 5, 6, 8, 9 | 5 | 1, 2, 5, 6, 8, 9 | — | 2, 3, 6, 7, 10, 11 |
| T02 | 1, 2, 4, 5, 7, 8 | 8, 9, 10, 11 | 3, 4 | 7, 8 | 2, 3, 6, 7, 9, 10 |
| T03 | 1, 2, 5, 6, 9, 10 | — | 1, 2, 5, 6, 9, 10 | — | 1, 2, 5, 6, 9, 10 |
| T04 | 1, 2, 5, 6, 9, 10 | — | — | — | 1, 2, 5, 6, 9, 10 |
| T05 | 1, 2, 5, 6, 8, 9 | — | 1, 2, 5, 6, 8, 9 | — | 2, 3, 6, 7, 10, 11 |
| T06 | 1, 2, 5, 6, 9, 10 | — | 1, 2, 9, 10 | — | 1, 2, 5, 6, 9, 10 |

T02 merges A and B at `(5,2)` then shares the full remainder. Map waypoints fix adjacency and travel. Match tile connections to successive route edges. Gate directions, unit facing and elevated shading are art and display choices driven by those routes and legal placement. [UI pp. 4–5, 25, 118–119. GDD p. 8 § G.2.]

## Technical atlas inventory

UI p. 6 shows the original **56-piece geometry diagram**. The Archive catalogue pairs indices 01–56 with `KRT_01`–`KRT_56`. Each rectangle below is `x, y, w, h` in the 1536 × 1536 technical SVG, with a 128 px top face illustrated per cell. These are **diagram coordinates**. For an authored runtime texture, store the actual export rectangle, art pivot, face size, extrusion/gutter and import filter in its own manifest. Display a 128 px top face at 80 logical units before viewport scale. Test edges with scaling and rotation. [UI pp. 3, 6. Archive `tile_piece_catalog.json`.]

Route masks use N=1, E=2, S=4, W=8. Mask 0 is the isolated design piece. Keep entry/exit, route, elevation, scenery and interaction layers separate. Valid/invalid, range, facing, reservation and construction may be drawn with the same UI overlay system as long as the six pictured meanings remain clear.

| Piece | Family | Geometry or use | NESW mask | Diagram rectangle |
|---|---|---|---:|---|
| `KRT_01` | Ground | Quiet ground 1 | — | `63, 152, 128, 128` |
| `KRT_02` | Ground | Quiet ground 2 | — | `243, 152, 128, 128` |
| `KRT_03` | Ground | Quiet ground 3 | — | `423, 152, 128, 128` |
| `KRT_04` | Ground | Quiet ground 4 | — | `603, 152, 128, 128` |
| `KRT_05` | Route connections | Route isolated | 0 | `783, 152, 128, 128` |
| `KRT_06` | Route connections | Route N | 1 | `963, 152, 128, 128` |
| `KRT_07` | Route connections | Route E | 2 | `1143, 152, 128, 128` |
| `KRT_08` | Route connections | Route NE | 3 | `1323, 152, 128, 128` |
| `KRT_09` | Route connections | Route S | 4 | `63, 348, 128, 128` |
| `KRT_10` | Route connections | Route NS | 5 | `243, 348, 128, 128` |
| `KRT_11` | Route connections | Route ES | 6 | `423, 348, 128, 128` |
| `KRT_12` | Route connections | Route NES | 7 | `603, 348, 128, 128` |
| `KRT_13` | Route connections | Route W | 8 | `783, 348, 128, 128` |
| `KRT_14` | Route connections | Route NW | 9 | `963, 348, 128, 128` |
| `KRT_15` | Route connections | Route EW | 10 | `1143, 348, 128, 128` |
| `KRT_16` | Route connections | Route NEW | 11 | `1323, 348, 128, 128` |
| `KRT_17` | Route connections | Route SW | 12 | `63, 544, 128, 128` |
| `KRT_18` | Route connections | Route NSW | 13 | `243, 544, 128, 128` |
| `KRT_19` | Route connections | Route ESW | 14 | `423, 544, 128, 128` |
| `KRT_20` | Route connections | Route NESW | 15 | `603, 544, 128, 128` |
| `KRT_21` | Elevation | Elevated top 1 | — | `783, 544, 128, 128` |
| `KRT_22` | Elevation | Elevated top 2 | — | `963, 544, 128, 128` |
| `KRT_23` | Elevation | Elevated top 3 | — | `1143, 544, 128, 128` |
| `KRT_24` | Elevation | Elevated top 4 | — | `1323, 544, 128, 128` |
| `KRT_25` | Low edge / corner | North lip | — | `63, 740, 128, 128` |
| `KRT_26` | Low edge / corner | East lip | — | `243, 740, 128, 128` |
| `KRT_27` | Low edge / corner | South lip | — | `423, 740, 128, 128` |
| `KRT_28` | Low edge / corner | West lip | — | `603, 740, 128, 128` |
| `KRT_29` | Low edge / corner | NE corner | — | `783, 740, 128, 128` |
| `KRT_30` | Low edge / corner | SE corner | — | `963, 740, 128, 128` |
| `KRT_31` | Low edge / corner | SW corner | — | `1143, 740, 128, 128` |
| `KRT_32` | Low edge / corner | NW corner | — | `1323, 740, 128, 128` |
| `KRT_33` | Decorative skin | Boardwalk skin 1 | — | `63, 936, 128, 128` |
| `KRT_34` | Decorative skin | Boardwalk skin 2 | — | `243, 936, 128, 128` |
| `KRT_35` | Decorative skin | Boardwalk skin 3 | — | `423, 936, 128, 128` |
| `KRT_36` | Decorative skin | Boardwalk skin 4 | — | `603, 936, 128, 128` |
| `KRT_37` | Nondeployable scenery | Low rock | — | `783, 936, 128, 128` |
| `KRT_38` | Nondeployable scenery | Rock pair | — | `963, 936, 128, 128` |
| `KRT_39` | Nondeployable scenery | Stump | — | `1143, 936, 128, 128` |
| `KRT_40` | Nondeployable scenery | Fern edge | — | `1323, 936, 128, 128` |
| `KRT_41` | Nondeployable scenery | Water border | — | `63, 1132, 128, 128` |
| `KRT_42` | Nondeployable scenery | Root edge | — | `243, 1132, 128, 128` |
| `KRT_43` | Entry | North entry | — | `423, 1132, 128, 128` |
| `KRT_44` | Entry | East entry | — | `603, 1132, 128, 128` |
| `KRT_45` | Entry | South entry | — | `783, 1132, 128, 128` |
| `KRT_46` | Entry | West entry | — | `963, 1132, 128, 128` |
| `KRT_47` | Tunnel exit | North tunnel exit | — | `1143, 1132, 128, 128` |
| `KRT_48` | Tunnel exit | East tunnel exit | — | `1323, 1132, 128, 128` |
| `KRT_49` | Tunnel exit | South tunnel exit | — | `63, 1328, 128, 128` |
| `KRT_50` | Tunnel exit | West tunnel exit | — | `243, 1328, 128, 128` |
| `KRT_51` | Interaction overlay | Valid tile | — | `423, 1328, 128, 128` |
| `KRT_52` | Interaction overlay | Invalid tile | — | `603, 1328, 128, 128` |
| `KRT_53` | Interaction overlay | Square range | — | `783, 1328, 128, 128` |
| `KRT_54` | Interaction overlay | Facing preview | — | `963, 1328, 128, 128` |
| `KRT_55` | Interaction overlay | Reserved above | — | `1143, 1328, 128, 128` |
| `KRT_56` | Interaction overlay | Construction | — | `1323, 1328, 128, 128` |

## Production handoff

- Keep an editable source per approved asset family in `assets/source-art/`. Retain independent layers for illustration, interactables, actors, portraits, and state overlays where they need to move separately. Version each source together with its export manifest. Preserve exact IDs across revisions. [UI pp. 6, 10–11. D-003, D-012.]
- Export lossless transparent PNGs for sprites and overlays, clean opaque backgrounds where alpha serves no purpose, and original SVG sources for scalable icons. Record source/export dimensions, crop, scale, pivot, group, state or pose IDs and intended import directory. Keep Godot-specific texture paths and selection regions in the runtime mapping. Use the [Scout manifest](../../assets/source-art/rangers/scout_sniper/manifest.json) as the worked binding example for cutouts. [GDD pp. 17, 29–30 §§ K, Q. UI pp. 3, 6, 10.]
- Use existing source/import directory conventions. Candidate paths for reviewed art include `assets/tiles/`, `assets/backgrounds/`, `assets/ui/`, `assets/portraits/` and `assets/imported/`. Keep UI interaction, text, animation and geometry in their own data and components. Use labeled placeholders where approvals or exports are pending. Verify original proportions, clarity on the 80-unit tile, alpha edges, UV seams, HUD/text overlap and Android touch. [GDD pp. 28–30 §§ O, P, Q. UI pp. 2–6.]
- Register each delivered asset and learning fact with origin, revision, permission, credit and reviewer under D-014. Apply the [reference publication policy](../reference/README.md) when moving a source archive or PDF. A working SVG or alpha PNG is evidence of editability or file format. Release review covers the actual content, its rights and its use in the game. [GDD pp. 29–33 §§ P, R, S, T.3. UI pp. 10–11.]

## Prioritized asset tickets

These tickets detail the art work within the [production backlog](../production/BACKLOG.md). P0 supports C09 and First Contact, P1 expands the tactical roster and regional campaign, and P2 supports the later rooms and activities. Use the [existing C05 phone check](../../export/README.md#c05-first-contact-phone-playtest) for the playable slice and C07 phone evidence before committing to bulk runtime art.

| Ticket | Priority and dependency | Delivery | Acceptance evidence |
|---|---|---|---|
| W08-A01 · Recover and clear the source package | P0 · KR-15, D-003/D-014 | Retain the matching reference archive and verify sources in the team's editor/viewer. Track the frame SVGs, PNGs, four tile files, component/navigation JSON, ten illustration layers and memory file by archive version. | Use the W08 ID, render and link checks as evidence. Finish a live offline viewer run on a workstation, including V15/V16 swipe, and record permissions and approved distribution location for each selected source. |
| W08-A02 · Shared theme and C09 control artwork | P0 · KR-08/KR-09 | Original editable icons plus exports for menu, ticket Tokens, Funds, pause/speed, valid/invalid and warning states, readiness and confirmation. Pick a cleared offline font and a scalable theme recipe. | Use one set in shell, plan, HUD and reports. Verify enlarged text, icon-plus-label states and 48 dp measured hit targets. Buttons and overlays stay within the safe region and retain readable labels. |
| W08-A03 · First Contact terrain and gates | P0 · KR-03/KR-10/KR-17 | Review the forest background, split out the tunnel and entrance, and supply authored ground/route/elevated top/lip pieces and overlay keys used by T01. Keep the existing C05 geometry. | Alpha/registration checks and original backdrop crop. Validate unblocked path and entrance/exit, first legal 2×1 Post drop, off-board and blocked masks. Compare a real device render against the C05 playtest. |
| W08-A04 · C1-01 battle portraits and cutouts | P0 · KR-09/KR-16, W06/C07 | Bind the verified Scout pilot and derive its thumbnail. Author Patrolman, Logistics Post and E01 trial art with independent world anchors. Supply the Manager opening portrait and basic bars/badges. | Verify known IDs and fallback art. Show distinct silhouettes, underfoot HP, cooldown name/portrait and the Post occupying its data-defined cells. Review the Scout rig on the target phone before scaling cutout production. |
| W08-A05 · Full atlas and six region layouts | P1 · KR-17, A03 | Pack production regions or overlay bindings for all 56 documented IDs. Map `tile_layouts.json` into validated Godot map/route assets. Review forest and Mulu backgrounds, supply four other regional backgrounds and optional region scenery. | Check all route masks 0–15, transparent edges, gutters and atlas region IDs at actual display size. Trace both T02 routes to one tunnel, preserve T01 for all five C1 missions, and verify each C2 pair shares its exact mask. |
| W08-A06 · Remaining tactical roster imagery | P1 · KR-11–KR-16, A04 | Author remaining Ranger cutouts and thumbnails, Facility visuals including build and manual utility layers, and clean enemy/boss images. Record construction and interaction anchors. | Catalogue totals are 12 Rangers, 13 Facilities, 15 common enemies and three bosses including A04. Check silhouette and underfoot HP on both field surfaces. Verify ranged mirroring, fixed melee facing where applicable, and one-cell Sentry plus reserved-above markers. |
| W08-A07 · Dialogue and Outreach portraits | P1 · KR-18, D-004 | Deliver editable Manager, faceless Leader and Poacher portraits and separately keyed expressions. Add poses or speakers from the reviewed script, and use the same Manager for Outreach grades. | Each authored speaker/pose key resolves to an approved asset or labeled fallback. Continue and Skip work with enlarged text at the safe bounds. A frozen mid-battle frame remains aligned under a portrait swap. |
| W08-A08 · Modular HQ and trophy | P2 · C15/C17 | Deliver office cross-section and independent room layers for eleven departments, one unbuilt module treatment, a shared trophy mount and three trophy appearances. | Same module target shows initial, built and upgraded states. Empty scenery stays noninteractive. The same trophy appears in HQ and Chaos at 1,000/2,000/3,000 and holds Tier 3 above that. |
| W08-A09 · Garden and education illustrations | P2 · W18/C19/C20, D-004 | Deliver clean Garden and plot art, four species in three stages, hornbill and nest-box layers, and art for reviewed articles. Use stable species/plot/article IDs. | Display two and six plots with one reusable component, three stages per species and the one-off nest-box event. Verify offline article attribution. Tie visuals to eligible garden/quiz state and complete the separate content review. |
| W08-A10 · Production import and attribution | P2 · W21/C22, D-014 | Freeze reviewed production imports and the attribution/permission register. Include editor source, runtime export and metadata links for each active asset. | Verify resolved resources, atlas seams and missing-art fallbacks with the pinned editor. Review actual Android export and device images, document measured size and remaining exceptions, and secure owner sign-off before distribution. |

W19b delivers the Garden portion of W08-A09. The four species have three verified exports each. The clearing, plot, nest box, guide, visitor and effects have their own paths and pivots. Editable foreground sheets, the flat backdrop and the candidate article bindings are recorded in the [Restoration kit manifest](../../assets/source-art/restoration/manifest.json). [W19b review](../production/W19B_RESTORATION_ART.md)

## Source validation

- Matched both canon PDF hashes and all 116 frames to their SVGs and 1280 × 720 PNGs. Resolved 483 relative illustration references and verified the ten artwork files' dimensions and alpha modes. Checked the six board layouts for adjacent routes, bounds and mask separation. Compared T01 against its existing Godot resources.
- Rendered storyboard pages 4, 6, 15, 23, 72, 89 and 126 for review. Inkscape rendered S01, S10, H05, S42, M03 and V16, then re-exported a temporary edit to S10's tutorial text. The two tile SVGs match their JSON catalogues, including 56 label/rectangle pairs and six template labels.
- Exercised 116 viewer frames, HQ → Ecology → Garden, Settings → reset, screen selection, tray drag and both tray limits in a JavaScript harness. Live Chromium was blocked by the workspace socket restriction. A live offline viewer pass, the selected assets' rights and production PNG exports remain in A01 and the downstream tickets.
