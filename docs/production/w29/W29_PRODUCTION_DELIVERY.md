# W29 production artwork delivery

24 November 2026 · `art/w29-production-art` · Godot 4.7.2

The pack covers the named combat roster, all Facility layouts, the six boards, the complete Headquarters, the Heat display, and the main and activity menu surfaces. The owner approved Poacher v0.3 as a standard-enemy style anchor. The field roster starts from the approved C28-A shapes and joints, with role-specific hair, uniforms and equipment. Larger boss silhouettes, the K9 companion, and the drone and bot have their own registered parts.

## Review the artwork

| Group | Delivery | Review |
|---|---|---|
| Rangers | All 12 named Rangers and the K9 dog. Reuses the live Scout and Patrolman. Each new identity has transparent parts, editable SVG, measured pivots, grip and effect sockets, animation keys, and a card badge. | [Ranger lineup at 80 and 60 pixels](rangers/ranger_lineup.png) |
| Foes | E01–E15 and the three bosses. E01 and E02 retain their approved cutouts. New art includes a separate aerial chassis, crawler chassis and role-specific gear. | [Standard enemies](foes/enemy_lineup.png) · [Bosses](foes/boss_lineup.png) |
| Facilities | All 13 ready, placement, construction, operating, Siege and destroyed visual sets. Shared plate art uses the same uniform scale in both axes. The revised Post has a full two-cell base. The Sentry Tower is centered on one occupied tile and stays inside its reserved cell above. | [Actual raised-pad fitting and silhouettes](facilities/facility_review.png) |
| Environments | T01 reuses First Contact. Five original Chapter 2 backdrops have scenery cards, gate and shared-exit registration, and front/back woodland occluders. T02 keeps its two entrance arrows. | [80 px tile boards](regions/regional_boards_80.jpg) · [60 px tile boards](regions/regional_boards_60.jpg) |
| Headquarters | Layered shell, planted surroundings, lobby, trophy anchor, unbuilt insert and all 11 furnished rooms. Every department has separate back and front layers, a detail plate and a role-specific staff rig. Each staff member has a stationary Work loop with feet planted. | [All rooms in Godot](hq/hq_built_1280x720.jpg) · [Opening day in Godot](hq/hq_opening_960x540.jpg) · [Room detail sheet](hq/room_review.png) |
| Menus | Three licensed offline fonts, 20 scalable frames, 52 glyph identities in two palettes, all 30 modifier ID mappings and original brand art. The 26-screen Godot review has navigation, Story access states, plan, loadouts, settings, HQ, Chaos and education/activity layouts. | [Home](menus/home_1280x720.jpg) · [1280×720](menus/menu_review_1280x720.jpg) · [960×540 and 130% text](menus/menu_review_960x540.jpg) |
| Effects and supporting art | Separate Heat track, fill and icon with a reusable Range scene. Field cues for healing, repair, concealment, detection, snare, stun, Heat overflow, Siege and phases. Three Chaos trophy forms share a mount. Four Records covers and the Garden reuse mapping accompany the activity layouts. | [Heat, cues, awards and covers](support/support_review.png) |
| Portraits and story | Poacher, Diversion Captain, Foreman and Poacher Leader pose keys, including captured. Four Manager Outreach grades derive from her approved C28-A portraits. The Messenger shares Poacher's portrait. The T06 finale plate keeps the dialogue area blank for live text. | [Nine new poses](support/portraits_review.png) · [Finale plate](../../../assets/imported/portraits/story/finale.png) |

## Package and runtime contracts

- [Art catalog](../../../data/presentation/w29/art_catalog.json) resolves each stable ID to its actual rig scene, semantic animation keys, card badge and editable manifest. [W29 audit](asset_audit.csv) records the checked-in artwork and its binding status. [W21 register](../w21/asset_register.csv) records the rendered files, fonts and their source families.
- Use the existing `BattleBoard` transform for actor anchors, route/entry/escape placement, HP and targeting overlays. On Facilities apply `tile_size()/80` uniformly. The `facility.sentry_tower` footprint and reservation stay owned by the gameplay catalog. Animation and art can use the shared combat-clock delta, with events and state driving clips. Clips carry no combat timers or authority.
- The [HQ manifest](../../../assets/source-art/hq/manifest.json) lists room hit-rect registrations, shell order, staff anchors and lobby trophy bounds. Use room construction and level state to choose each insert. Room art and staff use noninteractive CanvasItems beneath the existing controls. The three trophy tiers read the existing Chaos record.
- [Menu theme](../../../resources/presentation/w29_ui_theme.tres) is a scalable Godot resource. The preview fixtures use descriptive labels, art/text states, margins and scroll containers. Their example profile lives only in the fixture. Wire the theme and assets into the existing flow through stable keys.
- [Heat scene](../../../assets/imported/effects/w29/heat_meter.tscn) exposes `%HeatGauge` and `%HeatLabel`. Feed the existing Heat value and stage capacity, and show the existing overflow event. The fill and stripes communicate amount visually. The numeric label and the status message stay dynamic.

The current feature branch contains the production art and reusable Godot scenes. C28-A's live First Contact still uses its shipped assets. The [approved E02 integration ticket](W29_C01_HOLD_THE_LINE_HANDOFF.md) is the first campaign binding. Remaining new art and menu skin can be reviewed in desktop previews before live integration. Phone verification and D-014 release review remain open.

## Rigging handoff

The owner approved `b3c0243` as the visual baseline. Open a roster entry in the [art catalog](../../../data/presentation/w29/art_catalog.json) to locate its Godot rig, editable source and animation contract. Preserve the reference pose, draw order, registered pivots, shared cutouts and attachments when developing the clips. The same catalog links Facility placement anchors and the Headquarters staff loops. Future boss concepts may depart further from the standard unit silhouettes and costumes. The current kits carry the approved art.

## Preview in Godot

Open the game project in Godot 4.7.2 and run either scene using **Run Current Scene**.

- [Menu preview](../../../tests/art/w29_menus/menu_preview.tscn)
- [Animated Headquarters preview](../../../tests/art/w29_hq/hq_preview.tscn)

## Verification

| Check | Observed |
|---|---|
| Shared field cutouts | 449 part instances, 205 pose contracts and 14,240 sampled poses in both facings passed the isolated W27 probe. The original Scout’s existing live rig also loads from the catalog. |
| Assembled art | 732 checks load the catalog, packed rigs and support textures and sample their runtime animation player, including all 11 stationary HQ loops and non-100-capacity Heat. |
| Facilities | 13 rigs, 71 unique textures, 3,822 scale/animation samples, and 40,419 checks passed. |
| Regional boards | 65 existing ground cells, 84 elevated cells, six entries and five exits matched T02–T06. Occlusion passed at both tile sizes. Godot loaded the 25 checked regional and shared textures. |
| Menu layouts | 104 combinations across two sizes and two text scales, 544 button targets and 753 checks passed. 24 native Godot framebuffers include the HQ opening and built examples. |
| Baseline regression | All 2,037 checks across 29 project runners passed. The source ledger verified 1,117 file/asset records, 116 UI frames, 56 terrain entries and all six map geometries. |

~~~sh
python3 -B tools/build_w29_art_catalog.py --check
python3 -B tools/author_w29_facilities.py --godot
python3 -B tools/author_w29_regions.py --godot
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/art/w29_pack_probe.gd
godot --headless --path . --script res://tests/art/w29_menus/menu_probe.gd
python3 -B tools/run_regression.py --logs build/qa/w29
~~~

For the field overlap proof, call `tools/verify_w27_art.py` with a `--unit` argument for each asset directory carrying `animation_contract.json`. Use `tests/art/w29_capture.gd` with a native Godot window and pass an output directory after `--` to recapture the menu and HQ framebuffers.
