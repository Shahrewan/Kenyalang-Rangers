# Kenyalang Rangers milestone backlog

These are future testable tickets. **GDD** is *SimSimi.pdf* Task 1 (GDD v1.0). **Mini** is Task 2 (PDF pp. 34–39). **UI** is *Kenyalang_Rangers_Tileset_UI_Storyboard.pdf*. See the [systems catalog](../canon/SYSTEMS_INDEX.md), [data contracts](../canon/DATA_CONTRACTS.md), [art and UI spec](../canon/ART_AND_UI_SPEC.md) and [decision log](../canon/DECISION_LOG.md). Unresolved source values are `TBD`. Any temporary test value needs a fixture label and its source or decision reference.

| Milestone | Exit condition | Existing tracker work |
|---|---|---|
| M0 · Source and boot | Record the starter allowance and verify a pinned editor/export smoke build. | W00, W00b, C01 |
| M1 · First Contact | Play a complete C1-01 on a phone with touch deployment, wave resolution, results and retry. | C02–C05, core of C09 |
| M2 · Tactical roster and art | Verify all tactical registries, source asset coverage, original boards and a battle-sized rig. | W06, C07, W08, C10–C12, part of W21 |
| M3 · Regional Campaign | Verify ordered progression, all 15 operation records and authored dialogue triggers. | W13, C14 |
| M4 · Local progression | Verify room and deployable purchases, shared wallet, save recovery and modifiers. | C15–C16, part of C23 |
| M5 · Four side activities | Verify Chaos, PR, Records and Restoration loops, rewards and participation gates. | C17, W18, C19–C20 |
| M6 · Android release validation | Validate touch, accessibility, performance, balance and signed install on named Android devices. | W21, C22–C24 |

Downstream catalogs may use deterministic tests for dependencies pending integration. Real completion evidence belongs in [the progress tracker](PROGRESS_TRACKER.md). Record the commit, automated results, device evidence where applicable, open issues and review. [GDD pp. 29–31 §§ O.4, S.1–3; repository AGENTS.md, Testing and delivery]

## M0 · Source and boot

### KR-01 · Verify the starter loadout

- Implement and verify the [approved D-001 rule](../canon/DECISION_LOG.md#approved-decisions). A new save and a later replay list Scout Sniper, Patrolman and one mission-issued Starter Post outside Mechanical capacity. The supply ends with the operation.
- Verify the fixture leaves Mechanical unbuilt and its separately purchased Lv.1 two-slot capacity intact. Demonstrate that D05 denies the Post regardless of a tutorial grant.
- **Evidence.** GDD pp. 8–9, 18–19, 22, 24 §§ G.3, H.1, M.1, M.4, M.6; UI pp. 10, 22, 39, 62, 101 S10/S26/S28/S59.

### KR-02 · Version-pinned PC and Android boot

- Import and start the project under the pinned Godot 4.7.2 editor. Verify the editor and Android export template versions match and capture real tool output.
- Install a development APK on a named Android device. Boot in airplane mode, verify landscape and basic touch input on the safe-area surface, and record renderer/device details. Close the smoke gate only with device evidence.
- **Evidence.** User project configuration; GDD pp. 4, 28–30 §§ C, O.1, O.4, S.1; UI p. 3. Gate D-013.

## M1 · First Contact

### KR-03 · Grid, routing and occupancy

- **Depends on KR-02.** Use original T01 geometry and separate route and elevated cell types. Trace an enemy from entry through ground waypoints to the forest tunnel. There is no route through a platform.
- Reject overlap, blocked and off-board footprints. Verify both cells for a two-cell ground Ranger or 2×1 elevated Facility. Verify Sentry Tower occupies one elevated cell and reserves the cell above in a fixture.
- **Evidence.** GDD p. 8 § G.2; pp. 10, 17, 32 §§ H.1, J.2, T.2; UI pp. 4–6, 25, 66 S12/S32.

### KR-04 · Combat clock, waves and Integrity

- **Depends on KR-03.** Run sequential single spawns. Resolve each populated wave before the rest and next wave. Empty Chaos slots consume no spawns or rest. Repeat with 1×/2×, pause and dialogue and compare wave order and all combat timer snapshots.
- Start at 100 Integrity. Ordinary escape subtracts its fixture penalty, zero Integrity defeats, and a cinematic withdrawal leaves the escape count unchanged. A positive-Integrity Story result with zero escapes stays perfect after non-escape Integrity loss.
- **Evidence.** GDD pp. 6–9 §§ F.2–4, G.1, G.5; pp. 24, 29, 31 §§ M.7, O.2–4, S.3; UI pp. 8, 30–35 S17–S22.

### KR-05 · Touch deployment, skills and retreat

- **Depends on KR-03, KR-04.** Drag from the tray, preview legal footprints and forward reach, choose either facing for a melee Ranger, and verify it stays locked. Off-board, occupied and insufficient-Token drops show a reason and spend zero.
- Verify eligible tap release, valid target confirmation where applicable, and hold → contextual Retreat with no accidental skill. The retreated Ranger retains a visible cooldown before redeployment. Tune the proposed 350 ms threshold with touch evidence.
- **Evidence.** GDD pp. 8–9, 15, 29 §§ G.2–3, I.3, O.3–4; UI pp. 25–27, 99, 112, 124 S12–S14/S57/V10/M09.

### KR-06 · Token opening and Facility lifecycle

- **Depends on KR-01, KR-03, KR-04.** In a normal mode fixture start at zero. Verify the first eligible Post is free, instant and bypasses the first cooldown. Check base production at 10/10 s and 15/10 s for Lv.1/Lv.100 and the D01 yield change separately. Verify a later Post uses the approved escalating cost, build and cooldown. D05 starts with 120 Tokens and excludes all Posts.
- Cancel unfinished construction and verify an exact refund of paid Tokens. Verify built Facilities stay stationary and cannot retreat, while the build progresses only on the combat clock. A level change leaves Sonic Turret's seven-second base build unchanged.
- **Evidence.** GDD pp. 8–9 §§ G.3–4; pp. 15–17, 20, 22–24 §§ J.1–2, M.2, M.4–6; UI pp. 22, 28, 101, 118 S10/S15/S59/M02. Gates D-007, D-008 for final pricing and timing.

### KR-07 · HP, Siege, status and Heat engine

- **Depends on KR-03, KR-04.** In deterministic fixtures, ordinary melee/ranged hits cannot subtract Facility HP. A designated Siege hit can, while building and built. Confirm minimum baseline HP 100 for deployables, raw HP damage, and active named cover applied only in its scope.
- Check repair versus healing eligibility, Aerial block immunity and per-source status timers. In a Heat fixture apply Integrity loss and reset on a full gauge. Firebreak Beacon delays accumulation without removing it. Pause freezes all these effects.
- **Evidence.** GDD pp. 8–13 §§ G.2, G.4–5, H.1–3; pp. 16–17 § J.1a; p. 29 § O.2; UI pp. 28–31 S15–S18. Gate D-008 for final values.

### KR-08 · Operation planning and legal loadouts

- **Depends on KR-01, KR-02.** Present Rangers, Facilities, R&D, fixed debuffs and wave intelligence together. Return from all selectors with choices intact. Test actual available HR/Mechanical capacities and authored tutorial allowances.
- Inspect every incoming enemy, including modified values and functional tags. Enforce ownership/unlocks, distinct selections, the GDD's chapter buff limits and read-only Story debuffs. Use the authored starter allowance for the C1-01 milestone. Before enabling regular setup without a Post, test the approved D-002 validation rule.
- **Evidence.** GDD pp. 8–9, 14–15, 19, 22–24 §§ G.3, H.1, I.2–4, M.1, M.4–6; UI pp. 10, 15–19, 22 S04–S08/S10. Gate D-001 for the slice. D-002 and D-009 apply to general planning.

### KR-09 · Battle HUD and operation controls

- **Depends on KR-04, KR-05.** Show numeric Integrity, ticket Tokens, wave and defeated counts, speed and pause plus underfoot HP. Swipe across the populated tray with portrait/name preserved during cooldown. Verify pause/inspection and local Siege, Heat and placement warnings leave the arena readable.
- Verify pause can resume unchanged. Cancelling abandon returns to pause. Confirming abandonment returns to retained Story planning and pays zero.
- **Evidence.** GDD pp. 9, 15, 19, 29 §§ G.5, I.3, M.1, O.4; UI pp. 23, 30–33, 99, 112–113, 126–127 S11/S17–S20/S57/V10–V11/V15–V16.

### KR-10 · C1-01 first playable tutorial

- **Depends on KR-03–KR-09.** On a clean Android session, play First Contact on T01 with D01, two Ranger choices and the separately labeled free Starter Post. Use the GDD's 6/8 wave-count fixture. A first-time player can follow the drag and attack prompts or skip them and finish.
- Demonstrate win, loss, correct escape accounting, result and retry back to a retained plan. Record the phone, build, playtest observations and placeholder content used. Keep only explicitly sourced tutorial constraints in the acceptance baseline.
- **Evidence.** GDD pp. 6, 8–9 §§ F.2, G.1–3, H.1; pp. 22, 30–31 §§ M.4, S.1–3; UI pp. 10, 22, 34–36 S10/S21–S23.

## M2 · Tactical roster and art

### KR-11 · Ranger roster and abilities

- **Depends on KR-05, KR-07, KR-10.** Load the 12 exact names and three-per-class roster from data. Exercise placement, six role examples (blocking, ranged, healing, repair, detection and Specialist retreat) and at least one documented ability assertion per Ranger.
- Assert Guard Veteran's four charges and two forward tiles, Patrolman's permanent block-2, K9 howl's zero damage, mechanical repair eligibility, and Strike Team's escalations and lack of Records enhancement. Test Scout's targeted Focus only with the enhancement fixture.
- **Evidence.** GDD pp. 9–11 §§ H.1–1a; pp. 20, 26–27 §§ M.2, M.9; UI pp. 25–27 S12–S14. Gates D-007, D-008.

### KR-12 · Facility roster and utility effects

- **Depends on KR-06, KR-07, KR-10.** Load all 13 exact Facilities by type and apply documented HP/cost baselines in fixtures. Verify distinct cooldown relays, Medic Cabin's targeted one-kit action and the next-Specialist one-use discount. Verify each offensive turret's documented target and damage effect.
- Verify Tower occupancy and approved mount behavior, Firebreak's limited Heat slowdown, and the named status zones. Use the roster's documented unlock paths and test Siege against both construction and completed forms.
- **Evidence.** GDD pp. 15–17 §§ J.1–2; pp. 22, 25 §§ M.4, M.7; UI pp. 28–31, 66 S15–S18/S32. Gate D-008.

### KR-13 · Standard enemies and counters

- **Depends on KR-04, KR-07, KR-10.** Load the 15 source IDs E01–E15 with exact names, Danger, attack permissions and Medal Score weights. Verify Danger remains a priority category with no HP multiplier.
- Run individual tag/counter fixtures for concealment, Aerial, Technological, Heavy and Siege. E11/E12 hit eligible Facilities. E14 builds Heat and has no Siege attack. E15 escape immediately fails the operation. Exercise each enemy's documented behavior.
- **Evidence.** GDD pp. 8–9, 11–13 §§ G.2, G.4–5, H.2–2a; pp. 24–25 § M.7; UI pp. 19, 30–31 S08/S17–S18. Gates D-006, D-008.

### KR-14 · Boss encounters

- **Depends on KR-04, KR-07, KR-13.** Verify Diversion Captain in C1-05, Illegal Logging Foreman in C2-08 and Poacher Leader in C2-10. Each appears in its singular boss wave with separately scripted reinforcements, if authored.
- Test the sourced movement aura, increased Heat/temporary HP and phase/final surge behaviors with approved timing data. Test capture, stated catastrophic escape policy and pause at an intro or HP threshold. Preserve 200/300/500 Chaos points and no default Siege.
- **Evidence.** GDD pp. 6–7, 13 §§ F.2–4, H.3; pp. 22, 25, 29 §§ M.4, M.7, O.4; UI p. 8. Gate D-008. Use trigger fixtures until the KR-18 narrative integrates.

### KR-15 · Editable source asset recovery

- **Depends on KR-10.** Reconcile the 116 frame IDs against the separate candidate archive. Open the SVG sources with their referenced imagery, verify all matching PNGs, four tile sources, viewer and illustration files, and record version and rights. Record confirmed gaps separately.
- Maintain an import-ready inventory with the p. 6 56-piece geometry reference and finished textured atlas/rig dependencies. Treat the PDF pages as source references during import validation.
- Use the [W08 asset tickets](../canon/ART_ASSET_MANIFEST.md#prioritized-asset-tickets) for art intake and delivery order. Review shared templates and frame cases in the [component spec](../canon/UI_COMPONENT_SPEC.md#c09-handoff-and-acceptance).
- **Evidence.** UI pp. 1, 6–7, 10–11, 12–127; [asset register](../canon/ART_AND_UI_SPEC.md#source-assets-and-production-gaps). Gates D-003, D-014.

### KR-16 · Sprite, portrait and animation pipeline

- **Depends on KR-10, KR-15.** Verify one original Ranger cutout rig at real landscape phone size, with readable outline, separated props and HP, fixed melee facing, and appropriate Idle, Move, Attack/Heal/Repair, Skill, Hit, Deploy and Retreat/Defeat poses. Record tested dimensions, pivots, atlas settings and skeletal sampling.
- Review rig and export conventions before production coverage. Use separate portrait art and verify portrait pose swaps/dialogue animation and on-field readability for the remaining approved assets.
- **Evidence.** GDD pp. 7, 17, 29–31 §§ F.4, K, Q, S.1–3; UI pp. 2–3, 10–11, 20–21 S09/S09L. Gate D-012.

### KR-17 · Original tiles and regional routes

- **Depends on KR-03, KR-15.** Validate the six original T01–T06 masks from the visual specification. All five C1 missions share the exact T01 runtime geometry. Each C2 pair shares its assigned region template. Test both T02 entrance waypoints reach the same tunnel.
- Validate a runtime atlas against the 56 documented geometry pieces and review regional backdrops at device size. Layered scenery stays noninteractive and never hides valid cells or the route.
- **Evidence.** GDD pp. 8, 17, 21–22, 32 §§ G.2, K, M.4, T.2; UI pp. 4–6, 117–119 M01–M03. Gates D-003, D-012.

## M3 · Regional Campaign

### KR-18 · Narrative ingestion and dialogue triggers

- **Depends on KR-04, KR-14.** Supply approved external story text and triggers for the campaign, including Chapter 2 regional transitions and final C2-10 epilogue. Verify authored opening, wave/boss and victory/defeat beats through exact trigger tests.
- Continue and Skip preserve combat positions, cooldowns and wave state. The cinematic messenger never becomes a combat escape and portrayal remains consistent with the Leader/Manager roles. Start review with the [W13 source mapping and adaptation](W13_CAMPAIGN_CONTENT.md#chapter-2-source-and-adaptation).
- **Evidence.** GDD pp. 6–7, 29–30, 33 §§ F.1–4, O.2, Q, T.3; UI pp. 8, 20–24, 98, 120–121 S09/S09L/S09E/S56/M07–M08. Gate D-004.

### KR-19 · Campaign stage catalog, unlocks and settlement

- **Depends on KR-10–KR-14, KR-17, KR-18.** Validate 15 sourced stage IDs and exact names, one/two fixed debuffs per chapter, order, templates, approved wave data, recruit/unlock refs and boss placement. Verify Control visibility with tier fixtures, ordered unlocks and replay. Verify Firebreak Beacon availability before the first Heat wave in C2-07.
- Use the [15 W13 content tickets](W13_CAMPAIGN_CONTENT.md#stage-content-tickets) for per-stage criteria. Exercise a first nonperfect clear, later first perfect, then replay. First and perfect bonuses each pay once, and defeat pays zero. Reconcile provisional first-pass values and approved reward/routing data before closing. Check HQ and wallet integration when KR-21/KR-22 land.
- **Evidence.** GDD pp. 6–8, 19, 21–22, 24, 31, 33 §§ F.2–4, G.1, M.1, M.3–4, M.6, S.3, T.4; UI pp. 8, 10, 34–37, 98, 125 S21–S24/S56/M06. Gates D-006, D-009.

## M4 · Local progression

### KR-20 · Local save and recovery

- **Depends on KR-02, KR-10.** Verify versioned local progress and last-known-good backup with staged purchase, result, PR answer and collection fixtures. Close/reopen at transaction boundaries. Corrupt the primary and verify a valid backup restores the same profile without duplicating one-time rewards.
- Verify Settings-only confirmed reset erases both progress and Leader name and invalidates the old backup. Validate approved migration and neither-file-readable handling.
- **Evidence.** GDD pp. 28–29 §§ O.1, O.3–4; UI pp. 12–13, 94–97 S01–S02/S52–S55. Gate D-018.

### KR-21 · Shared Funds wallet

- **Depends on KR-20.** All confirmed source awards and costs go through one integer Funds ledger. With provisional cap fixture 9,999,999, verify 9,990,000 +54,000 credits 9,999 and permanently discards 44,001, with explicit warning and no alternate balance. Verify a full wallet, cancelled pending claim, and an insufficient purchase.
- Exercise a signed Harmful result and the approved underflow handling. Confirm failed transactions and one-time reward retries do not duplicate or partially apply changes.
- **Evidence.** GDD pp. 19, 21, 25–29 §§ M.1, M.3, M.7–10, N, O.2–4; UI pp. 68, 100 S34/S58. Gates D-005, D-016.

### KR-22 · Headquarters rooms and participation gates

- **Depends on KR-20, KR-21.** Fresh save shows only free Control, HR and Finance at Lv.1. Build/upgrade all 11 rooms instantly using the source price schedule totaling 16,160,000. Room panels expose the right activity and upgrade paths.
- Test Control fog versus prerequisite clears, HR and Mechanical throughout the five slot tiers, and Ecology Lv.5/Outreach Lv.5 both with and without Funds and their respective 60%/five-success participation. Reconcile against live Campaign, PR and Garden on integration.
- **Evidence.** GDD pp. 18–20, 26–27 §§ M.1–2, M.8, M.10; UI pp. 38–62, 109–111 S25–H11/S28/V07–V09; Mini pp. 37–38.

### KR-23 · Finance active-time storage

- **Depends on KR-20–KR-22.** Verify the stated room-level Funds/sec and room storage caps with simulated unpaused time, pause and app closure. A claim moves its earned Funds to the same wallet and reports any overflow. At the provisional Lv.2 baseline, confirm 4 Funds/sec and 25,000 storage.
- **Evidence.** GDD pp. 18–19, 21, 33 §§ M.1, M.3, T.4; UI pp. 44–45, 68, 100 H03/U03/S34/S58. Gate D-005 for held-wallet cap.

### KR-24 · Permanent Ranger and Facility progression

- **Depends on KR-11, KR-12, KR-20–KR-22.** HR and Mechanical expose the correct purchases for all 25 deployables. Validate Lv.1–100, checkpoints 20/40/60/80/100, exact 1,000,000 baseline total, and integer pricing with approved curve.
- Compare before/after stats. Upgrades modify existing raw output only, preserve geometry, charge limits and base build duration, and keep Records enhancements independent.
- **Evidence.** GDD pp. 19–20, 33 §§ M.1–2, T.4; UI pp. 63–66, 69–70, 109, 116 S29–S32/F01–F02/V07/V14; Mini p. 38. Gate D-007.

### KR-25 · R&D unlocks and buffs

- **Depends on KR-07, KR-08, KR-22.** Validate B01–B15 with source effects and penalties, room tiers across Eco/Combat/Guard/Crisis, and no potency change after unlocking. Verify distinct selection, one/two Campaign limits, and all compatible eligible unlocked buffs in Chaos.
- Verify Crisis benefit and drawback apply once together and negative-effect-triggered B08 applies one damage bonus. Reject or explain ineligible Heat and other effects.
- **Evidence.** GDD pp. 14, 19–20, 23–25 §§ I.2, M.1, M.5–7; UI pp. 18, 67, 73 S07/S33/S37. Gate D-011.

### KR-26 · Fixed debuffs and eligible Chaos modifiers

- **Depends on KR-06–KR-08, KR-13.** Verify D01–D15 source values, distinctness and points. Campaign assignments stay mandatory. Check D05 opening, D10 exempting the first free Post, D12/D15 rounding up and D14 limited to Heat operations.
- Run effect-specific fixtures for all 15 and combined eligibility/order cases. A debuff with no real effect earns no score. Resolve D05/B13, Heat, Aerial and Siege eligibility in the approved matrix.
- **Evidence.** GDD pp. 22–25 §§ M.4–7; UI pp. 9, 18, 73, 101 S07/S37/S59. Gate D-011.

## M5 · Four side activities

### KR-27 · Rainforest Chaos configuration

- **Depends on KR-08, KR-13–KR-14, KR-17, KR-25–KR-26.** Select an original route. Enforce up to five slots and 50 total enemies across types in each populated slot. Verify at 49/50 that slider and plus controls cannot add a 51st. Confirm zero counts, skip empty slots with no rest, and disable Start with all slots empty.
- Show enemy weights, buffs/debuffs, eligibility, filled loadout and live Medal Score/payout preview in the same setup. Confirm the initial loadout and configured enemies remain the source of scored quantities during battle.
- **Evidence.** GDD p. 15 § I.4; pp. 23–25 §§ M.5–7; UI pp. 9, 71–74, 114–115 S35–S38/V12–V13. Gate D-011.

### KR-28 · Chaos outcome, trophy and threshold rewards

- **Depends on KR-20–KR-21, KR-27.** Reproduce the 1,350-point/54,000 Funds worked fixture. Verify zero for nonpositive scores, exact payout jumps 999→1,000, 1,999→2,000 and 2,999→3,000, and a higher repeat victory. Verify one configured escape grants no payout, best, trophy or unlock even with positive Integrity.
- At the three thresholds verify Skill Relay Station, Specialist Calltower and Sentry Tower are one-time Chaos-only unlocks. HQ and Chaos show the same trophy. Personal best can rise past 3,000 without a fourth look.
- **Evidence.** GDD pp. 24–25, 31 §§ M.7, S.3; UI pp. 9, 71, 74–76 S35/S38–S40. Gate D-017 for a first run crossing several tiers.

### KR-29 · Reviewed educational content banks

- [W18 draft review](W18_EDUCATION_BANKS.md) has the validated banks, source register and approval status.
- Supply and review the final **20** distinct Outreach prompts, four graded answers and explanations each, and the final four-chapter Records bank with explanations and provenance. Associate facts with referenced sources and approved Restoration discoveries. Preserve the distinction between the provisional ~40 Records questions and the final count.
- Verify every content record is attributable and selectable in its correct mode. Ensure no production item is a recycled unreviewed storyboard sample. Check approved factual wording and protection of sensitive nest locations.
- **Evidence.** GDD pp. 25–27, 29–33 §§ M.8–10, P, R, S.2, T.3–4; UI pp. 10–11, 77–88, 95, 102. Gates D-004, D-014, D-016.

### KR-30 · PR Outreach timed batch

- **Depends on KR-20–KR-22, KR-29.** Test a local clock just before and at 20 hours. Refresh up to five distinct prompts from the 20-item bank, with shuffled four-option choices. Know which answers were already submitted after restart. Verify Manager feedback and all four grade/Funds results.
- Apply the approved Harmful policy and assert only Best/Acceptable responses count toward five successes for Lv.5. Reopen after changing local time and record the observed offline behavior.
- **Evidence.** GDD pp. 20, 25–26, 29, 31 §§ M.1, M.8, O.3–4, S.3; UI pp. 50, 77–84, 103–105, 110 H06/S41–P05/V01–V03/V08. Gate D-016.

### KR-31 · Records Encyclopaedia and enhancements

- **Depends on KR-11, KR-20–KR-22, KR-29.** Verify fact browsing and four chapter gates at Records Lv.2–5. Validate 15-second timer, four choices, incorrect/timeout feedback, first correct once and replay without duplicated Funds.
- Verify first perfect chapter result grants the approved once-only reward and named enhancement. Reopen to confirm the flags persist and the proper Ranger gains the documented enhancement. Strike Team gains none.
- **Evidence.** GDD pp. 19, 26–27, 31 §§ M.1, M.9, S.3; UI pp. 85–88, 102, 106–108 S43–S46/S60/V04–V06. Gate D-016.

### KR-32 · Habitat Restoration and offline growth

- **Depends on KR-20–KR-22, KR-29.** Enter the same garden from menu and Ecology. Validate four species, two-to-six plot capacity through Ecology only, and Seed/Sapling/Mature. Reopen after elapsed local time. Growth stops at the next unmet watering checkpoint, resumes when watered and never wilts.
- Collect each completed cycle once and verify retained tree scenery with a reusable plot. Verify one-time progress payouts, the 60% Ecology condition and the approved separate nest-box trigger with one visitor/fact. Growth rewards are Funds and discovered facts can be read in Records.
- **Evidence.** GDD pp. 14, 19–20, 27, 29, 31 §§ I.1, M.1, M.10, O.3–4, S.3; UI pp. 48–49, 89–93, 102, 111 H05/U05/S47–S51/S60/V09; Mini p. 39. Gate D-010.

## M6 · Android release validation

### KR-33 · Main navigation, settings and References

- **Depends on KR-19–KR-22, KR-27–KR-32.** From a fresh session and a developed save, walk the main menu, room-first navigation, Story, Chaos, garden, Settings and FAQ. Verify auto-load and first-name prompts. Settings can cancel/confirm reset and uses the KR-20 save behavior.
- Verify readable offline educational references, selected room and returning flows, and persistence of audio and display settings. Sample frames supply paths, and locked choices retain their sourced explanations.
- **Evidence.** GDD pp. 14–15, 18, 28–33 §§ I.1–4, L, O.1–3, P, R, T.3; UI pp. 7, 12–14, 38–62, 94–98 S01–S03/S25–H11/S28/S52–S56.

### KR-34 · Audio and accessibility

- **Depends on KR-09, KR-16, KR-33.** Verify master, music and SFX controls, duck/pause/transition around dialogue and visual equivalents for important cues. Apply the sourced audio directions per mode with approved tracks.
- On landscape Android screens, test larger text, safe areas/cutouts, color-plus-shape feedback, reachability, touchscreen-only navigation and skippable sequences. Test proposed 48 dp hit regions at device scale and report verified values.
- **Evidence.** GDD pp. 17–18, 28–31 §§ K–L, O.1, O.4, P, S.3; UI pp. 2–3, 32, 94 S19/S52. Gates D-012, D-013, D-014.

### KR-35 · Integrated balance and Android QA

- **Depends on KR-19–KR-34.** Run the 60-day scenario with approved rewards and compare 25.02M gross scenario earnings, 16.16M room spend and eight selected 1M deployables. Report deviations, clock edge cases, cap discard and repeatable Chaos farming. Treat pacing as a target.
- On named physical phones test 50 enemies in a populated wave with simultaneous deployables and effects, notch/ratio layout, pause/dialogue/boss resume, restart and reopen. Report measured FPS and conditions against 60 FPS target. Resolve critical failures with reproducible evidence.
- **Evidence.** GDD pp. 20–21, 28–31, 33 §§ M.2–3, O.1, O.4, S.1–3, T.4; UI pp. 2–3, 10. Gates D-005–D-008, D-013.

### KR-36 · Android distribution package

- **Depends on KR-02, KR-35.** Verify the chosen package ID, release channel requirements and signing custody. Build a signed APK with the pinned templates. Install and run it offline on the intended device matrix, with local progress surviving restart.
- Record the APK version, verified installation and device QA evidence. Include approved license and fact attribution and check that the design/content dependencies used by the package have been reviewed.
- **Evidence.** GDD pp. 4, 28–31, 33 §§ C, O.1, O.4, R, S.1–3, T.3–4; UI pp. 10–11; repository export/README.md. Gates D-013–D-015.
