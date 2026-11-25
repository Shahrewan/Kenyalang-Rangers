# C32-E · Recurring economy and Chaos score cap

25 November 2026 · Baseline `c2d119c` after PR #44 · Godot `4.7.2.stable.official.ed1daf0bf` · Compatibility

C32-E activates the Chaos cap for new runs. The composer, modifier editor and result show the same effective credit, score and Funds. Both Outreach alternatives and the Garden planning target below are for separate owner review. [Decision record](../canon/DECISION_LOG.md#c32-e-recurring-economy-playtest--2026-11-25)

Implementation `9ece4dd` updates `ChaosScore`, the Chaos composer breakdown and the competitive modifier preview. The existing result and settlement read that score. The test and packaging tools exercise the same routes and compare the legacy score in isolated study profiles.

## Chaos scoring

Let `E` be configured enemy base points. The game credits `min(eligible positive debuff points, max(200, E))`, adds `E`, and applies the full buff and effective slot deductions. The existing qualification and reward rules then use that total. The test suite retains checks for ineligible modifiers, D05 slot removal, all three trophy thresholds, escapes, losses, wallet clipping and failed-save retry. The original 1,350-point Mulu reference still earns 54,000.

| Genuine run | Enemy points | Listed → effective debuff credit | Before score / Funds | After score / Funds | End Integrity · combat tick |
| --- | ---: | ---: | ---: | ---: | ---: |
| T01 · 3 Trespassers across 2 waves, eight debuffs | 30 | 1,100 → 200 | 1,030 / 41,200 | **130 / 2,600** | 100 · 4,151 |
| T02 · 29 enemies across 2 waves, both entries, with Poachers, Drones and Runners | 510 | 900 → 510 | 910 / 18,200 | **520 / 10,400** | 100 · 5,726 |
| T05 · 31 enemies across 2 waves, with Ignition Operators and Heat | 605 | 500 → 500 | 305 / 6,100 | **305 / 6,100** | 90 · 7,410 |
| T01 · 250 Trespassers across 5 waves | 2,500 | 1,100 → 1,100 | 3,200 / 324,000 | **3,200 / 324,000** | 100 · 34,410 |

Each pair used the same legal loadout and modifiers, the real combat clock and no injected damage. The calibration profiles used purchased-spec Lv.100 equipment with original definitions. All four pairs killed every configured enemy and recorded zero escapes. The new three-enemy profile earns a best of 130 and remains unranked. The long route earns all three threshold Facilities. Its 324,000 payout reflects the existing curve. [Exact recipes and outcomes](evidence/c32-e/chaos-challenges.jsonl) · [Combat harness](../../tests/balance/c32_e_chaos_challenges.gd)

The fresh Android-resource replay earned 2,600 and recorded no threshold. A save created by the C32-D APK earned 41,200, the 1,030 best, Tier 1 and Skill Relay Station through the old formula. After the update its next genuine clear paid 2,600 and its wallet rose from 51,200 to 53,800. The earlier best, tier and ownership were present on cold reload. The cap uses the existing save and settlement paths. [Packaged continuity runner](../../tests/release/player_continuity.gd)

| In-game view | 1280×720 at 100% | 960×540 at 130% |
| --- | --- | --- |
| Modifier editor | [PNG](c32-e/1280x720-text100/modifier-cap.png) | [PNG](c32-e/960x540-text130/modifier-cap.png) |
| Configuration, trophy and conditional reward | [PNG](c32-e/1280x720-text100/chaos-cap-preview.png) | [PNG](c32-e/960x540-text130/chaos-cap-preview.png) |
| Actual new-profile combat receipt | [PNG](c32-e/1280x720-text100/chaos-cap-receipt.png) | [PNG](c32-e/960x540-text130/chaos-cap-receipt.png) |

## Outreach and the 60-day budget

| Room level | Installed Best | Middle trial Best | Original proposal Best |
| --- | ---: | ---: | ---: |
| 1 | 25,000 | 25,000 | 25,000 |
| 2 | 60,000 | 60,000 | 60,000 |
| 3 | 110,000 | 90,000 | 75,000 |
| 4 | 180,000 | 125,000 | 90,000 |
| 5 | 300,000 | 175,000 | 110,000 |
| **Five Best answers at Lv.5** | **1,500,000** | **875,000** | **550,000** |

Every alternative retains the five-question limit, question bank, 20-hour refresh, half-Best Acceptable payout, zero Poor payout and quarter-Best Harmful deduction. The model runs each schedule through the same Outreach session and wallet settlement as the game. The alternate values exist only in the test instances. [Prior measured five-answer batches](../qa/C32_D_ECONOMY_REWARDS.md#recurring-income-and-owner-decisions)

The table shows Day 7 / 30 / 60 gross positive Funds in millions. All six scenarios include the C32-D Campaign and Records awards. Modeled Story outcomes are inputs. Chaos results use genuine combat. The accounts use actual eligibility, room gates, purchase quotes, progression and daily save reloads. Casual allows 15 active minutes per day, moderate 30, and the highly active Chaos-regular schedule 75. The C32-D comparison reproduced its recorded checkpoints exactly.

| Economics scenario | Casual | Moderate | Highly active |
| --- | ---: | ---: | ---: |
| C32-D baseline | 0.38 / 5.40 / 12.85 | 1.17 / 11.37 / 21.25 | 4.71 / 23.23 / 37.18 |
| **Live Chaos cap only** | **0.35 / 5.30 / 12.60** | **1.09 / 10.89 / 19.14** | **2.58 / 19.34 / 30.29** |
| Middle Outreach only | 0.38 / 5.36 / 12.61 | 1.17 / 10.72 / 18.14 | 4.68 / 20.56 / 30.57 |
| Original Outreach proposal only | 0.38 / 5.33 / 12.45 | 1.17 / 10.32 / 17.41 | 4.66 / 19.03 / 27.00 |
| Chaos cap + middle Outreach | 0.35 / 5.26 / 12.30 | 1.09 / 10.29 / 17.33 | 2.58 / 17.07 / 24.08 |
| Chaos cap + original Outreach proposal | 0.35 / 5.23 / 12.17 | 1.09 / 9.97 / 16.43 | 2.58 / 15.80 / 20.76 |

[2,160 daily ledger rows](evidence/c32-e/daily.csv) · [108 exact checkpoints across six profiles](evidence/c32-e/checkpoints.csv) · [HQ, unit and activity milestones](evidence/c32-e/progression.jsonl)

Under live Chaos-only tuning, the casual profile funds Mechanical on Day 1 and Control Lv.5 on Day 47. It completes Story on Day 52 and spends 5M on Rangers and 2.39M on Facilities, ending with seven maxed units. The moderate profile completes Story on Day 35 and reaches eight maxed units on Day 49, spending 5M on Rangers, 3M on Facilities and 10.71M on HQ by Day 60. The highly active profile reaches all HQ levels plus eight maxed units and discards zero Funds, versus 2.20M discarded before the cap under the same schedule. The ordinary-only settlement test separately proves the 20,000 Mechanical gate and Control Lv.2–5 affordability without a single perfect award.

**Recommendation for owner review.** Use the middle Outreach table as the next separate trial, pending live participation evidence. With the cap, casual still completes by Day 52 with seven maxed units. Moderate still reaches eight maxed units by Day 57, versus six by Day 60 on the steeper proposal. Highly active gross falls from 30.29M on Chaos-only tuning to 24.08M on the middle schedule, versus 20.76M on the original proposal. The middle schedule therefore trims upper-tier income while retaining more progression room at normal play frequency.

Keep the full 24.16M spend as a stretch target. One supplemental model with the cap and middle Outreach substituted the 250-enemy challenge into the highly active schedule every two days once eligible. Seventeen long clears plus other activities led to 29.28M gross, all eight units at Lv.100 by Day 32 and all HQ levels by Day 48. That check averaged about 13.9 active minutes per day over the model and earned 5.87M from Chaos. It illustrates the impact of longer challenges and does not estimate how often players will choose that route. [Supplemental checkpoint ledger](evidence/c32-e/two-day-mix.jsonl)

## Habitat Restoration recommendation

Rebase the 60-day Garden allocation before changing payouts. The fastest repeat return is Mengaris at 18,000 per 72 hours. Six immediately unlocked plots with continuous cycles could produce at most 2.16M repeat Funds over 60 days. Adding all five one-time milestones gives a generous **4.71M ceiling**, 590,000 under the 5.30M planning assumption, even before unlock time, mixed species and watering gaps. Across the live Chaos-only schedules the measured Garden range was **3.526M–4.318M**, with 4.246M for the moderate profile. Use about **4.2M** as a moderate planning reference and about **3.5M** for casual models. Treat the overall 60-day goal as a range tied to activity mix. Preserve existing Garden participation, timers, species and progression while testing the revised budget. [Restoration rules](../../scripts/data/restoration_rules.gd) · [Source audit and earlier budget](../qa/C32_ECONOMY_AND_PROGRESSION.md#repeatable-income-and-cap)

## Verification and Android

The real one-save Campaign rerun matched all 15 C32-D ledger rows exactly. It cleared 15 missions, spent 4,539,879 from the starting wallet and Campaign receipts, and held 3,355,121 after the finale. The returning C2-07 replay also reproduced its 6,500 payout and recruit. The full regression suite passed **5,096 checks across 41 runners** with import and startup. The main simulation passed **32,355 checks** and the supplemental mix passed **1,171**. The two native sizes passed 21 checks each. W29 catalog and asset verification passed, including 732 assembled-art checks. [Campaign rerun summary](evidence/c32-e/campaign-rerun.jsonl)

```sh
python3 -B tools/run_regression.py --logs build/qa/c32-e/regression
godot --headless --path . --script res://tests/balance/c32_e_chaos_challenges.gd
godot --headless --path . --script res://tests/playtest/c32_d_fresh_campaign.gd
godot --headless --path . --script res://tests/balance/c32_economy.gd -- --daily > build/qa/c32-e/economy.log
python3 -B tools/summarize_c32_economy.py build/qa/c32-e/economy.log build/qa/c32-e/ledgers
godot --headless --path . --script res://tests/balance/c32_economy.gd -- --long-chaos-mix=2
godot --audio-driver Dummy --path . --script res://tests/unit/c32_e_chaos_cap_test.gd -- "$PWD/build/qa/c32-e/native" 960x540 130
```

The signed ARM64 debug APK is `build/android/kenyalang-rangers-c32-e-debug.apk` (40,186,070 bytes). APK Signature Scheme v2/v3 and 16 KiB alignment passed. SHA-256 `988aa87558e72f6f8d606fbe2b086b0d3eb1a539b2c49e7957ccfea1e4591c81`. The packaged resources passed **3,181 host checks** across 16 runners and six save continuity phases. Package ID `com.shahrewan.kenyalangrangers.dev`, min SDK 24 and target SDK 36. Android build tools report the existing themed-icon warning.

```sh
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-c32-e-debug.apk \
  --first-contact --hold-the-line --narrow-escape --campaign-visuals --combat-balance \
  --skill-orbs --ranger-kits --education --facility-growth --ranger-growth \
  --economy-rewards --previous-economy-active --chaos-cap \
  --previous build/android/kenyalang-rangers-c32-d-debug.apk --logs build/qa/c32-e/payload
```

ADB found zero phones. On a backed-up device with the same development signer, use `adb install -r build/android/kenyalang-rangers-c32-e-debug.apk` and launch offline. Open Chaos, configure the T01 three-enemy recipe and verify the 130 score, 200 credited debuff points and 2,600 projected Funds before Start. Win with all three defeated and inspect the credited amount. Repeat at 130% text and on a save that earned Tier 1 under C32-D. Verify the old trophy and Relay remain available after the capped clear and a restart. [USB setup](../../export/README.md)
