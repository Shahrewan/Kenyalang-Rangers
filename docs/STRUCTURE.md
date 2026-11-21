# Repository structure and placement guide

This document describes **intended locations**, not completed features. Existing files have been preserved.

| Path | Purpose |
|---|---|
| `docs/reference/` | GDD, storyboards, supporting source references (only publish redacted/approved versions) |
| `docs/canon/` | Approved gameplay rules, data contracts, decision log and art/UX specification |
| `docs/production/` | Work plan, tickets, progress tracker, source inventory and handoffs |
| `docs/qa/` | Test matrix, Android device benchmarks, QA screenshots and evidence |
| `data/rangers/`, `facilities/`, `enemies/`, `bosses/` | Data-driven gameplay registries and definitions |
| `data/stages/`, `modifiers/`, `buffs/`, `dialogue/` | Stage/wave configuration and authored content |
| `data/education/`, `garden/`, `economy/` | Educational, planting and currency/economy data |
| `scenes/` | Reusable Godot scenes divided by screen and combat domain |
| `scripts/autoload/` | Shared singleton scripts registered in Godot |
| `scripts/battle/`, `data/`, `game_modes/`, `ui/`, `persistence/` | Domain logic, validation, UX and versioned saves |
| `assets/source-art/` | Editable original art files |
| `assets/imported/` | Validated game-ready parts, spritesheets and exports, **not** Godot `.godot/imported/` cache |
| `assets/backgrounds/`, `tiles/`, `ui/`, `portraits/`, `audio/` | Runtime art and sound assets |
| `assets/placeholders/` | Clearly labeled temporary media |
| `tests/` | Automated and reproducible manual test fixtures |
| `export/` | Android export configuration and instructions; not generated APK/AAB binaries |

## Compatibility and migration
- Legacy directories `assets/characters/`, `assets/tilesets/` and `resources/` remain in place until actual references and dependencies can be inspected.
- Earlier tracking JPEG files have been **left untouched**; remove or relocate only after verifying they are not referenced.
- Folder placeholders (`.gitkeep`) can be removed when real files are added.
- Keep `project.godot`, `AGENTS.md`, and the production documents at their current paths. Do not move scenes/resources once referenced by UID/path without Godot verification.
- `.godot/` is a generated cache and must remain untracked.
