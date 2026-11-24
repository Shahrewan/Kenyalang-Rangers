# C28-B · Hold the Line

C1-02 uses the C28-A T01 field, terrain, HUD, deployment tray, radio portraits and result marks. E01 and E02 run as independent actors keyed by the battle's live serials. The adapter reads E02's approved scene, six-state clip and shared Intel badge from the W29 catalog. The near-hand strike effect follows the authored fist socket. The woodland approach and terminal display follow the live route and escape event. [W29-C01 handoff](../production/w29/W29_C01_HOLD_THE_LINE_HANDOFF.md)

The first equipped ordinary Post goes straight to Ready at zero cost. A subsequent Post reserves its ordinary two-cell footprint and displays its existing construction countdown. On completion the same four layers show its Ready state. Combat Medic and Sonic Turret were exercised in a returning profile with labeled field markers. Unsupported enemies in the illustrated adapter have labeled markers with live status and HP. [First Contact baseline](C28_A_FIRST_CONTACT.md)

## Campaign verification

| Run | Defeated | Escaped | Ending Integrity | Resolution tick |
| --- | ---: | ---: | ---: | ---: |
| C1-02 normal clear on W29 main `8054802` | 17 | 1 | 90 | 8169 |
| C1-02 live illustrated mission | 17 | 1 | 90 | 8169 |
| C1-01 perfect clear | 14 | 0 | 100 | |
| C1-01 ordinary clear | 13 | 1 | 90 | |
| C1-01 undefended defeat | 0 | 10 | 0 | |

The baseline replay used the existing Campaign auto-combat fixture in a clean archive and asserted tick 8169. The new runner opens C1-02 via Story, places the Post and five Rangers by synthetic touch when the original rules permit, and lets the live battle resolve. It compares the report with the battle state, verifies the pending `first_clear_funds` key and 0 Funds credited, and reloads the normal clear and Combat Medic and Sonic Turret unlocks. It exercises all six E02 clips, stacked blockers, vertical facing retention, pause, 2×, dialogue hold and exactly one terminal visual for each of the 18 actors. The native runs compare the real escape frame with and without the departing rig in the draw registry. [C26 fixture](C26_CAMPAIGN_MATRIX.md#android-manual-check)

The separate replay test verifies the repeated Post's spend, shared cooldown, construction at 1× and 2×, pause, exact cancellation refund, legal rebuild, completed state and full health. C1-03 opens with its existing field and portrait. The full Campaign runner also exercises all later missions.

## Captures and tooling

- [1280 × 720 mixed wave](c28-b/mixed-wave-1280x720.png)
- [960 × 540 pause Intel](c28-b/pause-intel-960x540.png)
- [960 × 540 repeat Post construction](c28-b/post-construction-960x540.png)
- [960 × 540 woodland escape frame](c28-b/woodland-escape-960x540.png)

Pinned Godot `4.7.2.stable.official.ed1daf0bf` passed editor import and startup and 2,069 checks across 30 runners. The C1-02 runner passed 32 headless checks and 41 checks at each rendered resolution. The C1-01 runner passed 26 headless and 38 at each rendered resolution. The two missions produced 36 native screenshots across both sizes.

W29 validation passed 732 pack checks, 753 menu checks and the generated catalog comparison. The read-only E02 source check verified 15 parts, 14 joins and a maximum raster delta of 1/255. The isolated Godot probes passed 386 E02 samples and 916 W27 samples. T01 validation checked 56 atlas regions, 76 textures and 80-/60-unit woodland occlusion. The W21 ledger checked 1,117 records and 116 frame mappings.

```sh
godot --headless --path . --editor --import --single-threaded-scene
python3 -B tools/run_regression.py --logs build/qa/c28-b/suite
python3 -B tools/build_w29_art_catalog.py --check
python3 -B tools/build_first_contact_data.py --check
python3 -B tools/export_w27_cutouts.py --unit enemies/e02
python3 -B tools/verify_w27_art.py --unit enemies/e02
python3 -B tools/verify_w27_art.py
python3 -B tools/verify_first_contact_art.py
python3 -B docs/production/w21/validate.py
godot --headless --path . --script res://tests/art/w29_pack_probe.gd
godot --headless --path . --script res://tests/art/w29_menus/menu_probe.gd

for size in 1280x720 960x540; do
  for stage in hold_the_line first_contact; do
    godot --path . --audio-driver Dummy --resolution "$size" \
      --script "res://tests/unit/c28_${stage}_test.gd" \
      -- "$PWD/build/qa/c28-b/screens/$stage/$size"
  done
done
```

The first workspace import hit an editor thread crash while scanning the newly fetched W29 artwork. A clean archive and the subsequent project import passed with `--single-threaded-scene`. The standard full regression import and native gameplay checks passed after import.

## Android

The development APK uses `com.shahrewan.kenyalangrangers.dev`, version code 1, ARM64, Android API 24 minimum and target API 36. It passed v2/v3 signature validation and 16 KiB alignment. The shipped payload includes E02's mapped scene, all 15 texture imports including its six shared E01 files, one Intel badge, the catalog and the exact E02 clip. E02 is the only W29 animation clip in the package. The extracted payload passed both missions, Campaign, HQ, Chaos, Restoration, and both a fresh save and a returning C28-A save. SHA-256 is `1d489ef454189251eea90e2143bf90f0393ebfc3591b725884682b82d5ac4893`.

```sh
mkdir -p build/android
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c28-b-debug.apk
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-c28-b-debug.apk \
  --first-contact --hold-the-line --previous build/android/kenyalang-rangers-c28-a-debug.apk \
  --logs build/qa/c28-b/payload
adb devices -l
adb install -r build/android/kenyalang-rangers-c28-b-debug.apk
```

ADB listed no attached phones. Physical installation, thumb reach, cutout margins, text scaling and frame time remain pending. The pinned workspace export wrapper is `./.android/godot-android`. The update must match the installed signer and satisfy the installed version code. [Install procedure](../../export/README.md#install-and-check-on-a-phone)

1. Launch offline on an ARM64 phone in landscape. At default and 130% text, check both Intel views, Continue/Skip, Pause, speed and that the field and tray clear the screen cutout.
2. Equip the ordinary Post and reproduce the C26 arrangement. Check E01/E02 depth, the two stacked HP bars, the E02 fist effect, pause and 2×, and the escape into the woods.
3. Replay with a second Post and unlocked support. Check the construction countdown, hold-to-cancel refund, per-type delay and completed state. Check Combat Medic and Sonic Turret labels, then relaunch and verify progress. Record phone model, Android API, screen, cutout, APK digest and observed frame time in the decision log.

## Changed files

- `scripts/battle/campaign_battle.gd` gates the additional illustrated mission. `scripts/ui/first_contact_field.gd` and `first_contact_skin.gd` bind the approved rig and existing clock. `sample_board.gd` draws construction and field fallbacks.
- `scripts/ui/wave_intel.gd` and `operation_results.gd` bind the Intel badge and shared clear marks. `export_presets.cfg` selects the E02 resource dependencies.
- `tests/unit/c28_hold_the_line_test.gd` drives the live cases and takes captures. `tools/check_android_payload.py` runs the same headless checks from the APK.
- The W21 and W29 ledgers record live bindings. This report, the tracker and the decision and handoff logs record evidence. Approved W29 art files were used from PR #32.
