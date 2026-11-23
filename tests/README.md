# Automated tests

From the project root, use the stable Godot editor version in `.godot-version`.

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/smoke/project_smoke.gd
godot --headless --path . --script res://tests/unit/battle_simulation_test.gd
godot --headless --path . --script res://tests/unit/deployment_test.gd
godot --headless --path . --script res://tests/unit/logistics_test.gd
godot --headless --path . --script res://tests/unit/first_contact_test.gd
godot --headless --path . --script res://tests/unit/scout_rig_test.gd
godot --headless --path . --script res://tests/unit/campaign_navigation_test.gd
godot --headless --path . --script res://tests/unit/offense_rangers_test.gd
godot --headless --path . --script res://tests/unit/facility_combat_test.gd
godot --headless --path . --script res://tests/unit/enemy_combat_test.gd
godot --headless --path . --script res://tests/unit/boss_combat_test.gd
godot --headless --path . --script res://tests/unit/campaign_resources_test.gd
godot --headless --path . --script res://tests/unit/campaign_story_test.gd
godot --headless --path . --script res://tests/unit/headquarters_progress_test.gd
godot --headless --path . --script res://tests/unit/headquarters_ui_test.gd
godot --headless --path . --script res://tests/unit/modifier_rules_test.gd
godot --headless --path . --script res://tests/unit/modifier_combat_test.gd
godot --headless --path . --script res://tests/unit/modifier_ui_test.gd
godot --headless --path . --script res://tests/unit/chaos_rules_test.gd
godot --headless --path . --script res://tests/unit/chaos_ui_test.gd
godot --headless --path . --script res://tests/unit/education_rules_test.gd
godot --headless --path . --script res://tests/unit/education_ui_test.gd
godot --headless --path . --script res://tests/unit/restoration_rules_test.gd
godot --headless --path . --script res://tests/unit/restoration_ui_test.gd
godot --headless --path . --script res://tests/unit/presentation_test.gd
```

Smoke scripts live in `tests/smoke/`, pure logic tests in `tests/unit/` when needed, and deterministic data under `tests/fixtures/`. Use standalone GDScript `SceneTree` runners, explicit assertions with descriptive failures, and a nonzero exit on failure. Keep tests offline and release-independent. Use fixed seeds and a manually stepped clock for future combat fixtures. Use dedicated test data and a temporary save location for persistence tests.

The current smoke script checks the engine pin, rendering and orientation settings, simulated safe-area math and the Main Menu to Sample battle transitions. Device touch, cutout fit, APK installation and frame rate require separate Android checks.

The C02 runner feeds one fixed frame at a time to the battle clock. It checks exact spawn ticks, empty-wave rest handling, route validation, 1×/2× equivalence, overlapping pause and dialogue, Integrity accounting, and the full fixture through scene controls. Future combat cooldowns and effects should subscribe to `CombatClock.stepped` or use deadlines expressed in its ticks.

The C03 runner checks transactional occupancy and Token costs, attack geometry, skill confirmation, the 350 ms gesture boundary, cooldowns on the combat clock, and synthetic native touch events delivered through the scene viewport. The Android phone checklist is in the [export guide](../export/README.md#c03-deployment-smoke-test).

The C04 tests check opening legality, Post payouts and cooldowns, D05 exclusivity, construction deadlines and exact refunds. The scene checks send synthetic touch through the viewport.

The C05 runner checks blocking and damage, an actual two-wave perfect clear, ordinary clear, defeat, tutorial skip, touch under simulated small-screen safe margins, Retreat, replay rewards and local reload. It writes to an isolated test save.

The C07 rig test reads the W06 manifest and checks neutral registration, real AnimationPlayer motion, clock pause/speed and mirrored or locked facing. The standalone clip preview supports visual joint checks.

The C09 runner checks a legacy save, first-launch naming, Story locks, opening legality, a planner draft with an explicitly unlocked R&D fixture, combat pause and abandon, tray pan versus deployment drag, live HUD and result credits from a completed C1-01. The current player build shows the R&D unlock requirements. The runner uses temporary saves and synthetic touch in a 960×540 viewport. See the [physical-phone checklist](../export/README.md#c09-navigation-and-battle-ui-phone-check).

The C10 Offense runner checks the three Ranger resources and their actual simulation output. It verifies Focus's Records gate and confirmation, the per-target Technological bonus and persistent EMP slow, Guard's fixed frontal coverage and four sequential charges, and combat-time pause and redeploy. It also checks a wave ending with two defeats from one skill. Synthetic touch places all three Rangers, confirms Focus, and restarts the sandbox. See the [sandbox phone check](../export/README.md#c10-offense-sandbox-phone-check).

The C11 runner covers all 13 Facility roles. It checks explicit Siege targeting throughout construction and operation, cancellation and replacement, repairs and kit stock, both cooldown relays, all turret cadences, Tower mounting and detection, Heat and the Specialist discount, and the three status zones. Synthetic touch scrolls the catalog, confirms an injured Scout's kit and reaches a real Siege attack in the same sandbox wave. See the [Facility phone check](../export/README.md#c11-facility-sandbox-phone-check).

The C12 runners exercise all 18 lifecycles, ability timing and counters, boss phases and reinforcement queues, Heat versus HP, capture versus ordinary victory, and capped received-damage marks with B05. The boss runner also opens the sandbox picker and checks actual dialog, phase, capture and return controls. [Encounter matrix](../docs/qa/C12_ENEMY_MATRIX.md) · [Phone checklist](../export/README.md#c12-enemy-and-boss-sandbox-phone-check)

The C14 resource runner checks all six W08 boards, the published wave totals and Control tiers, legal opening plans, fixed effects, reward settlement and backup recovery. The C14 Story runner launches the normal Campaign, clears C1-01 through synthetic touch and automatic combat, and drives the remaining 14 stages with scripted damage. It verifies spawn ticks and routes, Finance and Mechanical, both Heat operations, three fatal escapes, Foreman’s ordinary escape, and equivalent Continue and Skip state. Both runners use temporary saves. [C14 matrix](../docs/qa/C14_CAMPAIGN_MATRIX.md)

The C15 progression runner checks the eleven-room price and capacity ladders, all 25 level purchases, effective outputs, wallet settlement, both participation gates, activity snapshots, migration and failed-write recovery. The C15 UI runner exercises the landscape HQ, price previews, confirmation and cancellation, Finance lifecycle, live loadout capacity, Post payouts, and Settings recovery. Each uses temporary local profiles. [C15 matrix](../docs/qa/C15_HEADQUARTERS_MATRIX.md)

The C16 rules runner checks all 30 definitions and point values, unlock tiers, chapter limits, repeat selection, legal openings, compatibility, rounding and eligibility. The combat runner steps the shared clock through reveal, recon, construction, Siege, Heat, skills and exits. The UI runner opens the normal Story picker and Chaos trial with a temporary profile, changes modifiers and loadouts, and checks the resulting field and save state. [C16 matrix](../docs/qa/C16_MODIFIER_MATRIX.md) · [Phone checklist](../export/README.md#c16-modifier-phone-check)

The C17 rules runner checks the 18 enemy weights, mixed wave cap, empty-slot timing, worked-example arithmetic, payout boundaries, registered escapes and reinforcement accounting. It exercises the threshold transaction, wallet overflow, repeated clears and save retry. The C17 UI runner builds the storyboard's 60-enemy queue through the live composer, checks score and modifier changes, and drives qualifying and unqualified battles on an isolated profile. It then checks a cold relaunch into planning and both trophy views. [C17 matrix](../docs/qa/C17_CHAOS_MATRIX.md) · [Phone checklist](../export/README.md#c17-rainforest-chaos-phone-check)

The C19 rules and UI runners use synthetic banks and isolated profiles. They exercise approval, revision changes, four grades, the 20-hour boundary, clock changes, the participation gate, chapter gates, quiz timeout and pause, cold reload and replay-safe awards. Validate the W18 drafts independently with `python3 docs/production/w18/validate.py`. [C19 matrix](../docs/qa/C19_EDUCATION_MATRIX.md) · [W18 handoff](../docs/production/W18_EDUCATION_BANKS.md)

The C20 rules runner injects exact local timestamps to check all species, offline and backward clock behaviour, watering, replanting, Ecology access, the cap, and save retry. The UI runner opens both garden entrances, sends a touch event through the viewport, and checks all live stages, the one-time visitor and approval-gated discoveries in Records. Both use isolated profiles. [C20 matrix](../docs/qa/C20_RESTORATION_MATRIX.md)

The C22 runner verifies FAQ and article return routes, live mix settings, enlarged text, failed writes, reset cancellation, cold reload, sound generation and a 14-card battle tray. [C22 matrix](../docs/qa/C22_PRESENTATION_MATRIX.md)

Run all Godot smoke and unit checks with `python3 tools/run_regression.py`. Each runner gets a private user directory and log. C23 also supplies the separate process-kill test, 60-day economy ledger and rendered benchmark. [Commands and measured results](../docs/qa/C23_SYSTEM_AUDIT.md#reproduce)
