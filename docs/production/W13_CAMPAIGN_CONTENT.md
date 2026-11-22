# W13 Campaign content handoff

**22 November 2026 · C14 review draft**

The campaign manifest indexes 15 JSON stage specs. Each defines waves, ordered spawn groups, route bindings, intel, loss conditions, reward fields, full dialogue and art requirements. C14 loads these files for the Campaign playtest. The authored draft, trial numbers and payout review statuses still apply. [Campaign manifest](w13/campaign.json) · [C14 checks](../qa/C14_CAMPAIGN_MATRIX.md)

The [approved decisions](../canon/DECISION_LOG.md#approved-decisions) take precedence over GDD v1.0 in `SimSimi.pdf`. GDD pp. 6–8 §§ F.1–4, G.1–3 and pp. 21–22 § M.4 establish the missions and outcomes. The UI storyboard p. 8 confirms the order, pp. 20–24 and 120–121 show dialogue, and pp. 117–125 plus the five-page design-pack mini-storyboard show the Misty Approach play sequence. W08 specifies the six original layouts. [Campaign catalog](../canon/SYSTEMS_INDEX.md#campaign-missions) · [Map geometry](../canon/ART_ASSET_MANIFEST.md#six-map-geometry-layouts) · [UI components](../canon/UI_COMPONENT_SPEC.md)

## Review status

| Status | Meaning in this handoff |
|---|---|
| **Fixed** | Exact IDs, titles, mission order, map assignment, Control visibility, Story debuffs, sourced unlocks and mission supplies, and the three final-wave boss positions. |
| **Published first pass** | Wave totals from GDD p. 22 § M.4. Preserve the counts in this draft. A boss wave starts with one boss. The phase resource can queue additional enemies outside that published count. |
| **Proposed playtest** | Ordered groups from C1-02 onward, their route assignments, cadence grouping by stage, opening delays beyond C1-01, and the campaign Heat values. C1-01 carries the existing trial. Base enemy stats and boss phase numbers reference the C12 trials. |
| **Proposed dialogue** | Full review copy for all 15 stages. C1 copy follows GDD F.1–2. C2 briefing and outcomes adapt the team's recovered draft. Newly authored wave, phase, exception and epilogue copy is marked by sequence. |
| **TBD** | Final per-stage first-clear, first-perfect and replay amounts, finale completion amount, final playtest tuning, and review of persistent ownership and exceptional boss outcomes where the sources leave details open. JSON uses `null` for unresolved payout amounts. |

### Chapter 2 source and adaptation

Located and read all seven pages of the team-authored `dialog&story(test).docx`, dated 19 November 2026. It supplies five regional transitions and a briefing, victory and defeat for each of ten Chapter 2 missions. The playtest copy preserves those beats in shorter lines and uses the current rules for concealment, Siege, Aerial, Heat and fatal escapes. On the first operation of each region, the transition is part of the opening sequence. Foreman and Poacher Leader confrontations move to the actual boss arrival. Selected wave beats, phase notices, cause-specific outcomes and the ending field note are W13 additions for review. The source stays with the narrative team. [GDD p. 7 §§ F.3–4, p. 33 § T.3] · [Source inventory](SOURCE_INVENTORY.md)

| Team draft section | Pages | W13 coverage |
|---|---:|---|
| Regional Transition Beats | 1 | C2-01, C2-03, C2-05, C2-07 and C2-09 opening prefixes |
| Gunung Mulu | 1–2 | C2-01 / C2-02 briefings and outcomes |
| Batang Ai | 2–4 | C2-03 / C2-04 briefings and outcomes |
| Tanjung Datu | 4–5 | C2-05 / C2-06 briefings and outcomes |
| Imbak Canyon | 5–6 | C2-07 / C2-08 briefings, outcomes and Foreman confrontation |
| Sepilok-Kabili | 6–7 | C2-09 / C2-10 briefings, outcomes and Poacher Leader confrontation |

## Stage content tickets

Each row is one C14 content ticket. Its JSON provides the exact input and its acceptance column defines a stage-specific check in addition to the shared checks below. Map and wave sources are GDD pp. 6–8, 13, 19, 21–22 §§ F, G.1–2, H.3, M.1, M.4 and UI pp. 4–5, 8. All five C1 operations share one T01 geometry. Each Chapter 2 pair shares one map.

| Ticket and resource | Template | Published waves | Fixed debuffs | Sourced grant on clear or in mission | Stage acceptance |
|---|---|---|---|---|---|
| [W13-C1-01 · First Contact](w13/stages/c1-01.json) | T01 | 6 / 8 | D01 | Scout Sniper, Patrolman and Starter Post supplied at start | On a clean and replay profile show one Post outside Mechanical capacity, 0 Tokens and a legal free 2×1 drop. Run both E01 waves with and without hints. |
| [W13-C1-02 · Hold the Line](w13/stages/c1-02.json) | T01 | 8 / 10 | D02 | Combat Medic, Sonic Turret | From cleared C1-01, demonstrate a funded Mechanical build and valid ordinary opening. Verify blocking, elevated fire and an ordinary escape reducing Integrity. |
| [W13-C1-03 · Narrow Escape](w13/stages/c1-03.json) | T01 | 9 / 11 / 13 | D03 | Guard Veteran, Medic Cabin | Trigger the messenger after wave 2. Both Continue and Skip leave combat counters unchanged. Cover skill release versus hold and cooldown. |
| [W13-C1-04 · Watch the Ridge](w13/stages/c1-04.json) | T01 | 10 / 12 / 14 | D08 | Woods Tracker, Reinforced Cover Station | Show the locked facing and eligible Medic healing. Inspect an E05 with D08 applied. Its ranged attack cannot deal Facility damage. |
| [W13-C1-05 · Operation: Full Pivot](w13/stages/c1-05.json) | T01 | 14 / 18 / boss | D05 | Barricade Ops | Use 120 Tokens, zero Posts and no first-free tutorial. Resolve singular Captain capture as a win on positive Integrity. Test Captain escape and capture with live or queued support. |
| [W13-C2-01 · Misty Approach](w13/stages/c2-01.json) | T02 | 16 / 20 / 24 | D06 + D02 | K9 Ranger | Trace A and B to one tunnel, exercise visibility windows, and show no pre-clear dependency on K9. Check the M07/M08-style interlude. |
| [W13-C2-02 · Siege on the Ridge](w13/stages/c2-02.json) | T02 | 18 / 22 / 26 | D09 + D10 | Outpost Mechanic, Ranger Coordination Hub | Show a delayed paid construction, first Post exception, and a named Siege strike on a pending build. Clear with a roster available before the reward. |
| [W13-C2-03 · Aerial Crossing](w13/stages/c2-03.json) | T03 | 20 / 24 / 28 | D11 + D07 | Kenyalang Seer, Canopy Defense Launcher | E08 crosses ground blocks and responds to eligible ranged fire. Verify D11 movement and the shorter rest with pre-clear equipment. |
| [W13-C2-04 · Jammed Communications](w13/stages/c2-04.json) | T03 | 20 / 25 / 30 | D04 + D13 | Crowd Controller, Electric Pulse Turret | Show tightened individual spawn gaps and distinguish D04 cooldown scaling from a Signal Jammer's temporary effect. |
| [W13-C2-05 · Automated Pursuit](w13/stages/c2-05.json) | T04 | 22 / 26 / 30 / 32 | D08 + D12 | Saboteurist, Disruption Beacon | Inspect modified HP and the rounded-up Ranger price, then exercise Tracking Bot attack-rate loss and recovery. |
| [W13-C2-06 · Capture Operations](w13/stages/c2-06.json) | T04 | 24 / 30 / 35 | D03 + D04 | Strike Team, Dispatch Relay | Reproduce the Net Trapper's entangle and allow retreat through it. Verify the stage's normal clear and its separate Ranger and Facility unlocks. |
| [W13-C2-07 · Heat in the Gorge](w13/stages/c2-07.json) | T05 | 25 / 30 / 35 / 38 | D14 + D06 | One Firebreak Beacon supplied for the attempt | Show the Beacon in planning outside regular slots. Deploy at normal cost, check time to first E14, and verify Heat can still damage Integrity and reset with zero combat escapes. |
| [W13-C2-08 · Breaking the Line](w13/stages/c2-08.json) | T05 | 30 / 33 / 38 / boss | D14 + D08 | Foreman encounter | Start with no C2-07 supply. Check the Foreman's Heat and temporary HP. Verify that any allowed escape takes the correct outcome branch once its Story consequence is reviewed. |
| [W13-C2-09 · Desperate Convoy](w13/stages/c2-09.json) | T06 | 28 / 32 / 36 / 42 | D09 + D15 | Progression only | Resolve Mortar and Breacher warnings independently. Force one Wildlife Trafficker through at positive Integrity and verify immediate defeat with the specific report. |
| [W13-C2-10 · Final Interception](w13/stages/c2-10.json) | T06 | 25 / 30 / 36 / 45 / boss | D13 + D15 | Finale completion reward, amount TBD | Resolve the singular boss and queued Runners before victory. Verify the two phase notices, the final surge, fatal boss escape, and first completion plus replay. |

## Resource and trigger contract

| Field or event | Binding for C14 |
|---|---|
| `operation` | Build an ordered Story index by exact ID. A node needs its Control visibility tier and prior clear. Clear unlock IDs are persistent. Supply IDs have attempt scope. Use the mode's actual roster and eligible buff limits. A new stage starts at 100 Integrity. Apply the [approved opening validator](../canon/GAME_RULES.md#logistic-tokens-and-the-starter-post). |
| `waves[].groups[]` | Load standard/dedicated boss enemy definitions by ID and bind `route_index` into W08's ordered routes. T02 A=0 and B=1. Spawn one enemy at a time in array order. The interval after a group's final spawn schedules the next group too. Retain a wave until all scheduled spawns, live enemies and required phase arrivals resolve. Apply rest after resolution and before the next populated wave. |
| Cadence and effects | Use base group intervals and rests in the stage resource. Apply D13 to intervals and D07 to rests once. QA expected fields show the result before rounding to combat ticks. Use D12/D15's approved rounding where applicable and load the other debuff effects by ID. C2-07 and C2-08 alone have Heat. [GDD pp. 21–24 §§ M.4, M.6] · [C12 trials](../canon/DECISION_LOG.md#d-006-and-d-008-c12-enemy-and-boss-tuning--2026-11-22) |
| `enemy_intel` and `boss` | Bind exact roster names, tag, Danger, baseline/effective HP and counterplay from the catalogue. The JSON counts represent base queued enemies; show later phase support as a separate warning. Read boss rules, phase order, thresholds and add delays from the C12 resource. Danger is an independent priority category. [GDD pp. 11–13 §§ H.2–3] |
| `operation_opening` | Open the skippable briefing after an accepted plan and before the first combat tick. The first spawn is due after the stage delay. Skipping optional tutorial hints leaves supplies, validation, wave and Token state intact. |
| `before_wave_first_spawn` and `wave_resolved` | Fire a selected notice once at the scheduled first-spawn boundary after rest, before that wave's first spawn. Resume the same due spawn. Fire the messenger event once after C1-03 wave 2 fully resolves, before wave 3. Record the story event whether the player reads or skips it. It never enters the combat registry and changes no queued, defeated or escaped count or Integrity. |
| `boss_intro` and `boss_phase_changed` | Retain the C12 boss event and 1-based order of phases. Use the authored dialogue for the event in place of the sandbox announcement so each event opens one hold. Preserve pending arrivals and a later threshold when one hit crosses two. |
| `victory`, `defeat` and `after_victory_dialogue` | Settle combat once, keep a result snapshot, and choose a matching cause-specific sequence before its fallback. Carry the exact fatal escape ID or boss resolution on the snapshot. Continue and Skip leave the same report and payout state. The draft epilogue follows the first C2-10 victory and links to the normal result, Story, HQ and Chaos. Ordinary replay remains available. |
| Presentation | One speaker overlay with Continue and Skip, separate portrait/pose keys, wrapped text and readable fallback. Keep the combat clock held through the last line. Freezing covers movements, HP-related effects, waves, cooldowns, Heat, construction and reinforcement timers. No timer or camera change depends on reading a line. [GDD pp. 7, 9, 29–30 §§ F.4, G.5, O.2, Q] · [Storyboard dialogue](../canon/UI_COMPONENT_SPEC.md#entry-story-and-combat) |
| `outcome` and `rewards` | Ordinary clear requires resolved waves and positive Integrity. Perfect adds zero combat escapes. Heat-only Integrity loss can coexist with perfect. The Captain capture ends C1-05 and retires support without adding phantom defeats or escapes. E15 and the Poacher Leader have fatal escape outcomes. All real escapes count once. Apply first-clear, first-perfect and applicable replay Funds and unlocks through one profile transaction. A defeat or abandon pays zero. C1-01's 100/50 Funds are the existing isolated C05 trial only. [GDD pp. 7–8, 13, 21–22, 29 §§ G.1, H.2–3, M.3–4, O.3] · [D-005, D-006, D-018](../canon/DECISION_LOG.md#approved-decisions) |

### Timing and boss references

| W13 trial profile | Operations | Base spacing / rest in combat seconds |
|---|---|---:|
| Early C1 | C1-01–03 | 3.5 / 25 |
| Late C1 | C1-04–05 | 2.5 / 22 |
| Early C2 | C2-01–04 | 2.0 / 20 |
| Mid C2 | C2-05–08 | 1.5 / 18 |
| Late C2 | C2-09–10 | 1.1 / 15 |

C2-03 uses 12 s effective rest. C2-04 spaces enemies 1.6 s apart. C2-10 uses 0.88 s before tick rounding. The last populated wave has zero rest. Assigning these cadence bands to individual missions is a W13 proposal using the GDD p. 21 baselines. C2-07 has a 20-second opening and 20 planned enemies before the first E14. At base cadence that E14 is due at about 50 combat seconds. The regular Post can fund the 30-Token, six-second trial Beacon if placed early. Confirm the actual placement window on a named device. Both Heat stages use a proposed 100-capacity gauge and 10 Integrity loss per reset for Campaign tests. C12 sandbox tuning has its own scope.

| Boss and final wave | Current C12 phase trial | Settlement to test |
|---|---|---|
| [Diversion Captain](../../data/bosses/diversion_captain.tres) · C1-05 wave 3 | 70% HP schedules two E02 after 1 s at 1 s spacing. Movement aura is a separate boss effect. | The singular capture target ends the attempt when stopped. A Captain escape loses the attempt. |
| [Illegal Logging Foreman](../../data/bosses/illegal_logging_foreman.tres) · C2-08 wave 4 | 65% HP gives 600 temporary HP for 5 s and adds 4 Heat/sec over base. No phase adds in the current resource. | A regular boss wave resolves then settles. W13 includes alternate clear copy for the current ordinary-escape behavior while the Story escape decision remains open. |
| [Poacher Leader](../../data/bosses/poacher_leader.tres) · C2-10 wave 5 | 70% schedules two E03 after 1 s at 1 s spacing. At 35%, the Boss moves at 1.5× and schedules one E03 after 1.5 s. | Boss escape is fatal. Defeating the boss still leaves scheduled Runners to resolve. The ending depicts the group's successful interception as custody. |

## Regional and narrative art tickets

Use the layered T01–T06 drawings, the W08 atlas families and the reference-matched W06 chibi style. Deliver separated editable backdrops, relevant overlays, actual path-aligned entry and exit art, and landscape crop previews. Keep the grid at 12 × 5 with high contrast at the 80-unit reference tile. Gate markers, range previews, silhouettes and HP bars stay readable when effects overlap. The forest tunnel remains the exit. Props and environmental layers remain decorative. [GDD pp. 8–9, 17, 29–30, 32 §§ G.2–5, K, Q, T.2] · [W08 intake](../canon/ART_ASSET_MANIFEST.md#prioritized-asset-tickets) · [W06 Ranger art](W06_RANGER_SPRITE_SPEC.md)

| Art ticket | Priority and source | Deliverable and check |
|---|---|---|
| W13-ART-T01 · Forgotten Patrol | First Contact · W08-A03/A04 | Reuse exact T01 layout for five missions. Review the forest backdrop candidate, readable raised pads, one entry and tree-veiled tunnel. Check HUD, starter drag, and the cinematic layer at phone scale. |
| W13-ART-T02 · Gunung Mulu | First regional board · W08-A05, UI pp. 5, 118–121 | Review the Mulu backdrop candidate. Frame the two routes with limestone forms. Keep A/B and the merge clear in fog. Concealment and reveal are actor-level cues. |
| W13-ART-T03 · Batang Ai | Regional pass · W08-A05/A06, UI p. 4 | Author forest and waterway framing around the stepped lane. Use clearance above ground blockers for the drone silhouette. Reserve the readable tile band for the jammer warning. |
| W13-ART-T04 · Tanjung Datu | Regional pass · W08-A05/A06, UI p. 4 | Author subdued coastal forest and sea context. Leave the straight route and raised islands distinct. Validate a telegraphed Net Trapper cue against the Tracking Bot and jam icons. |
| W13-ART-T05 · Imbak Canyon | Regional pass · W08-A05/A06, UI pp. 4, 31 | Frame the route with canyon walls and separate mist/water accents. Keep the canyon floor, Heat gauge, Beacon footprint and Foreman shield legible throughout both operations. |
| W13-ART-T06 · Sepilok-Kabili | Regional pass · W08-A05/A06, UI pp. 4, 98 | Author lowland canopy, open sightlines and the tunnel. Show stable silhouettes for Mortar Crew, Heavy Breacher and Wildlife Trafficker. Distinguish final Runner support and the Poacher Leader's final phase. |
| W13-ART-STORY · Portrait and vignette pass | W08-A07 · UI pp. 20–24, 98, 120–121 | Deliver Manager briefing/concern/relief, Leader steady/reassuring, Poacher and messenger, and three boss portraits and keyed poses. Review full-screen type at large text scale. Use the messenger portrait and a far-trail vignette with no in-battle unit. Include non-graphic capture and epilogue frames. |

### Fact and setting review

The agency, routes and incidents are fictional. Region references inform silhouettes and materials. Campaign text avoids giving real routes, nest sites or wildlife-handling instructions. The C2-10 epilogue contains the only new natural-history statement. It is source-checked here and stays in the team's final editorial review under D-014. [GDD pp. 29–30, 32–33 §§ P, R, T.3]

| Reference key | Claim or art cue | Checked source |
|---|---|---|
| T02 | Limestone formations in Gunung Mulu National Park. | [Sarawak Forestry Corporation](https://sfc.sarawak.gov.my/web/subpage/webpage_view/66) |
| T03 | Forest and waterways in the Batang Ai area. | [Sarawak Forestry Corporation](https://sfc.sarawak.gov.my/web/subpage/webpage_view/55) |
| T04 | Coastal slopes and sea at Tanjung Datu. | [Sarawak Forestry Corporation](https://sfc.sarawak.gov.my/web/subpage/webpage_view/53) |
| T05 | Ridges and lowland forest in Imbak Canyon. Heat is a fictional combat effect. | [Yayasan Sabah Group](https://www.yayasansabahgroup.org.my/conservation_management.cfm) |
| T06 | Lowland forest in the reserve. Use the canonical mission label Sepilok-Kabili and the official source's Kabili-Sepilok name in credits. | [Sabah Biodiversity Outlook, forestry research](https://sabc.sabah.gov.my/sites/default/files/uploads/attachments/2020-05/Sabah-Biodiversity-Outlook.pdf) · [MyBIS protected area record](https://www.mybis.gov.my/pa/315) |
| `fact.hornbill_tree_cavity` | Rhinoceros Hornbills use tree cavities to nest. | [Forest Department Sarawak, Rhinoceros Hornbill](https://forestry.sarawak.gov.my/web/subpage/webpage_view/854) |

## C14 acceptance and decisions to close

1. Import 15 approved specs and resolve every roster, supply, wave, route, art fallback and trigger ID. Verify map masks and test both T02 entrances. The wave table, printed totals and timer expectations must agree.
2. Start from a new save, clear and reveal in order, then replay. Verify Control reveal never grants access alone. Verify grounds for all recruit/Facility unlocks, the Starter Post on every C1-01 attempt and non-persistent Firebreak supply. No mission teaches a mandatory counter gated behind its own clear reward.
3. Use D-009's funded and legal C1-02 opening check. The 20,000 Funds Mechanical build, ordinary Logistics Post availability, reachable currency and actual deployment must all work together. Keep the C05 test wallet separate and obtain approved Campaign payout values.
4. At 1× and 2×, compare Continue and Skip snapshots on an opening, a wave pause, the messenger, a boss intro and each threshold. Verify exactly one outcome and a single save transaction across first normal clear, later perfect, replay, failure and abandon.
5. Review the proposal with the narrative owner, confirm the Foreman's Story escape consequence, and playtest the exact W13 groups, Heat cap, opening times and full progression economy before locking content. Review C10's remaining Ranger class work and C05/C07/C12 physical-device gates. Keep `TBD` rewards pending approval. [D-004, D-006, D-008, D-009, D-014](../canon/DECISION_LOG.md#open-decisions)

### Validation run

- Checked both PDF identities, all 15 stage IDs, exact published wave counts, grants, Control levels, modifiers, trigger references and conditional outcome coverage. Verified 73 dialogue sequences, each with a known speaker and pose key.
- Imported the pinned Godot 4.7.2 project and ran a temporary resource probe against W08's six layouts and the existing C05/C12 resources. All 15 in-memory stage resources validated, and the probe traced 1,111 planned spawns across 49 waves. It compared ticks, waves, IDs and route origins with scripted enemy defeats to isolate scheduling. Gameplay balance and integration of the new dialogue remain C14 playtest work.
- Headless startup and all 562 assertions in the 11 existing runners passed. C05, C07 and C12 physical Android evidence remains pending.
