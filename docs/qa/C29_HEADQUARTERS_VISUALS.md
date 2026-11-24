# C29 · Live Headquarters

The main-menu Headquarters opens the W29 cross-section with its jungle, roof, rear frame, lobby, room layers, front frame and vegetation. It uses the 11 rectangle and staff registrations from the approved manifest. The unused twelfth bay shows the empty insert. An opening profile furnishes Control, Human Resources and Finance. Purchased departments show their own furnishings, current level and Work loop. Unbuilt rooms show the common empty treatment and still open their existing build and requirements page.

Room artwork and touch targets use the same transform. A scrollable viewport keeps the buttons reachable when the minimum touch size exceeds the available area. Dynamic room labels sit in the upper edge of each bay. Work loops remain behind the foreground furniture and pause while the view is hidden or the app is inactive. The department pages reuse the same layers and W29 theme. The lobby draws the approved trophy at its registered foot anchor using the saved Chaos score. [W29 preview and asset delivery](../production/w29/W29_PRODUCTION_DELIVERY.md)

## Live screenshots

| Profile | 1280 × 720 | 960 × 540 |
| --- | --- | --- |
| Opening day | [Fresh Headquarters](c29/fresh-headquarters-1280x720.png) | [Fresh Headquarters](c29/fresh-headquarters-960x540.png) |
| All 11 rooms constructed | [Developed Headquarters](c29/developed-headquarters-1280x720.png) | [Developed Headquarters](c29/developed-headquarters-960x540.png) |

- [960 × 540 at 130% text](c29/developed-headquarters-130-percent-960x540.png)
- [Mechanical before purchase](c29/mechanical-unbuilt-960x540.png) · [Mechanical after purchase](c29/mechanical-built-960x540.png)
- [Staff during Work playback](c29/staff-at-work-960x540.png) · [Lobby trophy close-up](c29/trophy-lobby-960x540.png)

The launcher UI test produced 22 captures. The complete local archive at `build/qa/c29/headquarters-screenshots.zip` also includes the established profile, Control, Records and R&D Crisis details, and the corresponding alternate-size frames.

## Tests run

| Check | Observed result |
| --- | --- |
| Pinned engine | Godot `4.7.2.stable.official.ed1daf0bf` Compatibility editor import and headless startup passed. |
| Full regression | 2,209 assertions across 31 runners passed, including 134 Headquarters UI, 260 progression, and the C28 Story runners. |
| Live UI and geometry | 134 checks at each native size. The runner tapped all rooms at 130% text, opened each available activity, and tapped the bottom Crisis room after scrolling a constrained viewport. It checked the fresh and established states, saved Levels 1–5, purchase confirmation, insufficient Funds, Finance claim and overflow, locked Control access, Ecology and Outreach requirements, and save reload. |
| Work and trophy | All 11 rigs looped the approved Work clip with registered stationary feet and foreground order. The runner checked hidden, visible, paused and resumed playback. It verified saved trophy thresholds and return from Rainforest Chaos. |
| Art | The runtime registration matches the approved W29 manifest. Catalog validation, 732 pack checks, 753 menu preview checks, and the W21 ledger with 1,117 records and 116 frame mappings passed. |

```sh
python3 -B tools/build_headquarters_art_data.py --check
python3 -B tools/build_w29_art_catalog.py --check
python3 -B docs/production/w21/validate.py
python3 -B tools/run_regression.py --logs build/qa/c29/final
godot --headless --path . --script res://tests/art/w29_pack_probe.gd
godot --headless --path . --script res://tests/art/w29_menus/menu_probe.gd

for size in 1280x720 960x540; do
  godot --path . --audio-driver Dummy --resolution "$size" \
    --script res://tests/unit/headquarters_ui_test.gd -- "$PWD/build/qa/c29/screens/$size"
done
```

The captures used the Compatibility renderer and Mesa software graphics. The virtual display reported that it could not change V-sync. No Android performance numbers were collected.

## Android package and device checklist

The ARM64 development APK uses `com.shahrewan.kenyalangrangers.dev`, version code 1, API 24 minimum and target API 36. It passed v2/v3 signature validation and 16 KiB alignment. The selected player pack contains the exact runtime registration, 11 staff scene remaps, 132 HQ and trophy textures, and the W29 theme. Host replay passed the expanded HQ UI runner, the three illustrated missions and fresh and returning C28-C profile checks. APK SHA-256 is `3eed1bf8d98481ae598e4019eac5a615f77853e10ca3ae545385ad5ae01535b2`.

```sh
mkdir -p build/android
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c29-debug.apk
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-c29-debug.apk \
  --first-contact --hold-the-line --narrow-escape --previous build/android/kenyalang-rangers-c28-c-debug.apk \
  --logs build/qa/c29/final-payload
adb devices -l
adb install -r build/android/kenyalang-rangers-c29-debug.apk
```

ADB listed no attached phones. Physical install, safe-area layout, thumb reach and device frame time remain pending. The workspace Godot wrapper is `./.android/godot-android`. Use the matching signer and a sufficient version code to update a device with an existing profile. [Android setup](../../export/README.md#install-and-check-on-a-phone)

1. Launch offline in landscape. Open Headquarters from the main menu and check room labels, touch targets and the bottom lobby at standard and 130% text. On a cutout device, check how scrolling exposes the outer and lower rooms.
2. Use a fresh and a returning profile. Compare empty and furnished Mechanical, buy a legal level, and claim a small Finance amount. Check the wallet and reopen Headquarters from an activity.
3. Watch the eleven Work loops on a fully constructed profile and check the saved trophy after returning from Chaos. Background the app and resume. Record device model, API, cutout, display density, APK digest and any timing or clipping issues.

## Changed files

- `scripts/ui/headquarters_overview.gd` composes the building, registered controls and lobby. `headquarters_office_art.gd` and `headquarters_room_page.gd` share the department layers and playback.
- `scripts/ui/headquarters_art.gd`, `data/presentation/w29/headquarters.json` and `tools/build_headquarters_art_data.py` make the original manifest registrations available to the player.
- `export_presets.cfg` selects the approved assets. `tests/unit/headquarters_ui_test.gd` extends the original C15 runner. The W21/W29 ledgers and production logs record the live bindings and evidence.
