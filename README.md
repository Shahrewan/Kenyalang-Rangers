# Kenyalang Rangers

Godot **4.7.2** (GDScript) game project for Android landscape, offline single-player.

## Starting points
- `project.godot`: Godot project file.
- `AGENTS.md`: development and Codex working rules.
- `README_FIRST.md`: Work/Codex onboarding and handoff pack.
- `docs/production/`: existing work plan, progress tracking, source inventory and unresolved decisions.
- [Canonical specifications](docs/canon/README.md): source-cited game rules, data contracts, art and UI spec, systems catalog and open decisions.
- `docs/reference/`: reference-file handling instructions.
- `docs/qa/`: test evidence and device validation.
- `docs/STRUCTURE.md`: folder map and placement guidelines.

**Implementation status:** directory scaffolding only. Folder existence does not imply a playable scene or game system.

## Source of truth
Implemented code in this Git repository; approved decisions and canonical game specifications govern design. Keep major feature changes on branches, review pull requests before merging into `main`, and prioritize playable C1-01 combat.

## Local setup
Clone the repo, import `project.godot` into Godot 4.7.2, and keep Godot-generated `.godot/` untracked. Run and test locally before accepting code changes. See `AGENTS.md` for the full workflow.

## Reference documents
The GDD and 127-page tileset/UI storyboard are separate production references. They are **not automatically included** in this public repository. See `docs/reference/README.md` before uploading PDFs, especially any academic covers containing personal information or signatures.
