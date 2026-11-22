# Kenyalang Rangers

Godot **4.7.2 stable** (GDScript) game project for Android landscape, offline single-player.

## Starting points
- `project.godot`: Godot project file.
- `AGENTS.md`: development and Codex working rules.
- `README_FIRST.md`: Work/Codex onboarding and handoff pack.
- `docs/production/`: existing work plan, progress tracking, source inventory and unresolved decisions.
- [Canonical specifications](docs/canon/README.md): source-cited game rules, data contracts, art and UI spec, systems catalog and open decisions.
- `docs/reference/`: reference-file handling instructions.
- `docs/qa/`: test evidence and device validation.
- `docs/STRUCTURE.md`: folder map and placement guidelines.

On first launch, enter a Leader name for the offline profile. Open **Story Mode → First Contact** to review the assigned Rangers, free Starter Post, fixed condition and both incoming waves. Story Mode contains all 15 W13 operations. Control reveals fogged nodes. Each operation still requires its predecessor's clear.

Choose **Start operation**, continue or skip the briefing, and drag the Starter Post across two raised tiles. Spend the generated Logistic Tokens on Scout Sniper and Patrolman. Drop Patrolman on the left or right half of the anchor tile to set its facing. Rangers attack automatically. Hold a Ranger to reveal **Retreat**. Pause to inspect waves and active enemies, resume, or confirm an abandon back to the plan. The local Campaign profile saves clears, perfect clears, recruit and Facility unlocks, and which mission to reopen at planning after interruption.

Use **Campaign access** to claim Finance's stored Funds, build Mechanical for 20,000 Funds, and upgrade Control. The trial starts with 10,000 Funds and Finance stores two per active, unpaused second up to 12,000. C1-02 can start after you buy Mechanical and equip the ordinary Logistics Post. Stage and finale payouts display **Funds pending review** while their amounts are unset. Finance is the current playable income source. Live balance, unresolved combat kits and the device checks are recorded in the [C14 matrix](docs/qa/C14_CAMPAIGN_MATRIX.md).

**Sample battle** opens the separate deployment and construction fixtures for testing.

Open `scenes/qa/ranger_sandbox.tscn` with **F6** or run `godot --path . scenes/qa/ranger_sandbox.tscn` to try the C10 Offense Rangers. This sandbox has its own 100-Token budget and a Records fixture for Scout's Focus. [Sandbox controls and phone check](export/README.md#c10-offense-sandbox-phone-check)

Open `scenes/qa/facility_sandbox.tscn` with **F6** or run `godot --path . scenes/qa/facility_sandbox.tscn` to try the 13 C11 Facilities. The sandbox starts with 1,000 trial Tokens and includes projectile, Siege, concealment, aerial and Heat fixtures. Swipe the deployment tray to reach the full catalog. [Facility sandbox and phone check](export/README.md#c11-facility-sandbox-phone-check)

Open `scenes/qa/enemy_sandbox.tscn` with **F6** or run `godot --path . scenes/qa/enemy_sandbox.tscn` for C12. Select the full standard roster, an individual standard enemy, or one of the three bosses. **Practice hit** advances boss trials to the next authored HP threshold through the battle's damage path. [Enemy and boss test matrix](docs/qa/C12_ENEMY_MATRIX.md)

## Source of truth
Implemented code in this Git repository; approved decisions and canonical game specifications govern design. Keep major feature changes on branches, review pull requests before merging into `main`, and prioritize playable C1-01 combat.

## PC launch and checks

Use the editor version in [`.godot-version`](.godot-version), **Godot 4.7.2 stable**. Alias the standard GDScript editor executable as `godot` on your PATH or substitute its full path. Open `project.godot` and press **F5**, or run from the repository root:

```sh
godot --version
godot --path . --editor
godot --path .
```

Run the import, startup and automated checks from the same directory:

```sh
godot --headless --path . --editor --import
godot --headless --path . --quit-after 30
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
```

Expect `4.7.2.stable` in the version, an import and startup free of script errors, and zero failures across the 13 test scripts. The logical layout starts at 1280×720, expands for other landscape aspect ratios, and maps Android system safe bounds into the UI margins. See the [test descriptions](tests/README.md).

## Android export prerequisites

- Install **Godot 4.7.2 stable** and the matching **4.7.2.stable export templates** via **Editor → Manage Export Templates**. The Android Debug preset uses the standard templates and targets ARM64.
- Install OpenJDK 17 and the Android SDK. Install SDK Command-line Tools, accept the SDK licenses, and install Platform-Tools (`adb`), Build-Tools (`apksigner`), and Android Platform 36. The verified export used Build-Tools 36.1.0. The linked export guide lists the full Godot 4.7 toolchain, including packages for custom builds. [Godot 4.7 Android export guide](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html)
- In **Editor → Editor Settings → Export → Android**, set **Java SDK Path** to the JDK root, and **Android SDK Path** to the SDK root. Configure debug signing locally if prompted. The team release identity and key custody are tracked separately.

The C14 cloud build produced a signed ARM64 debug APK. Physical installation remains pending because the workspace has no USB device access for a phone. Follow the [export and C14 phone steps](export/README.md#c14-campaign-phone-check).

## Reference documents
The GDD and 127-page tileset/UI storyboard are separate production references. They are **not automatically included** in this public repository. See `docs/reference/README.md` before uploading PDFs, especially any academic covers containing personal information or signatures.
