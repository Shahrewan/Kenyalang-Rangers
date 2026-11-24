# C32-B · Facility upgrade scaling

24 November 2026 · Baseline `66cc5b8` after PR #41 · Godot `4.7.2.stable.official.ed1daf0bf` · Compatibility

Implementation and fixtures are in `2407d80`. The runtime changes are the 13 `data/facilities/*.tres` definitions, `DeployableGrowth`, `DeployableLevels` and `DeployableUpgradePage`. The validation changes are the six-level combat runner, Mechanical capture runner, Sonic regression and APK replay tools.

Mechanical now shows current and target HP and the main output for all 13 Facilities, plus the exact cost and post-purchase balance when affordable. The campaign and Chaos planners pass the same effective stats to the field. These endpoints are reversible **trial tuning**. [D-007 decision](../canon/DECISION_LOG.md#c32-b-facility-growth-trial--2026-11-24)

## Before and after

Each stat pair is **HP / main output**. In the baseline, all six checkpoints used the Level 1 pair for every Facility except the Logistics Post. Its original 10-to-15 Token curve already applied and remains identical at all levels.

| Facility | Main output | Baseline Lv.100 | Lv.1 | Lv.20 | Lv.40 | Lv.60 | Lv.80 | Lv.100 |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Logistics Post | Tokens / 10 s, average | 160 / 15 | 160 / 10 | 168 / 10.96 | 176 / 11.97 | 184 / 12.98 | 192 / 13.99 | 200 / 15 |
| Medic Cabin | HP / kit | 170 / 65 | 170 / 65 | 178 / 67 | 187 / 70 | 196 / 73 | 204 / 75 | 213 / 78 |
| Skill Relay Station | s removed / skill recharge pulse | 190 / 3 | 190 / 3 | 199 / 3.12 | 209 / 3.24 | 219 / 3.36 | 228 / 3.48 | 238 / 3.6 |
| Dispatch Relay | s removed / deployment cooldown pulse | 200 / 3 | 200 / 3 | 210 / 3.12 | 220 / 3.24 | 230 / 3.36 | 240 / 3.48 | 250 / 3.6 |
| Sonic Turret | damage / pulse | 250 / 12 | 250 / 12 | 262 / 12 | 275 / 13 | 288 / 13 | 300 / 14 | 313 / 14 |
| Electric Pulse Turret | base damage / hit | 300 / 15 | 300 / 15 | 314 / 16 | 330 / 16 | 345 / 17 | 360 / 17 | 375 / 18 |
| Canopy Defense Launcher | base damage / shot | 380 / 34 | 380 / 34 | 398 / 35 | 417 / 37 | 437 / 38 | 456 / 40 | 475 / 41 |
| Sentry Tower | detection radius in tiles | 420 / 4 | 420 / 4 | 440 / 4 | 461 / 4 | 483 / 5 | 504 / 5 | 525 / 5 |
| Firebreak Beacon | Heat generation reduction % | 220 / 40 | 220 / 40 | 231 / 42 | 242 / 43 | 253 / 45 | 264 / 46 | 275 / 48 |
| Specialist Calltower | Token discount / claim | 240 / 8 | 240 / 8 | 252 / 8 | 264 / 9 | 276 / 9 | 288 / 10 | 300 / 10 |
| Ranger Coordination Hub | attack-rate bonus % | 270 / 25 | 270 / 25 | 283 / 26 | 297 / 27 | 311 / 28 | 324 / 29 | 338 / 30 |
| Reinforced Cover Station | incoming damage reduction % | 330 / 25 | 330 / 25 | 346 / 26 | 363 / 27 | 379 / 28 | 396 / 29 | 413 / 30 |
| Disruption Beacon | enemy outgoing damage reduction % | 330 / 20 | 330 / 20 | 346 / 21 | 363 / 22 | 379 / 22 | 396 / 23 | 413 / 24 |

[Facility resource catalog](../../data/facilities/catalog.tres)

The endpoints in `DeployableGrowth` write the following effective fields. All 13 set `hp` → `max_hp`. The Logistic Token output stays in `LogisticsRules.post_yield_numerator()`, with fractional carry in `DeploymentState`.

| Growth field | Effective field | Facilities |
| --- | --- | --- |
| `healing` | `heal_per_kit` | Medic Cabin |
| `cooldown_reduction_seconds` | `cooldown_reduction_seconds` | Skill Relay Station, Dispatch Relay |
| `attack_damage` | `attack_damage` | Sonic Turret, Electric Pulse Turret, Canopy Defense Launcher |
| `detection_radius` | `detection_radius` | Sentry Tower |
| `heat_slow_percent` | `heat_slow_percent` | Firebreak Beacon |
| `discount_tokens` | `discount_tokens` | Specialist Calltower |
| `attack_rate_bonus_percent` | `attack_rate_bonus_percent` | Ranger Coordination Hub |
| `incoming_reduction_percent` | `incoming_reduction_percent` | Reinforced Cover Station |
| `outgoing_reduction_percent` | `outgoing_reduction_percent` | Disruption Beacon |

The effective spec uses `x = (level - 1) / 99`. Integer values round once with `roundi`, so small integer outputs can hold steady for several levels. Relay seconds keep full precision until the existing clock converts them to ticks. For example, the six relay values remove 180, 187, 195, 202, 209 and 216 ticks per pulse. Mechanical rounds seconds and average Tokens to two decimal places. Fractional Token yield carries over to subsequent payouts. [Level calculation](../../scripts/data/deployable_levels.gd) · [Post yield](../../scripts/data/logistics_rules.gd)

## Runtime checks

- All 78 Facility/level combinations exercised live deployment, authored price, original build duration, type cooldown and occupied cells. Siege reduced the scaled HP, and ordinary fire was rejected. The independent effective spec kept every other authored field. The first normal Post stayed free and instant.
- Three Post payouts verified exact carry under B15. Medic Cabin waited for construction and the shared clock, then applied the confirmed kit to an injured Ranger. Skill Relay shortened a real spent charge. Dispatch Relay shortened already-modified Ranger and Facility cooldowns under B15.
- Sonic reduced ground HP without touching aerial targets and retained slow. Electric preserved the three-hit burst and the Technological bonus. Canopy prioritized aerial targets, kept its splash radius and applied the original 0.5× ground damage. Sentry revealed concealed enemies at the scaled boundary and retained clearance and its mounted Scout's extra range tile.
- Firebreak slowed actual Heat at 2× with B02. Two Firebreaks used the strongest active slowdown. Calltower consumed one scaled discount on a successful Specialist deployment. Coordination changed the ticks between real hits under B06. Cover and Disruption reduced actual incoming hits. With B11, Cover and Disruption stacked on a blocked 100-damage attack to deal 47 HP. Disruption kept its one-second ability delay.
- Mechanical required ownership and a built room before the 1,000,000 Funds upgrade. A cold-loaded Story and Chaos plan used the purchased Lv.100 Sonic at 313 HP, against 250 HP at Lv.1. Chaos eligibility, configured enemy count and score matched with and without this upgrade. The live C2-07 planner used the 220 HP, 40% Lv.1 supply even on a fixture save that already owned a Lv.100 Beacon. The live Campaign still grants Firebreak only as mission supply.
- The C31-C regression completed all four original legal outcomes. C2-08 cleared normally with one escape and five Heat overflows and cleared perfectly with 102 defeats. C2-09 cleared normally with six escapes and 10 Integrity and perfectly with 138 defeats, zero escapes and 100 Integrity. The Foreman and fatal E15 escape checks also passed. Existing Chaos settlement tests cover qualifying clears, score thresholds, unlocks and payout. [C32-B fixture](../../tests/unit/c32_b_facility_growth_test.gd) · [C31-C fixture](../../tests/unit/c31_c_campaign_test.gd) · [Chaos rules](../../tests/unit/chaos_rules_test.gd)

## Mechanical gallery

These captures run the actual Headquarters → Mechanical → Facility page with a disposable Lv.20 profile. Selecting Lv.100 costs 939,904 Funds and leaves 260,096 from 1,200,000.

| Facility | 1280×720 · 100% text | 960×540 · 130% text |
| --- | --- | --- |
| Logistics Post | [PNG](c32-b/1280x720-text100/logistics_post.png) | [PNG](c32-b/960x540-text130/logistics_post.png) |
| Electric Pulse Turret | [PNG](c32-b/1280x720-text100/electric_pulse_turret.png) | [PNG](c32-b/960x540-text130/electric_pulse_turret.png) |
| Skill Relay Station | [PNG](c32-b/1280x720-text100/skill_relay_station.png) | [PNG](c32-b/960x540-text130/skill_relay_station.png) |
| Disruption Beacon | [PNG](c32-b/1280x720-text100/disruption_beacon.png) | [PNG](c32-b/960x540-text130/disruption_beacon.png) |

## Reproduce

```sh
python3 -B tools/run_regression.py --logs build/qa/c32-b/regression
python3 -B tools/build_w29_art_catalog.py --check
python3 -B tools/build_campaign_visual_data.py --check
godot --headless --path . --script res://tests/art/w29_pack_probe.gd
godot --audio-driver Dummy --path . --script res://tests/playtest/c32_b_capture.gd -- "$PWD/build/qa/c32-b/1280x720" 1280x720 100
godot --audio-driver Dummy --path . --script res://tests/playtest/c32_b_capture.gd -- "$PWD/build/qa/c32-b/960x540" 960x540 130
```

Pinned editor import and startup passed, with **4,351 checks across 39 regression runners**, including 607 C32-B, 94 Facility combat, 260 HQ progression, 134 HQ UI, 94 Chaos rules, 43 Chaos UI and 11 C31-C Campaign checks. W29 catalog and registrations passed, with **732** additional art checks. Native Linux rendering passed eight checks at each size. The X11 software renderer reported that VSync switching is unavailable. C32's QA CSVs are excluded from Godot import by their local `.gdignore`.

## Android

The signed ARM64 debug APK is `build/android/kenyalang-rangers-c32-b-debug.apk`, 40,177,878 bytes. APK Signature Scheme v2/v3 and 16 KiB alignment passed. SHA-256 `1fec06308ff302c840eb31af02099ca216c666377ce6517f176f3ba620268d58`. Android build tools report the same themed-icon warning in C31-C and C32-B. The app ID is `com.shahrewan.kenyalangrangers.dev` with min SDK 24 and target SDK 36.

```sh
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-c32-b-debug.apk \
  --first-contact --hold-the-line --narrow-escape --campaign-visuals --combat-balance \
  --skill-orbs --ranger-kits --education --facility-growth \
  --previous build/android/kenyalang-rangers-c31-c-debug.apk --logs build/qa/c32-b/payload
```

The exported resources booted on the host and passed **2,584 checks** across 14 runners and six save-continuity phases. Both the current and C31-C APK seeded a profile through paid Mechanical and Lv.20 Post purchases. The new APK loaded 219,904 Funds and an effective 168 HP, then saved a further upgrade. The next launch read Lv.40, 176 HP and 88,999 Funds.

ADB reported zero devices. On a backed-up test phone with the same development signer, run `adb install -r build/android/kenyalang-rangers-c32-b-debug.apk` and launch offline. In landscape, open Mechanical at 100% and 130% text. Compare current and target stats, cancel a quote, then confirm a purchase and relaunch to verify the paid level and Funds. Deploy the purchased Facility in Story and Chaos and test its actual effect. Check that a C2-07 attempt still supplies the Lv.1 Beacon. [USB setup and troubleshooting](../../export/README.md)
