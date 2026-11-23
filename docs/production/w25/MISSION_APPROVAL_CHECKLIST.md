# W25 · Mission approval checklist

**Pending owner and narrative review · C24 baseline `bdbb8f2`.** See the [approval plan](../W25_CAMPAIGN_COMPLETION.md), [proposals](PROPOSALS.md) and [implementation tickets](CODEX_TICKETS.md). Each checkbox records a decision or evidence to collect. The locked working structure is 15 ordered missions on the existing T01–T06 boards. Counts below repeat the GDD p. 22 first-pass totals as W25 guardrails. The ordered groups, cadence and dialogue are the loaded W13 draft.

For every Funds box, record approval of `first_clear_funds`, `first_perfect_funds` and `replay_funds`. All are `null` in RC1. C2-10 also needs `story_completion_funds`. The permanent clear grants shown below already have sourced names and locations. The review checks their availability and save receipts. The Firebreak and pending Ranger decisions are called out where they affect play.

Queues are shown in exact array order. `@A` and `@B` are T02 route indices 0 and 1. The other boards use route index 0. Boss groups start with one boss. Phase reinforcements are outside the base totals. The last wave has zero rest. Dialogue and hint labels are suffixes of the existing stage-scoped IDs. For example, `opening` on C1-01 is `dialogue.c1_01.opening`.

## C1-01 · First Contact

[`stages/c1-01.json`](../w13/stages/c1-01.json) · `T01` · Control Lv.1, available on a new profile · `D01` · **6 / 8**. GDD p. 6 §§ F.1–2 and p. 22 § M.4.

- [ ] **Narrative and triggers.** Approve the missed recall, the Manager’s emergency call and the supportive Leader response. Confirm the queue introduction and the three hints teach the Starter Post, drag and automatic attacks. Sequences `opening`, `wave_2`, `victory`, `defeat`. Hints `starter_post`, `deploy_rangers`, `basic_attacks`.
- [ ] **Wave sequencing and cadence.** Review the 10 s opening and the original E01-only fixture as the starting point for the player version. Keep the fixture-only 100/50 Funds separate. 10 s opening, 3.5 s base interval and 25 s base rest. Effective 3.5 s interval and 25 s inter-wave rest before tick rounding.
- [ ] **Funds and unlock validation.** Approve the pending Funds fields for C1-01 and test the saved result. Progression clear with no additional permanent grant. Attempt supply `ranger.scout_sniper`, `ranger.patrolman`, `stage_supply.c1_01_starter_post`.
- [ ] **Balance and outcome.** Test clean, retry and developed replay with no ordinary Post entry or slot charge. Show zero opening Tokens, a legal free instant 2×1 Post, D01 generation and both waves. Compare hints on/off. A first clear must present the next ordinary opening and truthful Funds.

| Wave | Current base groups in order |
|---:|---|
| 1 | `E01` × 6 |
| 2 | `E01` × 8 |

## C1-02 · Hold the Line

[`stages/c1-02.json`](../w13/stages/c1-02.json) · `T01` · Control Lv.1, after `C1-01` clears · `D02` · **8 / 10**. GDD p. 6 § F.2 and p. 22 § M.4.

- [ ] **Narrative and triggers.** Approve the organized incursion, blocker and elevated support prompts, and the earned Medic and Sonic Turret receipt. Sequences `opening`, `wave_2`, `victory`, `defeat`. Hints `block`, `support`, `integrity`.
- [ ] **Wave sequencing and cadence.** Verify the transition from E02 to the quicker E03 threats and test the 10 s opening using the funded ordinary Post route. 10 s opening, 3.5 s base interval and 25 s base rest. Effective 3.5 s interval and 25 s inter-wave rest before tick rounding.
- [ ] **Funds and unlock validation.** Approve the pending Funds fields for C1-02 and test the saved result. Permanent clear grants `ranger.combat_medic`, `facility.sonic_turret`.
- [ ] **Balance and outcome.** From an actual C1-01 clear, build the 20,000 Funds Mechanical room and drop a legal ordinary Post. Validate the disabled Start reason if no affordable legal action exists. Take one nonfatal escape with positive Integrity and confirm clear, no perfect and one unlock of each grant.

| Wave | Current base groups in order |
|---:|---|
| 1 | `E01` × 3 → `E02` × 2 → `E01` × 3 |
| 2 | `E01` × 3 → `E02` × 4 → `E01` × 3 |

## C1-03 · Narrow Escape

[`stages/c1-03.json`](../w13/stages/c1-03.json) · `T01` · Control Lv.1, after `C1-02` clears · `D03` · **9 / 11 / 13**. GDD p. 6 § F.2, p. 29 § O.3 and p. 22 § M.4.

- [ ] **Narrative and triggers.** Approve the wave-2 messenger and skill or hold wording. Guard Veteran is a reward of this stage. In RC1 the earlier Scout and Combat Medic active skills need Records enhancements, and the bank is gated. Review the ready-skill hint as conditional teaching on a fresh playthrough. Sequences `opening`, `messenger`, `victory`, `defeat`. Hints `skill`, `retreat`.
- [ ] **Wave sequencing and cadence.** Review Runner pressure and the Shield Carrier introduction. Verify the cinematic beat occurs at wave 2 resolution, before wave 3, independent of selecting Continue or Skip. 10 s opening, 3.5 s base interval and 25 s base rest. Effective 3.5 s interval and 25 s inter-wave rest before tick rounding.
- [ ] **Funds and unlock validation.** Approve the pending Funds fields for C1-03 and test the saved result. Permanent clear grants `ranger.guard_veteran`, `facility.medic_cabin`.
- [ ] **Balance and outcome.** Clear on the pre-clear roster. Log wave 2’s cinematic event exactly once with unchanged combat counters and Integrity. Exercise hold and redeploy on first play. Test quick skill release on a replay with an eligible skill and verify no compulsory unreachable prompt on a clean profile.

| Wave | Current base groups in order |
|---:|---|
| 1 | `E01` × 3 → `E03` × 1 → `E02` × 3 → `E03` × 2 |
| 2 | `E01` × 4 → `E02` × 3 → `E03` × 2 → `E02` × 2 |
| 3 | `E02` × 4 → `E03` × 3 → `E01` × 3 → `E02` × 3 |

## C1-04 · Watch the Ridge

[`stages/c1-04.json`](../w13/stages/c1-04.json) · `T01` · Control Lv.2, after `C1-03` clears · `D08` · **10 / 12 / 14**. GDD p. 6 § F.2, p. 19 § M.1 and p. 22 § M.4.

- [ ] **Narrative and triggers.** Approve fixed facing, healing and range teaching. Check the Woods Tracker receipt and victory line against a recruit record whose combat kit is pending. Sequences `opening`, `wave_2`, `victory`, `defeat`. Hints `facing`, `heal`, `intel`.
- [ ] **Wave sequencing and cadence.** Review the move to 2.5 s spacing, 22 s rests and the first E05 threat with D08. Compare effective E05 stats in intel with the actual attack target types. 12 s opening, 2.5 s base interval and 22 s base rest. Effective 2.5 s interval and 22 s inter-wave rest before tick rounding.
- [ ] **Funds and unlock validation.** Approve the pending Funds fields for C1-04 and test the saved result. Permanent clear grants `ranger.woods_tracker`, `facility.reinforced_cover_station`.
- [ ] **Balance and outcome.** Require both Control Lv.2 and the prior clear. Demonstrate a fixed-facing blocker, eligible Medic heal and E05 damage to an eligible Ranger. E05 cannot damage a Facility. Grant Woods Tracker and Reinforced Cover Station once.

| Wave | Current base groups in order |
|---:|---|
| 1 | `E02` × 4 → `E05` × 1 → `E04` × 1 → `E02` × 4 |
| 2 | `E02` × 3 → `E05` × 2 → `E04` × 2 → `E03` × 2 → `E02` × 3 |
| 3 | `E02` × 4 → `E04` × 2 → `E05` × 3 → `E03` × 2 → `E02` × 3 |

## C1-05 · Operation: Full Pivot

[`stages/c1-05.json`](../w13/stages/c1-05.json) · `T01` · Control Lv.2, after `C1-04` clears · `D05` · **14 / 18 / boss**. GDD pp. 6–7 § F.2, p. 13 § H.3 and pp. 22, 24 §§ M.4, M.6.

- [ ] **Narrative and triggers.** Approve the diversion reveal, Captain introduction and first phase, custody victory and Captain-specific loss copy. Match Barricade Ops handoff to the result receipt. Sequences `opening`, `wave_2`, `boss_intro`, `boss_phase_1`, `victory`, `defeat`, `defeat_captain`. Hints `stockpile`, `capture`.
- [ ] **Wave sequencing and cadence.** Keep a singular Captain at wave 3. Review the 70% trigger, two E02 adds, speed aura, pursuit window and recorded capture-specific escape consequence. 12 s opening, 2.5 s base interval and 22 s base rest. Effective 2.5 s interval and 22 s inter-wave rest before tick rounding.
- [ ] **Funds and unlock validation.** Approve the pending Funds fields for C1-05 and test the saved result. Permanent clear grants `ranger.barricade_ops`.
- [ ] **Balance and outcome.** Start on 120 Tokens with Posts and the normal free-Post prompt absent. Test capture with existing support and with queued support, fatal Captain escape at positive Integrity, and an ordinary prior escape followed by capture. Reopen and verify one Barricade Ops unlock.

| Wave | Current base groups in order |
|---:|---|
| 1 | `E01` × 4 → `E02` × 4 → `E03` × 2 → `E02` × 4 |
| 2 | `E02` × 4 → `E04` × 2 → `E05` × 2 → `E02` × 4 → `E03` × 2 → `E01` × 4 |
| 3 | `boss.diversion_captain` × 1 |

## C2-01 · Misty Approach

[`stages/c2-01.json`](../w13/stages/c2-01.json) · `T02` · Control Lv.3, after `C1-05` clears · `D06` + `D02` · **16 / 20 / 24**. GDD p. 7 §§ F.3–4 and p. 22 § M.4. Team draft pp. 1–2 via W13.

- [ ] **Narrative and triggers.** Approve the Mulu transition and shortened team-draft opening/outcomes. Check the new A/B interlude and the line promising K9 for the next operation against the pending kit. Sequences `opening`, `wave_2`, `victory`, `defeat`.
- [ ] **Wave sequencing and cadence.** Approve the exact T02 A/B split and smoke and Runner spacing under D06 and D02. Check each entrance and the shared merge with no assumption of guaranteed detection. 12 s opening, 2 s base interval and 20 s base rest. Effective 2 s interval and 20 s inter-wave rest before tick rounding.
- [ ] **Funds and unlock validation.** Approve the pending Funds fields for C2-01 and test the saved result. Permanent clear grants `ranger.k9_ranger`.
- [ ] **Balance and outcome.** Show T02 gates A and B at their real locations and a single tunnel. Clear using pre-clear detection opportunities or visibility windows. Test later K9 receipt visibility without making it a mandatory pre-clear counter.

| Wave | Current base groups in order |
|---:|---|
| 1 | `E02` × 4 @A → `E02` × 3 @B → `E06` × 2 @A → `E03` × 2 @B → `E06` × 2 @B → `E02` × 3 @A |
| 2 | `E02` × 4 @B → `E03` × 3 @A → `E06` × 3 @A → `E06` × 3 @B → `E02` × 4 @A → `E02` × 3 @B |
| 3 | `E02` × 4 @A → `E03` × 4 @B → `E06` × 3 @A → `E06` × 3 @B → `E03` × 3 @A → `E02` × 4 @B → `E06` × 3 @A |

## C2-02 · Siege on the Ridge

[`stages/c2-02.json`](../w13/stages/c2-02.json) · `T02` · Control Lv.3, after `C2-01` clears · `D09` + `D10` · **18 / 22 / 26**. GDD p. 7 §§ F.3–4, p. 17 § J.2 and p. 22 § M.4. Team draft pp. 1–2 via W13.

- [ ] **Narrative and triggers.** Approve team-draft briefing/outcomes and the new wave-2 Siege warning. Keep Outpost Mechanic and the Coordination Hub as earned grants. Sequences `opening`, `wave_2`, `victory`, `defeat`.
- [ ] **Wave sequencing and cadence.** Review exact Demolitionist entry lanes, D09 Siege pressure and D10 build delay. Verify the ordinary opening Post remains free and instant. 12 s opening, 2 s base interval and 20 s base rest. Effective 2 s interval and 20 s inter-wave rest before tick rounding.
- [ ] **Funds and unlock validation.** Approve the pending Funds fields for C2-02 and test the saved result. Permanent clear grants `ranger.outpost_mechanic`, `facility.ranger_coordination_hub`.
- [ ] **Balance and outcome.** Without the rewards owned, place a paid build and observe a named Siege hit on construction. Show standard attacks cannot harm it. Clear and confirm Mechanic repair and the Coordination Hub are available only after the grant.

| Wave | Current base groups in order |
|---:|---|
| 1 | `E02` × 4 @A → `E02` × 3 @B → `E11` × 1 @A → `E03` × 3 @B → `E06` × 2 @B → `E04` × 2 @A → `E02` × 3 @B |
| 2 | `E02` × 4 @B → `E06` × 3 @A → `E11` × 2 @B → `E02` × 4 @A → `E04` × 3 @B → `E11` × 1 @A → `E03` × 3 @B → `E02` × 2 @A |
| 3 | `E02` × 4 @A → `E03` × 4 @B → `E11` × 2 @A → `E06` × 3 @B → `E04` × 3 @A → `E11` × 2 @B → `E03` × 3 @A → `E02` × 5 @B |

## C2-03 · Aerial Crossing

[`stages/c2-03.json`](../w13/stages/c2-03.json) · `T03` · Control Lv.3, after `C2-02` clears · `D11` + `D07` · **20 / 24 / 28**. GDD pp. 7–8 §§ F.3–4, G.2 and pp. 22, 24 §§ M.4, M.6. Team draft pp. 2–4 via W13.

- [ ] **Narrative and triggers.** Approve the Batang Ai transition, crossing briefing/outcomes and new wave-2 Drone beat. Annotate the Seer line with the actual unlock or field readiness. Sequences `opening`, `wave_2`, `victory`, `defeat`.
- [ ] **Wave sequencing and cadence.** Review the first E08 timing, faster D11 air movement and shortened effective 12 s rest. Verify the tutorial permits eligible ranged fire before the anti-air Facility reward. 12 s opening, 2 s base interval and 20 s base rest. Effective 2 s interval and 12 s inter-wave rest before tick rounding.
- [ ] **Funds and unlock validation.** Approve the pending Funds fields for C2-03 and test the saved result. Permanent clear grants `ranger.kenyalang_seer`, `facility.canopy_defense_launcher`.
- [ ] **Balance and outcome.** Use a pre-clear ranged loadout and show drones crossing a ground block. Finish without the Seer or Launcher supplied and confirm both clear grants once. Measure breathing room under the effective rest.

| Wave | Current base groups in order |
|---:|---|
| 1 | `E02` × 5 → `E08` × 2 → `E03` × 3 → `E08` × 3 → `E02` × 4 → `E04` × 3 |
| 2 | `E02` × 4 → `E08` × 4 → `E04` × 3 → `E03` × 4 → `E08` × 4 → `E02` × 5 |
| 3 | `E02` × 5 → `E08` × 5 → `E03` × 4 → `E04` × 4 → `E08` × 4 → `E02` × 6 |

## C2-04 · Jammed Communications

[`stages/c2-04.json`](../w13/stages/c2-04.json) · `T03` · Control Lv.3, after `C2-03` clears · `D04` + `D13` · **20 / 25 / 30**. GDD p. 7 §§ F.3–4 and pp. 22, 24 §§ M.4, M.6. Team draft pp. 2–4 via W13.

- [ ] **Narrative and triggers.** Approve the team-draft interference briefing/outcomes and new wave-2 cue for remaining basic attack coverage. Sequences `opening`, `wave_2`, `victory`, `defeat`.
- [ ] **Wave sequencing and cadence.** Review Jammer positioning and the 2 s base interval scaled to 1.6 s once. Distinguish temporary jammer effects from the fixed D04 duration effect. 12 s opening, 2 s base interval and 20 s base rest. Effective 1.6 s interval and 20 s inter-wave rest before tick rounding.
- [ ] **Funds and unlock validation.** Approve the pending Funds fields for C2-04 and test the saved result. Permanent clear grants `ranger.crowd_controller`, `facility.electric_pulse_turret`.
- [ ] **Balance and outcome.** Play without the Crowd Controller and Electric Pulse Turret grants. Confirm individual queue timing, cooldown expiry during and after jammer effects, ordinary clear and one grant for each.

| Wave | Current base groups in order |
|---:|---|
| 1 | `E02` × 4 → `E08` × 3 → `E07` × 1 → `E02` × 4 → `E04` × 2 → `E07` × 2 → `E08` × 4 |
| 2 | `E02` × 5 → `E07` × 2 → `E08` × 4 → `E03` × 4 → `E04` × 3 → `E07` × 2 → `E08` × 5 |
| 3 | `E02` × 5 → `E08` × 5 → `E07` × 2 → `E03` × 5 → `E08` × 4 → `E07` × 3 → `E04` × 3 → `E02` × 3 |

## C2-05 · Automated Pursuit

[`stages/c2-05.json`](../w13/stages/c2-05.json) · `T04` · Control Lv.4, after `C2-04` clears · `D08` + `D12` · **22 / 26 / 30 / 32**. GDD p. 7 §§ F.3–4 and pp. 22, 24 §§ M.4, M.6. Team draft pp. 4–5 via W13.

- [ ] **Narrative and triggers.** Approve the Tanjung Datu transition and automation briefing/outcomes. Review the new wave-2 notice and the Saboteurist availability claim while its combat kit remains pending. Sequences `opening`, `wave_2`, `victory`, `defeat`.
- [ ] **Wave sequencing and cadence.** Review the first 1.5 s interval/18 s rest stage, D08 enemy HP and rounded-up D12 Ranger cost. Check Tracking Bot cadence and visibility against the current pressure. 15 s opening, 1.5 s base interval and 18 s base rest. Effective 1.5 s interval and 18 s inter-wave rest before tick rounding.
- [ ] **Funds and unlock validation.** Approve the pending Funds fields for C2-05 and test the saved result. Permanent clear grants `ranger.saboteurist`, `facility.disruption_beacon`.
- [ ] **Balance and outcome.** Verify the Control Lv.4 gate and actual effective costs with the pre-clear roster. Exercise temporary attack-rate interference and recovery. Confirm legal opening and one Saboteurist and Disruption Beacon grant.

| Wave | Current base groups in order |
|---:|---|
| 1 | `E02` × 5 → `E09` × 2 → `E03` × 4 → `E04` × 3 → `E09` × 3 → `E02` × 5 |
| 2 | `E02` × 5 → `E09` × 3 → `E03` × 4 → `E07` × 2 → `E04` × 3 → `E09` × 4 → `E02` × 5 |
| 3 | `E02` × 6 → `E09` × 4 → `E08` × 3 → `E03` × 5 → `E07` × 2 → `E09` × 4 → `E04` × 3 → `E02` × 3 |
| 4 | `E02` × 5 → `E09` × 5 → `E03` × 5 → `E07` × 3 → `E08` × 4 → `E09` × 4 → `E04` × 4 → `E02` × 2 |

## C2-06 · Capture Operations

[`stages/c2-06.json`](../w13/stages/c2-06.json) · `T04` · Control Lv.4, after `C2-05` clears · `D03` + `D04` · **24 / 30 / 35**. GDD p. 7 §§ F.3–4 and pp. 22, 24 §§ M.4, M.6. Team draft pp. 4–5 via W13.

- [ ] **Narrative and triggers.** Approve team-draft capture-equipment beats and the wave-2 warning. Review the Strike Team line against a pending field kit and the distinct Dispatch Relay grant. Sequences `opening`, `wave_2`, `victory`, `defeat`.
- [ ] **Wave sequencing and cadence.** Review the E10 ordered groups, D03 Ranger health and D04 recharge pressure. Confirm the telegraph allows useful counterplay with pre-clear gear. 15 s opening, 1.5 s base interval and 18 s base rest. Effective 1.5 s interval and 18 s inter-wave rest before tick rounding.
- [ ] **Funds and unlock validation.** Approve the pending Funds fields for C2-06 and test the saved result. Permanent clear grants `ranger.strike_team`, `facility.dispatch_relay`.
- [ ] **Balance and outcome.** Trigger entangle, hold a block and allow retreat during the effect. Clear with the pre-clear loadout and verify the two earned grants are committed once. Confirm C2-07 is reachable from the saved result.

| Wave | Current base groups in order |
|---:|---|
| 1 | `E02` × 5 → `E10` × 2 → `E03` × 4 → `E04` × 3 → `E09` × 3 → `E10` × 2 → `E02` × 5 |
| 2 | `E02` × 5 → `E10` × 3 → `E09` × 4 → `E03` × 5 → `E04` × 4 → `E10` × 4 → `E02` × 5 |
| 3 | `E02` × 6 → `E10` × 4 → `E09` × 4 → `E03` × 5 → `E04` × 4 → `E10` × 5 → `E07` × 2 → `E02` × 5 |

## C2-07 · Heat in the Gorge

[`stages/c2-07.json`](../w13/stages/c2-07.json) · `T05` · Control Lv.4, after `C2-06` clears · `D14` + `D06` · **25 / 30 / 35 / 38**. GDD pp. 7, 9, 16 and 22 §§ F.3–4, G.5, J.1, M.4 and D-009. Team draft pp. 5–6 via W13.

- [ ] **Narrative and triggers.** Approve the Imbak Canyon transition, Heat instructions, wave-2 cue and `hint.c2_07.heat`. The supply description should match the ownership decision used by C2-08. Sequences `opening`, `wave_2`, `victory`, `defeat`. Hints `heat`.
- [ ] **Wave sequencing and cadence.** Review the 20 s opening, 20 base arrivals before first E14, the 30-Token/six-second Beacon trial and the shared T05 Heat numbers. Approve the time available using an ordinary Post and legal footprints. 20 s opening, 1.5 s base interval and 18 s base rest. Effective 1.5 s interval and 18 s inter-wave rest before tick rounding.
- [ ] **Funds and unlock validation.** Approve the pending Funds fields for C2-07 and test the saved result. Progression clear with no additional permanent grant. Attempt supply `stage_supply.c2_07_firebreak_beacon`. Permanent Firebreak acquisition requires a separate decision.
- [ ] **Balance and outcome.** Show one mission Beacon outside the Facility slots and a legal ordinary opening. Collect Tokens and finish the build before the first E14, then verify a diminished Heat tick. Force a Heat reset with positive Integrity and zero escapes to test perfect. Replay and abandon exercise the supply lifetime.

| Wave | Current base groups in order |
|---:|---|
| 1 | `E02` × 6 → `E06` × 2 → `E03` × 4 → `E02` × 8 → `E14` × 1 → `E02` × 1 → `E04` × 3 |
| 2 | `E02` × 6 → `E06` × 4 → `E14` × 1 → `E03` × 5 → `E04` × 4 → `E02` × 4 → `E14` × 1 → `E02` × 5 |
| 3 | `E02` × 6 → `E06` × 5 → `E14` × 1 → `E03` × 5 → `E04` × 4 → `E02` × 4 → `E14` × 1 → `E09` × 3 → `E02` × 6 |
| 4 | `E02` × 6 → `E06` × 5 → `E14` × 1 → `E03` × 6 → `E04` × 3 → `E02` × 5 → `E14` × 1 → `E09` × 3 → `E14` × 1 → `E02` × 7 |

## C2-08 · Breaking the Line

[`stages/c2-08.json`](../w13/stages/c2-08.json) · `T05` · Control Lv.4, after `C2-07` clears · `D14` + `D08` · **30 / 33 / 38 / boss**. GDD pp. 7, 9, 13 and 22 §§ F.3–4, G.5, H.3, M.4. Team draft pp. 5–6 via W13.

- [ ] **Narrative and triggers.** Approve the Foreman confrontation moved to arrival, new wave-3 and shield beats, and separate stopped, escaped-clear and defeat copy. The escaped-clear text depends on the owner’s Foreman outcome ruling. Sequences `opening`, `wave_3`, `boss_intro`, `boss_phase_1`, `victory`, `victory_foreman_escaped`, `defeat`.
- [ ] **Wave sequencing and cadence.** Review no automatic C2-07 supply, the T05 Heat model, 65% phase and D08 effective max HP. Confirm the B02/Beacon counterplay assumptions and nonfatal escape trial. 15 s opening, 1.5 s base interval and 18 s base rest. Effective 1.5 s interval and 18 s inter-wave rest before tick rounding.
- [ ] **Funds and unlock validation.** Approve the pending Funds fields for C2-08 and test the saved result. Progression clear with no additional permanent grant.
- [ ] **Balance and outcome.** Test the approved ownership branch on a returning save, then a genuine clear on the guardrail loadout. Test shield expiry on the shared clock, boss stopped, escape with positive Integrity and escape at zero after the penalty. Verify dialogue and grant routing for the selected outcome.

| Wave | Current base groups in order |
|---:|---|
| 1 | `E02` × 6 → `E06` × 4 → `E14` × 1 → `E03` × 5 → `E04` × 4 → `E02` × 4 → `E14` × 1 → `E02` × 5 |
| 2 | `E02` × 6 → `E04` × 4 → `E14` × 1 → `E03` × 5 → `E09` × 4 → `E02` × 5 → `E14` × 1 → `E02` × 7 |
| 3 | `E02` × 6 → `E04` × 4 → `E14` × 1 → `E03` × 6 → `E09` × 4 → `E02` × 5 → `E14` × 1 → `E06` × 4 → `E02` × 7 |
| 4 | `boss.illegal_logging_foreman` × 1 |

## C2-09 · Desperate Convoy

[`stages/c2-09.json`](../w13/stages/c2-09.json) · `T06` · Control Lv.5, after `C2-08` clears · `D09` + `D15` · **28 / 32 / 36 / 42**. GDD pp. 7, 12–13 and 22 §§ F.3–4, H.2–2a, M.4. Team draft pp. 6–7 via W13.

- [ ] **Narrative and triggers.** Approve the Sepilok-Kabili transition, convoy briefing/outcomes, wave-3 danger cue and E15-specific defeat copy. Sequences `opening`, `wave_3`, `victory`, `defeat`, `defeat_trafficker`.
- [ ] **Wave sequencing and cadence.** Review the first late cadence at 1.1 s and 15 s, Mortar and Breacher ordering, E15 priority, D09 Siege and D15 ordinary escape rounding. 15 s opening, 1.1 s base interval and 15 s base rest. Effective 1.1 s interval and 15 s inter-wave rest before tick rounding.
- [ ] **Funds and unlock validation.** Approve the pending Funds fields for C2-09 and test the saved result. Progression clear with no additional permanent grant.
- [ ] **Balance and outcome.** Require Control Lv.5 and the C2-08 clear. Stop a convoy with pre-clear gear. Exercise separable Mortar/Breacher cues and force an E15 escape at positive Integrity for immediate defeat, correct report and zero unlocks or Funds.

| Wave | Current base groups in order |
|---:|---|
| 1 | `E02` × 6 → `E12` × 1 → `E03` × 5 → `E04` × 4 → `E13` × 1 → `E02` × 5 → `E05` × 3 → `E02` × 3 |
| 2 | `E02` × 6 → `E12` × 1 → `E04` × 4 → `E03` × 6 → `E13` × 2 → `E05` × 4 → `E12` × 1 → `E02` × 8 |
| 3 | `E02` × 6 → `E12` × 1 → `E03` × 5 → `E13` × 2 → `E04` × 4 → `E05` × 4 → `E15` × 1 → `E02` × 6 → `E12` × 1 → `E02` × 6 |
| 4 | `E02` × 7 → `E12` × 1 → `E03` × 6 → `E13` × 2 → `E04` × 5 → `E05` × 4 → `E15` × 1 → `E02` × 6 → `E12` × 2 → `E13` × 1 → `E02` × 7 |

## C2-10 · Final Interception

[`stages/c2-10.json`](../w13/stages/c2-10.json) · `T06` · Control Lv.5, after `C2-09` clears · `D13` + `D15` · **25 / 30 / 36 / 45 / boss**. GDD pp. 7, 13 and 22 §§ F.3–4, H.3, M.4. Team draft pp. 6–7 via W13.

- [ ] **Narrative and triggers.** Approve the last transition through the selected wave, Leader arrival, both phases, custody dialogue, separate E15/Leader losses and first-clear-only epilogue. Approve `fact.hornbill_tree_cavity` for this exact use. Sequences `opening`, `wave_4`, `boss_intro`, `boss_phase_1`, `boss_phase_2`, `victory`, `defeat`, `defeat_trafficker`, `defeat_leader`, `epilogue`.
- [ ] **Wave sequencing and cadence.** Review D13 effective 0.88 s interval before tick rounding, final-wave singular boss, 70% and 35% thresholds, mandatory spawned or scheduled Runners and final speed surge. 15 s opening, 1.1 s base interval and 15 s base rest. Effective 0.88 s interval and 15 s inter-wave rest before tick rounding.
- [ ] **Funds and unlock validation.** Approve the pending Funds fields for C2-10 and test the saved result. Progression clear with no additional permanent grant. The separate first completion field is also pending.
- [ ] **Balance and outcome.** Exercise both thresholds, stop the Leader and keep the result pending until queued Runners resolve. Force each fatal escape independently. Verify first completion award and epilogue once, first perfect earned later if appropriate, replay credit and v2 reopen continuity.

| Wave | Current base groups in order |
|---:|---|
| 1 | `E02` × 5 → `E03` × 5 → `E04` × 3 → `E08` × 4 → `E07` × 2 → `E02` × 6 |
| 2 | `E02` × 6 → `E09` × 4 → `E03` × 5 → `E10` × 3 → `E05` × 4 → `E13` × 1 → `E04` × 3 → `E02` × 4 |
| 3 | `E02` × 6 → `E12` × 1 → `E04` × 4 → `E03` × 6 → `E08` × 4 → `E07` × 3 → `E13` × 2 → `E05` × 4 → `E02` × 6 |
| 4 | `E02` × 7 → `E03` × 6 → `E13` × 2 → `E12` × 1 → `E09` × 5 → `E10` × 4 → `E04` × 5 → `E08` × 4 → `E15` × 1 → `E02` × 9 → `E05` × 1 |
| 5 | `boss.poacher_leader` × 1 |
