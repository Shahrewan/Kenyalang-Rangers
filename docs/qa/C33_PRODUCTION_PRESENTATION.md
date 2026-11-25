# C33 production presentation

Baseline `eea0279` includes PR #45. Implementation `480879a` adds the approved W29 presentation to Rainforest Chaos and closes gaps in the Story replay, Outreach, Records and Settings interfaces. The player build uses Godot `4.7.2.stable.official.ed1daf0bf` and the matching Android debug template. [PR #46](https://github.com/Shahrewan/Kenyalang-Rangers/pull/46)

## Audit and implementation

Reviewed the supplied SimSimi GDD §§ I, M.7–10 and P, the two UI storyboard parts, the W29 catalog and art receipts, and the live screens reached from the launcher. The Story board and actor clips retain their original combat-clock consumers. The new bindings use existing production assets.

| Live screen | Review result |
| --- | --- |
| Leader naming, Main Menu, save recovery and reset | Reviewed the menu, startup and recovery paths against S01–02 and S52–55. The Android and project icon now uses the approved W29 hornbill. Existing home cards, offline profile handling and reset confirmation were verified through the current suites. |
| Chaos routes and regional previews | S35, storyboard p. 71. Removed the explicit route and trophy stand-ins. Preview draws the same asset registrations and tile/route resources as battle, including both of Gunung Mulu's entries and the woodland foreground. The map scales uniformly. The threshold panel uses the same approved trophy layers as Headquarters, and shows the three Facility badges and exact thresholds. |
| Chaos waves, loadout, modifiers and score | S36–38, pp. 72–74. Each of the 15 standard enemies and three bosses has its own badge. Loadout cards, including post exclusions under Fixed Stockpile, use the approved Ranger and Facility badges. All 30 modifier IDs use their authored glyph registrations. The score panel shows the projected trophy, effective C32-E credit and qualifying payout. It and the builder scroll independently. |
| Chaos battlefield, Enemy Intel, pause, boss and results | S09–19, S39–40 and S57. Verified the six illustrated fields and both Gunung Mulu entries. The live HUD uses larger W29 wave, Integrity and Token glyphs and wraps long region names. Imbak Canyon uses the approved Heat art. Pause lists enemy badges. Boss introductions and phases use the boss's approved portrait and the existing dialogue pause. Clear, escape and defeat receipts use their live outcomes and payout state, with the saved trophy and earned Facility badges. |
| Story map, planning, dialogue, pause and results | S03–24 and S56. The opening planner now shows the mission supply and E01 badge. C1-02 and C1-03 use the full W29 field catalogue so later-owned units selected on replay have art. C1-01 retains its starter-only presentation. The early Poacher/Runner fist attachment and story triggers, including cinematic withdrawal, use their existing cues. The Story portrait panel and pause HUD were exercised through the live Story route and established fixtures. |
| Headquarters overview, all 11 rooms, Finance and upgrades | S25–34. Visited the built and unbuilt room screens, Ranger and Facility rosters and upgrade panels. The existing W29 office artwork, roster badges and actual current/target statistics were already bound. |
| Habitat Restoration | S47–51. The clearing, plot beds, seeds, growth-stage trees and milestone flows use the existing Garden art. The labeled Garden fallbacks are resource-failure paths. |
| Outreach and response receipt | S41–42, pp. 77–78. The Operations Manager appears for the prompt and reacts to the persisted Best, Acceptable, Poor or Harmful grade with the corresponding approved expression. The question, explanation and credited Funds are read from the existing bank and settlement. |
| Records archive, quiz chapters, article and quiz | S43–46 and S60. The archive uses the four dedicated W29 chapter plates, and its article reader uses the approved panel artwork. The existing timer, response and first-perfect receipts are covered by the education suites. |
| Settings, battle Settings, controls and Field Guide | S52–55. Sound and mute glyphs reflect the stored slider values and retain their labels and numeric percentages. Pause opens Settings and returns to the same paused combat tick. The Developer Funds panel retains its existing availability. |
| Development and support fixtures | The sample battle, enemy practice and isolated modifier trial use labeled instructional previews. The trial remains reachable through its explicit practice action. Source-art rigs, atlases and review scenes are build inputs or QA fixtures. |

The 960×540 render at 130% exposed trophy text wrapping a character per line and longer Chaos HUD names being truncated. The threshold labels now span the trophy panel, and the battle title wraps as needed. The route buttons identify exactly one selection. The wave picker and loadout retain their touch actions, and scrollable content leaves the main navigation reachable.

## Native gameplay evidence

The C33 runner produced 52 real Godot frames for each of 1280×720 and 960×540 at both 100% and 130%. Full captures and logs are available locally in `build/qa/c33/native`. The figures below are a selection committed as native PNGs.

| Route | Picker 960×540 / 130% | Live combat 960×540 / 130% |
| --- | --- | --- |
| T01 Forgotten Patrol | [Picker](c33/960x540-130/route-t01.png) | [Battle](c33/960x540-130/battle-t01.png) |
| T02 Gunung Mulu | [Picker](c33/960x540-130/route-t02.png) | [Battle](c33/960x540-130/battle-t02.png) |
| T03 Batang Ai | [Picker](c33/960x540-130/route-t03.png) | [Battle](c33/960x540-130/battle-t03.png) |
| T04 Tanjung Datu | [Picker](c33/960x540-130/route-t04.png) | [Battle](c33/960x540-130/battle-t04.png) |
| T05 Imbak Canyon | [Picker](c33/960x540-130/route-t05.png) | [Battle](c33/960x540-130/battle-t05.png) |
| T06 Sepilok-Kabili | [Picker](c33/960x540-130/route-t06.png) | [Battle](c33/960x540-130/battle-t06.png) |

| Screen | Evidence |
| --- | --- |
| Chaos configuration | [Waves](c33/960x540-130/chaos-waves.png) · [Loadout](c33/960x540-130/chaos-loadout.png) · [Buffs](c33/960x540-130/modifiers-buffs.png) · [Debuffs](c33/960x540-130/modifiers-debuffs.png) · [Capped score](c33/960x540-130/capped-score.png) |
| Chaos pause and boss | [Pause/Intel](c33/960x540-130/chaos-pause.png) · [Diversion Captain at 960×540](c33/960x540-130/chaos-boss-dialogue.png) · [Diversion Captain at 1280×720](c33/1280x720-100/chaos-boss-dialogue.png) |
| Chaos settlement | [Qualifying clear](c33/960x540-130/chaos-victory.png) · [Escape with no payout](c33/960x540-130/chaos-escape.png) · [Fatal escape](c33/960x540-130/chaos-defeat.png) |
| Story | [First Contact planner](c33/960x540-130/story-planner.png) · [Hold the Line replay with Medic and Sonic](c33/1280x720-100/illustrated-replay-loadout.png) |
| Actor cues at 1280×720 / 130% | [K9 companion, Seer and recharge orbs](c33/chaos-k9-seer.png) · [Strike Team arriving on two cells](c33/chaos-strike-incoming.png) |
| Outreach and Records | [Prompt](c33/960x540-130/outreach.png) · [Best response](c33/960x540-130/outreach-response.png) · [Records](c33/960x540-130/records.png) · [Article](c33/960x540-130/records-article.png) |
| Settings | [Main Menu Settings](c33/960x540-130/settings.png) · [In-battle Settings](c33/960x540-130/settings-in-battle.png) |
| 1280×720 / 100% comparison | [T02 picker](c33/1280x720-100/route-t02.png) · [T05 Heat HUD](c33/1280x720-100/battle-t05.png) · [Wave builder](c33/1280x720-100/chaos-waves.png) · [Clear](c33/1280x720-100/chaos-victory.png) · [Records](c33/1280x720-100/records.png) |

## Verification

| Check | Evidence |
| --- | --- |
| Editor import, project startup and full regression | 5,353 checks across 42 runners. C33 adds 257 checks, including all route geometries/registrations, eligible controls, exact badge identities, live portraits, the 1×/2× clock, settings return flow and all three result paths. |
| Native review | Four passes, 309 checks in each. The same runner drove the launcher at both viewport sizes and both text sizes. The Linux llvmpipe driver reported that it cannot change V-Sync mode. |
| Gameplay and score | The real capped T01 run defeated all three enemies, retained 100 Integrity, credited 2,600 Funds at 130 Medal Score and remained unranked. Removing the defender for a one-E01 run produced 90 Integrity, one escape and zero payout. Letting E15 through produced defeat and zero payout. Hold the Line resolved at tick 8,169 with 17 defeated, one escaped and 90 Integrity. |
| Full fresh Campaign and returning profile | The C32-D one-save combat playtest reproduced all 15 clears, earned 7,885,000 Campaign Funds and ended with 3,355,121 Funds after purchases. The returning C2-07 replay preserved the perfect clear and granted Firebreak with the 6,500 replay receipt. |
| Art validators | W29 assembled-art probe passed 732 checks. W29 catalog, Campaign registrations and Android allowlist matched their source receipts. W27 and First Contact validators checked the original atlas, layers and assets. |
| Animation and field checks | The shared visual test checked all 12 Ranger and 13 Facility bindings, including deployment, damage, support, build/Ready/Active/destruction, 1×/2× and the Sentry Tower's mounted Scout and reserved cell. W29 checked the exact clip contracts for all 15 enemies and three bosses. Story and Chaos fixtures exercised representative live clips. The C31-B native runner checked K9 attachment, Specialist cues, Strike Team arrival and compact skill orbs. |
| Exported Android resources | Boot and 3,438 host checks replayed the APK's shipped assets. A fresh profile and a C32-E profile both passed seed/resume/verify. Added Outreach, Records and HUD paths are explicitly included in the selective export. |

```sh
python3 -B tools/run_regression.py --logs build/qa/c33/regression
godot --headless --path . --script res://tests/art/w29_pack_probe.gd
python3 -B tools/build_w29_art_catalog.py --check
python3 -B tools/build_campaign_visual_data.py --check
python3 -B tools/verify_first_contact_art.py
python3 -B tools/verify_w27_art.py
godot --headless --path . --script res://tests/playtest/c32_d_fresh_campaign.gd
godot --audio-driver Dummy --path . --script res://tests/unit/c33_production_presentation_test.gd -- "$PWD/build/qa/c33/native/960x540-130" 960x540 130
```

## Android candidate and remaining checks

The signed ARM64 debug APK is `build/android/kenyalang-rangers-c33-debug.apk`, SHA-256 `3c65701a59673d6edb7fa1e5540b041b22961107421e4e33566c103eb99b30b9`. It passes signature schemes v2/v3 and 16 KiB ZIP alignment, uses Android API 24 minimum and API 36 target, and has the same debug signer as the C32-E candidate. The regular launcher icon is the approved hornbill. `aapt2` still reports the template's missing optional themed-icon XML, also present in C32-E. The hosted run used the APK payload and a desktop renderer. ADB reported zero attached devices.

1. On a physical landscape phone, record the Android API, model, display size and cutout position. Install with `adb install -r build/android/kenyalang-rangers-c33-debug.apk` using the same debug signer for a returning profile.
2. Go offline and visit Chaos at 100% and 130%. Tap all six routes, including the lower entry at Gunung Mulu and the Heat route at Imbak Canyon. Drag the enemy slider, use plus/minus, and swipe both scroll columns independently. Toggle a Research buff and an eligible debuff, then check the effective score and payout.
3. Deploy and pause, open Settings and return to the same paused battle. Resume at 1× and 2×. Check tiles and unit readability near the cutout, tray drag and hold actions, boss dialogue and the clear/escape receipts.
4. Open Outreach and Records, confirm the response portrait and article frame, and relaunch to verify that the text size, trophy and existing saves carry over.

## Changed files

- `scripts/battle/{battle_scene,campaign_battle,chaos_battle}.gd` and the related `scripts/ui` scene controllers bind art to existing combat and menu state.
- `data/presentation/w29/art_catalog.json`, the W29 audit and the export tools record the approved glyph registrations and package dependencies. `project.godot` selects the approved icon.
- `tests/unit/c33_production_presentation_test.gd` exercises the new runtime paths. `tests/unit/c28_hold_the_line_test.gd` replaces its old replay-art fallback expectations with exact rig assertions while retaining the deterministic combat fixture.
