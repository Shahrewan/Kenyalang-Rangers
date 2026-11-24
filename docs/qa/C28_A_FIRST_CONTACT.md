# C28-A · First Contact

C1-01 opens from Story Mode with the approved woodland edge, an illustrated T01 field, the four-layer Logistics Post, an illustrated HUD and deployment tray, radio portraits, and clear/defeat badges. The Story screen uses the same 15 mission IDs, Control levels, prerequisite locks and clear records. C1-02 through C2-10 retain their existing battle presentation.

Scout reuses the C07 19-part rig. Patrolman and E01 use editable Skeleton2D/Bone2D scenes assembled from their 17 and 15 W27 parts. Accepted combat events and read-only actor state drive the clips and local effects. The shared combat clock controls both animation and effect lifetime. The foreground trees cover the approach. At the existing escape event the E01 rig continues its short Exit clip under cover while its visible sprite and HP disappear. T01's route and footprint data still govern travel and placement.

| Run through Story Mode | Integrity | Defeated | Escaped | Funds credited |
| --- | ---: | ---: | ---: | ---: |
| Perfect first clear | 100 | 14 | 0 | 10,000 |
| Ordinary first clear | 90 | 13 | 1 | 10,000 |
| Undefended defeat | 0 | 0 | 10 | 0 |

The mission runner opens the actual launcher on three isolated profiles, activates Continue and Skip, injects touch drag gestures, and advances the existing fixed combat clock. Neither win uses injected damage or edited resources. It checks that illegal placement spends nothing, the Starter Post occupies a legal raised pair instantly, one Patrolman blocks two E01, both Patrolman facings remain independent, and Scout's muzzle follows the mirrored tool. Each defeated or escaped enemy receives a single terminal visual transition. Normal and perfect still settle the same first-clear award. [C26 campaign matrix](C26_CAMPAIGN_MATRIX.md)

## In-game captures

- [1280 × 720 battle](c28-a/battle-1280x720.png)
- [960 × 540 briefing](c28-a/briefing-960x540.png)
- [960 × 540 woodland at the exact escape tick](c28-a/woodland-escape-960x540.png)

The Godot renderer captured the frames while running the mission test. The capture run compares the frame on the real escape tick with the same frame after removing the exiting rig from the presentation registry. The comparison checks that the escape leaves no visible body, outline or HP fragment at either resolution. The separate art validator also checks the foreground mask at 80- and 60-unit tile scales.

## Reproduce on PC

Godot 4.7.2 passed editor import, headless startup and 2,037 assertions across 29 runners. That includes 26 C28-A mission assertions and 252 Campaign assertions. Each native capture run passed 38 checks and wrote 10 PNGs at its requested resolution. The art tools verified 56 atlas regions, loaded 76 stage textures and sampled 916 W27 rig poses. The W21 ledger validates 465 asset records and 116 storyboard mappings.

```sh
python3 tools/run_regression.py --logs build/qa/c28-a/final
python3 -B tools/build_first_contact_data.py --check
python3 -B tools/verify_first_contact_art.py
python3 -B tools/verify_w27_art.py
python3 docs/production/w21/validate.py

for size in 1280x720 960x540; do
  godot --path . --audio-driver Dummy --resolution "$size" \
    --script res://tests/unit/c28_first_contact_test.gd \
    -- "$PWD/build/qa/c28-a/screens/$size"
done
```

Use a native display for captures and the pinned Godot `4.7.2.stable.official.ed1daf0bf` for all checks. The runtime registrations and clip data in `data/presentation/first_contact/` are generated from the approved sources. Regenerate them with `python3 -B tools/build_first_contact_data.py` when those sources change.

## Android test

```sh
mkdir -p build/android
godot --headless --path . --export-debug "Android Debug" \
  build/android/kenyalang-rangers-c28-a-debug.apk
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-c28-a-debug.apk \
  --first-contact --logs build/qa/c28-a/payload
adb devices -l
adb install -r build/android/kenyalang-rangers-c28-a-debug.apk
```

The workspace wrapper is `./.android/godot-android`. The APK uses `com.shahrewan.kenyalangrangers.dev`, version code 1, ARM64, Android API 24 minimum and target API 36. Use a compatible signed build with a sufficient version code when testing an update over an existing installation. Preserve the local profile on any device that already holds gameplay progress. [Toolchain and install procedure](../../export/README.md#install-and-check-on-a-phone)

The build passed v2/v3 signature checks, 16 KiB alignment, and host replay of the extracted player files for First Contact, Campaign, HQ, Chaos and Restoration. The profile passed seed, resume and verification through the C28-A files and in a saved-profile rehearsal from the C26 APK. APK SHA-256 is `a35f9e52d5f63984982ab2225fcf1b2c9613315cf914498499c4f80431302c36`.

1. Launch offline in landscape on an ARM64 phone, preferably with a cutout. Check the Story nodes, HUD, tray and dialogue buttons at normal and enlarged text settings.
2. Open First Contact. Try Continue and Skip on separate attempts and watch the field freeze behind dialogue. Drag the Post to the exit and then to `(1,0)+(2,0)`. Try a raised Scout and a ground Patrolman. Coordinates are zero-based from the top left.
3. Use Scout `(5,2)) and left-facing Patrolman `(6,3)` for the perfect-clear arrangement. On a separate attempt use Scout `(6,4)` and left-facing Patrolman `(7,3)` for the ordinary-clear arrangement. Watch both block slots, muzzle attachment, Hit/Defeat and the approach behind the trees. Compare pause, 1× and 2× during movement and a shot. Check the first Post on entry, then add a right-facing Patrolman once its type cooldown expires. Hold and retreat that copy.
4. Try an undefended run and check for ten escapes, zero Integrity and no reward. Restart and replay a clear to check that the first-clear award is consumed. Record device model, Android version, display and cutout, frame time, APK hash and result in the decision log.

ADB listed no attached devices in the workspace. The installation, finger feel, cutout, text scaling and frame time still need a physical phone. All C1-01 assets referenced by this pass are present. D-014 art clearance remains open. This pass uses the existing audio and the three approved dialogue drawings.
