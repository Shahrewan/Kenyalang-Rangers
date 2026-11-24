# C30 · Campaign balance and combat readability

Baseline `cc2be81` includes C28-D and C29. C30 uses Godot `4.7.2.stable.official.ed1daf0bf` and matching `4.7.2.stable` Android export templates. Runtime and tests are in `efc5f61` and the C2-07 timing refinement is in `6a267ba`. [PR #37](https://github.com/Shahrewan/Kenyalang-Rangers/pull/37)

The main menu uses the W29 composition, approved brand mark, illustrated cards and the current player’s name and balance. Reforestation, Settings and Field Guide remain accessible. The sample battle remains callable by the smoke test. Both upgrade lists and level-detail pages show the exact catalog badge for the unit, including ownership records for the five pending Ranger kits.

## Timing and economy

Each Chapter 2 stage has a `balance_trial.c30_pacing` block. The loader applies those per-wave factors before existing modifiers. The original authored interval and opening fields provide the comparison baseline. Chapter 1 keeps its authored schedule. The original wave rests, final ordinary cadence and boss-specific intervals remain in use. A semantic comparison against `cc2be81` verified that the ten added pacing blocks are the sole W13 stage changes.

| Operations | Opening seconds before → after | Interval factors by wave |
| --- | --- | --- |
| C2-01–04 | 12 → 20 | 1.50, 1.25, 1.00 |
| C2-05 | 15 → 20 | 1.50, 1.25, 1.10, 1.00 |
| C2-06 | 15 → 20 | 1.50, 1.25, 1.00 |
| C2-07 | 20 → 32 | 1.90, 1.70, 1.30, 1.00 |
| C2-08 | 15 → 20 | 1.50, 1.25, 1.10, 1.00 |
| C2-09 | 15 → 22 | 1.50, 1.25, 1.10, 1.00 |
| C2-10 | 15 → 22 | 1.50, 1.25, 1.10, 1.00, 1.00 |

For example, opening arrivals in C2-01 change from 2 s to 3 s apart, and C2-04’s D13 makes that 2.4 s. At C2-01 tick 1200 a Lv.1 free Post has produced 20 Tokens. A Guard costs 16 and can deploy before tick 1201. C2-07’s extra preparation and slower first three waves give the supplied Firebreak a build window and time to establish an early ranged line. The Firebreak keeps its normal cost and construction duration. Enemy HP, speed and damage preserve their existing resource values.

| Ranger | Seconds before → after | Facility | Seconds before → after |
| --- | --- | --- | --- |
| Scout Sniper | 14 → 24 | Logistics Post | 8 → 24 |
| Patrolman | 12 → 28 | Sonic Turret | 11 → 42 |
| Guard Veteran | 18 → 32 | Medic Cabin | 12 → 44 |
| Barricade Ops | 20 → 35 | Reinforced Cover Station | 14 → 50 |
| Combat Medic | 16 → 26 | Ranger Coordination Hub | 14 → 48 |
| Outpost Mechanic | 16 → 24 | Canopy Defense Launcher | 15 → 56 |
| Crowd Controller | 18 → 29 | Electric Pulse Turret | 13 → 52 |
| | | Disruption Beacon | 14 → 54 |
| | | Dispatch Relay | 12 → 43 |
| | | Firebreak Beacon | 10 → 40 |
| | | Skill Relay Station | 12 → 46 |
| | | Specialist Calltower | 12 → 49 |
| | | Sentry Tower | 15 → 60 |

The first Post remains free, instant and cooldown-free. Paid Posts retain their six-second build and escalating costs. Cancelling a build refunds its paid Tokens and keeps the type cooldown. Each active copy retains independent HP and charges. Retreat restarts the Ranger’s type cooldown. B15, won Records effects and Dispatch continue to apply. Chaos uses the new shared cooldowns with its original 18 s preparation, 2.5 s arrival interval and score rules. The pending field roster, including all three Specialists, remains unavailable.

## Defender damage and skill state

The focused fixtures register enemies through a real wave and observe actual HP loss. Patrolman deals 12 at 90-tick attack intervals to one eligible target. Barricade Ops deals 8 at 132 ticks to enemies in its frontal pattern. Guard Veteran, the canon Offense Ranger with a blocking role, deals 32 at 120 ticks and can hit multiple frontal targets. A Ranger facing away still blocks and can only attack tiles in front. Live melee feedback shows HP actually removed, including damage reduced by a temporary shield. Holding a melee Ranger shows its facing and block count. The original damage model and healing-only Medic remain in use.

The field badge reads each placement’s current charge or stock, effective next deadline and eligibility. A check, clock, lock or minus glyph distinguishes Ready, recovering, locked and spent. A partially filled bar can coexist with Ready. Stock and charges that replenish use real battle deadlines, including jam delays and Relay reductions. Single-use skills show spent. The selected-unit readout names the skill and shows the actual next wait or lock reason. It is separate from the deployment tray cooldown.

## Autonomous Campaign comparison

The playtest runner uses the actual roster, operation planner, Token costs, shared clock, automatic attacks, legal skill taps and target confirmation. Each matchup starts from a separate profile representing the prerequisite clears for that operation. Its setup never alters an enemy or its position. Low uses Lv.1 deployables, Mechanical Lv.1 and HR Lv.2. Progressed uses a Lv.30 Post, other deployables at Lv.1, Mechanical Lv.3, HR Lv.4, attainable Records unlocks and B13 where legal. The tactical run adds eligible research and changes where it spends Tokens and places defenses. No pending Ranger was fielded. Data in this section is distinct from the Story regression, which also drives deterministic forced narrative branches.

“I” is surviving Integrity. “W” is the last wave reached. Peak counts are simultaneous live enemies in the progressed opening wave.

| Operation | Low before → after | Progressed before → after | Progressed wave-one peak before → after |
| --- | --- | --- | --- |
| C1-01 | Perfect (100 I) → Perfect (100 I) | Perfect (100 I) → Perfect (100 I) | 4 → 5 |
| C1-02 | Clear (4 esc., 60 I) → Clear (4 esc., 60 I) | Perfect (100 I) → Perfect (100 I) | 5 → 6 |
| C1-03 | Clear (5 esc., 50 I) → Clear (5 esc., 50 I) | Perfect (100 I) → Perfect (100 I) | 5 → 5 |
| C1-04 | Clear (4 esc., 60 I) → Clear (4 esc., 60 I) | Perfect (100 I) → Perfect (100 I) | 9 → 9 |
| C1-05 | Perfect (100 I) → Perfect (100 I) | Perfect (100 I) → Perfect (100 I) | 8 → 8 |
| C2-01 | Lost W1 (10 esc.) → Clear (5 esc., 50 I) | Clear (1 esc., 90 I) → Perfect (100 I) | 11 → 6 |
| C2-02 | Clear (9 esc., 10 I) → Clear (3 esc., 70 I) | Clear (1 esc., 90 I) → Perfect (100 I) | 12 → 7 |
| C2-03 | Lost W1 (10 esc.) → Clear (6 esc., 40 I) | Clear (5 esc., 50 I) → Clear (4 esc., 60 I) | 13 → 9 |
| C2-04 | Lost W1 (10 esc.) → Clear (9 esc., 10 I) | Clear (7 esc., 30 I) → Clear (5 esc., 50 I) | 17 → 12 |
| C2-05 | Lost W1 (10 esc.) → Lost W1 (10 esc.) | Clear (4 esc., 60 I) → Clear (1 esc., 90 I) | 12 → 11 |
| C2-06 | Lost W1 (10 esc.) → Lost W1 (10 esc.) | Perfect (100 I) → Perfect (100 I) | 13 → 11 |
| C2-07 | Lost W1 (9 esc.) → Lost W4 (5 esc.) | Lost W4 (3 esc.) → Perfect (20 I) | 15 → 8 |
| C2-08 | Lost W1 (9 esc.) → Lost W1 (7 esc.) | Lost W2 (2 esc.) → Lost W2 (2 esc.) | 15 → 13 |
| C2-09 | Lost W1 (7 esc.) → Lost W1 (7 esc.) | Lost W2 (7 esc.) → Lost W3 (5 esc.) | 20 → 17 |
| C2-10 | Lost W1 (7 esc.) → Lost W1 (7 esc.) | Clear (2 esc., 70 I) → Lost W5 (2 esc.) | 20 → 15 |

### Additional legal loadouts

- The tactical loadout with B13/B05 and more raised cells reserved for Rangers cleared C2-03 at tick 16921 with 72 defeats and zero escapes. The same approach cleared C2-10 at tick 31530 with 140 defeats and zero escapes. With B13/B11 the finale produced a normal clear with 139 defeats, one escape, 85 Integrity and tick 33600.
- C2-07 with the stronger shipped opening cleared naturally at tick 25526 using B13, its supplied Firebreak, normal cost and by targeting near the planned block line. It defeated all 128 enemies with zero escapes and 20 Integrity. A B13/B02 line also cleared at tick 29070 with two escapes and 40 Integrity.
- The tested C2-08 and C2-09 loadouts still lost. An experimental longer opening and slower early groups reached C2-08’s Foreman and later into C2-09, with defeat in both cases. Those extra profiles were left out of the live stages. The longer C2-09 default trial reached wave four with 119 defeats before a fatal result. Zero-escape clears for C2-04 and C2-05 also remain unverified. No blanket reduction to movement, defender damage increase or arbitrary enemy removal was used.

[Before runs](evidence/c30/baseline-policy.jsonl) · [After runs](evidence/c30/tuned-policy.jsonl) · [Tactical runs](evidence/c30/tactical-final.jsonl) · [B11 trials](evidence/c30/tactical-guard-drills.jsonl) · [Pacing experiments](evidence/c30/stronger-pacing-trial.jsonl) · [Additional late-stage trials](evidence/c30/late-exact-trial.jsonl)

## Native rendered evidence

Each capture runner passed 15 checks on the actual launcher and Story field. The 960×540 run uses 130% text. The skill scene was captured with normal Post income and actual melee and skill events.

| View | 1280×720 | 960×540 |
| --- | --- | --- |
| Main menu | [View](c30/1280x720/home.png) | [View](c30/960x540/home.png) |
| Ranger upgrade | [View](c30/1280x720/ranger-upgrade.png) | [View](c30/960x540/ranger-upgrade.png) |
| Facility upgrade | [View](c30/1280x720/facility-upgrade.png) | [View](c30/960x540/facility-upgrade.png) |
| Guard ready, 4/4 | [View](c30/1280x720/skill-ready.png) | [View](c30/960x540/skill-ready.png) |
| Guard attack and HP loss | [View](c30/1280x720/melee-hit.png) | [View](c30/960x540/melee-hit.png) |
| C2-01 opening, 3/4 and charging, Records-locked Scout | [View](c30/1280x720/opening-recharge-and-lock.png) | [View](c30/960x540/opening-recharge-and-lock.png) |

## Regression and Android

Editor import and startup passed. The full pinned suite passed 3,287 checks across 33 runners, including 37 C30 combat checks and 1,048 Campaign Story checks. C1-02 still finishes at tick 8169 with 17 defeated, one escape and 90 Integrity. The former perfect C1-03 deployment order now produces three escapes, and a revised legal order recorded 33 defeated with no escapes at tick 13478. C1-03 defeat was still at tick 7228 and the autonomous normal fixture settled 28 defeated, five escapes and 50 Integrity. The W29 assembled art and menu probes passed 732 and 753 checks. First Contact verified all 56 atlas regions and 76 loaded textures. The W21 ledger passed 1,117 asset records and 116 storyboard mappings.

The ARM64 development APK uses `com.shahrewan.kenyalangrangers.dev`, version code 1, min API 24 and target API 36. Its SHA-256 is `9079fadc406a92101c560f9f979d4bfc75351774902987661e4befb26ba9306c`. It passed v2/v3 signature verification, 16 KiB alignment, exported-resource replay and fresh/C28-D save continuity. ADB listed no physical phone. Android installation, touch, cutouts, readability and frame time are pending.

```sh
python3 -B tools/run_regression.py --logs build/qa/c30/regression
godot --headless --path . --script res://tests/playtest/c30_campaign_playtest.gd
godot --headless --path . --script res://tests/playtest/c30_campaign_playtest.gd -- --tactical C2-03 C2-04 C2-07 C2-08 C2-09 C2-10
godot --path . --audio-driver Dummy --resolution 960x540 \
  --script res://tests/playtest/c30_capture.gd -- "$PWD/build/qa/c30/native/960x540" 960x540 130
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c30-debug.apk
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-c30-debug.apk \
  --first-contact --hold-the-line --narrow-escape --campaign-visuals --combat-balance \
  --previous build/android/kenyalang-rangers-c28-d-debug.apk --logs build/qa/c30/payload
adb install -r build/android/kenyalang-rangers-c30-debug.apk
```

Reproduce the previous balance by copying only the playtest runner into a checkout of `cc2be81` and running it there. Use a compatible signer when updating an installed test package. On a phone, open Story at normal and 130% text. Drag and hold a Ranger, compare the tray’s cooldown with on-field recharge, then pause and resume at 2×. Check stock after a Cabin completes and verify the tray scroll, charge numerals and enemy HP at native screen density. Relaunch offline and confirm the existing local save. [Installation prerequisites](../../export/README.md#install-and-check-on-a-phone)

Runtime and test changes are listed in [PR #37](https://github.com/Shahrewan/Kenyalang-Rangers/pull/37/files). The pacing configuration sits in the ten W13 Chapter 2 stage files, individual cooldowns in the Ranger and Facility resources, and the UI and combat changes in `scenes/menus/main_menu.tscn`, `scripts/ui` and the existing battle scripts.
