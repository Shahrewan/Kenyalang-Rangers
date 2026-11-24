# C28-C · Narrow Escape

C1-03 now uses the illustrated T01 field. E01, E02 and E03 run as separate combat actors. The E03 rig and Intel badge come from the W29 catalog. Its Move, Sprint, Blocked, Attack, Hit, Defeat and Exit states use the existing battle clock and live events. The sling and wrap follow the rig's authored hierarchy, and the fist cue uses the shared pivot registration.

Combat Medic's accepted basic heals and confirmed Treatment skill animate the case and target cue. Sonic Turret uses the four-layer Ready art, its construction and countdown, the Active clip for an actual sonic hit, and the authored Siege and ruined states when existing damage rules permit them. Both kits use the ordinary loadout and unlock rules. Unbound legal equipment continues through the labeled field display.

The post-wave-2 messenger uses the approved Poacher alert and radio cue during its existing dialogue line. Continue and Skip preserve the resolved enemy totals, active roster, Integrity, combat tick and Funds. The beat has no additional combat actor or reward. [W29 delivery](../production/w29/W29_PRODUCTION_DELIVERY.md)

## Live Story verification

| Run | Defeated | Escaped | Integrity | Resolution tick |
| --- | ---: | ---: | ---: | ---: |
| Ordinary first clear | 28 | 5 | 50 | 12899 |
| Perfect replay | 33 | 0 | 100 | 12962 |
| Undefended defeat | 0 | 10 | 0 | 7228 |

The launcher runner checks the C1-02 prerequisite and uses the original 9, 11 and 13 combat waves. All three results resolve through real combat. Both clears use touch deployment. The normal run checks the existing Retreat prompt, uses a Records-qualified Medic to test tap, target and Confirm, and reads all three messenger lines. The perfect replay uses an ordinarily upgraded level-100 Post and the unlocked Emergency Requisition buff, then skips the messenger. It resolves all 33 enemies. A separate damage fixture verifies the Medic's defeat, the Turret's Siege-only constraint and its destroyed art. C1-03 itself has no Siege attackers.

Both clear routes verify the report and reload the original flags and unlocks. First clear retains `first_clear_funds` as pending, and the perfect replay keeps `replay_funds` and `first_perfect_funds` pending. Defeat leaves no cleared record and Review plan returns to the same operation. Stage files, stat resources, exact timings and save schema are the original versions.

## Developer Funds

In **Settings → Developer**, enter a positive whole amount and choose **Add Funds** or **Remove Funds**. The existing Campaign wallet saves the change immediately and stays within 0–9,999,999. The controls are also available from battle pause Settings. Invalid input is rejected, and adjustments use the same atomic profile write as other Campaign changes. [Developer Settings capture](c28-c/developer-settings-960x540.png)

## Captures and verification

- [1280 × 720 mixed wave](c28-c/mixed-wave-1280x720.png)
- [960 × 540 messenger alert](c28-c/messenger-alert-960x540.png)
- [960 × 540 Combat Medic heal](c28-c/medic-healing-960x540.png)
- [960 × 540 Sonic Turret construction](c28-c/turret-construction-960x540.png)

Pinned Godot `4.7.2.stable.official.ed1daf0bf` passed editor import, startup, 46 Narrow Escape checks headless and 56 checks at each native size. Both native runs saved ten actual gameplay or Settings frames. The full suite passed 2,115 checks across 31 runners, including 26 First Contact and 32 Hold the Line checks.

The W29 catalog comparison passed. The read-only E03 and Medic source checks each verified 16 PNG parts and 15 joins, with a maximum premultiplied raster delta of 1/255. The isolated probes verified 1,356 samples across E02, E03 and the Medic. The W29 pack passed 732 checks and the W29 menu probe passed 753. T01 validation verified its 56 atlas regions and 76 loaded textures. The W21 audit verified 1,117 asset records and 116 storyboard mappings.

```sh
python3 -B tools/run_regression.py --logs build/qa/c28-c/verified
python3 -B tools/build_w29_art_catalog.py --check
python3 -B tools/export_w27_cutouts.py --unit enemies/e03 --unit rangers/combat_medic
python3 -B tools/verify_w27_art.py --unit enemies/e03 --unit rangers/combat_medic --unit enemies/e02
python3 -B tools/verify_first_contact_art.py
python3 -B docs/production/w21/validate.py
godot --headless --path . --script res://tests/art/w29_pack_probe.gd
godot --headless --path . --script res://tests/art/w29_menus/menu_probe.gd

for size in 1280x720 960x540; do
  godot --path . --audio-driver Dummy --resolution "$size" \
    --script res://tests/unit/c28_narrow_escape_test.gd \
    -- "$PWD/build/qa/c28-c/screens/$size"
done
```

## Android

The signed ARM64 debug APK passed v2/v3 signature validation and 16 KiB alignment. Its payload contains four catalog-selected rig remaps, 51 distinct textures and the three byte-matching E02, E03 and Medic clip contracts. Host playback of the shipped files passed all three illustrated missions, Campaign, HQ, Chaos, Restoration, and fresh and returning C28-B profiles. SHA-256 is `155b7ece233af09e1f53e798ea1220001573d6aa7a434a8ed8c18e5f8e2fc020`.

```sh
mkdir -p build/android
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c28-c-debug.apk
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-c28-c-debug.apk \
  --first-contact --hold-the-line --narrow-escape --previous build/android/kenyalang-rangers-c28-b-debug.apk \
  --logs build/qa/c28-c/verified-payload
adb devices -l
adb install -r build/android/kenyalang-rangers-c28-c-debug.apk
```

ADB listed no attached phone. Physical installation, cutout, touch, text scaling and frame time remain pending. The test package uses `com.shahrewan.kenyalangrangers.dev`, API 24 minimum, API 36 target, and version code 1. When updating a phone, retain the compatible signer and a sufficient version code. [Android setup](../../export/README.md#install-and-check-on-a-phone)

1. Launch offline in landscape and enter C1-03 from a cleared C1-02. Inspect the E03 Intel badge and battle at normal and 130% text.
2. Deploy a Post, Scout, Patrolman, Medic and Sonic Turret. Verify the build countdown, Sprint versus blocked pose, two speed settings and Pause. Check Retreat and confirm the unlocked Medic skill on an injured Ranger.
3. Verify Continue and Skip across separate attempts at the messenger. Compare active enemies, Integrity and Funds before and after. Replay with an unguarded path and inspect the failure and retry flow.
4. Open Settings, add and remove a small Funds amount, then relaunch and verify the wallet and Story record. Record device model, API, screen and cutout, APK hash, and observed frame time.

## Changed files

- `scripts/ui/first_contact_field.gd`, `first_contact_skin.gd`, `sample_board.gd`, `wave_intel.gd` and `deployment_controller.gd` bind the prepared field visuals and badges.
- `scripts/battle/campaign_battle.gd` and `scripts/ui/story_portrait.gd` bind the existing messenger beat. `ranger_combat.gd` and `facility_combat.gd` emit treatment and sonic presentation events.
- `scripts/ui/profile_settings_page.gd`, `launcher.gd` and `scripts/persistence/campaign_progress.gd` add the Developer wallet controls. `export_presets.cfg` and `tools/check_android_payload.py` package and verify the selected dependencies.
- The C28-C test runner, updated C28-B scope assertion, W21/W29 audits and production logs record evidence. W29 source artwork and Campaign stage data are read-only inputs.
