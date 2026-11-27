# C37 unified branding

27 November 2026 · Godot `4.7.2.stable.official.ed1daf0bf` and matching Android templates · Baseline main `19182d6`, including C38

## Brand sources and bindings

The supplied Kenyalang Rangers Brand Pack is the source for the GDD-inspired emblem. Its receipt describes a generated emblem traced into vector paths. All 26 listed entries matched their delivery SHA-256 and byte counts. The ZIP SHA-256 is `cb747120acd28a365b1fadeee481011c79c362ac46d077c5cad28516928dfa0e`. The owner supplied the artwork for this game. The menu art manifest records the source and exports.

| Surface | Treatment | Evidence |
| --- | --- | --- |
| Main Menu title | New cream SVG in the existing aspect-preserving frame. The title typography, sizing and panel arrangement match the previous menu. | [Before and after](c37/compare-menus.jpg) |
| Startup | Cream PNG centered on an olive Godot boot splash. The Android system startup graphic is sourced from the adaptive foreground. | [Native Godot startup at 960×540](c37/startup-960x540.png) |
| Headquarters and Main Menu HQ thumbnail | A small olive emblem on the pale reception wall beside the console. The changes in the 1280×720 lobby, overview and opening artwork occupy the 24×20 px rectangle starting at (590, 624). | [Before and after](c37/headquarters-reception.jpg) |
| Application icon | New square SVG for the project and the supplied 192 px Android launcher PNG. The preset also points to the three supplied 432 px adaptive layers. | [Packaged icon mask simulation](c37/packaged-launcher-masks.png) |
| Other production screens | Audited Leader naming, office artwork and signs, HQ onboarding, Story, planning, briefing dialogue, pause, results, Settings, Field Guide credits, Rainforest Chaos and Habitat Restoration. Their illustrations, action icons and badges have distinct roles. | [960×540 and 130% native screen review](c37/small-display-review.jpg) |

The repository scan covered live resource references and the superseded vector path, and the image review covered UI plates, the HQ room layers and shell, results, portraits, trophies and other hornbill images. The old W29 logo appeared in the Main Menu, project icon and their source masters. No additional embedded copy of that logo was found in the reviewed production artwork. Historical screenshots of older builds retain their recorded appearance. The root `icon.svg` is unbound prototype material. The Chaos trophy and Restoration guide and visitor depict other hornbills.

The cream and olive masters share the same path and 140×113 viewBox. The palette is cream `#F6EAD0` and olive `#354621`. Cream against olive measures **8.59:1**. Olive against the reception wall measures **6.45:1**. The UI authoring tool now copies the supplied source masters so regeneration uses C37. The HQ authoring tool reads the same olive master. [Source and export receipts](../../assets/source-art/ui/w29/manifest.json) · [HQ receipt](../../assets/source-art/hq/manifest.json)

## Verification

- Godot editor import and launch passed. Live Linux renders covered 13 views each at 1280×720 and 960×540, with 100% and 130% text, for 52 candidate captures. The results screen used a sample receipt. The Main Menu and HQ remained readable at the smaller window and larger text setting.
- The full suite passed **6,175 checks across 51 runners**. W29 catalog, Campaign and HQ registrations, First Contact art and W27 art checks passed. The exact signed APK passed **4,259 checks across 32 runs** in the host payload harness, including startup and fresh and returning-save flows.
- All five Android density buckets and the default bucket contain the full set of four launcher bitmaps. The largest foreground and monochrome silhouettes match the source alpha masks. The furthest nontransparent pixel is **129.41 px** from center, within Android's 132 px safe radius at 432 px. The packaged mark was reviewed at 48, 24 and 16 px in classic, circular, rounded and simulated themed masks. This is a host simulation using unpacked player resources.
- Android's compiled `res/mipmap-anydpi-v26/icon.xml` contains foreground, background and monochrome references. The candidate export uses themed icon data and omits the prior missing-themed-asset warning. Physical masking and theme tint are pending because ADB found no connected device.
- All **278 audio entries** and **220 compiled script/remap/native entries** match the C38 APK byte for byte. The only new game payload entry is the boot PNG. The delivery archive, authoring assets, extra raster sizes, Windows ICO and review images stay outside the APK.
- APK `build/android/kenyalang-rangers-c37-debug.apk` is **49,106,775 bytes**, 176,036 bytes smaller than the retained C38 APK. SHA-256 is `1c93f850e3d7507ff6a30a45eafe17201287705e02ce4379c4652b0d6ab395e6`. APK v2/v3 verification and 16 KiB ZIP alignment passed. Package `com.shahrewan.kenyalangrangers.dev` remains ARM64, version code 1, minimum SDK 24 and target SDK 36. The signer certificate is `0b79cac72bf38357eb4aa0dcb68e0b34bff7d2a9503a32e0928186f00b1bf052`.
- No Windows export preset exists. The supplied ICO was inspected and contains 16, 24, 32, 48, 64, 128 and 256 px entries. When adding a Windows preset, supply `platform/windows/KenyalangRangers.ico` from the private delivery under the preset's Application Icon setting and check the executable, window and taskbar on Windows.

## Reproduce

```sh
python3 -B tools/build_w29_art_catalog.py --check
python3 -B tools/build_campaign_visual_data.py --check
python3 -B tools/build_headquarters_art_data.py --check
python3 -B tools/verify_first_contact_art.py
python3 -B tools/verify_w27_art.py
python3 -B tools/run_regression.py --logs build/qa/c37/regression
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c37-debug.apk
python3 -B tools/verify_branding.py --apk build/android/kenyalang-rangers-c37-debug.apk
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-c37-debug.apk \
  --previous build/android/kenyalang-rangers-c38-debug.apk \
  --first-contact --hold-the-line --narrow-escape --campaign-visuals \
  --combat-balance --skill-orbs --ranger-kits --education --facility-growth --ranger-growth \
  --economy-rewards --previous-economy-active --chaos-cap --previous-chaos-capped \
  --production-presentation --android-stabilization --onboarding --audio --soundtrack \
  --logs build/qa/c37/payload
```

[Android install and launcher procedure](../../export/README.md#c37-branding-candidate)
