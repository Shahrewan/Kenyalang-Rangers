# C35 · Chapter 1 and Headquarters onboarding

26 November 2026 · Baseline `c6ac43b` (C34 / PR #47) · Implementation `446be75` · Godot `4.7.2.stable.official.ed1daf0bf`

The owner reported that the prior APKs were working on the phone. This pass teaches the existing combat and Headquarters controls. Story planning puts the lesson first, the battle coach is on by default, and Pause → Controls repeats the lesson. Players can skip normal story beats as before and turn off the live coaching from the plan. The coach reads the live field, placement rules and combat clock. It creates no new waits, pauses, victory gates or save data.

## Chapter 1 lessons

| Operation | Guidance and live cues |
| --- | --- |
| C1-01 First Contact | The coach marks the free Logistics Post's two raised tiles, shows how many Tokens are needed for the next unit, then marks Scout and Patrolman placements. It explains attack coverage, Face left → Deploy, enemy entry and exit, HP, Integrity, pause and perfect clears. A successful clear offers a direct link to Mechanical while it is unbuilt. |
| C1-02 Hold the Line | The lesson links to Mechanical and explains how to equip the ordinary Post. It covers other Facilities, construction and cancellation, overlapping fire, block limits, Enemy Intel and recovering from an escape. |
| C1-03 Narrow Escape | The lesson covers healing range, the skill orb, charge and recharge, aiming and confirming a skill, Records locks, Retreat and shared deployment cooldown. The battle coach recognizes ready and aimed skills. The messenger uses the existing story event. |
| C1-04 Watch the Ridge | After C1-03, the result links to Control Room while Level 2 is still required. The lesson combines blocking, damage and healing, covers two-cell facing, explains fixed effects and optional buffs, and identifies Rifle Spotters and Shield Carriers. |
| C1-05 Operation: Full Pivot | The lesson explains the 120-Token Fixed Stockpile without Posts, budgeting for replacements, the Captain's reinforcements, capture and fatal escape, plus the threat tags used in Chapter 2. |

Headquarters has a five-step **HQ tutorial** with links to Mechanical, Control Room, Human Resources, Finance and Records. It explains room access, equipment and permanent upgrades, Funds versus combat Tokens, research and side activities. Room actions open the existing purchase screens and still require the regular confirmation.

## Pacing and actual combat

The table gives seconds between resolved waves and the next wave's first spawn. Final-wave rest is zero throughout. Opening prep, spawn intervals within a wave, enemy counts, routes, modifiers, skills, cooldowns, rewards, unlocks and Chapter 2 are unchanged. The resolution ticks below are measured in the same fresh-profile Campaign fixture at 60 combat ticks per second.

| Operation | Inter-wave seconds, old → new | Resolution tick, old → new | Defeated / escaped / Integrity | Funds |
| --- | --- | --- | --- | --- |
| C1-01 | 25 → 18 | 8,692 → 8,272 | 14 / 0 / 100 | 15,000 |
| C1-02 | 25 → 18 | 8,169 → 7,749 | 17 / 1 / 90 | 30,000 |
| C1-03 | 25 → 18 | 12,899 → 12,179 | 28 / 5 / 50 | 60,000 |
| C1-04 | 22 → 16 | 13,456 → 12,361 | 36 / 0 / 100 | 140,000 |
| C1-05 | 22 → 16 | 14,700 → 13,980 | 35 / 0 / 100 | 240,000 |

All 15 operations cleared using live combat and legitimate purchases on one fresh save in `tests/playtest/c32_d_fresh_campaign.gd`. All ten Chapter 2 resolution ticks and outcomes matched the C34 fixture. The Campaign awarded **7,885,000 Funds** and the finished wallet held **3,355,121** after purchases, matching the C34 run. The dedicated First Contact touch regression also completes the actual suggested formation and credits **15,000 Funds**. The existing C28 tests passed their First Contact, Hold the Line and Narrow Escape scenarios, including perfect, ordinary and failed outcomes where covered.

## Rendered evidence

| Layout | Godot window captures |
| --- | --- |
| 960×540, 130% text | [Story lesson](c35/story-lesson-960.png) · [First placement prompt](c35/starter-placement-960.png) |
| 1280×720, 100% text | [Taught formation in active combat](c35/defending-the-bend-1280.png) · [HQ tutorial](c35/headquarters-tour-1280.png) |
| 1200×540, 130% text | [First Contact briefing](c35/briefing-1200.png) · [Gold tiles during a Post drag](c35/drag-preview-1200.png) |

The rendered runs use Compatibility on Linux, with synthetic touchscreen events for navigation. The C35 test uses the normal deployment transaction to check coach state and the resulting clear. C34 still exercises native touch-event sequences for deployment, facing, cancellation and repeated placements. Phone touch and novice comprehension remain pending for C35.

## Run the checks

```sh
python3 -B tools/run_regression.py --logs build/qa/c35/acceptance-source
godot --headless --path . --script res://tests/playtest/c32_d_fresh_campaign.gd
godot --headless --path . --script res://tests/art/w29_pack_probe.gd
python3 -B tools/build_w29_art_catalog.py --check
python3 -B tools/build_campaign_visual_data.py --check
godot --audio-driver Dummy --path . --script res://tests/unit/c35_onboarding_test.gd -- 960x540 130 "$PWD/build/qa/c35/native/960x540"
```

The pinned editor import and boot passed with 5,846 checks across 49 regression runners. The W29 checker passed 732 art checks and both data validators matched their approved receipts. The C35 runner passed 47 headless checks and 51 at each rendered size, including navigation, tile targets, pause and countdown, the actual taught clear, and both room-link routes. The 1200×540 native deployment run passed 141 checks. Logs are under `build/qa/c35`.

## Android candidate

`build/android/kenyalang-rangers-c35-debug.apk` uses the existing `com.shahrewan.kenyalangrangers.dev` identity and debug certificate. SHA-256 `d4656b72299b8834a8a3940e0e29249a3b8ac89499dfba371fd85a6582655293`. The ARM64 package passed v2/v3 signing and 16 KiB alignment checks. The shipped Godot pack booted and passed 3,930 checks across 30 runs, including fresh and returning C34 saves. No Android device was connected for this milestone. [Verification steps on a physical phone](../../export/README.md#c35-chapter-1-and-headquarters-onboarding)

```sh
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-c35-debug.apk \
  --previous build/android/kenyalang-rangers-c34-debug.apk \
  --first-contact --hold-the-line --narrow-escape --campaign-visuals \
  --combat-balance --skill-orbs --ranger-kits --education \
  --facility-growth --ranger-growth --economy-rewards --previous-economy-active \
  --chaos-cap --previous-chaos-capped --production-presentation --android-stabilization \
  --onboarding --logs build/qa/c35/acceptance-payload
```
