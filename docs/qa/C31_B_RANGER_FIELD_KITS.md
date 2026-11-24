# C31-B · Remaining Ranger field kits

Baseline `260d06e` includes C31-A / PR #38. Implementation commit `de7f517` is on `feature/c31-b-ranger-field-kits`. Verified with Godot `4.7.2.stable.official.ed1daf0bf` and matching Android templates. The five kits use the existing ownership, leveling and battle economy. The W29 art and animation contracts, enemy resources, mission resources, Funds rules and save schema stayed intact.

| Ranger | Recruited after | Live behavior |
| --- | --- | --- |
| Woods Tracker | C1-04 | The 22-HP net targets the highest-Danger visible ground enemy and immobilizes nearby ground enemies. A successful net qualifies a manual withdrawal for a refund and type cooldown reduction. The existing Records chapter improves Tracker HP and redeploy time. |
| K9 Ranger | C2-01 | One ground cell and one block, with a ranged tranquilizer. The mirrored dog attaches to the Ranger and occupies no extra cell. Howl slows and reveals with zero HP damage. |
| Kenyalang Seer | C2-03 | Elevated boomerang hits aerial targets and can bounce to two distinct neighbors. Scan reveals and applies up to ten +2% incoming-damage marks. |
| Saboteurist | C2-05 | Attacks Technological enemies. Expanding interference suppresses their attacks and abilities. Voluntary withdrawal deals nearby damage, briefly freezes Technological enemies and refunds Tokens. |
| Strike Team | C2-06 | Reserves two ground cells and arrives after two combat seconds. Voluntary withdrawals raise the next placement cost and arrival output, capped at two escalations. The combat-local rank resets on a new run. |

Howl and Scan use the C31-A recharge orbs. All five use separate W29 rigs and the same fixed-step clock for effects and art. The existing recruitment IDs and level values reload through the same save code. The GDD leaves some numeric tuning open. The pass documents the new field costs, cooldowns, timing and refunds as trial values. The five permanent growth endpoints still await approval. [Decision log](../canon/DECISION_LOG.md#c31-b-ranger-field-kit-playtest-tuning--2026-11-24)

## Late Campaign

The existing autonomous player used stage plans, selected save-owned Rangers from prior mission grants, paid actual Logistic Token costs, built Posts and triggered legal skills and retreats. Profiles with progressed HQ used a Lv.30 Post. The advanced trial used Lv.50, unlocked B14 and higher HQ slot capacity. The low profile used a Lv.1 Post with no optional buffs. The runs below use the shipped C30 stage data. The replay scripts issue deployment and skill actions and let combat resolve the result.

| Mission | Reproducible normal clear | Reproducible perfect clear | Remaining evidence |
| --- | --- | --- | --- |
| C2-04 | Expanded tactical, 73 defeated, 2 escaped, 80 Integrity, tick 16050 | Expanded progressed, B13, 75 defeated, 0 escaped, 100 Integrity, tick 16801 | Low expanded cleared with 67 defeated, 8 escaped, 20 Integrity. |
| C2-05 | Expanded mixed, 106 defeated, 4 escaped, 60 Integrity, tick 21558 | Legacy tactical, B13/B05, 110 defeated, 0 escaped, 100 Integrity, tick 20490 | Saboteurist is a clear reward and was excluded. |
| C2-08 | Open | Open | Mixed/frontline B13/B02 reached wave 4 and lost at tick 18800 with 101 defeats, 0 escapes and 10 Heat overflows. With B13/B14 it reached the same count with 0 escapes at tick 18269. Legacy tactical lost in wave 2 with 49 defeats. |
| C2-09 | Open | Open | The best run by defeats was legacy tactical: wave 2, 43 defeats, 7 escapes, 0 Integrity, tick 10489. The advanced expanded lineup reached wave 2 with 36 defeats and 7 escapes. |

For a separate balance review, test an attainable C2-08 cooling counter first. The ten overflows with zero escapes isolated Heat as the failure in the two strongest runs, and the existing Firebreak acquisition decision remains open. For C2-09, test an opening defense that protects the early route before comparing a revised timing curve. All of the tested C2-09 loadouts ended after seven escapes; the strongest survived into wave two. [Firebreak proposal](../production/w25/PROPOSALS.md)

[Existing lineup](evidence/c31-b/legacy.jsonl) · [Expanded tactical](evidence/c31-b/kits.jsonl) · [Mixed](evidence/c31-b/mixed.jsonl) · [Frontline](evidence/c31-b/frontline.jsonl) · [High-Stakes Intervention](evidence/c31-b/intervention.jsonl) · [Low and progressed profiles](evidence/c31-b/low.jsonl) · [C2-04 replay](evidence/c31-b/replay-c2-04.jsonl) · [C2-05 replay](evidence/c31-b/replay-c2-05.jsonl)

## Native captures

Each size passed 21 checks in the actual launcher and battle scenes. The 960×540 captures use 130% text. Captures use legal deployments, normal Post income, authored Story enemies and the configured Chaos waves.

| View | 1280×720 | 960×540 |
| --- | --- | --- |
| Woods Tracker net in Story, C2-08 | [PNG](c31-b/1280x720/story-tracker.png) | [PNG](c31-b/960x540/story-tracker.png) |
| Strike Team reserving two cells in Chaos | [PNG](c31-b/1280x720/chaos-strike-incoming.png) | [PNG](c31-b/960x540/chaos-strike-incoming.png) |
| K9 companion, Scan and recovering orbs | [PNG](c31-b/1280x720/chaos-k9-seer.png) | [PNG](c31-b/960x540/chaos-k9-seer.png) |
| Saboteurist pulse and Tracking Bots | [PNG](c31-b/1280x720/chaos-saboteur.png) | [PNG](c31-b/960x540/chaos-saboteur.png) |

## Verification and device handoff

Godot import and startup passed. The complete suite passed **3,401 checks across 35 runners**, including 49 new kit checks, 272 Campaign visual checks and 61 presentation checks. The W29 catalog and registration validators, 732-check art probe, 753-check menu probe and W21 inventory passed. The final APK passed its extracted-resource runs, including all three C28 tutorial fixtures, Story, Chaos, C30/C31 and fresh and returning C31-A saves.

Run the regression and evidence checks from the repository root.

```sh
python3 -B tools/run_regression.py --logs build/qa/c31-b/regression
python3 -B tools/build_w29_art_catalog.py --check
python3 -B tools/build_campaign_visual_data.py --check
godot --headless --path . --script res://tests/art/w29_pack_probe.gd
godot --headless --path . --script res://tests/playtest/c30_campaign_playtest.gd -- \
  --expanded-rangers C2-04 C2-05 C2-08 C2-09
godot --headless --path . --script res://tests/playtest/c30_campaign_playtest.gd -- \
  --tactical --expanded-rangers --mixed-lineup --frontline C2-08 C2-09
godot --headless --path . --script res://tests/playtest/c30_campaign_playtest.gd -- --tactical C2-05
godot --audio-driver Dummy --path . --script res://tests/playtest/c31_b_capture.gd -- \
  "$PWD/build/qa/c31-b/native/960x540" 960x540 130
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c31-b-debug.apk
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-c31-b-debug.apk \
  --first-contact --hold-the-line --narrow-escape --campaign-visuals --combat-balance --skill-orbs \
  --ranger-kits --previous build/android/kenyalang-rangers-c31-a-debug.apk --logs build/qa/c31-b/payload
```

The signed debug build SHA-256 is `9af76122eb00df484776030e1180abfbd7714c41a67066848d0901aa77bc0e61`. It verifies with signature schemes v2/v3 and passes 16 KiB alignment. ADB listed zero attached devices. Install with `adb install -r build/android/kenyalang-rangers-c31-b-debug.apk`, open Kenyalang Rangers offline in landscape, and use a save with the relevant recruits. Check both active skill orbs, mirrored K9 attachment, two-cell Strike placement and withdrawal, pause, 2× speed and a cold restart. Repeat at 130% text and confirm the notification and Retreat controls stay within the usable display.

## Changed areas

- `data/rangers`, `scripts/data` and `scripts/battle` declare and run the kits with the existing combat, modifier and recruitment paths.
- `scripts/ui` binds the W29 rigs, effects and badges and exposes the actual deployment state.
- `tests/unit`, `tests/playtest`, `tools/check_android_payload.py` and `export_presets.cfg` verify live runtime behavior and shipping resources.
- `docs/canon`, `docs/production` and this QA report record the trial parameters, art acceptance and unresolved device and balance work.
