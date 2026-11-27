# C36-D · Audio acceptance, integration and Android candidate

27 November 2026 · Godot `4.7.2.stable.official.ed1daf0bf` · C35 game baseline `24b4aa8` · C36-A manifest `57f5562`

Both batches are revision 2. Their embedded planning CSV hash matched the C36-A CSV. The candidate retains the C35 package identity and signer. Sound effects use the existing PresentationAudio node and the three saved volume controls. The original music tracks, rate, routing and synthesis are identical to C35. The audit covers one-shot SFX.

[Measured master manifest](../../data/audio/sfx_manifest.json) · [CSV mirror](../production/audio/C36_SFX_MANIFEST.csv) · [Runtime registry](../../data/presentation/sfx_catalog.json)

## Acceptance

| Batch | Required accepted | Optional accepted | Source WAV bytes | ZIP SHA-256 |
| --- | ---: | ---: | ---: | --- |
| A | 24 / 24 | 17 / 17 | 1,264,852 | `16fbc900bca258f8336770c60cef0f51a0dd01b1c4206b8227a06d4cd9824166` |
| B | 55 / 55 | 37 / 37 | 2,104,688 | `00038ce39319e39bbca2ce729e69d0b86683a869b2f5c7085e8189a9499a622d` |
| Total | **79 / 79** | **54 / 54** | **3,369,540** | |

**Missing: 0. Rejected: 0. Exact PCM duplicates: 0. Near duplicates flagged: 0.** The waveform screen checks same-length trimmed takes for a normalized correlation of at least 0.97. It cannot establish subjective similarity between different recordings.

The actual manifests matched the canonical cue IDs, paths, cases, entity IDs, actions, one-shot intent and variant assignments. The standard WAV decoder and FFmpeg produced identical PCM for all 133 files. Each file is signed mono PCM16 at 22,050 Hz. Measured duration is 75.011–3,030.023 ms, with each clip within its canonical maximum and within one source frame of target. Sample peaks are −19.319 to −7.001 dBFS, with zero clipped samples. At −56 dBFS, leading quiet is at most 22.540 ms and trailing quiet is at most 84.535 ms. The WAVs contain no loop chunks. The manifest and CSV record each clip's duration, sample peak, RMS, edge measurements, format, byte count, file hash and decoded PCM hash.

The production receipts describe original Kenyalang Rangers cue arrangements with edited CC0-1.0 Foley from OwlishMedia and Kenney. The 34 delivered source-bank excerpts matched their ledger SHA-256. Each accepted cue lists its source keys, and the ledger records the creator, original member, license, crop, original hash and edited hash. The OwlishMedia page identifies CC0. The Kenney page returned HTTP 403 during this audit, so its license is recorded from the supplied production receipt. The committed ledger and runtime WAVs are sufficient to audit the accepted assets without distributing the extracted bank or synthesis instructions. [Per-excerpt provenance](../production/audio/C36_SFX_PROVENANCE.json) · [OwlishMedia source](https://opengameart.org/node/86682) · [Kenney source](https://kenney.nl/assets/impact-sounds)

## Cue-to-event behavior

The measured master manifest lists **114 cue groups** and the exact assets and events for each group. The runtime registry resolves the group to available variants and carries its gain, priority, cooldown, voice limit and fallback. Canonical character and enemy IDs select the field cues.

| Runtime entry | Binding |
| --- | --- |
| Accepted placement, facing, invalid, cancel and removal | Two-step melee deployment emits the detent only when the selected side changes. Actual cost and occupancy commit emits one deploy cue. Cancel, invalid placement and invalid skill have separate feedback. Rangers use living retreat or zero-HP removal, including mounted Rangers. Facilities use start, true Ready tick, cancellation/refund or destruction. The instant first Logistics Post gets a single deploy cue. Woods Tracker net and mounted deployment replace the generic cue when eligible. [Deployment controller](../../scripts/ui/deployment_controller.gd) · [Battle audio bindings](../../scripts/ui/battle_audio_events.gd) |
| Ranger acts | `attack_presented(Attack)` is the one-shot onset for basic attacks. Ranged and launch effects cue from accepted presentation. Hits and bounces are kept inside the one action cue. Accepted skill commit, positive healing/repair, successful Woods Tracker deploy net, Saboteurist retreat EMP and delayed Strike Team landing are separate edges. Every Ranger and the K9 companion use the canonical profiles. The dog has a successful active Howl cue. [Entity map](../production/audio/C36_SFX_ENTITY_AUDIT.md) · [Ranger combat](../../scripts/battle/ranger_combat.gd) |
| Facility acts | Sonic, first accepted Electric burst shot and Canopy launch each get an action cue. Medic Cabin and Specialist Calltower stock use sounds come from accepted skill commits. Skill Relay readiness and Facility restock are based on the empty-to-usable edge. The ordinary readiness timer is separate from cast. Post income sounds only when Tokens were produced. Dispatch, detection, cover, fire protection and other passive auras stay silent in steady state. [Facility combat](../../scripts/battle/facility_combat.gd) · [Deployment state](../../scripts/battle/deployment_state.gd) |
| Enemy actions and status | An accepted enemy attack emits one family or actor cue. Siege windup comes from a committed windup and the specific impact requires accepted damage. E03 Sprint, E06 Smoke, E07 Jam, E09 Track, E10 Net and E13 successful knockdown are semantic cues. An immune or braced Breach is quiet. Hit-evaluation, each status tick, shield changes and normal footsteps stay quiet. [Battle audio bindings](../../scripts/ui/battle_audio_events.gd) · [Enemy abilities](../../scripts/battle/enemy_abilities.gd) |
| Bosses, waves and damage notices | All three registered boss intros and all four configured phases route by identity. Captain capture, Leader defeat and actual escape are distinct. The Foreman uses the existing Integrity outcome. Actual wave start ignores reinforcements, and inter-wave rest omits the final wave. Recon follows the existing HUD visibility edge. Heat overflow and an actual Integrity loss get scoped warnings. The cinematic messenger remains noncombat. [BattleSimulation](../../scripts/battle/battle_simulation.gd) · [Battle audio bindings](../../scripts/ui/battle_audio_events.gd) |
| Results and progression | The visible Story outcome selects defeat, victory, perfect, first-clear finale or an eligible ordinary recruitment receipt. Returning to Story after a newly cleared gate can sound a new operation. In Chaos, a newly settled trophy takes precedence over a new personal best or ordinary qualifying clear. An unqualified result uses defeat. A failed save produces a warning without a reward cue. HQ construction, upgrades, level milestones, Finance claims and credited overflow occur after actual transactions. One receipt sound replaces competing generic feedback. [Launcher](../../scripts/ui/launcher.gd) · [HQ room](../../scripts/ui/headquarters_room_page.gd) · [Permanent upgrades](../../scripts/ui/deployable_upgrade_page.gd) |
| Menus and learning | The basic confirmation and distinct invalid cue remain available everywhere. Changed navigation, deliberate lesson paging, modifier and Chaos wave/quantity commits, Continue/Skip, and battle pause controls use specific feedback. Outreach uses positive for Best/Acceptable and reflective for Poor/Harmful. Records cues correct, incorrect, timeout, completion and first perfect. A resumed review stays quiet. [Outreach](../../scripts/ui/outreach_page.gd) · [Records quiz](../../scripts/ui/records_quiz_page.gd) |
| Restoration | Plant, water and successful harvest use the committed cycle. The receipt uses the visitor, milestone, or ordinary collection cue. A newly observed foreground stage can notify while the plot is open. The first post-suspension growth update stays quiet. [Restoration](../../scripts/ui/headquarters_garden.gd) |

All 16 procedural IDs still resolve. If an accepted file fails to load, a mapped related asset is tried first and the original procedural tone remains the compatibility leaf where the manifest supplies one. No missing-file fallback is needed by the current package. `combat_impact_light` is intentionally shared fallback audio. `combat_support`, `combat_skill`, `combat_boss_alert` and `education_response` are retained as generic compatibility cues alongside more specific live routes. Basic attacks are shorter than their authored repeat intervals. Electric Pulse plays once at the first actual shot of the burst, with later hits carrying its visual effect.

## Mix, CPU and storage

- Android uses eight voices. Desktop uses twelve. Routine battle actions can occupy half the pool. Two voices are reserved for high-priority feedback, and priority 75+ can replace weaker playback when needed. At most four critical voices and at most the authored per-group limit can play. Same-frame requests coalesce by group. Group-specific cooldowns use monotonic audio time and variants rotate independently of game RNG. Siege impact clips use runtime warning priority 84. The bounded 40-file cache loads streams as needed.
- Master multiplies Music and SFX independently. On backgrounding, queued and active effects are cleared. Manual pause and dialogue drop routine battle audio while allowing intentional UI and applicable warnings. Transitions discard prior scene effects. Combat time, purchase state and save settlement have no dependency on playback. [Mixer](../../scripts/ui/presentation_audio.gd)
- WAV sources remain pristine. 121 effects use PCM import. Twelve longer boss and result clips use QOA after the delivered comparison showed a peak difference within 0.5 dB, and their imported streams were independently decoded in this project. Short, frequent sounds and the Stun Prod and Outreach cases with the larger QOA deviations use PCM. The comparison uses original WAVs for both modes.

| Measurement | Bytes |
| --- | ---: |
| Accepted WAV source | 3,369,540 |
| All-PCM import trial across 133 Godot .sample resources | 3,414,767 |
| Default all-QOA import trial across 133 resources | 734,643 |
| Selected PCM/QOA audio resources | 2,749,171 |
| Comparable ZIP compressed SFX entries in PCM-only trial | 2,689,614 |
| Compressed SFX resource entries in the signed candidate | 2,159,356 |
| Sum of selected Godot AudioStreamWAV data buffers | 2,698,102 |
| C35 signed APK | 41,063,412 |
| C36-D signed APK | 43,395,015 |

A controlled Linux headless preload left 40 resources in the cache. The selected import consumed 763,148 stream bytes and added 833,996 bytes of Godot-tracked static memory in that probe. PCM-only used 1,040,876 stream bytes and added 1,111,724 tracked bytes. The 400-block, 256-frame Godot decoder/mix-buffer microbenchmark averaged **15.13 µs** with eight streams in the selected mix versus **9.82 µs** for eight PCM streams. One PCM voice averaged 1.42 µs versus 1.28 µs in the PCM comparison. The harness calls eight simultaneous voice buffers in one timing window. These are host measurements of the resource cache and decoder work. Android mixer-thread timing, hardware memory, and audible mix quality have their own acceptance. [Benchmark harness](../../tests/playtest/c36_audio_cost.gd)

## Verification

- Pinned Godot editor import, headless startup and the full source suite passed **6,023 checks across 50 runners**. The exact signed Android payload booted off-device and passed **4,107 checks across 31 runs**, including the 165-check audio integration runner and the C35 compatible-save rehearsal.
- The focused tests decode all 133 runtime streams through Godot playback buffers, exercise all 16 replacements and simulated asset misses, check pool limits and warning reservations, and verify volume, pause, background and repeated transitions. They exercise bindings for all twelve Rangers, thirteen Facilities, fifteen enemies and three bosses.
- The synthetic touchscreen journey verifies a valid melee drop does not cue before confirmation, changed direction and Cancel do, and the real perfect-clear result dispatches exactly once. Chaos covers a failed save, successful trophy retry and an actual ineligible-escape receipt path in a scripted results fixture. HQ purchase verifies the exact wallet debit before the transaction cue. Outreach covers four committed grades. Records covers accepted answers, timeout and first perfect. Restoration covers planting, watering, collection, and quiet catch-up after suspension.
- The dense 40-enemy comparison runs combat at 1× and 2× with and without the adapter. It kept the same loss at tick 3,320, with 3 defeated, 10 escaped, 0 Integrity and 628 Tokens. Both speeds routed 75 events. The independent legal fresh-profile Campaign run also matched all 15 complete per-mission records from C35, including resolution ticks, clears, progression and **7,885,000 Funds** before purchases. The final wallet was **3,355,121 Funds**. These counts describe game logic and separate presentation instrumentation.
- The Android preset only ships the runtime cue registry, the 133 remaps, imported samples and runtime scripts. The production ZIPs, canonical planning data, raw source copies, provenance, synthesis code and test fixtures stay outside the APK. Off-device payload verification loads the candidate's actual resources and rehearses fresh and returning C35 saves.
- The signed candidate is `build/android/kenyalang-rangers-c36d-debug.apk`, SHA-256 `108624dea08ba2ddd3e6a5d3436c4f7432d7d725ced9e7cb76f59cf1787d3dfa`. It passed v2/v3 signature and 16 KiB alignment checks. The package remains `com.shahrewan.kenyalangrangers.dev`, ARM64, minSdk 24 and targetSdk 36. Both APKs have the same certificate SHA-256 `0b79cac72bf38357eb4aa0dcb68e0b34bff7d2a9503a32e0928186f00b1bf052`. The known-good C35 APK remains available with its recorded SHA-256.
- Physical Android and acoustic listening are pending. ADB reported no attached device. Windows has no preset in this repository. For a future Windows preset, include `data/presentation/sfx_catalog.json`, `scripts/ui/battle_audio_events.gd`, the PresentationAudio script and all accepted WAV references so Godot can include their remaps and samples. Retain the same import settings and verify playback in the exported pack.

## Reproduce

```sh
python3 -B tools/audit_sfx.py --batch /tmp/batch-a --batch /tmp/batch-b --ffmpeg
python3 -B tools/audit_sfx.py --ffmpeg
python3 -B tools/run_regression.py --logs build/qa/c36-d/acceptance-regression
godot --headless --path . --script res://tests/playtest/c36_audio_cost.gd
godot --headless --path . --script res://tests/playtest/c32_d_fresh_campaign.gd
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-c36d-debug.apk \
  --previous build/android/kenyalang-rangers-c35-debug.apk \
  --first-contact --hold-the-line --narrow-escape --campaign-visuals \
  --combat-balance --skill-orbs --ranger-kits --education --facility-growth --ranger-growth \
  --economy-rewards --previous-economy-active --chaos-cap --previous-chaos-capped \
  --production-presentation --android-stabilization --onboarding --audio \
  --logs build/qa/c36-d/acceptance-payload
```

Logs are retained under `build/qa/c36-d`. [Android update and listening procedure](../../export/README.md#c36-d-sound-effects-candidate)
