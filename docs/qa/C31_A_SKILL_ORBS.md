# C31-A · Compact active skill orbs

Baseline `f694677` includes C30 / PR #37. The renderer and verification are in `77b0014` on `feature/c31-a-skill-orbs`. [PR #38](https://github.com/Shahrewan/Kenyalang-Rangers/pull/38)

The shaded orb is 17 px across at an 80 px tile and 12.75 px across at a 60 px tile. Ready uses a check, Recovering uses a dim sphere and an amber radial fill, Locked uses a lock, and Spent uses a minus. A Ready check stays visible while another charge refills, and a small numeral shows current stock or charges for multi-charge skills. The existing selected-unit readout retains the full count, lock reason, and seconds. The renderer reads `BattleSkillStatus`, including its combat-time Ready flash.

Rangers use the rest bounds of the head and hat in the mirrored rig transform, with up to 2.5 rig units of live head movement. Mounted Scouts inherit the Sentry roof socket. The two stock Facilities use their placed W29 roof and indicator registration, or their construction art while pending. The renderer tests nearby positions against health bars, silhouettes, other orbs and board overlays. Woodland foreground still draws above the orbs. C30’s combat, skill timing, saves and touch actions retain their existing code.

## Matching C30 comparison

Both columns show C2-01 at the same opening-wave fixture with a 3/4 Guard and a Records-locked Scout. The selected Guard still shows its full count and recharge time.

| Native size and text scale | C30 | C31-A |
| --- | --- | --- |
| 1280×720 at 100% | [Before](c30/1280x720/opening-recharge-and-lock.png) | [After](c31-a/comparison/1280x720/after.png) |
| 960×540 at 130% | [Before](c30/960x540/opening-recharge-and-lock.png) | [After](c31-a/comparison/960x540/after.png) |

## Live finale examples

A separate fixture opens C2-10 through Story. It adds Tokens to stage the dense composition. The registered board, authored enemies, placement rules, skill activations, Facility stock, and clock are live. The spent Medic uses real target confirmation after simulated injury. The crowded frame contains multiple active enemies, a Barricade, two Guards with independent state, and a Scout mounted on the Sentry Tower. The mixed frame shows the two Guards’ different charge counts, the EMP’s recharge, the Medic’s spent state, and the mounted and unmounted Scouts’ Records locks.

| Example | 1280×720 · 100% | 1280×720 · 130% | 960×540 · 100% | 960×540 · 130% |
| --- | --- | --- | --- | --- |
| Single Ranger | [View](c31-a/1280x720-text100/single-ranger.png) | [View](c31-a/1280x720-text130/single-ranger.png) | [View](c31-a/960x540-text100/single-ranger.png) | [View](c31-a/960x540-text130/single-ranger.png) |
| Construction and Records locks | [View](c31-a/1280x720-text100/construction-and-records-lock.png) | [View](c31-a/1280x720-text130/construction-and-records-lock.png) | [View](c31-a/960x540-text100/construction-and-records-lock.png) | [View](c31-a/960x540-text130/construction-and-records-lock.png) |
| Cabin and Calltower replenishment | [View](c31-a/1280x720-text100/facility-replenishment.png) | [View](c31-a/1280x720-text130/facility-replenishment.png) | [View](c31-a/960x540-text100/facility-replenishment.png) | [View](c31-a/960x540-text130/facility-replenishment.png) |
| Crowded finale | [View](c31-a/1280x720-text100/crowded-finale.png) | [View](c31-a/1280x720-text130/crowded-finale.png) | [View](c31-a/960x540-text100/crowded-finale.png) | [View](c31-a/960x540-text130/crowded-finale.png) |
| Ready with refill, recovering and spent | [View](c31-a/1280x720-text100/mixed-skill-states.png) | [View](c31-a/1280x720-text130/mixed-skill-states.png) | [View](c31-a/960x540-text100/mixed-skill-states.png) | [View](c31-a/960x540-text130/mixed-skill-states.png) |

## Verification

Godot `4.7.2.stable.official.ed1daf0bf` passed editor import, startup and **3,324 checks across 34 runners**, including all 37 C30 combat checks and 37 C31 checks. The C31 runner checks the 60/80 px tile size, radial angles, viewport edges, HP clearance, native placement overlap, mixed skills, Facility stock, and the pause and 1×/2× combat clock. Each of the four native runs passed 74 checks and saved five PNGs. The two C30 comparison replays each passed 15 checks. Mesa llvmpipe reported its virtual display VSync warning.

The W29 catalog and Campaign export selection checks passed, as did the W29 732-check art probe, 753-check menu probe, First Contact art check, and W21 inventory. The signed ARM64 APK passed v2/v3 signature verification and 16 KiB alignment. Its exported resources passed the C31/C30 checks, the full Story verification and fresh and returning C30 save checks. SHA-256 `28ed4be3d652c4772dd2ad2361f9c9b14166d5ba54ef8e981548fe5c2db9075b`.

```sh
python3 -B tools/run_regression.py --logs build/qa/c31-a/regression
godot --path . --audio-driver Dummy --resolution 960x540 \
  --script res://tests/unit/c31_skill_orb_test.gd -- "$PWD/build/qa/c31-a/native/960x540-text130" 960x540 130
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c31-a-debug.apk
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-c31-a-debug.apk \
  --first-contact --hold-the-line --narrow-escape --campaign-visuals --combat-balance --skill-orbs \
  --previous build/android/kenyalang-rangers-c30-debug.apk --logs build/qa/c31-a/payload
```

ADB listed zero attached phones. Physical Android readability, touch and performance remain pending. Install the test APK with the compatible signer, then check adjacent Guard counters, a Scout on a Sentry Tower and Cabin restocking at 100% and 130% text. Hold a unit to compare the orb with its full readout. Pause during recharge and resume at 2×. [Android installation procedure](../../export/README.md#install-and-check-on-a-phone)

Runtime files are `scripts/ui/battle_skill_orb.gd`, `scripts/ui/first_contact_field.gd` and `scripts/ui/sample_board.gd`. The Android preset selects the renderer and the payload verifier exercises the existing Campaign resources. [Changed files](https://github.com/Shahrewan/Kenyalang-Rangers/pull/38/files)
