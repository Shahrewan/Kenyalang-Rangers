# Kenyalang Rangers art and UI specification

**GDD** is *SimSimi.pdf*, Task 1 (GDD v1.0). **Mini** is Task 2 (PDF pp. 34–39). **UI** is *Kenyalang_Rangers_Tileset_UI_Storyboard.pdf*. Page numbers are PDF pages. **FIXED** marks current visual or navigation intent, **PROVISIONAL** measurements and mockups, and **MISSING** deliverables or details marked `TBD`. Gameplay numbers in example screens follow [the GDD rulebook](GAME_RULES.md) and the [data contracts](DATA_CONTRACTS.md). [UI pp. 2, 10, 15, 34–35]

For implementation, use the [W08 component bindings](UI_COMPONENT_SPEC.md) and [asset manifest](ART_ASSET_MANIFEST.md). These carry forward the frame IDs and record checked geometry and asset availability.

## Visual language and screen sizing

- **FIXED**. Landscape phone composition, safe-area anchors, forest/cream UI, clear ground and elevated contrast. Keep the field visible, with edge-aligned HUD and narrow deployment tray. Use numeric Integrity and punched-ticket Logistic Tokens, a tree-veiled tunnel for the objective, and icon/shape plus color for important states. Scale menu and dialogue text. [GDD pp. 14–17 §§ I.1–4, K; pp. 28–29 §§ O.1, O.4, P; UI pp. 2–5, 23 S11]
- **PROVISIONAL**. Retain the storyboard value set for an Android prototype. Confirm all true hit regions and typography with a physical landscape phone, including narrow and notched screens. [UI p. 3, Visual Language; GDD p. 29 §§ O.4, P]

| Reference element | Storyboard proposal (UI p. 3) |
|---|---|
| Colors | Forest `#343D32`, Olive `#69734A`, Cream `#F3EBDD`, Sand `#BB9D73`, Amber `#E8B957`, Rust `#BC6550` |
| Canvas and menu | 1280 × 720 visual units, 24 outside margin, 16 principal gutter, 72 navigation band |
| HUD | Counter band y12–64. Stage, wave, defeated count, numeric Integrity, Tokens, speed and pause. |
| Arena | 12 × 5 tutorial grid, 80 displayed units per cell, 62–78 unit model height, HP bars below feet |
| Type and shapes | 28–34 titles, 20–26 body, 14–18 compact labels, 10–12 radius, 2–3 outline (visual units) |
| Hit areas | At least 48 Android dp after scaling, to be verified on physical devices |

- **FIXED**. On-field sprites are flat, mouthless chibi cutouts with oversized heads, short limbs, dark outlines, olive/earth palettes, strong equipment silhouettes, few props, minimal shading and readable HP bars below the feet. Melee facing stays locked. Ranged actors may face combat targets. Large separate dialogue portraits use more detail, animated poses/expressions and readable text reveal. The Leader is faceless and androgynous. [GDD pp. 6–7 §§ F.1, F.4; p. 17 § K; pp. 29–30 §§ P–Q; UI pp. 2–3, 20–21 S09/S09L, 120–121 M07–M08]
- **PROVISIONAL**. Lightweight 2D skeletal sampling is approximately 60 FPS and rendering targets 60 FPS. UI's current direction retires the older 18 FPS note. Cover Idle, Move, Attack/Heal/Repair, Skill, Hit, Deploy and Retreat/Defeat as appropriate. **MISSING**. Runtime exports, model dimensions by role, pivot atlas, part naming, portrait rig and animation specs are `TBD` after a representative battle-size art test. [GDD pp. 4, 28–30 §§ C, O.1, Q; p. 33 § T.4; UI pp. 2–3, 10–11]

## Original maps and tile grammar

**FIXED**. Each template uses separate path and elevated deployment classes. Scenery is noninteractive. The diagram layers are backdrop → ground → elevation → placement preview → entities → effects → HUD. Preserve a readable route, entrance glyphs and arrows, muted paths, visibly raised cells and the tree-veiled tunnel. The Sentry Tower reserves the cell above its 1×1 elevated footprint. Default Facilities use two adjacent horizontal elevated tiles. The two-cell ground Rangers validate both cells. [GDD pp. 7–8 § G.2; pp. 15–17 §§ I.3, J.2, K; p. 32 § T.2; UI pp. 2, 4–6, 25 S12, 66 S32]

| Template | Missions and visual intent | Source |
|---|---|---|
| T01 Forgotten Patrol | C1-01–C1-05 on identical terrain and routing. A single forest entrance feeds a stepped chokepoint, with elevated support around it. | GDD pp. 6–8 §§ F.2, G.2; pp. 21–22, 32 §§ M.4, T.2; UI pp. 4–5, 22 S10, 23 S11, 101 S59 |
| T02 Gunung Mulu | C2-01–C2-02. Mountain backdrop, independent entrances A and B, two paths converging on one tunnel. Misty Approach illustrates both lanes. | GDD pp. 7–8 §§ F.3, G.2; UI pp. 4–5, 117–119 M01–M03 |
| T03 Batang Ai | C2-03–C2-04. Original ground lane that turns through the upper part of the board, with separate elevated cells. | GDD pp. 7, 21–22, 32 §§ F.3, M.4, T.2; UI pp. 4, 8 |
| T04 Tanjung Datu | C2-05–C2-06. Original straight ground lane with raised deployment islands above and below in the diagram. | GDD pp. 7, 21–22, 32 §§ F.3, M.4, T.2; UI pp. 4, 8 |
| T05 Imbak Canyon | C2-07–C2-08. Original stepped canyon lane. Runtime Heat is conditional on the operation. | GDD pp. 7, 9, 21–22, 32 §§ F.3, G.5, M.4, T.2; UI pp. 4, 8, 31 S18 |
| T06 Sepilok-Kabili | C2-09–C2-10. Original stepped ground lane approaching the tunnel higher in the frame, with separately marked elevated deployment cells. | GDD pp. 7, 21–22, 32 §§ F.3, M.4, T.2; UI pp. 4, 8 |

The diagrams specify original geometry intent. Maintain the same T01 board across Chapter 1 and one regional board per Chapter 2 pair. A p. 32 GDD sample is a deployment grammar schematic. W08 checked exact coordinates for all six boards and matched T01 to the current runtime. The other five await implementation and import validation. [W08 map layouts](ART_ASSET_MANIFEST.md#six-map-geometry-layouts) · [GDD pp. 21, 32 §§ M.4, T.2; UI pp. 4–6]

**PROVISIONAL geometry inventory**. UI p. 6 documents 56 planned pieces and 128 px top faces. This is an atlas spec for production slicing. Runtime textures, packing margins, pivots and validated source rectangles are `TBD` before import. [UI pp. 6, 10]

| UI p. 6 piece indices | Family |
|---|---|
| 01–04 | Quiet ground variants |
| 05–20 | Route pieces, including isolated, straights, turns and junctions |
| 21–24 | Elevated tops |
| 25–28 / 29–32 | Cardinal lips / corner pieces |
| 33–36 | Boardwalk skins |
| 37–42 | Low rock, rock pair, stump, fern edge, water border, root edge |
| 43–46 / 47–50 | Cardinal entries / tunnel exits |
| 51–56 | Valid, invalid, square range, facing preview, reserved above, construction |

## Navigation and state behavior

**FIXED** intended interactions. The [frame index](#storyboard-frame-index) gives exact source pages and storyboard exits. Available states depend on progression and scenario.

| Flow | Expected touch navigation and feedback | Source |
|---|---|---|
| Boot / main menu | Load the one continuous save. First launch or confirmed reset with no name opens Leader naming. Headquarters has primary emphasis, Story Mode and Rainforest Chaos share the next priority, followed by Reforestation and Settings. Corner ? opens the educational FAQ/references. | GDD p. 14 § I.1; UI pp. 7, 12–14, 94–97 S01–S03/S52–S55; Mini p. 35 |
| Story / planning | Pick an available or replay node. One planning screen keeps Rangers, Facilities, fixed debuffs, eligible optional R&D and wave intelligence visible. Each selector returns with picks preserved. Locked/ineligible choices explain why. Threat inspection shows names, Danger, HP, tags and counters, including modified values where relevant. | GDD pp. 8, 14–15 §§ G.1, I.2–3; UI pp. 14–19 S03–S08, 30 S17 |
| Battle / dialogue | Compact HUD shows counters with pause and 1×/2×. Swipe the tray across the selected Rangers and Facilities, reaching up to 8 and 6 at max HQ slots. Each cooldown leaves the portrait/name visible with a countdown. Drag previews placement/facing. Tap release or a targeted confirmation fires eligible skills. Long hold shows Retreat. Dialogue takes the full screen and freezes the same state through Continue or Skip. | GDD pp. 7–9 §§ F.4, G.2–5; pp. 15, 19, 29 §§ I.3, M.1, O.2–3; UI pp. 20–30, 112, 117–124, 126–127 S09–S17/V10/M01–M09/V15–V16; Mini pp. 35–37 |
| Combat exceptions | S10 exposes the separated C1-01 Starter Post, a free 2×1 elevated first deployment, and skippable instructions. S59 shows 120 Tokens, no Post and no free-Post prompt for D05. Build and Siege warnings are local. Show precise invalid footprint, shortfall or cooldown reason without a failed spend. Pause can reveal enemy details, controls, settings and abandon confirmation. Confirmed abandon grants no rewards and returns to the retained plan in the documented Story flow. | GDD pp. 8–9 §§ G.2–5; pp. 15, 17, 22, 24 §§ I.3, J.2, M.4, M.6; UI pp. 10, 22, 28–33, 99, 101 S10/S15–S20/S57/S59 |
| Result / retry | Clearly distinguish Story perfect, normal clear with escape, defeat and deterministic unlocks. Itemize first-clear and perfect awards when eligible. Show defeat cause and retry/planning. Stage-specific displayed amounts are provisional. Chapter 2 epilogue returns to replayable Story, HQ and Chaos. | GDD pp. 7–8 §§ F.4, G.1; pp. 21–22 §§ M.3–4; UI pp. 34–37, 98, 125 S21–S24/S56/M06 |
| Headquarters | Cross-section of a modern operational office with discrete tap targets. Tap a built room to enter its own screen. An unbuilt module offers a cost and unlock preview. Inside a room choose its activity or Room upgrade. HR → Ranger upgrades → select Ranger. Mechanical → Facility upgrades → select Facility. Compare current and next benefits, Funds cost and prerequisites. Finance shows its active rate, storage and claim. | GDD pp. 14, 17–20 §§ I.1, K, M.1–2; UI pp. 7, 38–70, 109–110, 116 S25–F02/V07–V08/V14; Mini pp. 37–38 |
| Chaos | Main menu or HQ Chaos entrance → route/trophy → five-wave composer → eligible modifiers and loadout with live score and payout preview. Disable Start for all-empty configuration. Sliders and plus/minus clamp to wave total. Show qualifying and escaped-enemy results distinctly. | GDD p. 15 § I.4; pp. 24–25 § M.7; UI pp. 9, 38, 71–76, 114–115 S25/S35–S40/V12–V13 |
| Outreach | Outreach room → Answer questions → Manager, four choices → grade, explanation and Funds result → next question or batch complete. H06 shows “Today's questions.” Use **Current batch** language for the GDD's 20-hour cadence. Persist answers during that batch. The example viewer jump from question two to completion represents selected states. | GDD pp. 25–26, 29 §§ M.8, O.3; UI pp. 50, 77–84, 103–105 H06/S41–P05/V01–V03; Mini p. 39 |
| Records | Records opens facts and four quiz chapters. Unlocked chapter opens a four-choice 15-second question and then answer/timeout feedback. Show first-correct versus already paid. Chapter result shows accuracy, eligible bonus and named enhancement. Garden facts return to the article screen. | GDD pp. 19, 26–27 §§ M.1, M.9–10; UI pp. 52, 85–88, 102, 106–108 H07/S43–S46/S60/V04–V06 |
| Reforestation | Main menu shortcut and Ecology button open the same garden. Plant, water, wait or collect. Three growth visuals. Locked plot shows required Ecology level. Upgrades occur in Ecology through Room upgrade. Milestones, nest-box discovery and facts have dedicated states. | GDD pp. 14, 19–20, 27 §§ I.1, M.1, M.10; UI pp. 48–49, 89–93, 111 H05/U05/S47–S51/V09; Mini p. 39 |
| Settings, saves and wallet | Master/music/SFX controls, text scale, Settings-only reset confirmation. Wipe removes name and progress and invalidates the old backup. If primary is unreadable, valid backup recovers the same save. Pending overflow claim shows exact credit and permanent discard before confirmation. Analytics and online accounts are outside scope. | GDD pp. 18, 21, 28–30 §§ L, M.3, O.1–3, P, R; UI pp. 94–100 S52–S58 |

**PROVISIONAL / MISSING**. Exact widget sizes, cutout behavior across supported phones, optional camera zoom control, text-scale increments, drag/scroll gesture arbitration, and 350 ms hold calibration are pending implementation and device evidence. All fixed input paths must work by touch. [GDD pp. 8, 15, 28–29 §§ G.2–3, I.3, O.1, O.3–4, P; UI pp. 3, 27, 32 S14/S19]

## Audio, accessibility and content provenance

- **FIXED**. Audio direction is restrained office/lo-fi for HQ, layered percussion/strings and forest ambience in Story, more intense Chaos layers, calm nature or confirmation tones in Restoration and Records, and short cues for deployment, Tokens, readiness, invalid targets, victory and defeat. Separate master, music and SFX controls with visual equivalents for important audio. Dialogue uses text and portrait animation. Duck, pause or transition music cleanly for full-screen dialogue. Voice acting is optional. **MISSING** final asset and mixer choices are `TBD`. [GDD pp. 17–18 § L; pp. 29–30 §§ P–Q]
- **FIXED**. The six concept PNGs inform chibi proportions, modular office composition, spacing, forest route contrast and compact gear. Current GDD and UI use original maps, names and silhouettes. Earlier Watchguard geometry, animal heroes, Defense, secondary currencies, nest/egg objective, leaf Token icon and removable loadout slot ideas are historical visual-reference material. [GDD p. 5 § D; pp. 15, 17 §§ I.3, K; UI pp. 2–3, 11, 66 S32]
- **FIXED**. The references screen gives readable offline facts with attribution. Verified facts should distinguish real restoration times from accelerated game timers and avoid unsafe wildlife handling or disclosure of sensitive nest locations. GDD T.3 credits Forest Department Sarawak and IUCN Hornbill Specialist Group materials. The storyboard uses the Sarawak species page and IUCN HSG species profile and states that the large handbook was not relied on. The finished authored content still requires fact and rights review. [GDD pp. 29–33 §§ P, R, T.3; UI pp. 11, 86, 95, 102 S44/S53/S60]

## Source assets and production gaps

| Status | Asset or package | Evidence and next dependency |
|---|---|---|
| **RECOVERED in separate design archive** | **116 editable frame SVGs**, 116 matching PNG frame exports, offline viewer, ten illustration PNG layers and project-memory file. | W08 matched all 116 frame IDs and 483 relative asset links. Representative editor exports, a temporary S10 edit and viewer logic checks passed. Live viewer review and production rights remain open. [UI pp. 1–2, 7, 10, 12–127] · [Validation](ART_ASSET_MANIFEST.md#source-validation) |
| **MISSING in PDF handoff and GitHub main** | `tile_atlas_spec.svg`, `tile_piece_catalog.json`, `tile_grammar.svg` and `tile_layouts.json`. | Four separate deliverables are named on p. 6 and found in the separate candidate archive. Approve the mapping to runtime board data and production imagery. [UI pp. 4, 6, 10; design archive inventory] |
| **PARTIAL** | Scout cutout and rig pilot. Remaining production sprite cuts, anchors and rigs, textured atlas, additional regional backdrops and audio assets. | W06/C07 are verified off-device. Review at landscape phone size and complete the remaining deliverables and provenance records. [GDD pp. 17–18 §§ K–L; pp. 29–31 §§ Q, S.1–3; UI pp. 6, 10–11] · [Asset tickets](ART_ASSET_MANIFEST.md#prioritized-asset-tickets) |
| **MISSING** | Full narrative and final reviewed Outreach, Records and Restoration educational sources. | Sample dialogue, question/feedback layouts and example articles establish presentation. Full story and quiz facts enter through the authored banks and review. [GDD pp. 2, 7, 25–27, 33 §§ A, F.3–4, M.8–10, T.3; UI pp. 8, 10, 85–88, 98, 102] |

## Storyboard frame index

The labels and exits below come from each corresponding UI page. Each row cites its exact one-based PDF page. Exits describe the illustrated storyboard navigation, with applicability and data from the rules above.

| UI PDF page | Frame | Screen or state | Storyboard exits |
|---:|---|---|---|
| 12 | S01 | Main menu / one continuous save | S25, S03, S35, S47, S52, S53 |
| 13 | S02 | Leader name / first launch or reset | S01 |
| 14 | S03 | Story Mode / ordered mission map | S04, M01, S25 |
| 15 | S04 | Simultaneous operation planning | S05, S06, S07, S08, S09 |
| 16 | S05 | Ranger loadout selector | S04 |
| 17 | S06 | Facility loadout selector | S04 |
| 18 | S07 | Pre-battle R&D and fixed debuffs | S04, S33 |
| 19 | S08 | Wave intelligence and enemy details | S04, S17 |
| 20 | S09 | Story dialogue / Operations Manager | S09L, S11 |
| 21 | S09L | Story dialogue / faceless Leader | S11 |
| 22 | S10 | Opening tutorial / free Logistics Post | S12, S11 |
| 23 | S11 | Live battle / primary HUD | S12, S13, S14, S15, S16, S17, S18, S19, S09E, S21 |
| 24 | S09E | Story dialogue / Poacher | S11 |
| 25 | S12 | Drag deployment / footprint / facing | S11, S57 |
| 26 | S13 | Active skill / targeted confirmation | S11, S57 |
| 27 | S14 | Long-hold / retreat action | S11 |
| 28 | S15 | Facility construction / full refund | S11, S18 |
| 29 | S16 | Built Facility / manual utility | S11, S13 |
| 30 | S17 | Pause / enemy inspection | S11, S19 |
| 31 | S18 | Heat / Siege / conditional warnings | S11, S17, S23 |
| 32 | S19 | Battle pause menu | S11, S17, S20, S52 |
| 33 | S20 | Abandon confirmation | S19, S04 |
| 34 | S21 | Perfect Story victory | S24, S03, S25 |
| 35 | S22 | Story clear / escaped enemy | S04, S03, S25 |
| 36 | S23 | Defeat / useful retry | S04, S08, S03 |
| 37 | S24 | Recruit / Facility unlock reveal | S29, S31, S03 |
| 38 | S25 | Headquarters / developed overview | H01–H11, S35 |
| 39 | S26 | Headquarters / initial state | S27, S28, S29, S34 |
| 40 | H01 | Room main screen / Control | S25, S03, S27 |
| 41 | S27 | Room upgrade / Control | H01 |
| 42 | H02 | Room main screen / Human Resources | S25, S29, U02 |
| 43 | U02 | Room upgrade / Human Resources | H02 |
| 44 | H03 | Room main screen / Finance | S25, S34, U03 |
| 45 | U03 | Room upgrade / Finance | H03 |
| 46 | H04 | Room main screen / Mechanical | S25, S31, U04 |
| 47 | U04 | Room upgrade / Mechanical | H04 |
| 48 | H05 | Room main screen / Ecology | S25, S47, U05 |
| 49 | U05 | Room upgrade / Ecology | H05 |
| 50 | H06 | Room main screen / Outreach | S25, S41, U06 |
| 51 | U06 | Room upgrade / Outreach | H06 |
| 52 | H07 | Room main screen / Records | S25, S43, U07 |
| 53 | U07 | Room upgrade / Records | H07 |
| 54 | H08 | Room main screen / R&D Eco | S25, S33, U08 |
| 55 | U08 | Room upgrade / R&D Eco | H08 |
| 56 | H09 | Room main screen / R&D Combat | S25, S33, U09 |
| 57 | U09 | Room upgrade / R&D Combat | H09 |
| 58 | H10 | Room main screen / R&D Guard | S25, S33, U10 |
| 59 | U10 | Room upgrade / R&D Guard | H10 |
| 60 | H11 | Room main screen / R&D Crisis | S25, S33, U11 |
| 61 | U11 | Room upgrade / R&D Crisis | H11 |
| 62 | S28 | Build a department | S25, S58 |
| 63 | S29 | Ranger upgrades / choose Ranger | S30, H02 |
| 64 | S30 | Ranger upgrade / Scout Sniper | S29, V14 |
| 65 | S31 | Facility upgrades / choose Facility | F01, S32, H04 |
| 66 | S32 | Facility detail / footprint and level | S31, S58 |
| 67 | S33 | R&D catalogue / 15 distinct buffs | S07, S25 |
| 68 | S34 | Finance / active-time storage | S25, S58 |
| 69 | F01 | Facility upgrade / Logistics Post | S31, F02 |
| 70 | F02 | Facility upgrade / purchase confirmation | F01 |
| 71 | S35 | Rainforest Chaos / route and trophy | S36, S25 |
| 72 | S36 | Chaos builder / five wave slots | S37, S38, S59 |
| 73 | S37 | Chaos / eligible distinct modifiers | S36, S38 |
| 74 | S38 | Chaos / simultaneous loadout and score | S36, S37, S09 |
| 75 | S39 | Chaos / qualifying result and threshold | S35, S24, S36 |
| 76 | S40 | Chaos / escaped enemy invalidates reward | S36, S35 |
| 77 | S41 | PR Outreach / Manager and daily questions | S42, V01–V03, H06 |
| 78 | S42 | PR Outreach / illustrated response feedback | P02, H06 |
| 79 | P02 | PR Outreach / next question | P2A–P2D, H06 |
| 80 | P2A | PR Outreach / second response · Best response | P05, H06 |
| 81 | P2B | PR Outreach / second response · Acceptable | P05, H06 |
| 82 | P2C | PR Outreach / second response · Poor | P05, H06 |
| 83 | P2D | PR Outreach / second response · Harmful | P05, H06 |
| 84 | P05 | PR Outreach / daily set complete | H06, S25 |
| 85 | S43 | Records / archive and four quiz chapters | S44, S60, S25 |
| 86 | S44 | Records quiz / 15-second question | S45, S43 |
| 87 | S45 | Quiz / answer, timeout and repeat feedback | S44, S46 |
| 88 | S46 | Records / perfect chapter and enhancement | S30, S43 |
| 89 | S47 | Reforestation / six-plot overview | S48, S49, S50, S51, S60 |
| 90 | S48 | Garden / four-species seed selection | S47, S49 |
| 91 | S49 | Garden / watering and paused growth | S47, S60 |
| 92 | S50 | Garden / maturity and collection | S47, S48, S51 |
| 93 | S51 | Garden / milestones and nest-box discovery | S47, S60 |
| 94 | S52 | Settings / audio, display and save reset | S01, S55 |
| 95 | S53 | FAQ / educational references | S01, S60 |
| 96 | S54 | Save recovery / local backup | S01 |
| 97 | S55 | Settings / confirm progress wipe | S52, S02 |
| 98 | S56 | Story finale / continuing activities | S03, S25, S35 |
| 99 | S57 | Placement failure / helpful local feedback | S11, S12 |
| 100 | S58 | Funds cap / explicit overflow warning | S39, S34, S25 |
| 101 | S59 | Fixed Stockpile / alternate battle opening | S11, S17, S19 |
| 102 | S60 | Records / discovered fact article | S43, S47, S53 |
| 103 | V01 | PR Outreach / acceptable | P02, H06 |
| 104 | V02 | PR Outreach / poor | P02, H06 |
| 105 | V03 | PR Outreach / harmful | P02, H06 |
| 106 | V04 | Quiz / incorrect answer | S44, S46 |
| 107 | V05 | Quiz / timeout | S44, S46 |
| 108 | V06 | Quiz / first correct reward | S44, S46 |
| 109 | V07 | Upgrade / insufficient Funds | S30, S27 |
| 110 | V08 | Room upgrade / participation gate | S41, S25 |
| 111 | V09 | Garden / early two-plot state | S48, S27, S25 |
| 112 | V10 | Deployment / visible Ranger cooldown | S11 |
| 113 | V11 | Deployment / insufficient Tokens | S11, S15 |
| 114 | V12 | Chaos / empty setup validation | S36, S35 |
| 115 | V13 | Chaos / live run HUD | S17, S19, S39, S40 |
| 116 | V14 | Permanent levels / purchase confirmation | S30, V07 |
| 117 | M01 | Misty Approach / choose a squad | M02, S03 |
| 118 | M02 | Misty Approach / place the first Logistics Post | M03 |
| 119 | M03 | Misty Approach / defend both entrances | M07, M04 |
| 120 | M07 | Misty Approach / mid-battle Leader dialogue | M08, M04 |
| 121 | M08 | Misty Approach / mid-battle Poacher dialogue | M04 |
| 122 | M04 | Misty Approach / activate a skill | M05 |
| 123 | M05 | Misty Approach / retreat a Ranger | M09 |
| 124 | M09 | Misty Approach / redeployment countdown | M06 |
| 125 | M06 | Misty Approach / operation result | S03, S25 |
| 126 | V15 | Endgame deployment / Rangers side | V15, V16, M03 |
| 127 | V16 | Endgame deployment / Facilities side | V15, V16, M03 |
