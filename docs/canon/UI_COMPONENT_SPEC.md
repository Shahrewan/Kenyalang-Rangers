# W08 UI component specification

**Target** Godot 4.7.2 · Android landscape · offline single-player

**Sources** UI = *Kenyalang_Rangers_Tileset_UI_Storyboard.pdf*, GDD = *SimSimi.pdf*, Task 1, and Mini = Task 2 in the same PDF. Page references use one-based PDF pages. Source hashes and approved decisions live in the [decision log](DECISION_LOG.md#source-identity).

The 116 frame IDs identify design and test cases. A small set of screens, reusable controls and overlays display the live state of missions, combat, HQ and side activities. Gameplay follows [the rulebook](GAME_RULES.md) and [data contracts](DATA_CONTRACTS.md). The [asset manifest](ART_ASSET_MANIFEST.md) gives the map layouts, tile pieces, art sources and production tickets.

## Layout, theme and touch

| Element | W08 implementation guidance | Evidence |
|---|---|---|
| Canvas | Start at 1280 × 720 logical units. Allow extra landscape space outside the reference canvas. Project Android safe bounds from window pixels into the same viewport coordinates used for input. Keep controls and the full playable grid in the usable area. Use the existing safe-area helper as the starting point. | UI pp. 2–3. GDD pp. 28–29 §§ O.1, O.4, P. [Current helper](../../scripts/ui/safe_area.gd) |
| Menu and shell | Reference margin 24 units, main gutter 16, navigation band 72. Use anchored containers and let text wrap or a panel scroll. Keep the primary action in the safe area at every supported text scale. Use Headquarters as the main menu's primary destination, with Story and Chaos of equal secondary priority. | UI pp. 3, 12 S01, 94 S52. GDD p. 14 §§ I.1–2 |
| Palette | Forest `#343D32` for framing and text, Olive `#69734A` for field and secondary surfaces, Cream `#F3EBDD` for readable panels, Sand `#BB9D73` for ground and soft surfaces, Amber `#E8B957` for focus and attention, Rust `#BC6550` for error and danger accents. Use labels, symbols or outlines alongside color. | UI pp. 2–3, 25 S12, 99 S57. GDD pp. 17, 29 §§ K, P |
| Type and shapes | Reference sizes 28–34 title, 20–26 body and 14–18 compact labels. Radii 10–12 and outline 2–3 logical units. W08 carries these scale references. Choose and clear the actual offline font in the asset intake. Keep enlarged dialogue, menus and quizzes readable with scroll and wrap. | UI pp. 3, 20 S09, 86 S44, 94 S52. GDD pp. 28–30 §§ O.4, P, Q |
| Battle field | T01 shows 12 columns × 5 rows at 80 logical units per cell, 960 × 400 before scaling to fit. Scale board, sprite positions, ranges and pointer-to-cell conversion together. The 62–78 unit standing-height range excludes small underfoot HP bars. Preserve the W06/C07 Scout read at actual battle zoom. | UI pp. 3–5, 23 S11. GDD pp. 8–9, 17, 29–30 §§ G.2, G.5, K, Q. [W06 art brief](../production/W06_RANGER_SPRITE_SPEC.md) |
| HUD and tray | Reference top strip y12–64 within the safe layout. Put wave and defeated counts, numeric Integrity, ticket Tokens, 1×/2× and pause at the edges. Place the narrow tray along the bottom, with a clear scroll affordance. Pan the tray across the selected entries even at eight Rangers and six Facilities. Use a compact banner or inspection overlay when a detail needs more space. | UI pp. 3, 23, 30–31, 112, 126–127 S11/S17–18/V10/V15–16. GDD pp. 9, 15, 19 §§ G.5, I.3, M.1 |
| Hit regions | At least **48 Android dp in both dimensions** for every actionable control after scaling, including tray entries, pause, tooltips with actions, dialog choices and plus/minus. Compute required window pixels as `ceil(48 × Android display density)`. Convert those pixels to logical units with the actual viewport-to-window scale on each axis. Measure the intersection with the safe area and any scroll clip. Enlarge hit regions without overlapping other actions. Increase spacing or reflow if they collide. | UI p. 3. GDD p. 29 §§ O.4, P. [Android density units](https://developer.android.com/training/multiscreen/screendensities) |

Draw the route, both T02 entry markers, range shapes, ground and elevated tiles and the tunnel clearly at native scale. Punched-ticket shapes identify **Logistic Tokens**, the held balance uses **Funds**, and **Operational Integrity** is numeric. Use the separate portrait family for dialogue. The younger Operations Manager, faceless Leader and Poacher use named speaker values, pose and expression. [UI pp. 2–5, 20–24, 117–121. GDD pp. 6–9 §§ F.1, F.4, G.2–5, pp. 17, 29–30 §§ K, Q.]

## Navigation and ownership

- A common shell owns page title, Back, safe-area anchors and focus. Carry the originating context through selectors, article views, reports, confirmation and Settings. HQ opens a district room before its activity or upgrade. Garden entry from main and Ecology resolves to the same saved plots. A battle opens Settings through pause and returns to that pause. [UI pp. 7, 38–53, 89, 94. GDD pp. 14–15 §§ I.1–3, pp. 18–19 § M.1, p. 27 § M.10.]
- Keep a single planning draft keyed by operation or Chaos configuration. Selectors view and update its selected IDs. Confirming a selector returns to the draft. Cancelling it restores the pre-selector choices. Keep all five planning regions available on the same page, with scroll or subordinate panels for full lists. Validate the effective opening on Start with the same rules used at placement. Show the unbuilt Mechanical route after C1-01 when that explains a blocked C1-02 setup. [D-001, D-002, D-009. UI pp. 15–19 S04–S08, 62 S28, pp. 72–74 S36–S38. GDD pp. 14–15 §§ I.2–4, pp. 18–19 § M.1.]
- Run the shared battle scene beneath dialogue and pause. Both hold combat time during inspection, settings, Continue and Skip as applicable. Restore the previous overlay or battle snapshot by context, including the selected speed. Confirming abandon clears the run and returns to its retained plan with no reward. Recovery after relaunch uses D-018's fresh attempt from planning. [UI pp. 20–24, 30–33, 96 S54, 120–121. GDD pp. 7, 9 §§ F.4, G.5, pp. 28–30 §§ O, Q.]
- View components consume state snapshots keyed by canonical IDs and emit the selected action and its context. Placement, score, upgrade price, Funds credit/discard and eligibility use the gameplay or save service result. Use the returned outcome before changing the display. Publish one committed result so progress, wallet and one-time flags remain consistent. [GDD pp. 21–29 §§ M.3–10, O.2–4. D-005, D-007, D-011, D-016–018.]

## Shared UI kit

| Component | Data and states | Interaction and acceptance |
|---|---|---|
| Shell and action button | Title, source context, optional Funds balance, primary/secondary action, navigation target, enabled state and readable reason | Effective hit regions meet 48 dp. Back and system Back follow context. Disabled actions expose the reason and send no transaction. |
| Confirmation modal | Heading, consequence, cost or credited/discarded breakdown, confirm and cancel, prior focus/context | Covers pointer input to the layers below. Cancel returns to the same state and leaves the save, battle or plan untouched. Use for level purchase, overflow, abandon and reset. |
| Status chip and local notice | Name, status icon, amount or timer, anchor and error reason | Show text/icon as well as color for lock, invalid footprint, shortfall, cooldown, restore and result. Keep transient placement feedback near the cell or card. |
| Mission card | Stage ID, region, reveal state, prior-clear lock, clear/perfect status, authored rewards preview | Visibility from Control is independent of playability. Selecting a playable or replay mission opens its plan. A visible locked node explains its prerequisite. |
| Wave and enemy row | Wave index, ordered spawn counts, name, Danger, base/effective HP, tags, counterplay, route gate | Use in plan and pause. Danger is a category. Read modified values from the same rules used by combat. |
| Content card and selection list | Ranger, Facility, buff or debuff ID, portrait/icon, name, selection, capacity, unlock and explanation | Use for loadout, modifier and upgrade catalogues. C1-01 mission supply is a distinct row outside ordinary Mechanical capacity. Read-only fixed debuffs show their cause. |
| Score, price and Funds breakdown | Signed rows, totals, currency/score labels, quote and transaction outcome | Share across planning, procurement, Finance, results and overflow. On a blocked quote show exact shortfall or unmet participation. |
| Counters, thin meter and HP bar | Stage, wave, defeated, numeric Integrity, Tokens, speed, pause, HP, optional Heat or construction progress | Read clock-based values from combat. Heat gauge draws only for relevant stages. Siege marker attaches to the threatened Facility. HP sits under each model. |
| Deployment card and tray | Unit ID, portrait, name, price, count/availability and current cooldown | A horizontal swipe inside the tray scrolls. Moving a chosen card toward the board opens its footprint preview. Arbitrate both with one pointer capture, and cancel or release outside the board without spending Tokens. Calibrate gesture thresholds on a phone. Preserve identity during cooldown. |
| Footprint and target overlay | Selected tiles, legal mask, facing, valid target, range, build/cancel state | Preview uses the live board model and both cells of a two-cell footprint. Check target eligibility again on confirm before consuming a charge or kit. Suppress accidental activation after cancel, swipe, drag or hold. |
| Speaker panel | Full-screen text, speaker ID and expression with Continue/Skip | Used for opening, interlude and epilogue. Pause combat through the same clock. Wrap scaled text and retain both action targets. |
| Room tile, detail and benefit row | Room ID, built state, level 1–5, activity action, current/next effect, cost, participation | Eleven modules share shell and upgrade detail. Level-cap state displays current benefits and no purchase. Empty architecture does not accept a tap. |
| Quantity control | Enemy ID, count, remaining capacity, minus/plus and slider range | Editing one row cannot exceed the wave's 50 total. Announce the resulting count and the cap reason. Zero count is legal. |
| Question and feedback | Activity, prompt, order, four answers, optional timer, grade or correctness, explanation and wallet effect | Outreach and Records share layout with activity-specific rules. Record the response once. The next, finished, first-correct, repeat, timeout and loss states reuse the panel. |
| Plot tile, species row and milestone | Plot ID, unlock level, selected species, progress, maturity, action, reward and claim flag | Reuse six slot controls and switch plant, water, wait, collect or locked state by the saved plot. Seed/Sapling/Mature select the species art. |
| Result and unlock composition | Mode, outcome, resolved counts, escaped combat enemies, remaining Integrity, new rewards and keys | Reuse report layout for Story and Chaos with mode-specific eligibility. Unlock reveal is deterministic and lists every newly granted item. |

## Screen and overlay templates

The table names use plain design labels. Reuse existing Godot paths and naming where suitable. The [frame coverage](#frame-coverage) supplies the input/state case for each storyboard example and the [original frame index](ART_AND_UI_SPEC.md#storyboard-frame-index) preserves its drawn navigation.

| Template | Binding, navigation and state contract | Rule sources |
|---|---|---|
| Main menu · Leader name | Auto-load the single local save. Open naming once when absent or after a confirmed wipe. Menu uses HQ, Story, Chaos, Reforestation, Settings and the corner FAQ. | GDD pp. 14, 28–29 §§ I.1, O.1, O.3. UI pp. 12–13 S01/S02. D-018 |
| Story map · Operation plan | Order authored mission nodes by chapter. Control reveals nodes, previous clears grant access, and cleared nodes replay. Bind the five planning regions to one draft. Disable Start for a setup without an affordable legal first deployment. | GDD pp. 6–8, 14–15, 19, 21–24 §§ F.2–4, G.1–3, I.2–3, M.1, M.4–6. UI pp. 14–19. D-001–002, D-009 |
| Loadout · Modifier picker · Intel | The same list/sheet handles Rangers or Facilities and Story or Chaos context. Use actual slots, activity-specific modifier limits, locks, incompatible conditions and the actual wave list. The Intel component works inside a paused battle as well as planning. | GDD pp. 8–15, 19, 23–25 §§ G, H, I.2–4, M.1, M.5–7. UI pp. 16–19, 30, 73–74. D-009, D-011 |
| Dialogue | Use one overlay for all speakers, stage triggers and the epilogue. Leave the run frozen for mid-battle Continue/Skip. Bind authored script separately from portrait pose data. | GDD pp. 6–7, 18, 29–30 §§ F.1, F.4, L, O.2, Q. UI pp. 20–24, 98, 120–121. D-004 |
| Battle · Pause and confirmation | Same battle HUD for Story, two entrances and Chaos. Compose tutorial prompt, placement/skill/Retreat, local feedback, build/utility, Heat/Siege, pause, abandon and enemy inspection over it. Use the same validators for hover/drag and commit. | GDD pp. 8–9, 15–17, 28–29 §§ G, I.3, J.1–2, O.2–4. UI pp. 22–33, 99, 101, 112–115, 118–124, 126–127. D-001, D-008, D-011 |
| Report · Unlock | Story perfect uses zero combat escapes and a successful clear even with Heat loss. Story clear with escapes can pay eligible clear Funds. Chaos checks positive Integrity and every configured enemy defeated. Failure or abandonment gives no payout. Retain originating route and plan for review or retry. | GDD pp. 6–8, 21–22, 24–25 §§ F.2–4, G.1, M.3–4, M.7. UI pp. 34–37, 75–76, 125. D-005, D-017–018 |
| HQ overview · Room · Upgrade detail | One cross-section template with built/unbuilt module slots, one room page with activity and current/next benefits, one comparison layout for room or deployable purchase. HR and Mechanical lead to the shared catalogue. Costs and preview values bind the appropriate record. | GDD pp. 14, 17–21 §§ I.1, K, M.1–3. UI pp. 38–70, 109–110, 116. D-007, D-009–010 |
| Catalogue · Finance | Select owned units, inspect locked items and show all distinct buffs with unlock level and point cost. Finance displays active rate, storage cap and pending claim. Use the shared price breakdown and overflow confirmation for the wallet. | GDD pp. 18–21, 23 §§ M.1–3, M.5. UI pp. 63–68, 100. D-005, D-007 |
| Chaos route · Chaos composer | Route and shared HQ trophy from local record. Composer hosts five wave slots, modifier sheet and loadout preview together with live score and qualifying payout preview. Add, remove and clamp quantities in data. Disallow all-empty setup and ineligible effects. | GDD pp. 15, 23–25 §§ I.4, M.5–7. UI pp. 9, 71–76, 114–115. D-011, D-017 |
| Outreach | The Manager remains with the player across prompt and feedback. Show **Current batch**, its progress and time to the next eligible 20-hour refresh. Retain shuffled question and choice order, submitted responses and grade. | GDD pp. 20, 25–26, 29 §§ M.1, M.8, O.3–4. UI pp. 50, 77–84, 103–105. D-004, D-016 |
| Records hub · Records quiz · Article | One archive listing freely readable facts and four level-gated quiz chapters. Question uses the visible 15-second timer and a shared feedback panel. Report reflects accuracy, one-time chapter bonus and named enhancement. An article tracks its originating route from FAQ, Records or the Garden. | GDD pp. 19, 26–27, 29–30 §§ M.1, M.9–10, P–R. UI pp. 52, 85–88, 95, 102, 106–108. D-004, D-014, D-018 |
| Garden | One board with plot and species templates, watering/collection overlay, and milestone detail. Show the Ecology requirement when the room is unbuilt. Locked plots route to Ecology for upgrades. Persist progress through the midpoint checkpoint and collection. Mature scenery can remain while its plot is free. | GDD pp. 14, 19–20, 27, 29 §§ I.1, M.1, M.10, O.3. UI pp. 48–49, 89–93, 111. D-010 |
| Settings · Save recovery · FAQ | Adjustable master/music/SFX and text scale. Wipe confirmation only from Settings. Preserve or recover the same local save where possible, with explicit failure and Settings route if both copies fail. Provide readable offline reference text. | GDD pp. 18, 28–30 §§ L, O.1, O.3–4, P–R. UI pp. 94–97. D-014, D-018 |

## Frame coverage

Each row maps the listed PDF page and frame ID to a reusable view and identifies what is sourced, contextual or provisional. **Sample** includes pictured level, prices, HP, counters, wallet or dialogue for the illustrated profile. Only the cited GDD or an approval can establish a value for play. **Fixture** is an explicitly approved or worked example used for verification. **TBD** content stays in its authoring ticket. The source frames' hotspots describe storyboard navigation and can skip runtime steps.

### Entry, Story and combat

| UI PDF p. | Frame | Template or shared state | Binding and rule check |
|---:|---|---|---|
| 12 | S01 | Main menu | Auto-load. Open naming if the save has no Leader name. The shown balance and progress are sample profile values. |
| 13 | S02 | Leader name | Confirm to the same local profile. The typed name is example copy. |
| 14 | S03 | Story map | Order all 15 nodes. Bind Control reveal separately from prior-clear locks. Cleared Chapter 1 and open Misty Approach are a sample profile. |
| 15 | S04 | Operation plan | Keep all five inputs together and preserve them between selectors. C1-04 uses D08 and HR Lv.2 gives four slots. Token prices and Story payout cards are samples. |
| 16 | S05 | Loadout · Ranger | Select by roster ID, class, unlock and HR capacity. The depicted recruited Rangers are a sample selection. |
| 17 | S06 | Loadout · Facility | Use built Mechanical capacity and mission-only supply. D05 prohibits Posts. Sentry Tower occupies one elevated cell and reserves above. |
| 18 | S07 | Modifier picker · Story | One distinct buff in C1 or two in C2. Fixed debuffs are read-only. Unlock levels and effects come from the catalogue. Visible cards are a subset of 15. |
| 19 | S08 | Intel · planning | Inspect every actual wave and enemy. Show HP baseline and effective value with Danger, tags and counterplay. Pictured counts and base HP are reference values. |
| 20 | S09 | Dialogue · Manager | Continue or Skip with the combat clock held. Sample C1-04 script. |
| 21 | S09L | Dialogue · Leader | Use the faceless Leader portrait and the same Continue/Skip path. Sample copy. |
| 22 | S10 | Battle · First Contact tutorial | D-001 and D-006. Scout, Patrolman, one separate Starter Post and D01. D-006 covers 6/8 E01 waves. Starting Tokens 0. First Post free, instant and cooldown-free on a legal 2×1 footprint. The 12/10 Ranger costs are D-008 fixtures. |
| 23 | S11 | Battle · live | Bind top counters and underfoot HP to live state. Use actual ranged aim and locked melee facing. Positions and counts depict a C1-04 example. |
| 24 | S09E | Dialogue · Poacher | One speaker variant on the same frozen field. Sample interlude, text and trigger. |
| 25 | S12 | Battle · placement | Preview footprint, facing and range. Lock chosen melee facing after placement. The Veteran's two forward cells are sourced. The selected tile and card timer are samples. |
| 26 | S13 | Battle · target confirmation | Scout's additional Focus targeting requires Steady Aim. Instant skills and targeted confirmation share input dispatch. Sample eligibility comes from an enhanced profile. |
| 27 | S14 | Battle · retreat | Long hold offers Retreat for a Ranger, suppressing tap. D-008's 350 ms is a C1-01 calibration fixture. After retreat, read actual redeploy time and any named effects. |
| 28 | S15 | Battle · construction | Show site HP, Siege vulnerability, clock progress and cancel with exact paid refund. Sonic Turret's 7 s is its published base. Refund of 35 is an example. |
| 29 | S16 | Battle · built utility | Select an eligible ally and confirm a stored Medic kit use. Built Facilities stay in place. Heal output and stored count are sample tuning values. |
| 30 | S17 | Battle · pause with Intel | Pause before inspection. E05 Rifle Spotter 180 base HP and 207 with D08 is a worked example. It uses ordinary ranged attacks. |
| 31 | S18 | Battle · Heat/Siege | Only show Heat when relevant. Full Heat costs Integrity and resets. Pin Siege warning to its target. C2-07 gets D-009's Firebreak supply. Pictured gauge and damage amounts are examples. |
| 32 | S19 | Pause | Settings, controls, Intel, Resume and Abandon keep the run frozen. The visible battle is a snapshot. |
| 33 | S20 | Confirmation · abandon | Cancel returns to pause. Confirm returns to the retained operation plan and pays zero. |
| 34 | S21 | Report · perfect Story | Check zero combat escapes and positive Integrity. Separate one-time first-clear and first-perfect lines. Example C1-04 shows 50,000 + 20,000. Final stage amounts are TBD. |
| 35 | S22 | Report · Story clear with escape | Pay eligible clear award and explain why perfect was missed. Example one escape, 95 Integrity and 50,000 Funds establish no tuning values. Exclude the cinematic messenger from escape count. |
| 36 | S23 | Report · defeat | Show the real failure cause and retained retry choices. Award zero Funds and progress. Displayed end counters come from the run. |
| 37 | S24 | Unlock | Tie awards to the actual result. C1-04 grants Woods Tracker and Reinforced Cover Station. Return to the originating report or section. |

### Headquarters and progression

| UI PDF p. | Frame | Template or shared state | Binding and rule check |
|---:|---|---|---|
| 38 | S25 | HQ overview · developed | Eleven tappable department slots keyed by room ID. The empty bay is scenery. Levels and Funds depict a developed save. |
| 39 | S26 | HQ overview · initial | Only Control, HR and Finance built at Lv.1. Eight unbuilt slots show construction. 10,000 Funds is a prototype starting balance. |
| 40 | H01 | Room · Control | Read actual tier and Fog visibility. Activity enters Story. The shown room tier is sample. |
| 41 | S27 | Upgrade detail · Control | Use room costs and the next reveal range. Unlock visibility only. Progression order still applies. |
| 42 | H02 | Room · Human Resources | Activity enters the Ranger catalogue. Show live HR tier and slot count. Sample profile level. |
| 43 | U02 | Upgrade detail · HR | Preview next cost and capacity from the 3/4/5/6/8 schedule. |
| 44 | H03 | Room · Finance | Show active-time production and claim entry. Sample department level and stored Funds. |
| 45 | U03 | Upgrade detail · Finance | Quote next room price, active rate and its separate storage limit. Production rates/caps are configurable balance values. |
| 46 | H04 | Room · Mechanical | Activity enters the Facility catalogue after the room is built. Sample level. |
| 47 | U04 | Upgrade detail · Mechanical | Preview next cost and ordinary slot count from 2/3/4/5/6. Mission supply stays outside capacity. |
| 48 | H05 | Room · Ecology | Reforestation button opens the common Garden. Capacity expands only through the room upgrade. Sample level. |
| 49 | U05 | Upgrade detail · Ecology | Quote cost, new plot capacity and 60% participation at Lv.5. Use current restoration progress. |
| 50 | H06 | Room · Outreach | Show Current batch and its remaining time from the 20-hour local clock. The illustrated level and today's-questions wording are contextual. |
| 51 | U06 | Upgrade detail · Outreach | Quote next cost and participation. Five Best/Acceptable responses plus the applicable price gate Lv.5. |
| 52 | H07 | Room · Records | Activity enters archive. Facts at Lv.1, chapters at Lv.2–5. Sample completion state. |
| 53 | U07 | Upgrade detail · Records | Show next archive/chapter unlock from level record. Lookup the named enhancement for that chapter. |
| 54 | H08 | Room · R&D Eco | Bind the Eco group B01–B04. Display unlocked effects at current tier. Sample level. |
| 55 | U08 | Upgrade detail · R&D Eco | Show the next distinct unlock and cost. Existing buffs retain their strength. |
| 56 | H09 | Room · R&D Combat | Bind B05–B08 and actual unlocked set. Sample level. |
| 57 | U09 | Upgrade detail · R&D Combat | Show the next distinct unlock and cost. Existing buffs retain their strength. |
| 58 | H10 | Room · R&D Guard | Bind B09–B12 and actual unlocked set. Sample level. |
| 59 | U10 | Upgrade detail · R&D Guard | Show the next distinct unlock and cost. Existing buffs retain their strength. |
| 60 | H11 | Room · R&D Crisis | Bind B13–B15. The group first unlocks a buff at Lv.3. Sample level. |
| 61 | U11 | Upgrade detail · R&D Crisis | Read next unlock from the schedule, including tiers with no new buff. |
| 62 | S28 | Upgrade detail · build department | Cost and effect before instant construction. Mechanical Lv.1 uses 20,000 Funds and enables two slots. Validate and show shortfall if needed. |
| 63 | S29 | Catalogue · Rangers | Choose an owned Ranger. Scout is a sample selection. |
| 64 | S30 | Upgrade detail · Ranger | Show current/proposed stats, level and price. D-007 gives 60,096 Funds for Lv.1→20. Displayed base stats and target balance are samples. |
| 65 | S31 | Catalogue · Facilities | Show owned and locked entries with actual unlock sources. Logistics Post/Sentry Tower illustrate two states. |
| 66 | S32 | Upgrade detail · Sentry Tower | One occupied elevated tile, one reservation above. Chaos threshold 3,000 unlocks it. Leveling preserves footprint and base build time. |
| 67 | S33 | Catalogue · R&D | All 15 distinct buffs with exact group, unlock level and Chaos score penalty. Filter by mode eligibility in the invoking selector. |
| 68 | S34 | Finance | Track active/unpaused accrual and separate room storage. Rate 4/s, cap 25,000 and claim 12,480 illustrate Lv.2. Bind the actual wallet transaction. |
| 69 | F01 | Upgrade detail · Logistics Post | Show exact base Lv.1/Lv.100 yields of 10/15 per 10 s. Lv.20 display rounds the preview. Preserve underlying fractional carry and two elevated cells. |
| 70 | F02 | Confirmation · level purchase | Same modal as V14, bound to Facility quote. 186,500 held Funds is an example. Charge only if confirmed and eligible. |

### Rainforest Chaos

| UI PDF p. | Frame | Template or shared state | Binding and rule check |
|---:|---|---|---|
| 71 | S35 | Chaos route | Use original route list and the same record as HQ trophy. A best of 3,500 illustrates Tier 3. Thresholds are 1,000/2,000/3,000. |
| 72 | S36 | Chaos composer · waves | Up to five slots, 50 total across types in each populated slot, zero counts allowed. Empty slots add no rest. The 50/10 enemy configuration is the worked example. |
| 73 | S37 | Modifier picker · Chaos | Recompute eligibility for the current route, waves and loadout. The sample enables Aerial Tailwind for drones and disables unavailable Heat effects. Apply D-011 to D05 and conflicting modifiers. |
| 74 | S38 | Chaos composer · planning | Shared loadout, eligibility, waves and score together. Worked score 1,550 + 400 − 500 − 100 = 1,350. Each effective filled slot costs 100. Empty slots add zero. |
| 75 | S39 | Report · qualifying Chaos | Check all configured enemies defeated and positive Integrity. 1,350 pays 54,000 gross in the example. Apply wallet cap and every newly earned threshold once. |
| 76 | S40 | Report · unqualified Chaos | An escape blocks payout, threshold unlocks, trophy and personal-best changes even if Integrity stays positive. Counters are sample data. |

### Outreach, Records and Garden

| UI PDF p. | Frame | Template or shared state | Binding and rule check |
|---:|---|---|---|
| 77 | S41 | Outreach · question | Current batch with Manager, up to five from 20 and four shuffled choices per question. Prompt, answer text and rewards illustrate the format. |
| 78 | S42 | Outreach · Best | Same feedback panel for all grades. Report explanation and actual signed Funds change. Lv.1 Best amount in frame is a prototype figure. |
| 79 | P02 | Outreach · next question | Persist question and choice order. The second prompt is a sample. |
| 80 | P2A | Outreach · Best | Best contributes to participation. Pictured response and Funds are examples. Continue according to batch state. |
| 81 | P2B | Outreach · Acceptable | Acceptable contributes to participation. Pictured response and Funds are examples. Continue according to batch state. |
| 82 | P2C | Outreach · Poor | Show explanatory feedback and zero Funds. Pictured response is an example. Continue according to batch state. |
| 83 | P2D | Outreach · Harmful | Deduct at most held Funds. Show actual loss and submit state. Pictured amount is a prototype example. |
| 84 | P05 | Outreach · batch complete | End on actual completed batch and show next eligible refresh. The viewer's jump after question two and calendar-day wording are illustrative. Use D-016's 20-hour cadence. |
| 85 | S43 | Records hub | Freely readable facts and four named chapters gated by Lv.2–5. Sample archive entries are separate from final banks. |
| 86 | S44 | Records quiz · question | Four choices and 15 seconds. Fact example and bank position are illustrative. |
| 87 | S45 | Records quiz · repeat correct | Show explanation and previously paid state. Repeat correct can count for accuracy without paying again. |
| 88 | S46 | Report · Records chapter | Show accuracy, one-time chapter bonus and named enhancement. Counts and amounts are provisional. Strike Team has no enhancement. |
| 89 | S47 | Garden · developed | Six plot slots and exactly three growth visuals. Actual available plots follow Ecology. Pictured stages, species art and remaining hours are examples. |
| 90 | S48 | Garden · species picker | Four named species with 18/36/48/72-hour in-game durations. Show trial Funds from data. Keep the in-game clock clear in educational copy. |
| 91 | S49 | Garden · water required | Apply D-010 midpoint checkpoint. Show where growth stopped and resume on watering. Pictured remaining time is an example. |
| 92 | S50 | Garden · mature and collect | Collect the cycle's Funds once, keep the mature tree in scenery and release the slot. 3,000 repeat Fig Funds is a provisional example. |
| 93 | S51 | Garden · milestones | 20/40/60/80/100% states reuse a track. D-010 ties the nest-box discovery to the fourth distinct species at 80%. Ecology participation at 60% is separate. |

### Settings, errors and additional states

| UI PDF p. | Frame | Template or shared state | Binding and rule check |
|---:|---|---|---|
| 94 | S52 | Settings | Bind actual audio and text settings. Scale presets are mockup labels pending device review. Access reset from this route only. |
| 95 | S53 | FAQ · local references | Offline source attributions and reviewed educational text. Treat the pictured articles as examples of layout. |
| 96 | S54 | Save recovery | Restore the same profile from a valid last-known-good copy. If both are unreadable, present recovery and route any reset through Settings per D-018. |
| 97 | S55 | Confirmation · reset | Explicitly wipe progress and name, invalidate prior backup and return to naming. Cancel retains the same profile and Settings. |
| 98 | S56 | Dialogue · epilogue | Shared speaker panel and destinations to replayable Story, HQ and optional Chaos. Final prose and triggers are TBD under D-004. |
| 99 | S57 | Battle · local validation | Bad footprint, shortfall or cooldown binds failed validation and spends zero. “Need 11” and “Ready in 6 s” are examples. |
| 100 | S58 | Confirmation · wallet overflow | Manual claim has exact credit/discard and cancel. Immediate awards report settlement. Prototype case 9,990,000 + 54,000 with cap 9,999,999 credits 9,999 and discards 44,001. |
| 101 | S59 | Battle · Fixed Stockpile | C1-05 uses D05. Start at 120 Tokens, exclude all Posts and omit the free-Post tutorial. Apply D-011 eligibility and B13 exclusion in Chaos. |
| 102 | S60 | Article | Reuse reader for facts from Records, Garden or FAQ. No timer or recurring Funds. Keep content and review metadata separate from the layout. |
| 103 | V01 | Outreach · Acceptable | Grade variant of S42. Shown Lv.1 Funds and response are trial values. |
| 104 | V02 | Outreach · Poor | Grade variant of S42. Show explanation and zero Funds. |
| 105 | V03 | Outreach · Harmful | Grade variant of S42. Clamp loss to held Funds and persist the completed response. Sample loss is provisional. |
| 106 | V04 | Records quiz · incorrect | Explanation and zero Funds. Preserve question payout flag and accuracy separately. |
| 107 | V05 | Records quiz · timeout | Same feedback panel. Timeout pays zero. Visible timer comes from the current question. |
| 108 | V06 | Records quiz · first correct | Show actual one-time credit and set the paid flag. 30,000 is the prototype per-question value. |
| 109 | V07 | Upgrade detail · insufficient Funds | Show shortfall and originating detail. 10,000/60,096/50,096 are a worked display case. |
| 110 | V08 | Upgrade detail · participation gate | Outreach Lv.4→5 uses 950,000 and five Best/Acceptable responses. Ecology uses its own 60% gate and cost. |
| 111 | V09 | Garden · early | Two available slots at Lv.1. Locked tiles explain the needed Ecology level and link to its room. |
| 112 | V10 | Battle · cooldown card | Keep portrait and name beside the actual combat-time countdown. The pictured time is sample. |
| 113 | V11 | Battle · Token shortfall | Show needed Tokens and retain card identity. 35 cost, 24 held and 11 short illustrate the state. No failed spend. |
| 114 | V12 | Chaos composer · empty validation | Disable Start until there is at least one enemy and a legal opening. Empty slots add no rest. Nonpositive score pays zero if a run otherwise qualifies. |
| 115 | V13 | Battle · live Chaos | Same live HUD with Chaos label and populated waves. The three Ranger/two Facility selection depicts the worked example. |
| 116 | V14 | Confirmation · Ranger purchase | Quote Funds delta before committing. D-007 Lv.1→20 costs 60,096. Example 186,500 leaves 126,404. |

### Misty Approach and full tray

| UI PDF p. | Frame | Template or shared state | Binding and rule check |
|---:|---|---|---|
| 117 | M01 | Operation plan · T02 | C2-01 with gates A/B merging into a single tunnel. D06 and D02 fixed. 16/20/24 are first-pass Story wave counts. |
| 118 | M02 | Battle · normal free Post | Ordinary equipped Post uses the first-free rule and two elevated cells. This is a replay selection. The C1-01 mission allowance applies only to First Contact. |
| 119 | M03 | Battle · two entrances | Label A/B, keep blockers on ground and Scout elevated. Draw the two live routes and a common tunnel. Pictured placement is an example. |
| 120 | M07 | Dialogue · Leader on T02 | Same frozen battlefield and Continue/Skip. Mid-battle copy and trigger are illustrative. |
| 121 | M08 | Dialogue · Poacher on T02 | Swap speaker/portrait within the same overlay. Resume the same battle. Final dialogue is TBD. |
| 122 | M04 | Battle · Guard Veteran skill | Use actual ready charges from the Ranger. Preview the two tiles forward in the locked direction. Pictured charge count is contextual. |
| 123 | M05 | Battle · retreat | Reuse hold context and deployment cooldown states. Target/counters are example values. |
| 124 | M09 | Battle · cooldown card | Keep portrait/name and actual remaining time. The pictured countdown is illustrative. |
| 125 | M06 | Report · T02 Story | Same Story result and unlocking. K9 Ranger comes from C2-01; shown reward, HP and escape counters describe a sample run. |
| 126 | V15 | Battle · tray start | Eight Ranger/six Facility maximum; actual owned selections and cooldowns bind to the same continuous tray. |
| 127 | V16 | Battle · tray end | Same tray with scroll at the Facility end. Continue to show names, portraits and timers. |

## C09 handoff and acceptance

Start from the existing C05 shell, battle clock, deployment controller and [safe-area helper](../../scripts/ui/safe_area.gd). C09 covers main menu and Story nodes, simultaneous planning, shared dialogue/pause, live battle HUD and results. The room, Chaos and education templates are bindings for their later milestones. Preserve the [C05 physical-phone gate](../../export/README.md#c05-first-contact-phone-playtest) and record device evidence separately from desktop reference review.

| Check | Evidence to capture in implementation |
|---|---|
| Navigation and draft | Walk launch/name → Story → plan. Visit all selectors, cancel one and confirm another. Verify the same stage and draft return. Select a visible locked node and read its requirement. Test Settings from pause, including Back. |
| First action | On a clean C1-01 profile and its replay, show one Starter Post outside ordinary slots. Test a legal free drop, an invalid footprint with zero spend and a blocked opening. In a D05 fixture show 120 Tokens and no Post. |
| HUD and input | Check 16:9 and a wider/notched landscape phone at default and enlarged text. Log safe bounds, device density, transformed/clipped target widths and heights in dp. Pan both ends of the 14-card tray, drag onto every reachable board edge, confirm skill and hold Retreat. Record that the tray, HUD and notices leave route and legal cells visible. |
| Shared clock | Snapshot waves, HP, cooldown, build and Heat before pause/dialogue and after Resume/Skip at 1× and 2×. Verify no time advanced while held. Cancel abandon, then confirm it on another run and verify no payout. |
| Reports and finance | Exercise Story perfect after non-escape loss, normal clear with escape, defeat, Chaos unqualified with escape and qualifying tier crossings. Confirm wallet preview on a manual overflow claim and show settlement in an immediate award. |
| Later modes | Test purchase shortfall and participation gate, 49/50/51 wave edit boundary and all-empty Start, persisted 20-hour Outreach batch and 15-second quiz timeout, and the Garden midpoint checkpoint plus repeated collection protection. |
| Content and accessibility | Use the canonical 12 Rangers, 13 Facilities and stage/room IDs. Verify locks, warnings and grades remain legible without color alone. Navigate from title through play and read local references in airplane mode. |
