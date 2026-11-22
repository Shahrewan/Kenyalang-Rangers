# C14 Campaign verification

22 November 2026 · Godot `4.7.2.stable.official.ed1daf0bf` · Compatibility

Story Mode loads W13 directly. The same six W08 maps serve all 15 operations. The stockpiles, entry routes, fixed effects and dialogue triggers come from the stage data and the existing combat and deployment rules. [W13 specs](../production/W13_CAMPAIGN_CONTENT.md) · [W08 layouts](../canon/ART_ASSET_MANIFEST.md#six-map-geometry-layouts)

## Executed checks

| Scope | Result |
|---|---|
| Pinned import and startup | Editor import and headless project boot passed. |
| Existing suites | 562 checks passed in the 11 pre-C14 runners. |
| Campaign resource suite | 117 checks passed across geometry, exact wave totals, Control tiers, fixed effects, opening legality, settlement and save recovery. |
| Campaign Story suite | 249 checks passed through the normal Launcher, planner, Battle and Results routes. |
| Linux viewport | Native pointer navigation, briefing Continue and Skip, free Starter Post drag and pause passed at 960×540 under X11 with Mesa llvmpipe. |
| Android development export | The signed ARM64 APK passed signature, 16 KiB alignment and ZIP validation. The extracted APK payload loaded the Campaign and started its first battle in isolated host Godot. All 16 W13 JSON files matched their repository versions. |
| Physical Android | Awaiting a USB-connected phone. This workspace has no USB device bus. |

Run the Campaign checks from the project root using the pinned Godot executable. [Suite commands](../../tests/README.md)

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/unit/campaign_resources_test.gd
godot --headless --path . --script res://tests/unit/campaign_story_test.gd
```

## Sequence and outcomes

The Story runner makes a new Campaign profile, exercises a legacy Leader name, and completes C1-01 using touch deployment and automatic Ranger attacks. For the remaining 14 operations it applies scripted damage through the normal battle registry. The run clears 49 waves with 1,111 base arrivals and three mandatory Poacher Leader reinforcements. The resource runner compares each stage with the published totals. The Story runner checks the scripted spawn order, combat ticks and route bindings against W13. The runners use temporary saves.

| Operations | Checked in addition to clear and replay routing |
|---|---|
| C1-01 · T01 | 100 starting Integrity, zero Tokens, free mission Post, invalid drop, D01 generation, normal combat victory, pending currency and the original supply on a developed replay. |
| C1-02–03 · T01 | Mechanical purchase and ordinary Post, interrupted-attempt recovery and abandon, persistent clear unlocks, and one cinematic messenger withdrawal with unchanged Integrity and combat counts. |
| C1-04–05 · T01 | Control visibility and prior clear are separate. C1-05 has exactly 120 Tokens, rejects Posts, plays the Captain phase and ends by capture. A Captain escape selects the fatal report. |
| C2-01–02 · T02 | Entries A and B converge on the same tunnel. Permanent unlocks use the prior-clear path. D06 smoke, D09 Siege and D10 build duration resolve from effective definitions. |
| C2-03–04 · T03 | Aerial movement, shortened rests, Ranger skill recharge modifiers and compressed spawn intervals. |
| C2-05–06 · T04 | Effective HP and Token pricing, Ranger HP and recharge effects, and recruit and Facility unlock records. |
| C2-07–08 · T05 | Heat enabled only on these operations. The supplied 30-Token Beacon takes six combat seconds to build and reduces the first E14 Heat tick in C2-07. The C2-08 loadout loses the mission supply. The Foreman phase and the ordinary escape ending both resolve. |
| C2-09–10 · T06 | Wildlife Trafficker and Poacher Leader fatal escape outcomes, both finale phases, three required Runners, first-clear epilogue and pure replay. |

The read and skip runs match at opening, prewave, messenger, boss arrival, phase and outcome holds. They compare the clock, wave, HP, positions, Heat, Tokens, counts and active deployment deadlines. Reward settlement uses test amounts to check first-clear, first-perfect, completion and replay credits and repeat protection. The authored W13 amounts remain pending.

## Playtest status

The 20,000 Funds Mechanical opening is reachable from the 10,000 starting Funds after 5,000 active seconds of Finance. The automated route advances approved Finance accrual and purchases Control upgrades in the test profile. Normal late-Campaign income pacing, human-cleared balance and final payouts require validation. The build uses labeled board and portrait placeholders. Draft dialogue, the Foreman's escape rule, production art, the Barricade shove, Records enhancements and five pending Ranger combat kits remain open. [Decisions](../canon/DECISION_LOG.md#c14-campaign-playtest--2026-11-22) · [Phone checklist](../../export/README.md#c14-campaign-phone-check)
