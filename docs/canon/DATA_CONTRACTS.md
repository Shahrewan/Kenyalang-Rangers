# Kenyalang Rangers data contracts

**GDD** refers to *SimSimi.pdf*, Task 1 (GDD v1.0). **UI** refers to *Kenyalang_Rangers_Tileset_UI_Storyboard.pdf*. Page numbers are one-based PDF pages. The [systems index](SYSTEMS_INDEX.md) owns the source catalog rows. The [rulebook](GAME_RULES.md) owns cross-system invariants. Field names and storage layouts below are **PROVISIONAL** interface proposals, based on the GDD's Resource, manager and local-save suggestions. **FIXED** values follow the source requirements and the [approved decisions](DECISION_LOG.md#approved-decisions). **MISSING** values remain `TBD` in this documentation until sourced or approved. [GDD pp. 28–29 §§ O.1–3; UI p. 10, Handover]

## Identity, units and revisions

| Contract | Required relationship | Status and evidence |
|---|---|---|
| Source IDs | Preserve E01–E15, B01–B15, D01–D15, C1-01–C1-05 and C2-01–C2-10 exactly. Keep T01–T06 as template references. | **FIXED**. GDD pp. 11–13, 22–24 §§ H.2, M.4–6; UI pp. 4, 8 |
| Content identities | Rangers, Facilities, bosses, HQ rooms, dialogue, questions, facts and individual tree cycles need stable references for unlocks and saves. The catalog assigns a reproducible provisional key to each named unit, Facility, boss, room and activity without a PDF ID. Preserve the exact name alongside it. Approval of final serialized IDs, any duplicate-name migration, asset UIDs and serialization paths is `TBD`. H/U/F/S/M/V/P labels refer to storyboard frames. | **MISSING / PROVISIONAL**. GDD pp. 9–13 §§ H.1–3; pp. 15–20 §§ J.1, M.1–2; pp. 26–29 §§ M.9–10, O.2–3; UI pp. 7, 12–127 |
| Units | Express attacks/heals/repairs in HP per action, intervals in combat seconds at 1×, real-world PR and plant durations in local-clock hours, and room and level purchases in integer Funds. World grid uses discrete cells. Battle Tokens, Funds and Medal Score are distinct quantities. | **FIXED** semantics. GDD pp. 8–13 §§ G.3–5, H.1a, H.2a; pp. 19–21, 24–29 §§ M.1–3, M.7–10, O.2–4 |
| Versioning | Use stable references rather than display labels or row positions in saved records. Proposed separation of authored content revision, versioned save schema and runtime operation state. Exact field names, version numbers, migration map and file naming are `TBD`. | **PROVISIONAL / MISSING**. GDD pp. 28–29 §§ O.1–3; repository AGENTS.md, Coding practice |

## Combat definitions

Resource names follow the GDD architecture suggestion where available. Each row lists the fields needed to express documented behavior. Authoring can use the existing repository domain folders. [GDD pp. 28–29 § O.2; repository docs/STRUCTURE.md]

| Record / location | Fields and validation | Source |
|---|---|---|
| `RangerResource` / `data/rangers/` | Stable ID, exact name, class, ground/elevated placement, footprint, fixed-facing flag, eligible target types, block capacity, raw HP and output by level, attack cadence/range, deploy and redeploy data, ability refs, recruitment and optional Records enhancement. Four classes with three each. Barricade Ops and Strike Team validate two ground cells. Guard Veteran has one block, two forward tiles and four charges. Patrolman has two blocks at every permanent level. Scout's tap-target Focus requires Steady Aim. | GDD pp. 8–11 §§ G.2–4, H.1–1a; pp. 20, 26–27 §§ M.2, M.9; UI pp. 25–27 S12–S14 |
| `FacilityResource` / `data/facilities/` | Stable ID, exact name, category, elevated footprint, reserved cells, visual height, raw HP/output by level, Token pricing policy, fixed base build duration, cooldowns, unlock/recruitment source and eligible active, passive or claim behavior. Default 2×1 horizontal. Sentry Tower 1×1 plus the reserved cell above. Track 13 types and only one first-free policy, on Logistics Post under normal rules. | GDD pp. 8–9 §§ G.2–4; pp. 15–17 §§ J.1–2; pp. 20, 22, 24–25 §§ M.2, M.4, M.6–7; UI pp. 28–29, 66, 101 S15–S16/S32/S59 |
| `EnemyResource` / `data/enemies/` | Source ID, name, Danger 1–5, HP, movement/routing model, eligible target mask, functional tags, attack refs, status/escape rule, and exact Medal Score weight. Enemy HP is independent of Danger. Set Aerial block immunity. Key Siege permission on the **attack**, including explicit targets for E11 and E12. E15 needs an immediate-defeat escape outcome. | GDD pp. 8–9 §§ G.2, G.4; pp. 11–13 §§ H.2–2a; pp. 24–25 § M.7; p. 28 § O.2 |
| Boss definition / `data/bosses/` | Stable boss ref, name, associated operation, HP and attacks, phase and trigger refs, reinforcements, movement/Heat/temporary HP mechanisms and score weight. Use boss-specific escape/defeat or capture events. Phase thresholds, wave reinforcements and behavior timing `TBD`. Treat a special Siege attack as opt-in only. | GDD pp. 6–7 §§ F.2–4; p. 13 § H.3; pp. 22, 25 §§ M.4, M.7 |
| Attack and effect definition | Source ability, explicit damage type, targets and eligibility tags, action time, HP amount, area shape/range and facing, status type, duration, stacks, cadence, charges and triggers as applicable. Heal and repair have explicit target rules. Represent slow, reveal, mark, stun, immobilize, Knockdown and source-specific reductions. Keep K9's howl at zero HP damage. No universal Defense stat. | GDD pp. 8–13 §§ G.2–5, H.1–3; pp. 16–17 §§ J.1a, J.3 |
| Modifier definition / `data/buffs/`, `data/modifiers/` | B/D ID, exact name, scope, effect payload, signed Chaos points, distinct eligibility predicates and room unlock where applicable. Keep unconditional Story assignment distinct from eligibility in Chaos. Crisis payloads include benefit and drawback together. Use the [approved Chaos eligibility and D05/B13 rules](GAME_RULES.md#rainforest-chaos). Other numeric stacking and order remain `TBD`. | GDD pp. 14–15 §§ I.2, I.4; pp. 19–20, 22–25 §§ M.1, M.4–7; UI pp. 18, 67, 73, 101 S07/S33/S37/S59 |

**PROVISIONAL** balance values inherit the source tables in the [catalog](SYSTEMS_INDEX.md). For releases, resolve the **MISSING** attack order/tie-breaks, exact ranges, status durations/stacking, cooldown geometry, non-Logistics build times, later Post pricing, damage rounding, kit counts and unauthored stat endpoints. Preserve documented footprints, status scope and charge limits when tuning. [GDD pp. 8–13 §§ G.2–5, H.1–3; pp. 15–17, 20, 33 §§ J.1–2, M.2, T.4; UI pp. 27–29 S14–S16]

## Maps, stages and battle state

| Record | Required content and checks | Source |
|---|---|---|
| Original map template | Template ID, map geometry, typed ground/elevation/scenery cells, per-gate ordered routes, tunnel exit, backdrop ref and capability flags such as Heat. Ground route cannot traverse elevated cells. T01 shared by all Chapter 1 missions. T02 has two ingress gates and one common exit. Use [map and asset spec](ART_AND_UI_SPEC.md#original-maps-and-tile-grammar) for the visual template. Exact runtime cell and waypoint data require reconciliation against the separate design sources. | GDD pp. 8, 17, 21, 32 §§ G.2, K, M.4, T.2; UI pp. 4–6, 117–119 |
| `StageResource` / `data/stages/` | C1/C2 source ID, name, chapter, order, prior-clear requirement, Control reveal tier, template ID, fixed debuff refs, authored waves, dialogue triggers, unlock grants and reward refs. C1 one fixed debuff, C2 two. C1-01 and C2-07 have [mission-specific supply](GAME_RULES.md#story-progression) with lifetime and slot rules from D-001 and D-009. Keep these grants distinct from persistent unlocks. | GDD pp. 6–9 §§ F.2–4, G.1–3, H.1; pp. 19, 21–22, 24, 28–29 §§ M.1, M.4, M.6, O.2; UI pp. 8, 10, 22 S10 |
| Wave and ordered spawn group | Ordered group list with entity ref, count, entrance/route binding, inter-spawn interval, scripted event refs and inter-wave rest. A regular group expands to individual spawns. Preserve the printed Story counts as first-pass script totals, with scripted adds outside a singular boss wave total. Chaos has at most five slots, sum across types ≤50 per populated slot, and no spawn or rest for empty slots. | GDD p. 8 § G.1; pp. 21–22, 24–25, 28–29 §§ M.4, M.7, O.2; UI pp. 8–9, 72 S36, 114 V12 |
| Planning snapshot | Mode, operation/route, selected Ranger and Facility refs with permanent levels, distinct eligible buffs and fixed/selected debuffs, complete wave summary and separate starter provisions. Validate HR/Mechanical capacity, ownership or authored availability, and at least one legal affordable opening action. Store the resolved setup for the operation so drag/retreat never changes the effective Chaos filled-slot inputs. C1 max one buff, C2 max two. | GDD pp. 5, 9, 14–15, 19, 22–25 §§ C.2, H.1, I.2–4, M.1, M.4–7; UI pp. 10, 15–19 S04–S08, 74 S38 |
| Transient operation state | Shared combat clock with pause/dialogue and 1×/2×, Token balance, first-Post opening status, escalating later Post policy, occupancy/reservations, construction progress, cooldowns, ordered wave cursor, per-enemy outcomes, Heat if enabled and Operational Integrity starting at 100. Keep cinematic exits outside combat counters. Avoid giving a cancelled or invalid placement a persistent effect. | GDD pp. 6–9 §§ F.2–4, G.1–5; p. 17 § J.2; pp. 24, 29 §§ M.6, O.2–3; UI pp. 28, 99, 101 S15/S57/S59 |
| Operation result | Outcome, positive/zero Integrity and defeat cause, queued/defeated/escaped combat counts, Story perfect status, one-time reward eligibility, next unlocks, and Chaos score/qualifier/payout if applicable. Track first clear separately from first perfect. The cinematic messenger never increments escape count. The Story normal-clear reward and strict Chaos reward eligibility are distinct. | GDD pp. 6–8 §§ F.2, G.1; pp. 21–22, 24–25, 31 §§ M.3–4, M.7, S.3; UI pp. 34–37, 75–76 S21–S24/S39–S40 |
| Dialogue asset / `data/dialogue/` | Episode/stage ref, trigger and sequence order, speaker/portrait state, authored text, Continue/Skip and resume target. Trigger kinds include opening, selected waves, boss intro/threshold, clear and defeat. Final story prose, scene lists, boss thresholds and trigger lines `TBD`; sample UI lines are illustrative. | GDD pp. 7, 18, 29–30, 33 §§ F.3–4, L, O.2, Q, T.3; UI pp. 8, 20–24, 98, 120–121 S09/S09L/S09E/S56/M07–M08 |

Represent the normal 0-Token opening, first-free Post effect, and C1-01 Starter Post grant with its mission lifetime and no ordinary slot use. D05 has a 120-Token opening, excludes Posts and is incompatible with B13. See the [approved deployment rules](GAME_RULES.md#logistic-tokens-and-the-starter-post) and [W00b decisions D-001, D-002, D-009 and D-011](DECISION_LOG.md#approved-decisions). [GDD pp. 8–9, 19, 22–24 §§ G.3, H.1, M.1, M.4–6; UI pp. 10, 22, 39, 101 S10/S26/S59]

## Economy and progression

- **Room definition.** Store opening state, price and effect at each of Lv.1–5 plus participation requirements. Built free at Lv.1: Control, HR and Finance. The schedule totals 16,160,000 Funds. HR and Mechanical capacity and Ecology plot counts are sourced per tier in the [room catalog](SYSTEMS_INDEX.md#headquarters-rooms). Finance storage and the player's wallet are distinct Funds-bearing balances. Active-time rate and the separate room storage cap are the GDD's provisional economy figures. [GDD pp. 18–21, 33 §§ M.1–3, T.4; UI pp. 39, 62, 68 S26/S28/S34]
- **Wallet and transactions.** One integer Funds wallet takes stage, Chaos, Outreach, Records, Restoration and Finance activity results. When crediting a reward, `headroom = hard cap − current Funds`, `credited = min(incoming, headroom)` and `discarded = incoming − credited`. The fixed cap rule never grows and creates no overflow account. For manual overflow claims, preview credited and discarded amounts before confirmation. Report both amounts in the result for immediate rewards. UI's **provisional** cap fixture is 9,990,000 held + 54,000 incoming under a 9,999,999 cap, giving 9,999 credited and 44,001 discarded. The approved prototype cap is configurable. The shipping cap is `TBD`. Apply the Harmful deduction in [PR Outreach](#pr-outreach). [GDD pp. 19, 21, 25–29 §§ M.1, M.3, M.7–10, N, O.2–4; UI pp. 68, 100 S34/S58]
- **Deployable progression.** Each purchased level is an integer Lv.1–100. Fixed milestone levels are 20/40/60/80/100 and baseline cumulative cost is exactly 1,000,000. The approved cumulative price is `x = (L − 1) / 99`, `C(L) = round(1,000,000 × (0.15x + 0.85x²))`. The next level is `C(L + 1) − C(L)`. Published examples at levels 1/20/40/60/80/100 are 0/60,096/191,001/391,287/660,953/1,000,000. Every purchase retains skill behavior, geometry, charges and base build time. Interpolate linearly between reviewed endpoints and round integral outputs once, halves up. Carry fractional Post yield across 10 s payouts. Unauthored raw-stat endpoints are `TBD`. [GDD pp. 20, 33 §§ M.2, T.4; UI pp. 64, 66, 69–70, 116 S30/S32/F01–F02/V14]
- **Story rewards.** Fields for first-clear Funds, first-perfect Funds, replay Funds, unlock refs and final completion grant. Eligibility is one-time per stage for the first two even if earned on the same run. Stage reward amounts and any final completion grant are `TBD`. For the C1-04 mockup, S21 shows 50,000 first-clear plus 20,000 first-perfect for 70,000 credited. S22 shows the 50,000 eligible clear award, with one escape and 95 Integrity. These provisional examples do not set per-stage payouts or escape penalties. [GDD pp. 21–22 § M.3–4; UI pp. 10, 15, 34–35, 125 S04/S21–S22/M06]
- **Chaos settlement.** Keep personal best and first-tier award flags distinct from repeatable winnings within one qualifying-result transaction. Grant each newly crossed tier and apply one payout. Include filled slot counts, signed contribution breakdown, enemy outcomes, Integrity and trophy appearance tier in the report. Use the [exact score and payout rules](GAME_RULES.md#rainforest-chaos). At 999/1,000, qualifying gross Funds are 19,980/40,000. At 1,999/2,000 they are 79,960/130,000. At 2,999/3,000 they are 199,930/300,000. The PDF fixture is 1,350/54,000. An escape prevents related record or tier writes. [GDD pp. 24–25 § M.7; UI pp. 9, 71–76 S35–S40]
- **60-day balance scenario, provisional.** Keep this analysis separate from per-stage or per-activity award fields. Campaign 7.42M, PR 5.00M, Restoration 5.30M, Chaos 5.20M, Records 1.55M, Finance and replays 0.55M. Total 25.02M versus 16.16M HQ and 8.0M for eight maxed deployables, 24.16M planned spend. Proposed start is 10,000 Funds. [GDD pp. 18, 21, 27, 31, 33 §§ M.1, M.3, M.9–10, S.2, T.4]

## PR Outreach

- **Batch and response.** Authored content requires 20 distinct question IDs, prompt, four choices in shuffled order, grade and explanation per choice, and attribution/review metadata. Session data needs the persisted shuffled rotation, current batch IDs, question and choice order, answered flags, time of refresh and successful Best/Acceptable count toward Lv.5. Refresh at 20 elapsed local-clock hours and select up to five distinct questions. Save active session and answers after each response. Apply the approved clock-jump behavior in the [rulebook](GAME_RULES.md#outreach-records-and-habitat-restoration). [GDD pp. 25–26, 29 §§ M.8, O.3–4; UI pp. 77–84, 103–105 S41–P05/V01–V03]
- **Provisional payout schedule.** Preserve signed Funds changes and test all grades. Poor is zero. For Harmful, deduct the lesser of the configured loss and held Funds. Report the actual deduction and complete the response. Final rates remain `TBD`. [GDD pp. 26, 29, 33 §§ M.8, O.4, T.4; UI pp. 78, 80–83, 103–105 S42/P2A–P2D/V01–V03]

| Outreach Lv. | Best | Acceptable | Poor | Harmful |
|---|---:|---:|---:|---:|
| 1 | +25,000 | +12,500 | 0 | −6,250 |
| 2 | +60,000 | +30,000 | 0 | −15,000 |
| 3 | +110,000 | +55,000 | 0 | −27,500 |
| 4 | +180,000 | +90,000 | 0 | −45,000 |
| 5 | +300,000 | +150,000 | 0 | −75,000 |

## Records Encyclopaedia

- **Quiz and facts definitions.** Separate read-only article and quiz records. A quiz needs chapter, Records room level, stable question ID, prompt, four answers, correct answer, explanation and factual source attribution. Use a 15-second timer. Wrong or timeout gives explanatory feedback with no Funds. Persist first-correct flags independent of per-attempt accuracy, and separate a first perfect chapter's completion and named enhancement from question awards. Facts are freely readable with no timer or recurring Funds. [GDD pp. 19, 26–27, 30, 32–33 §§ M.1, M.9, R, T.3; UI pp. 85–88, 102, 106–108 S43–S46/S60/V04–V06]

| Records Lv. | Chapter and enhancement | Source |
|---|---|---|
| 2 | Scout Sniper, Steady Aim and Focus enhancements | GDD pp. 9, 26 §§ H.1, M.9; UI p. 26 S13 |
| 3 | Patrolman, Reinforced Patrol | GDD pp. 9, 26 §§ H.1, M.9 |
| 4 | Combat Medic, Emergency Treatment | GDD pp. 10–11, 26 §§ H.1–1a, M.9 |
| 5 | Woods Tracker, improved HP and reduced redeployment cooldown | GDD pp. 10, 26 §§ H.1, M.9 |

**PROVISIONAL** about 40 unique questions at 30,000 Funds first-correct each and four one-time chapter bonuses totaling 350,000 Funds (about 1.55M in the scenario). **MISSING** final questions, chapter split and reward authoring. Storyboard sample content and mockup counts cannot fill this bank. [GDD pp. 26–27, 33 §§ M.9, T.3–4; UI pp. 85–88 S43–S46]

## Habitat Restoration

- **Species, plot and milestone records.** Species ID and validated fact refs, base duration, visual by stage, base-duration midpoint checkpoint and cycle reward. Plot needs its Ecology capacity gate, species ref, progress through checkpoints, local timestamps, collection flag and a link to retained mature-tree scenery. Logical availability is separate from the retained visual. Persist first collected species, the additional collection flag, milestone claims, facts and the single nest-box visitor flag. Use the [approved restoration rules](GAME_RULES.md#outreach-records-and-habitat-restoration). First-species discovery reward and final payout tuning are `TBD`. [GDD pp. 14, 19–20, 27, 29 §§ I.1, M.1, M.10, O.3; UI pp. 48–49, 89–93, 111 H05/U05/S47–S51/V09]

| Tree type | GDD base duration | Provisional repeat-completion Funds |
|---|---:|---:|
| Strangler Fig | 18 hours | 3,000 |
| Belian / Bornean Ironwood | 36 hours | 8,000 |
| Red Meranti | 48 hours | 11,000 |
| Mengaris | 72 hours | 18,000 |

The values and visuals come from GDD p. 27 § M.10 and UI pp. 90–92 S48–S50. Times are in-game, with growth checked against device time and capped at the next unmet watering checkpoint. [GDD pp. 27, 30 §§ M.10, R; UI pp. 90–91 S48–S49]

| One-time milestone | Published Funds baseline | Design gate |
|---|---:|---|
| 20% | 50,000 | — |
| 40% | 150,000 | — |
| 60% | 350,000 | Ecology Lv.5 participation plus Funds cost |
| 80% | 750,000 | — |
| 100% | 1,250,000 | — |

The five milestone awards sum to 2.55M. Treat payout amounts as the published economy baseline for the prototype. D-010 triggers the separate nest-box event on the fourth distinct mature species collection. [GDD pp. 2, 20, 27 §§ A, M.1, M.10; UI p. 93 S51]

## Persistent save contract

| Area | Persisted information | Basis |
|---|---|---|
| Profile and settings | Save schema version, Leader name, settings and a last-known-good backup for the same profile. Reset is a confirmed Settings transaction discarding both progress and Leader name and invalidating the old backup. | GDD pp. 28–29 §§ O.1, O.3; UI pp. 12–13, 94–97 S01–S02/S52–S55 |
| Progress and shared economy | Wallet Funds, Finance storage, room levels, deployable levels, recruits and Facility unlocks, Story clear/perfect flags, Chaos personal best and threshold flags, and learned Records enhancements/facts. | GDD pp. 19–22, 25–29 §§ M.1–4, M.7–10, O.1–3; UI pp. 68, 71, 88, 102 S34/S35/S46/S60 |
| Timed activities | Persisted PR rotation, active batch, choice orders, answered IDs and refresh timestamp, plus plot state, local growth timestamps and collected/milestone flags. Local clock changes are an accepted limitation. | GDD pp. 25–27, 29, 31 §§ M.8–10, O.3–4, S.2; UI pp. 89–93 S47–S51 |
| Commit boundaries | Stage completion, room purchase, permanent level purchase, PR response and Restoration collection are explicit save points. Commit each award and its one-time flag together so retries, reopening and backup recovery cannot double-credit it. | GDD pp. 21, 25–29 §§ M.3, M.7–10, O.1–4; repository AGENTS.md, Coding practice |
| Recovery and migration | Restore the last-known-good backup if the active save is unreadable and a valid backup exists. If neither copy reads, show recovery and keep reset in confirmed Settings. An interrupted battle reopens in planning. Save formats and migrations remain `TBD`. | GDD pp. 28–29 §§ O.1, O.3; UI p. 96 S54 |

Example values in source screens may be used as labeled test fixtures. Any release-critical `TBD` requires an approved value or content artifact before the corresponding record is production-ready. See the [decision log](DECISION_LOG.md#open-decisions) and [backlog](../production/BACKLOG.md).
