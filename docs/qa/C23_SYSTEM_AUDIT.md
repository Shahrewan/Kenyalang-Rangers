# C23 regression, economy and recovery audit

23 November 2026. **Host regression passed. The Android performance gate and content decisions remain open.** Godot `4.7.2.stable.official.ed1daf0bf`, Compatibility. The C22 baseline passed 1,861 checks in 25 runners. A clean archive of C23 implementation `1780f08` passed editor import, launcher boot and 1,975 checks in 28 runners. The two 60-day runs produced byte-identical output. The separate operating-system interruption test also passed. [Runner totals](evidence/c23/suite.txt) · [Day-by-day ledger](evidence/c23/economy.txt) · [Crash result](evidence/c23/process-kill.txt)

## System coverage

| System | What ran and what remains |
|---|---|
| Campaign, Rangers and Facilities | All 15 stage resources loaded. Existing Story tests exercise prerequisites, dialogue, escapes, results and replay settlement. The new catalog test walks 2,475 level transitions across all 12 Ranger and 13 Facility definitions. Each track totals 1M and preserves footprint and construction time. Seven Ranger kits are field-selectable. K9 Ranger, Kenyalang Seer, Woods Tracker, Saboteurist and Strike Team have recruitment and upgrade records pending field integration. Firebreak Beacon has C2-07 mission supply and no permanent acquisition source. |
| Enemies, modifiers and time | Enemy and boss runners cover 15 standard enemies and three bosses. Modifier rules, combat and UI cover 15 buffs and 15 debuffs. Logistics and deployment cover the first free Post, D05 and footprint validation. Two repeated 50-enemy trials compared individual HP, distances and deadlines after pause, full-screen dialogue and resume. |
| Progression and activities | HQ tests cover all 11 room prices, participation gates, Finance claims and wallet cap. Chaos tests cover qualification, payout boundaries, best and one-time unlocks. Education tests cover the 20-hour boundary, PR grading, timed Records and first-correct settlement with synthetic banks. Garden tests cover four species, missed watering, clock changes, cycles and all five milestones. The W18 draft validator passed 20 Outreach situations and 40 Records questions. Editorial approval is open. |
| Persistence | v1 migration, backup recovery, newer saves, reset interruption and failed writes passed. C23 reproduced and fixed three defects. Failed Chaos abandonment now retains the attempt until the draft clears, and failed discard keeps Retry available. An invalid Records bank revision is rejected before writing. A plot marked both active and already collected triggers backup recovery, which restores a usable plot and a single harvest award. Story and Chaos preserve the paused confirmation screen on a failed abandon write. |
| Process interruption | A fresh Godot process committed a planting and a Best Outreach answer, then held open a deliberately partial scratch file for the next write. The Linux harness killed that process. A second process recovered the committed 35,000 Funds and the same PR answer and refresh deadline, rejected a duplicate response, resumed the plant and saved exactly 93,000 Funds after one harvest. This tests application death with a torn temporary file. Storage power loss and physical Android process death are unverified. |

GDD pp. 20–21 §§ M.2–3 and pp. 29–31 §§ O.2–4, S.2–3 specify these checks. Storyboard S19, S34, S36–S40 and S58–S59 cover the associated pause, wallet, award and wave-limit UI. The existing W21 source validator also passed all 116 frame mappings.

## Sixty-day balance

| Gross source (Funds) | GDD p. 21 scenario | Installed-content run |
|---|---:|---:|
| Campaign clears and perfection | 7,420,000 | 0 |
| PR Outreach | 5,000,000 | 0 |
| Habitat Restoration | 5,300,000 | 3,917,000 |
| Rainforest Chaos | 5,200,000 | 2,142,400 |
| Records | 1,550,000 | 0 |
| Finance and ordinary replays | 550,000 | 304,200 |
| **Total** | **25,020,000** | **6,363,600** |

**Budget experiment.** The reference column distributes each GDD source target over 60 days using cumulative integer differences. It assumes access to all purchases. After each day's receipts, it buys the 52 paid room levels in catalog order and then eight 1M deployable upgrades as Funds permit. Starting with 10,000, it reaches the 24.16M expense on day 58 and ends with 870,000. Holding the same receipts until day 60 discards 15,030,001 at the cap, leaving only 9,990,000 spent and 9,999 held. This isolates the effect of purchase timing.

**Installed-content scenario.** Each day claims ten active minutes of Finance, visits the garden 12 hours apart, attempts one accessible Story mission and plays one Chaos clear once Mechanical is built. The model grants a perfect Story result only after prerequisite and legal-opening checks. It assumes victory there. Chaos uses actual combat and settlement every time. Weekly study uses installed approved data if present. The schedule includes zero ordinary replays. Spending prioritizes the first Mechanical and Ecology purchases, then the cheapest eligible room with catalog order breaking ties, then owned field entries up to eight. Plots initially rotate species by slot and switch to Mengaris after 100% restoration. Each day cold-loads and compares the full logical profile.

The scenario bought Mechanical on day 9, recorded 13 Story clears, 52 qualifying Chaos clears and 86 harvests. It spent 6,060,000 on HQ, reached zero max-level deployables, discarded zero, and ended with 313,600 Funds. Control Lv.4 held back C2-09. All W13 stage award values are pending. Outreach and Records have no approved runtime banks, which also prevents the five qualifying responses for Outreach Lv.5. These results describe the specified activity schedule. Human playtime and win rates remain unmeasured.

### Balance findings for owner review

1. **Garden has a hard shortfall.** The highest current base yield is 250 Funds per plot-hour. Even six immediately unlocked plots with perfect timing can earn at most 2,160,000 in 60 days, plus 2,550,000 in one-time milestones. That generous 4,710,000 ceiling falls at least 590,000 short of 5.30M. Review the source allocation or the pending first-species rewards and rerun with realistic unlocks and watering gaps.
2. **A three-enemy repeatable Chaos clear pays 41,200.** On T01, two E01 plus one E01 in a second wave, Patrolman and Post selected, and D02/03/05/07/08/12/13/15 produce 1,030 points. D05 removes the Post. A Lv.1 Patrolman at (2,1) facing left defeats all three in 4,439 ticks. Repeating this case 127 times exceeds the entire 5.20M allocation in approximately 78.3 ideal minutes at 2×, excluding menus and placement. Review low-enemy modifier scoring and measure setup time with players before changing payouts.
3. **Early and endgame gates need content decisions.** A pristine profile is 10,000 short of Mechanical after the unpriced first clear. At Lv.1 Finance that costs 5,000 active seconds. Approve first-clear, perfect and replay amounts, W18 banks and awards, and permanent Firebreak acquisition, then repeat the installed-content simulation. The 15.03M delayed-spend loss is evidence for reviewing the prototype cap and warning UX. All balances and source reward values retain their existing settings.

## Dense-wave benchmark

The benchmark starts a real T05 battle view with two Rangers, two Facilities, 46 Shield Carriers, two Demolitionists, one Ignition Operator and the Diversion Captain. To keep all 50 resident together, the QA scene gives its local enemy copies tenfold HP, compresses spawns to one tick, spreads them on the route, seeds overlapping mark/slow deadlines and starts Heat near overflow. Actual attacks, movement, boss introduction, construction, Siege and Heat run on the shared clock. It samples monotonic time between process frames while all 50 are resident for approximately 6.8 combat seconds. FPS is frames divided by elapsed time. The memory counter measures Godot static allocations. OS process memory needs a separate phone reading.

The three packaged X11 runs used a 1152×648 window, a 1280×720 logical viewport, an AMD EPYC 9V74 and Mesa llvmpipe software rendering capped at 60 FPS. The driver reported unsupported V-Sync switching.

| Linux run | Frames sampled | Average FPS | p50 / p95 / p99 (ms) | Worst (ms) | Peak Godot static bytes |
|---|---:|---:|---|---:|---:|
| 1 | 348 | 50.78 | 18.25 / 26.00 / 29.86 | 175.85 | 41,361,763 |
| 2 | 289 | 42.47 | 21.58 / 34.65 / 71.38 | 86.09 | 41,361,387 |
| 3 | 332 | 48.66 | 18.70 / 29.09 / 41.58 | 89.24 | 41,361,387 |

**Android gate open.** ADB 37.0.3 successfully started and listed zero devices. The workspace exposes no USB bus. No phone model, Android FPS, memory measurement or user playtest is available. The separate signed ARM64 benchmark app starts this load directly and logs a machine-readable result. The ordinary debug APK retains the player launcher. Both passed signature v2/v3, ZIP and 16 KiB alignment checks and host-side packaged startup. The benchmark payload recorded 50 resident actors, four deployables, two Siege hits and one Heat overflow. [Physical-phone procedure](../../export/README.md#c23-physical-phone-benchmark) · [Rendered Linux runs](evidence/c23/rendered.jsonl)

Both debug APKs use matching 4.7.2 templates, minimum API 24, target API 36 and landscape orientation. The package inspector also emitted the existing template themed-icon warning. Local SHA-256 digests identify the tested binaries.

| Package | SHA-256 |
|---|---|
| Player `com.shahrewan.kenyalangrangers.dev` | `ea8a70b321f8e00709b717973fc6d5757089b316b254c03d0a06efb003779cbf` |
| Benchmark `com.shahrewan.kenyalangrangers.c23bench` | `e53a03c7020b716e050fd953ce077f90011dfba89c51ed3afb8623ac6033895a` |

## Reproduce

From the repository root with the pinned Godot on PATH and Python 3.11+ installed, run the following. The regression runner imports before running any scripts and isolates each user directory. The simulator uses a disposable profile.

```sh
python3 tools/run_regression.py
python3 tools/check_crash_recovery.py
godot --headless --path . --script res://tests/balance/economy_60_days.gd
godot --path . --resolution 1152x648 res://scenes/qa/c23_load.tscn
```

The final command reports host frame intervals and quits automatically. Per-runner logs are written under `build/qa/c23/`. The committed ledger includes all 60 daily income, purchase, discarded Funds and closing-balance entries.
