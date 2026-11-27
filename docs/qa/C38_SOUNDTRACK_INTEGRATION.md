# C38 soundtrack integration

27 November 2026 · Baseline main `f3b9d02` (revision 3 SFX, PR #50) · Godot editor and export templates `4.7.2.stable`

## Playback and credits

| Theme | Player-facing route | Loop duration | Godot wraps observed |
| --- | --- | ---: | ---: |
| Fajar Baram | Main Menu, Leader naming and save recovery | 120.733 s | 2 |
| Bali | Headquarters, management and operation planning | 112.941 s | 2 |
| Epic Nusantara | Story combat through C2-09 | 123.400 s | 2 |
| The Tribe | Rainforest Chaos combat | 207.000 s | 2 |
| Epic Gamelan Instrumental | C2-10 Final Interception combat | 26.520 s | 2 |
| Moonlight Wood | Habitat Restoration, Records archive and quiz, PR Outreach | 114.603 s | 2 |

The six original OGG hashes and all import loop settings were checked. The Godot offline mixer rendered positive audio buffers across two complete wraps per track, using full-file playback with zero offset. The supplied seam diagnostics give end-to-start sample jump ratios of 0.370, 0.096, 0.473, 0.201, 0.436 and 0.722 against each track's nearby 99th-percentile sample derivative. This verifies the decoded loop and preserves the supplied transition. Phone or headphone listening is still required to review musical phrasing.

The launcher applies the C2-10 override from the loaded stage ID. Settings retains the originating theme. Automated cases cover in-progress mode fades, pause, background and resume, persistent volume settings and the finale opened via the Story launcher.

Music and Audio Credits is available in the existing Field Guide under **FAQ → References → Credits and engine license** or **Settings → Help and references → Credits and engine license**. Track credits, source URLs and license text are readable offline. The source action copies the link where the platform provides a clipboard, with an external-open action on other platforms. The existing education source list, art/inspiration credits and Godot notices remain available. A native Linux run rendered at **960×540 and 130% text**, exercised the clipboard and verified scrolling and all six artist/title pairs. [Runtime capture](c38/credits-960x540-130.png) · [Full credit and license records](../reference/MUSIC_CREDITS.md)

## Verification and packaging

- Godot import and startup passed. The source suite passed **6,175 checks across 51 runners**, including 152 soundtrack checks. The native soundtrack and credits run passed **154 checks**.
- The fresh Campaign fixture's 15 mission records match C36-D byte for byte. The run awarded **7,885,000 Funds** across those clears and finished with **3,355,121 Funds** after purchases.
- The exact signed Android APK passed **4,259 checks across 32 runs** in the exported-resource harness on the host, including package boot, soundtrack loops and fresh and returning-save rehearsals.
- The six source files occupy **5,780,430 bytes**. Their imported resources account for **5,866,439 compressed APK bytes**. The pack also includes the Music and SFX bus layout and shared manifest. All 266 SFX resources and remaps match the revision 3 APK byte for byte. Source MP3s, the supplied ZIP and QA material are absent from the package.
- The signed C38 APK is **49,282,811 bytes**, an increase of **5,883,700 bytes** over the retained revision 3 APK. Package identity remains `com.shahrewan.kenyalangrangers.dev`, ARM64, minimum SDK 24 and target SDK 36. APK v2/v3 signature verification and 16 KiB alignment passed. The signer fingerprint remains `0b79cac72bf38357eb4aa0dcb68e0b34bff7d2a9503a32e0928186f00b1bf052`.
- Candidate `build/android/kenyalang-rangers-c38-debug.apk`, SHA-256 `befd341c7dcedddb8753e8072e0e302606adcda9efe9f2dda0ed450dc41c319b`. Retained C36 revision 3 APK SHA-256 `2c567a886cfec890879dd55f1160bfeb63cca6179a574508142b0e0de8259f93`.
- The project has no Windows export preset. A future preset should include the six OGG streams and remaps, `default_bus_layout.tres`, `data/presentation/music_manifest.json`, `scripts/ui/soundtrack.gd`, and the existing SFX and Field Guide dependencies.
- ADB listed no device. Installation, in-place update, native audio focus and acoustic phone or headphone evaluation remain open. [Device procedure](../../export/README.md#c38-soundtrack-candidate)

[LUFS and mixer evidence](C38_AUDIO_MIXING.md) · [Soundtrack source and disclosure records](../reference/MUSIC_CREDITS.md)

## Reproduce

```sh
mkdir -p build/android build/qa/c38
godot --headless --path . --editor --import
godot --headless --path . --quit-after 120
python3 -B tools/run_regression.py --logs build/qa/c38/regression
godot --path . --resolution 960x540 --script res://tests/unit/c38_soundtrack_test.gd \
  -- build/qa/c38/credits-960x540-130.png
godot --headless --path . --script res://tests/playtest/c32_d_fresh_campaign.gd
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c38-debug.apk
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-c38-debug.apk \
  --previous build/android/kenyalang-rangers-c36-rev3-debug.apk \
  --first-contact --hold-the-line --narrow-escape --campaign-visuals \
  --combat-balance --skill-orbs --ranger-kits --education --facility-growth --ranger-growth \
  --economy-rewards --previous-economy-active --chaos-cap --previous-chaos-capped \
  --production-presentation --android-stabilization --onboarding --audio --soundtrack \
  --logs build/qa/c38/payload
```

The delivered ZIP SHA-256 is `a8d4660c4f38be86007f998bf8b9f05f42874870e8a090e077ec1a436697f550`. Keep the owner-supplied archive and source recordings with the private acquisition records.
