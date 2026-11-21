# Kenyalang Rangers — milestone progress tracker

Status key: [ ] Not started, [~] In progress, [x] Verified. Change only after real verification.

## Repository preparation
- [x] GitHub directory scaffolding aligned to the requested design (structure verified on a feature branch; no playable game code implied).
- [x] Both PDFs reconciled into the six requested Markdown files. Catalog and frame coverage checked against source pages.
- [x] W00 exit check verified 137 unique [content IDs](../canon/DATA_CONTRACTS.md#identity-units-and-revisions) and checked [source availability](SOURCE_INVENTORY.md) against the reference and candidate archives.
- [x] Owner approved all 18 W00b choices on 21 November 2026. Final balance values and validation are tracked in the [decision log](../canon/DECISION_LOG.md#open-decisions).
- [x] C01 Godot 4.7.2 stable editor import, PC launch, 9 automated checks and desktop pointer navigation verified.
- [x] C01 signed ARM64 debug APK exported and passed signature, alignment and manifest checks.
- [ ] C01 install and smoke test on a physical Android phone. See [the procedure and device blocker](../../export/README.md).

## Development milestones
- [x] W00 Source inventory, canonical rulebook, decision log and 36 acceptance-based tickets assembled. See [BACKLOG.md](BACKLOG.md).
- [x] W00b Approved the implementation choices and recorded their rationale and scope. See [the approval record](../canon/DECISION_LOG.md#approved-decisions).
- [~] C01 Version-pinned Godot repo, PC smoke and Android debug export verified. Physical-phone install pending.
- [x] C02 Resource-driven grid and routes, shared combat clock and deterministic waves/Integrity verified. Deployment occupancy is tracked in C03.
- [~] C03 Touch input, facing, footprints, cooldowns and retreat verified in Godot. Physical-phone smoke test pending.
- [x] C04 Logistic Tokens, first-free Post, D05 and construction/refunds verified in Godot. Physical-phone smoke test pending.
- [~] C05 First Contact playable slice and debug APK verified off-device. Physical-phone playtest is required before expanding beyond C05.
- [ ] W06 Sprite technical specifications and one Ranger cutout kit
- [ ] C07 Skeleton2D/Bone2D rig experiment + states in Godot
- [ ] W08 UI style guide, map geometry and asset delivery plan
- [ ] C09 Common battle HUD, dialogue and planning shell
- [ ] C10 12 Rangers: data + all behavior + tests
- [ ] C11 13 Facilities: data + all behavior + tests
- [ ] C12 15 standard enemies + 3 bosses + Siege/Heat/status tests
- [ ] W13 All Campaign stage data, full dialogue and art tickets
- [ ] C14 15 stages, unlocks, full dialogue triggers and results
- [ ] C15 Headquarters 11 rooms, levels, upgrades, Funds cap, save
- [ ] C16 R&D 15 buffs + 15 debuffs, eligibility, tests
- [ ] C17 Rainforest Chaos editor/score/payout/trophy
- [ ] W18 Educational content research and final reviewed banks
- [ ] C19 Outreach and Records/Encyclopaedia modes
- [ ] C20 Habitat Restoration, growth and milestone gates
- [ ] W21 Production art/audio coverage and asset license checks
- [ ] C22 Full UI/settings/accessibility/audio integration
- [ ] C23 Save migration, QA/load testing, 60-day balance simulation
- [ ] C24 Android signing, APK, install/benchmark/release checklist

For each row add: owner, Git commit, actual automated test log, manual Android verification, known issues, acceptance sign-off date. These are milestones, NOT estimates of equal development effort.
