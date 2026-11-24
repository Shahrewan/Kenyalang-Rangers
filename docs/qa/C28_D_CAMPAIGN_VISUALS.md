# C28-D · Campaign visual and story integration

All 15 missions open through the player-facing Story map into an illustrated battlefield. C1-01–03 keep their original T01 bindings. C1-04 through C2-10 use the expanded W29 renderer and the approved theme on planning, dialogue and results. No W29 source artwork, stage data, dialogue, balance values or saves were edited.

Baseline `33ed205` includes C28-C PR #34 and the C29 Headquarters merge. Runtime commit `1f05b35`, verification commit `9cebcc8` and theme commit `8910613` are on `feature/c28-d-campaign-visuals`. [Pull request #36](https://github.com/Shahrewan/Kenyalang-Rangers/pull/36)

## Mission verification

The Story runner starts on a fresh local profile. It uses the launcher, plans, original Mechanical and Control gates, battle scenes, results and retry navigation. It verifies first perfect clears, one-escape replays and undefended defeats for every operation. The ordered clear reaches 49 waves and 1,114 live arrivals, including three finale reinforcements. It compares each configured arrival's tick, type, wave and entrance against the unchanged mission source. The later clear cases use deterministic damage and an assisted route advance for the single-escape replay. This verifies the authored resolution paths. Full autonomous balance playthroughs of C1-04 through C2-10 require separate playtesting.

| Mission | Board | Waves | Observed presentation or outcome |
| --- | --- | --- | --- |
| C1-01 First Contact | T01 Forgotten Patrol | 6 / 8 | Existing touch combat, briefing, woodland escape and all three outcomes retained. First clear credits 10,000 Funds. |
| C1-02 Hold the Line | T01 | 8 / 10 | Existing E02 art and ordinary Post. The original fixture still resolves at tick 8169 with 17 defeated, 1 escaped and 90 Integrity. |
| C1-03 Narrow Escape | T01 | 9 / 11 / 13 | E03, Medic and Sonic Turret retained. Continue and Skip agree on the post-wave-2 cue and one noncombat withdrawal at 100 Integrity. |
| C1-04 Watch the Ridge | T01 | 10 / 12 / 14 | W29 E04 and E05 use their own field rigs. The E05 teaching cue retains its authored trigger. |
| C1-05 Operation: Full Pivot | T01 | 14 / 18 / Captain | W29 Captain and portrait. The operation uses the 120-Token Fixed Stockpile. Captain phase and capture play through the existing story path. Captain escape is fatal. |
| C2-01 Misty Approach | T02 Gunung Mulu | 16 / 20 / 24 | Both authored entrances and converging routes, plus the approved Poacher alert portrait. |
| C2-02 Siege on the Ridge | T02 | 18 / 22 / 26 | Both entrances and the W29 Demolitionist. Facility warnings read the existing Siege target. |
| C2-03 Aerial Crossing | T03 Batang Ai | 20 / 24 / 28 | T03 bridge and woodland registration, aerial types and exact D07 rest timing. |
| C2-04 Jammed Communications | T03 | 20 / 25 / 30 | Unique Signal Jammer and Recon Drone rigs, plus the authored D13 cadence. |
| C2-05 Automated Pursuit | T04 Tanjung Datu | 22 / 26 / 30 / 32 | Coastal backdrop, woodland and Tracking Bot presentation. |
| C2-06 Capture Operations | T04 | 24 / 30 / 35 | Net Trapper and Tracking Bot art with existing ownership and clear gates. |
| C2-07 Heat in the Gorge | T05 Imbak Canyon | 25 / 30 / 35 / 38 | Illustrated Heat HUD and Firebreak trial. The first Heat increment is at tick 3001. The Beacon uses the original 30 Tokens, raised pair and build deadline. |
| C2-08 Breaking the Line | T05 | 30 / 33 / 38 / Foreman | Foreman portrait and Overheat. Both the defeated-Foreman clear and the Foreman escape clear were exercised. The alternate result has 50 Integrity and 1 escape. |
| C2-09 Desperate Convoy | T06 Sepilok-Kabili | 28 / 32 / 36 / 42 | T06 woodland and Wildlife Trafficker. E15 fatal escape selects the existing defeat copy. |
| C2-10 Final Interception | T06 | 25 / 30 / 36 / 45 / Leader | Leader phases and three phase Runners, fatal escape, capture dialogue and first-clear epilogue. Continue and Skip preserve the phase order. Ordinary replay excludes the epilogue. |

The suite checks the exact geometry of each regional route and entry against the loaded resources, counts visible registries separately from settled combat records, and verifies the original per-type cooldown and early autonomous fixtures. The decisive exits remove art and HP from the foreground on the existing terminal event. W29 timber and foliage draw over the escape approach.

## Live coverage

- Scout Sniper, Patrolman, Combat Medic, Guard Veteran, Barricade Ops, Outpost Mechanic and Crowd Controller all use their own rigs and badges wherever the gameplay allows them. Existing events drive deployment, allowed attack/skill/block clips, damage and removal. Scout muzzle registration, Medic case and Mechanic repair use authored sockets.
- Woods Tracker, K9 Ranger and its dog, Kenyalang Seer, Saboteurist and Strike Team have finished and packaged W29 art. Existing progression still flags their combat kits as pending. The result UI can show approved badges when their existing ownership is granted.
- Every E01–E15 instance and all three bosses resolve their exact rig IDs. The common renderer samples combat movement, eligible windups, active attacks and accepted terminal events. W29 Sprint, Conceal, Jam, Mark, Cast, Breach, Heat, Rally, Overheat, Surge and Captured are sampled from their existing cues. The clock advances poses and temporary effects once per combat step.
- All 13 retain their current footprints. Sentry Tower retains the reserved cell and uses the authored roof mount. Uniformly registered ghosts and the W29 build, Ready, Active, Siege and destroyed states follow the real placement and combat events. Passed Facility fixtures exercise construction and Ready, accepted Siege damage, destruction and release, and use the presentation signal directly to sample each Active clip. Field actions use actual utility/attack events where implemented. The passive coverage Facilities keep their Ready poses.
- Story uses the established illustrated indicators and deployment tray. Later operations add exact W29 loadout and Intel badges, regional planning thumbnails, registered placement overlays, healing, repair, EMP/Slow Field, concealment/detection, mark, stun, net, knockdown, Siege, boss and Heat feedback. T05 alone shows the Heat display in Story. Results use the existing flags and approved art.
- All ten authored portrait/pose combinations resolve. Operations Manager briefing and relieved use the C28 portraits, with concerned using the existing briefing alias. The faceless Leader uses steady, with the existing reassuring alias. Poacher alert uses the approved Poacher art. The messenger uses the same identity key with the C1-03 radio cue. The Diversion Captain and Foreman use confronting. The Poacher Leader uses confronting and captured. The first-clear epilogue adds its W29 plate next to the live responding portrait. Full-screen dialogue holds the combat clock. Authored placeholders and original Continue/Skip behavior remain in use.

Unapproved first-perfect, replay, and late first-clear values remain pending, as does the finale completion award. Final narrative approvals, late-Campaign balance on earned loadouts, and D-014 visual release clearance are open. [W25 approvals and tuning](../production/W25_CAMPAIGN_COMPLETION.md) · [W29 asset audit](../production/w29/asset_audit.csv)

## Native Godot captures

Both columns come from the Godot Compatibility renderer using the Story launcher. The 960×540 run uses 130% text. The automated capture runs step the clock and wait for a rendered frame before saving each PNG.

| Scene | 1280×720 | 960×540 |
| --- | --- | --- |
| Story selection and fog | [Full](c28-d/1280x720/story-selection.png) | [Small](c28-d/960x540/story-selection.png) |
| T01 Forgotten Patrol | [Full](c28-d/1280x720/t01-first-contact.png) | [Small](c28-d/960x540/t01-first-contact.png) |
| T02 Gunung Mulu | [Full](c28-d/1280x720/t02-c2-01.png) | [Small](c28-d/960x540/t02-c2-01.png) |
| T03 Batang Ai | [Full](c28-d/1280x720/t03-c2-03.png) | [Small](c28-d/960x540/t03-c2-03.png) |
| T04 Tanjung Datu | [Full](c28-d/1280x720/t04-c2-05.png) | [Small](c28-d/960x540/t04-c2-05.png) |
| T05 Imbak Canyon | [Full](c28-d/1280x720/t05-c2-07.png) | [Small](c28-d/960x540/t05-c2-07.png) |
| T06 Sepilok-Kabili | [Full](c28-d/1280x720/t06-c2-09.png) | [Small](c28-d/960x540/t06-c2-09.png) |
| Noncombat messenger | [Full](c28-d/1280x720/portrait-poacher_messenger-alert.png) | [Small](c28-d/960x540/portrait-poacher_messenger-alert.png) |
| Captain on the board | [Full](c28-d/1280x720/c1-05-boss.png) | [Small](c28-d/960x540/c1-05-boss.png) |
| Foreman on the board | [Full](c28-d/1280x720/c2-08-boss.png) | [Small](c28-d/960x540/c2-08-boss.png) |
| Leader on the board | [Full](c28-d/1280x720/c2-10-boss.png) | [Small](c28-d/960x540/c2-10-boss.png) |
| Leader portrait | [Full](c28-d/1280x720/portrait-poacher_leader-confronting.png) | [Small](c28-d/960x540/portrait-poacher_leader-confronting.png) |
| First-clear epilogue | [Full](c28-d/1280x720/first-clear-epilogue.png) | [Small](c28-d/960x540/first-clear-epilogue.png) |
| Foreman alternate clear | [Full](c28-d/1280x720/c2-08-alternate-result.png) | [Small](c28-d/960x540/c2-08-alternate-result.png) |
| Finale defeat | [Full](c28-d/1280x720/c2-10-alternate-result.png) | [Small](c28-d/960x540/c2-10-alternate-result.png) |

## Reproduce on PC

Godot `4.7.2.stable.official.ed1daf0bf` passed editor import, startup, and 3,249 checks across 32 runners, including 1,048 Story checks, 244 visual binding checks and the complete original C28-A/B/C tests (26, 32 and 46). The W29 art probe passed 732 checks and the menu review passed 753. The First Contact validator checked 56 atlas regions and 76 imported textures, and the W27 rig validator sampled 916 poses. The W21 ledger passed 1,117 asset entries and 116 storyboard mappings. Each native run passed 675 checks and saved 27 PNGs. Mesa llvmpipe reported that its virtual X display could not change VSync mode.

```sh
python3 -B tools/run_regression.py --logs build/qa/c28-d/regression
python3 -B tools/build_w29_art_catalog.py --check
python3 -B tools/build_campaign_visual_data.py --check
python3 -B tools/verify_first_contact_art.py
python3 -B tools/verify_w27_art.py
python3 -B docs/production/w21/validate.py
godot --headless --path . --script res://tests/art/w29_pack_probe.gd
godot --headless --path . --script res://tests/art/w29_menus/menu_probe.gd
godot --path . --audio-driver Dummy --resolution 1280x720 \
  --script res://tests/unit/campaign_story_test.gd -- "$PWD/build/qa/c28-d/screens/1280x720" 1280x720 100
godot --path . --audio-driver Dummy --resolution 960x540 \
  --script res://tests/unit/campaign_story_test.gd -- "$PWD/build/qa/c28-d/screens/960x540" 960x540 130
```

## Android

The signed ARM64 debug APK uses the matching `4.7.2.stable` templates, package `com.shahrewan.kenyalangrangers.dev`, minimum API 24, target API 36 and version code 1. It verifies under v2/v3 and 16 KiB alignment. SHA-256 `02635e627d9d99b96f71f30fac817702c329a18bf201fc50412f4467b1aaaf41`. The exported-resource run uses the actual APK asset pack with separate fresh and C29 returning profiles. ADB listed zero devices. Device installation, performance, safe areas and real touch checks remain open.

```sh
godot --headless --path . --export-debug "Android Debug" build/android/kenyalang-rangers-c28-d-debug.apk
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-c28-d-debug.apk \
  --first-contact --hold-the-line --narrow-escape --campaign-visuals \
  --previous build/android/kenyalang-rangers-c29-debug.apk --logs build/qa/c28-d/payload
adb devices -l
adb install -r build/android/kenyalang-rangers-c28-d-debug.apk
```

1. Use a compatible signer for a returning profile. Record the phone model, Android API, native display size and cutout position, plus the installed APK digest. Start offline in landscape. Verify the existing cleared/perfect records, Funds, Developer setting and saved leader name.
2. Check Story planning and touch deployment at 100% and 130%, especially the confirm button, loadout scroll, edge tiles and Sentry Tower's reserved cell. Test cancel and retreat. Verify both T02 entrances and T05 Heat.
3. Play early missions and the three boss branches. Check pause, 1×/2×, Continue, Skip, first-clear epilogue and replay. Background and resume during dialogue and combat. Record dropped frames or touch misses during busy mixed waves. [Phone installation prerequisites](../../export/README.md#install-and-check-on-a-phone)

## Changed files

- `scripts/ui/campaign_region_art.gd`, `campaign_heat_display.gd`, `campaign_visual_assets.gd`, `first_contact_field.gd`, `first_contact_skin.gd` and `sample_board.gd` compose the registered visual layers and sample the live state.
- `scripts/battle/campaign_battle.gd`, `battle_simulation.gd`, `enemy_abilities.gd` and `facility_combat.gd` connect the existing Campaign events to the cues. The presentation reads accepted actions and existing deadlines.
- `scripts/ui/story_portrait.gd`, `wave_intel.gd`, `planning_page.gd`, `loadout_picker.gd`, `deployment_controller.gd` and `operation_results.gd` draw the Story portraits, panels and badges.
- `data/presentation/w29/campaign_visuals.json`, `tools/build_campaign_visual_data.py` and `export_presets.cfg` carry the approved art registration and shipped dependency selection.
- `tests/unit/campaign_story_test.gd`, `campaign_visuals_test.gd`, `c28_narrow_escape_test.gd` and `tools/check_android_payload.py` carry the evidence. The W29 audit, W21 fallback locations, production progress and handoff logs record the current state.
