# Kenyalang Rangers systems index and catalogs

**GDD** is *SimSimi.pdf*, Task 1 (GDD v1.0). **UI** is *Kenyalang_Rangers_Tileset_UI_Storyboard.pdf*. All citations use PDF pages. See the [rulebook](GAME_RULES.md) for precedence and status definitions and the [data contracts](DATA_CONTRACTS.md) for record shapes. **FIXED** entries reflect an explicit source rule. **PROVISIONAL** figures retain the printed balance values. **MISSING** fields are `TBD`. The **provisional keys** below are stable reference IDs for the review draft where the PDFs supply names only. Source IDs are preserved wherever the PDFs provide them. [GDD pp. 28–29 § O.2; UI p. 4]

| System | Source inventory | Primary reference |
|---|---|---|
| Combat | 12 Rangers, 13 Facilities, 15 standard enemies, 3 bosses | GDD pp. 8–13 §§ G.2–5, H.1–3; pp. 15–17 §§ J.1–3 |
| Campaign | 15 ordered operations, 6 original tactical templates | GDD pp. 6–8 §§ F.2–4, G.1; pp. 21–22, 32 §§ M.4, T.2; UI pp. 4, 8 |
| Headquarters | 11 rooms, including 4 R&D departments | GDD pp. 18–20 §§ M.1–2; UI pp. 38–62 S25–H11/S28 |
| Modifiers | 15 R&D buffs and 15 Story/Chaos debuffs | GDD pp. 23–25 §§ M.5–7; UI pp. 67, 73 S33/S37 |
| Side activities | Rainforest Chaos, PR Outreach, Records Encyclopaedia, Habitat Restoration | GDD pp. 24–28 §§ M.7–10; UI pp. 71–93 S35–S51 and variants |

## Rangers

**FIXED**. Three Rangers in each of Offense, Defense, Support and Specialist. The named Records enhancements are separate from permanent levels. All per-action intervals are combat seconds at 1×. The same source tables explicitly designate the **PROVISIONAL** Lv.1 HP, damage, outputs and skill balance figures below. Published block count, charge limit and deployment geometry are part of each unit's written kit. **MISSING**. Canonical Ranger IDs, final level scaling, deployment/cooldown figures and exact ability parameters not given below are `TBD`. [GDD pp. 9–11 §§ H.1–1a; pp. 20, 26–27, 33 §§ M.2, M.9, T.4]

| Class | Ranger | Tile | Lv.1 HP / basic output (provisional) | Source ability and provisional supplemental values | Provisional key | Source |
| --- | --- | --- | --- | --- | --- | --- |
| Offense | Scout Sniper | Elevated | 100 / 24 direct per 2.0 s | Moderate square, focus-marked target priority. Focus tranq 24 HP plus brief immobilize. Records Steady Aim strengthens marked attacks and adds tap-target Focus. | `ranger.scout_sniper` | GDD pp. 9, 11 §§ H.1–1a; p. 26 § M.9; UI p. 26 S13 |
| Offense | Crowd Controller | Elevated | 120 / 30 AoE per 3.0 s | EMP extra versus Technological (proposed +30% basic bonus). Empowered EMP 50 AoE HP and a slowing field. | `ranger.crowd_controller` | GDD pp. 9, 11 §§ H.1–1a |
| Offense | Guard Veteran | Ground | 230 / 32 frontal AoE per 2.0 s | Block 1, two forward tiles, stun-prod heavy attack. FOUR charges, 46 frontal AoE per charge, about 13 s to restore one. Charge use resets the basic attack interval. | `ranger.guard_veteran` | GDD pp. 9–11 §§ H.1–1a; p. 20 § M.2 |
| Defense | Patrolman | Ground | 320 / 12 melee per 1.5 s | Beginner block 2, never gains block 3. Records Reinforced Patrol improves HP and counterattacks against an enemy actively attacking Patrolman (proposed +6 damage). | `ranger.patrolman` | GDD pp. 9, 11 §§ H.1–1a; p. 26 § M.9 |
| Defense | Barricade Ops | Ground, 2 tiles | 520 / 8 frontal melee per 2.2 s | Block 3, resists Heavy Breacher Knockdown. Active 12 frontal AoE, pushes enemies back two tiles, long recharge. Eligible for Medic healing and Mechanic repair. | `ranger.barricade_ops` | GDD pp. 10–11 §§ H.1–1a; p. 12 § H.2 |
| Defense | K9 Ranger | Ground | 230 / 12 ranged tranq per 1.7 s | Block 1 with tranquilizer rifle. Companion howl reveals and slows, dealing 0 HP damage. | `ranger.k9_ranger` | GDD pp. 10–11 §§ H.1–1a; p. 17 § J.3 |
| Support | Combat Medic | Elevated | 110 / 24 heal per 2.2 s | Chooses lowest-HP eligible ally. Records Emergency Treatment shortens heal interval and adds cleansing medic kit (proposed 65 HP). | `ranger.combat_medic` | GDD pp. 10–11 §§ H.1–1a; p. 26 § M.9 |
| Support | Kenyalang Seer | Elevated | 120 / 13 boomerang per 2.3 s | Scans highest Danger target. Reveal deals 0 HP. Up to TEN incoming-damage marks (proposed +2% per mark, max +20%). Boomerang can strike Aerial and bounce twice. | `ranger.kenyalang_seer` | GDD pp. 10–11 §§ H.1–1a |
| Support | Outpost Mechanic | Elevated | 140 / 10 attack per 2.2 s, 20 repair per 3.0 s | Repairs or improves nearby Facilities and Barricade Ops. Ordinary Rangers cannot receive its repair. | `ranger.outpost_mechanic` | GDD pp. 10–11 §§ H.1–1a; p. 17 §§ J.1a, J.2 |
| Specialist | Woods Tracker | Ground | 100 / 22 melee per 1.3 s | Deploy nets highest Danger target, with 22 HP to center target and nearby immobilize. Qualified retreat refunds Tokens and reduces all redeploy cooldowns with no direct damage. Records increases HP and reduces that Ranger's redeploy delay. | `ranger.woods_tracker` | GDD pp. 10–11 §§ H.1–1a; p. 26 § M.9 |
| Specialist | Saboteurist | Ground | 130 / 18 vs Technological per 2.3 s | Deployment interference pulse grows every 2 s. Retreat pulse does 20 AoE HP, freezes Technological targets for 2 s and refunds Tokens. | `ranger.saboteurist` | GDD pp. 10–11 §§ H.1–1a |
| Specialist | Strike Team | Ground, 2 tiles | 100 / 18 baton per 2.0 s | Deploys after 2 s, strikes highest Danger target. Eligible retreats escalate the next Token cost and arrival power. Proposed arrival damage 80/120/160 at zero/one/two escalations, with 1/2/3 targets. No beginner access or Records enhancement. | `ranger.strike_team` | GDD pp. 10–11 §§ H.1–1a; p. 27 § M.9 |

## Facilities

**FIXED**. The roster includes 4 Resource, 3 Sentry, 3 Strategist and 3 Status Facilities. All 13 deploy on elevated cells. The default footprint is two horizontal cells. Sentry Tower uses one and reserves the cell above. Only explicit Siege can damage a Facility, including during construction. Non-Siege attacks cannot. **PROVISIONAL**. Lv.1 HP, non-Logistics Token costs and proposed outputs are source baselines. **MISSING**. Canonical Facility IDs and unlisted build/cooldown, targeting, storage or escalation data are `TBD`. [GDD pp. 8–9 §§ G.2–4; pp. 15–17 §§ J.1–2; p. 33 § T.4; UI pp. 4, 66 S32]

| Class | Facility | Lv.1 HP / Token cost | Source behavior and baseline | Provisional key | Source |
| --- | --- | --- | --- | --- | --- |
| Resource | Logistics Post | 160 / first normal 0, later escalating | Optional in ordinary loadout. First normal Post instant and no first cooldown. **Fixed base output** 10 Tokens/10 s at Lv.1 → 15/10 s at Lv.100. C1-01 Starter Post and D05 are documented separately. | `facility.logistics_post` | GDD pp. 8–9 §§ G.3, H.1; pp. 15, 20, 22, 24 §§ J.1, M.2, M.4, M.6; UI pp. 22, 101 S10/S59 |
| Resource | Medic Cabin | 170 / 22 | Generates and stores manual medic kits. Pick an eligible ally and confirm. Proposed 65 HP per kit. | `facility.medic_cabin` | GDD pp. 15, 17 §§ J.1–1a; UI p. 29 S16 |
| Resource | Skill Relay Station | 190 / 26 | Area pulse reduces active Ranger skill cooldowns. First eligible 1,000 Chaos threshold unlock. | `facility.skill_relay_station` | GDD pp. 15, 25 §§ J.1, M.7 |
| Resource | Dispatch Relay | 200 / 28 | Pulse reduces applicable Ranger AND Facility cooldowns. | `facility.dispatch_relay` | GDD p. 16 § J.1 |
| Sentry | Sonic Turret | 250 / 35 | Fixed 7 s baseline build. 12 AoE HP every 2.8 s per eligible target and a separate slow. | `facility.sonic_turret` | GDD pp. 16–17 §§ J.1–2; UI p. 28 S15 |
| Sentry | Electric Pulse Turret | 300 / 45 | EMP bursts of three 15-HP hits (45 total against one target), about 5.5 s burst recovery. Proposed +30% hit damage against Technological. | `facility.electric_pulse_turret` | GDD p. 16 §§ J.1–1a |
| Sentry | Canopy Defense Launcher | 380 / 60 | Broad square AoE, prioritizes Aerial. Proposed 34 HP per hit to Aerial every 3.5 s, 17 HP to eligible ground targets. | `facility.canopy_defense_launcher` | GDD p. 16 §§ J.1–1a |
| Strategist | Sentry Tower | 420 / 65 | One elevated cell plus reserved cell above, larger square detection, “one ranged mount.” The attack table gives all other Facilities 0 direct HP. Mount behavior is `TBD`. First eligible 3,000 Chaos threshold unlock. | `facility.sentry_tower` | GDD p. 8 § G.2; pp. 16–17 §§ J.1–2; p. 25 § M.7; UI p. 66 S32 |
| Strategist | Firebreak Beacon | 220 / 30 | Slows Heat buildup and cannot eliminate it. Provided before the first Heat wave of C2-07. | `facility.firebreak_beacon` | GDD pp. 9, 16, 22 §§ G.5, J.1, M.4 |
| Strategist | Specialist Calltower | 240 / 34 | Builds a claimable one-use discount for the next Specialist deployment. First eligible 2,000 Chaos threshold unlock. | `facility.specialist_calltower` | GDD pp. 16, 25 §§ J.1, M.7; UI p. 29 S16 |
| Status | Ranger Coordination Hub | 270 / 40 | Square-area allied Ranger attack-speed bonus. | `facility.ranger_coordination_hub` | GDD p. 16 § J.1 |
| Status | Reinforced Cover Station | 330 / 50 | Named incoming-damage reduction in a square zone. No Defense stat. | `facility.reinforced_cover_station` | GDD pp. 9, 16 §§ G.4, J.1 |
| Status | Disruption Beacon | 330 / 50 | Reduces enemy attack effectiveness and delays selected enemy abilities. | `facility.disruption_beacon` | GDD p. 16 § J.1 |

Only the offensive turret outputs are specified as direct enemy HP damage. Other support, resource and status outputs are non-damaging in the attack table. An eligible Outpost Mechanic repairs by a provisional 20 HP every 3.0 s. The separate Sentry Tower mount wording is tracked in [D-008](DECISION_LOG.md#open-decisions). [GDD pp. 16–17 § J.1a]

## Standard enemies

**FIXED** IDs, names, Danger rating, authored threats and Chaos points. Danger 1–5 is threat priority and does not multiply HP. Functional tags may overlap. **PROVISIONAL** HP and damage/interval figures. **MISSING** ordinary escape penalties, movement and behavior timing not specified are `TBD`. [GDD pp. 11–13 §§ H.2–2a; pp. 24–25 § M.7; p. 33 § T.4]

| ID | Enemy | Danger | HP | HP damage / interval | Target and threat | Chaos points | Source |
|---|---|---:|---:|---|---|---:|---|
| E01 | Forest Trespasser | 1 | 100 | 6 / 1.8 s | Ground Rangers, slow baseline melee. | 10 | GDD pp. 11–12 §§ H.2–2a; p. 24 § M.7 |
| E02 | Poacher | 1 | 140 | 9 / 1.7 s | Ground Rangers, standard melee. | 15 | GDD p. 12 §§ H.2–2a; p. 25 § M.7 |
| E03 | Contraband Runner | 2 | 110 | 5 / 1.2 s | Ground Rangers, fast escape threat with Sprint. | 20 | GDD p. 12 §§ H.2–2a; p. 25 § M.7 |
| E04 | Shield Carrier | 3 | 450 | 12 / 2.2 s | Ground Rangers, high HP and visual shield. | 25 | GDD p. 12 §§ H.2–2a; p. 25 § M.7 |
| E05 | Rifle Spotter | 3 | 180 | 15 / 2.4 s | Eligible ground/elevated Rangers, ordinary ranged. | 25 | GDD p. 12 §§ H.2–2a; p. 25 § M.7 |
| E06 | Smoke Infiltrator | 3 | 150 | 12 / 1.6 s | Ground Rangers, temporary invisibility countered by detection. | 30 | GDD p. 12 §§ H.2–2a; p. 25 § M.7 |
| E07 | Signal Jammer | 4 | 320 | 8 / 2.4 s | Rangers, Technological, active skill interference separate from damage. | 35 | GDD p. 12 §§ H.2–2a; p. 25 § M.7 |
| E08 | Recon Drone | 3 | 120 | 7 / 2.0 s | Eligible Rangers, Aerial and Technological, unblockable from ground and no Siege. | 30 | GDD pp. 12–13 §§ H.2–2a; p. 25 § M.7 |
| E09 | Tracking Bot | 3 | 300 | 11 / 2.0 s | Rangers, Technological, attack-rate debuff separate. | 35 | GDD pp. 12–13 §§ H.2–2a; p. 25 § M.7 |
| E10 | Net Trapper | 3 | 250 | 8 / 2.0 s | Rangers, brief ranged entanglement separate. | 35 | GDD pp. 12–13 §§ H.2–2a; p. 24 § M.7 |
| E11 | Demolitionist | 4 | 360 | 60 Siege / 6.0 s | Facilities only, including construction. | 50 | GDD pp. 12–13 §§ H.2–2a; p. 25 § M.7 |
| E12 | Portable Mortar Crew | 4 | 600 | 120 Siege / 10.0 s | Facilities only, Technological, slow telegraphed bombardment. | 65 | GDD pp. 9, 12–13 §§ G.4, H.2–2a; p. 25 § M.7 |
| E13 | Heavy Breacher | 4 | 1,050 | 45 / 3.2 s | Blocking Rangers, Heavy Knockdown, Barricade Ops resists. | 60 | GDD pp. 12–13 §§ H.2–2a; p. 25 § M.7 |
| E14 | Ignition Operator | 4 | 280 | 9 / 2.5 s | Ground Rangers, Technological, builds Heat affecting Integrity, no Siege. | 55 | GDD pp. 9, 12–13 §§ G.4–5, H.2–2a; p. 25 § M.7 |
| E15 | Wildlife Trafficker | 5 | 850 | 18 / 2.0 s | Ground Rangers, escape immediately defeats the mission. | 90 | GDD pp. 12–13 §§ H.2–2a; p. 25 § M.7 |

## Bosses

**FIXED** names, mission assignments, threats and Chaos points. Bosses have no Siege unless explicitly authored. **PROVISIONAL** HP and direct attack values. **MISSING** canonical boss IDs, Danger numbers, phases, triggers, summons, exact timings and exact escape outcomes where unstated are `TBD`. [GDD pp. 7, 13 §§ F.3–4, H.3; pp. 22, 25 §§ M.4, M.7]

| Boss | Story mission | HP / damage / interval (provisional) | Source behavior | Chaos points | Provisional key | Source |
| --- | --- | --- | --- | ---: | --- | --- |
| Diversion Captain | C1-05 | 2,500 / 28 HP / 1.8 s | Normal Ranger attack, movement support/speed aura, modest reinforcements. Capture ends introductory operation. | 200 | `boss.diversion_captain` | GDD pp. 6–7 §§ F.2–3; p. 13 § H.3; pp. 22, 25 §§ M.4, M.7 |
| Illegal Logging Foreman | C2-08 | 8,000 / 42 HP / 2.5 s | Normal Ranger attack, Technological, increased Heat and optional temporary extra HP active effect. | 300 | `boss.illegal_logging_foreman` | GDD pp. 7, 13 §§ F.3, H.3; pp. 22, 25 §§ M.4, M.7 |
| Poacher Leader | C2-10 | 13,000 / 60 HP / 2.0 s | Normal Ranger attack, phases with reinforcements and fast Runners, final speed surge. Escape is catastrophic. | 500 | `boss.poacher_leader` | GDD pp. 7, 13 §§ F.3, H.3; pp. 22, 25 §§ M.4, M.7 |

## Campaign missions

**FIXED** operation IDs, order, template assignment, names, and assigned Story debuffs. **PROVISIONAL** first-pass counts per wave shown as authored. “Boss” is a singular boss wave, excluding any scripted reinforcements. C1-01's tutorial equipment is available **at start**. C2-07 provides Firebreak Beacon **before the first Heat wave**. Ordinary unlocks and teaching beats are shown as listed. **MISSING** full spawn compositions, timings by spawn, final dialogue, per-stage rewards and unlock semantics not stated by the source are `TBD`. [GDD pp. 6–8 §§ F.2–4, G.1; pp. 21–22 § M.4; p. 32 § T.2; UI pp. 4, 8, 10]

| Stage | Mission | Chapter/region template | Waves | Fixed debuffs | Unlock, provision or teaching beat | Source |
|---|---|---|---|---|---|---|
| C1-01 | First Contact | T01 Forgotten Patrol | 6 / 8 | D01 | Scout Sniper, Patrolman and Logistics Post supplied at start. Emergency call, free Post, drag and basic attacks. | GDD pp. 6, 9, 22 §§ F.2, H.1, M.4; UI pp. 8, 22 S10 |
| C1-02 | Hold the Line | T01 Forgotten Patrol | 8 / 10 | D02 | Combat Medic and Sonic Turret. Organized incursion, blocking, Integrity and elevated support. | GDD pp. 6, 22 §§ F.2, M.4; UI p. 8 |
| C1-03 | Narrow Escape | T01 Forgotten Patrol | 9 / 11 / 13 | D03 | Guard Veteran and Medic Cabin. Skill tap, hold to retreat, cinematic messenger. | GDD pp. 6, 22 §§ F.2, M.4; UI p. 8 |
| C1-04 | Watch the Ridge | T01 Forgotten Patrol | 10 / 12 / 14 | D08 | Woods Tracker and Reinforced Cover Station. Fixed melee facing, healing, ranged threats and positioning. | GDD pp. 6, 22 §§ F.2, M.4; UI pp. 8, 15 S04, 37 S24 |
| C1-05 | Operation: Full Pivot | T01 Forgotten Patrol | 14 / 18 / boss | D05 | Barricade Ops. Limited logistics, capture Diversion Captain. | GDD pp. 7, 13, 22 §§ F.2, H.3, M.4; UI pp. 8, 101 S59 |
| C2-01 | Misty Approach | T02 Gunung Mulu | 16 / 20 / 24 | D06 + D02 | K9 Ranger. Concealment and detection, two entrances converging. | GDD pp. 7–8 §§ F.3, G.2; p. 22 § M.4; UI pp. 5, 8, 117 M01 |
| C2-02 | Siege on the Ridge | T02 Gunung Mulu | 18 / 22 / 26 | D09 + D10 | Outpost Mechanic and Ranger Coordination Hub. Siege and fragile Facilities. | GDD pp. 7, 22 §§ F.3, M.4; UI p. 8 |
| C2-03 | Aerial Crossing | T03 Batang Ai | 20 / 24 / 28 | D11 + D07 | Kenyalang Seer and Canopy Defense Launcher. Aerial and drone counters. | GDD pp. 7, 22 §§ F.3, M.4; UI p. 8 |
| C2-04 | Jammed Communications | T03 Batang Ai | 20 / 25 / 30 | D04 + D13 | Crowd Controller and Electric Pulse Turret. Technology, EMP, jamming and compressed arrivals. | GDD pp. 7, 22 §§ F.3, M.4; UI p. 8 |
| C2-05 | Automated Pursuit | T04 Tanjung Datu | 22 / 26 / 30 / 32 | D08 + D12 | Saboteurist and Disruption Beacon. Tracking Bots and automation. | GDD pp. 7, 22 §§ F.3, M.4; UI p. 8 |
| C2-06 | Capture Operations | T04 Tanjung Datu | 24 / 30 / 35 | D03 + D04 | Strike Team and Dispatch Relay. Net Trappers and status disruption. | GDD pp. 7, 22 §§ F.3, M.4; UI p. 8 |
| C2-07 | Heat in the Gorge | T05 Imbak Canyon | 25 / 30 / 35 / 38 | D14 + D06 | Firebreak Beacon provided before the first Heat wave. Ignition Operators and Heat. | GDD pp. 7, 22 §§ F.3, M.4; UI pp. 8, 31 S18 |
| C2-08 | Breaking the Line | T05 Imbak Canyon | 30 / 33 / 38 / boss | D14 + D08 | Illegal Logging Foreman encounter and Heat. | GDD pp. 7, 13, 22 §§ F.3, H.3, M.4; UI p. 8 |
| C2-09 | Desperate Convoy | T06 Sepilok-Kabili | 28 / 32 / 36 / 42 | D09 + D15 | Mortar, Breacher and Wildlife Trafficker priority. | GDD pp. 7, 22 §§ F.3, M.4; UI p. 8 |
| C2-10 | Final Interception | T06 Sepilok-Kabili | 25 / 30 / 36 / 45 / boss | D13 + D15 | Poacher Leader finale, final Story completion reward and epilogue. | GDD pp. 7, 13, 22 §§ F.3–4, H.3, M.4; UI pp. 8, 98 S56 |

## Headquarters rooms

**FIXED** room names, current opening/upgrade price schedule, Lv.1–5 structure and capacity/unlock ladder. `k` means 1,000 Funds and `M` means 1,000,000 Funds. The sum is 16.160M. Only the three free Lv.1 rooms exist in a new save. **PROVISIONAL** Finance rates/storage and economic payout assumptions are retained for modeling. UI frame IDs H01–H11 identify screens. **MISSING** canonical room data IDs are `TBD`. [GDD pp. 18–21 §§ M.1–3; p. 33 § T.4; UI pp. 38–62, 68, 110 S25–H11/S28/S34/V08]

| Room | Open / Lv.2 / Lv.3 / Lv.4 / Lv.5 | Total | Benefits from Lv.1 to Lv.5 | Provisional key | Source |
| --- | --- | ---: | --- | --- | --- |
| Control Room | Free / 20k / 80k / 300k / 900k | 1.300M | Reveals ranges C1-01–03 / C1-04–05 / C2-01–04 / C2-05–08 / C2-09–10. Ordered clears still apply. | `room.control_room` | GDD pp. 18–19 § M.1; UI pp. 40–41 H01/S27 |
| Human Resources | Free / 25k / 110k / 350k / 1,000k | 1.485M | 3 / 4 / 5 / 6 / 8 Ranger slots. Ranger upgrades enter here. | `room.human_resources` | GDD pp. 18–20 §§ M.1–2; UI pp. 42–43, 63–64 H02/U02/S29/S30 |
| Finance Room | Free / 15k / 75k / 250k / 750k | 1.090M | Active Funds/sec and storage 2/12k, 4/25k, 7/50k, 10/90k, 15/160k. Claim from storage to shared wallet. | `room.finance_room` | GDD pp. 18–19, 21 §§ M.1, M.3; UI pp. 44–45, 68 H03/U03/S34 |
| Mechanical | 20k / 25k / 110k / 350k / 1,000k | 1.505M | 2 / 3 / 4 / 5 / 6 Facility slots. Facility upgrades enter here. | `room.mechanical` | GDD pp. 18–20 §§ M.1–2; UI pp. 46–47, 62, 65–66 H04/U04/S28/S31/S32 |
| Ecology | 20k / 20k / 90k / 300k / 900k | 1.330M | 2 / 3 / 4 / 5 / 6 plots. Reforestation access. Lv.5 also requires 60% restoration. | `room.ecology` | GDD pp. 19–20, 27 §§ M.1, M.10; UI pp. 48–49, 93, 111 H05/U05/S51/V09 |
| Outreach | 15k / 20k / 100k / 330k / 950k | 1.415M | PR enabled at Lv.1 with improved payouts on later tiers. Lv.5 also requires five Best or Acceptable responses. | `room.outreach` | GDD pp. 19–20, 25–26 §§ M.1, M.8; UI pp. 50–51, 110 H06/U06/V08 |
| Records | 15k / 20k / 100k / 300k / 900k | 1.335M | Facts archive / Scout Sniper / Patrolman / Combat Medic / Woods Tracker quiz chapters. | `room.records` | GDD pp. 19, 26 §§ M.1, M.9; UI pp. 52–53, 85 H07/U07/S43 |
| R&D Eco | 25k / 25k / 120k / 360k / 1,050k | 1.580M | No buff / B01 / B02 / B03 / B04. | `room.r_d_eco` | GDD pp. 19–20, 23 §§ M.1, M.5; UI pp. 54–55 H08/U08 |
| R&D Combat | 25k / 25k / 120k / 360k / 1,050k | 1.580M | No buff / B05 / B06 / B07 / B08. | `room.r_d_combat` | GDD pp. 19–20, 23 §§ M.1, M.5; UI pp. 56–57 H09/U09 |
| R&D Guard | 25k / 25k / 120k / 360k / 1,050k | 1.580M | No buff / B09 / B10 / B11 / B12. | `room.r_d_guard` | GDD pp. 19–20, 23 §§ M.1, M.5; UI pp. 58–59 H10/U10 |
| R&D Crisis | 30k / 30k / 150k / 450k / 1,300k | 1.960M | No buff / no buff / B13 / B14 / B15. | `room.r_d_crisis` | GDD pp. 19–20, 23 §§ M.1, M.5; UI pp. 60–61 H11/U11 |

## R&D buffs

**FIXED** catalog. Values retain the GDD mechanics and signed Chaos points. Crisis benefit and drawback apply together once. A room level unlocks a buff and never increases its potency. Duplicate selections are invalid. Stacking order, rounding and unstated compatibility rules are `TBD`. [GDD pp. 14, 19–20, 23 §§ I.2, M.1, M.5; UI pp. 18, 67, 73 S07/S33/S37]

| ID | Department / unlock | Buff | Effect | Chaos points | Source |
|---|---|---|---|---:|---|
| B01 | Eco / Lv.2 | Trail Reconnaissance | Warn about spawn locations 5 s before a wave. | −100 | GDD pp. 19, 23 §§ M.1, M.5 |
| B02 | Eco / Lv.3 | Fireline Preparation | Heat buildup −25% on Heat maps. | −100 | GDD pp. 19, 23 §§ M.1, M.5 |
| B03 | Eco / Lv.4 | Visibility Sweep | Reveal concealed enemies for 3 s after spawn. | −100 | GDD pp. 19, 23 §§ M.1, M.5 |
| B04 | Eco / Lv.5 | Safe Extraction Plan | Ordinary escape Integrity loss −25%, minimum 1. Escapes still count. | −100 | GDD pp. 19, 23 §§ M.1, M.5 |
| B05 | Combat / Lv.2 | Tranquilizer Calibration | Ranger attack damage +10%. | −100 | GDD pp. 19, 23 §§ M.1, M.5 |
| B06 | Combat / Lv.3 | Rapid Response Drills | Ranger auto-attack speed +12%. | −100 | GDD pp. 19, 23 §§ M.1, M.5 |
| B07 | Combat / Lv.4 | Skill Coordination | Active Skill cooldown recovery +20%. | −100 | GDD pp. 19, 23 §§ M.1, M.5 |
| B08 | Combat / Lv.5 | Exploit Weakness | Damage +20% vs a target with a negative effect/mark, one bonus only. | −200 | GDD pp. 19, 23 §§ M.1, M.5 |
| B09 | Guard / Lv.2 | Field Endurance | Ranger maximum HP +15%. | −100 | GDD pp. 19, 23 §§ M.1, M.5 |
| B10 | Guard / Lv.3 | Improved First Aid | Healing received +20%. | −100 | GDD pp. 19, 23 §§ M.1, M.5 |
| B11 | Guard / Lv.4 | Reinforced Positions | Blocking Rangers take 12% less damage from the named effect. | −100 | GDD pp. 19, 23 §§ M.1, M.5 |
| B12 | Guard / Lv.5 | Brace Training | Ignore first enemy Knockdown per deployment. | −100 | GDD pp. 19, 23 §§ M.1, M.5 |
| B13 | Crisis / Lv.3 | Emergency Requisition | Start +35 Tokens, Logistics generation −30%. | −200 | GDD pp. 19, 23 §§ M.1, M.5 |
| B14 | Crisis / Lv.4 | High-Stakes Intervention | Ranger damage +30%, max HP −25%. | −200 | GDD pp. 19, 23 §§ M.1, M.5 |
| B15 | Crisis / Lv.5 | Silent Mobilization | Redeploy cooldown −35%, Post yield +20%, active skills disabled. | −200 | GDD pp. 19, 23 §§ M.1, M.5 |

## Story debuffs and Chaos modifiers

**FIXED** catalog. Campaign assignments are read-only. Chaos accepts distinct eligible modifiers. An ineffective modifier cannot earn points. There are no slot-reduction debuffs. [GDD pp. 14, 22–24 §§ I.2, M.4, M.6–7; UI pp. 18, 73, 101 S07/S37/S59]

| ID | Debuff | Effect | Chaos points | Source |
|---|---|---|---:|---|
| D01 | Thin Supply Line | Logistics Post yield −10%. | +100 | GDD p. 23 § M.6 |
| D02 | Urgent Pursuit | All enemy movement speed +10%. | +100 | GDD p. 24 § M.6 |
| D03 | Field Fatigue | All Ranger maximum HP −15%. | +100 | GDD p. 24 § M.6 |
| D04 | Radio Static | Active Skill cooldown durations +20%. | +100 | GDD p. 24 § M.6 |
| D05 | Fixed Stockpile | No Logistics Posts; instead start with 120 fixed Tokens. | +200 | GDD p. 24 § M.6; UI p. 101 S59 |
| D06 | Persistent Concealment | Invisibility persists 2 s longer in relevant phases. | +100 | GDD p. 24 § M.6 |
| D07 | Limited Respite | Between-wave rest durations −40%. | +100 | GDD p. 24 § M.6 |
| D08 | Toughened Crew | Enemy maximum HP +15%. | +100 | GDD p. 24 § M.6 |
| D09 | High-Impact Siege | Siege Damage to Facilities +25%. | +200 | GDD p. 24 § M.6 |
| D10 | Delayed Construction | Facility construction duration +25%, excluding the first free Post. | +100 | GDD p. 24 § M.6 |
| D11 | Aerial Tailwind | Aerial enemy movement speed +25%. | +100 | GDD p. 24 § M.6 |
| D12 | Strained Logistics | Ranger deployment costs +10%, rounded up. | +100 | GDD p. 24 § M.6 |
| D13 | Compressed Arrivals | Enemy inter-spawn time −20%. | +200 | GDD p. 24 § M.6 |
| D14 | Heat Surge | Heat buildup +30% on Heat-enabled stages. | +200 | GDD p. 24 § M.6 |
| D15 | Critical Escape | Ordinary escape Integrity penalty +50%, rounded up. | +200 | GDD p. 24 § M.6 |

## Four side activities

| Activity | Entry | Fixed loop and relationship to progress | Provisional or missing content | Provisional key | Source |
| --- | --- | --- | --- | --- | --- |
| Rainforest Chaos | Main menu or Headquarters Chaos entrance | Custom routes, five wave slots, distinct effects, Medal Score and qualifying clears. Trophy and three exclusive Facility thresholds. | Numeric modifier overlaps are `TBD`. See [approved eligibility rules](GAME_RULES.md#rainforest-chaos). | `activity.rainforest_chaos` | GDD pp. 15, 23–25 §§ I.4, M.5–7; UI pp. 9, 38, 71–76 S25/S35–S40 |
| PR Outreach | HQ → Outreach → Answer questions | Up to five four-option responses per 20-hour batch from 20 unique questions. Manager feedback, Funds and Lv.5 participation. | Payout tuning and final bank `TBD`. | `activity.pr_outreach` | GDD pp. 25–26 § M.8; UI pp. 50, 77–84, 103–105 H06/S41–P05/V01–V03 |
| Records Encyclopaedia | HQ → Records | Facts archive, four 15-second quiz chapters, first-correct Funds and named one-time enhancements. | About 40 questions and 1.55M scenario are provisional. Authored bank `TBD`. | `activity.records_encyclopaedia` | GDD pp. 19, 26–27 §§ M.1, M.9; UI pp. 52, 85–88, 102 H07/S43–S46/S60 |
| Habitat Restoration | Main menu Reforestation or HQ → Ecology → Reforestation | Water four native tree types through three visual stages. Up to six plots, Funds, one nest-box discovery and statements read later in Records. Ecology alone upgrades plot capacity. | Final payouts `TBD`. See [approved watering, milestone and discovery rules](GAME_RULES.md#outreach-records-and-habitat-restoration). | `activity.habitat_restoration` | GDD pp. 14, 19–20, 27 §§ I.1, M.1, M.10; UI pp. 48–49, 89–93 H05/U05/S47–S51 |
