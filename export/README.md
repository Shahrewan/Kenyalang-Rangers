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
