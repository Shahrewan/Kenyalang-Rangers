# C32 · Economy and progression validation

Baseline `1119267` is main after PR #40. Godot `4.7.2.stable.official.ed1daf0bf`. The review adds a proposed value table, test harnesses and evidence. The live Campaign award fields, payout rules, save format and all game content retain their baseline values. [Proposal and owner decisions](../production/C32_ECONOMY_PROPOSAL.md)

## Evidence and assumptions

- **Installed** uses the post-C31-C player data. C1-01 credits 10,000 on first clear, Records pays 30,000 per unique first correct, other Campaign awards and Records chapter bonuses are pending.
- **Rewards** applies the proposed Campaign and Records values to disposable operation and catalog objects. All recurring sources use the installed values.
- **Guardrails** adds two isolated sensitivities to Rewards. Outreach Best amounts are 25k/60k/75k/90k/110k through its existing grading functions. Positive Chaos modifier credit is at most the greater of 200 or the configured enemy base points. Live assets and the payout curve stay in place.
- **GDD reference** allocates each published source goal in daily integer increments. Its expense curve uses the 52 priced room purchases and eight 1M tracks, without gameplay gates. It reproduces C23's reference experiment and isolates the effect of holding Funds.
- The three simulated variants use real wallet receipts, quotes, purchases, opt-in grade rules, timed gardens, installed quiz questions, Campaign unlocks and save transactions. Day-end cold reloads and wallet reconciliation cover all profiles. Story wins and perfects are scenario inputs. Before settlement the real planner checks prerequisites, ownership, affordable drops and effective loadouts. Story attempt times use successful 2× combat fixtures from C30/C31, 180 s per attempt for planning and reading, and 65% of combat time for scheduled losses. Chaos fights run through the real clock and damage system. The model therefore measures budgets under stated play choices. Actual player ability, reading times and challenge variety need a separate playtest. [C30 timings](C30_CAMPAIGN_BALANCE.md) · [C31-C timings](C31_C_LATE_CAMPAIGN.md)
- Active time counts modeled play and excludes offline watering gaps. Finance accrues on the simulated unpaused segments using the room level at that point. Finance storage saturation and wallet discard have separate columns. Story's 180 s allowance counts toward the session and is excluded from Finance to avoid crediting paused dialogue. Gross positive income is shown before losses and the wallet cap.

| Profile | Daily ceiling | Schedule |
| --- | ---: | --- |
| Casual | 15 min | One Garden visit, a Story attempt every three days, one Outreach response on two days a week, one Chaos clear weekly and a Records attempt every 14 days if eligible. |
| Moderate | 30 min | Two Garden visits, a Story attempt every other day, two Outreach responses on three days a week, two Chaos clears weekly and weekly Records. |
| Chaos regular | 75 min | Three Garden visits, daily Story attempts, three responses on four days a week, up to three Chaos runs on six days a week and Records every fourth day. |
| Rare perfect | 30 min | Moderate schedule with only C1-01 set to perfect. |
| HQ first | 30 min | Moderate schedule. Favors eligible room purchases before investing in units. |
| Unit first | 30 min | Moderate schedule. Prioritizes paid unit levels after buying required Story access and entry-level activity rooms. |

The default moderate, HQ-first, unit-first and Chaos-regular profiles aim for six reference Story perfects when all missions clear. The casual profile has three target perfects. All runs shop within the existing costs and gates and track up to eight preferred owned units. Every Chaos policy schedules one larger threshold run when its loadout is available. The remaining runs use the verified C23-style short route. Replays are optional and limited by the Story schedule. The session ceilings bound choices. They are larger than modeled active minutes because the model does not add idle play. [Daily ledger](evidence/c32/daily.csv) · [Checkpoint ledger](evidence/c32/checkpoints.csv) · [Full room and unit milestones](evidence/c32/progression.jsonl)

## Seven, thirty and sixty days

Gross positive income in millions of Funds. The exact ledger includes spending, remaining wallet and discard at every checkpoint.

| Profile | Installed 7 / 30 / 60 | Proposed awards 7 / 30 / 60 | Guardrails 7 / 30 / 60 |
| --- | ---: | ---: | ---: |
| Casual | 0.05 / 3.78 / 5.39 | 0.38 / 5.40 / 12.85 | 0.35 / 5.23 / 12.17 |
| Moderate | 0.97 / 6.27 / 10.91 | 1.17 / 11.37 / 21.25 | 1.09 / 9.97 / 16.43 |
| Chaos regular | 3.98 / 13.00 / 25.36 | 4.71 / 23.23 / 37.18 | 2.58 / 15.80 / 20.76 |
| Rare perfect | 0.97 / 6.27 / 10.91 | 1.16 / 10.72 / 19.02 | 1.08 / 9.42 / 15.58 |
| HQ first | 0.97 / 6.63 / 12.47 | 1.17 / 11.54 / 21.86 | 1.09 / 10.08 / 16.91 |
| Unit first | 0.97 / 5.16 / 8.22 | 1.17 / 10.31 / 18.50 | 1.09 / 9.55 / 15.32 |

### Day 60 with the proposed awards and current repeatable payouts

| Profile | Spent HQ | Spent Rangers | Spent Facilities | Wallet | Discarded | Active minutes | Story clears | Maxed units |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Casual | 5,040,000 | 5,000,000 | 2,660,953 | 89,716 | 0 | 279 | 15 | 7 |
| Moderate | 12,760,000 | 5,000,000 | 3,000,000 | 179,887 | 0 | 443 | 15 | 8 |
| Chaos regular | 16,160,000 | 5,000,000 | 3,000,000 | 9,999,999 | 2,206,357 | 772 | 15 | 8 |
| Rare perfect | 10,710,000 | 5,000,000 | 3,000,000 | 84,038 | 0 | 434 | 15 | 8 |
| HQ first | 16,160,000 | 3,851,954 | 1,451,383 | 52,230 | 0 | 443 | 15 | 4 |
| Unit first | 9,710,000 | 5,000,000 | 3,000,000 | 613,969 | 0 | 435 | 15 | 8 |

The moderate profile finishes Story on day 39 installed and day 35 with the proposal. The rare-perfect profile finishes on day 37 with one perfect, and all 15 ordinary clears are independently affordable without a single perfect or side payout. With the proposal, HQ-first maxes HQ on day 36 and has four maxed units at day 60. The unit-first profile maxes eight units on day 45 and spends 9.71M on HQ. The casual installed profile stops at 13 clears by day 60. The casual Rewards and Guardrails profiles finish Story on days 52 and 55 respectively. These are cash-flow and access results under the stated schedule. [Full progression checkpoints](evidence/c32/progression.jsonl)

### Comparison with the design scenario and C23

| 60-day source | GDD p. 21 | C23 installed audit | Same C23 policy on C31-C | C32 moderate with proposal |
| --- | ---: | ---: | ---: | ---: |
| Campaign first awards and completion | 7,420,000 | 0 | 10,000 | 7,420,000 |
| Outreach | 5,000,000 | 0 | 8,650,000 | 6,700,000 |
| Restoration | 5,300,000 | 3,917,000 | 4,277,000 | 4,282,000 |
| Chaos | 5,200,000 | 2,142,400 | 2,430,800 | 983,200 |
| Records | 1,550,000 | 0 | 1,200,000 | 1,550,000 |
| Finance and Story replays | 550,000 | 304,200 | 445,800 | 315,937 |
| **Gross total** | **25,020,000** | **6,363,600** | **17,013,600** | **21,251,137** |

C23's old policy reaches 13 clears and 6.06M spent. Running the same harness against C31-C reaches 15 clears and 16.86M spent after the live banks and the approved starter award. The C32 moderate policy attempts fewer Chaos runs and grades some Outreach answers Acceptable, Poor or Harmful instead of submitting all Best answers. In the GDD reference, buying as Funds arrive reaches 24.16M spent on day 58 and holds 870,000 on day 60. Waiting to spend until day 60 loses 15,030,001 and spends 9.99M. Both reference paths start with 10,000. [C23 report](C23_SYSTEM_AUDIT.md#sixty-day-balance) · [C23-policy rerun](evidence/c32/c23-policy-current.txt) · [Reference checkpoints](evidence/c32/gdd-reference.jsonl)

## Repeatable income and cap

| Observed Chaos recipe | Actual combat | Current settlement | Proposed scoring sensitivity |
| --- | --- | ---: | ---: |
| T01, three E01 across two waves | 4,421 ticks, 0 escapes · ~37 s at 2× | 1,030 points · 41,200 | 130 points · 2,600 |
| T01, 250 E01 across five waves | 34,938 ticks, 0 escapes · ~291 s at 2× | 3,200 points · 324,000 | 3,200 points · 324,000 |

Both use actual deployments and cooldowns, the D05 stockpile and eligible existing debuffs. The longer run requires the Guard, Scout, Patrolman and Medic loadout and the roster capacity to select it. Its first qualifying result earns all three Chaos Facilities on a profile that has earned none. For three enemies, modifiers contribute 1,100 points to a base of 30 before the slot cost. At the measured combat cadence, 127 short clears beat the 5.2M allocation in about 78 minutes of combat or 205 minutes with the modeled minute of setup per run. The tested cap on positive modifier credit brings the short recipe below the first threshold and keeps the 3,200-point earned clear at its existing rate. [Exact Chaos runs](evidence/c32/chaos-cases.jsonl)

Outreach is the largest recurring source in the high-activity profile. The installed Lv.5 table can pay 1.5M for five Best answers in one 20-hour batch. At one such batch daily that would reach 90M in 60 days before cap and spending. This is a ceiling, not a participation forecast. The model's high profile earns **12.80M** from Outreach before proposed Story awards and **16.58M** after them, because room purchases happen earlier. Under combined guardrails it earns **6.24M**. The moderate profile drops from **6.70M** to **2.55M** under the same sensitivity, below the 5M design allocation. This supports testing the upper-room payout slope with players before locking the exact table.

The post-award Chaos-regular profile reaches the 24.16M spend target on day 34 and discards **2,206,357**, holding the full prototype cap at day 60. Combined guardrails bring that same profile to **20.76M gross** and zero discard. The GDD hold-until-day-60 case shows that much larger overflow is possible from delayed spending alone. Retain the prototype cap during balance testing. Evaluate repeatable rates and spending behavior before using overflow as a reason to raise it.

### Test the target with a longer Chaos mix

With both guardrails active, two supplemental runs replaced some short-route clears within the same 156-attempt schedule with fully played 250-enemy challenges. The overall run ceiling and other activity policies stayed the same.

| Minimum gap between larger challenges | Larger clears | Day 60 gross | Spend | End wallet | Active minutes | Wallet discard | Milestone |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Three days | 12 | 24,342,483 | 22,860,000 | 1,200,278 | 815 | 0 | Eight units maxed on day 39. The last HQ purchase is 99,722 short. |
| Two days | 17 | 25,969,133 | 24,160,000 | 1,500,383 | 837 | 0 | Eight units maxed on day 37 and full HQ on day 55. |

The two-day case earns 5.87M from Chaos and averages about 14 active minutes per calendar day across all modes. It provides a tested route to the GDD spend target with the proposed guardrails. It assumes the deterministic T01 clear, including one-minute planning, and does not establish success rates on varied maps. The much smaller short-run credits leave room to test reducing the frequency of those runs in a mixed player session. [Supplemental checkpoints](evidence/c32/long-chaos-mix.jsonl)

Restoration's largest repeat yield is Mengaris at 18,000 per 72 h, or 250 Funds per plot-hour. Even six immediately available plots with continuous cycles could earn only 2.16M repeat Funds in 60 days. The five one-time milestones add 2.55M, leaving a generous **4.71M ceiling**, at least **590,000 below** the GDD's 5.30M. Real unlocks, mixed species and late watering reduce that ceiling. The proposed-award profiles generate 3.54M–4.34M from Restoration across the six schedules. Preserve Garden participation and re-budget the target around the measured results before considering additional first-species grants.

## Progression gates

| Checkpoint | Live cost and requirement | Evidence |
| --- | --- | --- |
| Mechanical Lv.1 before the ordinary C1-02 opening | 20,000 · no participation requirement | A fresh 10,000 wallet plus the approved C1-01 ordinary award pays exactly. The test places the free 2×1 ordinary Post at zero Tokens through the effective C1-02 plan. |
| Control Lv.2 before C1-04 | 20,000 increment · C1-03 prerequisite | 100,000 cumulative proposed ordinary income through C1-03 covers this and Mechanical. Required cumulative spend is 40,000. |
| Control Lv.3 before C2-01 | 80,000 increment · C1-05 prerequisite | 380,000 cumulative ordinary income versus 120,000 required spend. |
| Control Lv.4 before C2-05 | 300,000 increment · C2-04 prerequisite | 1.70M cumulative ordinary income versus 420,000 required spend. |
| Control Lv.5 before C2-09 | 900,000 increment · C2-08 prerequisite | 3.98M cumulative ordinary income versus 1.32M required spend. |
| Rangers and Facilities | Campaign and Chaos ownership. Facility level purchases additionally require Mechanical. | Live first-clear grants commit with the award and old grants survive reload. The 3,200-point clear supplies the three Chaos threshold Facilities. Firebreak is mission supply. |
| Ecology Lv.5 | 900,000 for the final level and 60% restoration | Three distinct matured species qualify. The test exercises planting, midpoint watering and maturity before the room purchase. |
| Outreach Lv.5 | 950,000 for the final level and five Best or Acceptable responses | Four qualifying responses still block the purchase. The fifth valid response opens it. |
| R&D | 6.70M for the four full rooms | Live gates provide 15 distinct effects at their authored room tiers. Purchasing them does not require a quiz or Story perfect flag. |
| Long-term HQ and eight units | 52 paid HQ purchases cost 16.16M. Each Lv.1→100 track costs 1M. | Buying all 25 unit tracks as well as HQ would cost 41.16M. The GDD 60-day reference covers eight tracks. |

The ordinary-clear route spends 1.32M on required rooms and holds 5.29M after the finale if the player skips all discretionary purchases. In the mixed profiles, elective room and level purchases can bring individual gates forward or push them later. The paid level checkpoints cost 60,096, 191,001, 391,287, 660,953 and 1,000,000 cumulatively. The level tests verify quotes, ownership and persistence. Generic HP, damage and utility growth endpoints are still unset in the current Ranger and Facility resources. The Logistics Post has its separate verified 10→15 Token yield curve. A paid level count alone is therefore an economy milestone. Combat value per Funds requires its own tuning decision.

## Existing saves

The tests reopen disposable v2 saves created through the actual settlement paths. The historical unpriced finale and chapter-perfect flags survive. The proposed C2-10 schedule gives a returning normal-clear profile **274,000** on its first perfect replay (265,000 perfect plus 9,000 replay), then 9,000 on subsequent replays. An existing perfect Records chapter remains consumed under a schedule change. A new player who gets only nine first-correct answers receives 270,000; a later perfect pays the missing 30,000 question award and the independent 50,000 proposed Scout chapter bonus. Further perfect attempts credit zero. The duplicate-settlement callback test requires an open attempt, and clears and flags are stored together.

An older C1-01 clear with the 10,000 starting wallet can still fund Mechanical with 5,000 active Lv.1 Finance seconds. The proposed 500 replay reduces that fallback to 4,750 active seconds. A returning test save at Control Lv.4 with C2-08 already cleared and zero held Funds buys Control Lv.5 after four existing Lv.3 Outreach batches of five Acceptable responses. This credits 1.10M across 60 elapsed hours from the first to fourth batch, leaves 200,000 after the upgrade and opens a legal C2-09 plan. The latter is a worked recurring-income route for a player who already has Outreach Lv.3. Under the lower Outreach sensitivity, five equivalent batches would credit 937,500 in 80 elapsed hours. Finance and Chaos remain repeatable when access differs. The catch-up allowances discussed in the proposal remain pending separate approval. [Options and cap example](../production/C32_ECONOMY_PROPOSAL.md#legacy-allowance-comparison)

## Reproduce and verify

Godot editor import, launcher startup and **3,744 checks across 38 runners** passed. The 314 new economy checks cover the proposal boundary, live reward predicates, actual room and deployable purchases, legacy eligibility, repeated Records, and Chaos settlement. The full six-profile simulation and repeat produced byte-identical ledgers with 15,817 checks and zero failures per run. The extractor independently reconciled 1,080 day records and 54 checkpoints. The three- and two-day longer Chaos mixes passed 1,170 and 1,171 checks respectively. The W29 catalog and Campaign registration validators passed. Runtime source, resources and export selection are identical to main, so this analysis milestone did not require a new Android package.

```sh
mkdir -p build/qa/c32
python3 -B tools/run_regression.py --logs build/qa/c32/regression
godot --headless --path . --script res://tests/balance/c32_economy.gd -- --daily > build/qa/c32/ledger.log
python3 -B tools/summarize_c32_economy.py build/qa/c32/ledger.log build/qa/c32/evidence
godot --headless --path . --script res://tests/balance/c32_economy.gd -- --long-chaos-mix
godot --headless --path . --script res://tests/balance/c32_economy.gd -- --long-chaos-mix=2
godot --headless --path . --script res://tests/balance/economy_60_days.gd
```

The model and tests use disposable `user://` paths with their own filenames. For repeatable runs with no system profile access, set `XDG_DATA_HOME`, `XDG_CACHE_HOME` and `XDG_CONFIG_HOME` to writable temporary directories. [Daily receipts](evidence/c32/daily.csv) · [7-, 30- and 60-day checkpoints](evidence/c32/checkpoints.csv) · [Source proposal](../production/c32/rewards_proposal.json)
