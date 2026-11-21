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
