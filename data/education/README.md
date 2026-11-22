# Player education banks

This is the runtime location for team-approved `outreach.json`, `records.json` and `references.json`. The W18 drafts and their review validator are under `docs/production/w18/`. The Android preset includes runtime JSON from this directory.

- Use the W18 layout with schema version 1, the matching `kind` and `editorial_status` set to `approved` after recording the team decision for that revision. The reference register can supply approved facts independently of the quizzes. All question and fact source IDs must resolve in the approved register.
- Keep IDs stable across revisions for the same question, fact and chapter. Increment the relevant bank's `content_revision` when changing prompts, question order, or answer order. Outreach adopts it at the next eligible refresh. Records offers an explicit replacement if a saved attempt belongs to an earlier revision.
- Outreach uses the grade-by-room payout table in the Headquarters catalog. Set Records `final_first_correct_funds` and each chapter's `final_perfect_chapter_funds` to the reviewed whole-Funds amounts.

The current player build displays the approval state. Test fixtures under `tests/fixtures/` exercise both modes independently of content review. [W18 handoff](../../docs/production/W18_EDUCATION_BANKS.md) · [Approval record](../../docs/canon/DECISION_LOG.md#open-decisions)
