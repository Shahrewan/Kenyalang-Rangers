# C32-C · Permanent Ranger upgrade scaling

24 November 2026 · Baseline `e582dc8` after PR #42 · Godot `4.7.2.stable.official.ed1daf0bf` · Compatibility

All 12 playable Rangers now use the existing level pipeline for HP and their active raw damage, healing and repair outputs. Human Resources shows current and target stats, the existing Funds quote and post-purchase balance. These numbers are **reversible trial endpoints pending final owner approval**. [Decision log](../canon/DECISION_LOG.md#c32-c-ranger-growth-trial--2026-11-24)

Implementation `623e9b1` changes the 12 Ranger resources, the shared growth resource and effective-spec pipeline, and the Ranger lines of the upgrade page. The combat runner, native capture runner, Campaign playtest and Android payload checks exercise those changes. Stage content, art and Facility files have no changes.

## Before and after

In the baseline, the Lv.1 values below also applied at every higher purchased level. The GDD pp. 10–11, 20 and 33 gives Lv.1 references and the level formula. C10, C14 and C31-B provide the implemented kit details. The trial uses the original Lv.1 stats and targets about +25% HP and +20% per scaled effect, with integers rounded to nearest, halves up.

| Ranger | HP and raw outputs in order | Lv.1 and baseline Lv.100 | C32-C Lv.20 | Lv.40 | Lv.60 | Lv.80 | Lv.100 |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Scout Sniper | HP · shot · Focus | 100 / 24 / 24 | 105 / 25 / 25 | 110 / 26 / 26 | 115 / 27 / 27 | 120 / 28 / 28 | 125 / 29 / 29 |
| Crowd Controller | HP · basic EMP · Empowered EMP | 120 / 30 / 50 | 126 / 31 / 52 | 132 / 32 / 54 | 138 / 34 / 56 | 144 / 35 / 58 | 150 / 36 / 60 |
| Guard Veteran | HP · basic · Stun prod | 230 / 32 / 46 | 241 / 33 / 48 | 253 / 34 / 50 | 265 / 36 / 51 | 276 / 37 / 53 | 288 / 38 / 55 |
| Patrolman | HP · basic | 320 / 12 | 335 / 12 | 352 / 13 | 368 / 13 | 384 / 14 | 400 / 14 |
| Barricade Ops | HP · basic | 520 / 8 | 545 / 8 | 571 / 9 | 597 / 9 | 624 / 10 | 650 / 10 |
| K9 Ranger | HP · rifle | 230 / 12 | 241 / 12 | 253 / 13 | 265 / 13 | 276 / 14 | 288 / 14 |
| Combat Medic | HP · ordinary heal · treatment | 110 / 24 / 65 | 115 / 25 / 67 | 121 / 26 / 70 | 127 / 27 / 73 | 132 / 28 / 75 | 138 / 29 / 78 |
| Kenyalang Seer | HP · boomerang per target | 120 / 13 | 126 / 14 | 132 / 14 | 138 / 15 | 144 / 15 | 150 / 16 |
| Outpost Mechanic | HP · basic · repair | 140 / 10 / 20 | 147 / 10 / 21 | 154 / 11 / 22 | 161 / 11 / 22 | 168 / 12 / 23 | 175 / 12 / 24 |
| Woods Tracker | HP · basic · net | 100 / 22 / 22 | 105 / 23 / 23 | 110 / 24 / 24 | 115 / 24 / 24 | 120 / 25 / 25 | 125 / 26 / 26 |
| Saboteurist | HP · basic · retreat pulse | 130 / 18 / 20 | 136 / 19 / 21 | 143 / 20 / 22 | 150 / 20 / 22 | 156 / 21 / 23 | 163 / 22 / 24 |
| Strike Team | HP · basic · arrival base · arrival step | 100 / 18 / 80 / 40 | 105 / 19 / 83 / 42 | 110 / 20 / 86 / 43 | 115 / 20 / 90 / 45 | 120 / 21 / 93 / 46 | 125 / 22 / 96 / 48 |

Each configured property interpolates linearly with `(level − 1) / 99` before rounding. Strike Team rounds its base arrival damage and per-rank step separately. Ranks 0/1/2 therefore hit 1/2/3 eligible targets for 80/120/160 each at Lv.1, 83/125/167 at Lv.20 and 96/144/192 at Lv.100. Its timing, costs and escalation cap stay on their existing rules. [Resource catalog](../../data/rangers/c14_campaign_roster.tres) · [Level pipeline](../../scripts/data/deployable_levels.gd)

| Growth fields | Live output |
| --- | --- |
| `hp`, `attack_damage` | Starting combat HP for all 12 and existing basic damage for 11 Rangers. Combat Medic keeps automatic healing. |
| `healing`, `repair` | Combat Medic's automatic healing and Outpost Mechanic's repair. |
| `skill_damage`, `skill_healing` | Focus, Empowered EMP, Stun prod and Emergency Treatment through an independent effective skill resource. |
| `field_damage`, `arrival_damage_step` | Woods Tracker's net, Saboteurist's retreat pulse and Strike Team's three arrival ranks. |

K9's dog still slows and reveals through Howl. Seer's Scan still reveals and marks at +2% damage received per stack. Both remain direct-damage-free. Barricade Ops uses its installed frontal attack. The GDD's proposed Barricade shove and the unspecified Medic heal-interval change are outside this upgrade trial. All deployment costs, target rules, ranges, timing, charges, footprints, status settings and Records enhancements use their existing gameplay sources. [C31-B kit audit](C31_B_RANGER_FIELD_KITS.md) · [Canonical leveling rules](../canon/GAME_RULES.md#headquarters-and-funds)

## Live combat and progression

- The new runner exercised 72 Ranger/level combinations using real combat ticks, damage, healing, repairs, taps and retreats. It compared the immutable authored fields and skills, actual deployment HP and cost, attacks, original timing and the scaled effects. Cases include airborne Scout and Seer targets, Crowd's Technological bonus and EMP, Guard's multi-target stun, K9's rifle and Howl, Medic's automatic and confirmed treatment, Mechanic repairs, Woods net, Saboteurist's timed interference and retreat damage, and all three Strike arrivals.
- Focus and Emergency Treatment require the same Records chapters after purchase. Scout's basic shot against a marked target still receives the separate +25% bonus, and Patrolman still adds the separate +6 counter. Woods adds its flat +10 HP after the permanent curve and retains its Records cooldown reduction.
- A disposable profile with original recruit and Records gates paid 191,001 Funds per Ranger for all 12 Lv.40 tracks and cold-loaded with 707,988 of its starting 3,000,000 Funds. Each paid Lv.40 Ranger deployed in a real Story and Chaos loadout using normal Post payments. The Story tutorial retained the original Lv.1 Scout and Patrolman. C32-B's full Facility growth suite and the original Chaos score, eligibility, settlement and progression suites also ran. [Growth fixtures](../../tests/unit/c32_c_ranger_growth_test.gd) · [C32-B Facility evidence](C32_B_FACILITY_GROWTH.md)

## Campaign balance replay

The progressed C30 autonomous player ran all 15 operations with Lv.1 Rangers on main and again on C32-C. Both JSONL ledgers match exactly, including outcome, recorded deployments, boss phases and resolution ticks. The paid comparison upgrades up to the first three selected, recruit-owned Rangers to Lv.40 through the normal purchase at 191,001 Funds each. It uses a disposable pre-funded wallet and ordinary in-battle Tokens, skill actions and attacks. The runs exercised legal combat outcomes with no scene, clock or enemy tuning in this PR. [Main baseline](evidence/c32-c/campaign-baseline.jsonl) · [C32-C Lv.1 replay](evidence/c32-c/campaign-level-one.jsonl) · [C32-C paid replay](evidence/c32-c/campaign-purchased.jsonl)

The broad policy cleared 13 of 15 with either investment. C2-03 improved from two escapes and 80 Integrity to one and 90. C2-04 went from 73 defeats, two escapes and 80 Integrity to 75, zero and 100. The generic opening failed C1-01 in both cases. It also failed C2-10 with either investment, including a fatal Leader escape in the paid case. The established C28-A scripted player fixtures verified all three real tutorial outcomes, and the targeted finale policy verified both boss phases and a perfect clear. The dedicated C31-C normal and perfect regressions also passed.

| Targeted operation | Policy | Lv.1 defeats / escapes / Integrity · tick | Three Lv.40 purchases | Lv.40 defeats / escapes / Integrity · tick |
| --- | --- | --- | --- | --- |
| C2-08 Breaking the Line | Expanded Heat policy with B02/B07 | 102 / 0 / 60 · 23506 | Guard, Scout, Crowd | 102 / 0 / 60 · 23250 |
| C2-09 Desperate Convoy | Expanded convoy policy with B05/B07 | 138 / 0 / 100 · 25590 | Guard, Scout, Crowd | 138 / 0 / 100 · 25585 |
| C2-10 finale | Tactical legacy selection with B13/B05 | 140 / 0 / 100 · 31530 | Scout, Patrolman, Guard | 140 / 0 / 100 · 31160 |

C2-08 retained four Heat overflows with each loadout. The Foreman phase moved from tick 20191 to 20071. C2-10's phases ran at ticks 22291 and 27529 at Lv.1 and at 22110 and 26661 with purchases. The three targeted clears used the existing unpriced Campaign awards. [Heat before](evidence/c32-c/heat-lv1.jsonl) · [Heat after](evidence/c32-c/heat-lv40.jsonl) · [Convoy before](evidence/c32-c/convoy-lv1.jsonl) · [Convoy after](evidence/c32-c/convoy-lv40.jsonl) · [Finale before](evidence/c32-c/finale-lv1.jsonl) · [Finale after](evidence/c32-c/finale-lv40.jsonl)

## Human Resources gallery

The actual Headquarters screens show Lv.20 → Lv.100. The 939,904 Funds quote leaves 260,096 from a 1,200,000 Funds wallet.

| Ranger | 1280×720 · 100% text | 960×540 · 130% text |
| --- | --- | --- |
| Scout Sniper | [PNG](c32-c/1280x720-text100/scout_sniper.png) | [PNG](c32-c/960x540-text130/scout_sniper.png) |
| Combat Medic | [PNG](c32-c/1280x720-text100/combat_medic.png) | [PNG](c32-c/960x540-text130/combat_medic.png) |
| Outpost Mechanic | [PNG](c32-c/1280x720-text100/outpost_mechanic.png) | [PNG](c32-c/960x540-text130/outpost_mechanic.png) |
| Woods Tracker | [PNG](c32-c/1280x720-text100/woods_tracker.png) | [PNG](c32-c/960x540-text130/woods_tracker.png) |
| Strike Team | [PNG](c32-c/1280x720-text100/strike_team.png) | [PNG](c32-c/960x540-text130/strike_team.png) |

## Reproduce

```sh
python3 -B tools/run_regression.py --logs build/qa/c32-c/regression
python3 -B tools/build_w29_art_catalog.py --check
python3 -B tools/build_campaign_visual_data.py --check
godot --headless --path . --script res://tests/art/w29_pack_probe.gd
godot --audio-driver Dummy --path . --script res://tests/playtest/c32_c_capture.gd -- "$PWD/build/qa/c32-c/1280x720" 1280x720 100
godot --audio-driver Dummy --path . --script res://tests/playtest/c32_c_capture.gd -- "$PWD/build/qa/c32-c/960x540" 960x540 130
```

```sh
godot --headless --path . --script res://tests/playtest/c30_campaign_playtest.gd -- --tactical --expanded-rangers
godot --headless --path . --script res://tests/playtest/c30_campaign_playtest.gd -- --tactical --expanded-rangers --ranger-level=40
godot --headless --path . --script res://tests/playtest/c30_campaign_playtest.gd -- --tactical --expanded-rangers --policy=heat --buffs=B02,B07 --ranger-level=40 C2-08
godot --headless --path . --script res://tests/playtest/c30_campaign_playtest.gd -- --tactical --expanded-rangers --policy=convoy --buffs=B05,B07 --ranger-level=40 C2-09
godot --headless --path . --script res://tests/playtest/c30_campaign_playtest.gd -- --tactical --buffs=B13,B05 --ranger-level=40 C2-10
```

Use `--ranger-level=1` for the matching targeted baseline. Pinned Godot import and startup passed. The full regression passed **4,877 checks across 40 runners**, including 526 new Ranger checks, 607 Facility checks, 260 HQ progression checks, 94 Chaos rules checks, 43 Chaos UI checks and 11 C31-C late Campaign checks. W29 catalog and registration validation passed with 732 art checks. Both native capture sizes passed 10 checks each. The X11 renderer reported that it could not switch VSync mode.

## Android

The signed ARM64 debug APK `build/android/kenyalang-rangers-c32-c-debug.apk` is 40,181,974 bytes and passed v2/v3 signing and 16 KiB alignment. SHA-256 `1be589fb913dcc8028beb5787f132b44a11e6f292ed3619d364c738cc5a78639`. Package `com.shahrewan.kenyalangrangers.dev`, min SDK 24, target SDK 36. Android build tools reported the existing themed-icon warning.

```sh
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-c32-c-debug.apk \
  --first-contact --hold-the-line --narrow-escape --campaign-visuals --combat-balance \
  --skill-orbs --ranger-kits --education --facility-growth --ranger-growth \
  --previous build/android/kenyalang-rangers-c32-b-debug.apk --logs build/qa/c32-c/payload
```

The exported resources booted on the host and passed **3,120 checks across 15 runners and six save-continuity phases**. The C32-B APK seed bought Scout Lv.20 and left 239,904 Funds. C32-C loaded it as 105 HP and 25 damage, with Focus still Records-locked. A further purchase persisted Lv.40, 110 HP, 26 damage and 108,999 Funds. The C32-B Post continuity track passed in the same run.

ADB found no attached phone. With a backed-up test profile and matching development signer, run `adb install -r build/android/kenyalang-rangers-c32-c-debug.apk` and start offline. In landscape, use Human Resources at 100% and 130% text. Cancel a milestone quote, confirm it, then restart and verify the saved level and remaining Funds. Deploy the Ranger in Story and Chaos and check the output against the preview. Use a Records-earned and a locked Scout or Medic to check skill availability, and verify Strike Team's two-cell placement and arrival in combat. [USB setup](../../export/README.md)
