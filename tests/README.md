# Automated tests

From the project root, use the stable Godot editor version in `.godot-version`.

```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/smoke/project_smoke.gd
godot --headless --path . --script res://tests/unit/battle_simulation_test.gd
godot --headless --path . --script res://tests/unit/deployment_test.gd
godot --headless --path . --script res://tests/unit/logistics_test.gd
godot --headless --path . --script res://tests/unit/first_contact_test.gd
godot --headless --path . --script res://tests/unit/campaign_navigation_test.gd
```

Smoke scripts live in `tests/smoke/`, pure logic tests in `tests/unit/` when needed, and deterministic data under `tests/fixtures/`. Use standalone GDScript `SceneTree` runners, explicit assertions with descriptive failures, and a nonzero exit on failure. Keep tests offline and release-independent. Use fixed seeds and a manually stepped clock for future combat fixtures. Use dedicated test data and a temporary save location for persistence tests.

The current smoke script checks the engine pin, rendering and orientation settings, simulated safe-area math and the Main Menu to Sample battle transitions. Device touch, cutout fit, APK installation and frame rate require separate Android checks.

The C02 runner feeds one fixed frame at a time to the battle clock. It checks exact spawn ticks, empty-wave rest handling, route validation, 1×/2× equivalence, overlapping pause and dialogue, Integrity accounting, and the full fixture through scene controls. Future combat cooldowns and effects should subscribe to `CombatClock.stepped` or use deadlines expressed in its ticks.

The C03 runner checks transactional occupancy and Token costs, attack geometry, skill confirmation, the 350 ms gesture boundary, cooldowns on the combat clock, and synthetic native touch events delivered through the scene viewport. The Android phone checklist is in the [export guide](../export/README.md#c03-deployment-smoke-test).

The C04 tests check opening legality, Post payouts and cooldowns, D05 exclusivity, construction deadlines and exact refunds. The scene checks send synthetic touch through the viewport.

The C05 runner checks blocking and damage, an actual two-wave perfect clear, ordinary clear, defeat, tutorial skip, touch under simulated small-screen safe margins, Retreat, replay rewards and local reload. It writes to an isolated test save.

Run the optional C07 rig check after editor import:

```sh
godot --headless --path . --script res://tests/unit/scout_rig_test.gd
```

The test reads the W06 manifest and checks neutral registration, real AnimationPlayer motion, clock pause/speed and mirrored or locked facing. The standalone clip preview supports visual joint checks.

The C09 runner checks a legacy save, first-launch naming, Story locks, opening legality, a planner draft with an explicitly unlocked R&D fixture, combat pause and abandon, tray pan versus deployment drag, live HUD and result credits from a completed C1-01. The current player build shows the R&D unlock requirements. The runner uses temporary saves and synthetic touch in a 960×540 viewport. See the [physical-phone checklist](../export/README.md#c09-navigation-and-battle-ui-phone-check).
