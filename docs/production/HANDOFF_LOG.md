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
