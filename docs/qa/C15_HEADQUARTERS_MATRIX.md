# C15 Headquarters verification

22 November 2026 · Godot `4.7.2.stable.official.ed1daf0bf` · Compatibility

| Area | Verified result |
|---|---|
| Room catalog | Eleven selectable rooms, three free openings, 55 prices and all completed purchases totaling 16,160,000 Funds. |
| Planner and capacity | HR and Mechanical unlock 3/4/5/6/8 Ranger slots and 2/3/4/5/6 Facility slots. Control reveals stages with ordered clears intact. |
| Participation | Ecology Lv.5 requires 60% restoration and the purchase price. Outreach Lv.5 requires five Best or Acceptable responses and its price. Records and R&D expose all sourced tier unlocks. |
| Finance and wallet | The five active rates and storage caps, focused and suspended behavior, separate stored balance, exact credit and discard preview, canceled claim, confirmed claim, and capped stage settlement. |
| Levels | All 25 unlockable IDs have L1–100 purchases. The 99 price steps and five milestone quotes reconcile to 1,000,000 Funds per ID. The Story planner carries purchased levels into an ordinary Post. The Lv.20 Post pays 21 Tokens over the first two installments, and Lv.100 pays 15 per installment. Geometry, block, charges and time settings stay fixed. |
| Activity persistence | Outreach reply order and grades, a deduction clamped to held Funds, 20-hour refresh boundaries, Records timer and one-time awards, and garden timer anchors and atomic collection settlement. |
| Migration and recovery | C14 v1 converts into v2 in place, damaged primary heals from a valid backup, an unreadable or newer save is preserved, failed writes leave the prior state, and only confirmed Settings reset invalidates the backup. An interrupted operation reopens at planning. |
| Linux pointer | At 960×540, the main menu opened the eleven-room cross-section. Human Resources opened Scout Sniper. The Lv.20 quote showed 60,096 Funds, cancel preserved 186,500, and confirmation saved Lv.20 and 126,404 Funds. |
| Android development export | Signed ARM64 APK passed v2/v3 verification, 16 KiB alignment and ZIP integrity. Isolated host launch using the extracted APK assets opened all 11 HQ room controls and the Scout Lv.20 quote, with 15 W13 operations loaded. |
| Physical Android | Pending a USB-connected phone. The cloud environment has no physical USB bus. |

The 260 progression checks and 40 UI checks ran with the 928 existing checks, totaling 1,228 across 15 runners. Tests used temporary profiles. [Launch and test commands](../../tests/README.md)

## Playtest choices

At C15, the starting balance and 9,999,999 wallet cap retained the approved trial values. The Logistics Post production endpoints were active, and other raw-stat endpoints still awaited review. C32-B added trial growth for all 13 Facilities. [Facility levels, screenshots and live combat verification](C32_B_FACILITY_GROWTH.md)

The save tests cover grade, timer and reward transactions using fixture IDs. Live Outreach and Records require authored banks and their activity screens. Live planting and collection belong to C20. C15 exposes room access, gates and the saved garden summary. Stage and finale payouts remain pending as documented in W13. [Decisions](../canon/DECISION_LOG.md#c15-headquarters-and-local-progression--2026-11-22) · [Physical phone checklist](../../export/README.md#c15-headquarters-phone-check)
