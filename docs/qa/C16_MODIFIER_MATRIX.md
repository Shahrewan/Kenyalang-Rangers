# C16 battle modifier verification

22 November 2026 · Godot `4.7.2.stable.official.ed1daf0bf` · Compatibility

| Area | Verified result |
|---|---|
| Catalog and research | B01–B15 and D01–D15 use their GDD IDs, names, effects and signed point weights. The four R&D rooms unlock choices at their existing tiers with fixed potency. |
| Story planning | All 15 operations use their authored fixed debuff counts. The picker enforces one optional buff in Chapter 1 and two distinct buffs in Chapter 2. It explains locked and ineligible choices. The battle consumes the same opening, roster and stage snapshot as planning. |
| Chaos eligibility | The modifier trial uses the T01 route, two fixed waves and actual HQ unlocks. Duplicate, locked and incompatible selections are rejected. Empty spawn groups provide no eligibility. The resolver checks legal footprints, affordable openings, encounters and relevant abilities. An invalid setup contributes zero modifier points. |
| B01–B08 | Recon highlights the configured entry points before the wave. Heat, spawn reveal, escape, Ranger damage, attack rate, recharge and one-time damage multiplication per hit were checked on the shared clock. Damage marks, stun, immobilize, actual slow and the completed Disruption zone qualify for B08. |
| B09–B15 | Ranger HP and healing adjust. Blocking modifies received damage. Brace absorbs one Knockdown per placement. B13 changes opening Tokens and carried Post yield. B14 applies both the damage increase and HP loss. B15 disables manual actives and shortens Ranger and Facility redeploy cooldowns. |
| D01–D08 | Post yield, enemy movement, Ranger HP, active-skill recharge, stockpile, smoke, between-wave rest and enemy HP all change in the relevant fixtures. D05 removed the Post, set 120 Tokens and blocked B13. |
| D09–D15 | A real Siege attack hits a Facility under construction for the increased damage. D10 extends timed construction and preserves the instant first Post. Aerial speed, rounded Ranger prices, shortened spawn gaps, Heat and rounded ordinary escape penalties were checked. |
| Linux pointer | At 960×540, selected B01 and D05, scrolled to the B13 conflict message, read the 120-Token opening preview, then started the trial. The tray had no Post. The field highlighted the entry point and showed five combat seconds before Wave 1. |
| Android development export | Signed ARM64 APK passed v2/v3 signatures, 16 KiB alignment and ZIP integrity. The catalog, trial and all 16 W13 JSON resources were present. The 29 modifier UI checks passed in an isolated Godot host run using only the extracted APK assets and the external runner. |
| Physical Android | USB installation, touch and cutout checks await a connected phone. The cloud environment has no USB device bus. |

The pinned editor import and headless startup succeeded. The full suite passed 1,458 checks across 18 runners, including 155 catalog and eligibility checks, 46 combat checks, and 29 UI checks for C16. [Launch and test commands](../../tests/README.md) · [Phone checklist](../../export/README.md#c16-modifier-phone-check)

## Stacking and applicability

- Apply reviewed permanent level values before battle modifiers. Mission supplies retain their authored levels. Add percentage points on the same stat and round integer damage and HP to nearest. B05 and B14 cover Ranger basic attacks and positive skill damage. D02 plus D11 gives aerial enemies +35% movement speed. B13 and B15 give 90% Post yield together, or 80% with D01, including fractional carry. B02 and D14 give 105% Heat gain before Firebreak's named multiplier.
- Divide recharge duration by recovery rate. B07 and D04 together give the original duration before other effects. Enemy jam adds its own fixed delay. B15 turns off manual Ranger and Facility skills, including Medic Cabin and Specialist Calltower, and applies a 0.65 multiplier to redeploy durations.
- B06 changes damaging auto-attacks. The rate combines multiplicatively with Coordination Hub and Tracking Bot. B08 applies once per hit alongside capped incoming damage marks. Detection and spawn reveal by themselves do not qualify. B10 increases healing received by Rangers. Repair uses its own rules. B11 applies while a Ranger is actually blocking and combines multiplicatively with named reductions. Barricade Ops retains its Knockdown immunity.
- Round D12 Ranger prices up with exact percentage arithmetic. Round the D15 ordinary penalty up first, then apply the B04 reduction and round to nearest, with a positive minimum of one. Both the fatal escape rules and perfect-clear disqualification still apply.
- D05 requires a legal Post in the baseline loadout and an affordable Post-free opening. D09 requires a Siege-capable enemy and a potentially reachable Facility. D10 needs a possible timed build, which may be a later ordinary Post if it can fit beside the first or a Siege enemy can destroy the first. D07 counts the rests before later populated waves. D13 applies to actual between-spawn delays in populated wave queues. Scripted boss reinforcements use their separate phase timings.
- A fixed Story debuff still appears if it lacks a target. The plan explains why it is inactive. Trial modifier points are a preview. Route and wave editing, total Medal Score, payouts, trophy and personal-best settlement belong to C17.

The overlap order uses C16 playtest choices where the GDD leaves timing and rounding open. Release balance awaits configurable Chaos and physical-phone playtests. [D-011](../canon/DECISION_LOG.md#d-011-c16-battle-modifier-playtest--2026-11-22)
