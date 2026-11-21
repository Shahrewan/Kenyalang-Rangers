# Decisions to lock before implementation or before their relevant milestone

These are **gaps/provisional figures identified in the supplied documents**, not new established game canon. Fill answers in `docs/canon/DECISION_LOG.md` and reference them in Work/Codex prompts.

| ID | Question | Priority | Suggested handling (not a canonical answer) |
|---|---|---|---|
| D-001 | How can C1-01 use a Logistics Post before the Mechanical room is constructed and before its Facility loadout capacity exists? | **Blocking for vertical slice** | Document a specific starter allowance independent of HQ Mechanical slots, or a deliberate starter-rule exception; preserve optional Posts in ordinary stages. |
| D-002 | What exactly happens when the Logistics Post is omitted from a loadout and no starting Tokens exist? | Blocking for non-tutorial modes | Define how to prevent impossible setups / validate loadouts / provide other legal token sources. |
| D-003 | Are the `tile_atlas_spec.svg`, `tile_piece_catalog.json`, `tile_grammar.svg`, `tile_layouts.json`, 116 SVG frames, PNGs, illustration layers, offline viewer and `PROJECT_MEMORY.md` recoverable? | Blocking for art production | Search the original art workspace first. PDFs are references; do not invent or extract fake editable layers. |
| D-004 | Where are the actual full Chapter 2 dialogue files, 20 Outreach scenarios, and roughly 40 Records questions? | Blocking for full content | Obtain or author separately and review conservation facts before final integration. |
| D-005 | What is the final maximum held Funds wallet? GDD proposes 9,999,999 and says the numeric cap is pending agreement. | Before economy lock | Keep numeric value as a named constant while prototype-testing, finalize before release. Overflow must be permanently discarded with visible warning. |
| D-006 | What are per-stage first-clear rewards, perfect bonuses, replay rewards, exact escape penalties, spawn group compositions and stage balance? | Before full Campaign authoring | Use clearly labeled provisional test fixtures, then lock in resource data after balance playtests. |
| D-007 | What exact stats scale from Levels 1–100 for every deployable? | Before progression implementation | Specify interpolation curves and rounding; preserve fixed skills/geometry, fixed build times and exact 1M cumulative purchase total. |
| D-008 | What are all ability constants not fully quantified in the GDD (durations, radii, cooldowns, status priority, stacking, bespoke Facility build times)? | Before full tactical roster | Create per-ability contracts and write edge-case tests for overlapping modifiers. |
| D-009 | What are the final Ranger/Facility loadout slot budgets for each phase and which unlocks are allowed before their rooms are built? | Before mission planning | Use GDD HR/Mechanical room tables; separately resolve starter/tutorial exceptions. |
| D-010 | How is 60% / 100% Restoration calculated, and how does a planted mature tree occupy/release a plot? | Before Garden | Specify deterministic progress and persistence semantics; no wilting/death. |
| D-011 | Which effects are considered eligible/ineligible on a chosen Rainforest Chaos route? | Before Chaos | Explicit capability flags; prevent score for irrelevant debuffs. |
| D-012 | What are art deliverable dimensions, body-part pivot coordinates, rig orientation variants, per-character palette and exporter tools? | Before mass sprite production | Validate one battle-size Ranger in Godot first and then standardize. |
| D-013 | What exact Godot 4 stable release and export template build, Android test devices, minimum FPS scenario and UI scale settings are pinned? | Before Codex implementation | Test a small Godot app on an actual Android phone early. |
| D-014 | Who approves narrated conservation information and licensing/attribution of audio, background art and sprites? | Before public distribution | Establish source ledger with published fact URLs, original/third-party art provenance and permissions. |
| D-015 | What is the final Android package name, signing and release channel? | Before shipping | Define package ID and secure signing/key custody; do not place signing credentials in Git. |

## Source fidelity notes
- GDD pp. 33 and storyboard p. 10 call many balance values provisional; do not treat them as measured.
- Storyboard p. 2 explicitly supersedes the older 18-FPS animation idea with a ~60 FPS sampling target. This remains a performance target, not a phone benchmark.
- GDD p. 19 says 11 HQ rooms, of which Control, HR and Finance initially exist free at Lv.1.
- GDD pp. 24–25 fix the score structure and the 1000/2000/3000 threshold behavior.
- GDD p. 30 says character art is skeletal cutout style, but no actual production-ready sliced artwork was included.
