# C31-C · Late Campaign and player education

Baseline `e65c92033` is main after PR #39. Godot `4.7.2.stable.official.ed1daf0bf` and matching Android templates were used. The Campaign content diff contains only C2-08 and C2-09 pacing and Heat fields. The original enemy queues, routes, units, dialogue, boss data, rewards and save schema remain compatible.

## C2-08 Breaking the Line

| Effective stage setting | C31-B baseline | C31-C |
| --- | --- | --- |
| Preparation | 20 s · first spawn tick 1201 | 36 s · first spawn tick 2161 |
| Arrivals by wave | 2.25 / 1.875 / 1.65 / 1.50 s | 2.80 / 2.15 / 1.70 / 1.50 s |
| Stage Heat gain | 1.00× | 0.32× |
| Heat capacity and overflow loss | 100 Heat · 10 Integrity | 100 Heat · 10 Integrity |

C31-B reached the Foreman with 101 defeats and zero escapes. Ten overflows still ended the run. D14 adds 30% Heat gain. With B02's −25%, the effective multiplier is 1.05× on the original stage and 0.336× on the tuned stage. The Foreman produces 3.36 Heat/s on the latter plan, rising to 4.704 Heat/s in its phase. The existing 65% trigger, five-second 600 HP shield and ordinary 50-Integrity alternate escape remain in the boss data. The progressed perfect run's four overflow ticks were 18642, 20360, 21636 and 22912. It kept 60 Integrity after defeating the Foreman at tick 23506. [Before](evidence/c31-c/baseline-heat.jsonl) · [After](evidence/c31-c/after-heat.jsonl) · [C31-B baseline report](C31_B_RANGER_FIELD_KITS.md)

| Trial | Low | Progressed | Advanced |
| --- | --- | --- | --- |
| Shipped, already-owned equipment | Normal · 101 defeated, 1 escaped, 40 Integrity, 5 overflows | Perfect · 102/0, 60 Integrity, 4 overflows | Perfect · 102/0, 50 Integrity, 5 overflows |
| Experimental permanent Beacon, original Heat gain | Loss · 100/1, 9 overflows | Loss · 63/6, 4 overflows | Loss · 101/0, 10 overflows |
| Experimental permanent Beacon, 0.55× Heat gain | Normal · 101/1, 10 Integrity, 8 overflows | Loss · 95/6, 4 overflows | Perfect · 102/0, 10 Integrity, 9 overflows |

The experimental runner cleared C2-07 with 126 defeats, two escapes and 40 Integrity, then awarded the Beacon through the existing Campaign completion and ownership path. C2-08 bought and built it normally for 30 Tokens and six seconds. Reserving Tokens after four fighters delayed the Beacon until 86 s on the low plan and 80 s on the progressed and advanced plans. Its existing 0.6× Heat multiplier mattered once built, and the cost and slot made the opening less forgiving. With 0.55× stage Heat, the normal and perfect outcomes still finished at 10 Integrity. The shipped option had more margin in all three tested profiles and works with the normal C2-07 mission supply expiring. **Permanent Firebreak recruitment remains an owner decision.** [Beacon with original Heat](evidence/c31-c/beacon-earned.jsonl) · [Beacon with 0.55× Heat](evidence/c31-c/beacon-shared.jsonl) · [D-009 proposal](../production/w25/PROPOSALS.md)

## C2-09 Desperate Convoy

Preparation changed from 22 to 52 s, moving the first arrival from tick 1321 to 3121. First-to-last arrival spacing changed from 1.65 / 1.375 / 1.21 / 1.10 s to 3.80 / 2.80 / 2.20 / 1.50 s. This gives the convoy an opening with four Rangers on the progressed test plan. Its free Lv.30 Post starts at (1,0), with K9 at (4,3) at tick 1200, Guard at (3,3) at 1800, Scout at (5,4) at 2400 and another K9 at (5,3) at 3000. The named cells use zero-based board coordinates. The played progressed strategy went from a peak of 14 active enemies before losing wave one to peaks of 3/3/4/6 across a full clear. The final wave's 1.50 s is 2.53 times faster than the revised opening. All 42 final-wave enemies still arrive, including the fatal E15 escape threat. [Before](evidence/c31-c/baseline-convoy.jsonl) · [After](evidence/c31-c/after-convoy.jsonl)

| Profile | Normal clear | Perfect clear |
| --- | --- | --- |
| Low | 132 defeated, 6 escaped, 10 Integrity · tick 25744 | 138/0, 100 Integrity · tick 25680 |
| Progressed | 134/4, 40 Integrity · tick 26530 | 138/0, 100 Integrity · tick 25590 |
| Advanced | 134/4, 40 Integrity · tick 26250 | 138/0, 100 Integrity · tick 26610 |

The normal fixture banks Tokens and builds Posts before buying its first Ranger at or after 80 s. The advanced perfect uses an exit-side hold and B14/B07. The progressed and low perfect plans use the forward hold. The advanced version of that forward hold still loses to an E15 escape in wave three. The advanced exit-side clear uses 176 skills and two tactical retreats. The ordinary and perfect wins use legal deployments, normal Post payments, real attacks and every combat clock tick. [Later opening](evidence/c31-c/normal-convoy-80.jsonl) · [Advanced formation](evidence/c31-c/after-convoy-advanced.jsonl)

The runner uses prior Campaign grants, room gates, the real loadout planner and Lv.1/30/50 Posts. Each win settles through Campaign progression. Both late missions credited zero Funds under their pending first-clear and first-perfect values. This held for the Beacon alternative too. C2-07 reran as a normal clear with 126/2 and 40 Integrity at tick 29070, and C2-10 reran as a perfect with 140/0 and 100 Integrity at tick 31530. The same scoped balance data leaves all Chaos routes on their existing definitions. [Adjacent runs](evidence/c31-c/adjacent-final.jsonl)

## Outreach and Records

Revision 2 loads 20 W18 Outreach scenarios, all four ten-question Records chapters, 20 facts and 34 sources. Outreach uses the existing 20-hour batch rotation, four graded options, explanations and normal Funds settlement. Records uses 15 seconds per question with a visible timer, pause/resume, offline article links and replay. The first correct answer uses the GDD trial amount of 30,000 Funds. The perfect chapter earns its named enhancement and shows the separately pending bonus.

The supplied *Latest_rhinoceros_hornbill_quiz.pdf* contributes Q2 and Q19 adaptations for the Sarawak state bird and typical clutch size. They are attributed to the official sources in the runtime register. It also supports overlapping W18 subjects such as species name, casque and tail markings. The remaining Records questions and all Outreach scenarios come from the W18 documentation. The runtime contains enough questions for both modes. [Runtime banks](../../data/education/README.md) · [W18 provenance](../production/W18_EDUCATION_BANKS.md)

## Native evidence

Each size uses the real launcher and Story screens with legal combat. The 960×540 set uses 130% text.

| View | 1280×720 | 960×540 |
| --- | --- | --- |
| C2-08 opening | [PNG](c31-c/1280x720/c2-08-opening.png) | [PNG](c31-c/960x540/c2-08-opening.png) |
| Foreman phase | [PNG](c31-c/1280x720/c2-08-foreman-phase.png) | [PNG](c31-c/960x540/c2-08-foreman-phase.png) |
| C2-08 perfect | [PNG](c31-c/1280x720/c2-08-result.png) | [PNG](c31-c/960x540/c2-08-result.png) |
| C2-09 opening | [PNG](c31-c/1280x720/c2-09-opening.png) | [PNG](c31-c/960x540/c2-09-opening.png) |
| C2-09 perfect | [PNG](c31-c/1280x720/c2-09-result.png) | [PNG](c31-c/960x540/c2-09-result.png) |
| Outreach question | [PNG](c31-c/1280x720/outreach.png) | [PNG](c31-c/960x540/outreach.png) |
| Outreach feedback | [PNG](c31-c/1280x720/outreach-feedback.png) | [PNG](c31-c/960x540/outreach-feedback.png) |
| Records archive | [PNG](c31-c/1280x720/records.png) | [PNG](c31-c/960x540/records.png) |
| Records timed question | [PNG](c31-c/1280x720/records-question.png) | [PNG](c31-c/960x540/records-question.png) |
| Records perfect chapter | [PNG](c31-c/1280x720/records-result.png) | [PNG](c31-c/960x540/records-result.png) |

## Verification

Editor import, startup and **3,430 checks across 37 runners** passed. This includes 11 deterministic late-Campaign checks, 18 installed education checks, 1,048 existing Story checks, 94 Chaos rules checks and 43 Chaos UI checks. Each native size passed 22 Campaign and 23 education checks. W29 catalog, Campaign registration, 732 assembled-art checks, and the W18 and W21 inventories passed.

The signed ARM64 debug APK passed v2/v3 signature verification, 16 KiB alignment, host startup, extracted-resource tests and fresh and C31-B returning save runs. The returning save opened the newly installed education activities and retained the existing wallet, room levels and Garden state. SHA-256 `84851c5684576183dbe8992b743f8096c1bdde297e7595c2984188fabc0ba778`.

## Reproduction

```sh
python3 -B tools/run_regression.py --logs build/qa/c31-c/verified-regression
godot --headless --path . --script res://tests/playtest/c30_campaign_playtest.gd -- \
  --tactical --expanded-rangers --policy=heat --buffs=B02,B07 --three-tiers C2-08
godot --headless --path . --script res://tests/playtest/c30_campaign_playtest.gd -- \
  --tactical --expanded-rangers --policy=heat --heat=0.55 --buffs=B02,B07 --three-tiers --trial-firebreak-award C2-08
godot --headless --path . --script res://tests/playtest/c30_campaign_playtest.gd -- \
  --tactical --expanded-rangers --policy=convoy --buffs=B05,B07 --three-tiers C2-09
godot --headless --path . --script res://tests/playtest/c30_campaign_playtest.gd -- \
  --tactical --expanded-rangers --policy=convoy --buffs=B05,B07 --hold-rangers=80 --three-tiers C2-09
godot --headless --path . --script res://tests/playtest/c30_campaign_playtest.gd -- \
  --tactical --expanded-rangers --policy=convoy-late --buffs=B14,B07 --three-tiers C2-09
godot --headless --path . --script res://tests/playtest/c30_campaign_playtest.gd -- --tactical C2-07 C2-10
godot --audio-driver Dummy --path . --script res://tests/unit/c31_c_campaign_test.gd -- \
  "$PWD/build/qa/c31-c/native/960x540" 960x540 130
godot --audio-driver Dummy --path . --script res://tests/unit/c31_c_education_test.gd -- \
  "$PWD/build/qa/c31-c/native/960x540" 960x540 130
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c31-c-debug.apk
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-c31-c-debug.apk \
  --first-contact --hold-the-line --narrow-escape --campaign-visuals --combat-balance --skill-orbs \
  --ranger-kits --education --previous build/android/kenyalang-rangers-c31-b-debug.apk --logs build/qa/c31-c/payload
```

Physical Android checks are pending. ADB found no attached hardware. With a returning test profile, use `adb install -r build/android/kenyalang-rangers-c31-c-debug.apk`. In airplane mode, verify Outreach submit/reopen, Records timeout/resume and chapter receipt, both mission openings, and Heat and skill-orb legibility at 130% text.
