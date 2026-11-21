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

**Implementation status:** **Open sample battle** runs the C03 deployment preview on T01. Drag a card onto a highlighted tile. Drop on the left or right half of the anchor to set melee facing. Tap Patrolman to activate its test skill. Tap Scout Sniper, select a covered tile, and use **Confirm skill**. Hold a Ranger for 350 ms to reveal **Retreat**. Its card shows the remaining combat-time redeploy cooldown. The preview has a separate 60-Token test budget. The campaign logistics economy and autonomous attacks are later milestones.

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
```

Expect `4.7.2.stable` in the version, no script errors during import or startup, and zero failures in all three test scripts. The logical layout starts at 1280×720, expands for other landscape aspect ratios, and maps Android system safe bounds into UI margins. The two screens use Godot controls and labeled drawn tiles.

## Android export prerequisites

- Install **Godot 4.7.2 stable** and the matching **4.7.2.stable export templates** via **Editor → Manage Export Templates**. The Android Debug preset uses the standard templates and targets ARM64.
- Install OpenJDK 17 and the Android SDK. Install SDK Command-line Tools, accept the SDK licenses, and install Platform-Tools (`adb`), Build-Tools (`apksigner`), and Android Platform 36. The verified export used Build-Tools 36.1.0. The linked export guide lists the full Godot 4.7 toolchain, including packages for custom builds. [Godot 4.7 Android export guide](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html)
- In **Editor → Editor Settings → Export → Android**, set **Java SDK Path** to the JDK root, and **Android SDK Path** to the SDK root. Configure debug signing locally if prompted. The team release identity and key custody are tracked separately.

Follow the [first APK export and physical-phone checklist](export/README.md). The C01 cloud build produced and verified a signed ARM64 debug APK. Physical installation remains pending because the workspace has no USB device access for a phone.

## Reference documents
The GDD and 127-page tileset/UI storyboard are separate production references. They are **not automatically included** in this public repository. See `docs/reference/README.md` before uploading PDFs, especially any academic covers containing personal information or signatures.
