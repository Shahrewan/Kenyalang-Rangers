# Source inventory — checked 20 November 2026

## Files physically present in the received ZIP

| Filename | Pages | What it contains |
|---|---:|---|
| SimSimi.pdf | 39 | Task 1 GDD v1.0 (pp. 1–33), Task 2 gameplay mini-storyboard (pp. 34–39). |
| Kenyalang_Rangers_Tileset_UI_Storyboard.pdf | 127 | Source review, visual language, six original tile templates, 56-tile geometry diagram, narrative order, 116 pictured UI states, storyboard navigation. |

## Mentioned by the PDFs but **not supplied** in this ZIP

- 116 editable SVG frames, matching PNG exports and offline storyboard viewer.
- `tile_atlas_spec.svg`, `tile_piece_catalog.json`, `tile_grammar.svg`, `tile_layouts.json`.
- Ten illustrated image layers, including regional backdrops and separate dialogue portraits.
- `PROJECT_MEMORY.md`.
- Six earlier visual reference PNGs.
- Full Chapter 2 dialogue source (`dialog&story(test).docx`), referenced by GDD p. 33.
- Restoration team original (`M.9 Habitat Restoration (Garden).docx`), referenced by GDD p. 33.
- Finished 20-question Outreach and ~40-item Records quiz content banks.

These absent items are not necessarily lost; they may exist elsewhere. Ask the project's owners to supply them, or recreate them with an explicit production step. Do not treat illustrations in a flattened PDF as layered animation assets.

## Key source page map

- GDD p. 4–5: genre, platforms, modes, feature scope.
- GDD p. 6–7 and UI storyboard p. 8: mission narrative and order.
- GDD p. 8–9: battle, Tokens, damage, attacks, Heat.
- GDD p. 9–13: full Ranger, enemy, boss registries.
- GDD p. 14–15: UI, battle HUD, Chaos configuration.
- GDD p. 15–17: 13 Facility types and placement rules.
- GDD p. 18–20: HQ rooms, costs, progression and R&D unlocks.
- GDD p. 21–22: Funds pacing, 15-wave mission configuration.
- GDD p. 23–25: 15 R&D buffs, 15 debuffs, Chaos score/payout formula.
- GDD p. 25–28: Outreach, Records, Garden, monetization scope.
- GDD p. 28–31: technical architecture, animation, accessibility, acceptance tests.
- UI storyboard p. 2–11: source reconciliation, palette, maps, tile inventory, navigation and source gaps.
- UI storyboard p. 12–127: 116 UI screens, variants, Mountain stage walkthrough.

## Supplemental archive check — 21 November 2026

The two-PDF handoff and GitHub main do not include the source bundle identified by UI storyboard pp. 6 and 10. The separate working archive `Kenyalang_Rangers_Design_Pack_v2.zip` contains a byte-identical storyboard PDF. Its 116 `screens/` SVG IDs and matching `renders/` PNG IDs agree with PDF pp. 12–127. It also contains the offline viewer, all four named tile sources, ten illustration PNGs and `PROJECT_MEMORY.md`. All 116 SVGs parse with text and vector shapes and all 483 relative asset references resolve inside the archive. These are recovery candidates pending editor, viewer, provenance and production-export verification. The external final story and quiz banks remain open. See [D-003 and D-004](../canon/DECISION_LOG.md#open-decisions).

## W08 design archive validation — 21 November 2026

Inkscape re-exported six representative frame SVGs and a temporary S10 text edit. The six map layouts and all 56 technical pieces match the archive's catalogues. The viewer's navigation and tray inputs passed simulated JavaScript checks. Live desktop viewer interaction, release permission and runtime asset exports remain open. See the [validation evidence](../canon/ART_ASSET_MANIFEST.md#source-validation).
