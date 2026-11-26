# First Android debug APK

For the current private release-template build, use the [C24 install, update and signing guide](C24_HANDOFF.md).

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

Open **Sample battle** in airplane mode. Drag Patrolman off the board and onto an elevated tile. The budget and board should remain unchanged in both cases. Drop it on a ground tile, choose a facing and tap **Deploy**. Drag the two-cell Ranger into an overlap and then onto two empty ground cells. Verify only a valid, confirmed placement charges Tokens.

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

1. Open **Kenyalang Rangers (Offense Sandbox)** in airplane mode. Drag Scout to `(2, 0)`, Crowd to `(2, 2)` and Guard to `(3, 1)` using zero-based coordinates. Choose **Face left** for Guard and tap **Deploy**. Check the 54 Token balance after all three drops and confirm the tray and HUD clear the field and cutout.
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

## C17 Rainforest Chaos phone check

Use the pinned export toolchain above and a USB-connected ARM64 Android 9 or later phone. Enable USB debugging, accept the authorization prompt, and run these commands from the repository root.

```sh
mkdir -p build/android
godot --headless --path . --editor --import --quit
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c17-debug.apk
adb devices -l
adb install -r build/android/kenyalang-rangers-c17-debug.apk
```

1. In airplane mode, open **Rainforest Chaos → Choose route**. Check the original board previews, safe margins in both landscape directions and the personal record in both Chaos and the ground-floor HQ entrance.
2. In **Configure run**, check that five empty slots block Start. Set Forest Trespasser to 49 and tap Poacher **+**. Try a third type with **+** and the slider and verify the wave stays at 50. Reduce either row and verify room opens immediately. Leave a gap between populated slots and check the battle shows only the populated wave count.
3. Use Mechanical Lv.1 and equip only Scout Sniper and the Logistics Post. Choose Forgotten Patrol, queue one Forest Trespasser and apply D15 Critical Escape. The preview shows 10 Medal Score and 200 qualifying Funds. Start, drop the Post across the raised pair at `(1, 0)` and place Scout at `(5, 2)` after the Post has paid enough Tokens. Verify the qualifying reward and balance. Replay and let the enemy escape with Integrity left to check zero additional credit.
4. For the worked example, use a QA profile with Mechanical, Combat Medic, Sonic Turret and R&D Combat Lv.2. Choose Gunung Mulu. Set Wave 1 to 20 Poachers, 10 Contraband Runners, 10 Shield Carriers and 10 Recon Drones. Set Wave 2 to 10 Demolitionists. Equip Scout, Patrolman, Medic, Post and Sonic. Apply B05 and D02, D09 and D11. Check 1,350 Medal Score, 54,000 qualifying Funds and at least Tier 1 in the trophy preview. Open the modifier sheet, make a change and cancel to confirm the preview returns to the prior values.
5. Launch a challenge, pause, and close the app. Use `adb shell am force-stop com.shahrewan.kenyalangrangers.dev` for a controlled cold start on the test phone. Reopen the app and verify the configuration returns with its counts, effects and loadout. Start again and check 100 Integrity, then confirm Abandon and verify the record and wallet. Record the APK hash, device model, Android version, density, cutout, touch and offline launch results. [C17 check matrix](../docs/qa/C17_CHAOS_MATRIX.md)

The C17 APK passed package and host gameplay checks. Physical installation awaits a connected phone.

## C19 education phone check

Use the pinned toolchain above and a USB-connected ARM64 Android 9 or later phone. Enable and authorize USB debugging on the phone.

```sh
mkdir -p build/android
godot --headless --path . --editor --import --quit
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c19-debug.apk
adb devices -l
adb install -r build/android/kenyalang-rangers-c19-debug.apk
```

1. Open **Kenyalang Rangers (Dev)** in airplane mode with Outreach and Records built. From Headquarters open both activities. The current build shows the pending content messages. Check Back and safe margins in both landscape orientations.
2. On a build with approved banks, open Outreach and submit an answer. Verify the Manager explanation, grade and actual Funds. Reopen the same prompt and compare the saved choice and award. Test the refresh boundary and a backward clock change on a disposable QA profile. Restore the device clock afterward.
3. In Records, compare the archive's citations and chapter gates. At Lv.2, open Scout's chapter. Pause, background and relaunch during a question. Verify the countdown resumes from the saved point, then let it expire and check the explanation and zero payout.
4. Complete a perfect chapter and replay. Compare the wallet, first-correct awards and enhancement after a cold restart. Check the longest approved prompts and answers with enlarged text and record touch sizes and any clipping. Capture the APK hash, phone model, Android version, screen density, cutout and offline launch result. [C19 matrix](../docs/qa/C19_EDUCATION_MATRIX.md)

The C19 APK passed host-side tests. Physical installation and approved-content reading checks remain open.

## C20 Restoration phone check

Use the pinned toolchain above and a USB-connected ARM64 Android 9 or later phone. Use a disposable QA profile for tests that change the phone's clock.

```sh
mkdir -p build/android
godot --headless --path . --editor --import --quit
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c20-debug.apk
adb devices
adb install -r build/android/kenyalang-rangers-c20-debug.apk
```

1. In airplane mode, open **Reforestation** from the Main Menu. With Ecology unbuilt, verify that **Open Ecology** leads to the room. On a QA profile with the 20,000 Funds build price, build Ecology Lv.1 and tap **Reforestation** in the room. Confirm the same garden opens with two available plots. Tap a locked plot and verify the required room level.
2. Plant Strangler Fig in Plot 1 and verify Seed and the nine-hour Water timer. Close the app and return at least nine hours later. To shorten the check, move the QA phone's clock forward while the app is closed. Confirm Sapling and **Water**. Wait or advance the clock again before watering and verify it still waits at halfway. Tap **Water** and verify the new nine-hour timer.
3. Close the app again. At least nine hours after watering, reopen from the other entrance. Collect the first Fig and verify the 20% milestone, 53,000 Funds before the wallet cap, and retained tree art. Replant the same plot, relaunch, and confirm the old cycle cannot pay again. Move the clock backward after observing a new checkpoint and verify the stage holds. Restore automatic date and time after the check.
4. On a developed QA profile, collect a third distinct species and check the 60% gate and 900,000 Funds purchase price in Ecology. After buying Lv.5, use the sixth plot. The fourth distinct species triggers one visitor flight and the nest box. Relaunch to check the box stays and the flight has finished. One further mature collection reaches 100%.
5. Check the plot and side controls in both landscape orientations, including cutout and edge reach. Record the APK hash, phone model, Android version, screen density, cutout and offline launch result. [C20 matrix](../docs/qa/C20_RESTORATION_MATRIX.md)

The C20 APK passed package and host gameplay checks. Physical installation and touch await a connected phone.

## C22 presentation phone check

Use an authorized ARM64 phone with USB debugging and the pinned Android Debug preset.

```sh
mkdir -p build/android
godot --headless --path . --editor --import --quit
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c22-debug.apk
adb devices
adb install -r build/android/kenyalang-rangers-c22-debug.apk
```

1. Launch offline. Open FAQ and References and locate both conservation source credits. From Main Menu Settings, mute Master, change Music and Sound effects independently, and select 130% text. Relaunch and verify the same choices. Open Reset and cancel with Back.
2. Start C1-01. Read the portrait dialogue and check Continue and Skip with enlarged text. Open Controls and Settings from pause. Return to pause and verify the same wave, speed and Tokens before resuming. Repeat after backgrounding. Check the board, HUD and pinned actions against the cutout in both landscape orientations. In a developed loadout, swipe from the first to the last card. Check that horizontal swipes preserve Tokens.
3. Try a valid and an occupied placement, a held Retreat and a targeted skill. Check the captions during recon, a Siege attack and Heat overflow with Master muted. Restore sound and check the cues on the phone speaker. Measure the smallest button and slider touch bounds against 48dp using the device density.
4. Open an available field note from Garden and Records on an approved-content build. Verify Back retains the originating view. Record device model, Android version, density, cutout, APK hash and pass/fail results. [C22 source audit](../docs/qa/C22_SOURCE_AUDIT.md)

## C23 physical phone benchmark

Build from the committed C23 checkout with Godot 4.7.2 and its matching Android templates. The benchmark exporter uses a disposable copy of HEAD and installs under its own package ID. The normal player's save and launcher have their own package.

```sh
python3 tools/export_c23_benchmark.py --godot ./.android/godot-android
adb devices -l
adb install -r build/android/kenyalang-rangers-c23-benchmark.apk
adb shell getprop ro.product.model
adb shell getprop ro.build.version.sdk
adb shell wm size
adb shell wm density
```

With a locally configured editor/SDK, omit the `--godot` option. On each candidate ARM64 phone, enable airplane mode, keep it in landscape and record the Android version, RAM, display refresh rate, resolution, cutout, and thermal/power state. Use `adb -s SERIAL` when multiple phones are attached. Keep serials out of shared evidence.

1. Start a log capture on the PC with `adb logcat -T 1 -v time -s godot:I`. Leave it running. Launch the app from its icon or use `adb shell monkey -p com.shahrewan.kenyalangrangers.c23bench 1`. The opening allows eight seconds of construction. The boss introduction closes automatically. Leave the app in the foreground until it exits and emits one `C23_BENCH` JSON row.
2. Collect three uninterrupted runs. Save each row with its APK hash and phone model. Check for 50 residents, four deployables, live Siege and Heat events, nonzero samples and measured memory. Record FPS and p50/p95/p99/max frame intervals against the 60 FPS / 16.67 ms goal. On a separate pass use `adb shell dumpsys meminfo com.shahrewan.kenyalangrangers.c23bench` while all 50 are visible for total PSS. Android presentation timing and thermal stability can be profiled over a longer repeated trace with Perfetto.
3. For save continuity, use the ordinary C23 development APK and a disposable player profile. In airplane mode plant and water a tree, background the app, run `adb shell am force-stop com.shahrewan.kenyalangrangers.dev`, and relaunch. Check the planted cycle and balance before and after one harvest. Repeat on a paused Chaos operation and verify that reopening restores the configuration. Capture any failure with package version and stage. Outreach answer continuity can be checked on phone once the approved bank is installed.

The cloud run on 23 November 2026 returned an empty ADB device list. Linux timings, package verification and outstanding sign-off are recorded in the [C23 audit](../docs/qa/C23_SYSTEM_AUDIT.md).

## C34 Android deployment and performance checks

The Android Debug preset uses Godot `4.7.2.stable.official.ed1daf0bf` and the `4.7.2.stable` templates with Java 17, Platform 36 and Build-Tools 36.1.0. The app is ARM64, uses the Compatibility renderer and retains `com.shahrewan.kenyalangrangers.dev` and the existing debug signer. Export using the workspace profile when available.

```sh
mkdir -p build/android
./.android/godot-android --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c34-debug.apk
```

On another machine use `godot` with the Java and SDK paths set in the editor. Before an update, use `apksigner verify --verbose --print-certs` to compare the candidate with the previously installed build's signing certificate, and record both APK hashes. If `adb install -r` reports an incompatible update, stop and keep the installed profile. Keep the default profile for update continuity and use a separate phone or Android user to test the new-Leader journey.

### Capture the reported drag failure

1. Attach and authorize a phone in USB debugging. Use `adb devices -l` to identify it locally. For multiple devices add `-s SERIAL` to each ADB command. Record the Android API, device model, GPU, RAM, native resolution, density, cutout and navigation mode, alongside the exact installed APK hash. Keep device serial numbers out of shared reports.
2. Open Story Mode, start First Contact, close the briefing and reproduce the reported drag using a real finger. Record whether it occurs during contact, movement outside the tray, first valid-cell preview, release or animation startup. Record which Ranger or Facility was selected and whether it happened in both landscape orientations.
3. On the PC, run the following from the repository root around the reproduction. The files stay local and the capture preserves the existing log buffers and save files.

   ```sh
   mkdir -p build/qa/c34/device
   package=com.shahrewan.kenyalangrangers.dev
   adb shell getprop ro.product.model
   adb shell getprop ro.build.version.release
   adb shell getprop ro.build.version.sdk
   adb shell wm size
   adb shell wm density
   adb shell cat /proc/meminfo | head -1
   adb shell dumpsys SurfaceFlinger | rg -m 1 'GLES:'
   adb shell dumpsys window displays | rg 'DisplayCutout|InsetsState' > build/qa/c34/device/insets.txt
   start=$(adb shell 'date "+%m-%d %H:%M:%S.000"' | tr -d '\r')
   app_pid=$(adb shell pidof -s "$package" | tr -d '\r')

   # Reproduce the drag now, before restarting the app.
   adb logcat -b crash -d -v threadtime -T "$start" > build/qa/c34/device/crash.txt
   if [ -n "$app_pid" ]; then
     adb logcat -b main -b system --pid "$app_pid" -d -v threadtime -T "$start" > build/qa/c34/device/player-process.txt
   fi
   adb shell pidof -s "$package"
   adb shell dumpsys activity exit-info "$package" > build/qa/c34/device/exit-info.txt
   ```

   Exit information is available from Android 11. Preserve the package-specific error, signal or ANR, PID, native backtrace and library Build ID when present. Extract only the game-related lines before sharing logs.
4. Install the candidate on the same phone with `adb install -r build/android/kenyalang-rangers-c34-debug.apk`. Repeat the drag on the same mission and tile, including valid and invalid Post previews, swipe-to-scroll, melee facing changes, Confirm, Cancel and interrupting a drag by backgrounding. Check with a free Starter Post, a paid Facility, a ranged Ranger and a two-cell melee Ranger. Verify the preview and cost first, then the on-field result, actual Token delta, cooldown and save continuity.

### Measure the running Android game

Use the same phone, build identity, quality settings and scenario for before/after comparisons. Record the display refresh rate, thermal state and whether a screen recorder is active. Capture First Contact, dense Chapter 2, Imbak Canyon Heat, a boss and Final Interception, a dense Chaos run, a populated Headquarters and repeated menu/battle transitions. Continue a representative session long enough to see if total PSS or frame times rise over time.

- Use Perfetto or the Android Studio System Trace with the game's SurfaceFlinger frame timeline on Android 12 or later. Measure sustained FPS and p50/p95/p99 frame intervals on the game surface. Android View hierarchy timings alone do not measure Godot rendering.
- Use `adb shell dumpsys meminfo com.shahrewan.kenyalangrangers.dev` at the same point in each paired scenario to compare total PSS. Measure cold launch and transitions separately. Record any PID change, ANR or system exit reason after dragging.
- After checking the production game, repeat the profile-continuity journey in airplane mode. Background, lock and reopen during a drag, facing selection and a paused operation, and verify the exact combat tick and saved progress when returning. Physical touches, emulator input and host gameplay tests are separate evidence.

## C35 Chapter 1 and Headquarters onboarding

From the repository root, use the same pinned toolchain and debug signing identity as C34. Compare signing certificates before updating a returning phone. Use a separate Android user or test device for the new-Leader journey so the returning profile stays available.

```sh
./.android/godot-android --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c35-debug.apk
adb devices -l
adb install -r build/android/kenyalang-rangers-c35-debug.apk
```

1. In airplane mode, open First Contact from Story. Read the planning steps and either Continue or Skip the briefing. Drag the card marked **Free** across the two gold tiles. Watch the Token cue advance to Scout and then Patrolman. Drop Patrolman on the marked path tile, use **Face left**, and tap **Deploy**. Check pause, resume and the 18-second break. Repeat the lesson from **Pause → Controls**.
2. Clear First Contact and use **Open Mechanical**. On a fresh test profile, check the balance and confirm the build. Return to Hold the Line and equip Logistics Post. Repeat a battle on a returning profile with **Show in-battle coaching** off to verify the replay and existing save.
3. Follow Narrow Escape's Medic, skill and Retreat lessons, and check the Control Room link on the result if the room is below Level 2. Verify the 16-second breaks in C1-04 and C1-05 and the Fixed Stockpile opening in C1-05.
4. Open **HQ tutorial**, tap through the five steps, open a department and return normally. Repeat at 130% text. Record the phone, APK SHA-256, touch results and any step that a new player could not complete without help.

The C35 APK was checked off-device. Physical installation and first-time usability for this candidate remain open. [C35 QA report](../docs/qa/C35_PLAYER_ONBOARDING.md)

## C36-D sound effects candidate

The C36-D build uses the existing ARM64 package identity and debug signer. Keep a known-good APK available before testing the update. After verifying certificates and authorizing USB debugging, use the existing development install and preserve its data.

```sh
./.android/godot-android --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c36d-debug.apk
adb devices -l
adb install -r build/android/kenyalang-rangers-c36d-debug.apk
```

1. Check that the C35 profile opens, launch First Contact offline, and compare a successful placement, invalid drop, changed facing and Cancel. Close and resume the game during an active wave. Check that prior combat sounds do not return.
2. Use device speakers and headphones at ordinary and high volume. Check the Music, SFX and Master controls independently. Listen through a dense 2× wave, Siege, Heat overflow and boss phases. Record overlap, clipping, unclear signals, the device model, Android version and the tested APK hash.
3. Check Story and Chaos receipts, HQ purchases, Outreach grades, Records timeout and Restoration collection. Verify volume and progress after a cold restart. The same name and signer allow testing with an existing profile without resetting it.

[C36-D audit and benchmarks](../docs/qa/C36_AUDIO_INTEGRATION.md)
