# Handoff log

## Repository structure alignment — 2026-11-21
- Added the requested canonical directory scaffold under `docs/`, `data/`, `scenes/`, `scripts/`, `assets/`, `tests/`, and `export/`.
- Preserved `project.godot`, `AGENTS.md`, `README_FIRST.md`, all existing documentation, and legacy directories/assets.
- Added `README.md` and `docs/STRUCTURE.md` as navigation.
- Files in `docs/canon/` are explicitly **draft scaffolds**, not completed or newly approved specifications.
- Reference PDFs have **not** been committed: privacy and distribution permissions need review.
- No Godot game logic, scene, Resource, export build or on-device test was created or run.
- Validation: compare old and new Git tree contents, ensure no deleted files; review pull request before merging.

## Canon and backlog reconciliation — 2026-11-21

- Reconciled GDD v1.0 and the complete tileset/UI storyboard into the five [canon documents](../canon/README.md) and the [36-ticket milestone backlog](BACKLOG.md). Source page, evidence and status are recorded with the catalogs, rules and ticket criteria.
- Verified the 12/13/15/3 combat catalog counts, 15 ordered missions, 11 HQ rooms, 15 buffs, 15 debuffs and four side activities. Checked all 116 frame labels/exit IDs, the room budget, level price endpoints, Chaos worked example, wallet overflow example, Markdown links and ticket dependencies.
- The local candidate design archive matches all 116 UI frames. Static checks found editable SVG geometry and text and resolved the 483 relative asset references. Review the candidate in art tooling before import. Final story/dialogue and question banks, the C1-01 slot exception, final wallet cap and stage payouts remain open in [the decision log](../canon/DECISION_LOG.md).
- Baseline editor import passed with Godot 4.7.2, using `godot --headless --path . --editor --quit`. Gameplay, Android export and physical-device validation remain future milestones.
- Prepared a documentation review commit based on GitHub main at `2e78ab6e13d72237565415299478026f7fc7575d`. The change set is Markdown only.

## W00b approvals — 2026-11-21

- The project owner approved all 18 W00b defaults. [DECISION_LOG.md](../canon/DECISION_LOG.md#approved-decisions) records option B for D-010 and option A for the other 17, with date, rationale, scope and sources.
- [GAME_RULES.md](../canon/GAME_RULES.md) carries the approved gameplay choices. The data contract, activity index and starter backlog now reference the same decisions.
- First Contact's 6/8-enemy and 350 ms settings are approved fixture defaults. The 9,999,999 Funds cap is for the prototype. Shipping values, unresolved content and verification are tracked in [Open decisions](../canon/DECISION_LOG.md#open-decisions).
- This change covers documentation. Godot 4.7.2 passed a headless editor import of the existing project in an isolated checkout. Matching Android export templates, offline APK install and physical-device checks remain in C01.

## W00 and W00b exit check — 2026-11-21

- Verified 137 unique documented [content IDs](../canon/DATA_CONTRACTS.md#identity-units-and-revisions). Preserved all 43 namespaced IDs from the W00 catalog and documented stable IDs for the existing quiz chapters, species and other authored records.
- Compared both PDF hashes and checked the 116 matching candidate SVGs and their 483 relative references. The [source inventory](SOURCE_INVENTORY.md) and art spec limit this archive to candidate sources. Final production art and unauthored content remain missing or pending validation.
- Verified owner approvals D-001, D-002, D-008 and D-013 for the Starter Post, opening validation, C1-01 touch model and Godot 4.7.2 before C01–C05. The 350 ms threshold applies to the C1-01 fixture.
- Godot 4.7.2 passed a headless editor import of the merged project at `ad86cb6`. Android template, APK and physical-device checks are tracked for C01.
## C01 Godot project foundation — 2026-11-21

- Added the stable version pin and landscape project settings, launcher and placeholder screens under `scenes/`, with safe-area projection and navigation in `scripts/ui/`.
- Added a debug Android preset, private build/signing ignores, data conventions and the GDScript smoke runner. The [README](../../README.md) records launch and test commands. The [export guide](../../export/README.md) records debug APK and phone steps.
- Godot `4.7.2.stable.official.ed1daf0bf` passed headless import and startup. The automated smoke script passed all nine checks. Pointer input opened Sample Battle and returned to Main Menu under Linux/X11 with Compatibility and Mesa llvmpipe.
- Android export failed validation because the 4.7.2.stable templates and Android SDK tools were missing and the Java SDK path was unset in the editor. APK installation, offline boot, touch and safe areas on physical Android remain unverified.

## C01 Android debug export follow-up — 2026-11-21

- Verified archive checksums, installed and configured the matching Godot Android templates, JDK 17 and SDK tools in the ignored workspace-local profile. Enabled Android ETC2/ASTC texture imports and added an original labeled development icon.
- Exported the signed `0.1.0-dev` ARM64 APK. APK signatures, alignment, archive integrity and manifest checks passed. Godot headless import, startup and all nine smoke checks passed after the project changes.
- Physical installation remains open. The workspace exposes no USB device bus, and ADB cannot create its default user directory on the read-only home filesystem. See the [phone procedure](../../export/README.md).

## C02 tactical battle foundation — 2026-11-21

- The sample battle now runs a reusable scene with editable map, waypoints, wave groups and an E01 trial definition. The T01 fixture uses 6/8 enemies, 3.5 seconds between spawns and 25 seconds of rest. The moving markers and manual defeat control are for this milestone's tests.
- A 60-step combat clock drives movement and wave scheduling, with independent pause and dialogue holds. Real exits debit Integrity. Scripted withdrawal emits a separate event and preserves the combat registry and counters.
- Godot 4.7.2 passed headless import and launch, nine project smoke checks and 29 deterministic battle checks. Native Linux pointer input opened the battle, held time across pause and dialogue, resumed and resolved a live marker. Physical Android playtesting remains pending.
- The C02 ARM64 debug APK passed signing, alignment and package-content checks. See the [C02 on-device procedure](../../export/README.md#c02-battle-smoke-test).

## C03 deployment and touch gestures — 2026-11-21

- Added separate placement and gesture logic, a touch-first tray, legal-footprint and attack previews, locked melee direction, elevated and reserved occupancy, targeted confirmation and contextual Retreat. Redeploy deadlines use combat ticks.
- Godot 4.7.2 passed editor import, startup, 9 project checks, 29 battle checks and 44 deployment checks. Synthetic native touch exercised invalid and valid drops, holds, and target selection. Linux/X11 pointer testing exercised drag placement, locked facing, Retreat and the confirmation button.
- The signed C03 ARM64 debug APK passed signature, alignment, archive and packaged-resource checks. Physical-phone input and safe-area evidence remain pending because the cloud workspace exposes no USB devices. See the [phone checklist](../../export/README.md#c03-deployment-smoke-test).

## C04 Logistic Tokens and construction — 2026-11-21

- The sample battle now has a transient Logistic Token wallet, the mission-issued Starter Post, a separate ordinary repeat-Post fixture and D05 Fixed Stockpile. Construction and payouts use the combat clock. Unfinished Facilities refund the exact paid cost on cancellation.
- Godot 4.7.2 passed headless import and startup and all 119 assertions across the project, battle, deployment and logistics runners. The C04 tests include synthetic touch placement and cancellation.
- The signed C04 ARM64 APK passed signature, alignment, ZIP integrity and logistics-resource checks. Physical-phone validation remains open. See the [C04 installation and smoke steps](../../export/README.md#c04-logistics-smoke-test).

## C05 First Contact vertical slice — 2026-11-21

- Added a Campaign entry for C1-01, a skippable opening tutorial, automatic Ranger targeting and attacks, Patrolman blocking, HP bars, result feedback and the versioned C05 local save with one-time provisional Funds.
- Godot 4.7.2 passed editor import, startup and 144 automated checks. The C05 fixtures covered all 14 enemies in a perfect clear, a clear with one escape, defeat, save reload, pause, Retreat, and touch under simulated cutout margins. Native X11 at 960×540 verified opening the mission, tutorial Continue, the Post drag and pause.
- The signed ARM64 APK passed signature, alignment, archive and packaged-resource checks. No USB phone was available. The [physical-phone procedure](../../export/README.md#c05-first-contact-phone-playtest) remains the no-go gate before expansion.

## W06 Ranger sprite production pilot — 2026-11-21

- Started from merged C05 at `33726d5`. Pilot v0.2.0 follows the owner’s specific style reference. The [W06 specification](W06_RANGER_SPRITE_SPEC.md) uses that lineup's head and boot proportions, warm ink, olive and oat cloth, and simplified gear for all 12 Ranger briefs. Heights, accents and technical dimensions are pilot choices under D-012.
- The Scout uses the upper-left Ranger's broad brim, ponytail and mantle. The SVG has 19 editable vector layers with separate ponytail and mantle pivots. All 19 transparent PNGs map to the 96 × 96 canvas and fixed ground anchor in the manifest. The reference sheet assembles the actual cutouts and labels their pivots. The isolated style study is a separate illustration.
- All 19 crop registrations, alpha edges and hashes passed. All 18 joints overlap in the neutral assembly. The neutral and two static pose renders stayed connected. Godot 4.7.2 passed editor import, texture load checks, startup and 144 existing checks across `project_smoke`, `battle_simulation`, `deployment`, `logistics` and `first_contact`.
- C05's physical-phone playtest remains open. C07 will use the manifest for the running rig, state animation, flipped facing and phone-scale readability checks before producing the remaining Ranger kits.

## C07 Scout Sniper rig pilot — 2026-11-21

- Built an isolated Skeleton2D/Bone2D preview using the 19 W06 cutouts and manifest. Added seven AnimationPlayer states, ground-anchor mirroring, a locked-facing demonstration, clock pause and 1×/2×.
- Godot 4.7.2 passed editor import, preview launch, 14 rig checks and 144 existing checks. A 1280×720 Linux render visually checked sampled poses from all seven states and mirrored Idle.
- Exported a standalone signed ARM64 preview APK and verified archive alignment and the 19 packaged textures. The standard C05 project and APK remain separate. The C05 and C07 physical-phone checks are still open. See the [rig guide](C07_SCOUT_RIG.md).

## W08 reusable UI and asset handoff — 2026-11-21

- Based on main at `dea0c09`. [UI_COMPONENT_SPEC.md](../canon/UI_COMPONENT_SPEC.md) maps every storyboard frame to a reusable template and its live inputs, including 48 dp measurement, C1-01 supply, layered battle HUD and C09 acceptance cases.
- [ART_ASSET_MANIFEST.md](../canon/ART_ASSET_MANIFEST.md) records ten recovered illustration candidates, six exact layouts, all 56 diagram pieces and ten prioritized delivery tickets. T01 matches the running map and route definitions. T02–T06 remain validated design geometry.
- Matched the two PDF hashes, 116 SVG/PNG pairs and 483 asset links. Reviewed seven rendered PDF pages, re-exported six SVG samples and a temporary S10 text edit, and tested viewer navigation and tray logic in a JavaScript harness. A live offline browser pass and production clearance stay open under D-003/D-014.
- Godot 4.7.2 passed headless editor import, startup and 158 existing checks across `project_smoke`, `battle_simulation`, `deployment`, `logistics`, `first_contact` and `scout_rig`. W08 changed documentation. Physical C05 and C07 checks remain open. C09 acceptance uses the [device check matrix](../canon/UI_COMPONENT_SPEC.md#c09-handoff-and-acceptance).

## C09 Story navigation and battle UI — 2026-11-22

- Based on merged W08 at `9b56916`. Added the shared theme, first-launch Leader naming and routed Main Menu, Story nodes, planning, battle and results. The C1-01 plan binds the mission Ranger roster, Starter Post, D01 and both live stage waves. It shows progression locks and R&D requirements. The new choice was verified with an explicitly unlocked B05 test profile.
- Added the live wave, defeated, Integrity and Token HUD, a horizontally scrolling deployment tray, and full-screen pause with the same wave preview and active enemies. Resume uses the existing combat clock. Confirmed abandon returns to the retained plan with no payout. Results show clear, perfect or defeat, and account separately for one-time Funds.
- Godot 4.7.2 passed editor import, startup and 191 automated checks across seven runners, including 33 C09 checks. At 960×540 under Linux/X11 and Compatibility, native pointer input opened the Story and plan, continued the briefing, deployed the free Post, paused, cancelled an abandon and resumed. The layout kept the HUD and tray clear of the board.
- The signed C09 ARM64 debug APK passed signature, alignment, ZIP and packaged-resource checks. Named phone, installation, measured target sizes and cutout behavior remain pending. C09 uses the existing First Contact operation. The C05 phone gate for expanded combat content remains open. See the [C09 phone procedure](../../export/README.md#c09-navigation-and-battle-ui-phone-check).

## C10 Offense Rangers — 2026-11-22

- Based on merged C09 at `6d800f6`. Added the editable Offense roster and a standalone combat sandbox for Scout Sniper, Crowd Controller and Guard Veteran. Scout prioritizes marked targets and uses confirmed Focus with the Records fixture. Crowd's EMP deals extra basic damage to Technological targets and creates a slowing field with its active. Guard blocks one, attacks two fixed front tiles and restores its four stun-prod charges one at a time. [Trial values](../canon/DECISION_LOG.md#d-007-and-d-008-c10-offense-tuning--2026-11-22)
- Godot 4.7.2 passed clean import and startup, the 67 Offense checks and 191 existing checks. The suite verifies HP, status expiry, a multi-target perfect clear, fixed facing, Aerial exclusions, recharge, pause, redeploy and synthetic touch. Native Linux pointer testing at 960×540 exercised all three deployments and skills, the HUD balance, pause, resume and hold-to-Retreat. [Test commands](../../tests/README.md)
- Signed ARM64 exports for the development build and the separate Offense sandbox passed v2/v3 signature, alignment, archive and packaged-resource checks. The packaged Godot resources from both APKs also started headlessly on Linux. Physical installation and phone input remain pending. [Phone procedure](../../export/README.md#c10-offense-sandbox-phone-check)
- The Offense checkpoint is ready for review. Defense, Support and Specialist each have their own class checkpoint. [C10 work plan](KENYALANG_RANGERS_MASTER_WORK_PLAN.md#c10--codex-build-all-12-rangers-one-class-at-a-time)

## C11 Facilities and Siege — 2026-11-22

- Based on merged C10 Offense at `fc94afa`. Added 13 editable Facility definitions and their Resource, Sentry, Strategist and Status behaviors. The new damage entry point permits Siege on Facility HP throughout construction and operation. The sandbox exercises the real battle simulation, including the Outpost Mechanic repair action. [Catalog](../../data/facilities/catalog.tres) · [Trial values](../canon/DECISION_LOG.md#d-007-and-d-008-c11-facility-tuning--2026-11-22)
- Godot 4.7.2 passed clean import, both scene launches and 352 checks across nine runners, including 94 C11 assertions. Native Linux pointer input at 960×540 verified an invalid drop, tray swipe, kit confirmation, the pinned Siege warning, pause and resumed HP damage. [Test commands](../../tests/README.md)
- Signed the regular development and separate Facility preview ARM64 APKs. Both passed v2/v3 signatures, ZIP alignment, archive and package checks. Their packaged Godot resources also booted headlessly on Linux. USB install and phone input remain pending. [Phone procedure](../../export/README.md#c11-facility-sandbox-phone-check)

## C12 enemy roster and boss encounters — 2026-11-22

- Based on C11 at `9cb1ad0`. Implemented E01–E15 and the three boss templates with typed attacks, status timing, boss phases and deterministic reinforcement arrivals. The enemy sandbox can start every individual encounter or the full standard roster. [Trial values](../canon/DECISION_LOG.md#d-006-and-d-008-c12-enemy-and-boss-tuning--2026-11-22)
- Godot 4.7.2 passed import, both scene launches and 562 checks across 11 runners. Coverage includes 152 standard-enemy and 58 boss and sandbox checks. Native Linux input at 960×540 exercised the picker and Captain intro, phase dialogue, reinforcement, capture and roster return. [Test matrix](../qa/C12_ENEMY_MATRIX.md)
- Signed the regular development and Enemy Sandbox ARM64 APKs. Both passed v2/v3 signatures, ZIP alignment and package checks. An initial preview omitted the catalog dependencies. The rebuilt preview embeds both catalogs, boots headlessly on Linux using the packaged resources and opens Poacher Leader's introduction. USB installation and phone input remain pending because the workspace has no USB bus. [Phone checklist](../../export/README.md#c12-enemy-and-boss-sandbox-phone-check)

## W13 Campaign content handoff — 2026-11-22

- Based on merged C12 at `66b53c2`. The [W13 handoff](W13_CAMPAIGN_CONTENT.md) links 15 review-ready stage specifications, shared JSON bindings, exact proposed spawn queues and six regional art tickets plus the portrait pass.
- Recovered the team's seven-page Chapter 2 draft and marked all 73 bound dialogue sequences as review copy. The C1-03 messenger remains outside the combat registry. Stage Funds remain TBD alongside the scoped C05 trial figures.
- Validated all 15 specs and ran an isolated Godot 4.7.2 resource probe for 49 waves and 1,111 base queued spawns. Pinned import, startup and all 562 existing assertions passed. C14 covers integration. Narrative approval, balance and physical phone checks remain open.
- W13 commit `2d1a544` merged to main at `bb3e60b`. The merge tree matches the verified content branch. [Pull request 14](https://github.com/Shahrewan/Kenyalang-Rangers/pull/14)

## C14 Campaign integration — 2026-11-22

- Loaded all 15 W13 operations into the normal Story route at W13 merge `bb3e60b`. Added five regional geometry templates, ordered Control locks, legal loadouts and all 15 fixed effects. The shared battle clock holds for authored dialogue, and results distinguish the C1-03 cinematic messenger, Captain capture, ordinary boss escape and fatal escape IDs.
- Added the version 1 Campaign profile, atomic updates, recoverable attempt marker, replay tracking, one-time clear and perfect milestones and persistent unlocks. Campaign access handles Finance, Mechanical and Control. The GDD's 10,000 starting Funds and Finance verify the 20,000 Funds C1-02 opening. W13 payout approval and late progression tuning remain open. [Decision record](../canon/DECISION_LOG.md#c14-campaign-playtest--2026-11-22)
- Godot 4.7.2 passed editor import, startup and 928 checks across 13 runners. Synthetic touch and automatic combat cleared C1-01. The scripted sequence cleared all 15 operations with 49 waves and 1,114 total arrivals. Linux pointer at 960×540 opened Story and the plan, used Continue and Skip, dragged the free Post and paused. [Verification matrix](../qa/C14_CAMPAIGN_MATRIX.md)
- The development ARM64 APK passed v2/v3 signatures, 16 KiB alignment, ZIP validation and a packaged-resource boot into C1-01 on Linux. Physical Android install and touch remain pending because the workspace has no USB device bus. [Install and phone procedure](../../export/README.md#c14-campaign-phone-check)

## C15 Headquarters, levels and saves — 2026-11-22

- Built the selectable eleven-room cross-section on C14 merge `30ccb87`. Room data drives exact GDD costs, Finance, Control, loadout capacity, Ecology, Outreach, Records and R&D unlocks. The ordinary planner uses purchased room and unit levels.
- Added all 25 unit price tracks and milestone transactions. The exact Logistics Post yield is live. Unreviewed raw-stat endpoints stay pending, and the five pending Rangers retain level records while their combat kits are being completed. [Decision record](../canon/DECISION_LOG.md#c15-headquarters-and-local-progression--2026-11-22)
- Migrated the version 1 Campaign profile to version 2. The wallet caps credits and records actual losses. The profile holds progress, activity checkpoints, room purchases and unit levels. Recovery restores a valid backup and confirmed Settings reset invalidates the previous profile backup.
- Godot passed pinned editor import, startup and all 1,228 automated checks across 15 runners. Native Linux pointer verified HQ navigation, both actions on the Lv.20 confirmation, and the persisted transaction at 960×540. The signed ARM64 APK passed signature, alignment, ZIP integrity and isolated host payload verification. Physical phone installation remains pending. [Verification matrix](../qa/C15_HEADQUARTERS_MATRIX.md)

## C16 R&D buffs and operation debuffs — 2026-11-22

- One catalog defines B01–B15 and D01–D15. Story keeps the W13 fixed selections and applies one or two distinct player buffs by chapter. The picker explains research gates and effects without usable targets.
- Planning and the field share the resolved stage, roster, opening and Logistic Post rules. The Rainforest Chaos modifier trial checks candidate effects against the loadout, original T01 route and two fixed waves. It previews eligible signed points. C17 can use the resolver with its authored unmodified stage, configured waves and loadout to get the effective slots and point entries.
- Godot passed import, startup and 1,458 checks across 18 runners. Linux pointer verified D05, its B13 conflict and the pre-wave recon cue. The ARM64 debug APK passed signature, alignment, ZIP integrity and 29 isolated host UI checks with its packaged assets. USB installation and touch remain pending. [C16 verification](../qa/C16_MODIFIER_MATRIX.md)

## C17 Rainforest Chaos — 2026-11-22

- The composer uses the six approved boards and existing enemy catalog. It clamps five independent wave slots, skips empty slots and shows the live score, qualifying Funds and trophy preview beside wave or loadout edits. The worked Mulu fixture gives 1,350 Medal Score and 54,000 Funds.
- Real combat settles the frozen score. One profile commit pays Funds, applies the cap, grants newly reached Facilities and updates the best. Registered escapes and defeat forfeit settlement. Relaunch after an interruption recovers the configuration at planning.
- Godot import, startup and 1,592 checks across 20 runners passed. Linux pointer play verified a mixed cap and a 200-Funds victory. The signed ARM64 export passed host-side package and gameplay checks. Physical installation and touch remain open. [C17 verification](../qa/C17_CHAOS_MATRIX.md)

## W18 Education banks — 2026-11-22

- Located the team's early Restoration brief. Finished Outreach and Records sources remain missing from the available material. Draft revision 1 supplies 20 four-choice Outreach situations, 40 four-choice Records questions, 20 facts, five proposed Garden fact links and 32 referenced publications. Each answer has a rationale or explanation. [W18 handoff](W18_EDUCATION_BANKS.md)
- `python3 docs/production/w18/validate.py` passed the three schemas, reference and ID checks, four chapter-to-Ranger bindings, 480 Outreach permutations and numeric location scan. Editorial review checked source scope and location clues. Pinned Godot 4.7.2 editor import, headless startup and 1,592 existing checks across 20 runners passed on C17.
- The mode reviewer and project owner need to approve the bank revision before C19 imports it. Records count and split, final education payouts and new on-device quiz checks remain open. [D-004, D-014 and D-016](../canon/DECISION_LOG.md#open-decisions)

## C19 Outreach and Records — 2026-11-23

- W18 was already merged in PR #19 at `a7176bf`. The three-schema, answer-key, citations and coordinate checks passed again on that merge.
- Headquarters opens both activity screens. Outreach persists rotation, choice order, grades and signed settlement. Records persists the active timed question, feedback and one-time question and chapter awards. The approved-bank loader validates referenced facts, choices and configured payouts. The W18 revision awaits approval and stays outside the player export.
- Godot passed editor import, startup and 1,680 checks across 22 runners. Native Linux exercised the synthetic Harmful deduction, pause and timeout. The signed Android package passed host checks, including the approval gate. Physical installation remains open. [C19 matrix](../qa/C19_EDUCATION_MATRIX.md)

## W19b Restoration art — 2026-11-23

- Delivered the four species at Seed, Sapling and Mature with a shared ground pivot. The art kit includes a flat 3:2 clearing, a reusable plot bed, two hornbill poses, a nest box, two four-frame effects and nine editable foreground sources. Reference facts use the W18 IDs. [W19b handoff and review sheet](W19B_RESTORATION_ART.md)
- Inspected transparent exports and rendered the two- and six-plot layout references at 960 × 540. Godot 4.7.2 editor import, headless startup, 19 texture loads and 1,680 existing checks across 22 runners passed.
- The original `d435892` commit landed on `main` at `4984ccd`. Editable background layers and D-014 release sign-offs remain open. [Pull request 21](https://github.com/Shahrewan/Kenyalang-Rangers/pull/21)

## C20 Habitat Restoration — 2026-11-23

- Main Menu and Ecology open the shared garden with two to six plots. The W19b clearing and sprites show Seed, Sapling and Mature. Device timestamps advance growth offline and stop at the midpoint until watered. One save commits the collection, retained tree, capped Funds, milestones and discovery IDs.
- Three distinct species meet Ecology's Lv.5 participation requirement. The fourth distinct species brings the one-time hornbill visitor and nest box. A further mature collection reaches 100%. The live build uses the GDD's provisional payouts. Garden discoveries appear with citations when their reference copy is approved.
- Passed pinned import and startup, 1,801 checks across 24 runners, and Linux pointer play at 960×540. The signed ARM64 APK passed host verification with all 19 restoration textures. Phone installation and touch remain open. [C20 matrix](../qa/C20_RESTORATION_MATRIX.md)

## W21 Production asset audit — 2026-11-23

- Audited C20 merge `fbeb1c7` against the 127-page storyboard and GDD. The ledger has 358 asset records, all 116 frame mappings and 38 placeholder, conditional and QA surfaces, each linked to a production ticket. All six original maps match the design package. The archive's atlas and illustration sources are candidates. The live Garden has all 19 textures, and Scout uses two of its 19 parts in the tray. [W21 audit and queue](W21_PRODUCTION_ASSET_AUDIT.md)
- The audit validator confirmed 247 external source file fingerprints, 39 static media references and 15 explicit placeholder labels. Godot 4.7.2 loaded the 39 textures and 12 packed scenes. Pinned editor import, startup and all 1,801 existing checks across 24 runners passed.
- C22 begins with field readability and reusable state bindings. Audio, approved portraits, production terrain, D-014 reviews and device validation remain open. [Priorities](W21_PRODUCTION_ASSET_AUDIT.md#production-tickets)

## W21 and C22 — 2026-11-23

- W21 commit `07205a7` merged through PR #23 at `66905b2`. The source validator passed 358 asset records and all 116 frame mappings.
- C22 connects the help and reference reader, shared article navigation, persistent mix and text settings, dedicated dialogue portraits and combat feedback. The audit tracks the new runtime bindings and development assets.
- The Godot regression suite, native mixed-audio recording and ARM64 package checks passed. Physical phone validation, released art/audio and education approval are open. [Verification and phone procedure](../qa/C22_PRESENTATION_MATRIX.md)

## C22 source review — 2026-11-23

- Compared the merge, archived screenshots and 1,838-check baseline with the attached design PDFs. The fixes connect pause Settings and Controls, improve enlarged controls and local drop feedback, identify the conservation sources, restore the Leader's hood, and itemize the Chaos wallet cap preview.
- The updated suite passed 1,861 checks across 25 runners. Linux captures and the signed APK payload support the corrected flows. User and physical-phone sign-off remain open. [C22 source audit](../qa/C22_SOURCE_AUDIT.md)

## C23 regression and balance — 2026-11-23

- Implementation `1780f08` passed 1,975 checks in 28 runners, including the repeatable dense-wave, save failure and catalog checks. The process-kill test and two identical 60-day ledgers passed separately.
- The reference budget funds the 24.16M target on day 58 with staged spending. The installed-content schedule earns 6,363,600. Garden has a 4.71M upper bound and a three-enemy Chaos setup earns 41,200 per clear. Balance proposals await owner review.
- The signed standalone benchmark runs from a separate Android package. Three Linux runs measured 42.47–50.78 FPS. ADB listed zero devices. The release gate awaits actual candidate phone results. [Audit, evidence and open gates](../qa/C23_SYSTEM_AUDIT.md)

## C24 Android candidate — 2026-11-23

- Built RC1 from `19cdf2a` for private testing. Version code 2 shares the development identity and signing certificate with C23 code 1. Release-template libraries, package settings, signatures, alignment, offline permissions and asset selection were checked.
- The clean project passed 1,977 assertions. Packaged host tests covered Story, bosses, HQ, Chaos and Garden, with fresh and cross-version save rehearsals. Physical Android and owner release sign-off remain open. [Candidate, evidence and checklist](../qa/C24_RELEASE_SIGNOFF.md)

## W25 Campaign completion plan — 2026-11-23

- Reconciled the original GDD, W13 and C14/C24 with all 15 loaded stage files. The review documents cover 49 ordered base waves, 73 draft dialogue sequences, 14 hints, 46 pending Funds amounts and 23 implementation tickets. [Approval plan](W25_CAMPAIGN_COMPLETION.md)
- Review starts with the C1-01 to C1-02 funding gap, then covers first-play skill teaching, grants whose field kits are pending, the Firebreak acquisition choice and the Foreman escape branch. The proposals require separate approval.
- On C24 merge `bdbb8f2`, Godot 4.7.2 editor import, headless startup and 1,977 checks across 28 runners passed. The separate 60-day audit reproduced 13 clears and zero Campaign Funds. Authentic later-stage clears and physical Android review remain open.

## C26 Campaign placeholder — 2026-11-23

- Reviewed W25 `f473668`, accepted its authored dialogue, hints and queue baseline for placeholder use, and applied the 10,000 Funds first C1-01 award. Existing v2 first-clear flags retain their settlement meaning.
- Base enemy and boss movement is 10% faster. Shared type cooldowns permit repeat Ranger and Facility placements with independent HP, footprint and interaction state.
- First Contact and Hold the Line cleared with automatic combat. All remaining Story results and boss branches ran with scripted combat in the ordered runner. W25's unpriced awards, late-stage balance and the physical playthrough remain open. [Verification and phone procedure](../qa/C26_CAMPAIGN_MATRIX.md)

## W27 First Contact art — 2026-11-23

- Reconciled the C24 First Contact route with the storyboard, W21, W06 and the existing Scout manifest. The plan covers the T01 board, live and placeholder assets, recommended batch order, drop-in cutout format and per-batch tests. [Production plan](W27_FIRST_CONTACT_ART.md)
- The first review batch has two transparent concept studies, an editable Logistics Post SVG with four registered layers and a same-scale comparison against the W06 Scout. The two unit studies are flattened. Accept visual direction before authoring separate cutouts. [Review sheet](w27/ART_REVIEW_BATCH_01.md)
- Godot 4.7.2 passed editor import, headless startup and 741 checks across 10 existing runners. A separate project loaded eight review resources. Live art binding, D-014 approval and physical landscape review remain open.

## W27 First Contact cutout delivery — 2026-11-23

- The owner approved the initial review and selected bare heads for the Trespasser and enemy art. Delivered original editable Patrolman and E01 masters, 32 independent alpha exports, measured pivots, grip sockets, and separate animation contracts. The original Scout rig and the four editable Logistics Post layers match the previous revision. [Cutout review sheet](w27/review/cutout_review.png)
- Godot 4.7.2 loaded all 32 exports in an isolated rig probe. Sampled all 13 clips in both directions, checked 30 joined pivots and verified 916 neutral and animated samples. Live binding and the physical landscape check remain open. [Import acceptance](w27/IMPORT_ACCEPTANCE.md)

## W27 study-fidelity correction — 2026-11-23

- The owner rejected the illustrated redraw. Rebuilt the 17 Patrolman and 15 E01 parts directly from the approved studies, with new art confined to hidden joints and E01's bare-hair patch. The neutral reassembly matches the normalized study targets within 2/255 per premultiplied channel. [Study comparison](w27/review/study_comparison.png)
- Godot loaded all 32 exports and verified 916 pose samples. The first-contact battle, Scout rig and Logistics Post retain their existing implementations. [Acceptance report](w27/IMPORT_ACCEPTANCE.md)

## W27 approved faction color — 2026-11-23

- The owner approved the study-matched style. Forest Trespasser now has a muted rust jacket and sleeves. The full E01 alpha mask and all 15 part pivots match the approved kit. Use this treatment as a reference for future enemy accents. [Comparison](w27/review/study_comparison.png)
- Re-exported and verified the 32 Patrolman and E01 transparent parts and sampled all 13 clips through 916 poses. The isolation probe also checked the four editable Logistics Post layers. Editor import, startup and 2,011 existing checks across 28 runners passed on C26 merge `8a28739`. Live Story bindings and physical Android review remain open. [Rig acceptance](w27/IMPORT_ACCEPTANCE.md)

## First Contact stage art — 2026-11-23

- Delivered the T01 forest plate, numbered terrain regions, separate entrance and tunnel, placement overlays, interface atlas, three dialogue poses and Scout shot effects. The battle, tutorial, opening and result previews use the approved W27 characters and supplied Post art. [Assets and registrations](FIRST_CONTACT_STAGE_ART.md)
- Prepared the 15-node Story board with Control fog, prerequisite locks and cleared/perfect stamps. Control Lv.1 and Lv.5 previews show the same locations. Godot passed 2,011 regression checks, verified the 56 atlas regions and loaded nine textures. Live scene binding and physical Android verification remain open.

## First Contact woodland edge — 2026-11-23

- The terminal sand trail now crosses the east edge into overlapping woodland. The trail runout, back trees and foreground trees have editable SVG sources and independent transparent exports. Foreground placement conceals the E01 art at the existing escape cell. [Woodland preview](first-contact-stage/woodland_exit_preview.jpg)
- The stage kit includes 56 individual atlas regions, four roster badges and four Post layers in draw order. The presentation manifest links the 19 Scout, 17 Patrolman and 15 Trespasser parts to their existing source manifests. [Integration handoff](FIRST_CONTACT_STAGE_ART.md#woodland-edge-and-separate-exports)
- Godot 4.7.2 loaded 76 registered stage textures. The regression suite passed 2,011 checks and the W27 rig probe passed 916 pose samples. Foreground occlusion was checked at 80 and 60 units per cell. [Verification](FIRST_CONTACT_STAGE_ART.md#verification-and-simulation-handoff)

## C28-A Illustrated First Contact — 2026-11-24

- Integrated the approved woodland branch at `63edd68`. Added the 17-part Patrolman and 15-part E01 scenes and field bindings for the 19-part Scout. T01 art follows the live board positions, and rigs and effects follow the shared combat clock.
- Registered the four Post layers, illustrated HUD, Story nodes, radio portraits and result badges. First Contact outcomes were reproduced through the Story launcher with real combat. The existing C26 movement and repeated placement rules remain in force. [Cases, screenshots and phone checklist](../qa/C28_A_FIRST_CONTACT.md)
- Pinned editor import and startup, 2,037 regression checks, 916 cutout samples and both native captures passed. The signed ARM64 APK passed package checks and host replay. A physical Android review remains open.

## W29 production art audit and first batch — 2026-11-24

- Reviewed post-C28-A main at `9c4e68f`, the original PDFs and external reference assets, and the current shipped paths. [W29 audit and batch plan](W29_PRODUCTION_ART.md) separates artwork, candidates, reusable components and missing art by ID.
- W29-B01 provides the editable E02 Poacher master, 15 independent transparent parts, registered pivots, pose keys and a derived Intel crop. The [review sheet and acceptance report](w29/W29_B01_IMPORT_ACCEPTANCE.md) show both field sizes and the isolated rig proof.
- Godot 4.7.2 passed 386 E02 samples and the 2,037 baseline checks. Original C28-A art and W27 joints passed their existing checks. W29 contains production art and QA tooling. The [W29-C01 handoff](w29/W29_C01_HOLD_THE_LINE_HANDOFF.md) gives the exact scope and tests for the pending live binding after owner review.

### W29-B01 base-art revision — 2026-11-24

- E02 v0.2 supersedes the declined first drawing. Its manifest points to the 13 existing E01 cutouts and preserves E01's bone registration. Its own exports are the neckerchief/jacket part, satchel and badge. The standard-unit base rule and boss exception apply to later batches. [Updated review and import evidence](w29/W29_B01_IMPORT_ACCEPTANCE.md)

- E02 v0.3 retains the approved proportions and E01 pivots, and introduces a short side-part, brick-red field vest, ochre sleeves and charcoal trousers. The refreshed manifest tracks nine variant parts, six shared parts and the badge. [Current review and import evidence](w29/W29_B01_IMPORT_ACCEPTANCE.md)

## W29 full production art delivery — 2026-11-24

- Accepted E02 v0.3 as the style anchor for the wider enemy roster. The [asset delivery](w29/W29_PRODUCTION_DELIVERY.md) records the completed art files, cutout tests and native menu/HQ review scenes.
- The art catalog covers 12 named Rangers, 15 enemies, three bosses, a K9 companion and all 13 Facilities. T01 stays available and T02–T06 have new plates and registered overlay layers.
- Facilities fit the original elevated tile footprints at both scales. All 11 HQ rooms have modular scenery and stationary role-specific Work loops. The theme, dialogue, trophy, Heat and effects artwork are ready as separate presentation assets.
- The [C1-02 binding](w29/W29_C01_HOLD_THE_LINE_HANDOFF.md) uses the compiled E02 rig. The gameplay code and shipping export route still use the existing presentation. Android touch and final release checks follow live binding.

## W29 approved rigging handoff — 2026-11-24

- The owner approved the current production artwork and requested a repository handoff for animation. Commit `b3c0243` anchors the reviewed visuals. The [art catalog and pose contract](w29/W29_PRODUCTION_DELIVERY.md#rigging-handoff) identify the editable masters, assembled rigs and proof images.
- Future boss designs may take more visual freedom to distinguish them from standard units. The registered cuts and reference poses in this handoff use the approved artwork.

## C28-B Hold the Line — 2026-11-24

- W29 PR #32 provided the E02 scene, its six-state clip and the Intel badge. C1-02 now uses those resources through the C28-A T01 adapter. The ordinary Post displays its construction countdown until Ready. The returning loadout uses labeled support and Facility fallbacks.
- The C1-02 live fixture resolved at tick 8169 with 17 defeated, one escaped and 90 Integrity. Godot passed 2,069 regression checks. Both native sizes reproduced C1-02 and all three First Contact outcomes.
- The signed ARM64 test APK passed its dependency audit and host replay, including C28-A profile continuity. Physical Android validation remains open. [Evidence and device procedure](../qa/C28_B_HOLD_THE_LINE.md)

## C28-C Narrow Escape — 2026-11-24

- Bound the approved E03, Medic, Sonic Turret and post-wave-2 messenger visuals to the illustrated C1-03 Story mission. The live fixture covered the 9/11/13 waves, all seven E03 clips, both messenger routes and the three results.
- Settings includes Developer Funds with existing wallet limits and profile saves. Verified add, remove, invalid input, limits and returning profile data.
- Godot 4.7.2 passed 2,115 regressions. The W29 catalog and art checks, 20 native captures, signed APK dependency audit and returning C28-B profile replay passed. Physical Android review remains open. [Evidence and phone procedure](../qa/C28_C_NARROW_ESCAPE.md)

## C29 Live Headquarters — 2026-11-24

- Composed the approved W29 building directly in Headquarters. Eleven registered bays use the saved room levels, furnishings, stationary Work loops and the existing department routes. The lobby uses the approved mount and the saved Chaos tier.
- Verified fresh, purchased and fully constructed profiles, 130% text, and room taps through the constrained scroll layout. Godot 4.7.2 passed 2,209 regressions and 22 native captures.
- The signed ARM64 APK passed the HQ dependency audit and headless replay using the shipped resources and a returning C28-C profile. Physical Android checks remain open. [Evidence and device checklist](../qa/C29_HEADQUARTERS_VISUALS.md)

## C28-D Complete Campaign visual and story integration — 2026-11-24

- The runtime uses the approved W29 field rigs, scenery, portraits and effects with the existing Campaign stage and clock. T01 through T06 are illustrated, including dual T02 entrances and T05 Heat. The original C28-A/B/C outcomes passed. The C1-03 messenger, Captain capture, Foreman escaped clear and finale first-clear/replay paths use the existing story decisions.
- Godot 4.7.2 ran 3,249 regression checks and produced native 1280×720 and 960×540 images. The ARM64 debug APK passed host resource and returning-profile checks. No phone was attached. [Exact tests, gallery and phone procedure](../qa/C28_D_CAMPAIGN_VISUALS.md)
- Five Ranger field kits and the K9 dog remain gated by gameplay support. Unapproved dialogue and payout fields retain their existing status. Late clear gameplay balance, physical Android and D-014 release clearance remain open. [PR #36](https://github.com/Shahrewan/Kenyalang-Rangers/pull/36)
