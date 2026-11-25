# C32 · Rewards and economy proposal

**Approved for live playtesting in C32-D.** The exact Campaign schedule and four Records bonuses below are installed. C1-01 retains its 10,000 Funds ordinary first clear. C32-E activates the Chaos safeguard and compares Outreach schedules for owner review. [Machine-readable schedule](c32/rewards_proposal.json) · [C32-D verification](../qa/C32_D_ECONOMY_REWARDS.md) · [C32-E verification](../qa/C32_E_RECURRING_ECONOMY.md)

## Campaign schedule

All figures are Funds. The one-time Story completion slot belongs to C2-10.

| Mission | First clear | First perfect | Successful replay | Story completion |
| --- | ---: | ---: | ---: | ---: |
| C1-01 | **10,000 approved** | 5,000 | 500 | — |
| C1-02 | 30,000 | 15,000 | 1,000 | — |
| C1-03 | 60,000 | 25,000 | 1,500 | — |
| C1-04 | 100,000 | 40,000 | 2,000 | — |
| C1-05 | 180,000 | 60,000 | 2,500 | — |
| C2-01 | 240,000 | 80,000 | 3,000 | — |
| C2-02 | 300,000 | 100,000 | 3,500 | — |
| C2-03 | 360,000 | 120,000 | 4,000 | — |
| C2-04 | 420,000 | 140,000 | 4,500 | — |
| C2-05 | 480,000 | 160,000 | 5,000 | — |
| C2-06 | 540,000 | 180,000 | 6,000 | — |
| C2-07 | 600,000 | 200,000 | 6,500 | — |
| C2-08 | 660,000 | 220,000 | 7,000 | — |
| C2-09 | 720,000 | 240,000 | 8,000 | — |
| C2-10 | 800,000 | 265,000 | 9,000 | 1,100,000 |
| **Total** | **5,500,000** | **1,850,000** | **64,000 for one replay of each** | **1,100,000** |

The GDD p. 21 M.3 allocation is 7.42M for 15 first clears with some perfects. A reference player earns the 5.5M first-clear sum, 1.1M finale award and 820,000 across six perfects (C1-02, C1-05, C2-02, C2-05, C2-08 and C2-10). The six slots calibrate the budget and serve as modeled outcomes. Ordinary-only completion earns 6.6M. Every perfect earns 8.45M including the finale. The 1.1M finale award funds a preferred Lv.100 track with 100,000 left toward HQ. Even the all-perfect one-time total represents only part of the 24.16M GDD spending target.

The prices put ordinary awards ahead of the first Mechanical and Control gates, with a larger margin in longer Chapter 2 operations. First-perfect awards add about one-third to one-half of the corresponding ordinary clear. Replay awards cap at 9,000 to keep successful replays supplemental. On the modeled 2× runs plus planning and dialogue, C1-01 and C2-10 replays yield about 129 and 1,219 Funds per active minute respectively. The regular score-model comparison includes Finance in the supplemental GDD category. [Ordinary-clear gate proof and timed inputs](../qa/C32_ECONOMY_AND_PROGRESSION.md)

## Records bonuses

| Records level and chapter | First-perfect bonus proposed |
| --- | ---: |
| Lv.2 · Scout Sniper | 50,000 |
| Lv.3 · Patrolman | 75,000 |
| Lv.4 · Combat Medic | 100,000 |
| Lv.5 · Woods Tracker | 125,000 |
| **Total** | **350,000** |

The ascending split follows GDD pp. 26–27 M.9, which budgets 350,000 across four chapters plus 1.2M for 40 unique first correct answers. The existing 30,000 question award and the named chapter enhancements have independent eligibility. A first perfect can pay after a previous non-perfect attempt. Further perfect replays award zero. [Settlement tests](../../tests/unit/c32_economy_test.gd)

## Owner decisions

| Decision | Recommendation | Implementation status |
| --- | --- | --- |
| Campaign and Records amounts | Use the exact schedule for live playtesting and review the mixed-income budget before release. | C32-D activates all 45 remaining Campaign values and four Records chapter bonuses. |
| Returning profiles | Keep existing first-clear, first-perfect, completion-derived eligibility and ownership records. A returning player can earn a newly eligible perfect, replay value or ordinary recurring income. | Flags and claimed Funds carry forward. Legacy compensation needs separate approval. |
| Firebreak Beacon | Recruit on a successful C2-07 clear or replay. Keep its separate Lv.1 mission supply and C2-08's local Heat tuning. | C32-D installs permanent acquisition and verifies the paid upgrade path. |
| Prototype wallet cap | Retain 9,999,999 and the existing permanent discard rule during further tuning. Re-evaluate repeated overflows after the repeatable sources are calibrated. | Current cap and settlement checks remain in force. |
| Chaos repeated payouts | Cap positive debuff credit at the greater of 200 or enemy base points. Preserve tier thresholds, slot and buff deductions, payout curve and qualification. | C32-E activates the cap for new runs. Previously earned trophies, records and Facilities carry forward. |
| Outreach repeated payouts | Evaluate 25k/60k/90k/125k/175k as an intermediate trial, alongside the original 25k/60k/75k/90k/110k proposal. | Both are comparison schedules for owner review. The installed Best values are 25k/60k/110k/180k/300k. |
| Habitat Restoration | Use measured repeat income and revisit the 5.30M budget target before adding new income. Keep participation and existing growth values for the next playtest. | The 4.71M theoretical ceiling and modeled receipts support owner review of the allocation. Any separate first-species award requires its own budget. |
| Rangers and Facilities | Review the new trial growth and affordability during live play. | C32-B and C32-C added the linear stat endpoints using the same level prices. |

## Legacy allowance comparison

The recommended cutover preserves earned records. It prevents repeat payment, but gives no automatic wallet catch-up when a formerly unpriced first-clear or chapter-perfect was already marked consumed. A player can use approved recurring income, or an approved future replay amount. The v2 save records milestones and flags. The original amount each milestone paid cannot be reconstructed from those flags alone.

A separately approved allowance could credit a fixed list of previously recorded IDs once and exclude the already approved C1-01 award. One illustration is a legacy profile with all 15 clears, the six reference perfects and all four Records perfects. The proposed gross allowance would be 6.59M for Campaign first clears and completion, 820,000 for Campaign perfects and 350,000 for Records, totalling 7.76M. At a held 5M, the existing wallet would credit 4,999,999 and permanently discard 2,760,001. That size can jump several Control and HQ gates. An actual policy would need a frozen eligibility boundary, explicit handling for pre-existing paid claims, an idempotent ledger and an atomic transaction with normal cap behavior. Compare legacy cohorts and resolve the payout policy before changing persistence. [Returning-save results](../qa/C32_ECONOMY_AND_PROGRESSION.md#existing-saves)
