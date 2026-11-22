# C17 Rainforest Chaos verification

22 November 2026 · Godot `4.7.2.stable.official.ed1daf0bf` · Compatibility

| Area | Verified result |
|---|---|
| Route and wave editor | Six original boards and all 18 enemy types use the existing tactical data. Five independent slots cap mixed quantities at 50 through sliders and plus/minus. The all-empty setup blocks Start. Leading, intervening and trailing empty slots contribute zero spawns and zero rest. |
| Worked example | Gunung Mulu runs 20 Poachers, 10 Contraband Runners, 10 Shield Carriers and 10 Recon Drones in Wave 1, then 10 Demolitionists in Wave 2. Enemy subtotals are 1,050 and 500. D02, D09 and D11 contribute +400. Three Rangers and two Facilities cost 500 points, and B05 costs 100. The preview and qualifying result agree on 1,350 Medal Score and 54,000 Funds, with Tier 1. |
| Modifier and loadout changes | Open slots contribute zero, and D05 excludes the Post from the slot count. Removing the final Siege enemy invalidates D09 and blocks the challenge. The modifier sheet previews the score and restores the prior selection on Cancel. |
| Outcome | An escape with Integrity remaining shows the unqualified report and pays zero. Defeat and confirmed abandon likewise award zero. Boss reinforcements use the real combat path. They resolve against the battle, and points and configured defeats come from the editor queue. Any registered combat escape forfeits the payout. |
| Payout boundaries | Scores −100/0/1/999/1,000/1,999/2,000/2,999/3,000/3,500/5,000 pay 0/0/20/19,980/40,000/79,960/130,000/199,930/300,000/360,000/540,000 gross Funds. |
| Transaction and trophy | A first qualifying 3,500 awards all three Facilities together with Tier 3. A capped wallet credits 10,000 and discards 350,000 in the test. A later clear can pay again, and crossing 3,000 keeps the final trophy look as the number rises. The same record appears in the route picker and the HQ ground-floor entrance. |
| Save continuity | Closing with a challenge in progress reopens its route, wave counts, modifiers and loadout at planning, with a fresh combat clock on Start. A failed result write leaves the profile intact and exposes Retry. One successful commit clears the pending configuration, updates wallet and best, and grants each first unlock. Those awards survive a cold load. |
| Native Linux | At 960×540, changed the route and loadout, filled one mixed wave with 49 Trespassers and one Poacher and checked a third slider at the cap. Played an actual one-Trespasser challenge using a Post and Scout. The 10-point preview matched the 200-Funds payout and the saved balance of 10,200. |
| Android development APK | Signed ARM64 package verified with v2/v3 signatures, 16 KiB alignment and ZIP integrity. Ran the C17 rules and UI checks on the host from the packaged Godot assets. |
| Physical Android | USB installation, touch size, cutout fit and performance await a named phone. The cloud workspace has no physical USB bus. |

The pinned editor import and headless startup passed. The complete suite passed 1,592 checks across 20 runners, including 94 C17 rules checks and 40 C17 UI checks. [Test commands](../../tests/README.md) · [Phone procedure](../../export/README.md#c17-rainforest-chaos-phone-check)

## Playtest timing

Chaos uses 18 combat seconds before the opening arrival, 2.5 seconds between queued enemies and 18 seconds between populated waves. Groups follow the existing enemy catalog order. On Gunung Mulu, groups alternate between the two authored entries and successive populated waves change the leading entry. Imbak Canyon uses the Story playtest Heat cap of 100 and 10 Integrity per reset. Release pacing and balance across long queues await playtest. [Decision log](../canon/DECISION_LOG.md#c17-rainforest-chaos-playtest--2026-11-22)
