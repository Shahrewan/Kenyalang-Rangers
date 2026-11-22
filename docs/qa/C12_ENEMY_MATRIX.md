# C12 enemy and boss test matrix

Run both scripts with the pinned Godot 4.7.2 editor after import.

```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/unit/enemy_combat_test.gd
godot --headless --path . --script res://tests/unit/boss_combat_test.gd
```

Each row runs through registration, authored HP, ordinary or Siege target selection and damage, pause or dialogue, defeat and escape settlement. The encounter column identifies the additional assertions. Values marked provisional in the GDD or added for the trials are recorded in the [decision log](../canon/DECISION_LOG.md#d-006-and-d-008-c12-enemy-and-boss-tuning--2026-11-22).

| Encounter | Additional automated coverage |
|---|---|
| E01 Forest Trespasser | Ground melee and the existing C1-01 perfect clear and ordinary escape regressions. |
| E02 Poacher | Ground melee output and ordinary Integrity settlement. |
| E03 Contraband Runner | Sprint activates after the initial delay, multiplies movement and holds while paused. |
| E04 Shield Carrier | The sourced 450 HP pool and the capped damage-mark fixture. |
| E05 Rifle Spotter | Ordinary ranged damage to an elevated Ranger beside an untouched Facility site. |
| E06 Smoke Infiltrator | Temporary concealed targeting, zero-damage detection and mark from the scan fixture, and natural expiry. |
| E07 Signal Jammer | Disruption extends its windup. Dialogue freezes it. The jam interrupts aiming, locks skill use and extends pending recharge as a separate event from damage. |
| E08 Recon Drone | Aerial and Technological tag overlap, ordinary ranged damage, and movement through a ground blocker. |
| E09 Tracking Bot | Ranger basic-attack interval scales during the effect and returns to base at expiry. |
| E10 Net Trapper | Timed entanglement stops basic attacks and active skills until expiry. |
| E11 Demolitionist | Independent Siege windup and 60 HP strike on unfinished construction beside Rangers. |
| E12 Portable Mortar Crew | Telegraphed 120 HP Siege attack against a site, Technological overlap and individual encounter selection. |
| E13 Heavy Breacher | Ordinary blocked melee, Knockdown releases Guard's block, and Barricade Ops keeps its block. |
| E14 Ignition Operator | Heat accrual through Firebreak, reset and Integrity loss, unchanged Facility HP and perfection with zero escapes. |
| E15 Wildlife Trafficker | Escape counts once and immediately defeats the operation. |
| Diversion Captain | Intro at 2×, movement aura, scheduled Poachers, successful or missed capture and full settlement in a regular wave. |
| Illegal Logging Foreman | Regular Ranger attack, phase Heat output, temporary HP absorption and expiry under the shared clock. |
| Poacher Leader | Ordered thresholds crossed by one hit, two dialogue holds, deterministic Runner arrival ticks, final surge and victory after the support resolves. |

The combined buff fixture selects the existing B05 effect and tests the 26 HP Ranger attack with the ten-stack damage mark cap. The resulting hit removes 31 HP, and the named mark bonus expires. Capture retires pending and active support without awarding extra defeats or escapes. A regular wave keeps scheduled support in its victory condition.

The sandbox runs the catalog through a three-wave standard lineup or a single selected encounter. **Practice hit** in boss encounters jumps through the same HP and phase rules used by deployed units. Device input, cutout and timing checks remain pending. [Android procedure](../../export/README.md#c12-enemy-and-boss-sandbox-phone-check)
