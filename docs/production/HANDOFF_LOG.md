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
