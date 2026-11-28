# Faster deployment and clearer Headquarters tips

28 November 2026 · Godot 4.7.2 · Baseline main `707063c` (merged C37)

## Player changes

- An upward card drag now previews legal tiles after 4 logical pixels of deliberate movement. The previous dead zone required more than 14 pixels before drag recognition. Horizontal scrolling still uses the 14-pixel dead zone and takes over only on a predominantly horizontal swipe in a scrollable tray. A fast drag that reaches the field in its release event still works.
- Tap a Ranger or Facility card, then tap a highlighted tile as an alternative to dragging. Selecting a card reserves no cells and spends no Tokens. Tap the same card again or use Android Back to cancel. An invalid tap keeps the card selected so the player can choose another tile. Melee placement still requires a facing choice and Deploy, and all placements use existing costs, footprints and cooldowns.
- While Mechanical is unbuilt, the first action above the Headquarters artwork is **Start here · HQ tips**. The first guide step tells players to build Mechanical and places **Open Mechanical** before Previous and Next. The header keeps **HQ tips** available after Mechanical is built.

## Verification

- The native touch-event regression starts the Facility preview on a 5-pixel lift, keeps a shallow diagonal eligible for deployment, and verifies a Scout drop delivered as press and release only. It exercises two-tap Post placement, an invalid tile, a swipe on the field, Android Back during an in-flight placement and explicit melee confirmation. The existing 25-deployable suite exercises drag placement, footprints, affordability, multiple fingers and cancellation. First Contact still earned a perfect clear and credited 15,000 Funds.
- Native Linux runs exercised both touch and onboarding at **960×540 and 130% text**. [HQ first action](quick-deploy/headquarters-start-here.png) · [First HQ tip](quick-deploy/headquarters-tour.png) · [Tap-to-place preview](quick-deploy/tap-to-place.png)
- The Godot import, startup and source suite passed **6,189 checks across 51 runners**. The exact signed Android APK passed **4,273 checks across 32 host payload runs**, including fresh and C37 update-save rehearsals.
- The C37 and candidate APKs contain the same entries. Only the five updated UI scripts, pack index and signature metadata changed. Package `com.shahrewan.kenyalangrangers.dev`, ARM64, minimum SDK 24, target SDK 36, and the debug signer match C37. APK v2/v3 verification and 16 KiB ZIP alignment passed.
- The signed candidate is `build/android/kenyalang-rangers-quick-deploy-debug.apk` (49,110,871 bytes). Its SHA-256 is `1f9e0e6929b8c46428d72baa7a69d732bd80a10bc0195b5aa58e8415018aad0b`. The retained C37 APK still has SHA-256 `1c93f850e3d7507ff6a30a45eafe17201287705e02ce4379c4652b0d6ab395e6`.

ADB found no physical Android device. Finger response, the perceived speed difference, in-place installation, and a first-time player's ability to find the tips remain handset checks. [Phone procedure](../../export/README.md#android-quick-deployment-and-hq-tips)

## Reproduce

```sh
mkdir -p build/android
python3 -B tools/run_regression.py --logs build/qa/android-quick-deploy/regression
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-quick-deploy-debug.apk
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-quick-deploy-debug.apk \
  --previous build/android/kenyalang-rangers-c37-debug.apk \
  --first-contact --hold-the-line --narrow-escape --campaign-visuals \
  --combat-balance --skill-orbs --ranger-kits --education --facility-growth --ranger-growth \
  --economy-rewards --previous-economy-active --chaos-cap --previous-chaos-capped \
  --production-presentation --android-stabilization --onboarding --audio --soundtrack \
  --logs build/qa/android-quick-deploy/payload
```
