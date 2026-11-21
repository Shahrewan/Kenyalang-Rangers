# KENYALANG RANGERS — COMPLETE WORK + CODEX PRODUCTION PLAN

**Prepared:** 20 November 2026  
**Source authority:** `SimSimi.pdf` (GDD v1.0 pp. 2–33; gameplay mini-storyboard pp. 34–39) and `Kenyalang_Rangers_Tileset_UI_Storyboard.pdf` (127 pages).  
**Goal:** A real, installable, offline, single-player, landscape Android game in Godot 4, completing the documented 15-mission Campaign, 12 Rangers, 13 Facilities, 11-room Headquarters, Rainforest Chaos, Outreach, Records, Habitat Restoration, save system, UI, art, audio, and tested APK.

This is a production guide and prompt library, not a claim that any game code, sprite rig or playable build already exists. Phase names and implementation architecture are recommendations; documented gameplay requirements are taken from the provided PDFs. The PDFs name some additional source assets that were NOT included in the uploaded ZIP.

## Read this before using a prompt

1. **Do not run all prompts as one task.** Run one stage, inspect its results, test, commit, and then continue.
2. **Work = design/content/art coordination; Codex = production code and Godot integration.** Switch whenever the next task changes from specification/content to repo edits, or back to reviewing/auditing decisions.
3. Start all coding tasks by requiring Codex to read the root `AGENTS.md` and current canonical design files.
4. Work and Codex should share files via the **same local repository** in desktop ChatGPT, or via a private GitHub repo when using cloud tools. Their conversations themselves do not automatically merge.
5. **Protect the canon.** The current GDD establishes gameplay; the later UI storyboard provides visual guidance and reiterates corrected rules. If they genuinely disagree, record the discrepancy and seek an explicit ruling, rather than improvising a mechanic.
6. **Don't upscale placeholders into fake completion.** A screen mockup is not a working scene. A rig diagram is not a rig. A PDF atlas diagram is not a slice-ready PNG atlas.
7. **Build APKs early.** A C1-01 installation on the target phone is a gate before expanding to dozens of assets and game modes.

## Handoff framework

### Canonical repository structure (recommended)

```text
kenyalang-rangers/
├── AGENTS.md
├── README.md
├── project.godot
├── docs/
│   ├── reference/             # copies of the supplied PDF references
│   ├── canon/                 # GAME_RULES, data contracts, decisions, art/UX spec
│   ├── production/            # this plan, tickets, logs, test evidence
│   └── qa/                    # test matrix, device benchmarks, QA screenshots
├── data/
│   ├── rangers/ facilities/ enemies/ bosses/
│   ├── stages/ modifiers/ buffs/ dialogue/
│   └── education/ garden/ economy/
├── scenes/
│   ├── menus/ battle/ units/ facilities/ hq/
│   ├── chaos/ outreach/ records/ garden/ dialogue/
│   └── ui/
├── scripts/
│   ├── autoload/ battle/ data/ game_modes/ ui/
│   └── persistence/
├── assets/
│   ├── source-art/            # editable sources, if available
│   ├── imported/              # validated riggable parts/PNG/spritesheets
│   ├── backgrounds/ tiles/ ui/ portraits/ audio/
│   └── placeholders/
├── tests/
└── export/                    # no secrets or private signing keys committed
```

All filenames are suggested organization, not an assertion that those files exist.

### Common completion clause

Append this to **every Codex prompt** when needed:

> Keep the Godot project launchable and preserve all completed features. Make the smallest coherent changes. Read `AGENTS.md` and the approved specs; do not silently invent unresolved rule values. State changed files, data contracts, verified test commands/results, remaining issues, and manual Android test steps. Update the progress tracker. Do not report unrun tests as passed.

### Stage gates

- **Gate A — foundation:** the Godot project opens, runs with placeholders and exports a trivial Android build.
- **Gate B — vertical slice:** C1-01 is playable on a real Android phone, with waves/Integrity/Token loop/placement.
- **Gate C — combat complete:** all specified Rangers/Facilities/enemies/boss abilities work on the shared combat engine with automated mechanic tests.
- **Gate D — Campaign complete:** 15 ordered missions, UI planning, dialogue/events and unlocks work; phone UI readable.
- **Gate E — metagame complete:** 11-room HQ, full economy/upgrades, Chaos, Outreach, Records, Garden and persistence work together.
- **Gate F — release candidate:** asset review, accessibility, performance, complete regression tests, signed APK, verified install.

---

# PHASE 0 — CANON, GAPS AND SOURCE CONTROL

## W00 — Work: Create the canonical game production specification

**When:** First. **Output:** Text/data specifications only, no gameplay implementation.  
**References:** GDD pp. 2–33, storyboard pp. 2–11 and all labeled UI pages.

```text
I am producing the entire Kenyalang Rangers game in Godot 4 for offline Android landscape. Use BOTH supplied PDFs as source references: SimSimi.pdf (GDD rules) and Kenyalang_Rangers_Tileset_UI_Storyboard.pdf (visual and navigation reference). Do a source-based reconciliation, not a generic Arknights clone design.

Create repository-ready documents: docs/canon/GAME_RULES.md, SYSTEMS_INDEX.md, DATA_CONTRACTS.md, ART_AND_UI_SPEC.md, DECISION_LOG.md, and docs/production/BACKLOG.md. Catalog all 12 named Rangers, 13 named Facilities, 15 enemy IDs, three bosses, 15 missions, 11 HQ rooms, 15 R&D buffs, 15 debuffs and all four side activities. Cite exact PDF page/section for every nontrivial rule. Separate FIXED, PROVISIONAL and MISSING. Highlight the starter Logistics Post loadout exception, absent 116 editable SVG/source files, external story/quiz banks, Funds cap and provisional stage rewards.

Preserve the original GDD's wording, numbers, names and constraints. Where the documents don't specify a value, mark it TBD rather than inventing mechanics. Produce a milestone backlog with one testable ticket per subsystem and acceptance criteria. Do not write Godot scenes or GDScript yet.
```

**Exit check:** All documented entities have stable IDs and no unsupported source asset is labeled available.

## W00b — Work: Resolve only the blocking design decisions

```text
Read DECISIONS_TO_LOCK.md and the two PDFs. Rank unresolved choices by what blocks C1-01, progression and later content. For each decision, show the exact existing source rule, two or three minimally invasive implementation choices, tradeoffs and recommended default explicitly labeled as a proposal. Do not change canon until I approve a choice. Save approved choices with date and rationale in docs/canon/DECISION_LOG.md and update docs/canon/GAME_RULES.md only for those choices.
```

**Exit check:** Core tutorial's Post availability, setup validation, input model and Godot version are approved before C01–C05.

# PHASE 1 — GODOT PROJECT AND PROTOTYPE

## C01 — Codex: Initialize a clean Android-ready Godot repository

**When:** Immediately after W00 and decision lock. **References:** GDD pp. 28–30.

```text
Open the Kenyalang Rangers repository. Read AGENTS.md and docs/canon/GAME_RULES.md. Set up a minimal Godot 4 GDScript project pinned to one stable editor and matching export-template version, a landscape viewport with scalable UI/safe areas, Compatibility renderer as initial target, a placeholder Main Menu, and a sample battle scene. Add a README with exact PC launch/headless checks and Android export prerequisites. Create data directories and automated test conventions. Set up a private-friendly .gitignore for Godot imports, temporary builds and signing secrets.

Use only labeled placeholder art. Do NOT build the entire battle engine, roster or HQ yet. Run the project using the available Godot executable; report what was actually verified. Provide a procedure to install the first empty Android APK on a physical phone. Record the pinned version/device details in the decision log.
```

**Exit check:** Headless import/parse works; PC scene runs; first Android build installs or a precise documented blocker is recorded.

## C02 — Codex: Grid, path, shared combat clock and wave simulator

**References:** GDD pp. 8–9, 29; UI storyboard pp. 3–6.

```text
Implement a reusable tactical BattleScene with explicit ground/elevated/nondeployable tile types, predefined waypoint enemy paths, spawn and tree-veiled tunnel exit. Use T01's 12x5 tutorial-grid presentation as design reference, but implement coordinates and routes as data resources rather than art pixel detection. Establish a single battle CombatClock for paused/dialogue/1x/2x time, wave sequencing, intervals, empty-wave handling, enemy registry and Integrity starting at 100.

Provide minimal placeholder enemy actors that travel along route points and resolve as defeated or escaped. Combat waves must not continue behind pause or full-screen dialogue. Include deterministic tests for waves, clocks, win/loss and the distinction between cinematic messenger retreat and registered combat escape. Keep all physics, cooldown and effect timers consistent with combat time.
```

**Exit check:** Deterministic wave completion and pause tests; exiting an enemy subtracts Integrity; a scripted noncombat exit does not.

## C03 — Codex: Touch deployment, occupancy, facing, retreat and attack ranges

**References:** GDD pp. 8–9; UI storyboard S10–S15, S57, V10–V11.

```text
Add a touch-first deployment controller using press/drag/release with valid-tile previews, square ranged coverage and selectable left/right melee facing locked at placement. Support one-tile and two-ground-tile Rangers; reserve both occupied cells. Create elevated-unit and Facility occupancy interfaces, including two horizontally adjacent cells and future one-cell Sentry Tower+cell-above reservation. Implement short tap release to trigger/arm skill and long hold (~350ms provisional) to reveal nearby Retreat; target-confirm skills must never fire on an unconfirmed drag.

Test out-of-bounds drags, overlapping units, invalid ground/elevation types, two-tile placements, directional front attacks, aerial targeting exclusions, tap/hold threshold and redeploy cooldown. Never rely on a right-click action. Prefer input logic testable outside visual widgets.
```

**Exit check:** Touch controls can be exercised on device; invalid placement never charges Tokens or corrupts occupancy.

## C04 — Codex: Logistic Tokens and construction lifecycle

**References:** GDD pp. 8, 15–17, 20, 24.

```text
Implement the temporary Logistic Tokens wallet separately from persistent Funds. Normal battles start with zero Tokens. Respect the approved C1-01 starter allowance. If a Logistics Post is equipped, its first NORMAL deployment costs zero, builds instantly, skips opening cooldown and generates Tokens; later Posts have escalating costs, normal cooldown and normal construction. Lv1 yield is 10 Tokens/10s and Lv100 is 15 Tokens/10s; intermediate levels can accumulate fractions internally. Construction times never shorten with leveling. Cancellation of unfinished Facilities refunds the entire paid Token cost. Do not allow completed Facilities to be retreated or moved.

Implement the D05 Fixed Stockpile alternate rule: Posts forbidden, starting stockpile 120 Tokens, and no first-free-Post exception. Add deterministic timer/resource tests at pause, 2x, construction cancellation and insufficient Tokens. Keep all token graphics as neutral ticket/token shapes, not leaves or coins.
```

**Exit check:** Free opening Post and D05 are mutually exclusive; all paid costs/refunds reconcile.

## C05 — Codex: Complete and export Campaign C1-01 (VERTICAL SLICE)

**References:** GDD pp. 6, 8–9, 22; UI storyboard S04, S10–S24; mini-storyboard pp. 34–39.

```text
Create a fully PLAYABLE C1-01 First Contact tutorial using the shared BattleScene, the approved opening Logistics Post rule, Scout Sniper, Patrolman, a small original T01 chokepoint and two sequential waves of 6 and 8 Forest Trespassers/appropriate introductory threats as specified. Include deployment cost feedback, HP bars below models, targeting, attacks, basic blocking, first-stage tutorial text, C1-01 fixed D01 Thin Supply Line, win/lose result, Funds reward as a visibly provisional data value if not locked, and basic local save of first clear/perfect clear. The exit must be a tree-veiled tunnel, never an egg or nest.

Build the compact phone battle HUD without covering central tiles and an installable Android test APK. Test waves, pause, zero-token start, free Post, touch, retreat, escape, tutorial skip, outcomes, save/relaunch, notched/small landscape screen and interaction errors. Do not add more stages yet.
```

**Exit check / NO-GO checkpoint:** Do not expand the project until C1-01 plays correctly on a real Android phone and no game-breaking parse/runtime errors remain.

# PHASE 2 — PRODUCTION ART / UI PIPELINE (CONCURRENT AFTER C05)

## W06 — Work: Define production-ready skeletal sprite asset contracts

**References:** GDD pp. 17, 29–30; UI storyboard pp. 2–3, 11 and combat examples.

```text
Create a production art specification for the 12 CURRENT canonical Ranger sprites in Kenyalang Rangers: Scout Sniper, Crowd Controller, Guard Veteran, Patrolman, Barricade Ops, K9 Ranger, Combat Medic, Kenyalang Seer, Outpost Mechanic, Woods Tracker, Saboteurist and Strike Team. Ignore older, noncanonical roster names and animal-hero art.

The style is flat-color, mouthless, thick-outlined, earthy chibi with oversized head, tiny body, few clear props, minimal shading, strong silhouettes at 62–78 visual units tall in a 1280x720 reference layout. Define per-character equipment silhouettes, neutral pose, orientation requirements, transparent individually exported PNG body pieces, correct stacking/overlap, hidden-area fill under joints, normalized canvas, suggested pivot metadata, import-scale rules, naming convention and versioning. Dialogue portraits are a separate more detailed asset family.

Make ONE sample Scout Sniper cutout kit with a manifest and reference sheet first. Explicitly distinguish image mockups from actual editable/sliced, alpha-transparent body layers. If the tool cannot output independent layered components, report that limitation and propose manual slicing/redraw steps rather than asserting that a flattened sprite is rig-ready.
```

**Exit check:** A set of independently editable body pieces, not just a character picture or sprite sheet.

## C07 — Codex: Prove the Godot cutout rig pipeline on one Ranger

**References:** GDD pp. 29–30; Godot stable cutout/2D skeleton docs.

```text
Using the approved Scout Sniper art-kit manifest and independent transparent body-part PNGs from assets/imported/rangers/scout_sniper/, build a reusable, lightweight Godot 4 Skeleton2D/Bone2D or documented cutout rig with appropriate layers, pivots and safe joint overlaps. Add AnimationPlayer/AnimationTree as justified and the minimum states Idle, Move (if used), Deploy, Attack, Skill, Hit and Retreat/Defeat. Preserve visual scale for small on-field chibi units.

Do not fake the separate artwork by cropping a flattened mockup without checking occluded joint details. If approved parts are unavailable, build a clearly labeled procedural/placeholder proof and keep art delivery as an open dependency. Compare on real phone at battle scale and test orientation, flipped ranged facing, fixed melee facing when applicable, animation-pause and 1x/2x controls. Document a reusable rig template and onboarding steps for all 12 Rangers and enemy variants.
```

**Exit check:** A real running rig animates without visible gaps or broken pivots in Godot at phone scale; not just a diagram.

## W08 — Work: Convert 127-page UI storyboard into an implementation-ready design system

```text
Use Kenyalang_Rangers_Tileset_UI_Storyboard.pdf as a VISUAL SPECIFICATION, NOT as 116 finished UI scenes. Produce docs/canon/UI_COMPONENT_SPEC.md and docs/canon/ART_ASSET_MANIFEST.md from its screen IDs. Group 116 screen/state mockups into reusable components and templates: shell/navigation, modal, mission card, loadout, battle HUD, skill targeting, results, HQ room, upgrade detail, Chaos builder, quiz response, garden plot, settings/error feedback.

Retain palette, 1280x720 visual reference, scalable safe areas, minimum real 48dp touch regions, narrow scrollable deployment tray and 12x5 tutorial presentation. Compare GDD gameplay rules with each UI example and flag mockup values that are merely illustrative. Distinguish required unique illustrations from state variants achievable with one reusable component. Define six map geometry resource layouts and a 56-piece technical atlas inventory; do not claim the PDF tile diagram is a completed exportable atlas. Produce prioritized asset tickets for the missing source SVG/PNG/JSON layers.
```

**Exit check:** A reusable screen/component inventory, not 116 separate unmaintainable Godot scenes.

## C09 — Codex: Implement navigation, battle HUD, planning screen and reusable UI primitives

**References:** GDD pp. 14–15; storyboard S01–S24, S57, V10–V11.

```text
Implement shared scalable UI components derived from the approved UI spec. Build Main Menu, Story node list, simultaneous pre-battle planning, full-screen pause/dialogue overlay, compact battle HUD and results. Planning must expose chosen Rangers, Facilities, selectable eligible R&D buffs, fixed debuffs and full incoming wave/enemy preview on one screen (sub-panels/scrolling are allowed while preserving simultaneous availability). Show wave progress, numerical Integrity, Tokens, pause, 1x/2x, small HP bars and horizontally scrollable deployment portraits.

Use a single navigation/router pattern and data-binding to game state, not hardcoded storyboard screenshots. Support error/disabled states for insufficient Tokens, cooldown, illegal footprint, ineligible buff and missing unlock. Optimize touch targets and safe areas on phone. Keep the battlefield visible and use original icons/art only.
```

**Exit check:** Usable navigation and HUD tied to live game state; no giant decorative panels blocking tactical geometry.

# PHASE 3 — COMPLETE TACTICAL COMBAT

## C10 — Codex: Build all 12 Rangers, one class at a time

**References:** GDD pp. 9–11. **Important:** Treat as FOUR bounded tickets, not one unreviewed huge edit.

```text
Using the GDD Ranger registry and the approved data contracts, implement a data-driven catalog for ALL 12 canonical Rangers grouped as Offense (Scout Sniper, Crowd Controller, Guard Veteran), Defense (Patrolman, Barricade Ops, K9 Ranger), Support (Combat Medic, Kenyalang Seer, Outpost Mechanic) and Specialist (Woods Tracker, Saboteurist, Strike Team). Work in class-sized commits and stop for test review between classes.

Implement actual HP/damage/heal/repair output, square ranges, block capacity, target preferences, skill state/charges/target confirmation, cooldown/redeploy, status application, 1- or 2-cell footprints, and special retreat/on-arrival effects. Examples requiring explicit tests: Guard Veteran four-charge attack, K9 dog howl having ZERO damage, Seer mark stacking max 10, Mechanic repairs Facilities and Barricade Ops but does not generally heal Rangers, Woods Tracker net and qualified retreat refund, Saboteurist tech retreat effect, Strike Team escalation and two-tile placement. Keep Level 1 values provisional and editable through resources. Add isolated unit tests and a combat sandbox scene.
```

**Exit check:** All 12 behaviors can be reproduced in combat sandbox; don't equate a roster data table with working AI/skills.

## C11 — Codex: Build all 13 Facilities and Siege-only Facility damage

**References:** GDD pp. 15–17.

```text
Implement the full 13-Facility catalog: Logistics Post, Medic Cabin, Skill Relay Station, Dispatch Relay, Sonic Turret, Electric Pulse Turret, Canopy Defense Launcher, Sentry Tower, Firebreak Beacon, Specialist Calltower, Ranger Coordination Hub, Reinforced Cover Station and Disruption Beacon. Split into Resource, Sentry, Strategist and Status commits.

Use only elevated legal placement with each Facility's actual footprint: default 2 horizontal tiles, except one-tile Sentry Tower whose tall sprite also reserves the cell above. Build timers never shorten with leveling. Implement Siege-only Facility damage during and after construction; ordinary ranged/melee/projectile hits never reduce Facility HP. Fully implement damaged state, repairs by Mechanic, cancel-full-refund, turret targeting, manual medic kit stock, cooldown pulses, detection/mounted ranger behavior, Heat slowdown, Specialist discount and named reduction/status effects. Test collision, overlaps, mount slot, repair and destruction.
```

**Exit check:** Facility Siege targeting is enforced as an invariant in automated tests and real battles.

## C12 — Codex: Enemy roster, bosses, ability interactions and Heat

**References:** GDD pp. 11–13, 9, 22.

```text
Implement the E01–E15 enemy roster from the GDD with its exact names, HP, Danger Level and functional tags (Technological, Invisible, Aerial, Heavy, Environmental, Siege-capable). Add ordinary melee/ranged behavior, conceal/reveal, aerial non-blockability, Runner sprint, Net Trapper entangle, Signal Jammer interference, Tracking Bot debuff, Heavy Breacher Knockdown and Wildlife Trafficker immediate failure on escape. Only Demolitionist and Portable Mortar Crew have the specified regular Siege attacks. Implement stage-local Heat accumulated by Ignition Operator and reduced (never eliminated) by Firebreak Beacon. Heat reaching threshold damages Integrity, not Facility HP.

Add separate boss templates for Diversion Captain (C1-05), Illegal Logging Foreman (C2-08) and Poacher Leader (C2-10), with deterministic phase and reinforcement triggers. Bosses are not Siege attackers unless explicitly specified. Build an interaction test matrix for clock pause, delayed ability, mark stacking, aerial, Siege, buffs, boss transition and victory resolution. Tune numbers only via data resources, preserving a change log.
```

**Exit check:** Every enemy/boss has test scenarios for spawn, targeting, damage, status, death, escape and pause.

# PHASE 4 — MAIN STORY AND LIVE CONTENT

## W13 — Work: Author Campaign data tickets, complete dialogue, regional art instructions

**References:** GDD pp. 6–7, 21–22; UI storyboard p. 8, S09/S09L/S09E, M07/M08; mini-storyboard.

```text
Create a 15-stage content specification, not actual running Godot levels. Chapter 1: C1-01 First Contact, C1-02 Hold the Line, C1-03 Narrow Escape, C1-04 Watch the Ridge, C1-05 Operation: Full Pivot—all share exact T01 geometry. Chapter 2: Gunung Mulu C2-01/02, Batang Ai C2-03/04, Tanjung Datu C2-05/06, Imbak Canyon C2-07/08, Sepilok-Kabili C2-09/10; two missions share each original regional template. Preserve wave counts, debuff IDs, unit/facility rewards and boss positions from the GDD table.

Find/ask for the referenced original full Chapter 2 script before writing replacement dialogue. If absent, write a NEW PROPOSED script with clear review status, not 'recovered canon'. Include Operations Manager, patient faceless Leader, serious later chapter tone, skippable full-screen opening/wave/boss/outcome dialogue, timed triggers and fact source review. The messenger retreat is cinematic and NEVER an escaped combat registry entity. Create per-stage resource-ready JSON/CSV designs for exact spawn groups, timing, scripted events, enemy summaries, loss conditions and reward placeholders clearly marked provisional.
```

**Exit check:** 15 reproducible content specifications; all noncanonical dialogue and numbers visibly flagged for approval.

## C14 — Codex: Implement full 15-stage Campaign using shared stage resources

```text
Implement the approved stage resource importer/loader, five original map templates beyond T01, 15 missions, prerequisite-unlock logic, in-mission tutorial prompts, stage-specific fixed debuffs, scripted reinforcements, rewards, replay and perfect tracking. Stage order and wave counts follow the GDD. Control Room level reveals additional fogged nodes but cannot skip previous-clear requirements.

Implement dialogue event hooks at mission start, designated wave transitions, boss arrival/HP thresholds, success and failure. A full-screen dialogue overlay pauses every combat clock and must resume to the SAME deterministic state after Continue or Skip. Verify C1-05 Fixed Stockpile, C2-07/08 Heat, boss capture/finale, forced Wildlife Trafficker failure, and replay rewards. Create scripted regression runs for all 15 resources and test narrative skips at several timings.
```

**Exit check:** Can complete all 15 missions sequentially, replay earlier missions, skip all dialogue and never accidentally unlock an uncleared later mission.

# PHASE 5 — HEADQUARTERS, PERSISTENCE AND UPGRADES

## C15 — Codex: Headquarters 11 rooms, unified Funds, leveling and robust saves

**References:** GDD pp. 18–21, 28–29; UI storyboard S25–S34, H/U/F, S58, V07–V08/V14.

```text
Implement the Headquarters as a modular wide cross-section of 11 selectable modern office rooms (not an open-plan character walk simulation). Control, Human Resources and Finance start at Lv1, with a proposed 10,000 starting Funds according to the GDD; eight other rooms must be purchased. Make per-room Level 1–5 costs, unlocks and participation gates data-driven and reproduce the GDD table; full HQ max cost totals 16,160,000 Funds. HR controls Ranger loadout slots (3→8), Mechanical Facility slots (2→6), Finance active-unpaused Funds and cap, Ecology plots, Outreach payouts, Records chapters and four R&D rooms.

All 12 Rangers and 13 Facilities have Level 1–100 purchases. The cumulative level cost function must match C(L)=round(1,000,000*(0.15x+0.85x²)), x=(L-1)/99, with C(1)=0 and C(100)=1,000,000 per deployable, and milestones 20/40/60/80/100. Levels improve raw outputs only; no new skills, shorter build times, extra blocks, or extra currencies. Implement Funds cap as one configured constant, wallet overflow destroyed with UI warning, purchase errors, negative PR deductions, versioned local save, atomic-ish write/backup and recovery UI. Persist all stage unlocks, levels, upgrades, quiz/grading and garden timers. Add arithmetic, reload and migration tests.
```

**Exit check:** Full progress survives cold restart and Funds can never exceed configured cap; totals and slots reconcile with GDD.

## C16 — Codex: 15 R&D buffs and 15 mandatory/optional debuffs

**References:** GDD pp. 19–20, 23–24.

```text
Build a single data-driven modifier system for B01–B15 R&D buffs and D01–D15 debuffs with stable IDs, additive/multiplicative priority rules, applicability validation, named source effects, UI eligibility and tests. R&D room levels unlock choices without increasing buff strength. One unique selected buff in Chapter 1, two in Chapter 2, and any number of DISTINCT compatible unlocked buffs in Rainforest Chaos. Chapter 1 has one fixed stage debuff; Chapter 2 two. No duplicates, slot-removal debuffs, 'contracts' UI terminology or score for irrelevant/ineffective debuffs.

Explicitly test combinations B13 Emergency Requisition (+35 Tokens with lower generation), B15 Silent Mobilization (skill disabled), D05 Fixed Stockpile (120 Tokens/no Posts), D14 Heat Surge only on Heat-enabled maps, D09 Siege Damage and D10 delayed build. Every modifier must affect a real subsystem, and its disabled state must be visible before battle.
```

**Exit check:** Modifier eligibility and deterministic interactions are tested; no duplicate or no-effect scoring exploit.

# PHASE 6 — RAINFOREST CHAOS

## C17 — Codex: Full configurable Chaos mode, scoring, payouts and trophy

**References:** GDD pp. 15, 24–25; UI storyboard S35–S40, S36, S38, V12–V13 and p. 9 worked example.

```text
Implement Rainforest Chaos: choose an original approved route, configure up to FIVE wave slots with enemy-type row sliders and +/- controls, total 1–50 enemies in each POPULATED wave, skip empty waves without rest, select Ranger/Facility loadout, R&D buffs and distinct eligible debuffs, and preview calculated Medal Score/Funds/trophy before launch. Block the 51st enemy in each wave, even across mixed enemy types.

Score = sum enemy-count*enemy points + debuff points -100 per FILLED Ranger slot -100 per FILLED Facility slot - selected buff penalties. EMPTY slots award no points. Validate the storyboard worked example: waves worth 1,050+500; debuffs +400; five filled slots -500; buff -100; final S=1,350 with qualifying payout 54,000 Funds. Success and payouts require positive Integrity AND zero configured enemy escapes, with every configured enemy defeated. Calculate piecewise linear payouts: below 1000:20*S; 1000–1999:40000+40*(S-1000); 2000–2999:130000+70*(S-2000); 3000+:300000+120*(S-3000). First threshold rewards at 1000/2000/3000 unlock Skill Relay Station/Specialist Calltower/Sentry Tower and the trophy visual tier, capped in appearance at Tier 3. Store personal best. Run boundary tests at scores 0, 999, 1000, 1999, 2000, 2999, 3000 and >3000.
```

**Exit check:** Score/payout example and boundary tests match exact GDD values; escape or defeat yields no Chaos Funds/record.

# PHASE 7 — EDUCATION AND HABITAT RESTORATION

## W18 — Work: Create factual, localized education banks

**References:** GDD pp. 25–27, 30, 32–33; UI storyboard S41–S46 and S60.

```text
Locate the actual approved Outreach bank and Records question source files referenced by the GDD. If missing, author DRAFT replacement datasets for review rather than claiming recovery. Outreach must have 20 distinct public-relations situations, each with FOUR choice responses graded Best, Acceptable, Poor and Harmful, randomized choice positions, justifications and topical coverage: nest-location privacy, wildlife rescue, misinformation, donor transparency, community needs and responsible tourism.

Records should have approximately 40 factual conservation questions across four chapters, four choices each, the correct answer and brief factual explanation, with 15-second countdown during play; the final exact count/reward values remain provisional until team approval. Link the four perfect-chapter bonuses to Scout Sniper, Patrolman, Combat Medic and Woods Tracker enhancements; NOT Strike Team. Fact-check against Forest Department Sarawak and IUCN Hornbill Specialist Group sources. Supply JSON schemas, question IDs, reference URLs, review status, sensitive nesting-information safeguards and licensing notes. Do not invent unsupported science facts.
```

**Exit check:** Every question has validation and sourced explanation; no bogus citation or sensitive nesting location disclosure.

## C19 — Codex: Outreach 20-hour batches and Records quiz/Encyclopaedia

```text
Import only approved question banks. Build Outreach room's rotating 20-question bank with up to five distinct four-choice questions per LOCAL-device 20-hour batch, response grading Best/Acceptable/Poor/Harmful and Funds changes according to Outreach room level (GDD p. 26). Persist active batch, answered IDs, grade and next-refresh timestamp even after app closure; show the timer and explanation; five Best/Acceptable responses are needed for Outreach Lv5 participation gate. No real social network or reputation currency.

Implement Records facts browse, four level-unlocked quiz chapters, a pause-correct 15-second timer, first-correct-only Funds reward per unique question, once-only chapter perfect reward and its named Ranger enhancement. Replays never duplicate the first-correct reward. Add tests for clock changes, batch rollover, negative Funds effects, question replay, quiz timeout, perfect bonus, local save/relaunch and app exit during a question. Document accepted local-time clock-manipulation limitation without introducing a server.
```

**Exit check:** Quiz/explanation works from actual data, and repeated answers cannot farm one-time rewards.

## W19b — Work: Restoration content and four-species illustration set

**References:** GDD pp. 27–28; UI storyboard S47–S51 and V09.

```text
Use the GDD Restoration section to design four stylized native-tree assets: Strangler Fig, Belian/Bornean Ironwood, Red Meranti and Mengaris, each with exactly three clearly recognizable growth stages Seed, Sapling and Mature. Create transparent, consistently sized, exportable art or list missing editor-ready parts. Design the six-plot garden background, gentle watering and collection effects, one-off artificial nest-box milestone art, and a small informative Rhinoceros Hornbill guide. Preserve the no-death/no-wilt rule and conservation fact accuracy. Provide verified fact URLs and never imply the game's 18–72-hour growth equals real forest maturation.
```

**Exit check:** Three stages per species, consistent naming/import guides and factual/attribution record.

## C20 — Codex: Garden, growth persistence and milestones

```text
Implement the Ecology room's Habitat Restoration activity and the Main Menu Reforestation shortcut, both opening the SAME garden scene. Support 2 plots at Ecology Lv1 expanding to 6 through room upgrades, four species with proposed 18/36/48/72-hour base durations, Seed/Sapling/Mature appearance, local-clock timestamps, limited watering checkpoints, maturity collection and replanting. Plants NEVER wilt or die; lack of watering pauses growth at the next checkpoint. Trees remain visually represented after completion while a gameplay plot becomes reusable, as documented.

Persist timers while the app is closed, show staged information and one-time conservation discoveries, implement the 20/40/60/80/100% restoration milestones and one-time Funds rewards 50k/150k/350k/750k/1.25M. Ecology Lv5 must require at least 60% participation milestone AND room Funds price. Nest-box discovery is a one-off visual/fact event, not a new currency or management minigame. Test offline app reopen, altered clock, delayed watering, replanting, reward once-only and Funds cap.
```

**Exit check:** Growth states are deterministic across app restarts; no planting exploit or repeat milestone payouts.

# PHASE 8 — ASSET COVERAGE, POLISH AND RELEASE

## W21 — Work: Finish the production asset manifest and audit art/audio usage

```text
Audit all current Godot scene assets against the GDD and 127-page storyboard, screen by screen at a component/template level. Build a production manifest listing every remaining Ranger/enemy/boss cutout kit, Facility state, tree stage, HQ room, region backdrop, six original tile layouts, 56 technical atlas pieces, three boss portraits, dialogue illustrations, icon, VFX and sound cue. Identify duplicates that can reuse one source, and unique assets needed for correct legibility. Prioritize missing assets by gameplay risk rather than illustrative prettiness. Keep copyright provenance/attribution and avoid reusing Arknights maps, logos, sprites or assets. Do not assert that unfinished PDF illustrations are exported PNG layers.
```

**Exit check:** Every in-game placeholder has a documented replacement ticket or an approved decision to retain it.

## C22 — Codex: Complete reusable UI, accessibility, audio and control integration

```text
Complete all UI COMPONENTS and dynamic states represented by the storyboard, not 116 independent duplicated scenes. Add the remaining HQ, skill/retreat, Chaos, quiz, garden, help, FAQ, References, settings, pause, reset confirmation, cap warning and save recovery states. UI text scales; icons and shape supplement color; tap targets are at least 48dp after real device scaling; compact HUD and narrow swipeable tray remain usable up to 8 Rangers + 6 Facilities. Implement master/music/SFX sliders and meaningful visual alternatives to critical audio alerts. Story dialogue uses separate large expressive portraits, Continue and Skip, and never resumes timers early. Add plain-language invalid action feedback and Settings save-wipe confirmation.

Test screen transitions, Back handling, persistence, rotation locking, landscape cutout safe areas and every UI error variant. Replace placeholders only with confirmed/approved imported assets. Confirm no forbidden old tokens, egg/nest Integrity objective, oversized on-field buildings or generic Defense stat leaks into labels.
```

**Exit check:** Every storyboard functional flow can be navigated and produces the specified actual game result.

## C23 — Codex: Regression suite, balancing and crash/save resilience

**References:** GDD pp. 20–21, 29–31.

```text
Run a full-system audit of the Godot project. Write deterministic regression tests for 15 stages, 12 Rangers, 13 Facilities, 15 enemy types, 3 bosses, 15 buffs, 15 debuffs, first Post, D05, all 11 rooms, 25 deployable level curves, fixed Funds cap, Chaos thresholds, Outreach 20-hour refresh, Records first-correct rewards, garden milestones, pause/dialogue and local save recovery. Stress test a 50-enemy Chaos wave with multiple Rangers/Facilities and overlapping statuses; instrument frame time and memory on actual candidate Android phones.

Build a reproducible 60-day **economy simulation**, not an assumption of real user behavior: compare the GDD scenario contributions (~7.42M Campaign, 5.0M Outreach, 5.3M Garden, 5.2M Chaos, 1.55M Records, .55M Finance/replays) against the desired ~24.16M expense (16.16M HQ + 8 max-level deployables). Flag impossible pacing, overly fast Chaos loops, Funds-cap overflow losses and broken unlock gates. List changes as proposals rather than silently replacing balancing data. Record measurable FPS outcomes and device specifications; do not promise 60 FPS without benchmarks.
```

**Exit check:** All blockers fixed; reproducible test log, balance simulation, device-measured FPS and no corrupted saves.

## C24 — Codex: Android release candidate and handoff

```text
Prepare an Android release candidate for Kenyalang Rangers using the pinned Godot editor/export templates. Verify the package identifier, orientation, min Android target and supported ARM64 configuration; use approved app name/icon and a release-safe signing procedure (NEVER commit keys or passwords). Export APK (and AAB only if the chosen distribution requires it), install on actual Android phones and run the entire first-use and returning-save flows without networking.

Create deliverables: an installable build, version/build metadata, accurate device test matrix, a QA checklist with real pass/fail results, controls/help page, conservation sources/credits, known limitations (local clock trust and provisional balance if any), and a reproducible export guide. Demonstrate C1-01, a later Story stage, boss, HQ purchase/upgrade, Chaos score boundary, Outreach, Records, Garden and save-relaunch. Provide a release signoff report containing unresolved blockers; do not claim production-complete if any required mode is missing.
```

**Exit check:** Human-verified install + feature playthrough on Android; launch without internet; no crash or missing asset during representative flows.

---

# OPTIONAL REPEATABLE PROMPTS FOR FUTURE ITERATIONS

## R01 — Work: Design audit after any completed Codex milestone

```text
Review the repository change summary, available screenshots, exact test evidence and user-verified gameplay for milestone [ID]. Compare with SimSimi.pdf GDD sections/pages [X] and storyboard frames/pages [Y]. Make a compliance table: confirmed / needs manual verification / incorrect / missing asset / unresolved design choice. Write at most five highest-priority follow-up implementation tickets, each with acceptance tests and no unsupported assertions. Do not modify code in this review.
```

## R02 — Codex: Debug one verified issue without broad rewrites

```text
Fix the verified bug [DESCRIPTION] in Kenyalang Rangers. Reproduction: [EXACT STEPS]. Expected behavior: [GDD RULE]. Actual behavior/log: [LOG]. Read AGENTS.md and inspect dependent systems before changing files. First add a regression test that fails before the fix (where practical), implement the smallest solution, run relevant tests and a Godot smoke check, list changed files and note any remaining reproduction cases. Do not refactor unrelated scenes or gameplay values.
```

## R03 — Work: Author one design-change request, then hand to Codex

```text
I want to change [RULE] from [OLD] to [NEW]. Compare the current GDD, approved canon, related UI mockups and implemented systems. Prepare a design-change proposal listing directly affected levels, data resources, balance, save migration, UI/tutorial text and tests. Explain tradeoffs and whether it conflicts with other canonical rules. Stop for approval before updating GAME_RULES.md or sending an implementation ticket to Codex.
```

## R04 — Codex: Create tests before changing a complex interdependent system

```text
Read current GAME_RULES.md, AGENTS.md and the existing code for [SYSTEM]. Enumerate invariants and build deterministic tests for documented cases and boundaries before changing architecture. Present a minimally invasive plan, apply only an approved scoped refactor, run tests and compare before/after effects. Specifically guard pause behavior, save serialization and upgrade/buff interactions. Output concrete results, not generic reassurance.
```

---

# WHICH MODEL AND WHICH EXPERIENCE?

| Task | Recommended experience | Model/effort recommendation |
|---|---|---|
| Source reconciliation, backlog, milestone brief | Work | Sol by default; harder reasoning only for contradictions |
| Straightforward Godot scene and GDScript | Codex | Sol by default |
| New combat architecture / many interacting systems | Codex | Start Sol with a plan; escalate if genuinely blocked |
| Sprite concept, color/pose sheet, layered asset plan | Work + appropriate image/graphics tools | Model choice secondary to **editable asset quality** |
| Rigging imports, Bone2D, AnimationPlayer, state machine | Codex | Sol; escalate for hard rig/export/debug issues |
| Research-backed conservation explanations | Work | Verify against sources and review manually |
| Android export, real-device profile, regression tests | Codex | Sol ordinarily |
| Design compliance and screenshot audit | Work | Sol ordinarily |

**Model usage principle:** A higher-end reasoning model does not automatically make a better layered sprite or ensure a bug-free game. Spend first on proper specifications, source layers, tests and small changes. Upgrade reasoning effort/model only for proven difficult cross-system problems.

# REALISTIC SCOPE AND DELIVERY ORDER

This is a large original student/indie game, even though its combat is simplified compared with Arknights. The 116 storyboard frames are UX references, not 116 fully separate scenes that must be individually generated. Reusable screens, shared character controllers, typed resources, and data-driven stage scripts reduce the amount of bespoke code, but **every Ranger ability, enemy interaction, mission content, offline timer and art kit still needs implementation and testing**.

The most important dependency chain is:

```text
Canonical rules -> Godot/Android smoke test -> shared battle clock/grid
-> touch deployment + Token economy -> C1-01 on phone
-> reusable animation/UI pipelines -> complete combat roster
-> 15 mission content + dialogue -> HQ/Funds/levels/modifiers
-> Chaos -> education/garden -> integration/QA -> release APK
```

Art, sound, educational content and region backdrops can be developed in parallel **after** their pipelines/specs are settled, but avoid parallel edits to the same Godot scenes. For a small part-time team, schedule around verified milestones rather than assigning an unrealistic fixed number of AI prompts or promising a finish date.

# NON-NEGOTIABLE ACCEPTANCE MATRIX

| System | Must be verified |
|---|---|
| Offline & Android | Fresh install, landscape, touch-only, no network calls required, safe areas, save-reopen |
| C1 tutorials | Free Post, two waves in C1-01, fixed map reused for all 5 C1 missions, skippable narration |
| Combat | 100 Integrity, no Defense stat, explicit Siege-only Facility damage, facing, aerial, pause/dialogue clocks |
| Roster | All 12 named Rangers, 13 named Facilities, E01–E15 + 3 bosses, skill/status/cooldown tests |
| Story | 15 linear/replayable missions, two Chapter 2 missions per region, ordered unlocks, correct boss operations |
| Progression | 11 rooms, room Lv1–5, 25 deployables Lv1–100/1M Funds each, fixed Funds-only economy |
| Modifiers | 15 B and 15 D IDs, no duplicates, eligibility, no ignored modifier free score |
| Chaos | 5 slots, ≤50 per wave, empty-wave skip, 1350→54000 worked example, strict zero escape, tier thresholds |
| Outreach/Records | 20-hour/5 response batch, 20 scenarios, 4 grade types, 4 Records chapters, unique one-time rewards |
| Garden | 4 species, 3 visual stages, 2→6 plots, no plant death, local offline watering/maturity, milestone gates |
| Art/audio | Real riggable layers, original sparse tactical maps, 60 FPS **measured** against target phone, correct credits |
| Release | APK installs; full critical-path walkthrough; no undocumented placeholders masquerading as complete |

**Final note:** The source files explicitly describe certain figures as **provisional** (GDD p. 33, storyboard p. 10). Their inclusion in a prompt is for reproducible first-pass testing, not a claim that the original team has approved those balance values.
