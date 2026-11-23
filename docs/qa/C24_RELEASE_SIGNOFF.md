# C24 Android release sign-off · RC1

**Internal device-test candidate ready. Distribution sign-off is on hold.** A signed, non-debuggable ARM64 player APK was produced on 23 November 2026. The clean source suite passed 1,977 checks. The signed package's Godot resources passed host gameplay and cross-process save checks. ADB reported zero attached devices. The required human-verified offline installation, signed update and representative Android playthrough remain open. [Install, play and rebuild](../../export/C24_HANDOFF.md) · [Binary fingerprint and metadata](evidence/c24/build.json)

## Artifact identity

| Field | Verified result |
|---|---|
| Display name and Android identity | Kenyalang Rangers · `com.shahrewan.kenyalangrangers.dev` · `0.1.0-rc.1` (code 2). The prior C23 player uses the same package and signing certificate, code 1. |
| Source and engine | `19cdf2a5e6119261304581c2a30df4da03a64856` · Godot `4.7.2.stable.official.ed1daf0bf` · matching `4.7.2.stable/android_release.apk`. Both packaged native libraries matched the ARM64 release template byte for byte. |
| Toolchain | Temurin OpenJDK 17.0.21.1, Android Platform 36, Build-Tools 36.1.0, Platform-Tools 37.0.3. Standard APK export, local signing after alignment. |
| File | `kenyalang-rangers-0.1.0-rc.1-internal.apk` · 27,750,367 bytes · SHA-256 `655473bf4a97758d16e0e1688e4103e598c62e4e938bfc8a0c05d1eae6048394`. The JSON records unsigned, template and signer fingerprints too. |
| Manifest | Minimum API 24, target API 36, ARM64 only, landscape, OpenGL ES 3 and Compatibility renderer. No requested Android permissions, including INTERNET. App backup is disabled. |
| Integrity and contents | APK v2/v3 signature verified. ZIP CRC and 16 KiB alignment passed. Both ARM64 libraries have 16 KiB ELF LOAD alignment. The APK contains 390 Godot asset entries, the player launcher, W13 manifest and 15 stage files. Review banks, test scripts and the C23 benchmark scene are excluded. |
| Launcher art | The 192 px classic icon decoded pixel-identically to the project development PNG. The adaptive foreground differs from the stock template. The background and monochrome rasters match the template. The package inspector reports a missing optional themed-icon XML. Final owner-approved icon and physical launcher appearance remain open. |

D-015 targets private APK sideloading. RC1 uses the existing development signer for C23 continuity. The team controls the decision on `com.shahrewan.kenyalangrangers`, final signer and recovery custody. No public release or store submission was made. [Decision log](../canon/DECISION_LOG.md)

## Device and host matrix

| Environment | Install, offline use and update | Gameplay, presentation and performance |
|---|---|---|
| Physical baseline target · Android 9 / 3 GB / ARM64 / ES 3 | **Unrun.** No attached model or OS build. | Touch, cutout, audio, frame timing, memory and human observations pending. |
| Physical preferred target · Android 11+ / 4 GB+ / ARM64 | **Unrun.** No attached model or previous signed install. | Fresh launch, returning save, background/resume and long session pending. |
| Linux x86-64 · pinned Godot headless | APK asset pack loaded on host. Clean RC1 profile, then two RC1 cold relaunches. A separate run created a profile with the C23 APK payload, then used it across two RC1 processes. | Gameplay and wallet verified below. Android package-manager update, activity lifecycle, platform rendering and phone audio require hardware. |
| Linux x86-64 · X11 / Mesa llvmpipe / 960×540 | Launched the signed RC1 asset pack directly. | Rendered Campaign runner passed 249 assertions plus three screenshot captures. First Contact showed 14 defeated, zero escaped and 100 Integrity. Linux software-rendered C23 load results remain the latest benchmark. [C23 measurements](C23_SYSTEM_AUDIT.md#dense-wave-benchmark) |

## Acceptance evidence

| C24 check | Observed outcome |
|---|---|
| Editor and launcher | **Pass on host.** Clean committed archive imported, booted and passed 1,977 checks across 28 isolated runners. The separate process-kill recovery test passed. [Source suite](evidence/c24/source-suite.txt) |
| First use and returning save | **Pass on packaged host resources.** Naming through the actual UI created a 10,000 Funds profile. Six simulated Finance storage cycles funded real room purchases, a Records upgrade and a planted Fig. Two later processes restored the name, room levels and 12,000 Funds, then settled 53,000 once and reopened at 65,000 Funds. Both the fresh and C23-to-RC1 paths passed. |
| C1-01, later stage and boss | **Pass on packaged host resources.** Three synthetic touch deployments and autonomous Ranger attacks cleared C1-01. C1-02 funded planning, pause, interruption and abandon were exercised. The ordered Campaign runner drove all 15 stages, including Captain capture, Foreman phases/escape and the Poacher Leader finale. For later stages it injected damage and selected escapes to reach scripted transitions. Player difficulty remains unmeasured. |
| HQ, Chaos and Garden | **Pass on packaged host resources.** Room and deployable purchase/upgrade, confirmed and cancelled transactions, wallet cap, Chaos 999/1,000, 1,999/2,000 and 2,999/3,000 boundaries, the 1,350-point preview and settlement, 51st-enemy rejection, and Garden watering, collection and reload passed. Garden used controlled timestamps. |
| Outreach and Records | **Gameplay blocked in RC1.** On the actual packaged screens, Outreach displayed the bank approval gate and the unlocked Records Lv.2 room kept its chapter disabled. Source-only education tests passed with explicit synthetic data. W18 validation passed for 20 Outreach and 40 Records draft questions. Team approval and final Records award values remain outstanding. |
| Controls, conservation and credits | **Pass on host.** Main Menu FAQ, pause controls, cited sources, returning navigation, local credits and Godot license were exercised. The offline source index names Forest Department Sarawak and the IUCN Hornbill Specialist Group. The credits identify Group SimSimi, project art and generated audio. Named asset/fact review and permission sign-off are pending under D-014. |
| Audio and shutdown | RC1 skips playback when Godot selects the silent Dummy driver. The rendered startup and Campaign reruns exited without the earlier retained audio instances. Movie capture still produced 90 frames with 48 kHz stereo PCM, peak 599 on the signed-16 scale. Forced quit during movie recording reported two retained objects. X11 also warned that the virtual driver cannot change V-Sync. Speaker output, suspension and shutdown on a phone remain untested. |

The packaged check ran five existing gameplay runners (521 assertions) and two 17-check profile journeys. The update journey begins on C23. These are host executions using resources extracted from the signed APK. The installed player contains no QA fixtures. [Exact payload results](evidence/c24/payload.txt) · [Host replay tool](../../tools/check_android_payload.py)

## Open release decisions

- **Physical acceptance.** Record named phone results for offline install, use, signed update and save continuity. Run the separate C23 benchmark on the same devices. The current workspace has no USB bus and a working ADB server listed no devices.
- **Content and progression.** Five Ranger field kits remain pending. Firebreak Beacon has a mission supply entry and no permanent acquisition source. Campaign dialogue and rewards, most raw-stat endpoints, late-stage balance and the 60-day scenario remain provisional. Local clock changes can advance or delay Outreach and plant timers. [C23 audit](C23_SYSTEM_AUDIT.md)
- **Distribution.** The asset owner and content lead still need to clear the shipping icon, artwork, audio and facts. The project owner must confirm the team namespace, signing/recovery custodians and release decision. Store binaries and signing material under private team custody. [Asset audit](../production/W21_PRODUCTION_ASSET_AUDIT.md#provenance-and-approval) · [Education intake](../../data/education/README.md)

The reproducible build, phone checklist, control guide and commands to verify the signed binary are in the [RC1 handoff](../../export/C24_HANDOFF.md).
