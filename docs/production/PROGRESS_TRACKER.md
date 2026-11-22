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
- [x] W06 [Reference-matched specs for 12 Rangers and the redrawn Scout Sniper v0.2.0 kit](W06_RANGER_SPRITE_SPEC.md) verified off-device. C07 covers rigging and phone review.
- [~] C07 Scout Sniper rig, seven states and standalone APK verified off-device. Phone review remains open.
- [x] W08 [UI component spec](../canon/UI_COMPONENT_SPEC.md) and [asset manifest](../canon/ART_ASSET_MANIFEST.md) verified against 116 storyboard states, six board layouts and 56 technical atlas pieces. Asset delivery and phone checks remain in their downstream tickets.
- [~] C09 Story navigation, planning, dialogue, live battle HUD and results verified off-device. Physical-phone touch and safe-area verification pending. See the [phone checklist](../../export/README.md#c09-navigation-and-battle-ui-phone-check).
- [~] C10 Offense checkpoint. Scout Sniper, Crowd Controller and Guard Veteran run in the isolated combat sandbox. Review Offense tests before starting Defense. Support and Specialist follow their own checkpoints.
- [~] C11 All 13 Facility roles and Siege-only HP damage verified in Godot and the sandbox. Physical Android installation and touch checks pending. [Phone checklist](../../export/README.md#c11-facility-sandbox-phone-check)
- [~] C12 All 15 standard enemies, three boss templates and their combat interactions verified off-device. Physical Android playtest pending. [Encounter matrix](../qa/C12_ENEMY_MATRIX.md)
- [x] W13 [Campaign handoff](W13_CAMPAIGN_CONTENT.md) verified as 15 content specs with exact spawn queues, proposed dialogue and art tickets. Final author approval, tuning and C14 integration remain open.
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
