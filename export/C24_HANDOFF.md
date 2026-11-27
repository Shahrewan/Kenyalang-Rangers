# Kenyalang Rangers · Android RC1 handoff

**Internal device testing.** The installable file is `kenyalang-rangers-0.1.0-rc.1-internal.apk`. The app label is **Kenyalang Rangers**, version `0.1.0-rc.1`, Android version code `2`, package `com.shahrewan.kenyalangrangers.dev`. It uses the release engine, the project’s development launcher art and the same development signer as the verified C23 debug APK. The proposed final namespace, release artwork and team signing custody await owner review. [Sign-off and device matrix](../docs/qa/C24_RELEASE_SIGNOFF.md) · [Build metadata](../docs/qa/evidence/c24/build.json)

## Install offline and exercise the update

Use an ARM64 phone supporting OpenGL ES 3. The APK minimum is API 24. The project's baseline test phone target is Android 9 with 3 GB RAM and the preferred target is Android 11+ with 4 GB or more. Enable Developer options and USB debugging and authorize the PC. Set airplane mode and explicitly turn Wi-Fi off. USB ADB works with both disabled.

1. Check the signed APK against SHA-256 `655473bf4a97758d16e0e1688e4103e598c62e4e938bfc8a0c05d1eae6048394` using `sha256sum` or PowerShell `Get-FileHash -Algorithm SHA256`. Use a fresh test device or Android user profile for the first-use pass. Existing team saves can stay in their current profile.
2. From the directory containing the signed file, run the following with the target phone connected. Add `-s SERIAL` after `adb` if more than one device is attached. The app opens in landscape.

   ```sh
   adb devices -l
   adb install -r kenyalang-rangers-0.1.0-rc.1-internal.apk
   adb shell am start -W -n com.shahrewan.kenyalangrangers.dev/com.godot.game.GodotAppLauncher
   ```

3. Name the Leader, enter Story and run the checklist below. After a successful transaction, record the displayed Funds, relevant room level and plant or mission state. Close and reopen with these commands and compare the saved values.

   ```sh
   adb shell am force-stop com.shahrewan.kenyalangrangers.dev
   adb shell am start -W -n com.shahrewan.kenyalangrangers.dev/com.godot.game.GodotAppLauncher
   ```

4. For an **update** use a separate test profile or phone with the C23 code-1 APK from the matching signer already installed. Record its Leader, wallet, rooms, Story record and active plant. Run the same `adb install -r` and launch commands using RC1. Verify all recorded values and the next legal transaction across a second relaunch. Android identifies updates by package and signing identity. A certificate mismatch requires the correctly signed APK. Removing an install erases its local save.
5. For each physical run record phone model, Android version/API, RAM, GPU, display resolution/refresh, cutout, APK hash, prior version, offline state, result and tester/date in the device matrix. Keep device serials and identifying logs private.

## Player controls and physical QA route

| In the app | Action and expected result |
|---|---|
| Main Menu | Open **FAQ → How do I deploy and retreat?** for touch instructions. **FAQ → References → Credits and engine license** works offline. **Settings** adjusts text and Master, Music and Sound effects. Check visible Back and Android Back, speaker mix and cutout fit. |
| C1-01 First Contact | Start the mission and continue or skip the dialogue. Drag the free Starter Post to elevated cells at (1,0), measured from the top-left tile at (0,0). After two payouts, place Scout at (5,2). After the next payout place Patrolman at (6,3), facing left. This layout cleared 14 enemies on the host. Pausing or opening full-screen dialogue holds combat. |
| Deployment and skills | Swipe the tray to browse. Drag and release on valid terrain and choose a melee Ranger's facing with the left/right half of its tile. Tap a deployed Ranger to use or arm a skill, then confirm if a target is required. Hold to reveal Retreat. Check that dropping on the wrong terrain preserves Tokens. |
| HQ and later Story | Claim Finance and build Mechanical for 20,000 Funds. Equip the normal Post in C1-02. Check Planning, Start, pause and relaunch. Use a progressed team test save for C1-05's Diversion Captain or a Chapter 2 boss. Verify introduction, HP transition, resolved outcome and next mission. In HR or Mechanical buy an affordable level and verify the new level after relaunch. |
| Rainforest Chaos | Check 49 → 50 enemies and the rejected 51st in one wave. With Mechanical and the starter Patrolman, configure T01, two E01 in wave 1 and one E01 in wave 2. Select only Patrolman and Logistics Post, then D02, D03, D05, D07, D08, D12, D13 and D15. The preview is 1,030 points. D05 supplies 120 Tokens and removes the Post. Place Patrolman at (2,1) facing left. A qualifying clear pays 41,200 before the cap and grants the 1,000-point unlock once. |
| Outreach and Records | Build Outreach and select **Open Outreach**. Build Records, upgrade to Lv.2 and select **Records Encyclopaedia**. In this build, Outreach reports the bank approval gate and the first Records chapter stays disabled. Record those states. A complete graded response, a timed Records quiz and a one-time payout on a phone require approved production banks. |
| Reforestation | Build Ecology, open **Reforestation**, choose Plot 1 and plant Strangler Fig. On the normal local clock, water at or after nine hours and collect nine hours after watering. An overdue plant waits for water. First Fig collection earns 3,000 plus the 50,000 milestone before cap clipping. Check the same plot through HQ and the Main Menu and confirm that reopening cannot pay twice. |

## Rebuild and sign

Use Python 3.11+ and Godot `4.7.2.stable.official.ed1daf0bf`, matching `4.7.2.stable` Android release templates, JDK 17, SDK Platform 36 and Build-Tools 36.1.0. Configure the SDK and JDK paths in Godot as described in the export guide. The helper builds the current **committed** tree in a temporary directory and writes the unsigned APK and source metadata to `build/android/c24/`. The verified binary was built from `19cdf2a`. Version labels, code and package ID can be supplied explicitly for a subsequent candidate. [Android setup](README.md#export-on-the-pc)

```sh
python3 tools/export_android_candidate.py --godot ./.android/godot-android
```

On a configured workstation with Godot on PATH, omit `--godot`. The helper takes the classic, adaptive and themed icons from the committed preset. Use `--icon` only to override the classic icon with a tracked, approved PNG. On the signing workstation, align first, sign the aligned copy, then verify the final bytes. Set `ANDROID_SDK_ROOT` and `KEYSTORE_PATH` to the local paths and supply the password interactively when prompted. For the internal update test, use the development keystore matching the prior install. For a team distribution build, use the owner-confirmed package via `--package`, a higher version code for each update and the team key held outside the repository. Verify adaptive and themed appearance on the intended launchers. Record the public certificate fingerprint, backup and recovery custodians privately with the team.

```sh
sdk="$ANDROID_SDK_ROOT/build-tools/36.1.0"
out=build/android/c24
stem=com.shahrewan.kenyalangrangers.dev-0.1.0-rc.1-2
apk="$out/kenyalang-rangers-0.1.0-rc.1-internal.apk"
"$sdk/zipalign" -P 16 -f 4 "$out/$stem-unsigned.apk" "$out/$stem-aligned.apk"
"$sdk/apksigner" sign --ks "$KEYSTORE_PATH" --out "$apk" "$out/$stem-aligned.apk"
"$sdk/apksigner" verify --verbose --print-certs "$apk"
"$sdk/zipalign" -c -P 16 4 "$apk"
"$sdk/aapt" dump badging "$apk"
"$sdk/aapt" dump permissions "$apk"
sha256sum "$apk"
python3 tools/check_android_payload.py "$apk"
```

The commands show the internal artifact names. For a production identity use its own filenames, approved assets and certificate. Private sideloading uses an APK. Builds may differ in signature and ZIP metadata when rebuilt. Compare each artifact with its own recorded hash. Keep signed binaries in the private handoff channel. This repository contains source and verification evidence.
