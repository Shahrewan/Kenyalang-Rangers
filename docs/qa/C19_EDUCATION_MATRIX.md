# C19 Outreach and Records verification

23 November 2026 · Godot `4.7.2.stable.official.ed1daf0bf` · Compatibility

| Area | Verified result |
|---|---|
| W18 handoff | Commit `0d23356` is on `main` via PR #19. The W18 validator passed three schemas, 20 Outreach questions, 40 Records questions, 20 facts, 32 cited sources, 480 shuffled answer permutations and the numeric location scan. |
| Approval gate | Godot opens the built Outreach and Records rooms and explains the pending content gate. The loader rejected W18 as draft. Separate synthetic data exercised valid records, incomplete awards, missing citations, invalid answers and grade duplication. |
| Outreach rotation | One batch of up to five distinct questions draws from the saved rotation. Four batches cover 20 unique IDs before reshuffle. A rollback retains the anchor. A forward jump opens one batch, and an expired prompt cannot pay. A bank revision preserves the current deadline. |
| Outreach settlement | All four grades use the selected authored choice after shuffle. Low-balance deductions stop at zero. Overflow shows the actual credit and discard. Only Best and Acceptable advance the Lv.5 participation gate. Answers and explanations remain reviewable after reload. |
| Records archive and quiz | Cited facts browse offline. Four chapters use Records Lv.2–5. The 15-second timer stops during pause, feedback and backgrounding. Normal exit saves the remaining ticks, and reopening the question requires Resume. Timeout displays an explanation and awards zero. |
| Replay and settlement | First-correct awards and perfect chapters have separate saved flags. Reopening feedback shows the recorded award. A replay can achieve its first perfect clear even if some answers already paid. Further correct answers and perfect clears award zero for the same IDs. |
| Named enhancements | All four chapter flags reach planning. Steady Aim and Focus use Scout's existing binding. Reinforced Patrol adds six against an aggressor. Emergency Treatment's confirmed kit restores 65 HP and clears current statuses. Woods Tracker's flag and tunable HP/redeploy fields are available for its pending field kit. Strike Team has no Records flag. |
| Native Linux | At 960×540 with synthetic data, a real pointer selected a shuffled Harmful response and deducted 6,250 Funds. The quiz countdown held while paused and reached timeout with zero reward after Resume. |
| Android development APK | Signed ARM64 package passed v2/v3 signatures, 16 KiB alignment and ZIP integrity. Host validation exercised the actual closed content gate and the packaged scripts with a synthetic test fixture. |
| Physical Android | Installation and touch, text and cutout observations await a USB-connected phone. |

The pinned editor import, startup and 1,680 checks across 22 runners passed. C19 accounts for 63 rules checks and 25 launcher UI checks. W18 remains in source review. The live questions and Records award amounts await approval. [Test commands](../../tests/README.md) · [Phone procedure](../../export/README.md#c19-education-phone-check)

## Timing and tuning

Outreach uses the device's local wall clock. Changing it can delay or advance eligibility. The offline timer opens at most one new batch per refresh. Records uses active game time. It checkpoints at one-second intervals and saves the exact integer tick on normal pause, background or exit. An abrupt stop before a lifecycle callback can restore the previous checkpoint.

Emergency Treatment allows one kit per deployment as a playtest choice. Patrolman and Woods Tracker HP, Combat Medic's shortened automatic heal interval, and Woods Tracker's reduced redeployment delay have tuning fields and await approved values. The Woods Tracker field kit remains pending from earlier milestones. [Decision log](../canon/DECISION_LOG.md#c19-outreach-and-records--2026-11-23)
