# C32-D · Economy rewards and Facility ownership

25 November 2026 · Baseline `65c91f7` after PR #43 · Godot `4.7.2.stable.official.ed1daf0bf` · Compatibility

C32-D installs the exact 45 remaining Campaign entries and four Records first-perfect bonuses for live playtesting. The 10,000 Funds C1-01 first clear and 30,000 Funds per unique first-correct Records answer retain their original amounts. All 25 permanent upgrade curves remain available under their original costs. [Approved schedule](../production/C32_ECONOMY_PROPOSAL.md)

Implementation `5397ef2` updates the 15 W13 stage reward sections, installed Records awards, the Firebreak Facility definition, and the existing Mechanical and results displays. A structural stage comparison verified that the sole change outside the reward sections is the C2-07 recruit. The existing save transaction applies the new data.

## Installed receipts and save rules

| Case | Funds and result |
| --- | --- |
| All 15 ordinary first clears | 5,500,000 first-clear Funds + 1,100,000 finale bonus = **6,600,000**. |
| All 15 perfect first clears | 6,600,000 + 1,850,000 perfect awards = **8,450,000**. |
| One successful replay per mission after first perfect | **64,000** in replay awards. |
| Later first-perfect finale | 265,000 first perfect + 9,000 replay. The prior first clear and completion flags remain consumed. |
| Failed or abandoned operation | Zero Funds and no clear unlock. |
| Replay with 400 of wallet space | 400 credited, 8,600 permanently discarded, with the result consumed once. |
| Every installed Records question and chapter | 1,200,000 across 40 unique first correct answers plus 350,000 across the four first-perfect bonuses. Each quiz reward and enhancement flag settles once. |

A successful C2-07 win grants the permanent Firebreak Beacon once. The temporary card is Lv.1 (220 HP, 40% Heat mitigation) and lives outside Mechanical slots on C2-07. A Lv.20 owned Beacon has 231 HP and 42% mitigation and occupies one regular Facility slot in eligible ordinary Story plans and Chaos. Deployment still spends 30 Tokens, builds for six seconds, and starts its existing 40-second type cooldown. An upgraded Beacon stays out of C2-07's regular slots and its plan offers one Lv.1 card. C2-08's 0.32× stage Heat gain and all combat content remain in place. [Facility and save tests](../../tests/unit/c32_economy_test.gd)

The C32-C update rehearsal preserved historical milestones and wallet balances, including the unpaid C2-07 clear, unpaid Records chapter-perfect flag and paid first-correct flags. A new successful replay earned 6,500 Funds and the missing recruit. An existing perfect chapter gave zero on replay. Failures to write the Story and Records results preserved the pre-result state and a retry committed both the award and its unlock or enhancement together. Compensation for historical graded or cleared content is a separate owner decision. [Package continuity runner](../../tests/release/player_continuity.gd)

## Fresh Campaign with genuine combat

One new profile started with 10,000 Funds. It used the shipping operation planner, real deployments, automatic attacks, legal skill activations, retreats, and normal Logistic Token production. The first three missions used explicit placements, and the remaining missions used the C30/C31 tactical player. Every win settled through `CampaignProgress` and the save cold-loaded after each operation. Campaign receipts supplied all income. The wallet reconciled to **3,355,121** after **7,885,000** earned and **4,539,879** spent.

| Mission | Defeated | Escaped | Integrity | Resolution tick | Funds credited | Wallet after |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| C1-01 | 14 | 0 | 100 | 8,692 | 15,000 | 25,000 |
| C1-02 | 17 | 1 | 90 | 8,169 | 30,000 | 35,000 |
| C1-03 | 28 | 5 | 50 | 12,899 | 60,000 | 95,000 |
| C1-04 | 36 | 0 | 100 | 13,456 | 140,000 | 190,000 |
| C1-05 | 35 | 0 | 100 | 14,700 | 240,000 | 430,000 |
| C2-01 | 60 | 0 | 100 | 14,508 | 320,000 | 410,000 |
| C2-02 | 66 | 0 | 100 | 19,492 | 400,000 | 448,124 |
| C2-03 | 71 | 1 | 90 | 15,841 | 360,000 | 808,124 |
| C2-04 | 73 | 2 | 80 | 16,320 | 420,000 | 818,028 |
| C2-05 | 110 | 0 | 100 | 22,881 | 640,000 | 1,158,028 |
| C2-06 | 89 | 0 | 100 | 14,340 | 720,000 | 1,878,028 |
| C2-07 | 128 | 0 | 60 | 22,290 | 800,000 | 2,028,028 |
| C2-08 | 102 | 0 | 50 | 24,678 | 880,000 | 2,847,932 |
| C2-09 | 138 | 0 | 100 | 25,560 | 960,000 | 2,907,932 |
| C2-10 | 139 | 1 | 85 | 31,680 | 1,900,000 | 3,355,121 |

The first clear funded Mechanical for 20,000 before C1-02. Control gates consumed 1,300,000 across Lv.2–5. The test bought a Lv.30 Post and upgraded Scout in time for C2-04, recruited all Story units and bought Firebreak Lv.20. Before the finale it brought Scout and Guard to Lv.80 and Patrolman to Lv.40. The earlier, lighter finale loadout lost to a Leader escape. The verified loadout earned an ordinary clear with one nonfatal escape and both Leader phases; the existing targeted C31-C/C32-C perfect fixtures remain separate evidence. The clear path used 10 perfect bonuses. The 6.6M and 8.45M totals above use deterministic settlement inputs to check the boundary cases. [Genuine combat ledger](evidence/c32-d/fresh-campaign.jsonl) · [Combat runner](../../tests/playtest/c32_d_fresh_campaign.gd)

The same runner cloned the saved C2-07 progress with the ownership gap of a returning profile and completed a second genuine C2-07 fight. The saved perfect stayed earned and the replay paid 6,500 and recruited the Beacon. The Android cutover test separately produced its historical save under the actual C32-C APK. [Returning replay](evidence/c32-d/returning-firebreak.jsonl)

## Recurring income and owner decisions

The comparison save has all 12 Rangers and 13 Facilities at Lv.100. Outreach ran five Best answers from the installed bank per tested tier. The alternate table used the C32 proposal in the isolated comparison.

| Outreach room | Current per 20-hour batch | Proposed per batch | Difference |
| --- | ---: | ---: | ---: |
| Lv.3 | 550,000 | 375,000 | −32% |
| Lv.4 | 900,000 | 450,000 | −50% |
| Lv.5 | 1,500,000 | 550,000 | −63% |

**Outreach recommendation for owner review.** Trial the upper-tier table separately. A fully successful Lv.5 batch each day for 60 days would gross up to 90M today versus 33M under the proposed table before wallet clipping or spending. The model below shows the mixed-profile sensitivity and supports measuring participation before finalizing amounts.

| Chaos recipe | Real combat | Current score / Funds | Proposed cap score / Funds |
| --- | --- | ---: | ---: |
| T01, 2 + 1 E01 | 3 defeats, zero escapes, 3,521 ticks | 1,030 / 41,200 | 130 / 2,600 |
| T01, 5 × 50 E01 | 250 defeats, zero escapes, 34,410 ticks | 3,200 / 324,000 | 3,200 / 324,000 |

**Chaos recommendation for owner review.** Trial the positive-debuff credit cap at the greater of 200 or the configured enemy points. It moves the three-enemy configuration below the 1,000-point trophy threshold while preserving the measured 250-enemy score, payout and tier. The settled points and timings above used the real resolver and genuine combat. The alternate credit was calculated on the completed study run before settlement into a disposable profile. Current Outreach and Chaos formulas remain active. [Max-level receipts](evidence/c32-d/max-level-recurring.jsonl) · [Existing rules and sensitivities](../production/C32_ECONOMY_PROPOSAL.md#owner-decisions)

## 7-, 30- and 60-day simulations

The financial model sets Story outcomes and attempts as scenario inputs. It exercises actual rewards, owned loadout resolution, Funds, room and level quotes, Outreach answers, Records answers, Garden transactions and day-end cold reloads. Chaos outcomes use genuine combat. Pre-activation uses the C32-C growth curves and historical reward/Beacon availability. Installed uses the C32-D data directly. Guardrails uses the same activated rewards plus the unapproved income sensitivities. Figures show gross positive income in millions of Funds.

| Profile | Pre-activation Day 7 / 30 / 60 | Installed Day 7 / 30 / 60 | Guardrails Day 7 / 30 / 60 |
| --- | ---: | ---: | ---: |
| Casual | 0.05 / 3.78 / 5.39 | 0.38 / 5.40 / 12.85 | 0.35 / 5.23 / 12.17 |
| Moderate | 0.97 / 6.27 / 10.91 | 1.17 / 11.37 / 21.25 | 1.09 / 9.97 / 16.43 |
| Chaos regular | 3.98 / 13.00 / 25.35 | 4.71 / 23.23 / 37.18 | 2.58 / 15.80 / 20.76 |
| Rare perfect | 0.97 / 6.27 / 10.91 | 1.16 / 10.72 / 19.01 | 1.08 / 9.42 / 15.58 |
| HQ first | 0.97 / 6.63 / 12.47 | 1.17 / 11.54 / 21.86 | 1.09 / 10.08 / 16.91 |
| Unit first | 0.97 / 5.16 / 8.22 | 1.17 / 10.31 / 18.50 | 1.09 / 9.55 / 15.32 |

All installed schedules reach 15 modeled Story clears by Day 60. The installed Chaos-regular profile spends 24.16M and discards 2,203,252 above the cap. With both guardrails it spends 19.71M and discards zero on the same policy. The installed moderate profile spends 20.76M, compared with 16.08M under the guardrails. Coordinate any final reductions with expected challenge frequency and other income sources. The validator reconciled **1,080 daily ledgers and 54 checkpoints**. [Daily ledger](evidence/c32-d/daily.csv) · [7/30/60 checkpoints](evidence/c32-d/checkpoints.csv) · [Timed progression](evidence/c32-d/progression.jsonl) · [Chaos recipes](evidence/c32-d/chaos-cases.jsonl)

## Rendered receipts

First Contact uses a real combat win. The later Story screenshots use the established narrative driver, which controls enemy outcomes so the game can show the exact award and unlock states. The Records screenshots use actual quiz answers. The Firebreak image shows the real unlocked Mechanical quote.

| Receipt | 1280×720 at 100% | 960×540 at 130% |
| --- | --- | --- |
| First Contact first awards | [PNG](c32-d/1280x720-text100/c1-01-result.png) | [PNG](c32-d/960x540-text130/c1-01-result.png) |
| Firebreak recruitment and first awards | [PNG](c32-d/1280x720-text100/c2-07-result.png) | [PNG](c32-d/960x540-text130/c2-07-result.png) |
| Finale completion, clear and perfect awards | [PNG](c32-d/1280x720-text100/c2-10-first-receipt.png) | [PNG](c32-d/960x540-text130/c2-10-first-receipt.png) |
| Records first correct | [PNG](c32-d/1280x720-text100/records-first-correct.png) | [PNG](c32-d/960x540-text130/records-first-correct.png) |
| Records first perfect | [PNG](c32-d/1280x720-text100/records-result.png) | [PNG](c32-d/960x540-text130/records-result.png) |
| Recruited Beacon Lv.20 quote | [PNG](c32-d/1280x720-text100/firebreak-upgrade.png) | [PNG](c32-d/960x540-text130/firebreak-upgrade.png) |

## Verification and Android

Godot import and startup passed with **5,078 checks across 40 regression runners**, including 514 economy checks, 1,049 Story checks, the original C31-C combat fixtures, and both growth suites. The full 60-day model passed **15,817 checks**. W29 catalog and art checks passed with 732 art checks. Native captures ran at both listed sizes. The Linux renderer reported its existing VSync switching warning.

```sh
python3 -B tools/run_regression.py --logs build/qa/c32-d/regression
godot --headless --path . --script res://tests/playtest/c32_d_fresh_campaign.gd
godot --headless --path . --script res://tests/balance/c32_d_recurring.gd
godot --headless --path . --script res://tests/balance/c32_economy.gd -- --daily > build/qa/c32-d/economy.log
python3 -B tools/summarize_c32_economy.py build/qa/c32-d/economy.log build/qa/c32-d/ledgers
```

The signed ARM64 debug APK `build/android/kenyalang-rangers-c32-d-debug.apk` is 40,181,974 bytes. APK Signature Scheme v2/v3 and 16 KiB alignment passed. SHA-256 `31f14890f58326518e668ee51afacdf18b1ed30c0c4f6a9ad96d60719c84d9ca`. The host loaded the exported resources and passed **3,141 checks** across 15 runners and six fresh and returning save phases. The package is `com.shahrewan.kenyalangrangers.dev`. The Android tools reported the existing themed-icon warning.

```sh
python3 -B tools/check_android_payload.py build/android/kenyalang-rangers-c32-d-debug.apk \
  --first-contact --hold-the-line --narrow-escape --campaign-visuals --combat-balance \
  --skill-orbs --ranger-kits --education --facility-growth --ranger-growth --economy-rewards \
  --previous build/android/kenyalang-rangers-c32-c-debug.apk --logs build/qa/c32-d/payload
```

ADB found zero devices. On a test phone with the compatible development signer and a backed-up save, run `adb install -r build/android/kenyalang-rangers-c32-d-debug.apk`, then launch offline. Use a returning C2-07 save, confirm the balance stays the same on startup, and clear C2-07 to check the 6,500 Funds receipt and recruit. Open Mechanical, buy a milestone, restart and deploy the purchased version in another Story or Chaos plan. Replay C2-07 to verify its single Lv.1 supplied card. Verify the Records first-correct and perfect receipts and that a replay adds zero for consumed flags. Check results and quote buttons at 130% text. [USB setup](../../export/README.md)
