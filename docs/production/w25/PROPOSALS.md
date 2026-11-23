# W25 · Campaign proposals awaiting approval

These options are for review against the [preserved rules and current evidence](../W25_CAMPAIGN_COMPLETION.md). A recommended option is a proposal. Enter an explicit owner decision before applying any data change. Keep the stage structure and existing IDs as acceptance constraints.

## Fund the first ordinary opening

**Existing rule.** D-009 keeps the 20,000 Funds Mechanical build and slot requirement. D-001 scopes the Starter Post to C1-01. GDD pp. 18–22 §§ M.1, M.3–4 gives the starting and progression context. C14 verified the ordinary Post after 5,000 active seconds of Finance at the starting 10,000 Funds.

| Option | Effect and tradeoff |
|---|---|
| **Recommended proposal.** Trial a 10,000 Funds C1-01 first-clear award. | Reaches 20,000 on a clean normal clear before optional spending, even with a combat escape and no perfect award. Retains Finance for recovery after spending. The number follows the current shortfall and needs approval as part of the Campaign budget. |
| Keep the Finance-funded route and test its intended wait with players. | Preserves the current progression delay. With the pending first-clear payout and no spending, the initial gap takes about 83 minutes 20 seconds of active Lv.1 Finance. A smaller approved first-clear award could reduce the wait. |

Record the accepted wait, first-clear amount, after-clear wallet and legal 2×1 Post drop. Preserve the separate C05 amounts of 100/50 in the fixture. [C14 opening evidence](../../qa/C14_CAMPAIGN_MATRIX.md#playtest-status) · [C23 findings](../../qa/C23_SYSTEM_AUDIT.md#balance-findings-for-owner-review)

## Approve the Funds schedule and existing-save treatment

**Existing rule.** First clear, first perfect, successful replay and first C2-10 completion use the current [settlement predicates](../../../scripts/persistence/campaign_progress.gd). A first perfect can accompany the first clear or pay alongside replay on a later clear. Defeat and abandon pay zero. D-005 fixes discard and scopes 9,999,999 to the prototype. D-018 commits awards, progress and grants together. GDD p. 21 § M.3 gives a scenario of 7.42M from Campaign clears with some perfection, alongside 0.55M combined Finance and replay. It leaves a per-mission split open.

**Recommended proposal.** Approve one table of 46 integer amounts. Start with reachable first-clear gates, then allocate first-perfect bonuses, replay and the C2-10 completion award. State the assumed perfect and replay counts, payout source, spending schedule and time budget when comparing to 7.42M and 0.55M. Keep the current prototype cap during the content test. Compare early spending and delayed claims in the C23 model before choosing the shipping cap. Values outside the C1-01 experiment remain `TBD`.

| Gate | Required spend under the example route | Cumulative new Funds needed above the 10,000 start |
|---|---|---:|
| C1-02 | Mechanical Lv.1 at 20,000 | 10,000 |
| C1-04 | Mechanical Lv.1 plus Control Lv.2 at 20,000 | 30,000 |
| C2-01 | Prior purchases plus Control Lv.3 at 80,000 | 110,000 |
| C2-05 | Prior purchases plus Control Lv.4 at 300,000 | 410,000 |
| C2-09 | Prior purchases plus Control Lv.5 at 900,000 | 1,310,000 |

The table assumes ordinary Post openings, no other spending, no overflow and no mandatory perfects. First-clear credits and a stated Finance schedule may both count. Other approved sources or spending change the real receipts. Re-run the installed-content scenario with an explicit W18 bank assumption and record stage reachability independently of the total. [GDD pp. 18–22 §§ M.1, M.3–4](../../canon/SYSTEMS_INDEX.md#headquarters-rooms) · [C23 scenario](../../qa/C23_SYSTEM_AUDIT.md#sixty-day-balance)

| Existing-save option | Effect and tradeoff |
|---|---|
| **Recommended proposal.** Keep recorded first-clear/perfect flags and saved ownership. | Data-only cutover. A replay can earn an approved replay value and a first perfect if its flag is still unset. Existing first-clear and completed finale flags remain consumed, even if they originally settled at zero. An earlier C1-01 clear can still use Finance toward Mechanical. |
| Approve a separate one-time adjustment for named legacy flags. | Gives selected RC1 profiles new value. Requires an explicit backfill eligibility and amount policy, an idempotent ledger, cap and failure/recovery tests, and separate implementation approval. The v2 flags record accomplishment and contain no original payout history per award. |

## Lock dialogue and newcomer teaching

**Existing rule.** GDD pp. 6–7 §§ F.1–4 and D-004 keep the supportive Leader, capable Manager, cinematic messenger, chapter tone and source-based C2 story. Draft lines and trigger timing await review. Stable IDs are in the [mission checklist](MISSION_APPROVAL_CHECKLIST.md). C22 provides silhouettes and captions while D-014 tracks art and credit clearance.

| Option | Effect and tradeoff |
|---|---|
| **Recommended proposal.** Review each W13 sequence in place and keep its existing trigger and identity where the reviewed beat fits. | Gives the writer a short diff against the seven-page C2 source while preserving tested pause and save paths. Correct the five pending field-kit promises to describe earned recruitment or future field readiness. Use C1-03's actual first-play hold and redeploy teaching and an eligible replay for active-skill practice. Verify the named fact and attribution before final epilogue copy. |
| Restore individual team-authored lines with approved edits and recheck the cue. | Keeps more of the writer's voice when wording fits the branch and phone text layout. Lines that imply unsupported grants or outcomes need an approved replacement. A trigger change needs its own Continue/Skip and once-per-attempt test. |

The first-play C1-03 check uses the current pre-clear roster. Guard Veteran is obtained after clear. Scout and Medic active skills currently depend on Records, whose approved runtime data remains pending. A data-only copy pass can make skill advice conditional on readiness. Later live field kits can restore approved availability wording after their own tests. The epilogue's `fact.hornbill_tree_cavity` retains the existing stable ID. [W13 narrative provenance](../W13_CAMPAIGN_CONTENT.md#chapter-2-source-and-adaptation) · [W18 references](../w18/references.json)

## Tune queues and timing by mission pair

**Existing rule.** GDD p. 8 § G.1 and pp. 21–22 § M.4 specify sequential spawns, breathing room and published first-pass totals. D-006 approved the narrow C1-01 fixture. C14 checks the current order and effective cadence. Candidate stage and shared combat values are listed in the [approval plan](../W25_CAMPAIGN_COMPLETION.md#exact-trial-numbers-to-approve-or-replace).

| Option | Effect and tradeoff |
|---|---|
| **Recommended proposal.** Human-play the loaded W13 queues as the control, then adjust one failing group's order, gate or delay at a time within the existing totals. | Makes the causal change measurable and retains the tested separation between base waves and boss support. Record failed opening, first danger cue, clearance time and operation result before changing a second variable. |
| Tune a shared enemy or Facility value when several missions demonstrate the same issue. | Keeps a common base definition across Story and Chaos. Compare both consumers and rerun modifiers, roster and payout regressions. Stage-specific openings and D14 Heat still need mission evidence. |

For each mission, record the selected pre-clear IDs and levels, effective buffs/debuffs, Control and wallet, order of drops, first counter pressure, Integrity/escapes and clear time. On the two-entry Mulu stages record which approach caused the loss. On C2-07/08 record Heat resets and whether an ordinary opening could complete a Beacon build in time. The proposal accepts the first-pass counts as scope boundaries while retaining the first-wave and inter-wave timing decisions for owner approval.

## Decide Firebreak permanence before the canyon sign-off

**Existing rule.** D-009 approves temporary C2-07 supply before the first Heat wave with normal price and placement. C2-08 has no mission supply. GDD p. 22 § M.4 specifies the provision and leaves permanent recruitment open.

| Option | Effect and tradeoff |
|---|---|
| **Recommended proposal.** Keep mission-only ownership if a tested pre-clear roster can fairly clear C2-08. | Preserves current saves and C2-07's teaching. C2-08 must show a viable route even if the player has no Beacon or B02. If that fails consistently, compare queue/Heat tuning and the permanent option before locking the stage. |
| Grant `facility.firebreak_beacon` on C2-07 clear as a separate permanent award. | Gives a reliable later counter at the normal slot, cost and build rules. Changes the C2-08 and Chaos baseline. The existing grant loop can award the new ID on a successful C2-07 replay to returning saves. Verify the UI offers only the intended copy during C2-07, the one-time ownership receipt and prior-profile behavior. |

Approve the choice, copy and tested loadout together. Keep a distinct decision for the 100 capacity, 10 Integrity reset and effective D14/slowdown numbers. The active C2-07 supply defaults and pending ownership are recorded in [C14](../../qa/C14_CAMPAIGN_MATRIX.md#sequence-and-outcomes) and [C23](../../qa/C23_SYSTEM_AUDIT.md#balance-findings-for-owner-review).

## Decide Foreman escape and confirm the two other boss settlements

**Existing rule.** GDD p. 13 § H.3 calls for Diversion Captain capture and a catastrophic Poacher Leader escape. It specifies Foreman Heat and temporary HP and leaves that boss's escape consequence open. C14 tests both capture escape and the Foreman ordinary escape branch.

| Foreman option | Effect and tradeoff |
|---|---|
| **Recommended proposal.** Keep the 50-Integrity ordinary deduction if the stage remains fair in play. | Matches RC1 and keeps both trial branches reachable. Stopping the boss uses `victory`. An escape leaving positive Integrity uses `victory_foreman_escaped`, can advance to Sepilok-Kabili and earns the applicable clear or replay award without a perfect bonus. The penalty bringing Integrity to zero yields defeat. Review 50 separately from whether the escape is fatal. |
| Use a C2-08-specific fatal escape override. | Makes stopping the Foreman mandatory before the region changes. Requires approved fatal-specific defeat text and a C2-08-only binding. Skip promoting the freed-tunnel victory variant in this branch. Retest Story and Chaos consumption of the Foreman resource. |

**Recommended proposal.** Confirm Captain capture and early withdrawal of support, Captain escape failure in this capture operation, Leader and E15 fatal escape, and Leader support resolution before victory. Sign off the exact phase numbers only after real play. Keep the custody line as a narrative framing of the settled finale if the author approves it. [Stage and phase evidence](../W25_CAMPAIGN_COMPLETION.md#exact-trial-numbers-to-approve-or-replace) · [C14 outcome tests](../../qa/C14_CAMPAIGN_MATRIX.md#sequence-and-outcomes)

## Approval record

For a decision, record the mission ID or shared decision, exact field path or dialogue ID, approved value or reviewed copy hash, approver, date, rationale and evidence. Retain an open field as `TBD` until the corresponding approval is recorded. Use [the decision log](../../canon/DECISION_LOG.md#open-decisions) to connect the signed choice to the [affected Codex ticket](CODEX_TICKETS.md).
