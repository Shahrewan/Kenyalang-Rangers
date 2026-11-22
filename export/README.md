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

## C11 Facility sandbox phone check

Use the Godot 4.7.2 Android toolchain above and a USB-connected ARM64 phone. To reproduce the standalone sandbox, copy the project to a temporary directory. In that copy set `run/main_scene` to `res://scenes/qa/facility_sandbox.tscn`, append that scene to `export_files` in **Android Debug**, and use `com.shahrewan.kenyalangrangers.facilitypreview` and `Kenyalang Rangers (Facility Sandbox)` for the package ID and name.

```sh
mkdir -p build/android
godot --headless --path . --editor --import
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c11-facility-preview.apk
adb devices -l
adb install -r build/android/kenyalang-rangers-c11-facility-preview.apk
```

1. Open **Kenyalang Rangers (Facility Sandbox)** in airplane mode. Swipe the tray while the board stays clear. Drop a Facility over a ground tile and check that the Token balance stays at 1,000. Use zero-based coordinates for the following drops.
2. Place Medic Cabin at `(1, 1)` and Scout Sniper at `(4, 3)`. As ordinary projectiles reduce Scout's HP, check that the Cabin has full HP. Once a kit arrives, tap the Cabin, tap Scout and use **Confirm skill**. Repeat on another run with a drag across Scout before selection to verify the drag preserves the kit.
3. Watch the Siege enemy pin a red warning to the Cabin near the entry. Pause during the windup, wait, then resume and check the HP loss. On a fresh attempt place Sonic at `(1, 1)` when Siege approaches so the site is hit while unfinished. Tap **Cancel build** before seven combat seconds and check the full 35-Token refund. Let a site be destroyed on another attempt and check that its footprint is free.
4. Try Sentry Tower at `(3, 1)` and confirm that `(3, 0)` stays reserved. Once the Tower is ready, drag an available Scout to the Tower's base. Watch detection when concealed enemies arrive. Place Mechanic within two tiles of an injured Facility to check repair. Swipe to the Calltower and Specialist test card to verify the one-use discount and the charged cost.
5. In the second wave, compare the Heat gauge with Firebreak active on one attempt. Check the compact display, Pause, speed and tray at default and enlarged text settings and around the phone's cutout. Record the build, named device, Android version, density, safe insets and results. [Decision log](../docs/canon/DECISION_LOG.md#d-007-and-d-008-c11-facility-tuning--2026-11-22)

The signed C11 packages passed export and archive checks. Physical installation and this phone run remain pending. The cloud workspace has no USB device bus, and its ADB daemon cannot create its directory on the read-only home filesystem.

## C12 enemy and boss sandbox phone check

Use the toolchain above and a USB-connected ARM64 Android phone. To reproduce the standalone APK, copy the project to a temporary directory. Set `run/main_scene` in that copy to `res://scenes/qa/enemy_sandbox.tscn`, append that scene to `export_files` in **Android Debug**, and set the package ID and name to `com.shahrewan.kenyalangrangers.enemypreview` and `Kenyalang Rangers (Enemy Sandbox)`.

```sh
mkdir -p build/android
godot --headless --path . --editor --import
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c12-enemy-preview.apk
adb devices -l
adb install -r build/android/kenyalang-rangers-c12-enemy-preview.apk
```

1. Open **Kenyalang Rangers (Enemy Sandbox)** in airplane mode. Scroll the encounter picker to all three bosses. Select a standard enemy, start it, tap **Roster**, and verify its selection persists. Check the picker, tray and battle HUD around the phone's cutout.
2. Choose Smoke Infiltrator and try the Seer Scan test card on a nearby elevated tile. Tap to reveal the `?` marker and inspect its mark in Pause. Choose Recon Drone in another round and check that it passes Guard while an elevated Scout can hit it. Try the Signal Jammer or Net Trapper with a Ranger in range and check its pending and expired status at 1× and 2×.
3. Compare Rifle Spotter and Portable Mortar Crew on separate runs with a Post at `(1, 0)`. Check the Mortar's red Siege warning and HP change after the windup, including a pause during aiming. The Post should keep full HP against Rifle Spotter.
4. Check that Firebreak slows Ignition Operator's Heat gauge and that a capacity reset deducts Integrity. On its own run, let Wildlife Trafficker reach the tunnel and verify immediate defeat.
5. Start each boss, test Continue and Skip, and use **Practice hit** to reach each phase. Check the Captain's capture, Foreman's temporary HP, and Leader's surge and Runner arrivals. Wait through a phase dialogue to verify that the arrivals hold. Record the APK, phone model, Android version, density, safe insets and results. [Encounter matrix](../docs/qa/C12_ENEMY_MATRIX.md)

## C14 Campaign phone check

Use a USB-connected ARM64 phone with Android 9 or later and the pinned export toolchain above. On the phone, enable Developer options and USB debugging, then accept the computer's authorization prompt. Run these commands from the repository root on the connected computer. The last two commands also work with the existing signed C14 APK.

```sh
mkdir -p build/android
godot --headless --path . --editor --import --quit
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c14-debug.apk
adb devices -l
adb install -r build/android/kenyalang-rangers-c14-debug.apk
```

1. Open **Kenyalang Rangers (Dev)** in airplane mode. Set the Leader name, enter **Story Mode**, and check that C1-02 is locked and C1-04 is fogged. In C1-01, review the loadout and both waves and check that the plan fits the safe area in both landscape directions.
2. Start C1-01. Read one line and wait before using **Skip**. Confirm combat stays at the same starting state. Drag the Post to ground and check zero Tokens, then use the elevated pair at `(1, 0)`. Use the generated Tokens to place Scout at `(5, 2)` and a left-facing Patrolman at `(6, 3)`. Pause across a payout and resume. Check the next wave notice, hold-to-Retreat, the safe area and result after both waves. On a replay, the same three mission cards should appear at zero Tokens.
3. After C1-01, open **Campaign access** from the C1-02 plan. Claim enough Finance to reach 20,000 and build Mechanical. On the trial balance, with no stage Funds credited, this takes 5,000 active unpaused seconds. Return to the plan, equip the ordinary Post and start. Test resume after backgrounding, and relaunch after closing the app mid-operation. An interrupted attempt returns to planning.
4. With the appropriate progression unlocked, check C1-05 starts at 120 with the Post omitted. Check T02 route labels A/B, and C2-07's six-second Firebreak build, 30-Token price and Heat gauge. Check C2-08's Heat without the supplied card. In the finale, wait through a phase dialogue, resume to the Runner arrivals, and verify the first-clear epilogue on an eligible profile.
5. Record the installed APK hash, phone model, Android version, landscape dimensions, screen density, cutout/safe insets and observed results. [Verification matrix](../docs/qa/C14_CAMPAIGN_MATRIX.md)

The signed C14 APK was exported with Godot `4.7.2.stable.official.ed1daf0bf` and matching `4.7.2.stable` templates. Physical installation remains pending. The cloud workspace exposes no USB bus, and its ADB server cannot create `/home/agent/.android` on the read-only home filesystem.

## C15 Headquarters phone check

Use the pinned Godot toolchain and a USB-connected ARM64 test phone with Android 9 or later. For the migration check, start from a C14 development install signed with the same debug key. Keep its name, wallet and progress on the phone when installing C15 with `-r`.

```sh
mkdir -p build/android
godot --headless --path . --editor --import --quit
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c15-debug.apk
adb devices -l
adb install -r build/android/kenyalang-rangers-c15-debug.apk
```

1. Open **Kenyalang Rangers (Dev)** in airplane mode. With a C14 profile, compare the migrated name, Funds, Finance storage, Control, Mechanical and Story clears. On a clean profile verify the three free rooms, eleven selectable bays, and the 10,000 starting balance.
2. Tap Human Resources and Mechanical to view capacity and unit levels. Use a funded QA profile to preview a milestone. Cancel once and compare the wallet, then confirm and check the exact price and level. Reopen the app and verify both survived. Check the same screens in both landscape orientations.
3. Open Finance and compare its rate and storage before and after a purchase. Background the game briefly and check that Finance stopped. On an overflow QA fixture, cancel the discard preview and compare both balances before confirming.
4. Build Mechanical on an eligible profile, equip the ordinary Post, and verify its purchased level in Story. Use the Garden shortcut and Ecology's activity button to reach the same saved plot view.
5. Use a disposable QA profile to open **Settings → Reset local progress**. Cancel first. Verify the profile is still present, then confirm on the disposable profile and check that a cold restart opens naming. Record the APK hash, phone model, Android version, density, cutout and observations.

The C15 development APK passed host-side package and resource checks. Physical install and signed-update continuity await a connected phone. [C15 verification matrix](../docs/qa/C15_HEADQUARTERS_MATRIX.md)

## C16 modifier phone check

Use the pinned toolchain above and a USB-connected ARM64 Android 9 or later phone. Enable USB debugging and accept the authorization prompt. Run these commands on the connected PC from the repository root.

```sh
mkdir -p build/android
godot --headless --path . --editor --import --quit
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c16-debug.apk
adb devices -l
adb install -r build/android/kenyalang-rangers-c16-debug.apk
```

1. Open **Kenyalang Rangers (Dev)** in airplane mode. Use a QA profile with Mechanical built and the ordinary Logistics Post equipped. Unlock B01 and B02 with R&D Eco Lv.3, and B13 and B15 with R&D Crisis Lv.5. Open **Rainforest Chaos → Modifier trial → Edit modifiers**.
2. Select B01 in **R&D buffs** and D05 in **Debuffs**. Back in R&D buffs, scroll to B13 and check the conflict message. Return to planning, check **120 Tokens** and the effective slot count with the Post excluded, then start. Confirm the field tray has no Post. When the entry outline appears, pause and confirm the forecast and wave hold. Resume and place a Ranger by touch. Check the picker, field and pause controls in both landscape orientations.
3. Return to the plan, clear D05, and combine B13 and B15 with a Post. Check for 35 opening Tokens, then place a Lv.1 Post to verify the 9-Token payout per 10 combat seconds. With Guard Veteran or Medic Cabin equipped, try an available active by touch and check the disabled message.
4. Compare two runs with Sonic Turret and a Post equipped. Select D09 and D10 in one run. Place the first Post at `(8, 0)` and Sonic Turret beside the entrance at `(1, 0)`. Check that the Post stays instant and Sonic's build grows from seven to 8.75 combat seconds. Watch the first Demolitionist in Wave 2 deal 60 HP normally or 75 with D09. Toggle B02 and D14 to compare Heat when Ignition Operator is active.
5. In **Story Mode**, open a Chapter 1 and an unlocked Chapter 2 operation. Check their fixed debuffs and one- and two-buff limits. Verify that B02 is ineligible on First Contact. Record the installed APK hash, device model, Android version, density, cutout, touch results and whether offline launch succeeded. [C16 matrix](../docs/qa/C16_MODIFIER_MATRIX.md)

The C16 APK passed host-side package, resource and UI checks. Installation awaits a connected physical phone.
