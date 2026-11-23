# Kenyalang Rangers

Godot **4.7.2 stable** (GDScript) game project for Android landscape, offline single-player.

## Android candidate

RC1 is available for private device testing. The handoff covers the signed APK, offline installation, controls, save continuity and the remaining Android and content gates. [RC1 handoff](export/C24_HANDOFF.md) · [Release sign-off](docs/qa/C24_RELEASE_SIGNOFF.md)

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

Open **Headquarters** to enter or build any of the eleven rooms. Control, Human Resources and Finance start built. Open Finance to claim stored Funds, build Mechanical for 20,000 Funds to equip the ordinary Logistics Post in C1-02, and upgrade Control to reveal more operations. A fresh profile starts at 10,000 Funds and earns another 10,000 for the first clear of First Contact. Finance Lv.1 stores two per active, unpaused second up to 12,000. Unpriced awards display **Funds pending review**. [C26 Campaign verification](docs/qa/C26_CAMPAIGN_MATRIX.md)

Human Resources and Mechanical show Ranger and Facility levels, milestone prices and purchase confirmations. The ordinary Logistics Post gains Token output as it levels. Other raw-stat endpoints await review. Existing C14 Campaign saves migrate to the HQ profile on launch. If a backup is recovered, the game shows a notice and resumes the saved route. Reset is available in **Settings** with confirmation. [C15 verification and open items](docs/qa/C15_HEADQUARTERS_MATRIX.md)

Build and upgrade the four **R&D** rooms to unlock modifiers. In a Story plan, open **Edit modifiers** to choose up to one distinct buff in Chapter 1 or two in Chapter 2. The fixed Story debuffs appear in planning. The Chaos route screen also offers the C16 **Modifier trial**, a fixed two-wave practice encounter. [C16 verification](docs/qa/C16_MODIFIER_MATRIX.md)

Open **Rainforest Chaos → Choose route** or use the ground-floor HQ entrance. Choose one of six original routes and configure up to five waves. Use the sliders and plus/minus to add up to 50 enemies per wave across all enemy types. **Loadout** and **Edit modifiers** update the Medal Score, qualifying Funds and trophy preview. Clearing a challenge requires positive Integrity and zero escapes. Qualifying first clears at 1,000, 2,000 and 3,000 unlock Facilities and change the shared trophy. If a challenge is interrupted, relaunch to review the saved configuration and start a fresh attempt. [C17 verification](docs/qa/C17_CHAOS_MATRIX.md)

From **Headquarters**, build Outreach or Records to open their activity screens. Outreach uses a 20-hour local batch timer and four response grades. Records opens with its cited facts archive and unlocks timed quiz chapters at Lv.2–5. The W18 banks await team review. [Runtime intake](data/education/README.md) · [C19 verification](docs/qa/C19_EDUCATION_MATRIX.md)

Build **Ecology**, then open **Reforestation** from the Main Menu or the Ecology room. Plant a seed for free, water it halfway and collect it at maturity. Growth advances offline as far as the next watering check. Collection releases the plot and keeps the mature tree in the garden. Ecology upgrades expand capacity from two to six plots. The fourth distinct species brings a hornbill visitor and the nest box. [C20 verification](docs/qa/C20_RESTORATION_MATRIX.md)

Open **FAQ** for touch instructions and offline references. **Settings** stores Master, Music, Sound effects and text size on the device. [C22 checks](docs/qa/C22_PRESENTATION_MATRIX.md)

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
godot --headless --path . --editor --import --quit
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

Expect `4.7.2.stable` in the version, an import and startup free of script errors, and zero failures across the 25 test scripts. The logical layout starts at 1280×720, expands for other landscape aspect ratios, and maps Android system safe bounds into the UI margins. [Test descriptions](tests/README.md)

## Android export prerequisites

- Install **Godot 4.7.2 stable** and the matching **4.7.2.stable export templates** via **Editor → Manage Export Templates**. The Android Debug preset uses the standard templates and targets ARM64.
- Install OpenJDK 17 and the Android SDK. Install SDK Command-line Tools, accept the SDK licenses, and install Platform-Tools (`adb`), Build-Tools (`apksigner`), and Android Platform 36. The verified export used Build-Tools 36.1.0. The linked export guide lists the full Godot 4.7 toolchain, including packages for custom builds. [Godot 4.7 Android export guide](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html)
- In **Editor → Editor Settings → Export → Android**, set **Java SDK Path** to the JDK root, and **Android SDK Path** to the SDK root. Configure debug signing locally if prompted. The team release identity and key custody are tracked separately.

The C22 cloud build produced a signed ARM64 debug APK. Physical installation remains pending because the workspace has no USB access to a phone. [Export and C22 phone steps](export/README.md#c22-presentation-phone-check)

## Reference documents
The GDD and 127-page tileset/UI storyboard are separate production references. They are **not automatically included** in this public repository. See `docs/reference/README.md` before uploading PDFs, especially any academic covers containing personal information or signatures.
