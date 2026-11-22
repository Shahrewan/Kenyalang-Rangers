# W18 · Education banks for review

**Draft revision 1 · 22 November 2026.** The W18 exit check covers attributed questions, valid answer keys and nest privacy. C19 requires the team's approval of the bank it imports. [D-004, D-014 and D-016](../canon/DECISION_LOG.md#open-decisions)

| Deliverable | Contents |
|---|---|
| [Outreach bank](w18/outreach.json) | 20 fictional Sarawak outreach situations. Each has four independently graded responses and four Manager justifications. Six required topics have three situations each, plus two on trail access. |
| [Records bank](w18/records.json) | 40 factual questions, with ten in each of four chapters. Every question has four choices, one keyed answer, a short explanation and source IDs. The topics and ten-question split are proposed. |
| [Reference register](w18/references.json) | 32 checked publication links with locators, 20 short facts and five candidate Garden fact links. The W13 tree-cavity fact keeps `fact.hornbill_tree_cavity` and its published wording. |
| Schemas and validation | [Outreach schema](w18/schemas/outreach.schema.json), [Records schema](w18/schemas/records.schema.json), [reference schema](w18/schemas/references.schema.json) and [local validation](w18/validate.py). |

## Source recovery and open approvals

| Status | Finding | Basis |
|---|---|---|
| **FIXED** | Each Outreach batch contains up to five distinct questions from the 20-question rotation. Four shuffled choices use Best, Acceptable, Poor or Harmful. Records uses a 15-second timer and four chapters gated at Lv.2–5. | GDD pp. 25–27 §§ M.8–M.9. Storyboard pp. 77–84 S41/S42/P02/P2A–P2D/P05, pp. 85–88 S43–S46 and p. 102 S60. [Rulebook](../canon/GAME_RULES.md#outreach-records-and-habitat-restoration) |
| **PROVISIONAL** | W18 supplies original, source-checked review candidates. The GDD p. 26 Outreach table remains the C15 prototype payout configuration. The Records budget model uses about 40 × 30,000 Funds for first correct answers and 350,000 Funds across four perfect bonuses, about 1.55M in total. | GDD p. 26 § M.8, pp. 26–27 § M.9 and p. 33 § T.4. [Data contracts](../canon/DATA_CONTRACTS.md#pr-outreach) |
| **MISSING** | The final team Outreach and Records sources were missing from the supplied references, repository and available project-file search. The team review, final Records count and split, final Outreach rates and exact Records award amounts are `TBD`. | GDD pp. 25–27 §§ M.8–M.9 and p. 33 § T.3. Storyboard p. 10 Handover. [Source inventory](SOURCE_INVENTORY.md#w18-education-source-review--22-november-2026) |

The team brief *M.9 Habitat Restoration (Garden).docx* was located. Its pp. 1–3 identify the four native tree types, 18/36/48/72-hour game durations and a hornbill guide. Its early plot scale, six stages, watering schedule, permanent stat buffs and repeat nest-box ideas predate the approved design. Use the current four species and three visible stages from GDD p. 27 § M.10 and the midpoint and fourth-distinct-species nest-box event from D-010. Garden fact mappings are candidates for the guide and later Records browsing. The game durations describe the simulation. [D-010](../canon/DECISION_LOG.md#approved-decisions) · [Storyboard pp. 89–93 S47–S51](../canon/ART_AND_UI_SPEC.md#storyboard-frame-index)

## Chapter bindings

| Stable chapter ID | Records room | Draft topic | Perfect-chapter enhancement |
|---|---:|---|---|
| `records_chapter.scout_sniper` | Lv.2 | Hornbill observations | Scout Sniper · Steady Aim and Focus enhancements |
| `records_chapter.patrolman` | Lv.3 | Forests and waterways | Patrolman · Reinforced Patrol |
| `records_chapter.combat_medic` | Lv.4 | Safe field observations | Combat Medic · Emergency Treatment |
| `records_chapter.woods_tracker` | Lv.5 | Native trees and restoration | Woods Tracker · improved HP and reduced redeployment cooldown |

Strike Team is excluded from Records enhancements. Each Records question and each perfect chapter track their own one-time settlement. Replay retains full eligibility for a new perfect chapter attempt, including questions that previously paid their first-correct award. Wrong or timed-out responses earn no question Funds and show the explanation. Facts are freely readable and have no timer or recurring Funds. [GDD pp. 19, 26–27 §§ M.1, M.9 and p. 30 § R](../canon/DATA_CONTRACTS.md#records-encyclopaedia) · [Storyboard pp. 85–88 S43–S46, p. 102 S60 and pp. 106–108 V04–V06](../canon/ART_AND_UI_SPEC.md#storyboard-frame-index)

## Source, privacy and rights review

- Each question points to a specific section of one or more sources. Forest Department Sarawak and IUCN Hornbill Specialist Group support the species questions. The district-scale landscape questions use protected-area and biodiversity publications. Guide facts describe ecology, including the limited role of a nest box. The cue for a Garden visitor comes from the game rules. [Reference register](w18/references.json) · [W13 fact](w13/campaign.json)
- Published player copy uses regional or habitat-level context. The team review should check prompts, all choices and explanations, captions, images and metadata for exact nest locations or clues that allow a visitor to find one. Wildlife reports in the fictional scenarios go privately to authorised staff. [Cornell Lab sharing guidance](https://support.ebird.org/en/support/solutions/articles/48000803210-sensitive-species-in-ebird) · [Sarawak Forestry Corporation enforcement FAQ](https://sarawakforestry.com/layout2/wp-content/uploads/2020/05/FAQs-Wildlife-Enforcement-1.pdf)
- The bank copy paraphrases the factual sources. Publication links are held for verification and credits. Source text, images, tables and illustrations require a separate reuse check if incorporated in a release. The donor and community prompts apply general transparency and consultation guidance. [Fundraising Regulator practice guide](https://www.fundraisingregulator.org.uk/about-fundraising/resources/documenting-your-fundraising-decisions) · [Convention on Biological Diversity ecosystem approach](https://www.cbd.int/recommendation/sbstta/default.shtml?id=7027)
- Under D-014 the mode content reviewer checks facts, grading and local wording. The project owner approves the specific bank revision for distribution. Reviewer names and approval date are `TBD`. [Source and provenance index](SOURCE_INVENTORY.md#w18-education-source-review--22-november-2026) · [Asset provenance policy](../canon/ART_ASSET_MANIFEST.md#production-handoff)

## Validation and C19 handoff

Run `python3 docs/production/w18/validate.py` with Python 3 and `jsonschema` 4.x. It passed all three Draft 2020-12 schemas, 60 unique prompts, 240 choice IDs, four chapter bindings, 20 fact IDs, 32 referenced sources and 480 Outreach choice permutations. The numeric coordinate scan passed. The wording review also covered indirect location clues and the safety of responses, including distractors. Godot 4.7.2 editor import, headless startup and 1,592 existing checks across 20 runners passed on C17. Device reading and touch checks belong to the C19 screens.

| C19 area | Acceptance check |
|---|---|
| Outreach rotation and save | Evaluate the 20-hour boundary from the last refresh and confirm one active batch with up to five distinct questions. A forward jump can open at most one new batch. A backward jump keeps the existing batch. Relaunch mid-batch and compare the shuffled choices, saved question and selection, grade and actual settlement. Supply C15's integer choice permutation from the bank's authored choice array and resolve the grade from the selected choice. Version any change to authored choice order before using it with saved permutations. [GDD pp. 25–26 § M.8 and p. 29 §§ O.3–4](../canon/DATA_CONTRACTS.md#pr-outreach) · [D-016](../canon/DECISION_LOG.md#approved-decisions) |
| Outreach Funds and participation | Submit each grade through the C15 wallet. A Harmful response with insufficient Funds settles the actual deduction and completes the response. Only Best or Acceptable counts toward the five-response prerequisite for Outreach Lv.5. The room price also applies. Verify overflow discard under the 9,999,999 Funds prototype cap and check the fifth success gate. [GDD pp. 20–21 §§ M.1, M.3, pp. 25–26 § M.8 and p. 29 § O.4](../canon/DATA_CONTRACTS.md#economy-and-progression) · [D-005 and D-016](../canon/DECISION_LOG.md#approved-decisions) |
| Records quiz and replay | Confirm gates at Lv.2–5, a pause-correct 15-second timer, timeout feedback and one payout per first correct answer. Save and relaunch mid-question and after settlement. After a perfect attempt, check the corresponding enhancement and the one-time chapter claim. Payout amounts stay configurable and final amounts are `TBD`. [GDD pp. 26–27 § M.9 and p. 29 § O.3](../canon/DATA_CONTRACTS.md#records-encyclopaedia) |
| Android landscape | With the approved data in S41/S42 and S44/S45, verify the longest prompts, four touch targets and feedback fit with increased text size. Test a Records timeout and reopen a partially answered Outreach batch offline. Store enough local source credit to describe each fact offline. [Storyboard pp. 77–78, 86–87 and 102 S41/S42/S44/S45/S60](../canon/ART_AND_UI_SPEC.md#storyboard-frame-index) · [GDD p. 30 § R](../canon/GAME_RULES.md) |
