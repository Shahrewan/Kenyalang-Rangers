# Work ↔ Codex reusable handoff

## Practical shared-context setup

**Preferred on Windows desktop:** Open the same local Git/Godot project folder in Work (when local file access is enabled, grant permission) and in Codex. Maintain the canonical design notes, art manifests and change requests as repository Markdown/JSON. Git is for history and recovery; a private GitHub remote is optional but recommended for remote/cloud collaboration.

**Web Work + Codex Cloud:** Put canonical production files in a private GitHub repository or make a deliberate choice to keep the existing public repository. The GitHub connector was confirmed connected on 20 November 2026, and `Shahrewan/Kenyalang-Rangers` was discovered with only `README.md`. Configure Codex Cloud against that repo for coding changes. GitHub integration supports relevant read/write operations when permissioned; Work may have different tools depending on the active experience. Preserve approvals, avoid claiming cloud-based direct editing is automatically available, and only perform repository changes when authorized.

Work and Codex have different conversation histories. Do not assume copying a chat link means Codex can read the entire Work discussion. They can share *project files* and repository state, not automatically transfer every hidden decision or past thought.

## Every Work-to-Codex handoff should have these fields

```markdown
# Handoff: <TASK-ID> — <feature>
Date:
Base Git commit/branch:
GDD references (pages/sections):
Storyboard references (pages/screen IDs):
Design decisions approved:
Deliverables and acceptance tests:
Assets available (exact repo paths):
Assets missing/placeholders required:
Data contract changes:
Files expected to change:
Files/behavior to leave untouched:
QA scenarios (including pause, save/load, invalid input):
Unresolved questions / blocking decisions:
Owner and next review point:
```

## Universal Work prompt: turn a specification into an implementation ticket

> Using `docs/canon/GAME_RULES.md`, the GDD, the UI storyboard and the current repository state, write a single bounded implementation handoff for [FEATURE]. Specify scope, inputs/outputs, resources, screens, state transitions, edge cases, art availability, dependencies, measurable acceptance tests and source page references. Identify gaps without inventing answers. Save the handoff in `docs/production/tickets/`. Do not modify application code.

## Universal Codex prompt: implement one approved ticket

> Read `AGENTS.md`, `docs/canon/GAME_RULES.md`, and `docs/production/tickets/[TICKET].md`. Inspect the existing Godot project and implement only the ticket's scope. Do not rewrite unrelated systems or guess missing canonical content. Add automated or deterministic tests where possible, run the Godot editor/headless smoke check, give a phone test script if appropriate, update the progress/handoff log, and report actual tests, touched paths and remaining issues. Leave the game launchable.

## Universal Work review prompt: cross-check what Codex built

> Compare the changed code, screenshots, test evidence and built behavior for [TICKET] against `SimSimi.pdf` [pages] and UI storyboard [pages/screen IDs]. Distinguish confirmed compliance, missing behavior, provisional placeholder content, accessibility problems, and contradictions. Create prioritized follow-up tickets. Do not report a visual mockup as a working feature; do not change code unless explicitly requested.

## Safe change order

1. Work writes or updates a ticket and any asset/JSON specifications.
2. A human approves unresolved rule choices.
3. Codex implements in a feature branch and runs tests.
4. The human launches the scene, checks Android where relevant and reviews changes.
5. Codex fixes defects; merge only after green exit checks.
6. Work audits the merged milestone against the GDD and creates the next ticket.

Avoid simultaneous Work and Codex edits on the same `.tscn`, `.tres`, atlas, or large spec file. Prefer small commits and stable scene/resource IDs to avoid Godot merge conflicts.
