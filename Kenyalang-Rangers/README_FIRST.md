# Kenyalang Rangers — Work ↔ Codex development pack

Prepared from the two PDFs provided on 20 November 2026:

1. `SimSimi.pdf` — 39 pages; GDD v1.0 on pages 1–33, gameplay mini-storyboard on 34–39.
2. `Kenyalang_Rangers_Tileset_UI_Storyboard.pdf` — 127 pages; visual specification, six map templates, tile inventory, 116 storyboard screens/states.

## Important: do not confuse PDF mockups with finished game assets
The received ZIP contains **only the PDFs**. The visual storyboard mentions editable SVG frames, PNG exports, JSON tile maps, ten illustration layers, an offline viewer and a `PROJECT_MEMORY.md`, but none of those were inside this ZIP. Recover the originals from the earlier project files if available; otherwise recreate production assets using the PDFs as references. Do not claim to have imported these unprovided files.

The full Chapter 2 script, the 20-item Outreach question bank and the approximately 40-question Records bank are also referred to as separate assets in the GDD but are not present in the received ZIP.

## What you get

- `KENYALANG_RANGERS_MASTER_WORK_PLAN.md`: full copy/paste prompt library (W00, W00b, C01–C24, W19b, repeatable review/debug prompts), acceptance gates, recommended handoffs and AI model choices.
- `AGENTS.md`: repository instructions for Codex to preserve the canon and test each change.
- `DECISIONS_TO_LOCK.md`: concrete unresolved rules/asset gaps needing owner decisions.
- `SOURCE_INVENTORY.md`: what was actually in the PDFs versus referenced but unsupplied native sources.
- `WORK_CODEX_HANDOFF.md`: how to use one repository as shared context and implementation-ticket template.
- `PROGRESS_TRACKER.md`: milestone checklist.

## Start here

1. You already have a GitHub repository: `Shahrewan/Kenyalang-Rangers` (checked 20 November 2026; currently public and with only `README.md`). Consider making it private if you do not want pre-release assets exposed. Create an empty **Godot 4 GDScript** project on your computer and connect this repo as its Git remote.
2. Copy `AGENTS.md` into the repository root. Copy the other Markdown files into `docs/production/`.
3. Put the two original PDFs in `docs/reference/` **locally** (or another stable location) and record their exact paths in `docs/production/SOURCE_INVENTORY.md`. PDFs are large; consider Git LFS or keeping them out of Git and using approved cloud/project attachments. For GitHub/cloud Codex, canonical text specs in Git are easier to access than a local-only PDF.
4. Start a ChatGPT **Work** task with **Prompt W00** in `KENYALANG_RANGERS_MASTER_WORK_PLAN.md`. Have it produce `docs/canon/*`, a rules/decision register, and a repository-facing implementation brief. Treat it as a plan, not an implemented game.
5. Resolve the blocking entries in `DECISIONS_TO_LOCK.md` (particularly starter Logistics Post access).
6. Switch to **Codex**, open the **same local repository** or a connected GitHub repo, and run **Prompt C01**. Demand an editor-launch smoke test before adding gameplay systems.
7. Continue through the prompts in order. Gate every milestone with a working Godot project and tests, and regularly install builds on Android.

## Recommended cadence

- **Work:** GDD reconciliation, game content, asset specifications, multi-page UI reviews, conservation-fact research, test/acceptance planning.
- **Codex:** Godot scenes, GDScript, resource definitions, imports, animation rigs, UI implementation, automated tests, debugging, Android builds.
- **Work again:** When a design or art decision needs to change, or after a milestone for independent comparison against the original PDFs.
- **Codex again:** When a written, approved design change is ready to implement.

Keep `docs/canon/GAME_RULES.md` authoritative and `docs/production/PROGRESS_TRACKER.md` updated. Avoid asking an agent to build the complete game in one prompt.

## Quick success definition

The first significant milestone is **a working, installable Android version of C1-01** with a first-free Logistics Post, valid drag placement, one enemy route, waves, basic Rangers, Integrity, victory/defeat, and save integrity. Do not generate 116 UI screens or 25 complete deployable rigs before this works.

## Linked GitHub status as reviewed

Existing repository: https://github.com/Shahrewan/Kenyalang-Rangers — `main`, public, contents `README.md` only. No GitHub files were edited as part of preparing this planning pack.

## Helpful official references

- Work and Codex: https://help.openai.com/en/articles/20001275-chatgpt-work-and-codex
- GitHub in ChatGPT: https://help.openai.com/en/articles/11145903-connecting-github-to-chatgpt
- Codex `AGENTS.md` and phased workflow: https://developers.openai.com/cookbook/examples/codex/iterating-development-workflows-with-codex
- Godot cutout animation: https://docs.godotengine.org/en/stable/tutorials/animation/cutout_animation.html
- Godot Android export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
