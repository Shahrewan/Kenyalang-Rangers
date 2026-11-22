# First Android debug APK

This procedure checks the placeholder launcher and static sample field on one physical phone. Use the **Android Debug** preset and its development package ID `com.shahrewan.kenyalangrangers.dev`. Use an ARM64 phone for this preset. Release signing and distribution follow D-015 in the [decision log](../docs/canon/DECISION_LOG.md).

## Export on the PC

1. Install and configure the versions and tools listed in the [project README](../README.md#android-export-prerequisites). In the editor, verify that Manage Export Templates shows **4.7.2.stable** installed.
   For command-line SDK setup, point the SDK manager at your chosen SDK directory:

   ```sh
   sdkmanager --sdk_root="/path/to/android-sdk" --licenses
   sdkmanager --sdk_root="/path/to/android-sdk" "platform-tools" "build-tools;36.1.0" "platforms;android-36"
   ```

2. From the repository root, import and export the debug APK:

   ```sh
   mkdir -p build/android
   godot --headless --path . --editor --import
   godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-debug.apk
   ```

   In the editor you can also use **Project → Export → Android Debug → Export Project**, with **Export With Debug** enabled. Keep debug signing local. Retain the same debug key for repeat installs over the same package.

## Install and check on a phone

1. Activate **Developer options → USB debugging**, connect the unlocked phone over USB, and approve the debugging prompt. Use `adb` from the SDK's `platform-tools` on your PATH.
2. Confirm the phone appears as `device` and install the APK:

   ```sh
   adb devices
   adb install -r build/android/kenyalang-rangers-debug.apk
   ```

   If multiple devices appear, use `adb -s SERIAL install -r ...` for the test phone only. An update requires the same signing key as the installed package.
3. Turn on airplane mode and open **Kenyalang Rangers (Dev)**. Confirm it starts offline in landscape. Tap **Open sample battle**, check that the header and controls clear the cutout and system bars, then tap **Back to menu**. Repeat after backgrounding and resuming the app. Confirm both buttons are reachable by touch on the chosen phone.
4. Record the phone model, Android version/API, RAM, GPU, resolution, cutout, editor/template version, APK version and observed pass/fail in the [decision log](../docs/canon/DECISION_LOG.md). Keep device serials and signing details out of Git.

## Cloud build and validation

The workspace-local toolchain is under the ignored `.android/` directory. It contains the configured Godot editor profile, the matching Android APK templates, JDK 17.0.21.1, SDK Platform 36, Build-Tools 36.1.0, and Platform-Tools 37.0.3. Use the local launcher to reuse that profile:

```sh
mkdir -p build/android
./.android/godot-android --headless --path . --editor --import
./.android/godot-android --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-debug.apk
```

The export produced `build/android/kenyalang-rangers-debug.apk`. Android tools verified its v2 and v3 signatures, ZIP alignment and package manifest. The manifest reports ARM64, landscape, Compatibility, minimum API 24, and target API 36. API 24 is the engine template minimum. The project test target remains Android 9 or later. Android resource inspection reported a themed-icon entry from the standard template. The app manifest uses the regular launcher icon.

No physical phone is accessible in this workspace. The USB device bus is absent, and ADB daemon startup fails when it tries to create its user directory on the read-only home filesystem. Install the built APK from a PC with an attached phone using the steps above.

## C02 battle smoke test

The signed C02 build is `build/android/kenyalang-rangers-c02-debug.apk`. Signature, ZIP alignment and packaged battle-script and resource checks passed. The Android Debug preset explicitly includes combat scripts that the selected-scene exporter misses when they are referenced through global GDScript classes. To rebuild the C02 APK with the workspace profile:

```sh
./.android/godot-android --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c02-debug.apk
```

Install that file from a connected PC using `adb install -r build/android/kenyalang-rangers-c02-debug.apk`. Open **Sample battle** in airplane mode and check that the buttons fit within the phone's safe area. Wait for an enemy marker, pause, and open the dialogue preview. The marker and spawn count should stay fixed. Continue or skip, then resume and let a marker reach the tunnel. Integrity should fall by 10. A restart should restore 100 Integrity. Repeat using the defeat control and confirm it increments Defeated without charging Integrity.

## C03 deployment smoke test

Install the signed C03 development build from a USB-connected PC:

```sh
adb install -r build/android/kenyalang-rangers-c03-debug.apk
```

Open **Sample battle** in airplane mode. Drag Patrolman off the board and onto an elevated tile. The budget and board should remain unchanged in both cases. Drop it on a ground tile, choosing a half of the tile to set its facing. Drag the two-cell Ranger into an overlap and then onto two empty ground cells. Verify only the valid placement charges Tokens.

Quick-tap Scout Sniper to arm its skill. Drag across the board and release to check that this does not activate it. Tap a covered tile, then tap **Confirm skill**. Hold a Ranger until **Retreat** appears, use it, and check that its cooldown freezes when paused and allows redeployment afterward. Confirm that the tray, Retreat and confirmation controls fit inside the phone's safe area.

## C04 logistics smoke test

Install the signed C04 build with `adb install -r build/android/kenyalang-rangers-c04-debug.apk`. In **Sample battle**, check the zero-Token First Contact opening. Drag the Starter Post onto two adjacent elevated tiles. It should build instantly and pay 9 Tokens after ten combat seconds. Pause before the payout, wait, then resume to check that pause holds the timer.

Select **D05 Fixed Stockpile**. Verify 120 Tokens and an absent Post card. Place Sonic Turret for 35 Tokens, tap the unfinished Facility and choose **Cancel build** before its seven seconds elapse. The wallet should return to 120 and both cells should be free. Place it again and let it finish. The completed Facility should remain stationary. Use **Normal loadout** to check that later Posts display a paid cost and build time.

## C05 First Contact phone playtest

Install the signed C05 build with `adb install -r build/android/kenyalang-rangers-c05-debug.apk` from the project root on a PC connected to an ARM64 phone. Open **First Contact** in airplane mode. Confirm that both Continue and Skip leave the briefing, that the clock waits behind it, and that the field and tray fit around the phone's cutout. Note the model, Android version, resolution and safe-area behavior.

Start by dragging the Starter Post off the board once and checking that Tokens stay at zero. Place it on the top-left pair of raised tiles. At nine Tokens, Scout placement should be rejected without spending. After the next payout, place Scout on the raised tile beside the bend. After one more payout, place Patrolman on the lower path facing left. A reproducible perfect-clear layout uses zero-based anchors Post (1, 0), Scout (5, 2), Patrolman (6, 3). Check HP bars, attacks, blocking, pause and the result.

Restart and test hold-to-Retreat and redeploy cooldown. In an undefended run, inspect the 10-Integrity escape penalty and defeat. Close and relaunch after a clear, replay it, and confirm that the first-clear or perfect bonus cannot be awarded twice. Record the installed build and results in the decision log. The phone evidence is required before work expands beyond C05.

## C07 Scout rig phone review

Install the standalone preview beside the C05 build:

```sh
adb install -r build/android/kenyalang-rangers-c07-rig-preview.apk
```

Run the C05 First Contact playtest first and record its result. Then open **Kenyalang Rangers (Scout Rig)** in landscape. Watch Idle, Deploy, Attack, Skill, Hit, Retreat and Defeat at normal phone scale. Flip facing and compare the tool grip, joints, feet and HP reference against the raised tile. Check that **Lock facing** prevents another flip, and that Pause and 1×/2× act on a running clip. Record the model, Android version, build and any joint gaps or scale/readability issues.

To reproduce the standalone APK, use a temporary project copy. Point its main scene to `res://scenes/qa/scout_rig_preview.tscn`. In its Android Debug preset select the preview scene and `res://scripts/battle/combat_clock.gd` as export resources, and set the package ID to `com.shahrewan.kenyalangrangers.rigpreview`. Run the pinned editor import and standard debug export from that copy. The shipped C05 preset stays in the original checkout.

## C09 navigation and battle UI phone check

Build from the repository root with the configured Godot 4.7.2 editor and templates, then install on a USB-connected ARM64 Android phone. The workspace build uses `./.android/godot-android` for the `godot` commands.

```sh
mkdir -p build/android
godot --headless --path . --editor --import
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c09-debug.apk
adb devices -l
adb install -r build/android/kenyalang-rangers-c09-debug.apk
```

1. In airplane mode, open **Kenyalang Rangers (Dev)** in landscape. On a fresh test profile, enter a Leader name, relaunch and check that it persists. When updating an existing C05 install with the same debug key, verify that the Funds and clear records carry over. Leave existing test data in place during an update.
2. Open **Story Mode**, check the reason shown for a locked node, then open **First Contact**. Review both Ranger costs, the free Starter Post outside the Mechanical slots, the fixed D01 debuff, the R&D unlock requirements, and the enemy details in both waves. Use Android Back to return to Story and reopen the plan.
3. Start the operation and try Continue and Skip. Check that combat waits during the briefing. Drop the Post on an invalid footprint and verify zero Tokens and an empty board, then deploy it on a legal pair. In **Sample battle**, swipe sideways across an overflowing set of deployment cards, then drag a card up onto the board. The sideways swipe should only scroll the tray. Check affordability, hold-to-Retreat and cooldown feedback.
4. In First Contact, change to 2×, pause, review incoming waves, and check that movement and payout timing wait. Open **Abandon operation**, tap **Keep playing**, then **Resume**. In a separate attempt confirm **Abandon**. The same plan should reopen with the original local Funds balance.
5. Clear the mission using the placements in the [C05 playtest](#c05-first-contact-phone-playtest). Check results, the first-clear/perfect reward breakdown and the Story clear badge. Replay to check that the one-time Funds are only awarded once. On a run without defenses, verify defeat and zero payout.
6. On a notched phone, repeat with default and enlarged system text settings. Check that both ends of the tray, the outer board cells, Pause and speed, the wave preview, and the results buttons remain reachable. Measure the visible hit areas against the 48 dp target using device density. Record the phone model, Android version, display resolution, density, safe-area insets, APK and outcomes in the [decision log](../docs/canon/DECISION_LOG.md#d-001-d-002-and-d-018-c09-integration--2026-11-22).

The C09 APK passed package verification in the cloud. Physical installation and this phone run remain open.

## C10 Offense sandbox phone check

The Offense sandbox uses the Android toolchain above. To reproduce its separate APK, make a temporary project copy. Set `run/main_scene` to `res://scenes/qa/ranger_sandbox.tscn`, append that scene to `export_files` in the **Android Debug** preset, and set `package/unique_name` to `com.shahrewan.kenyalangrangers.offensepreview` and `package/name` to `Kenyalang Rangers (Offense Sandbox)`. Then run the pinned import and export in that copy. Keep the development profile available for the C05 physical-phone check.

```sh
mkdir -p build/android
godot --headless --path . --editor --import
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c10-offense-preview.apk
adb install -r build/android/kenyalang-rangers-c10-offense-preview.apk
```

1. Open **Kenyalang Rangers (Offense Sandbox)** in airplane mode. Drag Scout to `(2, 0)`, Crowd to `(2, 2)` and Guard to `(3, 1)` using zero-based coordinates. Release Guard on the left half of its tile to face the entry. Check the 54 Token balance after all three drops and confirm the tray and HUD clear the field and cutout.
2. Tap Scout when a target is inside its square. Drag across the field once, then tap the target's tile and press **Confirm skill**. Damage and the immobilize ring should first appear at confirmation. The test sandbox supplies **Steady Aim**.
3. Tap Crowd when enemies cluster in range. Observe the EMP drop in HP and the teal slowing field. Technological targets have a `T`. The ordinary EMP has the higher output against them. Check movement and recharge at 1× or 2× and across Pause or the dialogue preview.
4. Tap Guard up to four times while ground enemies are within two tiles in front. Observe the damage, stun ring and remaining charges. A fifth tap during recharge should leave HP alone. Pause with charges missing, wait, resume, and verify only one returns after thirteen combat seconds. Test hold-to-Retreat and a legal redeploy after its countdown. The `A` targets in wave two should pass Guard and remain eligible for the elevated attackers.
5. Restart to clear the sandbox state. Record the build, model, Android version, density, cutout fit and touch outcomes in the [decision log](../docs/canon/DECISION_LOG.md#d-007-and-d-008-c10-offense-tuning--2026-11-22).
